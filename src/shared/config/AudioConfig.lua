-- GDD §14.5 / §16. Every sound asset ID lives here — no IDs anywhere else in
-- code (§16 hard rule). Music/Ambient are keyed by the same chapter Ids as
-- ChapterConfig; AudioConfig.spec.lua cross-checks the two stay in sync.

local CHAPTER_IDS = {
	"TempleCourtyard",
	"BurningVillage",
	"BambooForest",
	"MountainPass",
	"AncientCatacombs",
	"SkyPagoda",
	"UnderworldGate",
	"WarlordsThrone",
}

local AudioConfig = {
	SFX = {
		LightAttack = { Id = 0, Volume = 0.7, PitchRange = { 0.95, 1.05 } },
		HeavyAttack = { Id = 0, Volume = 0.8, PitchRange = { 0.9, 1.0 } },
		Block = { Id = 0, Volume = 0.7 },
		PerfectParry = { Id = 0, Volume = 0.8 }, -- distinct "chime" variant, §16
		DodgeRoll = { Id = 0, Volume = 0.5 },
		FinishingMove = { Id = 0, Volume = 0.9 },
		ContainerBreakWood = { Id = 0, Volume = 0.7 },
		ContainerBreakClay = { Id = 0, Volume = 0.7 },
		ContainerBreakChest = { Id = 0, Volume = 0.8 },
		EnemyHit = { Id = 0, Volume = 0.6, PitchRange = { 0.9, 1.1 } },
		EnemyDeath = { Id = 0, Volume = 0.6 },
		BossPhaseTransition = { Id = 0, Volume = 0.9 },
		UltimateActivation = { Id = 0, Volume = 1.0 },
		ChiMeterFull = { Id = 0, Volume = 0.6 },
		ChapterComplete = { Id = 0, Volume = 1.0 },
		UIClick = { Id = 0, Volume = 0.5 },
	},

	Music = {
		Lobby = { Id = 0, Volume = 0.3, Looped = true },
	},

	-- §16: per-chapter ambient loop (temple wind, village fire crackle, etc.)
	Ambient = {},

	-- T-140: crossfade duration for every music/ambient stem swap (Lobby <->
	-- chapter, Exploration <-> Combat) — satisfies the "not an abrupt cut"
	-- DoD as a tunable constant rather than a hardcoded tween time.
	MusicCrossfadeDuration = 0.5,
}

for _, chapterId in CHAPTER_IDS do
	AudioConfig.Music[chapterId] = {
		Combat = { Id = 0, Volume = 0.4, Looped = true },
		Exploration = { Id = 0, Volume = 0.35, Looped = true },
	}
	AudioConfig.Ambient[chapterId] = { Id = 0, Volume = 0.3, Looped = true }
end

return AudioConfig
