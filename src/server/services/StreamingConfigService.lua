--!strict
-- T-182 (GDD §17.4). Enables Workspace streaming and applies the tuned
-- radii from `PerformanceConfig.Streaming` so chapters load progressively
-- instead of fully upfront.
--
-- Audit note for this task's DoD ("no gameplay-critical script assumes a
-- part exists before streamed-in confirmation"): every server system that
-- touches level geometry (ArenaGateController, DestructibleContainerService,
-- ChestService, GrappleService, NPCVendorService, TraversalInteractableService,
-- UltimateService, WeaponPickupService, CombatService's enemy registry) is
-- already built on `CollectionService:GetTagged(tag)` +
-- `GetInstanceAddedSignal`/`GetInstanceRemovedSignal`, which tolerates an
-- instance arriving late exactly the same way it tolerates one being placed
-- in Studio after the service starts — there is no eager `WaitForChild` on
-- streamed Workspace geometry anywhere in this codebase (the only
-- `WaitForChild` calls target a Player's own Character/Humanoid, which is
-- never subject to streaming). No new guard code was needed to satisfy this
-- DoD; this service only needed to turn streaming on.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)

local StreamingConfig = ConfigService.Performance.Streaming

local StreamingConfigService = Knit.CreateService({
	Name = "StreamingConfigService",
	Client = {},
})

function StreamingConfigService:KnitInit()
	Workspace.StreamingEnabled = true
	Workspace.StreamingMinRadius = StreamingConfig.MinRadius
	Workspace.StreamingTargetRadius = StreamingConfig.TargetRadius
end

return StreamingConfigService
