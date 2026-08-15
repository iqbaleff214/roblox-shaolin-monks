--!strict
-- T-115 (GDD §11.4). 50-tier seasonal pass. Free track always accrues;
-- Premium track is gated by live GamePass ownership at claim time (the same
-- live-check discipline VIPService, T-113, established) — never a cached
-- flag. Because `currentTier` is always recomputed from banked tier XP
-- (BattlePassTierCurve, never stored separately) and the ownership check
-- only happens at claim time, a player who already earned tier 30 for free
-- can claim every earned Premium reward the instant they buy Premium — no
-- special "retroactive unlock" migration needed, it falls out of the design.
--
-- `GrantTierXP` is a real, ready server-internal method awaiting its caller
-- (a chapter-clear/quest-completion hookup, Phase 10) — the same
-- forward-dependency seam used throughout this codebase.
--
-- Persistence: `PlayerDataService` (T-160, Phase 14) now exists with
-- matching `BattlePassTierXP`/`BattlePassClaimed` profile fields, but this
-- service isn't wired to it yet — still in-memory per session, ready for
-- the same direct-profile-access retrofit CurrencyService (T-110) and
-- ProgressionService (T-090) already demonstrate.

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)
local BattlePassTierCurve = require(ReplicatedStorage.Shared.modules.BattlePassTierCurve)

local BattlePassConfig = ConfigService.BattlePass
local MonetizationConfig = ConfigService.Monetization

local BattlePassService = Knit.CreateService({
	Name = "BattlePassService",
	Client = {},
})

-- (player: Player, track: string, tier: number, reward: {any})
BattlePassService.RewardClaimed = Signal.new()

type PlayerState = {
	tierXP: number,
	claimed: { [string]: boolean }, -- key = track .. ":" .. tier
}

local states: { [Player]: PlayerState } = {}

local function getState(player: Player): PlayerState
	local state = states[player]
	if not state then
		state = { tierXP = 0, claimed = {} }
		states[player] = state
	end
	return state
end

local function currentTier(player: Player): number
	return BattlePassTierCurve.tierForXP(getState(player).tierXP, BattlePassConfig.XPPerTier, BattlePassConfig.TierCount)
end

local function ownsPremium(player: Player): boolean
	local passId = MonetizationConfig.GamePasses.BattlePassId
	if passId <= 0 then
		return false
	end
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
	end)
	return ok and owns == true
end

-- Server-internal: ready, awaiting a real caller (see file header).
function BattlePassService:GrantTierXP(player: Player, amount: number)
	if amount <= 0 then
		return
	end
	getState(player).tierXP += amount
end

local function grantReward(player: Player, reward: { Type: string, Amount: number?, Category: string? }, source: string)
	if reward.Type == "Coins" and reward.Amount then
		Knit.GetService("CurrencyService"):GrantCurrency(player, "Coins", reward.Amount, source)
	end
	-- "Cosmetic" rewards have no concrete item catalog yet for their
	-- categories (WeaponSkin/UltimateFxSkin/...) — RewardClaimed still fires
	-- below so a future system can resolve and grant the specific item.
end

function BattlePassService.Client:GetCurrentTier(player: Player): number
	return currentTier(player)
end

function BattlePassService.Client:HasPremium(player: Player): boolean
	return ownsPremium(player)
end

function BattlePassService.Client:RequestClaimReward(player: Player, track: string, tier: number): boolean
	if not Knit.GetService("RateLimitService"):TryConsume(player, "BattlePassService.RequestClaimReward") then
		return false
	end
	if track ~= "Free" and track ~= "Premium" then
		return false
	end
	if tier < 1 or tier > currentTier(player) then
		return false
	end
	if track == "Premium" and not ownsPremium(player) then
		return false
	end

	local state = getState(player)
	local claimKey = track .. ":" .. tier
	if state.claimed[claimKey] then
		return false
	end

	local reward = if track == "Free" then BattlePassConfig.FreeTrackRewards[tier] else BattlePassConfig.PremiumTrackRewards[tier]
	if not reward then
		return false
	end

	state.claimed[claimKey] = true
	grantReward(player, reward, `BattlePass:{track}:{tier}`)
	BattlePassService.RewardClaimed:Fire(player, track, tier, reward)
	return true
end

function BattlePassService:KnitInit()
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
end

return BattlePassService
