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
	end)
end
