-- GDD §5.1 / §5.3. Head/Body/Arm/Leg accessory definitions. Cosmetic only —
-- no combat-stat field is ever allowed on an entry here (enforced by
-- AccessoryConfig.spec.lua's disallowed-key guard). AssetId placeholders are
-- filled by the Studio accessory catalog work (STUDIO_TASKS.md S-050-S-053).
--
-- This is a starter catalog; S-050-S-053 grow it with real art per rarity
-- tier without touching the schema below.

return {
	HeadMonkHood = {
		Slot = "Head",
		DisplayName = "Monk Hood",
		Rarity = "Common",
		UnlockSource = "Shop",
		AssetId = 0,
	},
	HeadHornedHelm = {
		Slot = "Head",
		DisplayName = "Horned Helm",
		Rarity = "Epic",
		UnlockSource = "Crate",
		AssetId = 0,
	},
	BodyDiscipleRobe = {
		Slot = "Body",
		DisplayName = "Disciple's Robe",
		Rarity = "Common",
		UnlockSource = "Shop",
		AssetId = 0,
	},
	BodyWarlordArmor = {
		Slot = "Body",
		DisplayName = "Warlord's Armor",
		Rarity = "Legendary",
		UnlockSource = "BattlePass",
		AssetId = 0,
	},
	ArmClothWraps = {
		Slot = "Arm",
		DisplayName = "Cloth Wraps",
		Rarity = "Common",
		UnlockSource = "Shop",
		AssetId = 0,
	},
	ArmJadeBracers = {
		Slot = "Arm",
		DisplayName = "Jade Bracers",
		Rarity = "Rare",
		UnlockSource = "QuestReward",
		AssetId = 0,
	},
	LegSandals = {
		Slot = "Leg",
		DisplayName = "Travel Sandals",
		Rarity = "Common",
		UnlockSource = "Shop",
		AssetId = 0,
	},
	LegStormGreaves = {
		Slot = "Leg",
		DisplayName = "Storm Greaves",
		Rarity = "Epic",
		UnlockSource = "Crate",
		AssetId = 0,
	},
}
