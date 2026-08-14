-- GDD §14.3 / §4. Enemy role stats and AI tuning shared by every faction
-- reskin (§4.6) — factions are Studio-side asset swaps over these same roles,
-- never separate config entries or code paths (see EnemyController, T-060).

return {
	ConcurrentAttackerCap = 3, -- §4.3/§4.4: only 2-3 enemies attack at once
	AggroRadius = 24, -- studs
	AttackTelegraph = 0.4, -- seconds of windup before a hit lands

	Roles = {
		Grunt = { Health = 40, Damage = 6, Poise = 20 },
		Soldier = { Health = 60, Damage = 8, Poise = 40, Blocks = true },
		Heavy = { Health = 120, Damage = 16, Poise = 90 },
		Ranged = { Health = 35, Damage = 10, Poise = 15, AttackRange = 30 },
		Assassin = { Health = 30, Damage = 9, Poise = 15, MoveSpeedMult = 1.4 },
		Elite = { Health = 300, Damage = 18, Poise = 200, UltimateAttack = true },
		-- GDD §14.3's example shape omits Boss, but §4.2 requires one; reuses
		-- the same Poise-gated state machine as Elite with Phases added (§4.5).
		Boss = { Health = 1500, Damage = 22, Poise = 400, Phases = 3 },
	},
}
