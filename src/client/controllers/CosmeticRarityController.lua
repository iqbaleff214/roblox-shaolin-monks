--!strict
-- T-082 (GDD §5.3). Watches every player's `Equipped_<Slot>` attributes
-- (set by AccessoryService, T-080 — Player attributes, so this works for
-- every character in the server, not just the local one) and applies the
-- rarity-tier VFX preset (T-082's RarityVisualPreset) at render time.
--
-- No per-accessory attachment points exist yet (real meshes are Studio work,
-- S-050–S-057) — so rather than 4 overlapping whole-character outlines (one
-- per slot) fighting each other visually, this applies a single Highlight
-- reflecting the HIGHEST rarity tier among the 4 equipped slots. Once real
-- accessory meshes exist, a follow-up pass can attach a ParticleEmitter to
-- each specific worn mesh instead — this file is the only thing that would
-- need to change.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)
local RarityVisualPreset = require(ReplicatedStorage.Shared.modules.RarityVisualPreset)

local AccessoryConfig = ConfigService.Accessory
local SLOTS = { "Head", "Body", "Arm", "Leg" }
local HIGHLIGHT_NAME = "CosmeticRarityFX"

local CosmeticRarityController = Knit.CreateController({
	Name = "CosmeticRarityController",
})

local function highestRarityPreset(player: Player): RarityVisualPreset.Preset?
	local highestDensity = -1
	local highestPreset: RarityVisualPreset.Preset? = nil

	for _, slot in SLOTS do
		local itemId = player:GetAttribute("Equipped_" .. slot)
		if type(itemId) == "string" then
			local item = AccessoryConfig[itemId]
			if item then
				local preset = RarityVisualPreset.resolve(item.Rarity)
				if preset.ParticleDensity > highestDensity then
					highestDensity = preset.ParticleDensity
					highestPreset = preset
				end
			end
		end
	end

	return highestPreset
end

local function applyPreset(character: Model, preset: RarityVisualPreset.Preset?)
	local existing = character:FindFirstChild(HIGHLIGHT_NAME) :: Highlight?

	if preset and preset.GlowIntensity > 0 then
		local highlight = existing
		if not highlight then
			highlight = Instance.new("Highlight")
			highlight.Name = HIGHLIGHT_NAME
			highlight.Parent = character
		end
		highlight.OutlineColor = preset.Color
		highlight.FillColor = preset.Color
		highlight.FillTransparency = 1 - preset.GlowIntensity * 0.5
		highlight.OutlineTransparency = 1 - preset.GlowIntensity
	elseif existing then
		existing:Destroy()
	end
end

local function refreshPlayer(player: Player)
	local character = player.Character
	if character then
		applyPreset(character, highestRarityPreset(player))
	end
end

local function watchPlayer(player: Player)
	for _, slot in SLOTS do
		player:GetAttributeChangedSignal("Equipped_" .. slot):Connect(function()
			refreshPlayer(player)
		end)
	end
	player.CharacterAdded:Connect(function()
		refreshPlayer(player)
	end)
	if player.Character then
		refreshPlayer(player)
	end
end

function CosmeticRarityController:KnitStart()
	for _, player in Players:GetPlayers() do
		watchPlayer(player)
	end
	Players.PlayerAdded:Connect(watchPlayer)
end

function CosmeticRarityController:KnitInit() end

return CosmeticRarityController
