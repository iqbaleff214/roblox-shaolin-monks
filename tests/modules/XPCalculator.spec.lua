local ReplicatedStorage = game:GetService("ReplicatedStorage")

local XPCalculator = require(ReplicatedStorage.Shared.modules.XPCalculator)

return function()
	describe("XPCalculator", function()
		it("should classify a no-damage, no-death clear as Flawless", function()
			expect(XPCalculator.classifyPerformance({ TookDamage = false, Deaths = 0, HadHighComboAverage = false })).to.equal("Flawless")
		end)

		it("should classify 2+ deaths as MultipleDeaths even with a high combo", function()
			expect(XPCalculator.classifyPerformance({ TookDamage = true, Deaths = 2, HadHighComboAverage = true })).to.equal("MultipleDeaths")
		end)

		it("should classify a single death without high combo as Standard", function()
			expect(XPCalculator.classifyPerformance({ TookDamage = true, Deaths = 1, HadHighComboAverage = false })).to.equal("Standard")
		end)

		it("should classify a damaged-but-high-combo clear as HighCombo", function()
			expect(XPCalculator.classifyPerformance({ TookDamage = true, Deaths = 0, HadHighComboAverage = true })).to.equal("HighCombo")
		end)

		it("should produce a Flawless-to-MultipleDeaths XP ratio matching the 2.5x/0.5x table (T-090 test case)", function()
			local flawlessXP = XPCalculator.computeXP("Adept", "Flawless")
			local multiDeathXP = XPCalculator.computeXP("Adept", "MultipleDeaths")
			expect(flawlessXP / multiDeathXP).to.be.near(5, 0.0001)
		end)

		it("should scale linearly with the difficulty multiplier", function()
			local novice = XPCalculator.computeXP("Novice", "Standard")
			local master = XPCalculator.computeXP("Master", "Standard")
			expect(master / novice).to.be.near(2.0, 0.0001)
		end)
	end)
end
