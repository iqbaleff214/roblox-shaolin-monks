-- T-048 (GDD §3.7, §9.1, §10.1). Live Combo Counter (rolling ~2s hit window)
-- feeding a banked, never-decreasing Style Score. Each hit scores the
-- combo's current length (so a 5-hit combo banks 1+2+3+4+5=15 — longer
-- combos are worth more per hit, rewarding sustained play over the same
-- number of hits split into shorter combos). Actual reward-scaling
-- (§9.1's multiplier table, §10.1) is Phase 7/9 territory; this module only
-- owns the score itself.

local StyleScoreTracker = {}
StyleScoreTracker.__index = StyleScoreTracker

StyleScoreTracker.DEFAULT_COMBO_RESET_WINDOW = 2 -- seconds, §3.7 "rolling ~2s hit window"

export type StyleScoreTracker = typeof(setmetatable(
	{} :: {
		comboResetWindow: number,
		comboCounter: number,
		styleScore: number,
		lastHitAt: number?,
	},
	StyleScoreTracker
))

function StyleScoreTracker.new(comboResetWindow: number?): StyleScoreTracker
	return setmetatable({
		comboResetWindow = comboResetWindow or StyleScoreTracker.DEFAULT_COMBO_RESET_WINDOW,
		comboCounter = 0,
		styleScore = 0,
		lastHitAt = nil :: number?,
	}, StyleScoreTracker)
end

-- Registers a hit at time `now`; if the rolling window lapsed since the last
-- hit, the live combo restarts at 0 first. Returns the new combo counter.
function StyleScoreTracker.registerHit(self: StyleScoreTracker, now: number): number
	if self.lastHitAt ~= nil and (now - self.lastHitAt) > self.comboResetWindow then
		self.comboCounter = 0
	end
	self.comboCounter += 1
	self.styleScore += self.comboCounter
	self.lastHitAt = now
	return self.comboCounter
end

-- Explicit reset (the player got hit, or the arena ended). Only clears the
-- live counter — banked Style Score is never reduced by a reset (§3.7).
function StyleScoreTracker.resetCombo(self: StyleScoreTracker)
	self.comboCounter = 0
	self.lastHitAt = nil :: number?
end

return StyleScoreTracker
