-- T-163 (GDD §17.3). Schema-versioned player profile with safe defaults for
-- fields that don't exist yet in an older save. `migrate` never errors on a
-- payload missing (or entirely lacking) fields — every field not present in
-- `savedData` is filled from `DEFAULT_PROFILE`, and the result is always
-- stamped with `CURRENT_SCHEMA_VERSION`, so a new field added post-launch
-- (a future system needing a new save slot) never breaks an existing save;
-- it just adopts the default the next time that player loads, and persists
-- for real on their next save.
--
-- Field coverage matches GDD §17.3's list: level, XP, Coins, Jade,
-- inventory, skill tree allocation, chapter progress, quest progress,
-- mastery stars, streak — plus BattlePass tier XP/claims, the one Phase 9
-- system GDD's §17.3 list predates.

local PlayerProfileMigration = {}

PlayerProfileMigration.CURRENT_SCHEMA_VERSION = 1

export type PlayerProfile = {
	SchemaVersion: number,
	Level: number,
	TotalXP: number,
	AvailableSkillPoints: number,
	Coins: number,
	Jade: number,
	Inventory: { [string]: { [string]: any } },
	SkillTree: { [string]: number },
	ChapterProgress: { [string]: boolean },
	QuestProgress: {
		DailyPeriodId: number?,
		WeeklyPeriodId: number?,
		Daily: { [string]: any },
		Weekly: { [string]: any },
		DistinctBossesDefeated: { [string]: boolean },
	},
	MasteryStars: { [string]: number },
	LoginStreak: number,
	LastLoginPeriodId: number?,
	BattlePassTierXP: number,
	BattlePassClaimed: { [string]: boolean },
}

local function defaultProfile(): PlayerProfile
	return {
		SchemaVersion = PlayerProfileMigration.CURRENT_SCHEMA_VERSION,
		Level = 0,
		TotalXP = 0,
		AvailableSkillPoints = 0,
		Coins = 0,
		Jade = 0,
		Inventory = {},
		SkillTree = {},
		ChapterProgress = {},
		QuestProgress = {
			DailyPeriodId = nil :: number?,
			WeeklyPeriodId = nil :: number?,
			Daily = {},
			Weekly = {},
			DistinctBossesDefeated = {},
		},
		MasteryStars = {},
		LoginStreak = 0,
		LastLoginPeriodId = nil :: number?,
		BattlePassTierXP = 0,
		BattlePassClaimed = {},
	}
end

-- `savedData` is whatever the DataStore returned (nil for a brand-new
-- player, a table for a returning one — possibly from an older schema
-- version, missing fields this version added). Returns a complete,
-- safe-defaulted profile; never mutates `savedData` or shares any table
-- reference with a previous call's defaults.
function PlayerProfileMigration.migrate(savedData: any?): PlayerProfile
	local profile = defaultProfile()
	if type(savedData) == "table" then
		for key, value in savedData :: { [string]: any } do
			if (profile :: { [string]: any })[key] ~= nil or key == "SchemaVersion" then
				(profile :: { [string]: any })[key] = value
			end
		end
	end
	profile.SchemaVersion = PlayerProfileMigration.CURRENT_SCHEMA_VERSION
	return profile
end

return PlayerProfileMigration
