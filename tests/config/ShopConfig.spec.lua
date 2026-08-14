local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopConfig = require(ReplicatedStorage.Shared.config.ShopConfig)
local WeaponConfig = require(ReplicatedStorage.Shared.config.WeaponConfig)

return function()
	describe("ShopConfig", function()
		it("should price every Combo Scroll in Coins, never Jade (§10.3 hard rule)", function()
			expect(#ShopConfig.ComboScrolls > 0).to.equal(true)
			for _, scroll in ShopConfig.ComboScrolls do
				expect(scroll.Currency).to.equal("Coins")
			end
		end)

		it("should reference a valid weapon for every Combo Scroll", function()
			for _, scroll in ShopConfig.ComboScrolls do
				expect(WeaponConfig.Weapons[scroll.WeaponId]).to.be.a("table")
			end
		end)

		it("should cover a Combo Scroll for all 5 weapons", function()
			local seen = {}
			for _, scroll in ShopConfig.ComboScrolls do
				seen[scroll.WeaponId] = true
			end
			for weaponId in WeaponConfig.Weapons do
				expect(seen[weaponId]).to.equal(true)
			end
		end)

		it("should price every cosmetic in Coins or Jade only", function()
			for _, item in ShopConfig.Cosmetics do
				expect(item.Currency == "Coins" or item.Currency == "Jade").to.equal(true)
				expect(item.Price > 0).to.equal(true)
			end
		end)

		it("should only bundle item Ids that exist in the Cosmetics catalog", function()
			local cosmeticIds = {}
			for _, item in ShopConfig.Cosmetics do
				cosmeticIds[item.Id] = true
			end
			for _, bundle in ShopConfig.Bundles do
				for _, contentId in bundle.Contents do
					expect(cosmeticIds[contentId]).to.equal(true)
				end
			end
		end)
	end)
end
