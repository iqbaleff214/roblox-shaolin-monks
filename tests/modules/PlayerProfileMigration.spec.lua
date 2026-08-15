local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerProfileMigration = require(ReplicatedStorage.Shared.modules.PlayerProfileMigration)

return function()
	describe("PlayerProfileMigration", function()
		it("should return a complete default profile for a brand-new player (nil saved data)", function()
			local profile = PlayerProfileMigration.migrate(nil)
			expect(profile.SchemaVersion).to.equal(PlayerProfileMigration.CURRENT_SCHEMA_VERSION)
			expect(profile.Level).to.equal(0)
			expect(profile.Coins).to.equal(0)
			expect(profile.Inventory).to.be.a("table")
		end)

		it("should preserve existing fields from a saved payload", function()
			local profile = PlayerProfileMigration.migrate({ Level = 12, Coins = 500 })
			expect(profile.Level).to.equal(12)
			expect(profile.Coins).to.equal(500)
		end)

		it("should safe-default a field missing from an older save without erroring (T-163 test case)", function()
			-- Simulates a save written before BattlePassTierXP existed.
			local oldSave = { Level = 5, TotalXP = 400, Coins = 200, Jade = 10 }
			local profile = PlayerProfileMigration.migrate(oldSave)
			expect(profile.Level).to.equal(5)
			expect(profile.BattlePassTierXP).to.equal(0)
			expect(profile.MasteryStars).to.be.a("table")
			expect(profile.SchemaVersion).to.equal(PlayerProfileMigration.CURRENT_SCHEMA_VERSION)
		end)

		it("should drop unknown fields from a foreign/corrupted payload rather than carrying them forward", function()
			local profile = PlayerProfileMigration.migrate({ Level = 3, SomeRemovedField = "junk" })
			expect((profile :: any).SomeRemovedField).to.equal(nil)
		end)

		it("should never share a nested default table reference across separate calls", function()
			local profileA = PlayerProfileMigration.migrate(nil)
			local profileB = PlayerProfileMigration.migrate(nil)
			profileA.Inventory.Accessory = { HeadMonkHood = true }
			expect(profileB.Inventory.Accessory).to.equal(nil)
		end)

		it("should always stamp the current schema version even on a versioned old save", function()
			local profile = PlayerProfileMigration.migrate({ SchemaVersion = 0, Level = 1 })
			expect(profile.SchemaVersion).to.equal(PlayerProfileMigration.CURRENT_SCHEMA_VERSION)
		end)
	end)
end
