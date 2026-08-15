local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigService = require(ReplicatedStorage.Shared.ConfigService)

local EXPECTED_KEYS = {
	"Combat",
	"Weapon",
	"Enemy",
	"Chapter",
	"Loot",
	"Accessory",
	"Progression",
	"Shop",
	"Monetization",
	"Audio",
	"UI",
	"Localization",
	"Quest",
}

return function()
	describe("ConfigService", function()
		it("should expose all 13 config modules as non-nil tables (§14.6)", function()
			for _, key in EXPECTED_KEYS do
				expect(ConfigService[key]).to.be.a("table")
			end
		end)

		it("should expose exactly 13 keys, no more, no less", function()
			local count = 0
			for _ in ConfigService do
				count += 1
			end
			expect(count).to.equal(#EXPECTED_KEYS)
		end)
	end)
end
