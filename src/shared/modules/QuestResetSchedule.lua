-- T-093 (GDD §9.4, §7.4, §7.3). Pure calendar-boundary math: converts a Unix
-- timestamp into a "period id" for daily (midnight UTC, shifted by the
-- configured reset hour) and weekly (Monday 00:00 UTC) cadences. Two moments
-- share a period id iff they fall in the same reset window; QuestService (and
-- StreakService, T-094, which reuses the daily id for login-streak tracking)
-- only needs to compare ids, never parse a calendar itself.
--
-- Uses os.time/os.date (pure Luau stdlib, not a Roblox API) so this stays
-- testable without any game/service dependency.

local SECONDS_PER_DAY = 86400
local SECONDS_PER_WEEK = SECONDS_PER_DAY * 7
-- Unix epoch (1970-01-01) was a Thursday, 3 days after the preceding Monday.
-- Shifting every timestamp forward by those 3 days makes `floor(shifted /
-- SECONDS_PER_WEEK)` flip exactly on Monday 00:00 UTC instead of on the
-- epoch's own Thursday-aligned week boundary.
local MONDAY_EPOCH_OFFSET_SECONDS = SECONDS_PER_DAY * 3

local QuestResetSchedule = {}

function QuestResetSchedule.dailyPeriodId(unixTime: number, resetHourUTC: number): number
	local shifted = unixTime - resetHourUTC * 3600
	return math.floor(shifted / SECONDS_PER_DAY)
end

function QuestResetSchedule.weeklyPeriodId(unixTime: number): number
	local shifted = unixTime + MONDAY_EPOCH_OFFSET_SECONDS
	return math.floor(shifted / SECONDS_PER_WEEK)
end

return QuestResetSchedule
