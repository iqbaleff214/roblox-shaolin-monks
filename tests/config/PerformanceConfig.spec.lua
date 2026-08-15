local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PerformanceConfig = require(ReplicatedStorage.Shared.config.PerformanceConfig)

return function()
	describe("PerformanceConfig", function()
		it("should define positive LOD tuning values", function()
			expect(PerformanceConfig.LOD.DefaultSwapDistance > 0).to.equal(true)
			expect(PerformanceConfig.LOD.CheckIntervalSeconds > 0).to.equal(true)
		end)

		it("should define a streaming target radius larger than the min radius", function()
			expect(PerformanceConfig.Streaming.MinRadius > 0).to.equal(true)
			expect(PerformanceConfig.Streaming.TargetRadius > PerformanceConfig.Streaming.MinRadius).to.equal(true)
		end)
	end)
end
