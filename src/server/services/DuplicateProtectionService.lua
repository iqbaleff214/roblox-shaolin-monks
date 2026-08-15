--!strict
-- T-103 (GDD §10.4, §11.6). Converts a duplicate cosmetic grant into Coins
-- instead of a wasted second copy, subscribing directly to InventoryService's
-- (T-081) existing `DuplicateGranted` signal — that hookup already existed,
-- waiting for exactly this. Conversion rate is config-driven
-- (LootConfig.DuplicateConversionRate), scaled by the item's rarity tier.
--
-- Rarity resolution: only AccessoryConfig (T-015) defines real items with a
-- `Rarity` field today; WeaponSkin/UltimateFxSkin/Emote/SpiritCompanion item
-- definitions don't exist in any config yet (Phase 9's cosmetic shop growth,
-- S-050+). Those categories fall back to "Common" until their own config
-- exists — honest and safe, never a crash on an unresolvable item.
--
-- Reuses LootService's (T-101) `RewardRolled` signal for the actual Coins
-- payout rather than introducing a second reward surface — Phase 9's
-- CurrencyService only needs to subscribe to one place for every Coin-source
-- in this codebase.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)

local LootConfig = ConfigService.Loot
local AccessoryConfig = ConfigService.Accessory
local FALLBACK_RARITY = "Common"

local DuplicateProtectionService = Knit.CreateService({
	Name = "DuplicateProtectionService",
})

local function resolveRarity(category: string, itemId: string): string
	if category == "Accessory" then
		local item = AccessoryConfig[itemId]
		if item and type(item.Rarity) == "string" then
			return item.Rarity
		end
	end
	return FALLBACK_RARITY
end

local function onDuplicateGranted(player: Player, category: string, itemId: string)
	local rarity = resolveRarity(category, itemId)
	local rate = LootConfig.DuplicateConversionRate[rarity] or LootConfig.DuplicateConversionRate[FALLBACK_RARITY]

	local LootService = Knit.GetService("LootService")
	LootService.RewardRolled:Fire(player, "Coins", rate, `Duplicate:{category}:{itemId}`)
end

function DuplicateProtectionService:KnitStart()
	local InventoryService = Knit.GetService("InventoryService")
	InventoryService.DuplicateGranted:Connect(onDuplicateGranted)
end

return DuplicateProtectionService
