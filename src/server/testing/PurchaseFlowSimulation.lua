--!strict
-- T-192 (GDD §17 QA). Consolidated purchase-flow regression suite covering
-- both monetization paths from Phase 9:
--   * Developer Product (Jade Shards, T-114) — drives the REAL
--     `MarketplaceService.ProcessReceipt` hook JadeProductService installs,
--     with the same receipt twice, asserting the double-call idempotency
--     case from T-114's own DoD.
--   * GamePass (VIP, T-113) — GamePass ownership itself can't be faked
--     outside Roblox's own sandboxed purchase testing (a manual Studio Test
--     tab step, not scriptable, and `MonetizationConfig.VIPPassId` is still
--     a T-200 placeholder 0 in this environment either way) — but the
--     downstream contract VIPService documents (live ownership -> the
--     `IsVIP` Player attribute -> CurrencyService/ProgressionService reading
--     it for the boost) is fully real code, so this exercises that half
--     directly by toggling the same attribute VIPService itself writes.
--
-- Requires a live Player. Invoke from the Studio command bar:
--   require(game.ServerScriptService.Server.testing.PurchaseFlowSimulation).run()

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)

local PurchaseFlowSimulation = {}

local function checkJadeProductIdempotency(player: Player, check: (boolean, string) -> ()): ()
	local CurrencyService = Knit.GetService("CurrencyService")
	local product = ConfigService.Monetization.JadeProducts[1]

	local receiptInfo = {
		PlayerId = player.UserId,
		PurchaseId = "SimPurchase_" .. tostring(os.clock()),
		ProductId = product.ProductId,
		CurrencySpent = product.Robux,
		CurrencyType = Enum.CurrencyType.Robux,
		PlaceIdWherePurchased = game.PlaceId,
	}

	local before = CurrencyService:GetBalance(player, "Jade")
	local firstDecision = MarketplaceService.ProcessReceipt(receiptInfo)
	local afterFirst = CurrencyService:GetBalance(player, "Jade")

	check(firstDecision == Enum.ProductPurchaseDecision.PurchaseGranted, "first ProcessReceipt call grants Jade")
	check(afterFirst - before == product.Jade, `granted amount matches config ({product.Jade})`)

	local secondDecision = MarketplaceService.ProcessReceipt(receiptInfo) -- same PurchaseId
	local afterSecond = CurrencyService:GetBalance(player, "Jade")

	check(secondDecision == Enum.ProductPurchaseDecision.PurchaseGranted, "repeat ProcessReceipt call still reports PurchaseGranted")
	check(afterSecond == afterFirst, "repeat call does not re-grant Jade (idempotent per T-114's DoD)")
end

local function checkVipBoostApplication(player: Player, check: (boolean, string) -> ()): ()
	local CurrencyService = Knit.GetService("CurrencyService")
	local originalIsVIP = player:GetAttribute("IsVIP")

	player:SetAttribute("IsVIP", false)
	local baseline = CurrencyService:GetBalance(player, "Coins")
	CurrencyService:GrantCurrency(player, "Coins", 100, "PurchaseFlowSimulation")
	local afterNonVIP = CurrencyService:GetBalance(player, "Coins")
	check(afterNonVIP - baseline == 100, "non-VIP grant is unboosted")

	player:SetAttribute("IsVIP", true)
	local beforeVIP = CurrencyService:GetBalance(player, "Coins")
	CurrencyService:GrantCurrency(player, "Coins", 100, "PurchaseFlowSimulation")
	local afterVIP = CurrencyService:GetBalance(player, "Coins")
	local expectedBoosted = math.floor(100 * (1 + ConfigService.Monetization.VIPBoostCoins))
	check(afterVIP - beforeVIP == expectedBoosted, `VIP grant applies the configured Coin boost (expected {expectedBoosted})`)

	player:SetAttribute("IsVIP", originalIsVIP)
end

-- Runs both purchase-flow checks end-to-end. Requires a live Player.
function PurchaseFlowSimulation.run(): boolean
	local player = Players:GetPlayers()[1]
	if not player then
		warn("[PurchaseFlowSimulation] Requires a live Player (Studio Play/solo-test) — aborting.")
		return false
	end

	local ok = true
	local function check(condition: boolean, label: string)
		if not condition then
			ok = false
			warn(`[PurchaseFlowSimulation] FAILED: {label}`)
		else
			print(`[PurchaseFlowSimulation] OK: {label}`)
		end
	end

	checkJadeProductIdempotency(player, check)
	checkVipBoostApplication(player, check)

	print(`[PurchaseFlowSimulation] Overall: {if ok then "PASS" else "FAIL"}`)
	return ok
end

return PurchaseFlowSimulation
