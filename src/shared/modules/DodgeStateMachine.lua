-- GDD §3.3 / §17.1 / T-031. Pure dodge-roll timing state machine: tracks
-- when the last dodge started and answers "is this timestamp still inside
-- the i-frame window" / "can a new dodge start yet". Takes its durations as
-- constructor args rather than reading CombatConfig itself, so it stays
-- testable without any Roblox APIs — DodgeService (server) is the thin
-- Roblox-facing wrapper that reads CombatConfig and owns one instance of
-- this per player.

local DodgeStateMachine = {}
DodgeStateMachine.__index = DodgeStateMachine

export type DodgeStateMachine = typeof(setmetatable(
	{} :: {
		iFrameDuration: number,
		cooldownDuration: number,
		lastDodgeAt: number?,
	},
	DodgeStateMachine
))

function DodgeStateMachine.new(iFrameDuration: number, cooldownDuration: number): DodgeStateMachine
	return setmetatable({
		iFrameDuration = iFrameDuration,
		cooldownDuration = cooldownDuration,
		lastDodgeAt = nil :: number?,
	}, DodgeStateMachine)
end

-- Starts a new dodge at `now` if the cooldown from the previous dodge has
-- elapsed. Returns false (no state change) if still on cooldown.
function DodgeStateMachine.tryDodge(self: DodgeStateMachine, now: number): boolean
	if self.lastDodgeAt ~= nil and (now - self.lastDodgeAt) < self.cooldownDuration then
		return false
	end
	self.lastDodgeAt = now
	return true
end

-- True while `now` falls inside the i-frame window opened by the most
-- recent successful dodge.
function DodgeStateMachine.isInvulnerable(self: DodgeStateMachine, now: number): boolean
	if self.lastDodgeAt == nil then
		return false
	end
	local elapsed = now - self.lastDodgeAt
	return elapsed >= 0 and elapsed < self.iFrameDuration
end

return DodgeStateMachine
