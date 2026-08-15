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
-- Persistence (T-160, Phase 14): reads/writes go straight through
-- PlayerDataService:GetProfile(player).Level/.TotalXP/.AvailableSkillPoints
-- on every call rather than a locally-cached copy — PlayerDataService's
-- async load mutates the profile's fields in place whenever it resolves, so
-- a local cache taken before that finishes would freeze at the pre-load
-- default and never see the loaded value (CurrencyService, T-110,
-- documents this same reasoning).

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

local function getProfile(player: Player)
	return Knit.GetService("PlayerDataService"):GetProfile(player)
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

	local profile = getProfile(player)
	profile.TotalXP += grantedAmount
	ProgressionService.XPGranted:Fire(player, grantedAmount, source, profile.TotalXP)

	local newLevel = LevelCurve.levelForXP(profile.TotalXP)
	while profile.Level < newLevel do
		profile.Level += 1
		profile.AvailableSkillPoints += ProgressionConfig.SkillPoints.PerLevel
		ProgressionService.LevelUp:Fire(player, profile.Level, ProgressionConfig.SkillPoints.PerLevel)
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
	local profile = getProfile(player)
	if profile.AvailableSkillPoints < amount then
		return false
	end
	profile.AvailableSkillPoints -= amount
	return true
end

function ProgressionService:GetLevel(player: Player): number
	return getProfile(player).Level
end

function ProgressionService:GetAvailableSkillPoints(player: Player): number
	return getProfile(player).AvailableSkillPoints
end

--// Read-only client API \\--

function ProgressionService.Client:GetLevel(player: Player): number
	return ProgressionService:GetLevel(player)
end

function ProgressionService.Client:GetXP(player: Player): number
	return getProfile(player).TotalXP
end

function ProgressionService.Client:GetAvailableSkillPoints(player: Player): number
	return ProgressionService:GetAvailableSkillPoints(player)
end

return ProgressionService
