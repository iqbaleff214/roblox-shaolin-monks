--!strict
-- T-112 (GDD §11.2). Coins/Jade cosmetic purchases, granting into inventory
-- (InventoryService, T-081). Price and currency are always read server-side
-- from `ShopConfig` by looking the item up by its own Id — the client only
-- ever sends an item Id, never a price, so there is no code path where a
-- client-supplied price could even be read, let alone trusted.
--
-- Item id resolution: only "Accessory" cosmetics resolve to a real config
-- entry (`AccessoryId` -> AccessoryConfig) today; WeaponSkin/UltimateFxSkin/
-- Emote categories have no dedicated item config yet (same gap noted in
-- Phase 8's DuplicateProtectionService), so they're granted into inventory
-- keyed by the shop entry's own Id instead — real and functional, ready for
-- those configs to exist later without changing this file.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)

local ShopConfig = ConfigService.Shop

local CosmeticShopService = Knit.CreateService({
	Name = "CosmeticShopService",
	Client = {},
})

local function findCosmetic(shopItemId: string)
	for _, entry in ShopConfig.Cosmetics do
		if entry.Id == shopItemId then
			return entry
		end
	end
	return nil
end

local function findBundle(bundleId: string)
	for _, entry in ShopConfig.Bundles do
		if entry.Id == bundleId then
			return entry
		end
	end
	return nil
end

local function inventoryItemId(entry: { Id: string, AccessoryId: string? })
	return entry.AccessoryId or entry.Id
end

function CosmeticShopService.Client:RequestPurchase(player: Player, shopItemId: string): boolean
	if not Knit.GetService("RateLimitService"):TryConsume(player, "CosmeticShopService.RequestPurchase") then
		return false
	end
	local entry = findCosmetic(shopItemId)
	if not entry then
		return false
	end

	local CurrencyService = Knit.GetService("CurrencyService")
	if not CurrencyService:SpendCurrency(player, entry.Currency, entry.Price, "Shop:" .. shopItemId) then
		return false
	end

	Knit.GetService("InventoryService"):Grant(player, entry.Category, inventoryItemId(entry))
	return true
end

function CosmeticShopService.Client:RequestPurchaseBundle(player: Player, bundleId: string): boolean
	if not Knit.GetService("RateLimitService"):TryConsume(player, "CosmeticShopService.RequestPurchaseBundle") then
		return false
	end
	local bundle = findBundle(bundleId)
	if not bundle then
		return false
	end

	local CurrencyService = Knit.GetService("CurrencyService")
	if not CurrencyService:SpendCurrency(player, bundle.Currency, bundle.Price, "Bundle:" .. bundleId) then
		return false
	end

	local InventoryService = Knit.GetService("InventoryService")
	for _, contentId in bundle.Contents do
		local entry = findCosmetic(contentId)
		if entry then
			InventoryService:Grant(player, entry.Category, inventoryItemId(entry))
		end
	end
	return true
end

return CosmeticShopService
