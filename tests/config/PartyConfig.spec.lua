local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PartyConfig = require(ReplicatedStorage.Shared.config.PartyConfig)

return function()
	describe("PartyConfig", function()
		it("should cap party size at 4 per §12.2 (leader + 3 invited friends)", function()
			expect(PartyConfig.MaxPartySize).to.equal(4)
		end)
	end)
end
