-- T-095 (GDD §9.7, §7.3). Pure helpers for the leaderboard's DataStore
-- naming scheme and "is this a better score" comparison.
--
-- The weekly/all-time split (DoD: "resetting on schedule without losing
-- all-time records") is achieved entirely through the store NAME: the
-- all-time store name is stable forever, while the weekly store name embeds
-- the current week's period id, so a new week automatically starts writing
-- to a brand-new, empty OrderedDataStore without ever touching the frozen
-- previous week's store or the all-time store.

local LeaderboardKey = {}

function LeaderboardKey.storeName(category: string, chapterId: string, scope: string, weekId: number?): string
	if scope == "Weekly" then
		return `SMA_{category}_{chapterId}_W{weekId}`
	end
	return `SMA_{category}_{chapterId}_AllTime`
end

-- ClearTime: lower is better. StyleScore (and everything else): higher is better.
function LeaderboardKey.isBetter(category: string, newValue: number, oldValue: number): boolean
	if category == "ClearTime" then
		return newValue < oldValue
	end
	return newValue > oldValue
end

-- OrderedDataStore's GetSortedAsync needs an explicit ascending flag: ClearTime
-- wants the smallest value first, everything else wants the largest first.
function LeaderboardKey.sortAscending(category: string): boolean
	return category == "ClearTime"
end

return LeaderboardKey
