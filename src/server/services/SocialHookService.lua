--!strict
-- T-125 (GDD §12.4). Three social broadcasts:
--   * FINISH! callout: fires to nearby party members the instant a Finishing
--     Move lands (CombatService.FinishingMoveLanded, real today).
--   * Flawless banner: `BroadcastFlawlessClear` is a real, ready
--     server-internal method awaiting the same "was this arena Flawless"
--     detector gap noted in ProgressionService/StreakService (Phase 7/8) —
--     not auto-wired to anything yet, since that detector doesn't exist.
--   * Hub-wide boss-defeat announcement: bosses are only ever fought in a
--     battlefield's reserved server, never the Lobby server, so reaching
--     "players currently in the Lobby server" (§12.4's explicit scope, not
--     a global cross-server broadcast) requires genuine cross-server
--     messaging (MessagingService). Every server publishes on boss defeat;
--     only a server that IS the Lobby (a non-reserved server —
--     `game.PrivateServerId == ""`) relays it to its own connected clients.

local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local HUB_ANNOUNCEMENT_TOPIC = "SMA_HubAnnouncements"
local FINISH_CALLOUT_RANGE = 40 -- studs; "nearby teammates" (§12.4)

local SocialHookService = Knit.CreateService({
	Name = "SocialHookService",
	Client = {
		FinishCallout = Knit.CreateSignal(), -- (finisher: Player)
		FlawlessBanner = Knit.CreateSignal(), -- ()
		HubAnnouncement = Knit.CreateSignal(), -- (kind: string, data: {any})
	},
})

local function isLobbyServer(): boolean
	return game.PrivateServerId == ""
end

local function onFinishingMoveLanded(_target: Model, player: Player?)
	if not player then
		return
	end
	local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?

	local PartyService = Knit.GetService("PartyService")
	local members = PartyService:GetPartyMembers(player)
	if #members == 0 then
		members = { player }
	end

	for _, member in members do
		if member == player then
			SocialHookService.Client.FinishCallout:Fire(member, player)
		elseif rootPart then
			local memberRoot = member.Character and member.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if memberRoot and (memberRoot.Position - rootPart.Position).Magnitude <= FINISH_CALLOUT_RANGE then
				SocialHookService.Client.FinishCallout:Fire(member, player)
			end
		end
	end
end

-- Server-internal: real and ready; awaits a live "was this clear Flawless"
-- detector as its caller (same gap as Phase 7/8's equivalent seams).
function SocialHookService:BroadcastFlawlessClear(members: { Player })
	for _, member in members do
		SocialHookService.Client.FlawlessBanner:Fire(member)
	end
end

local function onEnemyDefeated(target: Model, _player: Player?)
	if target:GetAttribute("Role") ~= "Boss" then
		return
	end
	local bossId = target:GetAttribute("EnemyId")
	local identity = if type(bossId) == "string" then bossId else target.Name

	pcall(function()
		MessagingService:PublishAsync(HUB_ANNOUNCEMENT_TOPIC, { Kind = "BossDefeated", BossId = identity })
	end)
end

local function onHubAnnouncementMessage(message: { Data: any })
	if not isLobbyServer() then
		return -- §12.4: only Lobby-server clients ever see this
	end
	local data = message.Data
	if type(data) ~= "table" or type(data.Kind) ~= "string" then
		return
	end
	SocialHookService.Client.HubAnnouncement:FireAll(data.Kind, data)
end

function SocialHookService:KnitStart()
	local CombatService = Knit.GetService("CombatService")
	CombatService.FinishingMoveLanded:Connect(onFinishingMoveLanded)
	CombatService.EnemyDefeated:Connect(onEnemyDefeated)

	pcall(function()
		MessagingService:SubscribeAsync(HUB_ANNOUNCEMENT_TOPIC, onHubAnnouncementMessage)
	end)
end

return SocialHookService
