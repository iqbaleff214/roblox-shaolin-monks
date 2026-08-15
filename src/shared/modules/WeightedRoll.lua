-- T-101/T-102 (GDD §17.5, §10.4). Generic weighted pick over an explicit,
-- caller-ordered list of {key, weight} entries. Takes the order as an
-- explicit list (not a plain `{[key]: weight}` dictionary) rather than
-- iterating a dictionary with `pairs`/generic-for internally, so the result
-- is deterministic purely by construction — it never depends on incidental
-- Luau table-iteration order, which §17.5's "reproducible given the same
-- seed" requirement can't tolerate leaving to chance.

local WeightedRoll = {}

export type Entry = { key: string, weight: number }

function WeightedRoll.pick(rng: Random, entries: { Entry }): string
	local total = 0
	for _, entry in entries do
		total += entry.weight
	end

	local roll = rng:NextNumber(0, total)
	local cumulative = 0
	for _, entry in entries do
		cumulative += entry.weight
		if roll <= cumulative then
			return entry.key
		end
	end

	return entries[#entries].key -- floating-point safety net
end

return WeightedRoll
