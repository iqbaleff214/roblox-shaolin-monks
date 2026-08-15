-- GDD §14.3 / §4. Enemy role stats and AI tuning shared by every faction
-- reskin (§4.6) — factions are Studio-side asset swaps over these same roles,
-- never separate config entries or code paths (see EnemyController, T-060).

return {
	ConcurrentAttackerCap = 3, -- §4.3/§4.4: only 2-3 enemies attack at once
	AggroRadius = 24, -- studs
	AttackTelegraph = 0.4, -- seconds of windup before a hit lands
	AttackCooldown = 1.5, -- §4.4: seconds between one enemy's own attacks

	-- §4.3 "ring" behavior: enemies without an attacker token orbit the
	-- player at this radius/speed instead of idling.
	CirclingRadius = 10, -- studs
	CirclingSpeed = 6, -- studs/s

	-- §3.9: a non-boss Staggered enemy that never receives a Finishing Move
	-- recovers on its own after this long, rather than freezing forever.
	StaggerRecoveryDuration = 4, -- seconds

	-- §4.5: boss/Elite phase-transition tuning, shared by both (Elites use a
	-- condensed 1-phase configuration of the same mechanism).
	Boss = {
		PhaseTransitionInvulnerableDuration = 2, -- seconds, no damage accepted mid-transition
		CounterWindowDuration = 1, -- seconds the grab-counter window stays open per phase
		ParryPunishWindowDuration = 1, -- seconds the parry-punish window stays open per phase
	},

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
