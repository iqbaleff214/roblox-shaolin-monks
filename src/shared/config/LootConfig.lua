-- GDD §14.4 / §3.8 / §10.2 / §10.4. Destructible container hit pools and the
-- published (§10.4 "no hidden odds") chest rarity weight tables. Every
-- ChestRarityWeights row must sum to 100 — see LootConfig.spec.lua.

return {
	Containers = {
		WoodenCrate = { Hits = 1, DropTable = "Common" },
		ClayUrn = { Hits = 1, DropTable = "Common" },
		SupplyBarrel = { Hits = 2, DropTable = "Uncommon" },
		JadeChest = { Hits = 3, DropTable = "Rare", Hidden = true },
	},

	ChestRarityWeights = {
		Arena = { Common = 60, Uncommon = 25, Rare = 10, Epic = 4, Legendary = 1 },
		Chapter = { Common = 40, Uncommon = 30, Rare = 18, Epic = 9, Legendary = 3 },
		Boss = { Common = 20, Uncommon = 30, Rare = 28, Epic = 16, Legendary = 6 },
		Vault = { Common = 10, Uncommon = 25, Rare = 30, Epic = 25, Legendary = 10 },
	},
}
