local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DropTableRoller = require(ReplicatedStorage.Shared.modules.DropTableRoller)

return function()
	describe("DropTableRoller", function()
		it("should reproduce an identical result when rolling the same seed twice (T-101 test case)", function()
			local firstRoll = DropTableRoller.rollContainerDrop(12345, "WoodenCrate")
			local secondRoll = DropTableRoller.rollContainerDrop(12345, "WoodenCrate")
			expect(firstRoll.coins).to.equal(secondRoll.coins)
			expect(firstRoll.bonusItem).to.equal(secondRoll.bonusItem)
		end)

		it("should keep container Coins within the configured Min/Max range", function()
			for seed = 1, 50 do
				local roll = DropTableRoller.rollContainerDrop(seed, "SupplyBarrel")
				expect(roll.coins >= 10 and roll.coins <= 20).to.equal(true)
			end
		end)

		it("should always attach JadeChest's guaranteed relic drop", function()
			local roll = DropTableRoller.rollContainerDrop(99, "JadeChest")
			expect(roll.guaranteedItem).to.equal("Relic")
		end)

		it("should return zeroed output for an unknown container type instead of erroring", function()
			local roll = DropTableRoller.rollContainerDrop(1, "NotAContainer")
			expect(roll.coins).to.equal(0)
			expect(roll.bonusItem).to.equal(nil)
		end)

		it("should reproduce an identical enemy-kill roll for the same seed", function()
			local firstRoll = DropTableRoller.rollEnemyKillDrop(555, "Boss")
			local secondRoll = DropTableRoller.rollEnemyKillDrop(555, "Boss")
			expect(firstRoll.coins).to.equal(secondRoll.coins)
		end)

		it("should keep enemy-kill Coins within the configured Min/Max range", function()
			for seed = 1, 50 do
				local roll = DropTableRoller.rollEnemyKillDrop(seed, "Grunt")
				expect(roll.coins >= 2 and roll.coins <= 4).to.equal(true)
			end
		end)

		it("should derive the same daily seed for two moments on the same UTC day", function()
			local seedA = DropTableRoller.dailySeed(0)
			local seedB = DropTableRoller.dailySeed(3600)
			expect(seedA).to.equal(seedB)
		end)
	end)
end
