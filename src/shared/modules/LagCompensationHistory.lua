-- T-042 (GDD §17.1). Per-target position history ring buffer + rewind
-- lookup — the "favor the attacker" mechanism: the server rewinds an enemy's
-- hitbox to where it actually was at the attacker's reported input
-- timestamp before committing damage, rather than trusting current position.
-- CombatService owns one instance per Enemy-tagged target.

local LagCompensationHistory = {}
LagCompensationHistory.__index = LagCompensationHistory

-- Comfortably covers realistic ping (§17.1); older snapshots are trimmed on
-- every record() so memory stays bounded regardless of session length.
LagCompensationHistory.DEFAULT_BUFFER_DURATION = 1

export type Snapshot = { time: number, position: Vector3 }

export type LagCompensationHistory = typeof(setmetatable(
	{} :: {
		bufferDuration: number,
		snapshots: { Snapshot },
	},
	LagCompensationHistory
))

function LagCompensationHistory.new(bufferDuration: number?): LagCompensationHistory
	return setmetatable({
		bufferDuration = bufferDuration or LagCompensationHistory.DEFAULT_BUFFER_DURATION,
		snapshots = {},
	}, LagCompensationHistory)
end

-- Records `position` at time `now`, then trims anything older than the
-- buffer duration. Snapshots must be recorded in non-decreasing time order.
function LagCompensationHistory.record(self: LagCompensationHistory, position: Vector3, now: number)
	table.insert(self.snapshots, { time = now, position = position })
	local cutoff = now - self.bufferDuration
	while #self.snapshots > 0 and self.snapshots[1].time < cutoff do
		table.remove(self.snapshots, 1)
	end
end

-- Returns the target's interpolated position at `targetTime`, clamped to the
-- oldest/newest recorded snapshot if out of range. Returns nil if nothing
-- has been recorded yet.
function LagCompensationHistory.rewind(self: LagCompensationHistory, targetTime: number): Vector3?
	local count = #self.snapshots
	if count == 0 then
		return nil
	end
	if targetTime <= self.snapshots[1].time then
		return self.snapshots[1].position
	end
	if targetTime >= self.snapshots[count].time then
		return self.snapshots[count].position
	end
	for i = 1, count - 1 do
		local a, b = self.snapshots[i], self.snapshots[i + 1]
		if targetTime >= a.time and targetTime <= b.time then
			local span = b.time - a.time
			local alpha = if span > 0 then (targetTime - a.time) / span else 0
			return a.position:Lerp(b.position, alpha)
		end
	end
	return self.snapshots[count].position -- unreachable; satisfies strict return typing
end

return LagCompensationHistory
