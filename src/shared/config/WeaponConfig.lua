-- GDD §5.2 / §3.5-3.6. One entry per Main Weapon: a combo string (each step
-- multiplies CombatConfig's base Light/Heavy damage, so tuning base damage
-- tunes every weapon at once) and an Ultimate Technique.
--
-- Balance rule (§5.2 "balanced by design" pillar): theoretical DPS at default
-- combo efficiency must stay within a tight tolerance across all 5 weapons —
-- see WeaponConfig.spec.lua, which computes it from this data. FrameTime is
-- the per-step animation+recovery time budget; it is the tuning knob used to
-- keep DPS aligned while DamageMultiplier expresses each weapon's flavor
-- (Iron Gauntlets hits harder per swing but is slower; Twin Blades is the
-- opposite).

local CombatConfig = require(script.Parent.CombatConfig)

local LIGHT_DAMAGE = CombatConfig.Attacks.LightDamage
local HEAVY_DAMAGE = CombatConfig.Attacks.HeavyDamage

-- Every weapon's base combo string is 3 Light hits into a Heavy finisher,
-- matching the shared "playstyle, not power" design pillar.
local function comboString(lightMultiplier: number, lightFrameTime: number, heavyMultiplier: number, heavyFrameTime: number)
	return {
		{ Input = "Light", DamageMultiplier = lightMultiplier, FrameTime = lightFrameTime, AnimationId = 0 },
		{ Input = "Light", DamageMultiplier = lightMultiplier, FrameTime = lightFrameTime, AnimationId = 0 },
		{ Input = "Light", DamageMultiplier = lightMultiplier, FrameTime = lightFrameTime, AnimationId = 0 },
		{ Input = "Heavy", DamageMultiplier = heavyMultiplier, FrameTime = heavyFrameTime, AnimationId = 0 },
	}
end

return {
	BaseDamage = {
		Light = LIGHT_DAMAGE,
		Heavy = HEAVY_DAMAGE,
	},

	AirComboDamageMultiplier = 0.85, -- air-combo hits deal slightly less than grounded (§3.2)
	RunningAttackDamageMultiplier = 1.1, -- running attack rewards closing distance (§3.2)

	Weapons = {
		TwinBlades = {
			DisplayName = "Twin Blades",
			Range = 6, -- studs; §5.2 "low-reach"
			Arc = 60, -- degrees, full swing arc centered on the attacker's facing
			ComboTree = comboString(0.9, 0.32, 1.3, 0.63),
			AirComboAnimationId = 0,
			RunningAttackAnimationId = 0,
			Ultimate = {
				Name = "Whirlwind Strike",
				Damage = 60,
				AreaShape = "Circle",
				AreaRadius = 12,
				AnimationId = 0,
				FxSlot = "UltimateFx_TwinBlades",
			},
		},
		WarStaff = {
			DisplayName = "War Staff",
			Range = 9, -- studs; §5.2 "medium reach"
			Arc = 70,
			ComboTree = comboString(1.0, 0.37, 1.6, 0.75),
			AirComboAnimationId = 0,
			RunningAttackAnimationId = 0,
			Ultimate = {
				Name = "Heaven's Sweep",
				Damage = 70,
				AreaShape = "Cone",
				AreaRadius = 16,
				ConeAngle = 100, -- degrees, full cone angle (Cone-shape-only field)
				AnimationId = 0,
				FxSlot = "UltimateFx_WarStaff",
			},
		},
		HookSwords = {
			DisplayName = "Hook Swords",
			Range = 8, -- studs; chain-grapple pulls enemies into medium reach
			Arc = 60,
			ComboTree = comboString(1.0, 0.35, 1.4, 0.69),
			AirComboAnimationId = 0,
			RunningAttackAnimationId = 0,
			Ultimate = {
				Name = "Serpent's Coil",
				Damage = 55,
				AreaShape = "Circle",
				AreaRadius = 14,
				AnimationId = 0,
				FxSlot = "UltimateFx_HookSwords",
			},
		},
		IronGauntlets = {
			DisplayName = "Iron Gauntlets",
			Range = 5, -- studs; §5.2 close-range, highest poise damage
			Arc = 50,
			ComboTree = comboString(1.2, 0.43, 1.8, 0.86),
			AirComboAnimationId = 0,
			RunningAttackAnimationId = 0,
			Ultimate = {
				Name = "Mountain Breaker",
				Damage = 90,
				AreaShape = "Circle",
				AreaRadius = 10,
				AnimationId = 0,
				FxSlot = "UltimateFx_IronGauntlets",
			},
		},
		BattleGlaive = {
			DisplayName = "Battle Glaive",
			Range = 12, -- studs; §5.2 "longest reach"
			Arc = 80, -- arcing sweeps
			ComboTree = comboString(1.05, 0.37, 1.5, 0.74),
			AirComboAnimationId = 0,
			RunningAttackAnimationId = 0,
			Ultimate = {
				Name = "Dragon's Arc",
				Damage = 65,
				AreaShape = "Line",
				AreaRadius = 20, -- travel length for the Line shape
				LineWidth = 6, -- studs, perpendicular hit width (Line-shape-only field)
				AnimationId = 0,
				FxSlot = "UltimateFx_BattleGlaive",
			},
		},
	},
}
