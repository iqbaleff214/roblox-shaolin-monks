--!strict
-- T-093 (GDD §9.4). Daily/Weekly quest progress tracking and reward grant.
-- Reset cadence uses QuestResetSchedule's pure period-id math (daily =
-- midnight UTC per §7.4, weekly = Monday UTC per §9.7/§7.3) — a player's
-- stored period id is compared against the current one on every read/write;
-- a mismatch means the bucket (Daily or Weekly) resets before anything else
-- happens.
--
-- Reward grant: XP-type rewards call ProgressionService directly (built this
-- same phase, no seam needed); Coins/Title/CosmeticCrate rewards only fire
-- `QuestCompleted` — Currency (T-110), the Title/Crate systems (Phase 9) don't
-- exist yet, matching this codebase's established forward-dependency pattern.
--
-- Real hookups wired today: LandFinishingMoves (CombatService.FinishingMoveLanded)
-- and DefeatDistinctBosses (CombatService.EnemyDefeated filtered to Role ==
-- "Boss", tracked as a set so reskinned repeats of the same boss don't
-- double-count). BreakContainers/FindHiddenRelics await T-100/T-102 (Phase 8);
-- ClearChapterNoDeath/ClearTrialRush await the chapter-clear and Trial Rush
-- flows (Phase 10) — `IncrementProgress`/`CompleteQuest` are real, ready,
-- server-internal methods for those future callers.
--
-- Persistence: `PlayerDataService` (T-160, Phase 14) now exists with a
-- matching `QuestProgress` profile field (period ids + Daily/Weekly
-- progress + DistinctBossesDefeated), but this service isn't wired to it
-- yet — still in-memory per session, ready for the same direct-profile-
-- access retrofit CurrencyService (T-110) and ProgressionService (T-090)
-- already demonstrate.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)
local QuestResetSchedule = require(ReplicatedStorage.Shared.modules.QuestResetSchedule)

local QuestConfig = ConfigService.Quest

local QuestService = Knit.CreateService({
	Name = "QuestService",
	Client = {},
})

-- (player: Player, questId: string, rewardType: string, rewardAmountOrValue: any)
QuestService.QuestCompleted = Signal.new()

type QuestProgress = { progress: number, completed: boolean }

type PlayerState = {
	dailyPeriodId: number?,
	weeklyPeriodId: number?,
	dailyProgress: { [string]: QuestProgress },
	weeklyProgress: { [string]: QuestProgress },
	distinctBossesDefeated: { [string]: boolean }, -- backs DefeatDistinctBosses; cleared on weekly reset
}

local states: { [Player]: PlayerState } = {}

local function findQuestDef(questId: string): { Id: string, Goal: number, RewardType: string, RewardAmount: number?, RewardValue: any }?
	for _, entry in QuestConfig.Daily do
		if entry.Id == questId then
			return entry
		end
	end
	for _, entry in QuestConfig.Weekly do
		if entry.Id == questId then
			return entry
		end
	end
	return nil
end

local function isDaily(questId: string): boolean
	for _, entry in QuestConfig.Daily do
		if entry.Id == questId then
			return true
		end
	end
	return false
end

local function getState(player: Player): PlayerState
	local state = states[player]
	if not state then
		state = {
			dailyPeriodId = nil :: number?,
			weeklyPeriodId = nil :: number?,
			dailyProgress = {},
			weeklyProgress = {},
			distinctBossesDefeated = {},
		}
		states[player] = state
	end
	return state
end

-- Resets the Daily/Weekly bucket whenever the current period id has moved
-- past what's stored, discarding all progress for that bucket.
local function refreshPeriods(state: PlayerState)
	local now = os.time()
	local currentDaily = QuestResetSchedule.dailyPeriodId(now, QuestConfig.ResetHourUTC)
	local currentWeekly = QuestResetSchedule.weeklyPeriodId(now)

	if state.dailyPeriodId ~= currentDaily then
		state.dailyPeriodId = currentDaily
		state.dailyProgress = {}
	end
	if state.weeklyPeriodId ~= currentWeekly then
		state.weeklyPeriodId = currentWeekly
		state.weeklyProgress = {}
		state.distinctBossesDefeated = {}
	end
end

local function getProgressTable(state: PlayerState, questId: string): { [string]: QuestProgress }
	return if isDaily(questId) then state.dailyProgress else state.weeklyProgress
end

function QuestService:CompleteQuest(player: Player, questId: string)
	local def = findQuestDef(questId)
	if not def then
		return
	end

	if def.RewardType == "XP" and def.RewardAmount then
		local ProgressionService = Knit.GetService("ProgressionService")
		ProgressionService:GrantXP(player, def.RewardAmount, "Quest:" .. questId)
	end

	QuestService.QuestCompleted:Fire(player, questId, def.RewardType, def.RewardAmount or def.RewardValue)
end

-- Server-internal: advances `questId`'s progress by `amount`, auto-completing
-- (and granting the reward) the moment its Goal is reached. A no-op once
-- already completed this period, preventing a double reward.
function QuestService:IncrementProgress(player: Player, questId: string, amount: number)
	local def = findQuestDef(questId)
	if not def then
		return
	end

	local state = getState(player)
	refreshPeriods(state)
	local progressTable = getProgressTable(state, questId)

	local entry = progressTable[questId]
	if not entry then
		entry = { progress = 0, completed = false }
		progressTable[questId] = entry
	end
	if entry.completed then
		return
	end

	entry.progress = math.min(def.Goal, entry.progress + amount)
	if entry.progress >= def.Goal then
		entry.completed = true
		self:CompleteQuest(player, questId)
	end
end

local function onFinishingMoveLanded(_target: Model, player: Player?)
	if player then
		QuestService:IncrementProgress(player, "LandFinishingMoves", 1)
	end
end

local function onEnemyDefeated(target: Model, player: Player?)
	if not player or target:GetAttribute("Role") ~= "Boss" then
		return
	end
	local bossId = target:GetAttribute("EnemyId")
	local identity = if type(bossId) == "string" then bossId else target.Name

	local state = getState(player)
	refreshPeriods(state)
	if not state.distinctBossesDefeated[identity] then
		state.distinctBossesDefeated[identity] = true
		QuestService:IncrementProgress(player, "DefeatDistinctBosses", 1)
	end
end

function QuestService.Client:GetProgress(player: Player, questId: string): { progress: number, goal: number, completed: boolean }
	local def = findQuestDef(questId)
	if not def then
		return { progress = 0, goal = 0, completed = false }
	end
	local state = getState(player)
	refreshPeriods(state)
	local entry = getProgressTable(state, questId)[questId]
	return {
		progress = if entry then entry.progress else 0,
		goal = def.Goal,
		completed = if entry then entry.completed else false,
	}
end

function QuestService:KnitInit()
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
end

function QuestService:KnitStart()
	local CombatService = Knit.GetService("CombatService")
	CombatService.FinishingMoveLanded:Connect(onFinishingMoveLanded)
	CombatService.EnemyDefeated:Connect(onEnemyDefeated)
end

return QuestService
