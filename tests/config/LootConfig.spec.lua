local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LootConfig = require(ReplicatedStorage.Shared.config.LootConfig)

local EXPECTED_CONTAINERS = { "WoodenCrate", "ClayUrn", "SupplyBarrel", "JadeChest" }
local EXPECTED_CHEST_TIERS = { "Arena", "Chapter", "Boss", "Vault" }

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
	end)
end
