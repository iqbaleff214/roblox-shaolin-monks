local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalizationConfig = require(ReplicatedStorage.Shared.config.LocalizationConfig)

return function()
	describe("LocalizationConfig", function()
		it("should support exactly the 8 launch languages from §13.1", function()
			expect(#LocalizationConfig.SupportedLocales).to.equal(8)
		end)

		it("should always include 'en' as a supported locale and the default", function()
			expect(LocalizationConfig.DefaultLocale).to.equal("en")

			local found = false
			for _, locale in LocalizationConfig.SupportedLocales do
				if locale == "en" then
					found = true
				end
			end
			expect(found).to.equal(true)
		end)

		it("should make 'en' the fallback root (maps to itself)", function()
			expect(LocalizationConfig.FallbackChain.en).to.equal("en")
		end)

		it("should resolve every supported locale to 'en' within one hop (no fallback cycles)", function()
			for _, locale in LocalizationConfig.SupportedLocales do
				local fallback = LocalizationConfig.FallbackChain[locale]
				expect(fallback).never.to.equal(nil)
				-- Depth-1 chain by design: following the chain from any locale
				-- must land on "en" in at most one more hop.
				if fallback ~= "en" then
					expect(LocalizationConfig.FallbackChain[fallback]).to.equal("en")
				end
			end
		end)
	end)
end
