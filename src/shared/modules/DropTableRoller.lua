-- T-101 (GDD §3.8, §10.2, §17.5). Server-seeded, reproducible drop rolls for
-- container breaks and enemy kills. Every roll takes an explicit `seed` and
-- constructs a fresh `Random.new(seed)` internally, so calling the same
-- function with the same seed always produces the exact same result — the
-- reproducibility §17.5 requires for anti-cheat auditing and the Daily Relic
-- Hunt's shared-seed remix (§7.4).
--
-- Requires LootConfig directly (config data, not a Roblox service), matching
-- every other pure module's precedent for needing one specific config table.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LootConfig = require(ReplicatedStorage.Shared.config.LootConfig)
local QuestResetSchedule = require(ReplicatedStorage.Shared.modules.QuestResetSchedule)

local DropTableRoller = {}

export type ContainerRoll = { coins: number, bonusItem: string?, guaranteedItem: string? }
export type EnemyKillRoll = { coins: number }

function DropTableRoller.rollContainerDrop(seed: number, containerType: string): ContainerRoll
	local drop = LootConfig.ContainerDrops[containerType]
	if not drop then
		return { coins = 0, bonusItem = nil, guaranteedItem = nil }
	end

	local rng = Random.new(seed)
	local coins = rng:NextInteger(drop.CoinsMin, drop.CoinsMax)

	local bonusItem: string? = nil
	if drop.BonusDrop and rng:NextNumber() < drop.BonusDrop.Chance then
		bonusItem = drop.BonusDrop.Type
	end

	return { coins = coins, bonusItem = bonusItem, guaranteedItem = drop.GuaranteedDrop }
end

function DropTableRoller.rollEnemyKillDrop(seed: number, role: string): EnemyKillRoll
	local range = LootConfig.EnemyKillCoins[role]
	if not range then
		return { coins = 0 }
	end

	local rng = Random.new(seed)
	return { coins = rng:NextInteger(range.Min, range.Max) }
end

-- §7.4: a seed shared by every player on the same UTC calendar day, reusing
-- QuestResetSchedule's (T-093) daily boundary math — the Daily Relic Hunt
-- mode (not a scripted task yet) will use this so everyone gets the same
-- remix that day.
function DropTableRoller.dailySeed(unixTime: number): number
	return QuestResetSchedule.dailyPeriodId(unixTime, 0)
end

return DropTableRoller
