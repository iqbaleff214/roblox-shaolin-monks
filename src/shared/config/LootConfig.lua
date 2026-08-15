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

	-- §10.2's literal per-container payout table (T-101). Coins are always
	-- granted (a Min/Max roll); BonusDrop is an independent chance roll on
	-- top, distinct per container per the GDD table (a Wooden Crate's Health
	-- Orb chance is not the same slot as a Clay Urn's Chi Orb chance, even
	-- though both containers share the "Common" DropTable tier above).
	ContainerDrops = {
		WoodenCrate = { CoinsMin = 5, CoinsMax = 10, BonusDrop = { Type = "HealthOrb", Chance = 0.1 } },
		ClayUrn = { CoinsMin = 5, CoinsMax = 10, BonusDrop = { Type = "ChiOrb", Chance = 0.1 } },
		SupplyBarrel = { CoinsMin = 10, CoinsMax = 20, BonusDrop = { Type = "ThrowableWeapon", Chance = 0.15 } },
		JadeChest = { CoinsMin = 0, CoinsMax = 0, GuaranteedDrop = "Relic", BonusDrop = { Type = "Cosmetic", Chance = 0.25 } },
	},

	-- T-101: enemy-kill Coin drops, keyed by EnemyConfig.Roles. Not an
	-- explicit GDD table, but T-101 requires enemy kills to roll a drop the
	-- same way container breaks do; scaled roughly with each role's Health.
	EnemyKillCoins = {
		Grunt = { Min = 2, Max = 4 },
		Soldier = { Min = 3, Max = 6 },
		Heavy = { Min = 6, Max = 10 },
		Ranged = { Min = 3, Max = 6 },
		Assassin = { Min = 3, Max = 6 },
		Elite = { Min = 15, Max = 25 },
		Boss = { Min = 50, Max = 80 },
	},

	ChestRarityWeights = {
		Arena = { Common = 60, Uncommon = 25, Rare = 10, Epic = 4, Legendary = 1 },
		Chapter = { Common = 40, Uncommon = 30, Rare = 18, Epic = 9, Legendary = 3 },
		Boss = { Common = 20, Uncommon = 30, Rare = 28, Epic = 16, Legendary = 6 },
		Vault = { Common = 10, Uncommon = 25, Rare = 30, Epic = 25, Legendary = 10 },
	},

	-- T-101: how much a Health/Chi Orb bonus drop restores. Health applies
	-- directly to the player's Humanoid; Chi applies via CombatService:GrantChi.
	OrbRestoreAmounts = {
		HealthOrb = 20,
		ChiOrb = 15,
	},

	-- T-103 (§10.4/§11.6): Coins awarded when a cosmetic pull is a duplicate,
	-- scaled by the item's rarity tier.
	DuplicateConversionRate = {
		Common = 10,
		Uncommon = 25,
		Rare = 60,
		Epic = 150,
		Legendary = 400,
	},
}
