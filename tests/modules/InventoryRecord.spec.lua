local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryRecord = require(ReplicatedStorage.Shared.modules.InventoryRecord)

return function()
	describe("InventoryRecord", function()
		it("should grant a new item and report it as owned", function()
			local inventory = InventoryRecord.new()
			local granted, wasDuplicate = inventory:grant("Accessory", "HeadMonkHood", 0)
			expect(granted).to.equal(true)
			expect(wasDuplicate).to.equal(false)
			expect(inventory:isOwned("Accessory", "HeadMonkHood")).to.equal(true)
		end)

		it("should route a second grant of the same item through the duplicate path, not a second entry (T-081 test case)", function()
			local inventory = InventoryRecord.new()
			inventory:grant("Accessory", "HeadMonkHood", 0)
			local granted, wasDuplicate = inventory:grant("Accessory", "HeadMonkHood", 10)

			expect(granted).to.equal(false)
			expect(wasDuplicate).to.equal(true)

			local entry = inventory:getEntry("Accessory", "HeadMonkHood")
			expect(entry).never.to.equal(nil)
			expect((entry :: any).duplicatesReceived).to.equal(1)
			expect((entry :: any).acquiredAt).to.equal(0) -- unchanged by the duplicate grant
		end)

		it("should accumulate duplicatesReceived across repeated grants", function()
			local inventory = InventoryRecord.new()
			inventory:grant("Emote", "Bow", 0)
			inventory:grant("Emote", "Bow", 1)
			inventory:grant("Emote", "Bow", 2)
			local entry = inventory:getEntry("Emote", "Bow")
			expect((entry :: any).duplicatesReceived).to.equal(2)
		end)

		it("should keep categories independent (same itemId in different categories doesn't collide)", function()
			local inventory = InventoryRecord.new()
			inventory:grant("WeaponSkin", "Jade", 0)
			expect(inventory:isOwned("WeaponSkin", "Jade")).to.equal(true)
			expect(inventory:isOwned("UltimateFxSkin", "Jade")).to.equal(false)
		end)

		it("should report unowned items as not owned and return nil for their entry", function()
			local inventory = InventoryRecord.new()
			expect(inventory:isOwned("Accessory", "Nonexistent")).to.equal(false)
			expect(inventory:getEntry("Accessory", "Nonexistent")).to.equal(nil)
		end)
	end)
end
