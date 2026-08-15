local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RarityVisualPreset = require(ReplicatedStorage.Shared.modules.RarityVisualPreset)
local UIConfig = require(ReplicatedStorage.Shared.config.UIConfig)

return function()
	describe("RarityVisualPreset", function()
		it("should resolve each rarity to its matching Colors/RarityTiers entry (T-082 test case)", function()
			local rarities = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }
			for _, rarity in rarities do
				local preset = RarityVisualPreset.resolve(rarity)
				expect(preset.Color).to.equal(UIConfig.Colors["Rarity" .. rarity])
				expect(preset.GlowIntensity).to.equal(UIConfig.RarityTiers[rarity].GlowIntensity)
				expect(preset.ParticleDensity).to.equal(UIConfig.RarityTiers[rarity].ParticleDensity)
			end
		end)

		it("should give Legendary a strictly higher glow and particle density than Common", function()
			local common = RarityVisualPreset.resolve("Common")
			local legendary = RarityVisualPreset.resolve("Legendary")
			expect(legendary.GlowIntensity > common.GlowIntensity).to.equal(true)
			expect(legendary.ParticleDensity > common.ParticleDensity).to.equal(true)
		end)

		it("should fall back to Common for an unrecognized rarity instead of erroring", function()
			local preset = RarityVisualPreset.resolve("NotARarity")
			expect(preset.Color).to.equal(UIConfig.Colors.RarityCommon)
			expect(preset.GlowIntensity).to.equal(UIConfig.RarityTiers.Common.GlowIntensity)
		end)
	end)
end
