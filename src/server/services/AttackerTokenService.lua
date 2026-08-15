--!strict
-- T-050 (GDD §4.3, §4.4). Thin Knit wrapper around AttackerTokenPool, one
-- pool per "encounter" (`poolId`, caller-defined — e.g. an arena id). Purely
-- server-internal: EnemyController (T-060, Phase 4) will `Knit.GetService`
-- this directly and request/release a token as it transitions an enemy
-- into/out of the Attacking state. No Client table — nothing here is ever
-- called by a player's own client.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)
local AttackerTokenPool = require(ReplicatedStorage.Shared.modules.AttackerTokenPool)

local AttackerTokenService = Knit.CreateService({
	Name = "AttackerTokenService",
})

local pools: { [string]: AttackerTokenPool.AttackerTokenPool } = {}

local function getPool(poolId: string): AttackerTokenPool.AttackerTokenPool
	local pool = pools[poolId]
	if not pool then
		pool = AttackerTokenPool.new(ConfigService.Enemy.ConcurrentAttackerCap)
		pools[poolId] = pool
	end
	return pool
end

function AttackerTokenService:RequestToken(poolId: string, attacker: any): boolean
	return getPool(poolId):request(attacker)
end

function AttackerTokenService:ReleaseToken(poolId: string, attacker: any)
	getPool(poolId):release(attacker)
end

function AttackerTokenService:IsHoldingToken(poolId: string, attacker: any): boolean
	return getPool(poolId):isHolding(attacker)
end

-- Called when an arena/encounter ends (e.g. T-061's gate unseals) so the
-- pool doesn't linger forever.
function AttackerTokenService:ReleasePool(poolId: string)
	pools[poolId] = nil
end

return AttackerTokenService
