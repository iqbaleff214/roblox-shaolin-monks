local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BattlePassTierCurve = require(ReplicatedStorage.Shared.modules.BattlePassTierCurve)

return function()
	describe("BattlePassTierCurve", function()
		it("should be tier 0 at 0 XP", function()
			expect(BattlePassTierCurve.tierForXP(0, 200, 50)).to.equal(0)
		end)

		it("should reach a tier exactly at its threshold, not one XP before", function()
			expect(BattlePassTierCurve.tierForXP(399, 200, 50)).to.equal(1)
			expect(BattlePassTierCurve.tierForXP(400, 200, 50)).to.equal(2)
		end)

		it("should clamp at TierCount even with far more XP than needed", function()
			expect(BattlePassTierCurve.tierForXP(1000000, 200, 50)).to.equal(50)
		end)

		it("should be monotonically non-decreasing as XP grows", function()
			local previous = 0
			for xp = 0, 20000, 100 do
				local tier = BattlePassTierCurve.tierForXP(xp, 200, 50)
				expect(tier >= previous).to.equal(true)
				previous = tier
			end
		end)
	end)
end
