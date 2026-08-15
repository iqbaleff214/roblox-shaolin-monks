local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CosmeticItemPicker = require(ReplicatedStorage.Shared.modules.CosmeticItemPicker)
local AccessoryConfig = require(ReplicatedStorage.Shared.config.AccessoryConfig)

return function()
	describe("CosmeticItemPicker", function()
		it("should only ever return an item whose Rarity matches the request", function()
			for seed = 1, 20 do
				local itemId = CosmeticItemPicker.pickAccessoryByRarity(seed, "Common")
				expect(itemId).to.be.a("string")
				expect(AccessoryConfig[itemId].Rarity).to.equal("Common")
			end
		end)

		it("should return nil for a rarity with no matching items instead of erroring", function()
			expect(CosmeticItemPicker.pickAccessoryByRarity(1, "NotARarity")).to.equal(nil)
		end)

		it("should be deterministic for the same seed", function()
			expect(CosmeticItemPicker.pickAccessoryByRarity(123, "Epic")).to.equal(CosmeticItemPicker.pickAccessoryByRarity(123, "Epic"))
		end)
	end)
end
