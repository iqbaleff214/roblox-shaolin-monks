local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MonetizationConfig = require(ReplicatedStorage.Shared.config.MonetizationConfig)

return function()
	describe("MonetizationConfig", function()
		it("should never allow Coins to convert to Jade (§11.1 one-way economy)", function()
			expect(MonetizationConfig.CoinToJadeRate).to.equal(nil)
		end)

		it("should match the §14.5 shape: GamePasses, 3 JadeProducts, VIP boosts", function()
			expect(MonetizationConfig.GamePasses.VIPPassId).never.to.equal(nil)
			expect(MonetizationConfig.GamePasses.BattlePassId).never.to.equal(nil)
			expect(#MonetizationConfig.JadeProducts).to.equal(3)
			expect(MonetizationConfig.VIPBoostXP).to.equal(0.25)
			expect(MonetizationConfig.VIPBoostCoins).to.equal(0.25)
		end)

		it("should give every JadeProduct a positive Jade amount and Robux price", function()
			for _, product in MonetizationConfig.JadeProducts do
				expect(product.Jade > 0).to.equal(true)
				expect(product.Robux > 0).to.equal(true)
			end
		end)

		-- §17.6 pre-launch checklist: placeholder 0 IDs are expected pre-launch
		-- and only warned about here. T-200's startup assertion is the hard
		-- failure gate right before publish, not this schema test.
		it("should warn (not fail) about any placeholder 0 IDs still present", function()
			if MonetizationConfig.GamePasses.VIPPassId == 0 then
				warn("[MonetizationConfig] VIPPassId is still a placeholder (0) — fill before launch, see S-080/T-200.")
			end
			if MonetizationConfig.GamePasses.BattlePassId == 0 then
				warn("[MonetizationConfig] BattlePassId is still a placeholder (0) — fill before launch, see S-081/T-200.")
			end
			for index, product in MonetizationConfig.JadeProducts do
				if product.ProductId == 0 then
					warn(string.format("[MonetizationConfig] JadeProducts[%d].ProductId is still a placeholder (0) — fill before launch, see S-082/T-200.", index))
				end
			end
		end)
	end)
end
