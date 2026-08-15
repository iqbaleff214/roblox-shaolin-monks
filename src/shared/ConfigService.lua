-- GDD §14.6. The single require point for every config module. Gameplay and
-- UI scripts require ConfigService, never an individual config.X file
-- directly (T-151's lint enforces this later); config modules may still
-- require each other internally (e.g. WeaponConfig reads CombatConfig's base
-- damage) since that's config-to-config composition, not a bypass.

local Config = {
	Combat = require(script.Parent.config.CombatConfig),
	Weapon = require(script.Parent.config.WeaponConfig),
	Enemy = require(script.Parent.config.EnemyConfig),
	Chapter = require(script.Parent.config.ChapterConfig),
	Loot = require(script.Parent.config.LootConfig),
	Accessory = require(script.Parent.config.AccessoryConfig),
	Progression = require(script.Parent.config.ProgressionConfig),
	Shop = require(script.Parent.config.ShopConfig),
	Monetization = require(script.Parent.config.MonetizationConfig),
	Audio = require(script.Parent.config.AudioConfig),
	UI = require(script.Parent.config.UIConfig),
	Localization = require(script.Parent.config.LocalizationConfig),
	Quest = require(script.Parent.config.QuestConfig),
	BattlePass = require(script.Parent.config.BattlePassConfig),
}

return Config
