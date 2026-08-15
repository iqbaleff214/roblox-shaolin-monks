--!strict
-- T-114 (GDD §14.5). `ProcessReceipt` for the 3 Jade Shard Developer Product
-- tiers. Idempotent per Roblox's ProcessReceipt contract: every PurchaseId is
-- recorded in its own dedicated DataStore (not the not-yet-built T-160
-- PlayerDataService — receipt idempotency is a self-contained concern with
-- its own durable store, the same reasoning Phase 8's LeaderboardService
-- used for OrderedDataStore) before returning `PurchaseGranted`, so a
-- server-restart replay of the same receipt is recognized and skipped rather
-- than re-granting Jade.
--
-- `MarketplaceService.ProcessReceipt` is a single global assignment per game
-- — this service is its sole owner.

local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)

local MonetizationConfig = ConfigService.Monetization
local receiptStore = DataStoreService:GetDataStore("SMA_ProcessedReceipts")

local JadeProductService = Knit.CreateService({
	Name = "JadeProductService",
})

local function findProduct(productId: number)
	for _, product in MonetizationConfig.JadeProducts do
		if product.ProductId == productId then
			return product
		end
	end
	return nil
end

local function wasAlreadyProcessed(purchaseId: string): boolean?
	local ok, result = pcall(function()
		return receiptStore:GetAsync(purchaseId)
	end)
	if not ok then
		return nil -- couldn't verify; caller must not proceed
	end
	return result == true
end

local function markProcessed(purchaseId: string)
	local ok = pcall(function()
		receiptStore:SetAsync(purchaseId, true)
	end)
	if not ok then
		warn(`[JadeProductService] failed to durably mark receipt {purchaseId} as processed`)
	end
end

local function processReceipt(receiptInfo: { PlayerId: number, PurchaseId: string, ProductId: number })
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local alreadyProcessed = wasAlreadyProcessed(receiptInfo.PurchaseId)
	if alreadyProcessed == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- DataStore unavailable; let Roblox retry
	end
	if alreadyProcessed then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local product = findProduct(receiptInfo.ProductId)
	if not product then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	Knit.GetService("CurrencyService"):GrantCurrency(player, "Jade", product.Jade, "JadeProduct:" .. receiptInfo.ProductId)
	markProcessed(receiptInfo.PurchaseId)

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function JadeProductService:KnitStart()
	MarketplaceService.ProcessReceipt = processReceipt
end

return JadeProductService
