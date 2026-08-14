-- GDD §3.1 / T-032. Pure fire-once-per-press-with-reset-delay gate, shared by
-- every traversal interactable type (Lever, PressurePlate, CollapsingWalkway)
-- so TraversalInteractableService doesn't hand-roll debounce logic per tag.

local DebounceGate = {}
DebounceGate.__index = DebounceGate

export type DebounceGate = typeof(setmetatable(
	{} :: {
		resetDelay: number,
		lastFiredAt: number?,
	},
	DebounceGate
))

function DebounceGate.new(resetDelay: number): DebounceGate
	return setmetatable({
		resetDelay = resetDelay,
		lastFiredAt = nil :: number?,
	}, DebounceGate)
end

-- Returns true (and records `now`) exactly once per `resetDelay` window;
-- returns false without side effects if still within the window.
function DebounceGate.tryFire(self: DebounceGate, now: number): boolean
	if self.lastFiredAt ~= nil and (now - self.lastFiredAt) < self.resetDelay then
		return false
	end
	self.lastFiredAt = now
	return true
end

return DebounceGate
