-- T-116 (GDD §11.5). Pure expiry check + deterministic candidate picking for
-- limited-time item rotation. Takes `now`/`seed` as explicit arguments
-- (no hidden wall-clock/RNG state), matching every other pure module's
-- discipline in this codebase.

local RotationSchedule = {}

function RotationSchedule.isExpired(startedAt: number, now: number, durationHours: number): boolean
	return (now - startedAt) >= durationHours * 3600
end

-- Picks up to `count` distinct items from `pool`, skipping anything in
-- `excluded`. Sorts the candidate list first so the result is deterministic
-- for a given seed regardless of incidental table-iteration order (the same
-- discipline WeightedRoll documents).
function RotationSchedule.pickRotation(pool: { string }, excluded: { [string]: boolean }, count: number, seed: number): { string }
	local candidates = {}
	for _, id in pool do
		if not excluded[id] then
			table.insert(candidates, id)
		end
	end
	table.sort(candidates)

	local rng = Random.new(seed)
	local picked = {}
	for _ = 1, math.min(count, #candidates) do
		local index = rng:NextInteger(1, #candidates)
		table.insert(picked, candidates[index])
		table.remove(candidates, index)
	end
	return picked
end

return RotationSchedule
