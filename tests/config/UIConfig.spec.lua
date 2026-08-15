local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIConfig = require(ReplicatedStorage.Shared.config.UIConfig)

return function()
	describe("UIConfig", function()
		it("should strictly order breakpoints Desktop > Tablet > Portrait (§15.2)", function()
			expect(UIConfig.Breakpoints.Desktop > UIConfig.Breakpoints.Tablet).to.equal(true)
			expect(UIConfig.Breakpoints.Tablet > UIConfig.Breakpoints.Portrait).to.equal(true)
		end)

		it("should order particle limits High > Medium > Low (§17.4)", function()
			expect(UIConfig.ParticleLimits.High > UIConfig.ParticleLimits.Medium).to.equal(true)
			expect(UIConfig.ParticleLimits.Medium > UIConfig.ParticleLimits.Low).to.equal(true)
		end)

		it("should define Color3 values for every color token", function()
			for _, color in UIConfig.Colors do
				expect(typeof(color)).to.equal("Color3")
			end
		end)

		it("should define relative (0-1) layout anchors, never pixel offsets", function()
			for _, anchor in UIConfig.LayoutAnchors do
				expect(typeof(anchor)).to.equal("Vector2")
				expect(anchor.X >= 0 and anchor.X <= 1).to.equal(true)
				expect(anchor.Y >= 0 and anchor.Y <= 1).to.equal(true)
			end
		end)

		it("should define all 5 rarity tiers with a matching Colors.RarityXxx entry (§5.3)", function()
			local expectedRarities = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }
			for _, rarity in expectedRarities do
				expect(UIConfig.RarityTiers[rarity]).to.be.a("table")
				expect(UIConfig.Colors["Rarity" .. rarity]).never.to.equal(nil)
			end
			local count = 0
			for _ in UIConfig.RarityTiers do
				count += 1
			end
			expect(count).to.equal(#expectedRarities)
		end)

		it("should scale rarity GlowIntensity and ParticleDensity monotonically from Common to Legendary", function()
			local orderedRarities = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }
			local previousGlow, previousDensity = -1, -1
			for _, rarity in orderedRarities do
				local tier = UIConfig.RarityTiers[rarity]
				expect(tier.GlowIntensity >= previousGlow).to.equal(true)
				expect(tier.ParticleDensity >= previousDensity).to.equal(true)
				previousGlow, previousDensity = tier.GlowIntensity, tier.ParticleDensity
			end
		end)
	end)
end
