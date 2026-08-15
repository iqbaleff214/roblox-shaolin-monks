-- T-117 (GDD §11.6). Picks a random concrete item id matching a rolled
-- rarity. Only AccessoryConfig (T-015) has real items with a `Rarity` field
-- today — the same gap noted in Phase 8/9's other rarity-resolution seams
-- (DuplicateProtectionService, CosmeticShopService). Candidate ids are
-- sorted before rolling so the pick is deterministic for a given seed
-- regardless of incidental table-iteration order (WeightedRoll's discipline).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AccessoryConfig = require(ReplicatedStorage.Shared.config.AccessoryConfig)

local CosmeticItemPicker = {}

function CosmeticItemPicker.pickAccessoryByRarity(seed: number, rarity: string): string?
	local candidates = {}
	for id, item in AccessoryConfig do
		if item.Rarity == rarity then
			table.insert(candidates, id)
		end
	end
	if #candidates == 0 then
		return nil
	end
	table.sort(candidates)

	local rng = Random.new(seed)
	return candidates[rng:NextInteger(1, #candidates)]
end

return CosmeticItemPicker
