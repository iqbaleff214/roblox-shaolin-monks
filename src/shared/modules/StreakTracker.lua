-- T-094 (GDD §9.5). Pure streak bookkeeping for two independent mechanics:
--   * Login streak: consecutive daily logins (by QuestResetSchedule period
--     id). A missed day breaks the streak — it does NOT carry over as a
--     partial credit toward the next login. `registerLogin` enforces this by
--     resetting to 0 on a gap and letting today's login count as the fresh
--     start, so the observable result is exactly 1 (never anything derived
--     from the gap size, which is the off-by-one bug this guards against).
--   * In-run Flawless-arena streak: consecutive Flawless arena clears grant
--     an escalating Coin bonus per arena *after* the first (§9.5) — the
--     first Flawless clear itself banks no bonus, only extends the streak.

local StreakTracker = {}
StreakTracker.__index = StreakTracker

export type StreakTracker = typeof(setmetatable(
	{} :: {
		loginStreak: number,
		lastLoginPeriodId: number?,
		arenaFlawlessStreak: number,
	},
	StreakTracker
))

function StreakTracker.new(): StreakTracker
	return setmetatable({
		loginStreak = 0,
		lastLoginPeriodId = nil :: number?,
		arenaFlawlessStreak = 0,
	}, StreakTracker)
end

-- Registers a login at daily `periodId`. Returns (newStreak, milestoneReached).
function StreakTracker.registerLogin(self: StreakTracker, periodId: number, milestoneDays: number): (number, boolean)
	if self.lastLoginPeriodId == periodId then
		-- Same day (e.g. a rejoin) — no change, no double-counted milestone.
		return self.loginStreak, false
	elseif self.lastLoginPeriodId ~= nil and periodId == self.lastLoginPeriodId + 1 then
		self.loginStreak += 1
	else
		-- First-ever login, or a gap of 1+ missed days: streak breaks (-> 0)
		-- then today's login starts the fresh count at 1.
		self.loginStreak = 0
		self.loginStreak += 1
	end
	self.lastLoginPeriodId = periodId

	local milestoneReached = self.loginStreak % milestoneDays == 0
	return self.loginStreak, milestoneReached
end

-- Registers an arena clear. Returns (newArenaStreak, bonusCoins). A
-- non-Flawless clear breaks the streak and grants no bonus.
function StreakTracker.registerArenaClear(self: StreakTracker, wasFlawless: boolean, baseBonus: number, bonusPerStreak: number): (number, number)
	if not wasFlawless then
		self.arenaFlawlessStreak = 0
		return 0, 0
	end

	self.arenaFlawlessStreak += 1
	if self.arenaFlawlessStreak <= 1 then
		return self.arenaFlawlessStreak, 0
	end

	local bonus = baseBonus + (self.arenaFlawlessStreak - 2) * bonusPerStreak
	return self.arenaFlawlessStreak, bonus
end

return StreakTracker
