--!strict
-- T-095 (GDD §9.7, §7.3). Per-chapter best ClearTime + StyleScore leaderboards
-- (all-time and weekly), plus a separate Trial Rush weekly board. Backed by
-- real OrderedDataStores per the DoD, using LeaderboardKey's (T-095, pure)
-- store-naming scheme so a weekly reset is just "start writing to a new
-- store name" — the previous week's store and the all-time store are never
-- touched by that rotation.
--
-- Submission is server-internal only (`SubmitClearTime`/`SubmitStyleScore`/
-- `SubmitTrialRushTime`) — never client-exposed, matching this codebase's
-- "never client-supplied" rule for anything that persists player-favorable
-- state (mirrors T-090's XP rule). Real callers (the chapter-clear and Trial
-- Rush flows, Phase 10, not built yet) don't exist yet; this is the same
-- shared trigger gap noted in ProgressionService/MasteryService.
--
-- DataStore I/O is live-service integration, not TestEZ-testable headlessly —
-- every call is pcall-guarded and warns rather than erroring on failure
-- (e.g. Studio without API access enabled), consistent with this being
-- Roblox-live-service territory the same way T-113/T-114's MarketplaceService
-- calls are.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local LeaderboardKey = require(ReplicatedStorage.Shared.modules.LeaderboardKey)
local QuestResetSchedule = require(ReplicatedStorage.Shared.modules.QuestResetSchedule)

local TRIAL_RUSH_CATEGORY = "TrialRush"
local TOP_ENTRIES_DEFAULT_LIMIT = 10
local FRIENDS_SCAN_LIMIT = 100 -- top entries fetched before filtering down to friends (first FriendPages page only)

local LeaderboardService = Knit.CreateService({
	Name = "LeaderboardService",
	Client = {},
})

local storeCache: { [string]: OrderedDataStore } = {}

local function getStore(name: string): OrderedDataStore
	local store = storeCache[name]
	if not store then
		store = DataStoreService:GetOrderedDataStore(name)
		storeCache[name] = store
	end
	return store
end

local function currentWeekId(): number
	return QuestResetSchedule.weeklyPeriodId(os.time())
end

local function submitBest(storeName: string, category: string, userId: number, value: number)
	local store = getStore(storeName)
	local key = tostring(userId)
	local ok, err = pcall(function()
		store:UpdateAsync(key, function(old: number?)
			if old == nil or LeaderboardKey.isBetter(category, value, old) then
				return value
			end
			return old
		end)
	end)
	if not ok then
		warn(`[LeaderboardService] submit failed for {storeName}/{key}: {tostring(err)}`)
	end
end

local function submitToAllScopes(category: string, chapterId: string, userId: number, value: number)
	submitBest(LeaderboardKey.storeName(category, chapterId, "AllTime"), category, userId, value)
	submitBest(LeaderboardKey.storeName(category, chapterId, "Weekly", currentWeekId()), category, userId, value)
end

-- Server-internal: real submission points, awaiting the chapter-clear flow
-- (Phase 10) as their caller.
function LeaderboardService:SubmitClearTime(player: Player, chapterId: string, timeSeconds: number)
	submitToAllScopes("ClearTime", chapterId, player.UserId, math.floor(timeSeconds))
end

function LeaderboardService:SubmitStyleScore(player: Player, chapterId: string, styleScore: number)
	submitToAllScopes("StyleScore", chapterId, player.UserId, math.floor(styleScore))
end

-- Server-internal: awaiting the Trial Rush mode (not built yet) as its caller.
-- Trial Rush has no chapter concept, so "Global" stands in for chapterId.
function LeaderboardService:SubmitTrialRushTime(player: Player, timeSeconds: number)
	submitBest(LeaderboardKey.storeName(TRIAL_RUSH_CATEGORY, "Global", "Weekly", currentWeekId()), "ClearTime", player.UserId, math.floor(timeSeconds))
end

type Entry = { UserId: number, Value: number }

local function fetchTopEntries(storeName: string, category: string, limit: number): { Entry }
	local store = getStore(storeName)
	local ascending = LeaderboardKey.sortAscending(category)
	local ok, pages = pcall(function()
		return store:GetSortedAsync(ascending, math.clamp(limit, 1, 100))
	end)
	if not ok or not pages then
		return {}
	end

	local page = (pages :: DataStorePages):GetCurrentPage()
	local results: { Entry } = {}
	for _, item in page do
		local userId = tonumber(item.key)
		if userId then
			table.insert(results, { UserId = userId, Value = item.value })
		end
	end
	return results
end

function LeaderboardService.Client:GetTopEntries(_player: Player, chapterId: string, category: string, scope: string, limit: number?): { Entry }
	local storeName = LeaderboardKey.storeName(category, chapterId, scope, currentWeekId())
	return fetchTopEntries(storeName, category, limit or TOP_ENTRIES_DEFAULT_LIMIT)
end

function LeaderboardService.Client:GetTrialRushTopEntries(_player: Player, limit: number?): { Entry }
	local storeName = LeaderboardKey.storeName(TRIAL_RUSH_CATEGORY, "Global", "Weekly", currentWeekId())
	return fetchTopEntries(storeName, "ClearTime", limit or TOP_ENTRIES_DEFAULT_LIMIT)
end

-- Friends-prioritized display (§12.4/§9.7): fetches a broader top-N slice
-- then filters to the requesting player's friends (first FriendPages page)
-- plus themself, preserving leaderboard order.
function LeaderboardService.Client:GetFriendsEntries(player: Player, chapterId: string, category: string, scope: string): { Entry }
	local storeName = LeaderboardKey.storeName(category, chapterId, scope, currentWeekId())
	local topEntries = fetchTopEntries(storeName, category, FRIENDS_SCAN_LIMIT)

	local friendIds: { [number]: boolean } = { [player.UserId] = true }
	local ok, friendPages = pcall(function()
		return Players:GetFriendsAsync(player.UserId)
	end)
	if ok and friendPages then
		local ok2 = pcall(function()
			for _, friend in (friendPages :: FriendPages):GetCurrentPage() do
				friendIds[friend.Id] = true
			end
		end)
		if not ok2 then
			warn(`[LeaderboardService] failed reading friends page for {player.UserId}`)
		end
	end

	local filtered: { Entry } = {}
	for _, entry in topEntries do
		if friendIds[entry.UserId] then
			table.insert(filtered, entry)
		end
	end
	return filtered
end

return LeaderboardService
