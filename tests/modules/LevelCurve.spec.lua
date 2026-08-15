local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LevelCurve = require(ReplicatedStorage.Shared.modules.LevelCurve)
local ProgressionConfig = require(ReplicatedStorage.Shared.config.ProgressionConfig)

return function()
	describe("LevelCurve", function()
		it("should start a fresh player (0 XP) at Level 0", function()
			expect(LevelCurve.levelForXP(0)).to.equal(0)
		end)

		it("should reach Level 1 exactly at its threshold, not one XP before", function()
			local threshold = ProgressionConfig.XP.ThresholdForLevel(1)
			expect(LevelCurve.levelForXP(threshold - 1)).to.equal(0)
			expect(LevelCurve.levelForXP(threshold)).to.equal(1)
		end)

		it("should be monotonically non-decreasing as XP grows", function()
			local previousLevel = 0
			for xp = 0, 20000, 500 do
				local level = LevelCurve.levelForXP(xp)
				expect(level >= previousLevel).to.equal(true)
				previousLevel = level
			end
		end)

		it("should report xpForNextLevel matching the config threshold one level up", function()
			expect(LevelCurve.xpForNextLevel(4)).to.equal(ProgressionConfig.XP.ThresholdForLevel(5))
		end)
	end)
end
