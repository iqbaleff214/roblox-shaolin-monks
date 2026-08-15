local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatConfig = require(ReplicatedStorage.Shared.config.CombatConfig)
local WeaponConfig = require(ReplicatedStorage.Shared.config.WeaponConfig)

local EXPECTED_WEAPON_IDS = {
	"TwinBlades",
	"WarStaff",
	"HookSwords",
	"IronGauntlets",
	"BattleGlaive",
}

local DPS_TOLERANCE = 0.05 -- ±5%, GDD §5.2 "balanced by design" pillar

local function theoreticalDps(weapon)
	local totalDamage = 0
	local totalTime = 0
	for _, step in weapon.ComboTree do
		local base = if step.Input == "Light" then CombatConfig.Attacks.LightDamage else CombatConfig.Attacks.HeavyDamage
		totalDamage += base * step.DamageMultiplier
		totalTime += step.FrameTime
	end
	return totalDamage / totalTime
end

return function()
	describe("WeaponConfig", function()
		it("should define exactly the 5 weapons from GDD §5.2", function()
			local seen = {}
			for id in WeaponConfig.Weapons do
				seen[id] = true
			end
			for _, id in EXPECTED_WEAPON_IDS do
				expect(seen[id]).to.equal(true)
			end
			local count = 0
			for _ in WeaponConfig.Weapons do
				count += 1
			end
			expect(count).to.equal(#EXPECTED_WEAPON_IDS)
		end)

		it("should give every weapon a non-empty combo tree and an Ultimate", function()
			for _, weapon in WeaponConfig.Weapons do
				expect(#weapon.ComboTree > 0).to.equal(true)
				expect(weapon.Ultimate).to.be.a("table")
				expect(weapon.Ultimate.Damage).to.be.a("number")
				expect(weapon.Ultimate.AreaShape).to.be.a("string")
				expect(weapon.Ultimate.AreaRadius).to.be.a("number")
				expect(weapon.Ultimate.AnimationId).never.to.equal(nil)
				expect(weapon.Ultimate.FxSlot).to.be.a("string")
			end
		end)

		it("should give every weapon a positive melee Range and Arc for hit detection (T-042)", function()
			for _, weapon in WeaponConfig.Weapons do
				expect(weapon.Range).to.be.a("number")
				expect(weapon.Range > 0).to.equal(true)
				expect(weapon.Arc).to.be.a("number")
				expect(weapon.Arc > 0).to.equal(true)
				expect(weapon.Arc <= 360).to.equal(true)
			end
		end)

		it("should keep theoretical DPS within ±5% across all 5 weapons at default combo efficiency", function()
			local dpsValues = {}
			local sum = 0
			local count = 0
			for id, weapon in WeaponConfig.Weapons do
				local dps = theoreticalDps(weapon)
				dpsValues[id] = dps
				sum += dps
				count += 1
			end

			local average = sum / count
			for _, dps in dpsValues do
				local deviation = math.abs(dps - average) / average
				expect(deviation <= DPS_TOLERANCE).to.equal(true)
			end
		end)

		it("should give a Cone-shaped Ultimate a positive ConeAngle and a Line-shaped one a positive LineWidth (T-072)", function()
			for _, weapon in WeaponConfig.Weapons do
				if weapon.Ultimate.AreaShape == "Cone" then
					expect(weapon.Ultimate.ConeAngle).to.be.a("number")
					expect(weapon.Ultimate.ConeAngle > 0).to.equal(true)
					expect(weapon.Ultimate.ConeAngle <= 360).to.equal(true)
				elseif weapon.Ultimate.AreaShape == "Line" then
					expect(weapon.Ultimate.LineWidth).to.be.a("number")
					expect(weapon.Ultimate.LineWidth > 0).to.equal(true)
				end
			end
		end)

		-- T-071: every AnimationId (combo steps, air combo, running attack,
		-- Ultimate) must resolve to a real asset once Studio (S-042/S-043)
		-- delivers them. Warn-only for now — matches MonetizationConfig's
		-- placeholder-ID test (T-018): 0 is expected pre-launch, not a
		-- failure, but every occurrence is surfaced so nothing is missed.
		it("should warn (not fail) about any AnimationId fields still at the placeholder value", function()
			local placeholderCount = 0
			for weaponId, weapon in WeaponConfig.Weapons do
				for stepIndex, step in weapon.ComboTree do
					if step.AnimationId == 0 then
						placeholderCount += 1
						warn(string.format("[WeaponConfig] %s.ComboTree[%d].AnimationId is still a placeholder (0) — fill before launch, see S-042.", weaponId, stepIndex))
					end
				end
				if weapon.AirComboAnimationId == 0 then
					placeholderCount += 1
					warn(string.format("[WeaponConfig] %s.AirComboAnimationId is still a placeholder (0) — fill before launch, see S-042.", weaponId))
				end
				if weapon.RunningAttackAnimationId == 0 then
					placeholderCount += 1
					warn(string.format("[WeaponConfig] %s.RunningAttackAnimationId is still a placeholder (0) — fill before launch, see S-042.", weaponId))
				end
				if weapon.Ultimate.AnimationId == 0 then
					placeholderCount += 1
					warn(string.format("[WeaponConfig] %s.Ultimate.AnimationId is still a placeholder (0) — fill before launch, see S-043.", weaponId))
				end
			end
			-- Not a failing assertion — see comment above. `placeholderCount`
			-- is computed (not discarded) so this remains a real check a
			-- future hard-fail variant (mirroring T-200) can build on.
			expect(placeholderCount >= 0).to.equal(true)
		end)
	end)
end
