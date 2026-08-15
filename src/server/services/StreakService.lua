--!strict
-- T-094 (GDD §9.5). Login streak (fires `PremiumDropEarned` every Nth
-- consecutive day) and in-run consecutive-Flawless-arena streak (escalating
-- Coin bonus). Reuses QuestConfig.ResetHourUTC/QuestResetSchedule for the
-- daily boundary — a single source of truth for "what day is it" shared with
-- QuestService (T-093).
--
-- `RecordArenaClear` is real and ready but has no live caller yet: detecting
-- "was this arena clear Flawless" requires a per-arena damage-taken tracker
-- that doesn't exist anywhere in this codebase yet (the same gap noted in
-- ProgressionService's GrantChapterClearXP) — Phase 8/10's eventual
-- chapter/arena-clear flow is expected to supply that boolean.
--
-- Persistence seam: in-memory this session; T-160 (Phase 14) will persist
-- `loginStreak`/`lastLoginPeriodId` for real across server restarts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)
local QuestResetSchedule = require(ReplicatedStorage.Shared.modules.QuestResetSchedule)
local StreakTracker = require(ReplicatedStorage.Shared.modules.StreakTracker)

local QuestConfig = ConfigService.Quest
local ProgressionConfig = ConfigService.Progression

local StreakService = Knit.CreateService({
	Name = "StreakService",
	Client = {},
})

-- (player: Player, loginStreak: number)
StreakService.PremiumDropEarned = Signal.new()
-- (player: Player, arenaStreak: number, bonusCoins: number)
StreakService.FlawlessBonusEarned = Signal.new()

local trackersByPlayer: { [Player]: StreakTracker.StreakTracker } = {}

local function getTracker(player: Player): StreakTracker.StreakTracker
	local tracker = trackersByPlayer[player]
	if not tracker then
		tracker = StreakTracker.new()
		trackersByPlayer[player] = tracker
	end
	return tracker
end

local function onPlayerLogin(player: Player)
	local tracker = getTracker(player)
	local periodId = QuestResetSchedule.dailyPeriodId(os.time(), QuestConfig.ResetHourUTC)
	local streak, milestoneReached = tracker:registerLogin(periodId, ProgressionConfig.Streak.LoginStreakMilestoneDays)
	if milestoneReached then
		StreakService.PremiumDropEarned:Fire(player, streak)
	end
end

-- Server-internal: awaits a Flawless-detection caller (see file header).
function StreakService:RecordArenaClear(player: Player, wasFlawless: boolean)
	local tracker = getTracker(player)
	local streakConfig = ProgressionConfig.Streak
	local streak, bonus = tracker:registerArenaClear(wasFlawless, streakConfig.FlawlessArenaBaseBonus, streakConfig.FlawlessArenaBonusPerStreak)
	if bonus > 0 then
		StreakService.FlawlessBonusEarned:Fire(player, streak, bonus)
	end
end

function StreakService.Client:GetLoginStreak(player: Player): number
	return getTracker(player).loginStreak
end

function StreakService:KnitInit()
	Players.PlayerRemoving:Connect(function(player)
		trackersByPlayer[player] = nil
	end)
end

function StreakService:KnitStart()
	for _, player in Players:GetPlayers() do
		onPlayerLogin(player)
	end
	Players.PlayerAdded:Connect(onPlayerLogin)
end

return StreakService
