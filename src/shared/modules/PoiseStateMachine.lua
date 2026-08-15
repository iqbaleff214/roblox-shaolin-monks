-- T-046 (GDD §3.9, §4.5). Per-target Poise: fills on hits, decays over time
-- when untouched, and locks into a Staggered state once it crosses the
-- threshold — the state that gates a Finishing Move input (§3.9), or a boss/
-- Elite's phase transition instead (§4.5, hands off to T-065). One instance
-- per hittable target (enemy, boss, or Elite), owned by CombatService.

local PoiseStateMachine = {}
PoiseStateMachine.__index = PoiseStateMachine

export type PoiseStateMachine = typeof(setmetatable(
	{} :: {
		threshold: number,
		decayPerSecond: number,
		poise: number,
		lastUpdatedAt: number,
		isStaggered: boolean,
	},
	PoiseStateMachine
))

function PoiseStateMachine.new(threshold: number, decayPerSecond: number, now: number): PoiseStateMachine
	return setmetatable({
		threshold = threshold,
		decayPerSecond = decayPerSecond,
		poise = 0,
		lastUpdatedAt = now,
		isStaggered = false,
	}, PoiseStateMachine)
end

-- Staggered targets don't passively decay out of the state — only
-- clearStagger() resets them (Finishing Move landed, or a phase transition
-- consumed it).
local function applyDecay(self: PoiseStateMachine, now: number)
	if not self.isStaggered then
		local elapsed = now - self.lastUpdatedAt
		if elapsed > 0 then
			self.poise = math.max(0, self.poise - self.decayPerSecond * elapsed)
		end
	end
	self.lastUpdatedAt = now
end

-- Registers a hit's poise damage at time `now`. Returns true exactly once —
-- on the hit that crosses the Stagger threshold.
function PoiseStateMachine.applyHit(self: PoiseStateMachine, poiseDamage: number, now: number): boolean
	applyDecay(self, now)
	if self.isStaggered then
		return false -- already staggered; doesn't re-trigger
	end
	self.poise += poiseDamage
	if self.poise >= self.threshold then
		self.isStaggered = true
		return true
	end
	return false
end

-- Advances passive decay without registering a hit; call periodically so
-- Poise drains even between hits.
function PoiseStateMachine.tick(self: PoiseStateMachine, now: number)
	applyDecay(self, now)
end

-- Finishing Move landed (or a boss/Elite phase transition consumed the
-- stagger, §4.5) — resets to a fresh bar.
function PoiseStateMachine.clearStagger(self: PoiseStateMachine, now: number)
	self.isStaggered = false
	self.poise = 0
	self.lastUpdatedAt = now
end

return PoiseStateMachine
