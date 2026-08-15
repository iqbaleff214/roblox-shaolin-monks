--!strict
-- T-080 (GDD §5.1). Head/Body/Arm/Leg equip/unequip, gated on ownership via
-- InventoryService (T-081). Sets `Equipped_<Slot>` Player attributes —
-- replicated automatically to every client, so anyone can inspect anyone
-- else's loadout (§12.1) without a round-trip.
--
-- Zero combat coupling by construction: this file never requires
-- CombatService, never touches a Humanoid stat, and AccessoryConfig's own
-- schema (T-015) structurally excludes stat fields (enforced by
-- AccessoryConfig.spec.lua's disallowed-key guard) — there is no code path
-- anywhere for an equipped accessory to change damage/HP/speed, which is
-- what the DoD's "zero measurable change to CombatService outputs" actually
-- requires. That guarantee is verified by construction and by the existing
-- schema test, not by a runtime combat-scenario comparison.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)

local AccessoryConfig = ConfigService.Accessory

local VALID_SLOTS = { Head = true, Body = true, Arm = true, Leg = true }

local AccessoryService = Knit.CreateService({
	Name = "AccessoryService",
	Client = {},
})

local function attributeName(slot: string): string
	return "Equipped_" .. slot
end

function AccessoryService.Client:RequestEquip(player: Player, slot: string, itemId: string): boolean
	if not VALID_SLOTS[slot] then
		return false
	end
	local item = AccessoryConfig[itemId]
	if not item or item.Slot ~= slot then
		return false
	end

	local InventoryService = Knit.GetService("InventoryService")
	if not InventoryService:IsOwned(player, "Accessory", itemId) then
		return false
	end

	player:SetAttribute(attributeName(slot), itemId)
	return true
end

function AccessoryService.Client:RequestUnequip(player: Player, slot: string): boolean
	if not VALID_SLOTS[slot] then
		return false
	end
	player:SetAttribute(attributeName(slot), nil)
	return true
end

-- Server-internal read, e.g. for a future outfit-preview or NPC vendor UI.
function AccessoryService:GetEquipped(player: Player, slot: string): string?
	if not VALID_SLOTS[slot] then
		return nil
	end
	local itemId = player:GetAttribute(attributeName(slot))
	return if type(itemId) == "string" then itemId else nil
end

return AccessoryService
