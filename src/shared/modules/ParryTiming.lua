-- T-043 (GDD §3.3). Classifies a block input's timing relative to an
-- incoming hit into "PerfectParry" (full negate + stun attacker), "Block"
-- (partial mitigation — holding block, but not timed precisely), or "None"
-- (not blocking, or blocked too late to matter at all).

local ParryTiming = {}

export type ParryResult = "PerfectParry" | "Block" | "None"

-- `timingDelta` = (block input time) - (impact time), in seconds.
--   negative -> blocked before impact (by |timingDelta| seconds) — good
--   positive -> blocked after impact — already too late, even for a block
--   nil      -> never blocked at all
function ParryTiming.classify(timingDelta: number?, parryWindow: number): ParryResult
	if timingDelta == nil then
		return "None"
	end
	if timingDelta > 0 then
		return "None" -- the hit already landed before the block input registered
	end
	if -timingDelta <= parryWindow then
		return "PerfectParry"
	end
	return "Block"
end

return ParryTiming
