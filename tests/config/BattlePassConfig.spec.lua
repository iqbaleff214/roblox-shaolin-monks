local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BattlePassConfig = require(ReplicatedStorage.Shared.config.BattlePassConfig)

return function()
	describe("BattlePassConfig", function()
		it("should define exactly 50 tiers (§11.4)", function()
			expect(BattlePassConfig.TierCount).to.equal(50)
		end)

		it("should have exactly TierCount entries in each reward track", function()
			local freeCount = 0
			for _ in BattlePassConfig.FreeTrackRewards do
				freeCount += 1
			end
			local premiumCount = 0
			for _ in BattlePassConfig.PremiumTrackRewards do
				premiumCount += 1
			end
			expect(freeCount).to.equal(BattlePassConfig.TierCount)
			expect(premiumCount).to.equal(BattlePassConfig.TierCount)
		end)

		it("should define a positive XPPerTier", function()
			expect(BattlePassConfig.XPPerTier > 0).to.equal(true)
		end)

		it("should give every reward entry a valid Type", function()
			for tier = 1, BattlePassConfig.TierCount do
				expect(type(BattlePassConfig.FreeTrackRewards[tier].Type)).to.equal("string")
				expect(type(BattlePassConfig.PremiumTrackRewards[tier].Type)).to.equal("string")
			end
		end)

		it("should make every Premium tier at least as valuable in Coins as the matching Free tier where both grant Coins", function()
			for tier = 1, BattlePassConfig.TierCount do
				local free = BattlePassConfig.FreeTrackRewards[tier]
				local premium = BattlePassConfig.PremiumTrackRewards[tier]
				if free.Type == "Coins" and premium.Type == "Coins" then
					expect(premium.Amount >= free.Amount).to.equal(true)
				end
			end
		end)
	end)
end
