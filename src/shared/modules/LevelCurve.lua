-- T-090 (GDD §9.1). Converts banked total XP into a Level using
-- ProgressionConfig.XP.ThresholdForLevel as the cumulative-XP-to-reach curve.
-- Players start at Level 0 (ThresholdForLevel(1) == 100, not 0) — reaching
-- Level 1 is itself the first milestone, consistent with the config's own
-- formula rather than introducing a second, competing definition of "Level 1".

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProgressionConfig = require(ReplicatedStorage.Shared.config.ProgressionConfig)

local LevelCurve = {}

function LevelCurve.levelForXP(totalXP: number): number
	local level = 0
	while ProgressionConfig.XP.ThresholdForLevel(level + 1) <= totalXP do
		level += 1
	end
	return level
end

-- Cumulative XP required to reach `currentLevel + 1` — the HUD's XP-bar
-- "next level" target (T-131, not built yet).
function LevelCurve.xpForNextLevel(currentLevel: number): number
	return ProgressionConfig.XP.ThresholdForLevel(currentLevel + 1)
end

return LevelCurve
