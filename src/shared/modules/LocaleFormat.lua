-- T-152 (GDD §13.2). Locale-aware number and date formatting.
--
-- Number formatting is pure Luau string manipulation driven by
-- LocalizationConfig.NumberFormat (T-152) — fully deterministic and
-- testable. Date formatting defers to Roblox's own `DateTime:FormatLocalTime`,
-- which is genuinely locale- and local-timezone-aware when run on the
-- client (unlike `os.date`, which Roblox does not guarantee reflects the
-- player's real timezone) — this module only maps our short locale codes
-- (e.g. "pt-BR") to the region-qualified ids that API expects (e.g.
-- "pt-br"), pcall-guarded since an unrecognized locale id is Roblox's own
-- live-service behavior to reject, not something this module can validate
-- in advance.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalizationConfig = require(ReplicatedStorage.Shared.config.LocalizationConfig)

local LocaleFormat = {}

local LOCALE_ID_MAP: { [string]: string } = {
	en = "en-us",
	id = "id-id",
	es = "es-es",
	["pt-BR"] = "pt-br",
	fr = "fr-fr",
	de = "de-de",
	ru = "ru-ru",
	["zh-CN"] = "zh-cn",
}

-- Groups `digits` (a plain non-negative integer string) into 3s from the
-- right, joined by `separator`. Reverse -> chunk -> join -> reverse is the
-- standard trick for grouping from the LEAST significant digit without
-- needing to know the total length up front.
local function groupDigits(digits: string, separator: string): string
	local reversedDigits = digits:reverse()
	local chunks = {}
	for i = 1, #reversedDigits, 3 do
		table.insert(chunks, reversedDigits:sub(i, i + 2))
	end
	return table.concat(chunks, separator):reverse()
end

function LocaleFormat.formatNumber(value: number, locale: string): string
	local format = LocalizationConfig.NumberFormat[locale] or LocalizationConfig.NumberFormat[LocalizationConfig.DefaultLocale]

	local isNegative = value < 0
	local rounded = math.floor(math.abs(value) * 100 + 0.5) / 100 -- round to 2 decimal places
	local integerPart = math.floor(rounded)
	local fractionalCents = math.floor((rounded - integerPart) * 100 + 0.5)

	local result = groupDigits(tostring(integerPart), format.ThousandsSeparator)
	if fractionalCents > 0 then
		result = result .. format.DecimalSeparator .. string.format("%02d", fractionalCents)
	end
	if isNegative then
		result = "-" .. result
	end
	return result
end

-- `formatToken` is a Roblox DateTime ICU-style pattern (e.g. "LL" for a
-- localized medium date). Falls back to the default locale's id, then to
-- a fixed "en-us" pattern, if the requested locale id errors.
function LocaleFormat.formatDate(unixTimestamp: number, locale: string, formatToken: string): string
	local dateTime = DateTime.fromUnixTimestamp(unixTimestamp)
	local localeId = LOCALE_ID_MAP[locale] or LOCALE_ID_MAP[LocalizationConfig.DefaultLocale]

	local ok, formatted = pcall(function()
		return dateTime:FormatLocalTime(formatToken, localeId)
	end)
	if ok then
		return formatted
	end

	local fallbackOk, fallbackFormatted = pcall(function()
		return dateTime:FormatLocalTime(formatToken, "en-us")
	end)
	return if fallbackOk then fallbackFormatted else ""
end

return LocaleFormat
