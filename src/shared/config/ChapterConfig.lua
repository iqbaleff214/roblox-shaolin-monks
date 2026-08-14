-- GDD §8. One entry per chapter, in story order. LevelGate follows §8.3's
-- tier gates exactly (both chapters in a tier share the same gate); ArenaCount
-- stays within §8.1's "3-5 combat arenas" range. Ids are the canonical chapter
-- identifiers used by ChapterConfig, AudioConfig, and the Studio Workspace
-- folder structure (STUDIO_TASKS.md S-001) — keep them in sync everywhere.

return {
	{
		Id = "TempleCourtyard",
		DisplayName = "Temple Courtyard",
		DifficultyTier = "Novice",
		LevelGate = 0,
		Faction = "Jade Serpent Cultists",
		SignatureHazard = "CollapsingScaffolding",
		ArenaCount = 3,
		BossId = "CultistWarlord",
	},
	{
		Id = "BurningVillage",
		DisplayName = "Burning Village",
		DifficultyTier = "Novice",
		LevelGate = 0,
		Faction = "Raider Warband",
		SignatureHazard = "SpreadingFire",
		ArenaCount = 3,
		BossId = "RaiderChieftain",
	},
	{
		Id = "BambooForest",
		DisplayName = "Bamboo Forest",
		DifficultyTier = "Adept",
		LevelGate = 8,
		Faction = "Shadow Stalkers",
		SignatureHazard = "BreakableBambooCover",
		ArenaCount = 4,
		BossId = "ShadowMatriarch",
	},
	{
		Id = "MountainPass",
		DisplayName = "Mountain Pass",
		DifficultyTier = "Adept",
		LevelGate = 8,
		Faction = "Frost Wardens",
		SignatureHazard = "IceFooting",
		ArenaCount = 4,
		BossId = "FrostSentinel",
	},
	{
		Id = "AncientCatacombs",
		DisplayName = "Ancient Catacombs",
		DifficultyTier = "Veteran",
		LevelGate = 18,
		Faction = "Restless Dead",
		SignatureHazard = "BoneTrapTiles",
		ArenaCount = 4,
		BossId = "BoneWarden",
	},
	{
		Id = "SkyPagoda",
		DisplayName = "Sky Pagoda",
		DifficultyTier = "Veteran",
		LevelGate = 18,
		Faction = "Wind Monks (corrupted)",
		SignatureHazard = "WindGustPlatforming",
		ArenaCount = 5,
		BossId = "SkyDuelist",
	},
	{
		Id = "UnderworldGate",
		DisplayName = "Underworld Gate",
		DifficultyTier = "Master",
		LevelGate = 30,
		Faction = "Nezhar's Legion",
		SignatureHazard = "CorruptedGroundDOT",
		ArenaCount = 5,
		BossId = "WraithCommander",
	},
	{
		Id = "WarlordsThrone",
		DisplayName = "Warlord's Throne",
		DifficultyTier = "Master",
		LevelGate = 30,
		Faction = "Nezhar's Honor Guard",
		SignatureHazard = "EscortGauntlet",
		ArenaCount = 3,
		BossId = "Nezhar", -- final boss (§1, §4.6)
	},
}
