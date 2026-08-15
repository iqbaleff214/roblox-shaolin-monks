local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AntiCheatConfig = require(ReplicatedStorage.Shared.config.AntiCheatConfig)

return function()
	describe("AntiCheatConfig", function()
		it("should give every rate limit a positive burst and refill rate", function()
			for actionKey, limit in AntiCheatConfig.RateLimits do
				expect(limit.MaxTokens > 0).to.equal(true)
				expect(limit.RefillPerSecond > 0).to.equal(true)
				expect(type(actionKey)).to.equal("string")
			end
		end)

		it("should define a positive DefaultRateLimit fallback", function()
			expect(AntiCheatConfig.DefaultRateLimit.MaxTokens > 0).to.equal(true)
			expect(AntiCheatConfig.DefaultRateLimit.RefillPerSecond > 0).to.equal(true)
		end)
	end)
end
