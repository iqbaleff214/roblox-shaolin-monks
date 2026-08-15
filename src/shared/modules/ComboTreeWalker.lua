-- T-041 (GDD §3.2, §10.3). Walks a weapon's ComboTree (WeaponConfig) one
-- input at a time, respecting ComboWindow and the player's unlocked depth
-- (how many Combo Scrolls they own, §10.3). Pure state machine — CombatService
-- owns one instance per player and feeds it validated input events.
--
-- Unlocked-depth seam: the Combo Scroll shop (T-111) and player inventory
-- (T-081/T-160) don't exist yet. Callers pass `unlockedDepth` explicitly;
-- DEFAULT_UNLOCKED_DEPTH is the baseline every player starts with (their
-- first Light hit) until those systems are wired in.

local ComboTreeWalker = {}
ComboTreeWalker.__index = ComboTreeWalker

ComboTreeWalker.DEFAULT_UNLOCKED_DEPTH = 1

export type ComboStep = {
	Input: string,
	DamageMultiplier: number,
	FrameTime: number,
	AnimationId: number,
}

export type ComboTreeWalker = typeof(setmetatable(
	{} :: {
		comboTree: { ComboStep },
		comboWindow: number,
		unlockedDepth: number,
		currentStep: number,
		lastInputAt: number?,
	},
	ComboTreeWalker
))

function ComboTreeWalker.new(comboTree: { ComboStep }, comboWindow: number, unlockedDepth: number?): ComboTreeWalker
	return setmetatable({
		comboTree = comboTree,
		comboWindow = comboWindow,
		unlockedDepth = unlockedDepth or ComboTreeWalker.DEFAULT_UNLOCKED_DEPTH,
		currentStep = 0, -- 0 = no combo in progress
		lastInputAt = nil :: number?,
	}, ComboTreeWalker)
end

-- Attempts to advance the combo with `inputType` ("Light"/"Heavy") at time
-- `now`. Returns the new 1-based step index on success, or nil if the input
-- had no effect (window expired and this restarts at step 1 next call, past
-- the unlocked depth, past the end of the tree, or the wrong input type for
-- the next step — a mistimed Heavy doesn't erase Light progress, it's just
-- dropped).
function ComboTreeWalker.advance(self: ComboTreeWalker, inputType: string, now: number): number?
	if self.lastInputAt ~= nil and (now - self.lastInputAt) > self.comboWindow then
		self.currentStep = 0
	end

	local nextStep = self.currentStep + 1
	if nextStep > self.unlockedDepth or nextStep > #self.comboTree then
		return nil
	end

	local stepData = self.comboTree[nextStep]
	if stepData.Input ~= inputType then
		return nil
	end

	self.currentStep = nextStep
	self.lastInputAt = now
	return nextStep
end

function ComboTreeWalker.getCurrentStepData(self: ComboTreeWalker): ComboStep?
	if self.currentStep == 0 then
		return nil
	end
	return self.comboTree[self.currentStep]
end

function ComboTreeWalker.reset(self: ComboTreeWalker)
	self.currentStep = 0
	self.lastInputAt = nil :: number?
end

return ComboTreeWalker
