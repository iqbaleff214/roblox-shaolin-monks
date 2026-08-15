-- T-090 (GDD §9.1). Pure XP formula: BaseXP × DifficultyMultiplier ×
-- StyleScoreMultiplier. Requires ProgressionConfig directly (config data,
-- not a Roblox service) rather than ConfigService, matching RarityVisualPreset's
-- precedent for pure modules that need one specific config table.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProgressionConfig = require(ReplicatedStorage.Shared.config.ProgressionConfig)

local XPCalculator = {}

export type PerformanceInput = {
	TookDamage: boolean,
	Deaths: number,
	HadHighComboAverage: boolean,
}

-- Classifies a chapter/arena clear into one of the four §9.1 performance
-- tiers. Flawless takes priority over everything else; two or more deaths is
-- "Multiple Deaths" regardless of combo performance.
function XPCalculator.classifyPerformance(input: PerformanceInput): string
	if not input.TookDamage and input.Deaths == 0 then
		return "Flawless"
	elseif input.Deaths >= 2 then
		return "MultipleDeaths"
	elseif input.HadHighComboAverage then
		return "HighCombo"
	end
	return "Standard"
end

-- Unknown tiers fall back to a 1.0 multiplier/BaseXP rather than erroring —
-- every caller in this codebase is server-internal and passes a validated
-- tier, but a silent no-op default is safer than a hard crash on a typo.
function XPCalculator.computeXP(difficultyTier: string, performanceTier: string): number
	local difficultyMultiplier = ProgressionConfig.XP.DifficultyMultiplier[difficultyTier] or 1.0
	local styleMultiplier = ProgressionConfig.XP.StyleScoreMultiplier[performanceTier] or 1.0
	return ProgressionConfig.XP.BaseXP * difficultyMultiplier * styleMultiplier
end

return XPCalculator
