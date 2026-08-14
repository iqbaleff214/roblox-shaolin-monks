-- GDD §10.3 / §11.2. Combo Scrolls (Sifu's Dojo) and the Coins/Jade cosmetic
-- shop. Combo Scrolls are Coin-only by hard rule — §10.3: "never purchasable
-- with premium currency" — enforced by ShopConfig.spec.lua for every entry.
-- Robux-priced items (Chapter Cosmetic Pass, §11.2) live in
-- MonetizationConfig instead, since they go through MarketplaceService
-- Developer Products, not this Coins/Jade shop.

return {
	-- §10.3: one starter Combo Scroll per weapon, unlocking the weapon's
	-- combo-tree finisher. Later scrolls (deeper strings) are added here as
	-- WeaponConfig's combo trees grow, without changing this schema.
	ComboScrolls = {
		{
			Id = "TwinBlades_FlowingStrikes",
			WeaponId = "TwinBlades",
			DisplayName = "Twin Blades: Flowing Strikes",
			Currency = "Coins",
			Price = 250,
		},
		{
			Id = "WarStaff_HeavensSweep",
			WeaponId = "WarStaff",
			DisplayName = "War Staff: Sweeping Guard Break",
			Currency = "Coins",
			Price = 250,
		},
		{
			Id = "HookSwords_SerpentChain",
			WeaponId = "HookSwords",
			DisplayName = "Hook Swords: Serpent Chain",
			Currency = "Coins",
			Price = 250,
		},
		{
			Id = "IronGauntlets_StoneFist",
			WeaponId = "IronGauntlets",
			DisplayName = "Iron Gauntlets: Stone Fist Finisher",
			Currency = "Coins",
			Price = 250,
		},
		{
			Id = "BattleGlaive_ArcingWind",
			WeaponId = "BattleGlaive",
			DisplayName = "Battle Glaive: Arcing Wind Sweep",
			Currency = "Coins",
			Price = 250,
		},
	},

	-- §11.2 cosmetic categories. AccessoryId/WeaponId reference AccessoryConfig
	-- / WeaponConfig entries; this is a starter catalog grown by the Studio
	-- asset work (S-050-S-057) without touching the schema.
	Cosmetics = {
		{
			Id = "Shop_HeadMonkHood",
			Category = "Accessory",
			AccessoryId = "HeadMonkHood",
			Currency = "Coins",
			Price = 300,
		},
		{
			Id = "Shop_BodyDiscipleRobe",
			Category = "Accessory",
			AccessoryId = "BodyDiscipleRobe",
			Currency = "Coins",
			Price = 300,
		},
		{
			Id = "Shop_TwinBladesSkin_Jade",
			Category = "WeaponSkin",
			WeaponId = "TwinBlades",
			Currency = "Jade",
			Price = 150,
		},
		{
			Id = "Shop_UltimateFx_Emberglow",
			Category = "UltimateFxSkin",
			Currency = "Jade",
			Price = 200,
		},
		{
			Id = "Shop_Emote_MeditationIdle",
			Category = "Emote",
			Currency = "Jade",
			Price = 80,
		},
	},

	Bundles = {
		{
			Id = "DisciplesStarterBundle",
			DisplayName = "Disciple's Starter Bundle",
			Currency = "Jade",
			Price = 400,
			Contents = { "Shop_HeadMonkHood", "Shop_TwinBladesSkin_Jade" },
		},
	},
}
