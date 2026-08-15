--!strict
-- T-134 (GDD §15.3). Settings menu logic: applies changes to live systems
-- immediately (no rejoin/reload) and persists them via SettingsService
-- (T-134). Language selection is stored/broadcast but has no live text to
-- re-render yet — LocalizationService (T-150, Phase 13) doesn't exist. Every
-- other setting has a real, live system it applies to today:
--   * Music/SFX volume -> SoundService SoundGroups (this controller creates
--     them, since no Studio audio setup, S-070-072/T-140, exists yet
--     either) — any Sound parented under them gets the volume live,
--     including already-playing ones, since SoundGroup.Volume applies to
--     its whole subtree continuously.
--   * Control scheme -> a manual override read by anything consulting
--     `GetEffectiveControlScheme` instead of InputSchemeController's
--     (T-130) auto-detection directly.
--   * Graphics quality -> exposed for T-181's (Phase 16, not built)
--     particle-limit wiring to read.
--   * Lock-on assist -> read directly by CombatController's lock-on logic.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local SettingsController = Knit.CreateController({
	Name = "SettingsController",
})

SettingsController.SettingsChanged = Signal.new() -- (settings: {[string]: any})

local currentSettings: { [string]: any } = {
	MusicVolume = 0.8,
	SfxVolume = 0.8,
	ControlScheme = "Auto",
	GraphicsQuality = "High",
	LockOnAssist = true,
	Language = "en",
}

local musicGroup: SoundGroup
local sfxGroup: SoundGroup

local function ensureSoundGroups()
	if not musicGroup then
		musicGroup = Instance.new("SoundGroup")
		musicGroup.Name = "MusicGroup"
		musicGroup.Parent = SoundService
	end
	if not sfxGroup then
		sfxGroup = Instance.new("SoundGroup")
		sfxGroup.Name = "SfxGroup"
		sfxGroup.Parent = SoundService
	end
end

local function applyVolumes()
	ensureSoundGroups()
	musicGroup.Volume = currentSettings.MusicVolume
	sfxGroup.Volume = currentSettings.SfxVolume
end

function SettingsController:GetSettings(): { [string]: any }
	return currentSettings
end

function SettingsController:GetMusicSoundGroup(): SoundGroup
	ensureSoundGroups()
	return musicGroup
end

function SettingsController:GetSfxSoundGroup(): SoundGroup
	ensureSoundGroups()
	return sfxGroup
end

function SettingsController:GetEffectiveControlScheme(): string
	return currentSettings.ControlScheme
end

function SettingsController:SetSetting(key: string, value: any)
	if currentSettings[key] == nil then
		return
	end
	currentSettings[key] = value

	if key == "MusicVolume" or key == "SfxVolume" then
		applyVolumes()
	end

	SettingsController.SettingsChanged:Fire(currentSettings)

	local SettingsService = Knit.GetService("SettingsService")
	SettingsService:SaveSettings(currentSettings)
end

function SettingsController:KnitStart()
	ensureSoundGroups()

	local SettingsService = Knit.GetService("SettingsService")
	SettingsService:LoadSettings():andThen(function(loaded: { [string]: any })
		for key, value in loaded do
			currentSettings[key] = value
		end
		applyVolumes()
		SettingsController.SettingsChanged:Fire(currentSettings)
	end)
end

function SettingsController:KnitInit() end

return SettingsController
