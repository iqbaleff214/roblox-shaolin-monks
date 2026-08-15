-- T-092 (GDD §9.3). Pure star calculation: 0-3 stars per chapter clear, one
-- star each for Style Score, damage taken, and clear time independently
-- clearing their ProgressionConfig.Mastery threshold. No live gameplay state
-- involved — purely a function of the three inputs, so tuning a threshold
-- never requires a full replay to verify.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProgressionConfig = require(ReplicatedStorage.Shared.config.ProgressionConfig)

local MasteryStars = {}

function MasteryStars.calculate(styleScore: number, damageTaken: number, clearTimeSeconds: number): number
	local mastery = ProgressionConfig.Mastery
	local stars = 0
	if styleScore >= mastery.StyleScoreThreshold then
		stars += 1
	end
	if damageTaken <= mastery.MaxDamageTakenForStar then
		stars += 1
	end
	if clearTimeSeconds <= mastery.ClearTimeThresholdSeconds then
		stars += 1
	end
	return stars
end

return MasteryStars
