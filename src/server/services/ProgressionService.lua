--!strict
-- T-090 (GDD §9.1). Server-authoritative XP and Level. `GrantXP` is the
-- single writer (T-049/T-110's "one function" pattern) — no Client method on
-- this service ever mutates XP; only server-internal callers (a future
-- chapter-clear flow via T-121/Phase 10, or this same phase's QuestService
-- for XP-type quest rewards) may grant it.
--
-- Also owns the Skill Point bank that SkillTreeService (T-091) spends from —
-- leveling grants Skill Points, never raw stat power, per §9.1's explicit
-- design rule.
--
-- Persistence seam: `PlayerDataService` (T-160, Phase 14) doesn't exist yet.
-- Held in memory per session, the same interim pattern as every other
-- player-data system in this codebase (InventoryService, WeaponService, ...).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)
local XPCalculator = require(ReplicatedStorage.Shared.modules.XPCalculator)
local LevelCurve = require(ReplicatedStorage.Shared.modules.LevelCurve)

local ProgressionConfig = ConfigService.Progression

local ProgressionService = Knit.CreateService({
	Name = "ProgressionService",
	Client = {},
})

-- (player: Player, amount: number, source: string, newTotalXP: number)
ProgressionService.XPGranted = Signal.new()
-- (player: Player, newLevel: number, skillPointsGranted: number) — fired once
-- per level crossed, so a multi-level jump from one grant fires once per level.
ProgressionService.LevelUp = Signal.new()

type PlayerState = {
	totalXP: number,
	level: number,
	availableSkillPoints: number,
}

local states: { [Player]: PlayerState } = {}

local function getState(player: Player): PlayerState
	local state = states[player]
	if not state then
		state = { totalXP = 0, level = 0, availableSkillPoints = 0 }
		states[player] = state
	end
	return state
end

-- Server-internal: the one function that ever mutates XP. `source` is logged
-- for future anti-cheat/audit purposes (mirrors T-110's currency-grant DoD).
-- T-113: VIPService sets the `IsVIP` attribute; a VIP player's grant is
-- boosted by MonetizationConfig.VIPBoostXP.
function ProgressionService:GrantXP(player: Player, amount: number, source: string)
	if amount <= 0 then
		return
	end

	local grantedAmount = amount
	if player:GetAttribute("IsVIP") == true then
		grantedAmount = math.floor(amount * (1 + ConfigService.Monetization.VIPBoostXP))
	end

	local state = getState(player)
	state.totalXP += grantedAmount
	ProgressionService.XPGranted:Fire(player, grantedAmount, source, state.totalXP)

	local newLevel = LevelCurve.levelForXP(state.totalXP)
	while state.level < newLevel do
		state.level += 1
		state.availableSkillPoints += ProgressionConfig.SkillPoints.PerLevel
		ProgressionService.LevelUp:Fire(player, state.level, ProgressionConfig.SkillPoints.PerLevel)
	end
end

-- Server-internal convenience wrapping XPCalculator's §9.1 formula — the
-- ready hookup point for chapter-clear XP once a caller (Phase 10's Party/
-- Chapter flow) exists to supply real difficulty/performance data.
function ProgressionService:GrantChapterClearXP(player: Player, difficultyTier: string, performanceInput: XPCalculator.PerformanceInput)
	local tier = XPCalculator.classifyPerformance(performanceInput)
	local amount = XPCalculator.computeXP(difficultyTier, tier)
	self:GrantXP(player, amount, "ChapterClear")
end

-- Server-internal: spends banked Skill Points. Returns false (no state
-- change) if the player doesn't have enough — SkillTreeService (T-091) is
-- the only caller.
function ProgressionService:SpendSkillPoints(player: Player, amount: number): boolean
	local state = getState(player)
	if state.availableSkillPoints < amount then
		return false
	end
	state.availableSkillPoints -= amount
	return true
end

function ProgressionService:GetLevel(player: Player): number
	return getState(player).level
end

function ProgressionService:GetAvailableSkillPoints(player: Player): number
	return getState(player).availableSkillPoints
end

--// Read-only client API \\--

function ProgressionService.Client:GetLevel(player: Player): number
	return ProgressionService:GetLevel(player)
end

function ProgressionService.Client:GetXP(player: Player): number
	return getState(player).totalXP
end

function ProgressionService.Client:GetAvailableSkillPoints(player: Player): number
	return ProgressionService:GetAvailableSkillPoints(player)
end

function ProgressionService:KnitInit()
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
end

return ProgressionService
