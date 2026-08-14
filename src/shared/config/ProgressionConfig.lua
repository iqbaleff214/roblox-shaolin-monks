-- GDD §9 / §10.1. XP formula, level thresholds, Skill Point costs, and the
-- capped stat-growth curve. §9.2: stat growth must reach its ceiling by
-- Level 30 so a F2P player and a top spender arrive at the same combat
-- ceiling — HealthBonusAtLevel/ChiBonusAtLevel enforce that by construction
-- (math.min caps the effective level), rather than relying on a hand-typed
-- table staying correct.

local MAX_STAT_LEVEL = 30
local HEALTH_PER_RANK = 5
local CHI_PER_RANK = 3

local ProgressionConfig = {}

-- §9.1: XP per chapter = BaseXP × DifficultyMultiplier × StyleScoreMultiplier
ProgressionConfig.XP = {
	BaseXP = 100,

	DifficultyMultiplier = {
		Novice = 1.0,
		Adept = 1.25,
		Veteran = 1.6,
		Master = 2.0,
	},

	StyleScoreMultiplier = {
		Flawless = 2.5, -- no damage taken
		HighCombo = 2.0,
		Standard = 1.0,
		MultipleDeaths = 0.5,
	},
}

function ProgressionConfig.XP.ThresholdForLevel(level: number): number
	-- Cumulative XP required to reach `level`; smooth increasing curve, no
	-- hand-typed table to drift out of sync.
	return math.floor(100 * (level ^ 1.5))
end

-- §9.2: Skill Points spent on combo/mobility unlocks and capped stat growth.
ProgressionConfig.SkillPoints = {
	PerLevel = 1,
	NodeCosts = {
		ExtendedCombo = 1,
		DoubleJump = 2,
		DodgeCooldownReduction = 1,
		ParryWindowExtension = 2,
		WeaponRetrievalSpeed = 1,
		HealthGrowth = 1, -- per rank, capped at MAX_STAT_LEVEL ranks
		ChiGrowth = 1, -- per rank, capped at MAX_STAT_LEVEL ranks
	},
}

ProgressionConfig.StatGrowth = {
	HealthPerRank = HEALTH_PER_RANK,
	ChiPerRank = CHI_PER_RANK,
	MaxRankLevel = MAX_STAT_LEVEL,
}

function ProgressionConfig.StatGrowth.HealthBonusAtLevel(level: number): number
	local cappedLevel = math.clamp(level, 0, MAX_STAT_LEVEL)
	return cappedLevel * HEALTH_PER_RANK
end

function ProgressionConfig.StatGrowth.ChiBonusAtLevel(level: number): number
	local cappedLevel = math.clamp(level, 0, MAX_STAT_LEVEL)
	return cappedLevel * CHI_PER_RANK
end

return ProgressionConfig
