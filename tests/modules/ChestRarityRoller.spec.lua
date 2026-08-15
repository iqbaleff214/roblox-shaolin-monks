local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ChestRarityRoller = require(ReplicatedStorage.Shared.modules.ChestRarityRoller)
local LootConfig = require(ReplicatedStorage.Shared.config.LootConfig)

return function()
	describe("ChestRarityRoller", function()
		it("should return nil for an unknown chest tier instead of erroring", function()
			expect(ChestRarityRoller.roll(1, "NotATier")).to.equal(nil)
		end)

		it("should be deterministic for the same seed", function()
			expect(ChestRarityRoller.roll(777, "Arena")).to.equal(ChestRarityRoller.roll(777, "Arena"))
		end)

		it("should match the published Arena Chest weights within ~2% over 10,000 rolls (T-102 test case)", function()
			local counts = { Common = 0, Uncommon = 0, Rare = 0, Epic = 0, Legendary = 0 }
			local sampleSize = 10000
			for seed = 1, sampleSize do
				local rarity = ChestRarityRoller.roll(seed, "Arena")
				counts[rarity] += 1
			end

			for rarity, weight in LootConfig.ChestRarityWeights.Arena do
				local observedPercent = (counts[rarity] / sampleSize) * 100
				expect(math.abs(observedPercent - weight) < 2).to.equal(true)
			end
		end)

		it("should only ever return one of the 5 published rarities for every tier", function()
			local validRarities = { Common = true, Uncommon = true, Rare = true, Epic = true, Legendary = true }
			for tier in LootConfig.ChestRarityWeights do
				for seed = 1, 20 do
					local rarity = ChestRarityRoller.roll(seed, tier)
					expect(validRarities[rarity]).to.equal(true)
				end
			end
		end)
	end)
end
