-- GDD §14.2 / §3.2-3.9. Base combat tuning shared by every weapon (WeaponConfig
-- multiplies these), every enemy (EnemyConfig), and the client/server combat
-- systems (Phase 3). No gameplay script should hardcode these values directly.

return {
	Attacks = {
		LightDamage = 8,
		HeavyDamage = 20,
		ComboWindow = 0.6, -- seconds to chain the next input
		ParryWindow = 0.15, -- seconds before impact for a perfect parry
		DodgeIFrames = 0.2, -- seconds of invulnerability during a dodge roll
		DodgeCooldown = 0.8,
	},
	Poise = {
		StaggerThreshold = 100,
		PoiseDecayPerSec = 5, -- poise bar drains if the enemy isn't hit
	},
	ChiMeter = {
		Max = 100,
		GainPerHitDealt = 4,
		GainPerHitTaken = 6,
	},
}
