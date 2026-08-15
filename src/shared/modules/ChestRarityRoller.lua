-- T-102 (GDD §10.4). Rolls a chest's cosmetic rarity against
-- LootConfig.ChestRarityWeights[tier], wrapping WeightedRoll (T-101/T-102)
-- with an explicit, fixed rarity order — the same "no incidental table
-- iteration order" discipline WeightedRoll itself documents.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LootConfig = require(ReplicatedStorage.Shared.config.LootConfig)
local WeightedRoll = require(ReplicatedStorage.Shared.modules.WeightedRoll)

local ChestRarityRoller = {}

local RARITY_ORDER = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }

function ChestRarityRoller.roll(seed: number, tier: string): string?
	local weights = LootConfig.ChestRarityWeights[tier]
	if not weights then
		return nil
	end

	local entries: { WeightedRoll.Entry } = {}
	for _, rarity in RARITY_ORDER do
		table.insert(entries, { key = rarity, weight = weights[rarity] })
	end

	return WeightedRoll.pick(Random.new(seed), entries)
end

return ChestRarityRoller
