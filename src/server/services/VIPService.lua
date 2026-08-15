--!strict
-- T-113 (GDD §11.3). VIP GamePass ownership. Boost application (+25% XP,
-- ProgressionService; +25% Coins, CurrencyService) reads the `IsVIP` Player
-- attribute this service sets — live-checked via
-- `MarketplaceService:UserOwnsGamePassAsync` at session start (and on
-- explicit refresh), never a value trusted from a persisted DataStore flag
-- alone. A stale-ownership exploit after a refund can't survive past the
-- next check because there is no fallback path that skips the live call.
--
-- VIP Training Hall access and the scoreboard/above-head badge are both
-- fully described by the same `IsVIP` attribute (a Studio-built Training
-- Hall gate or badge display just reads it, S-016/S-080) — no separate flag
-- to keep in sync.
--
-- Monthly cosmetic drop: fires `MonthlyDropDue` at most once per UTC
-- calendar month while VIP is active. No specific cosmetic item is defined
-- anywhere yet (same "no dedicated config" gap as other not-yet-cataloged
-- cosmetic categories) — this is the real, ready trigger; granting a
-- specific item is Phase 9's cosmetic-shop growth to wire in later.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)

local MonetizationConfig = ConfigService.Monetization

local VIPService = Knit.CreateService({
	Name = "VIPService",
	Client = {},
})

-- (player: Player)
VIPService.MonthlyDropDue = Signal.new()

local lastDropMonthKey: { [Player]: number } = {}

local function monthKey(now: number): number
	local date = os.date("!*t", now)
	return date.year * 12 + date.month
end

local function checkMonthlyDrop(player: Player)
	local key = monthKey(os.time())
	if lastDropMonthKey[player] ~= key then
		lastDropMonthKey[player] = key
		VIPService.MonthlyDropDue:Fire(player)
	end
end

local function refreshOwnership(player: Player)
	local passId = MonetizationConfig.GamePasses.VIPPassId
	local isVIP = false
	if passId > 0 then
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
		end)
		isVIP = ok and owns == true
	end

	player:SetAttribute("IsVIP", isVIP)
	if isVIP then
		checkMonthlyDrop(player)
	end
end

function VIPService.Client:RequestRefreshVIPStatus(player: Player)
	refreshOwnership(player)
end

function VIPService.Client:IsVIP(player: Player): boolean
	return player:GetAttribute("IsVIP") == true
end

function VIPService:KnitInit()
	Players.PlayerRemoving:Connect(function(player)
		lastDropMonthKey[player] = nil
	end)
end

function VIPService:KnitStart()
	for _, player in Players:GetPlayers() do
		refreshOwnership(player)
	end
	Players.PlayerAdded:Connect(refreshOwnership)
end

return VIPService
