--!strict
-- T-092 (GDD §9.3). Tracks best-ever star count per chapter per player (a
-- replay never lowers an already-earned rating) and the running total across
-- all chapters, firing `MilestoneReached` when the total crosses one of
-- ProgressionConfig.Mastery.MilestoneTotals — the hookup point for the
-- permanent-cosmetic unlock (Phase 8/9, not built yet).
--
-- `RecordChapterClear` is server-internal, real, and ready — it awaits the
-- same not-yet-built "chapter clear" trigger as ProgressionService's
-- GrantChapterClearXP and LeaderboardService's SubmitClearTime/SubmitStyleScore
-- (Phase 10's Party/Chapter flow). Persistence seam: in-memory this session,
-- same interim pattern as every other player-data system here; T-160 (Phase
-- 14) will back it with real DataStore persistence.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)
local MasteryStars = require(ReplicatedStorage.Shared.modules.MasteryStars)

local ProgressionConfig = ConfigService.Progression

local MasteryService = Knit.CreateService({
	Name = "MasteryService",
	Client = {},
})

-- (player: Player, totalStars: number, milestone: number)
MasteryService.MilestoneReached = Signal.new()

type PlayerState = {
	starsByChapter: { [string]: number },
	totalStars: number,
	milestonesReached: { [number]: boolean },
}

local states: { [Player]: PlayerState } = {}

local function getState(player: Player): PlayerState
	local state = states[player]
	if not state then
		state = { starsByChapter = {}, totalStars = 0, milestonesReached = {} }
		states[player] = state
	end
	return state
end

local function recomputeTotal(state: PlayerState): number
	local total = 0
	for _, stars in state.starsByChapter do
		total += stars
	end
	return total
end

function MasteryService:RecordChapterClear(player: Player, chapterId: string, styleScore: number, damageTaken: number, clearTimeSeconds: number): number
	local stars = MasteryStars.calculate(styleScore, damageTaken, clearTimeSeconds)
	local state = getState(player)
	local previousBest = state.starsByChapter[chapterId] or 0

	if stars > previousBest then
		state.starsByChapter[chapterId] = stars
		state.totalStars = recomputeTotal(state)

		for _, milestone in ProgressionConfig.Mastery.MilestoneTotals do
			if state.totalStars >= milestone and not state.milestonesReached[milestone] then
				state.milestonesReached[milestone] = true
				MasteryService.MilestoneReached:Fire(player, state.totalStars, milestone)
			end
		end
	end

	return stars
end

function MasteryService:GetTotalStars(player: Player): number
	return getState(player).totalStars
end

function MasteryService.Client:GetChapterStars(player: Player, chapterId: string): number
	return getState(player).starsByChapter[chapterId] or 0
end

function MasteryService.Client:GetTotalStars(player: Player): number
	return MasteryService:GetTotalStars(player)
end

function MasteryService:KnitInit()
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
end

return MasteryService
