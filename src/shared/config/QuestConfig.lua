-- GDD §9.4 / §7.4 / §7.3. Daily/Weekly quest definitions — reward type and
-- amount are config-driven per the "no magic numbers" rule (§14); QuestService
-- only interprets IDs and progress, never hardcodes a reward number.

local QuestConfig = {}

QuestConfig.ResetHourUTC = 0 -- daily reset at midnight UTC (§7.4); weekly reset uses the same hour on the Monday boundary

QuestConfig.Daily = {
	{ Id = "LandFinishingMoves", Description = "Land 5 Finishing Moves", Goal = 5, RewardType = "Coins", RewardAmount = 200 },
	{ Id = "BreakContainers", Description = "Break 20 destructible containers", Goal = 20, RewardType = "Coins", RewardAmount = 150 },
	{ Id = "ClearChapterNoDeath", Description = "Clear a chapter without dying", Goal = 1, RewardType = "XP", RewardAmount = 300 },
}

QuestConfig.Weekly = {
	{ Id = "ClearTrialRush", Description = "Clear Trial Rush", Goal = 1, RewardType = "Title", RewardValue = "TrialRusher" },
	{ Id = "DefeatDistinctBosses", Description = "Defeat 3 different bosses", Goal = 3, RewardType = "CosmeticCrate", RewardValue = "Rare" },
	{ Id = "FindHiddenRelics", Description = "Find 3 hidden relic containers", Goal = 3, RewardType = "Coins", RewardAmount = 1000 },
}

return QuestConfig
