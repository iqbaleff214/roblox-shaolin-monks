local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LootConfig = require(ReplicatedStorage.Shared.config.LootConfig)

local EXPECTED_CONTAINERS = { "WoodenCrate", "ClayUrn", "SupplyBarrel", "JadeChest" }
local EXPECTED_CHEST_TIERS = { "Arena", "Chapter", "Boss", "Vault" }
local EXPECTED_RARITIES = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }

return function()
	describe("LootConfig", function()
		it("should define all 4 container types from §10.2", function()
			for _, id in EXPECTED_CONTAINERS do
				local container = LootConfig.Containers[id]
				expect(container).to.be.a("table")
				expect(container.Hits).to.be.a("number")
				expect(container.Hits > 0).to.equal(true)
				expect(container.DropTable).to.be.a("string")
			end
		end)

		it("should mark JadeChest as hidden per §3.8", function()
			expect(LootConfig.Containers.JadeChest.Hidden).to.equal(true)
		end)

		it("should define all 4 chest tiers from §10.4", function()
			for _, tier in EXPECTED_CHEST_TIERS do
				expect(LootConfig.ChestRarityWeights[tier]).to.be.a("table")
			end
		end)

		it("should sum every ChestRarityWeights row to exactly 100 (published odds, §10.4)", function()
			for _, weights in LootConfig.ChestRarityWeights do
				local total = 0
				for _, weight in weights do
					total += weight
				end
				expect(total).to.equal(100)
			end
		end)

		it("should define a valid ContainerDrops entry for all 4 container types (§10.2)", function()
			for _, id in EXPECTED_CONTAINERS do
				local drop = LootConfig.ContainerDrops[id]
				expect(drop).to.be.a("table")
				expect(drop.CoinsMin).to.be.a("number")
				expect(drop.CoinsMax).to.be.a("number")
				expect(drop.CoinsMax >= drop.CoinsMin).to.equal(true)
			end
		end)

		it("should give JadeChest a guaranteed relic drop per §3.8/§10.2", function()
			expect(LootConfig.ContainerDrops.JadeChest.GuaranteedDrop).to.equal("Relic")
		end)

		it("should keep every BonusDrop chance within (0, 1]", function()
			for _, drop in LootConfig.ContainerDrops do
				if drop.BonusDrop then
					expect(drop.BonusDrop.Chance > 0 and drop.BonusDrop.Chance <= 1).to.equal(true)
				end
			end
		end)

		it("should define a positive Coin range for every EnemyConfig role", function()
			for _, range in LootConfig.EnemyKillCoins do
				expect(range.Min > 0).to.equal(true)
				expect(range.Max >= range.Min).to.equal(true)
			end
		end)

		it("should define positive OrbRestoreAmounts for HealthOrb and ChiOrb", function()
			expect(LootConfig.OrbRestoreAmounts.HealthOrb > 0).to.equal(true)
			expect(LootConfig.OrbRestoreAmounts.ChiOrb > 0).to.equal(true)
		end)

		it("should define a positive DuplicateConversionRate for every rarity tier, increasing with rarity", function()
			local previous = 0
			for _, rarity in EXPECTED_RARITIES do
				local rate = LootConfig.DuplicateConversionRate[rarity]
				expect(rate > previous).to.equal(true)
				previous = rate
			end
		end)
	end)
end
