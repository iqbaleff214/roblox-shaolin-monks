-- T-047 (GDD §3.6). Chi meter fill/cap/activation gate. Execution of the
-- Ultimate itself belongs to T-072 (Phase 5, not built yet) — this module
-- only owns the meter and the "is it legal to activate" gate; CombatService
-- fires an `UltimateActivated` signal on a successful `tryActivate()` for
-- T-072 to pick up once it exists.

local ChiMeterState = {}
ChiMeterState.__index = ChiMeterState

export type ChiMeterState = typeof(setmetatable(
	{} :: {
		max: number,
		value: number,
	},
	ChiMeterState
))

function ChiMeterState.new(max: number): ChiMeterState
	return setmetatable({ max = max, value = 0 }, ChiMeterState)
end

function ChiMeterState.gain(self: ChiMeterState, amount: number)
	self.value = math.min(self.max, math.max(0, self.value + amount))
end

function ChiMeterState.isFull(self: ChiMeterState): boolean
	return self.value >= self.max
end

-- Attempts to activate the Ultimate. Only succeeds (and resets the meter to
-- 0) when the meter is full; otherwise leaves state untouched.
function ChiMeterState.tryActivate(self: ChiMeterState): boolean
	if not self:isFull() then
		return false
	end
	self.value = 0
	return true
end

return ChiMeterState
