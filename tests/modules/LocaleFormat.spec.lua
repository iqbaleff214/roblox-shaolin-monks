local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocaleFormat = require(ReplicatedStorage.Shared.modules.LocaleFormat)

return function()
	describe("LocaleFormat", function()
		describe("formatNumber", function()
			it("should format 1234567 with comma thousands separators for en (T-152 test case)", function()
				expect(LocaleFormat.formatNumber(1234567, "en")).to.equal("1,234,567")
			end)

			it("should format 1234567 with period thousands separators for id (T-152 test case)", function()
				expect(LocaleFormat.formatNumber(1234567, "id")).to.equal("1.234.567")
			end)

			it("should render the same value differently across the two locales", function()
				local en = LocaleFormat.formatNumber(1234567, "en")
				local id = LocaleFormat.formatNumber(1234567, "id")
				expect(en).never.to.equal(id)
			end)

			it("should not insert a separator for values under 1000", function()
				expect(LocaleFormat.formatNumber(999, "en")).to.equal("999")
			end)

			it("should format a negative value with the sign preserved", function()
				expect(LocaleFormat.formatNumber(-1500, "en")).to.equal("-1,500")
			end)

			it("should format a decimal value using the locale's decimal separator", function()
				expect(LocaleFormat.formatNumber(1234.5, "en")).to.equal("1,234.50")
				expect(LocaleFormat.formatNumber(1234.5, "id")).to.equal("1.234,50")
			end)

			it("should fall back to the default locale's format for an unrecognized locale", function()
				expect(LocaleFormat.formatNumber(1234567, "xx")).to.equal("1,234,567")
			end)
		end)

		describe("formatDate", function()
			it("should return a non-empty string without erroring for every supported locale", function()
				local now = 1735689600 -- 2025-01-01T00:00:00Z, an arbitrary fixed timestamp
				local LocalizationConfig = require(ReplicatedStorage.Shared.config.LocalizationConfig)
				for _, locale in LocalizationConfig.SupportedLocales do
					local formatted = LocaleFormat.formatDate(now, locale, "LL")
					expect(type(formatted)).to.equal("string")
				end
			end)
		end)
	end)
end
