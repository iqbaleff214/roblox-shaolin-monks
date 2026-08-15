local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MasteryStars = require(ReplicatedStorage.Shared.modules.MasteryStars)
local ProgressionConfig = require(ReplicatedStorage.Shared.config.ProgressionConfig)

return function()
	describe("MasteryStars", function()
		local mastery = ProgressionConfig.Mastery

		it("should award 0 stars when every criterion misses its threshold", function()
			local stars = MasteryStars.calculate(
				mastery.StyleScoreThreshold - 1,
				mastery.MaxDamageTakenForStar + 1,
				mastery.ClearTimeThresholdSeconds + 1
			)
			expect(stars).to.equal(0)
		end)

		it("should award 3 stars when every criterion exactly meets its threshold (boundary)", function()
			local stars = MasteryStars.calculate(
				mastery.StyleScoreThreshold,
				mastery.MaxDamageTakenForStar,
				mastery.ClearTimeThresholdSeconds
			)
			expect(stars).to.equal(3)
		end)

		it("should award exactly 1 star for a Style-only clear", function()
			local stars = MasteryStars.calculate(
				mastery.StyleScoreThreshold + 100,
				mastery.MaxDamageTakenForStar + 1,
				mastery.ClearTimeThresholdSeconds + 1
			)
			expect(stars).to.equal(1)
		end)

		it("should award exactly 2 stars for Survival + Speed but not Style", function()
			local stars = MasteryStars.calculate(
				mastery.StyleScoreThreshold - 1,
				mastery.MaxDamageTakenForStar,
				mastery.ClearTimeThresholdSeconds
			)
			expect(stars).to.equal(2)
		end)

		it("should reject a criterion one unit past its threshold", function()
			local stars = MasteryStars.calculate(
				mastery.StyleScoreThreshold,
				mastery.MaxDamageTakenForStar + 1,
				mastery.ClearTimeThresholdSeconds
			)
			expect(stars).to.equal(2)
		end)
	end)
end
