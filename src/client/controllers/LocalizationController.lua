--!strict
-- T-150 (GDD §13.2). Wraps the pure Translator (T-150) with the actual
-- locale-selection policy: SettingsController's (T-134) Language setting
-- once it loads, otherwise `LocalizationService.SystemLocaleId` normalized
-- down to one of LocalizationConfig's 8 supported codes, otherwise
-- DefaultLocale. `Translate` never shows a raw key to the player — for any
-- key that exists in "en" at all, Translator's own fallback chain (locale
-- -> en) guarantees a real string comes back.
--
-- Reacts live to SettingsController.SettingsChanged (fired once on initial
-- load, and again on every subsequent change) rather than reading
-- GetSettings() synchronously at KnitStart — that would race the async
-- SettingsService:LoadSettings() call and read the pre-load default instead
-- of the player's actual saved language.

local LocalizationService = game:GetService("LocalizationService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)
local Translator = require(ReplicatedStorage.Shared.modules.Translator)

local LocalizationConfig = ConfigService.Localization
local TranslationStrings = ConfigService.Translations

local LocalizationController = Knit.CreateController({
	Name = "LocalizationController",
})

LocalizationController.LocaleChanged = Signal.new() -- (locale: string)

local function isSupportedLocale(locale: string): boolean
	for _, supported in LocalizationConfig.SupportedLocales do
		if supported == locale then
			return true
		end
	end
	return false
end

local function normalizeLocale(systemLocaleId: string): string
	for _, supported in LocalizationConfig.SupportedLocales do
		if supported:lower() == systemLocaleId:lower() then
			return supported
		end
	end
	local primary = systemLocaleId:match("^(%a+)")
	if primary then
		for _, supported in LocalizationConfig.SupportedLocales do
			if supported:lower() == primary:lower() then
				return supported
			end
		end
	end
	return LocalizationConfig.DefaultLocale
end

local currentLocale = normalizeLocale(LocalizationService.SystemLocaleId)

function LocalizationController:GetLocale(): string
	return currentLocale
end

function LocalizationController:SetLocale(locale: string)
	if not isSupportedLocale(locale) or locale == currentLocale then
		return
	end
	currentLocale = locale
	LocalizationController.LocaleChanged:Fire(currentLocale)
end

function LocalizationController:Translate(key: string): string
	return Translator.resolve(currentLocale, key, TranslationStrings, LocalizationConfig.FallbackChain, LocalizationConfig.DefaultLocale)
end

function LocalizationController:KnitStart()
	local SettingsController = Knit.GetController("SettingsController")
	SettingsController.SettingsChanged:Connect(function(settings: { [string]: any })
		if type(settings.Language) == "string" then
			self:SetLocale(settings.Language)
		end
	end)
end

function LocalizationController:KnitInit() end

return LocalizationController
