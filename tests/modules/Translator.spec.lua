local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Translator = require(ReplicatedStorage.Shared.modules.Translator)

return function()
	local translations = {
		en = { ["ui.button.play"] = "Play", ["ui.button.back"] = "Back" },
		id = { ["ui.button.back"] = "Kembali" },
	}
	local fallbackChain = { en = "en", id = "en", ["zh-CN"] = "en" }

	describe("Translator", function()
		it("should return the exact-locale translation when it exists", function()
			expect(Translator.resolve("id", "ui.button.back", translations, fallbackChain, "en")).to.equal("Kembali")
		end)

		it("should fall back to en when the key is missing in the requested locale (T-150 test case)", function()
			expect(Translator.resolve("id", "ui.button.play", translations, fallbackChain, "en")).to.equal("Play")
		end)

		it("should return the raw key when even the default locale is missing it", function()
			expect(Translator.resolve("id", "ui.button.nonexistent", translations, fallbackChain, "en")).to.equal("ui.button.nonexistent")
		end)

		it("should resolve en directly without needing a fallback hop", function()
			expect(Translator.resolve("en", "ui.button.play", translations, fallbackChain, "en")).to.equal("Play")
		end)

		it("should fall back to en for a locale with no translations table at all", function()
			expect(Translator.resolve("zh-CN", "ui.button.play", translations, fallbackChain, "en")).to.equal("Play")
		end)
	end)
end
