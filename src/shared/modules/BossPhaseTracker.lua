-- T-065 (GDD §4.5). HP-banded phase tracker for bosses (3 phases) and Elite
-- Champions (1 phase — "condensed 1-phase version" per the DoD, same module,
-- just constructed with `phaseCount = 1`, never a separate implementation).
--
-- Phase boundaries split maxHealth into `phaseCount` even bands; crossing
-- down into a lower band opens a brief invulnerable transition window
-- (during which EnemyController must reject damage — enforcement lives
-- there, this module only tracks the window) plus one grab-counter window
-- and one parry-punish window per phase.

local BossPhaseTracker = {}
BossPhaseTracker.__index = BossPhaseTracker

export type BossPhaseTracker = typeof(setmetatable(
	{} :: {
		maxHealth: number,
		phaseCount: number,
		currentPhase: number,
		isInvulnerable: boolean,
		invulnerableUntil: number,
		counterWindowUntil: number,
		parryPunishWindowUntil: number,
	},
	BossPhaseTracker
))

function BossPhaseTracker.new(maxHealth: number, phaseCount: number): BossPhaseTracker
	return setmetatable({
		maxHealth = maxHealth,
		phaseCount = math.max(phaseCount, 1),
		currentPhase = 1,
		isInvulnerable = false,
		invulnerableUntil = 0,
		counterWindowUntil = 0,
		parryPunishWindowUntil = 0,
	}, BossPhaseTracker)
end

-- 1-indexed phase for a given HP value; phase `phaseCount` is the lowest
-- (final) HP band, phase 1 is full health.
local function phaseForHealth(health: number, maxHealth: number, phaseCount: number): number
	if phaseCount <= 1 then
		return 1
	end
	local bandSize = maxHealth / phaseCount
	local phase = phaseCount - math.floor(math.max(health, 0) / bandSize)
	return math.clamp(phase, 1, phaseCount)
end

-- Call after applying damage, with the resulting HP. Returns true exactly
-- once per threshold crossing and opens the invulnerable transition window.
function BossPhaseTracker.checkPhaseTransition(self: BossPhaseTracker, currentHealth: number, now: number, invulnerableDuration: number): boolean
	if self.currentPhase >= self.phaseCount then
		return false -- already in the final phase; nothing left to cross into
	end
	local newPhase = phaseForHealth(currentHealth, self.maxHealth, self.phaseCount)
	if newPhase > self.currentPhase then
		self.currentPhase = newPhase
		self.isInvulnerable = true
		self.invulnerableUntil = now + invulnerableDuration
		return true
	end
	return false
end

-- Must be polled (or checked at damage-application time) so the
-- invulnerability window actually expires once its duration elapses.
function BossPhaseTracker.updateInvulnerability(self: BossPhaseTracker, now: number)
	if self.isInvulnerable and now >= self.invulnerableUntil then
		self.isInvulnerable = false
	end
end

function BossPhaseTracker.openCounterWindow(self: BossPhaseTracker, now: number, duration: number)
	self.counterWindowUntil = now + duration
end

function BossPhaseTracker.isCounterWindowOpen(self: BossPhaseTracker, now: number): boolean
	return now < self.counterWindowUntil
end

function BossPhaseTracker.openParryPunishWindow(self: BossPhaseTracker, now: number, duration: number)
	self.parryPunishWindowUntil = now + duration
end

function BossPhaseTracker.isParryPunishWindowOpen(self: BossPhaseTracker, now: number): boolean
	return now < self.parryPunishWindowUntil
end

return BossPhaseTracker
