--!strict
-- T-111 (GDD §10.3). Coins-only purchase flow for Sifu's Dojo's Combo
-- Scrolls. The server reads `ShopConfig.ComboScrolls[i].Currency` itself and
-- always spends Coins regardless of what the client requests — there is no
-- code path that reads a client-supplied currency type at all, which is what
-- makes a spoofed "Jade" flag structurally impossible here, not just
-- validated away.
--
-- Ownership is tracked via InventoryService (T-081) under a "ComboScroll"
-- category — reusing its existing generic Grant/IsOwned API needs no schema
-- change. This finally closes T-041's (Phase 3) "gated by owned Combo
-- Scrolls" seam: see the matching one-line addition in CombatService.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)

local ShopConfig = ConfigService.Shop
local INVENTORY_CATEGORY = "ComboScroll"

local ComboScrollShopService = Knit.CreateService({
	Name = "ComboScrollShopService",
	Client = {},
})

local function findScroll(scrollId: string)
	for _, scroll in ShopConfig.ComboScrolls do
		if scroll.Id == scrollId then
			return scroll
		end
	end
	return nil
end

function ComboScrollShopService.Client:RequestPurchase(player: Player, scrollId: string): boolean
	if not Knit.GetService("RateLimitService"):TryConsume(player, "ComboScrollShopService.RequestPurchase") then
		return false
	end
	local scroll = findScroll(scrollId)
	if not scroll then
		return false
	end

	local InventoryService = Knit.GetService("InventoryService")
	if InventoryService:IsOwned(player, INVENTORY_CATEGORY, scrollId) then
		return false -- already owned; no double-charge
	end

	local CurrencyService = Knit.GetService("CurrencyService")
	-- §10.3 hard rule: Combo Scrolls are Coin-only. `scroll.Currency` is
	-- always "Coins" per ShopConfig.spec.lua's guard, but spending explicitly
	-- against "Coins" here (not `scroll.Currency`) means even a corrupted
	-- config entry could never accidentally charge Jade.
	if not CurrencyService:SpendCurrency(player, "Coins", scroll.Price, "ComboScroll:" .. scrollId) then
		return false
	end

	InventoryService:Grant(player, INVENTORY_CATEGORY, scrollId)
	return true
end

function ComboScrollShopService.Client:IsOwned(player: Player, scrollId: string): boolean
	local InventoryService = Knit.GetService("InventoryService")
	return InventoryService:IsOwned(player, INVENTORY_CATEGORY, scrollId)
end

return ComboScrollShopService
