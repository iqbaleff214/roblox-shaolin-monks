--!strict
-- T-110 (GDD §11.1, §17.2). Server-authoritative Coins and Jade Shards.
-- `GrantCurrency`/`SpendCurrency` are the ONLY functions that ever mutate a
-- balance (T-049/T-110's "single writer" pattern) — every mutation logs its
-- source and SpendCurrency rejects (with zero partial deduction) any attempt
-- to go negative.
--
-- One-way economy: there is no ConvertCurrency function anywhere in this
-- file, and never will be — Coins cannot become Jade, enforced by omission,
-- matching MonetizationConfig's `CoinToJadeRate = nil` guard (T-018).
--
-- Closes the loop from two earlier phases: subscribes to LootService's
-- (T-101) `RewardRolled` signal so every "Coins" roll (container break,
-- enemy kill, duplicate-protection conversion, Finishing Move relic's future
-- Coin companion) finally lands in a real balance instead of only a signal.
--
-- VIP boost (T-113): reads the `IsVIP` Player attribute set by VIPService —
-- a live-checked-at-session-start flag, not a value this service persists or
-- re-derives itself — and applies MonetizationConfig.VIPBoostCoins only to
-- Coins (never Jade, which is Robux-purchased already).
--
-- Persistence (T-160, Phase 14): this service holds no balance state of its
-- own — every read/write goes straight through
-- PlayerDataService:GetProfile(player).Coins/.Jade, the single live source
-- of truth. Deliberately NOT a local cache hydrated once from the profile:
-- PlayerDataService's async load mutates the profile table's fields in
-- place whenever it resolves, so a separate local cache taken before that
-- finishes would freeze at the pre-load default and never see the loaded
-- value. Reading the profile field directly on every call sidesteps that
-- race entirely — the reference integration pattern for the rest of
-- §17.3's data list.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)

local MonetizationConfig = ConfigService.Monetization
local VALID_CURRENCIES = { Coins = true, Jade = true }

local CurrencyService = Knit.CreateService({
	Name = "CurrencyService",
	Client = {},
})

-- (player: Player, currency: string, amount: number, source: string, newBalance: number)
CurrencyService.CurrencyGranted = Signal.new()
-- (player: Player, currency: string, amount: number, source: string, newBalance: number)
CurrencyService.CurrencySpent = Signal.new()

local function getProfile(player: Player)
	return Knit.GetService("PlayerDataService"):GetProfile(player)
end

-- Server-internal: the sole writer that increases a balance. Coins-only VIP
-- boost is applied here so every Coin source (loot, quests, shop refunds,
-- future systems) benefits uniformly without each caller re-deriving it.
function CurrencyService:GrantCurrency(player: Player, currency: string, amount: number, source: string)
	if not VALID_CURRENCIES[currency] or amount <= 0 then
		return
	end

	local grantedAmount = amount
	if currency == "Coins" and player:GetAttribute("IsVIP") == true then
		grantedAmount = math.floor(amount * (1 + MonetizationConfig.VIPBoostCoins))
	end

	local profile = getProfile(player)
	profile[currency] += grantedAmount
	CurrencyService.CurrencyGranted:Fire(player, currency, grantedAmount, source, profile[currency])
end

-- Server-internal: the sole writer that decreases a balance. Rejects
-- (with zero partial deduction) if the balance can't cover `amount`.
function CurrencyService:SpendCurrency(player: Player, currency: string, amount: number, source: string): boolean
	if not VALID_CURRENCIES[currency] or amount <= 0 then
		return false
	end

	local profile = getProfile(player)
	if profile[currency] < amount then
		return false
	end

	profile[currency] -= amount
	CurrencyService.CurrencySpent:Fire(player, currency, amount, source, profile[currency])
	return true
end

function CurrencyService:GetBalance(player: Player, currency: string): number
	if not VALID_CURRENCIES[currency] then
		return 0
	end
	return getProfile(player)[currency]
end

function CurrencyService.Client:GetBalance(player: Player, currency: string): number
	return CurrencyService:GetBalance(player, currency)
end

local function onRewardRolled(player: Player, rewardType: string, amount: number?, source: string)
	if rewardType == "Coins" and amount then
		CurrencyService:GrantCurrency(player, "Coins", amount, source)
	end
end

function CurrencyService:KnitStart()
	local LootService = Knit.GetService("LootService")
	LootService.RewardRolled:Connect(onRewardRolled)
end

return CurrencyService
