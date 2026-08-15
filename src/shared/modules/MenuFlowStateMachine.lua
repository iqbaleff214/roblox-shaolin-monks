-- T-133 (GDD §15.3). Pure menu flow state machine: Lobby -> Chapter Select
-- -> Party Setup -> Loadout Check -> Ready -> Load, with every state able to
-- step back exactly one stage. Chaining those back-steps always reaches
-- Lobby, so no state is ever a dead end (T-133's DoD) without needing a
-- separate "path to Lobby" table to keep in sync with ORDER.

local MenuFlowStateMachine = {}
MenuFlowStateMachine.__index = MenuFlowStateMachine

MenuFlowStateMachine.ORDER = { "Lobby", "ChapterSelect", "PartySetup", "LoadoutCheck", "Ready", "Load" }

local INDEX_BY_STATE: { [string]: number } = {}
for index, state in MenuFlowStateMachine.ORDER do
	INDEX_BY_STATE[state] = index
end

export type MenuFlowStateMachine = typeof(setmetatable({} :: { index: number }, MenuFlowStateMachine))

function MenuFlowStateMachine.new(): MenuFlowStateMachine
	return setmetatable({ index = 1 }, MenuFlowStateMachine)
end

function MenuFlowStateMachine.current(self: MenuFlowStateMachine): string
	return MenuFlowStateMachine.ORDER[self.index]
end

-- Advances exactly one stage forward. Returns false (no change) if already
-- at the final stage.
function MenuFlowStateMachine.advance(self: MenuFlowStateMachine): boolean
	if self.index >= #MenuFlowStateMachine.ORDER then
		return false
	end
	self.index += 1
	return true
end

-- Steps back exactly one stage. Returns false (no change) if already at Lobby.
function MenuFlowStateMachine.back(self: MenuFlowStateMachine): boolean
	if self.index <= 1 then
		return false
	end
	self.index -= 1
	return true
end

-- Jumps directly to `state` (e.g. a menu button that skips ahead/back to a
-- specific screen). Returns false for an unrecognized state name.
function MenuFlowStateMachine.goTo(self: MenuFlowStateMachine, state: string): boolean
	local index = INDEX_BY_STATE[state]
	if not index then
		return false
	end
	self.index = index
	return true
end

return MenuFlowStateMachine
