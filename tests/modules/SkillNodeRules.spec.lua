local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SkillNodeRules = require(ReplicatedStorage.Shared.modules.SkillNodeRules)
local ProgressionConfig = require(ReplicatedStorage.Shared.config.ProgressionConfig)

return function()
	describe("SkillNodeRules", function()
		it("should cap HealthGrowth/ChiGrowth at ProgressionConfig's MaxRankLevel", function()
			expect(SkillNodeRules.maxRank("HealthGrowth")).to.equal(ProgressionConfig.StatGrowth.MaxRankLevel)
			expect(SkillNodeRules.maxRank("ChiGrowth")).to.equal(ProgressionConfig.StatGrowth.MaxRankLevel)
		end)

		it("should cap every other node at a single rank", function()
			for node in ProgressionConfig.SkillPoints.NodeCosts do
				if node ~= "HealthGrowth" and node ~= "ChiGrowth" then
					expect(SkillNodeRules.maxRank(node)).to.equal(1)
				end
			end
		end)

		it("should reject a capped stat node purchase at/beyond its max rank (T-091 test case)", function()
			local maxRank = ProgressionConfig.StatGrowth.MaxRankLevel
			expect(SkillNodeRules.canPurchase("HealthGrowth", maxRank - 1)).to.equal(true)
			expect(SkillNodeRules.canPurchase("HealthGrowth", maxRank)).to.equal(false)
			expect(SkillNodeRules.canPurchase("HealthGrowth", maxRank + 5)).to.equal(false)
		end)

		it("should reject a second purchase of a single-rank node", function()
			expect(SkillNodeRules.canPurchase("DoubleJump", 0)).to.equal(true)
			expect(SkillNodeRules.canPurchase("DoubleJump", 1)).to.equal(false)
		end)
	end)
end
