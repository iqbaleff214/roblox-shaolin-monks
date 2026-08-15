--!strict
-- T-100 (GDD §3.8, §10.2). Tag-driven (`DestructibleContainer`, see
-- STUDIO_TASKS.md S-002) component: one generic module handles all 4
-- container types purely via the `ContainerType` attribute + LootConfig's
-- Hits value — no per-type script forking.
--
-- Hit detection reuses the same weapon-arc geometry CombatService's own
-- attack resolution uses (via the shared WeaponArcCheck module) rather than
-- a separate proximity-prompt "smash" interaction, so containers break on
-- the exact same swings that hit enemies. CombatService calls `CheckHits`
-- once per resolved attack (a single, minimal addition to its already-shipped
-- RequestAttack) right alongside its own enemy hit-detection loop.
--
-- Containers never respawn mid-run (§3.8) — breaking one simply destroys the
-- instance; a fresh respawn only happens because the whole place reloads.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)
local WeaponArcCheck = require(ReplicatedStorage.Shared.modules.WeaponArcCheck)

local LootConfig = ConfigService.Loot
local CONTAINER_TAG = "DestructibleContainer"

local DestructibleContainerService = Knit.CreateService({
	Name = "DestructibleContainerService",
})

-- (container: Instance, containerType: string, player: Player?)
DestructibleContainerService.ContainerBroken = Signal.new()

type ContainerState = {
	containerType: string,
	hitsRemaining: number,
}

local states: { [Instance]: ContainerState } = {}

local function getPosition(instance: Instance): Vector3?
	if instance:IsA("BasePart") then
		return instance.Position
	elseif instance:IsA("Model") then
		return instance:GetPivot().Position
	end
	return nil
end

local function register(instance: Instance)
	local containerType = instance:GetAttribute("ContainerType")
	if type(containerType) ~= "string" then
		warn(`[DestructibleContainerService] "{instance:GetFullName()}" is missing a ContainerType attribute`)
		return
	end
	local containerConfig = LootConfig.Containers[containerType]
	if not containerConfig then
		warn(`[DestructibleContainerService] "{instance:GetFullName()}" has an unknown ContainerType "{containerType}"`)
		return
	end

	states[instance] = { containerType = containerType, hitsRemaining = containerConfig.Hits }
end

local function unregister(instance: Instance)
	states[instance] = nil
end

local function breakContainer(instance: Instance, state: ContainerState, player: Player?)
	states[instance] = nil
	DestructibleContainerService.ContainerBroken:Fire(instance, state.containerType, player)
	instance:Destroy()
end

-- Server-internal: called once per resolved attack (CombatService's
-- RequestAttack) with the same attacker position/facing/weapon shape it
-- already uses for enemy hit detection.
function DestructibleContainerService:CheckHits(attackerPosition: Vector3, attackerLookVector: Vector3, weapon: { Range: number, Arc: number }, player: Player?)
	for instance, state in states do
		local position = getPosition(instance)
		if position and WeaponArcCheck.isWithinArc(attackerPosition, attackerLookVector, position, weapon.Range, weapon.Arc) then
			state.hitsRemaining -= 1
			if state.hitsRemaining <= 0 then
				breakContainer(instance, state, player)
			end
		end
	end
end

function DestructibleContainerService:KnitInit()
	for _, instance in CollectionService:GetTagged(CONTAINER_TAG) do
		register(instance)
	end
	CollectionService:GetInstanceAddedSignal(CONTAINER_TAG):Connect(register)
	CollectionService:GetInstanceRemovedSignal(CONTAINER_TAG):Connect(unregister)
end

return DestructibleContainerService
