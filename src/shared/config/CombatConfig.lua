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

	-- §3.1: movement/traversal tuning (Phase 2). Kept here rather than a new
	-- config file since Phase 1 closed the config domain list at 12 files
	-- (§14.1/§14.6) and movement is combat-adjacent, not its own domain.
	Movement = {
		WalkSpeed = 16, -- studs/s
		JumpPower = 50, -- studs/s upward velocity on the first jump

		DoubleJump = {
			Impulse = 45, -- studs/s upward velocity applied on the air-jump
		},

		WallRun = {
			MinEntrySpeed = 10, -- studs/s of lateral speed required to start a wall-run
			Duration = 1.2, -- seconds before forced detach
			Speed = 20, -- studs/s of travel along the wall
			GravityScale = 0.15, -- fraction of normal gravity while wall-running
		},

		LedgeGrab = {
			DetectionDistance = 3, -- studs, forward raycast reach
			DetectionHeight = 4, -- studs, vertical span checked above the wall hit for a clear ledge lip
			ClimbDuration = 0.5, -- seconds for the climb-up motion
		},

		DodgeRoll = {
			Distance = 10, -- studs covered by a single dodge roll
		},
	},
}
