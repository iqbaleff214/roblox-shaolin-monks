--!strict
-- T-117 (GDD §11.6). Opens crates earned via gameplay or purchased with Jade
-- Shards, resolving a rolled rarity into a concrete granted item.
--
-- Gameplay path: subscribes directly to ChestService's (T-102) existing
-- `ChestOpened` signal — that hookup already rolled a rarity, this is simply
-- its first real consumer.
-- Purchase path: `RequestPurchaseCrate` spends Jade via CurrencyService
-- (T-110) then rolls against the SAME ChestRarityRoller (T-101/T-102) used
-- by gameplay chests — no code path anywhere converts Robux directly to a
-- crate; Jade is the only currency accepted, and Jade itself is only ever
-- obtained through JadeProductService's (T-114) Developer Product flow,
-- satisfying §11.6's UGC-policy requirement by construction.
--
-- Duplicate-protection (T-103) requires no new code here: InventoryService's
-- (T-081) `Grant` already routes every repeat grant through its idempotent
-- InventoryRecord logic and fires `DuplicateGranted`, which
-- DuplicateProtectionService (T-103) already listens to.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)
local ChestRarityRoller = require(ReplicatedStorage.Shared.modules.ChestRarityRoller)
local CosmeticItemPicker = require(ReplicatedStorage.Shared.modules.CosmeticItemPicker)

local ShopConfig = ConfigService.Shop

local CrateOpeningService = Knit.CreateService({
	Name = "CrateOpeningService",
	Client = {},
})

-- (player: Player, category: string, itemId: string, rarity: string, source: string)
CrateOpeningService.CrateItemGranted = Signal.new()

local function findCrate(crateId: string)
	for _, crate in ShopConfig.Crates do
		if crate.Id == crateId then
			return crate
		end
	end
	return nil
end

local function grantFromRarity(player: Player, rarity: string, source: string)
	local seed = Random.new():NextInteger(1, 2 ^ 31 - 1)
	local itemId = CosmeticItemPicker.pickAccessoryByRarity(seed, rarity)
	if not itemId then
		return
	end

	Knit.GetService("InventoryService"):Grant(player, "Accessory", itemId)
	CrateOpeningService.CrateItemGranted:Fire(player, "Accessory", itemId, rarity, source)
end

local function onChestOpened(player: Player, tier: string, rarity: string)
	grantFromRarity(player, rarity, "Chest:" .. tier)
end

function CrateOpeningService.Client:RequestPurchaseCrate(player: Player, crateId: string): boolean
	local crate = findCrate(crateId)
	if not crate then
		return false
	end

	local CurrencyService = Knit.GetService("CurrencyService")
	if not CurrencyService:SpendCurrency(player, crate.Currency, crate.Price, "Crate:" .. crateId) then
		return false
	end

	local seed = Random.new():NextInteger(1, 2 ^ 31 - 1)
	local rarity = ChestRarityRoller.roll(seed, crate.ChestTier)
	if rarity then
		grantFromRarity(player, rarity, "CratePurchase:" .. crateId)
	end
	return true
end

function CrateOpeningService:KnitStart()
	local ChestService = Knit.GetService("ChestService")
	ChestService.ChestOpened:Connect(onChestOpened)
end

return CrateOpeningService
