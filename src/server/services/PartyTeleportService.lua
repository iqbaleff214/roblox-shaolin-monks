--!strict
-- T-121 (GDD §12.2). Teleports a full party together into a reserved server
-- for the selected chapter, triggered by PartyService's (T-120)
-- `PartyStartRequested` signal. `TeleportAsync` with a member list is a
-- single atomic call across the whole party — Roblox either lands everyone
-- in the same reserved server or the call fails outright, so "no
-- partial-party splits" (the DoD) falls out of the API's own contract
-- rather than needing custom rollback logic. On failure this retries once
-- before giving up; a failed call moves no one, so the party is simply
-- still in the Lobby either way — nothing to explicitly "roll back".
--
-- Teleport data carries the party's identity (id + member UserIds) so
-- PartyChatService (T-122) can recreate the same chat channel in the
-- destination server without anyone manually rejoining.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)

local ChapterConfig = ConfigService.Chapter
local RETRY_DELAY = 3 -- seconds before a single retry attempt

local PartyTeleportService = Knit.CreateService({
	Name = "PartyTeleportService",
})

-- (partyId: string, chapterId: string, members: {Player}) — a real,
-- ready hookup for a future "return party to Lobby with an error" UI
-- (Phase 11, not built yet).
PartyTeleportService.TeleportFailed = Signal.new()

local function findChapter(chapterId: string)
	for _, chapter in ChapterConfig do
		if chapter.Id == chapterId then
			return chapter
		end
	end
	return nil
end

local function attemptTeleport(partyId: string, chapterId: string, members: { Player }): boolean
	local ok = pcall(function()
		local reservedServerAccessCode = TeleportService:ReserveServer(game.PlaceId)
		local teleportOptions = Instance.new("TeleportOptions")
		teleportOptions.ReservedServerAccessCode = reservedServerAccessCode

		local memberUserIds = {}
		for _, member in members do
			table.insert(memberUserIds, member.UserId)
		end
		teleportOptions:SetTeleportData({
			PartyId = partyId,
			ChapterId = chapterId,
			MemberUserIds = memberUserIds,
		})

		TeleportService:TeleportAsync(game.PlaceId, members, teleportOptions)
	end)
	return ok
end

local function onPartyStartRequested(partyId: string, chapterId: string, members: { Player })
	if not findChapter(chapterId) then
		return
	end

	-- Only currently-connected members can be teleported; a member who
	-- disconnected between requesting and this call is simply excluded.
	local connectedMembers = {}
	for _, member in members do
		if member.Parent then
			table.insert(connectedMembers, member)
		end
	end
	if #connectedMembers == 0 then
		return
	end

	if attemptTeleport(partyId, chapterId, connectedMembers) then
		return
	end

	task.delay(RETRY_DELAY, function()
		if not attemptTeleport(partyId, chapterId, connectedMembers) then
			PartyTeleportService.TeleportFailed:Fire(partyId, chapterId, connectedMembers)
		end
	end)
end

function PartyTeleportService:KnitStart()
	local PartyService = Knit.GetService("PartyService")
	PartyService.PartyStartRequested:Connect(onPartyStartRequested)
end

return PartyTeleportService
