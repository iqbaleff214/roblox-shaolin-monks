--!strict
-- T-120 (GDD §12.2). Party leader invites up to 3 friends (party of 4 total),
-- with state synced across every member's client via a Knit RemoteSignal
-- (`Client.PartyUpdated`) — the first system in this codebase that needs
-- live UI-facing state replication rather than a one-shot RemoteFunction
-- call. Membership/leader/ready rules are owned by the pure PartyRoster
-- module (T-120); this service is the thin Roblox-facing wrapper matching
-- every other stateful system's split in this codebase.
--
-- Leader-only actions (`RequestKickMember`, `RequestStartChapter`) check
-- `roster:isLeader(player)` server-side — a non-leader's request is rejected
-- regardless of what the client believes its own role is.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)
local PartyRoster = require(ReplicatedStorage.Shared.modules.PartyRoster)

local PartyConfig = ConfigService.Party

local PartyService = Knit.CreateService({
	Name = "PartyService",
	Client = {
		PartyUpdated = Knit.CreateSignal(), -- (snapshot: {leader: Player, members: {Player}, ready: {[Player]: boolean}})
		PartyInviteReceived = Knit.CreateSignal(), -- (fromPlayer: Player, partyId: string)
	},
})

-- (partyId: string, chapterId: string, members: {Player}) — server-internal;
-- PartyTeleportService (T-121) is the real consumer.
PartyService.PartyStartRequested = Signal.new()
-- (partyId: string, members: {Player}) — fired on every membership/leader
-- change, including an empty `members` on disband. PartyChatService (T-122)
-- is the real consumer.
PartyService.PartyChanged = Signal.new()

type PartyState = {
	id: string,
	roster: PartyRoster.PartyRoster,
	openToMatchmaking: boolean,
}

local parties: { [string]: PartyState } = {}
local partyIdByPlayer: { [Player]: string } = {}
-- target player -> set of partyIds that invited them
local pendingInvites: { [Player]: { [string]: boolean } } = {}
local nextPartyId = 0

local function newPartyId(): string
	nextPartyId += 1
	return "Party" .. nextPartyId
end

local function broadcast(party: PartyState)
	local snapshot = {
		leader = party.roster.leader,
		members = party.roster.members,
		ready = party.roster.ready,
	}
	for _, member in party.roster.members do
		PartyService.Client.PartyUpdated:Fire(member, snapshot)
	end
	PartyService.PartyChanged:Fire(party.id, party.roster.members)
end

local function disbandParty(party: PartyState)
	for _, member in party.roster.members do
		partyIdByPlayer[member] = nil
	end
	parties[party.id] = nil
	PartyService.PartyChanged:Fire(party.id, {})
end

local function leaveCurrentParty(player: Player)
	local partyId = partyIdByPlayer[player]
	if not partyId then
		return
	end
	local party = parties[partyId]
	if not party then
		partyIdByPlayer[player] = nil
		return
	end

	partyIdByPlayer[player] = nil
	local emptied = party.roster:removeMember(player)
	if emptied then
		disbandParty(party)
	else
		broadcast(party)
	end
end

function PartyService.Client:CreateParty(player: Player): boolean
	if partyIdByPlayer[player] then
		return false -- already in a party
	end
	local id = newPartyId()
	local party: PartyState = {
		id = id,
		roster = PartyRoster.new(player, PartyConfig.MaxPartySize),
		openToMatchmaking = false,
	}
	parties[id] = party
	partyIdByPlayer[player] = id
	broadcast(party)
	return true
end

function PartyService.Client:InviteToParty(player: Player, target: Player): boolean
	local partyId = partyIdByPlayer[player]
	local party = partyId and parties[partyId]
	if not party or not party.roster:isLeader(player) then
		return false
	end
	if not party.roster:hasRoom() or partyIdByPlayer[target] then
		return false
	end

	local invites = pendingInvites[target]
	if not invites then
		invites = {}
		pendingInvites[target] = invites
	end
	invites[party.id] = true

	PartyService.Client.PartyInviteReceived:Fire(target, player, party.id)
	return true
end

function PartyService.Client:AcceptInvite(player: Player, partyId: string): boolean
	local invites = pendingInvites[player]
	if not invites or not invites[partyId] then
		return false
	end
	pendingInvites[player] = nil

	if partyIdByPlayer[player] then
		return false -- already in a party
	end
	local party = parties[partyId]
	if not party or not party.roster:addMember(player) then
		return false
	end

	partyIdByPlayer[player] = partyId
	broadcast(party)
	return true
end

function PartyService.Client:DeclineInvite(player: Player, partyId: string)
	local invites = pendingInvites[player]
	if invites then
		invites[partyId] = nil
	end
end

function PartyService.Client:KickMember(player: Player, target: Player): boolean
	local partyId = partyIdByPlayer[player]
	local party = partyId and parties[partyId]
	if not party or not party.roster:isLeader(player) or player == target then
		return false
	end
	if not party.roster:contains(target) then
		return false
	end

	partyIdByPlayer[target] = nil
	local emptied = party.roster:removeMember(target)
	if emptied then
		disbandParty(party)
	else
		broadcast(party)
	end
	return true
end

function PartyService.Client:SetReady(player: Player, isReady: boolean)
	local partyId = partyIdByPlayer[player]
	local party = partyId and parties[partyId]
	if not party then
		return
	end
	party.roster:setReady(player, isReady)
	broadcast(party)
end

function PartyService.Client:LeaveParty(player: Player)
	leaveCurrentParty(player)
end

function PartyService.Client:SetOpenToMatchmaking(player: Player, isOpen: boolean): boolean
	local partyId = partyIdByPlayer[player]
	local party = partyId and parties[partyId]
	if not party or not party.roster:isLeader(player) then
		return false
	end
	party.openToMatchmaking = isOpen
	return true
end

-- Finds any party marked open with room and joins it — the "matchmake into
-- an open party" path (§12.2), as a simple linear search over open parties.
function PartyService.Client:RequestQuickJoin(player: Player): boolean
	if partyIdByPlayer[player] then
		return false
	end
	for _, party in parties do
		if party.openToMatchmaking and party.roster:hasRoom() then
			if party.roster:addMember(player) then
				partyIdByPlayer[player] = party.id
				broadcast(party)
				return true
			end
		end
	end
	return false
end

function PartyService.Client:RequestStartChapter(player: Player, chapterId: string): boolean
	local partyId = partyIdByPlayer[player]
	local party = partyId and parties[partyId]
	if not party or not party.roster:isLeader(player) then
		return false
	end

	PartyService.PartyStartRequested:Fire(party.id, chapterId, party.roster.members)
	return true
end

--// Server-internal reads (ArenaGateController/T-123, ReviveService/T-124) \\--

function PartyService:GetPartySize(player: Player): number
	local partyId = partyIdByPlayer[player]
	local party = partyId and parties[partyId]
	return if party then party.roster:size() else 0
end

function PartyService:GetPartyMembers(player: Player): { Player }
	local partyId = partyIdByPlayer[player]
	local party = partyId and parties[partyId]
	return if party then party.roster.members else {}
end

function PartyService:KnitInit()
	Players.PlayerRemoving:Connect(function(player)
		leaveCurrentParty(player)
		pendingInvites[player] = nil
	end)
end

return PartyService
