--!strict
-- T-101 (GDD §3.8, §3.9, §10.2, §17.5). Rolls drops on the three real sources
-- available today: container break (DestructibleContainerService, T-100),
-- enemy kill (CombatService.EnemyDefeated), and Finishing Move (§3.9's
-- "guarantees a relic drop" — CombatService.FinishingMoveLanded).
--
-- Every roll gets a fresh seed derived from this server instance's own
-- session seed plus a monotonic counter (§17.5 "per-instance seed"), and is
-- appended to a bounded in-memory log — the ready hookup point for T-170's
-- anti-cheat audit (Phase 15, not built yet).
--
-- HealthOrb/ChiOrb bonus drops are applied immediately (no dependency on the
-- not-yet-built Currency system, T-110): HealthOrb heals the player's
-- Humanoid directly, ChiOrb calls CombatService:GrantChi. Every other reward
-- type (Coins, ThrowableWeapon, Relic, Cosmetic) only fires `RewardRolled` —
-- Currency (T-110), WeaponPickupService's world-item spawn, and the cosmetic
-- crate system (T-117) are the real, not-yet-built consumers, matching this
-- codebase's established forward-dependency pattern.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)
local DropTableRoller = require(ReplicatedStorage.Shared.modules.DropTableRoller)

local LootConfig = ConfigService.Loot
local MAX_LOG_ENTRIES = 500

local LootService = Knit.CreateService({
	Name = "LootService",
})

-- (player: Player, rewardType: string, amount: number?, source: string)
LootService.RewardRolled = Signal.new()

local sessionSeed = Random.new():NextInteger(1, 2 ^ 31 - 1)
local rollCounter = 0

type RollLogEntry = { seed: number, kind: string, key: string, at: number }
local rollLog: { RollLogEntry } = {}

local function nextSeed(): number
	rollCounter += 1
	return sessionSeed + rollCounter
end

local function logRoll(seed: number, kind: string, key: string)
	table.insert(rollLog, { seed = seed, kind = kind, key = key, at = os.clock() })
	if #rollLog > MAX_LOG_ENTRIES then
		table.remove(rollLog, 1)
	end
end

local function applyHealthOrb(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + LootConfig.OrbRestoreAmounts.HealthOrb)
	end
end

local function applyChiOrb(player: Player)
	Knit.GetService("CombatService"):GrantChi(player, LootConfig.OrbRestoreAmounts.ChiOrb)
end

local function grantBonusItem(player: Player, itemType: string, source: string)
	if itemType == "HealthOrb" then
		applyHealthOrb(player)
	elseif itemType == "ChiOrb" then
		applyChiOrb(player)
	end
	LootService.RewardRolled:Fire(player, itemType, nil, source)
end

local function onContainerBroken(_instance: Instance, containerType: string, player: Player?)
	local seed = nextSeed()
	local roll = DropTableRoller.rollContainerDrop(seed, containerType)
	logRoll(seed, "Container", containerType)

	if not player then
		return
	end

	local source = "Container:" .. containerType
	if roll.coins > 0 then
		LootService.RewardRolled:Fire(player, "Coins", roll.coins, source)
	end
	if roll.bonusItem then
		grantBonusItem(player, roll.bonusItem, source)
	end
	if roll.guaranteedItem then
		LootService.RewardRolled:Fire(player, roll.guaranteedItem, nil, source)
	end
end

local function onEnemyDefeated(target: Model, player: Player?)
	if not player then
		return
	end
	local role = target:GetAttribute("Role")
	if type(role) ~= "string" then
		return
	end

	local seed = nextSeed()
	local roll = DropTableRoller.rollEnemyKillDrop(seed, role)
	logRoll(seed, "EnemyKill", role)

	if roll.coins > 0 then
		LootService.RewardRolled:Fire(player, "Coins", roll.coins, "EnemyKill:" .. role)
	end
end

local function onFinishingMoveLanded(_target: Model, player: Player?)
	if player then
		-- §3.9: a Finishing Move always guarantees a relic drop, no roll needed.
		LootService.RewardRolled:Fire(player, "Relic", nil, "FinishingMove")
	end
end

-- Server-internal: read-only audit trail for T-170 (Phase 15, not built yet).
function LootService:GetRecentRolls(): { RollLogEntry }
	return rollLog
end

function LootService:KnitStart()
	local DestructibleContainerService = Knit.GetService("DestructibleContainerService")
	DestructibleContainerService.ContainerBroken:Connect(onContainerBroken)

	local CombatService = Knit.GetService("CombatService")
	CombatService.EnemyDefeated:Connect(onEnemyDefeated)
	CombatService.FinishingMoveLanded:Connect(onFinishingMoveLanded)
end

return LootService
