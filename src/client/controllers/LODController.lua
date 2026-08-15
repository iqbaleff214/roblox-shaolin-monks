--!strict
-- T-180 (GDD §17.4). Generic tag-driven LOD swap for battlefield decoration
-- props — see STUDIO_TASKS.md §0 (S-002) for the tag/attribute contract.
-- Studio (S-020–S-027) tags a decoration prop `LODProp` and groups its
-- detail levels under two children named `Near` (full detail) and `Far`
-- (simplified/low-poly), with an optional `LODDistance` attribute (studs);
-- one generic client controller then swaps between them by camera distance
-- — no per-prop script is ever written.
--
-- Deliberately polls on a throttled interval (`PerformanceConfig.LOD.
-- CheckIntervalSeconds`), not every Heartbeat, and checks every tracked prop
-- in one batched pass — a per-prop Heartbeat connection (or a check every
-- frame) would make the LOD system itself a frame-time cost, defeating its
-- own purpose (§17.4's DoD: "frame time impact of LOD swapping itself is
-- negligible").

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)

local LODConfig = ConfigService.Performance.LOD
local LOD_PROP_TAG = "LODProp"

local LODController = Knit.CreateController({
	Name = "LODController",
})

type PropEntry = {
	position: Vector3,
	swapDistance: number,
	near: Instance,
	far: Instance,
	nearParent: Instance,
	farParent: Instance?,
	isNear: boolean,
}

local registry: { [Instance]: PropEntry } = {}

local function resolvePosition(instance: Instance): Vector3?
	if instance:IsA("Model") then
		return instance:GetPivot().Position
	elseif instance:IsA("BasePart") then
		return instance.Position
	end
	return nil
end

local function register(instance: Instance)
	local near = instance:FindFirstChild("Near")
	local far = instance:FindFirstChild("Far")
	if not near or not far then
		return -- malformed authoring; nothing to swap between
	end

	local position = resolvePosition(instance)
	if not position then
		return
	end

	local distanceAttribute = instance:GetAttribute("LODDistance")
	local swapDistance = if type(distanceAttribute) == "number" then distanceAttribute else LODConfig.DefaultSwapDistance

	-- Starts in the "Near" state; the next poll corrects it if the camera is
	-- actually already far away.
	registry[instance] = {
		position = position,
		swapDistance = swapDistance,
		near = near,
		far = far,
		nearParent = near.Parent :: Instance,
		farParent = nil,
		isNear = true,
	}
	far.Parent = nil
end

local function unregister(instance: Instance)
	registry[instance] = nil
end

local function applyState(entry: PropEntry, shouldBeNear: boolean)
	if shouldBeNear == entry.isNear then
		return
	end
	entry.isNear = shouldBeNear
	if shouldBeNear then
		entry.near.Parent = entry.nearParent
		entry.far.Parent = nil
	else
		entry.far.Parent = entry.nearParent
		entry.near.Parent = nil
	end
end

local function pollAll()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local cameraPosition = camera.CFrame.Position

	for _, entry in registry do
		local distance = (entry.position - cameraPosition).Magnitude
		applyState(entry, distance <= entry.swapDistance)
	end
end

function LODController:KnitStart()
	for _, instance in CollectionService:GetTagged(LOD_PROP_TAG) do
		register(instance)
	end
	CollectionService:GetInstanceAddedSignal(LOD_PROP_TAG):Connect(register)
	CollectionService:GetInstanceRemovedSignal(LOD_PROP_TAG):Connect(unregister)

	task.spawn(function()
		while true do
			task.wait(LODConfig.CheckIntervalSeconds)
			pollAll()
		end
	end)
end

function LODController:KnitInit() end

return LODController
