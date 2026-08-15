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

	-- T-152 (§13.2): decimal/thousands separator convention per locale. A
	-- deliberate simplification of real CLDR locale data (e.g. French's
	-- traditional narrow-no-break-space grouping, or CJK myriad grouping)
	-- for a launch-scope engineering task — real per-locale nuance is
	-- localization-content work, not something this formatter invents.
	NumberFormat = {
		en = { ThousandsSeparator = ",", DecimalSeparator = "." },
		["zh-CN"] = { ThousandsSeparator = ",", DecimalSeparator = "." },
		id = { ThousandsSeparator = ".", DecimalSeparator = "," },
		es = { ThousandsSeparator = ".", DecimalSeparator = "," },
		["pt-BR"] = { ThousandsSeparator = ".", DecimalSeparator = "," },
		fr = { ThousandsSeparator = ".", DecimalSeparator = "," },
		de = { ThousandsSeparator = ".", DecimalSeparator = "," },
		ru = { ThousandsSeparator = ".", DecimalSeparator = "," },
	},
}
