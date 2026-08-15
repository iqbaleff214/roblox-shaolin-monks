--!strict
-- T-126 (GDD §12.1). Generic tag-driven trigger for `NPCVendor` instances
-- (Sifu's Dojo, Cosmetic Shop stall, Battle Pass board — STUDIO_TASKS.md
-- S-002), firing `VendorInteracted` with the instance's `VendorType`
-- attribute. Interaction style auto-detects a descendant ProximityPrompt or
-- ClickDetector, the same fallback discipline TraversalInteractableService
-- (T-032) established. Adding a new vendor in Studio is tag + attribute
-- only — this file never needs to change or know a vendor's specific
-- identity.
--
-- The actual shop UI (Phase 11, not built yet) is the real consumer of this
-- signal; this service only owns detecting the interaction.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local VENDOR_TAG = "NPCVendor"

local NPCVendorService = Knit.CreateService({
	Name = "NPCVendorService",
	Client = {
		VendorInteracted = Knit.CreateSignal(), -- (vendorType: string)
	},
})

local function bindVendor(instance: Instance)
	local vendorType = instance:GetAttribute("VendorType")
	if type(vendorType) ~= "string" then
		warn(`[NPCVendorService] "{instance:GetFullName()}" is missing a VendorType attribute`)
		return
	end

	local prompt = instance:FindFirstChildWhichIsA("ProximityPrompt", true)
	local clickDetector = instance:FindFirstChildWhichIsA("ClickDetector", true)

	if prompt then
		prompt.Triggered:Connect(function(player: Player)
			NPCVendorService.Client.VendorInteracted:Fire(player, vendorType)
		end)
	elseif clickDetector then
		clickDetector.MouseClick:Connect(function(player: Player)
			NPCVendorService.Client.VendorInteracted:Fire(player, vendorType)
		end)
	end
end

function NPCVendorService:KnitInit()
	for _, instance in CollectionService:GetTagged(VENDOR_TAG) do
		bindVendor(instance)
	end
	CollectionService:GetInstanceAddedSignal(VENDOR_TAG):Connect(bindVendor)
end

return NPCVendorService
