--!strict
-- T-032 (GDD §3.1). One generic, tag-driven framework for every traversal
-- interactable (Lever, PressurePlate, CollapsingWalkway) — see
-- STUDIO_TASKS.md §0 (S-002) for the tag/attribute contract. Studio drops a
-- tagged instance with the documented attributes; no per-chapter script is
-- ever written for these.
--
-- Attribute contract (all optional; sane defaults below):
--   ResetDelay (number)  — seconds before the interactable can fire again.
--   TargetId   (string)  — opaque id forwarded on `Fired` for downstream
--                           systems (e.g. a future Arena Gate) to match
--                           against what this instance controls.
--   CollapseDelay (number, CollapsingWalkway only) — seconds between trigger
--                           and the walkway actually giving way.
--
-- Lever interaction style is auto-detected: a descendant ProximityPrompt or
-- ClickDetector is used if present, otherwise it falls back to Touched (walk
-- into it), so Studio can author whichever fits the scene without needing a
-- different tag or a code change.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Maid = require(ReplicatedStorage.Packages.Maid)
local Signal = require(ReplicatedStorage.Packages.Signal)
local DebounceGate = require(ReplicatedStorage.Shared.modules.DebounceGate)

local LEVER_TAG = "Lever"
local PRESSURE_PLATE_TAG = "PressurePlate"
local COLLAPSING_WALKWAY_TAG = "CollapsingWalkway"

local DEFAULT_RESET_DELAY = 1 -- seconds; Lever/PressurePlate
local DEFAULT_COLLAPSE_DELAY = 0.4 -- seconds; CollapsingWalkway trigger -> gives way
local DEFAULT_WALKWAY_RESET_DELAY = 5 -- seconds; CollapsingWalkway gives way -> respawns

local TraversalInteractableService = Knit.CreateService({
	Name = "TraversalInteractableService",
})

-- Fires (instance: Instance, tag: string, targetId: string?) whenever any
-- tagged interactable successfully activates. Server-internal for now —
-- future systems (e.g. Arena Gate, T-061) require this service and connect.
TraversalInteractableService.Fired = Signal.new()

local registry: { [Instance]: { gate: DebounceGate.DebounceGate, maid: any } } = {}

local function getNumberAttribute(instance: Instance, attributeName: string, default: number): number
	local value = instance:GetAttribute(attributeName)
	if type(value) == "number" then
		return value
	end
	return default
end

local function hasToucherHumanoid(toucher: BasePart): boolean
	local ancestor = toucher.Parent
	return ancestor ~= nil and ancestor:FindFirstChildOfClass("Humanoid") ~= nil
end

local function register(instance: Instance, resetDelay: number): { gate: DebounceGate.DebounceGate, maid: any }
	local entry = {
		gate = DebounceGate.new(resetDelay),
		maid = Maid.new(),
	}
	registry[instance] = entry
	return entry
end

local function unregister(instance: Instance)
	local entry = registry[instance]
	if not entry then
		return
	end
	entry.maid:Destroy()
	registry[instance] = nil
end

-- Returns true if this call actually fired (gate was open), false if the
-- reset delay was still active.
local function fire(instance: Instance, tag: string): boolean
	local entry = registry[instance]
	if not entry then
		return false
	end
	if not entry.gate:tryFire(os.clock()) then
		return false
	end
	local targetIdAttribute = instance:GetAttribute("TargetId")
	local targetId: string? = if type(targetIdAttribute) == "string" then targetIdAttribute else nil
	TraversalInteractableService.Fired:Fire(instance, tag, targetId)
	return true
end

--// Lever \\--

local function bindLever(instance: Instance)
	local entry = register(instance, getNumberAttribute(instance, "ResetDelay", DEFAULT_RESET_DELAY))

	local proximityPrompt = instance:FindFirstChildWhichIsA("ProximityPrompt", true)
	local clickDetector = instance:FindFirstChildWhichIsA("ClickDetector", true)

	if proximityPrompt then
		entry.maid:GiveTask(proximityPrompt.Triggered:Connect(function()
			fire(instance, LEVER_TAG)
		end))
	elseif clickDetector then
		entry.maid:GiveTask(clickDetector.MouseClick:Connect(function()
			fire(instance, LEVER_TAG)
		end))
	elseif instance:IsA("BasePart") then
		entry.maid:GiveTask(instance.Touched:Connect(function(toucher)
			if hasToucherHumanoid(toucher) then
				fire(instance, LEVER_TAG)
			end
		end))
	end
end

--// PressurePlate \\--

local function bindPressurePlate(instance: Instance)
	if not instance:IsA("BasePart") then
		return
	end
	local entry = register(instance, getNumberAttribute(instance, "ResetDelay", DEFAULT_RESET_DELAY))
	entry.maid:GiveTask(instance.Touched:Connect(function(toucher)
		if hasToucherHumanoid(toucher) then
			fire(instance, PRESSURE_PLATE_TAG)
		end
	end))
end

--// CollapsingWalkway \\--

local function collapseAndReset(instance: BasePart, collapseDelay: number, resetDelay: number)
	local originalTransparency = instance.Transparency
	local originalCanCollide = instance.CanCollide

	task.delay(collapseDelay, function()
		if not instance.Parent then
			return -- destroyed before it could collapse
		end
		instance.CanCollide = false
		instance.Transparency = 1

		task.delay(resetDelay, function()
			if not instance.Parent then
				return
			end
			instance.CanCollide = originalCanCollide
			instance.Transparency = originalTransparency
		end)
	end)
end

local function bindCollapsingWalkway(instance: Instance)
	if not instance:IsA("BasePart") then
		return
	end
	local resetDelay = getNumberAttribute(instance, "ResetDelay", DEFAULT_WALKWAY_RESET_DELAY)
	local collapseDelay = getNumberAttribute(instance, "CollapseDelay", DEFAULT_COLLAPSE_DELAY)
	-- Full cycle (collapse + reset) counts as this interactable's "reset
	-- delay" for the purposes of the debounce gate, so it can't be
	-- re-triggered mid-collapse.
	local entry = register(instance, collapseDelay + resetDelay)

	entry.maid:GiveTask(instance.Touched:Connect(function(toucher)
		if not hasToucherHumanoid(toucher) then
			return
		end
		if not entry.gate:tryFire(os.clock()) then
			return
		end
		local targetId = instance:GetAttribute("TargetId")
		TraversalInteractableService.Fired:Fire(instance, COLLAPSING_WALKWAY_TAG, if type(targetId) == "string" then targetId else nil)
		collapseAndReset(instance, collapseDelay, resetDelay)
	end))
end

--// Lifecycle \\--

local BINDERS: { [string]: (Instance) -> () } = {
	[LEVER_TAG] = bindLever,
	[PRESSURE_PLATE_TAG] = bindPressurePlate,
	[COLLAPSING_WALKWAY_TAG] = bindCollapsingWalkway,
}

function TraversalInteractableService:KnitInit()
	for tag, binder in BINDERS do
		for _, instance in CollectionService:GetTagged(tag) do
			binder(instance)
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(binder)
		CollectionService:GetInstanceRemovedSignal(tag):Connect(unregister)
	end
end

return TraversalInteractableService
