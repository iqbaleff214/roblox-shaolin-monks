-- GDD §13.1 / §13.2. Launch-supported locales and the fallback chain. Every
-- locale falls back to "en" directly (depth-1 chain) so there is no risk of
-- a fallback cycle — see LocalizationConfig.spec.lua.

return {
	DefaultLocale = "en",

	SupportedLocales = {
		"en",
		"id",
		"es",
		"pt-BR",
		"fr",
		"de",
		"ru",
		"zh-CN",
	},

	FallbackChain = {
		en = "en", -- root: falls back to itself
		id = "en",
		es = "en",
		["pt-BR"] = "en",
		fr = "en",
		de = "en",
		ru = "en",
		["zh-CN"] = "en",
	},
}
