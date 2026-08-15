-- T-050 (GDD §4.3, §4.4). Server-side token allocator enforcing the 2-3
-- concurrent-attacker cap: only enemies holding a token may enter the
-- Attacking state; the rest hold in the ring/circling state (§4.3). Keyed by
-- opaque attacker identifiers so it doesn't need EnemyController (T-060,
-- Phase 4) to exist — any caller-supplied key works, including a plain table
-- in tests.

local AttackerTokenPool = {}
AttackerTokenPool.__index = AttackerTokenPool

export type AttackerTokenPool = typeof(setmetatable(
	{} :: {
		capacity: number,
		holders: { [any]: boolean },
		count: number,
	},
	AttackerTokenPool
))

function AttackerTokenPool.new(capacity: number): AttackerTokenPool
	return setmetatable({
		capacity = capacity,
		holders = {},
		count = 0,
	}, AttackerTokenPool)
end

-- Requests a token for `attacker`. Returns true if granted (or already
-- held — idempotent), false if the pool is already at capacity.
function AttackerTokenPool.request(self: AttackerTokenPool, attacker: any): boolean
	if self.holders[attacker] then
		return true
	end
	if self.count >= self.capacity then
		return false
	end
	self.holders[attacker] = true
	self.count += 1
	return true
end

-- Releases `attacker`'s token, if held. Safe to call even if they never held
-- one.
function AttackerTokenPool.release(self: AttackerTokenPool, attacker: any)
	if self.holders[attacker] then
		self.holders[attacker] = nil
		self.count -= 1
	end
end

function AttackerTokenPool.isHolding(self: AttackerTokenPool, attacker: any): boolean
	return self.holders[attacker] == true
end

function AttackerTokenPool.activeCount(self: AttackerTokenPool): number
	return self.count
end

return AttackerTokenPool
