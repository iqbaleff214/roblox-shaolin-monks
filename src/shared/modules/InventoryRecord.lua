-- T-081 (GDD §5.1, §5.3, §11.2). Pure idempotent grant/ownership tracking
-- for one player's cosmetic inventory (Accessories, WeaponSkins,
-- UltimateFxSkins, Emotes, SpiritCompanions — category is caller-supplied,
-- not enumerated here, so new categories never need a code change).
-- InventoryService (server) owns one instance per player.

local InventoryRecord = {}
InventoryRecord.__index = InventoryRecord

export type ItemEntry = {
	acquiredAt: number,
	duplicatesReceived: number,
}

export type InventoryRecord = typeof(setmetatable(
	{} :: {
		itemsByCategory: { [string]: { [string]: ItemEntry } },
	},
	InventoryRecord
))

function InventoryRecord.new(): InventoryRecord
	return setmetatable({ itemsByCategory = {} }, InventoryRecord)
end

function InventoryRecord.isOwned(self: InventoryRecord, category: string, itemId: string): boolean
	local items = self.itemsByCategory[category]
	return items ~= nil and items[itemId] ~= nil
end

-- Idempotent: granting an already-owned item never creates a second entry —
-- it only increments that entry's `duplicatesReceived` (§10.4/§11.6's
-- duplicate-protection conversion path, T-103, reads this later).
-- Returns (granted, wasDuplicate): `granted` is true exactly on the item's
-- first-ever grant for this player.
function InventoryRecord.grant(self: InventoryRecord, category: string, itemId: string, now: number): (boolean, boolean)
	local items = self.itemsByCategory[category]
	if not items then
		items = {}
		self.itemsByCategory[category] = items
	end

	local existing = items[itemId]
	if existing then
		existing.duplicatesReceived += 1
		return false, true
	end

	items[itemId] = { acquiredAt = now, duplicatesReceived = 0 }
	return true, false
end

function InventoryRecord.getEntry(self: InventoryRecord, category: string, itemId: string): ItemEntry?
	local items = self.itemsByCategory[category]
	return items and items[itemId]
end

return InventoryRecord
