-- T-150 (GDD §13.2). Pure translation-key resolution: given a requested
-- locale and a key, returns the translation for that locale, falling back
-- to `fallbackChain[locale]` (per LocalizationConfig, T-021) when the key
-- is missing there, and finally to `defaultLocale` if even the fallback
-- doesn't have it. Only returns the raw key itself as an absolute last
-- resort — a real content bug (defaultLocale should always be complete),
-- never the expected path, but still safer than erroring in front of a
-- player.
--
-- Takes `translations`/`fallbackChain`/`defaultLocale` as explicit
-- arguments rather than reading TranslationStrings/LocalizationConfig
-- itself, so it stays testable with a tiny fake dictionary instead of the
-- full seed content.

local Translator = {}

export type Translations = { [string]: { [string]: string } }

function Translator.resolve(locale: string, key: string, translations: Translations, fallbackChain: { [string]: string }, defaultLocale: string): string
	local localeTable = translations[locale]
	if localeTable and localeTable[key] then
		return localeTable[key]
	end

	local fallbackLocale = fallbackChain[locale]
	if fallbackLocale and fallbackLocale ~= locale then
		local fallbackTable = translations[fallbackLocale]
		if fallbackTable and fallbackTable[key] then
			return fallbackTable[key]
		end
	end

	local defaultTable = translations[defaultLocale]
	if defaultTable and defaultTable[key] then
		return defaultTable[key]
	end

	return key
end

return Translator
