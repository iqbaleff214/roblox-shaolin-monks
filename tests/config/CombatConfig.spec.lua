local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatConfig = require(ReplicatedStorage.Shared.config.CombatConfig)

-- Exact key sets per §14.2 shape. Deliberately exhaustive so a typo/rename
-- (e.g. "ParryWindow" -> "ParyWindow") fails loudly instead of silently
-- reading nil at runtime.
local EXPECTED_SHAPE = {
	Attacks = { "LightDamage", "HeavyDamage", "ComboWindow", "ParryWindow", "DodgeIFrames", "DodgeCooldown", "BlockDamageReduction" },
	Poise = { "StaggerThreshold", "PoiseDecayPerSec" },
	ChiMeter = { "Max", "GainPerHitDealt", "GainPerHitTaken" },
	Disarm = { "ChanceOnHeavyVsBlocking", "VulnerableDuration" },
	Grapple = { "ThrowDamage", "HumanShieldHitCapacity" },
	WeaponPickup = { "ThrowDamage", "MeleeDamage", "MeleeSwings" },
}

-- §3.1 Movement is nested (sub-tables per mechanic), so it's checked
-- separately from the flat EXPECTED_SHAPE subtables above.
local EXPECTED_MOVEMENT_KEYS = { "WalkSpeed", "JumpPower", "DoubleJump", "WallRun", "LedgeGrab", "DodgeRoll" }

local function assertExactKeys(t, expectedKeys)
	local expectedSet = {}
	for _, key in expectedKeys do
		expectedSet[key] = true
		expect(t[key]).never.to.equal(nil)
	end
	for key in t do
		expect(expectedSet[key]).to.equal(true)
	end
end

return function()
	describe("CombatConfig", function()
		it("should expose exactly Attacks, Poise, ChiMeter, Movement, Disarm, Grapple, and WeaponPickup", function()
			local seen = {}
			for key in CombatConfig do
				seen[key] = true
			end
			expect(seen.Attacks).to.equal(true)
			expect(seen.Poise).to.equal(true)
			expect(seen.ChiMeter).to.equal(true)
			expect(seen.Movement).to.equal(true)
			expect(seen.Disarm).to.equal(true)
			expect(seen.Grapple).to.equal(true)
			expect(seen.WeaponPickup).to.equal(true)

			local count = 0
			for _ in CombatConfig do
				count += 1
			end
			expect(count).to.equal(7)
		end)

		it("should match the exact field set for each subtable (typo/rename guard)", function()
			for subtableName, expectedKeys in EXPECTED_SHAPE do
				assertExactKeys(CombatConfig[subtableName], expectedKeys)
			end
		end)

		it("should give every numeric field a valid (non-negative) value", function()
			for subtableName in EXPECTED_SHAPE do
				for _, value in CombatConfig[subtableName] do
					expect(type(value)).to.equal("number")
					expect(value >= 0).to.equal(true)
				end
			end
		end)

		it("should give damage and cap fields a strictly positive value", function()
			expect(CombatConfig.Attacks.LightDamage > 0).to.equal(true)
			expect(CombatConfig.Attacks.HeavyDamage > 0).to.equal(true)
			expect(CombatConfig.Poise.StaggerThreshold > 0).to.equal(true)
			expect(CombatConfig.ChiMeter.Max > 0).to.equal(true)
		end)

		it("should keep the disarm chance a valid probability (§3.5)", function()
			expect(CombatConfig.Disarm.ChanceOnHeavyVsBlocking >= 0).to.equal(true)
			expect(CombatConfig.Disarm.ChanceOnHeavyVsBlocking <= 1).to.equal(true)
		end)

		it("should keep block damage reduction a valid fraction (§3.3)", function()
			expect(CombatConfig.Attacks.BlockDamageReduction >= 0).to.equal(true)
			expect(CombatConfig.Attacks.BlockDamageReduction <= 1).to.equal(true)
		end)

		it("should match the exact top-level field set for Movement (typo/rename guard)", function()
			assertExactKeys(CombatConfig.Movement, EXPECTED_MOVEMENT_KEYS)
		end)

		it("should give every Movement leaf value a strictly positive number", function()
			local function assertAllPositiveNumbers(t)
				for _, value in t do
					if type(value) == "table" then
						assertAllPositiveNumbers(value)
					else
						expect(type(value)).to.equal("number")
						expect(value > 0).to.equal(true)
					end
				end
			end
			assertAllPositiveNumbers(CombatConfig.Movement)
		end)
	end)
end
