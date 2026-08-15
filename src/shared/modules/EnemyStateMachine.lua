-- T-060 (GDD §4). Pure state graph shared by every enemy role — the state
-- machine itself never forks per role; EnemyController plugs role-specific
-- *behavior* (T-062) into each state via EnemyConfig.Roles data, never by
-- branching this graph.
--
-- Idle -> Aggro -> Circling -> Attacking -> Staggered -> Dead, with the
-- realistic side-paths a live fight needs: losing aggro back to Idle,
-- getting staggered from any active-combat state, and dying from anywhere.

local EnemyStateMachine = {}
EnemyStateMachine.__index = EnemyStateMachine

export type EnemyState = "Idle" | "Aggro" | "Circling" | "Attacking" | "Staggered" | "Dead"

local VALID_TRANSITIONS: { [EnemyState]: { [EnemyState]: boolean } } = {
	Idle = { Aggro = true, Dead = true },
	Aggro = { Circling = true, Staggered = true, Dead = true, Idle = true },
	Circling = { Attacking = true, Staggered = true, Dead = true, Idle = true },
	Attacking = { Circling = true, Staggered = true, Dead = true },
	-- Recovered (Finishing Move / phase transition consumed it, or the §3.9
	-- auto-recovery timer elapsed) back to Circling, or finished off outright.
	Staggered = { Circling = true, Dead = true },
	Dead = {}, -- terminal; no legal transitions out
}

export type EnemyStateMachine = typeof(setmetatable(
	{} :: {
		state: EnemyState,
	},
	EnemyStateMachine
))

function EnemyStateMachine.new(initialState: EnemyState?): EnemyStateMachine
	return setmetatable({ state = initialState or "Idle" }, EnemyStateMachine)
end

-- Attempts to transition to `newState`. Returns true and updates state if
-- the transition is legal per the graph above; returns false (no change,
-- e.g. an illegal jump like Idle -> Attacking) otherwise.
function EnemyStateMachine.transition(self: EnemyStateMachine, newState: EnemyState): boolean
	local allowed = VALID_TRANSITIONS[self.state]
	if allowed and allowed[newState] then
		self.state = newState
		return true
	end
	return false
end

function EnemyStateMachine.is(self: EnemyStateMachine, state: EnemyState): boolean
	return self.state == state
end

return EnemyStateMachine
