local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TranslationStrings = require(ReplicatedStorage.Shared.config.TranslationStrings)
local LocalizationConfig = require(ReplicatedStorage.Shared.config.LocalizationConfig)

return function()
	describe("TranslationStrings", function()
		it("should fully populate 'en' with non-empty string values for every key", function()
			expect(TranslationStrings.en).to.be.a("table")
			local count = 0
			for key, value in TranslationStrings.en do
				expect(type(key)).to.equal("string")
				expect(type(value)).to.equal("string")
				expect(#value > 0).to.equal(true)
				count += 1
			end
			expect(count > 0).to.equal(true)
		end)

		it("should only define locales that exist in LocalizationConfig.SupportedLocales", function()
			local validLocales = {}
			for _, locale in LocalizationConfig.SupportedLocales do
				validLocales[locale] = true
			end
			for locale in TranslationStrings do
				expect(validLocales[locale]).to.equal(true)
			end
		end)

		it("should never define a key for a non-en locale that doesn't also exist in 'en' (drift guard)", function()
			for locale, translations in TranslationStrings do
				if locale ~= "en" then
					for key in translations do
						expect(TranslationStrings.en[key]).never.to.equal(nil)
					end
				end
			end
		end)
	end)
end
