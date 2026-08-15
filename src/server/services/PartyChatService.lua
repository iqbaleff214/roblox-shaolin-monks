--!strict
-- T-122 (GDD §12.2). Party chat channel persistence: creates a TextChannel
-- per party (TextChatService) and keeps its membership synced to
-- PartyService's (T-120) `PartyChanged` signal. "Persists across chapter
-- loads/teleports" means the SAME logical channel reappears in the
-- destination server the instant everyone lands there — the party's
-- identity/membership is carried in PartyTeleportService's (T-121) teleport
-- data and read back via `player:GetJoinData()` on PlayerAdded, so nobody
-- has to manually rejoin a channel.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local CHANNEL_FOLDER_NAME = "PartyTextChannels"

local PartyChatService = Knit.CreateService({
	Name = "PartyChatService",
})

local channelsByPartyId: { [string]: TextChannel } = {}
local memberUserIdsByPartyId: { [string]: { [number]: boolean } } = {}

local function getOrCreateChannel(partyId: string): TextChannel
	local channel = channelsByPartyId[partyId]
	if channel and channel.Parent then
		return channel
	end

	local folder = TextChatService:FindFirstChild(CHANNEL_FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = CHANNEL_FOLDER_NAME
		folder.Parent = TextChatService
	end

	channel = Instance.new("TextChannel")
	channel.Name = "Party_" .. partyId
	channel.Parent = folder
	channelsByPartyId[partyId] = channel
	return channel
end

local function syncChannelMembers(partyId: string, members: { Player })
	if #members == 0 then
		local channel = channelsByPartyId[partyId]
		if channel then
			channel:Destroy()
			channelsByPartyId[partyId] = nil
		end
		memberUserIdsByPartyId[partyId] = nil
		return
	end

	local channel = getOrCreateChannel(partyId)
	local currentSet = memberUserIdsByPartyId[partyId]
	if not currentSet then
		currentSet = {}
		memberUserIdsByPartyId[partyId] = currentSet
	end

	local wantedSet: { [number]: boolean } = {}
	for _, member in members do
		wantedSet[member.UserId] = true
	end

	for userId in currentSet do
		if not wantedSet[userId] then
			pcall(function()
				channel:RemoveUserAsync(userId)
			end)
			currentSet[userId] = nil
		end
	end

	for _, member in members do
		if not currentSet[member.UserId] then
			local ok = pcall(function()
				channel:AddUserAsync(member.UserId)
			end)
			if ok then
				currentSet[member.UserId] = true
			else
				warn(`[PartyChatService] failed to add {member.Name} to channel {channel.Name}`)
			end
		end
	end
end

local function onPlayerAdded(player: Player)
	local ok, joinData = pcall(function()
		return player:GetJoinData()
	end)
	if not ok or not joinData then
		return
	end

	local teleportData = joinData.TeleportData
	if type(teleportData) ~= "table" or type(teleportData.PartyId) ~= "string" then
		return
	end
	local carriedMemberUserIds = teleportData.MemberUserIds
	if type(carriedMemberUserIds) ~= "table" then
		return
	end

	-- Rejoin every carried member who's actually present in this server
	-- instance (the whole party should be, per T-121's atomic teleport).
	local presentMembers = {}
	for _, userId in carriedMemberUserIds do
		local member = Players:GetPlayerByUserId(userId)
		if member then
			table.insert(presentMembers, member)
		end
	end
	if #presentMembers > 0 then
		syncChannelMembers(teleportData.PartyId, presentMembers)
	end
end

function PartyChatService:KnitInit()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

function PartyChatService:KnitStart()
	local PartyService = Knit.GetService("PartyService")
	PartyService.PartyChanged:Connect(syncChannelMembers)
end

return PartyChatService
