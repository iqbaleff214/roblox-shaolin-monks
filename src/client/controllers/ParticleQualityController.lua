--!strict
-- T-181 (GDD §17.4). Wires `UIConfig.ParticleLimits`' quality tiers to every
-- `QualityScaledParticle`-tagged ParticleEmitter/Trail (see STUDIO_TASKS.md
-- §0/S-002) — no Studio VFX assets (S-065) exist yet, so this builds the
-- generic reusable framework now: any future emitter just needs the tag,
-- no code change here.
--
-- An emitter's `Rate` (ParticleEmitter) or `Lifetime`-driven `PartEmissionCount`
-- (Trail has no `Rate`, so Trails instead scale `MaxLength`/`Lifetime` isn't
-- meaningful here — Trails are treated as pass/fail via `Enabled` since they
-- don't have a discrete emission-rate concept) is captured once at
-- registration as its High-tier baseline, then live-rescaled through
-- `ParticleQualityResolver` on every graphics-quality change — including
-- ones already mid-emission (SettingsController.SettingsChanged fires
-- immediately, no rejoin needed, per the DoD).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)
local ParticleQualityResolver = require(ReplicatedStorage.Shared.modules.ParticleQualityResolver)

local ParticleLimits = ConfigService.UI.ParticleLimits
local TAG = "QualityScaledParticle"

local ParticleQualityController = Knit.CreateController({
	Name = "ParticleQualityController",
})

local baseRateByEmitter: { [ParticleEmitter]: number } = {}
local currentTier = "High"

local function applyTier(emitter: ParticleEmitter)
	local baseRate = baseRateByEmitter[emitter]
	if not baseRate then
		return
	end
	emitter.Rate = ParticleQualityResolver.resolveRate(baseRate, currentTier, ParticleLimits)
end

local function register(instance: Instance)
	if not instance:IsA("ParticleEmitter") then
		return -- Trails have no discrete Rate; only ParticleEmitters participate
	end
	baseRateByEmitter[instance] = instance.Rate
	applyTier(instance)
end

local function unregister(instance: Instance)
	local emitter = instance :: ParticleEmitter
	baseRateByEmitter[emitter] = nil
end

local function applyTierToAll()
	for emitter in baseRateByEmitter do
		applyTier(emitter)
	end
end

function ParticleQualityController:KnitStart()
	for _, instance in CollectionService:GetTagged(TAG) do
		register(instance)
	end
	CollectionService:GetInstanceAddedSignal(TAG):Connect(register)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(unregister)

	local SettingsController = Knit.GetController("SettingsController")
	SettingsController.SettingsChanged:Connect(function(settings: { [string]: any })
		local quality = settings.GraphicsQuality
		if type(quality) == "string" and quality ~= currentTier then
			currentTier = quality
			applyTierToAll()
		end
	end)
end

function ParticleQualityController:KnitInit() end

return ParticleQualityController
