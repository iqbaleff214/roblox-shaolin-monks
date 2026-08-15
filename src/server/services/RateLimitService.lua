--!strict
-- T-171 (GDD §17.2). Server-internal-only guard other services call at the
-- top of a high-frequency Client method: `if not
-- Knit.GetService("RateLimitService"):TryConsume(player,
-- "CombatService.RequestAttack") then return <safe default> end`. Excess
-- calls are dropped silently — the player is never disconnected or warned,
-- matching the DoD's "blunt spam without breaking legitimate fast-combo
-- play."
--
-- Wraps the pure RateLimiter (token bucket) module with per-(player,
-- actionKey) bucket storage. `actionKey` is always `ServiceName.MethodName`
-- (see AntiCheatConfig's header) so two services can share a method name
-- (e.g. ComboScrollShopService/CosmeticShopService both have
-- `RequestPurchase`) without their buckets colliding.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)
local RateLimiter = require(ReplicatedStorage.Shared.modules.RateLimiter)

local AntiCheatConfig = ConfigService.AntiCheat

local RateLimitService = Knit.CreateService({
	Name = "RateLimitService",
	Client = {},
})

local bucketsByPlayer: { [Player]: { [string]: RateLimiter.BucketState } } = {}

local function getLimit(actionKey: string): { MaxTokens: number, RefillPerSecond: number }
	return AntiCheatConfig.RateLimits[actionKey] or AntiCheatConfig.DefaultRateLimit
end

-- Server-internal: returns true if this call is within `actionKey`'s
-- configured rate limit (and consumes one token), false if it should be
-- dropped.
function RateLimitService:TryConsume(player: Player, actionKey: string): boolean
	local buckets = bucketsByPlayer[player]
	if not buckets then
		buckets = {}
		bucketsByPlayer[player] = buckets
	end

	local limit = getLimit(actionKey)
	local bucket = buckets[actionKey] or RateLimiter.newBucket(limit.MaxTokens)

	local allowed, nextBucket = RateLimiter.tryConsume(bucket, os.clock(), limit.MaxTokens, limit.RefillPerSecond)
	buckets[actionKey] = nextBucket
	return allowed
end

function RateLimitService:KnitInit()
	Players.PlayerRemoving:Connect(function(player)
		bucketsByPlayer[player] = nil
	end)
end

return RateLimitService
