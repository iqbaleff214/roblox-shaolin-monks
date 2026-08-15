--!strict
-- T-134 (GDD §15.3). Settings persistence. T-160 (PlayerDataService, Phase
-- 14) doesn't exist yet — settings are their own self-contained concern
-- with their own dedicated DataStore, the same reasoning T-114's
-- JadeProductService and T-095's LeaderboardService already established for
-- "needs to survive a restart, general PlayerDataService isn't built yet".
--
-- Settings only ever affect the OWNING player's own client experience
-- (audio volume, control scheme, graphics quality, lock-on assist,
-- language) — there's no server-authoritative gameplay reason to validate
-- them beyond basic type/range sanity, unlike Currency/XP.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local settingsStore = DataStoreService:GetDataStore("SMA_PlayerSettings")

local DEFAULT_SETTINGS = {
	MusicVolume = 0.8,
	SfxVolume = 0.8,
	ControlScheme = "Auto",
	GraphicsQuality = "High",
	LockOnAssist = true,
	Language = "en",
}

local SettingsService = Knit.CreateService({
	Name = "SettingsService",
	Client = {},
})

local function isValidSettings(settings: any): boolean
	if type(settings) ~= "table" then
		return false
	end
	if type(settings.MusicVolume) ~= "number" or settings.MusicVolume < 0 or settings.MusicVolume > 1 then
		return false
	end
	if type(settings.SfxVolume) ~= "number" or settings.SfxVolume < 0 or settings.SfxVolume > 1 then
		return false
	end
	if type(settings.ControlScheme) ~= "string" then
		return false
	end
	if type(settings.GraphicsQuality) ~= "string" then
		return false
	end
	if type(settings.LockOnAssist) ~= "boolean" then
		return false
	end
	if type(settings.Language) ~= "string" then
		return false
	end
	return true
end

function SettingsService.Client:LoadSettings(player: Player): { [string]: any }
	local ok, result = pcall(function()
		return settingsStore:GetAsync(tostring(player.UserId))
	end)
	if ok and isValidSettings(result) then
		return result
	end
	return DEFAULT_SETTINGS
end

function SettingsService.Client:SaveSettings(player: Player, settings: any): boolean
	if not isValidSettings(settings) then
		return false
	end
	local ok = pcall(function()
		settingsStore:SetAsync(tostring(player.UserId), settings)
	end)
	return ok
end

return SettingsService
