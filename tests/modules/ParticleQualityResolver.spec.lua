local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ParticleQualityResolver = require(ReplicatedStorage.Shared.modules.ParticleQualityResolver)

return function()
	describe("ParticleQualityResolver", function()
		local limits = { High = 200, Medium = 100, Low = 40 }

		it("should return the base rate unchanged on High tier", function()
			expect(ParticleQualityResolver.resolveRate(50, "High", limits)).to.equal(50)
		end)

		it("should scale the rate down proportionally on Medium tier", function()
			expect(ParticleQualityResolver.resolveRate(50, "Medium", limits)).to.equal(25)
		end)

		it("should scale the rate down proportionally on Low tier", function()
			expect(ParticleQualityResolver.resolveRate(50, "Low", limits)).to.equal(10)
		end)

		it("should fall back to the full base rate for an unknown tier", function()
			expect(ParticleQualityResolver.resolveRate(50, "Ultra", limits)).to.equal(50)
		end)

		it("should return 0 when High is configured as 0 (guards divide-by-zero)", function()
			expect(ParticleQualityResolver.resolveRate(50, "Medium", { High = 0, Medium = 0, Low = 0 })).to.equal(0)
		end)
	end)
end
