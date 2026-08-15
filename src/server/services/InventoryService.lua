--!strict
-- T-081 (GDD §5.1, §5.3, §11.2). Per-player cosmetic ownership, backed by
-- InventoryRecord's idempotent grant logic. `Grant` is server-internal only
-- — nothing reaches this from the client directly; only server-initiated
-- systems (shop purchase, crate open, quest reward, chapter completion —
-- Phase 8/9's T-101/T-103/T-112/T-117, none built yet) call it.
--
-- Persistence seam: `PlayerDataService` (T-160, Phase 14) doesn't exist yet.
-- This service holds inventory in memory per session, the same interim
-- state every other player-data system in this codebase currently uses
-- (WeaponService's loadout, CombatService's PlayerState, etc.) — T-160
-- adding real DataStore persistence later means this service loads from and
-- saves to it, not a redesign.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local InventoryRecord = require(ReplicatedStorage.Shared.modules.InventoryRecord)

local InventoryService = Knit.CreateService({
	Name = "InventoryService",
	Client = {},
})

-- (player: Player, category: string, itemId: string) — T-103 (Phase 8,
-- not built yet) subscribes to convert duplicate pulls to Coins (§10.4/§11.6).
InventoryService.DuplicateGranted = Signal.new()
-- (player: Player, category: string, itemId: string) — fired only on a
-- genuine first-time grant.
InventoryService.ItemGranted = Signal.new()

local inventoryByPlayer: { [Player]: InventoryRecord.InventoryRecord } = {}

local function getInventory(player: Player): InventoryRecord.InventoryRecord
	local inventory = inventoryByPlayer[player]
	if not inventory then
		inventory = InventoryRecord.new()
		inventoryByPlayer[player] = inventory
	end
	return inventory
end

-- Server-internal: grants `itemId` in `category` to `player`. Idempotent —
-- a repeat grant never duplicates the entry, only fires DuplicateGranted.
function InventoryService:Grant(player: Player, category: string, itemId: string)
	local inventory = getInventory(player)
	local granted, wasDuplicate = inventory:grant(category, itemId, os.clock())

	if granted then
		InventoryService.ItemGranted:Fire(player, category, itemId)
	elseif wasDuplicate then
		InventoryService.DuplicateGranted:Fire(player, category, itemId)
	end
end

function InventoryService:IsOwned(player: Player, category: string, itemId: string): boolean
	return getInventory(player):isOwned(category, itemId)
end

function InventoryService.Client:IsOwned(player: Player, category: string, itemId: string): boolean
	return InventoryService:IsOwned(player, category, itemId)
end

function InventoryService.Client:GetOwnedItemIds(player: Player, category: string): { string }
	local inventory = getInventory(player)
	local items = inventory.itemsByCategory[category]
	local ids: { string } = {}
	if items then
		for itemId in items do
			table.insert(ids, itemId)
		end
	end
	return ids
end

function InventoryService:KnitInit()
	Players.PlayerRemoving:Connect(function(player)
		inventoryByPlayer[player] = nil
	end)
end

return InventoryService
