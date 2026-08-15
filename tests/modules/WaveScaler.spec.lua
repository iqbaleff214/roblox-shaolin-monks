local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WaveScaler = require(ReplicatedStorage.Shared.modules.WaveScaler)

return function()
	describe("WaveScaler", function()
		it("should scale enemy count and HP differently at party size 1 vs 4 (T-064 test case)", function()
			local soloCount = WaveScaler.scaleEnemyCount(3, 1)
			local fullPartyCount = WaveScaler.scaleEnemyCount(3, 4)
			expect(soloCount).to.equal(3)
			expect(fullPartyCount).to.equal(4)
			expect(fullPartyCount > soloCount).to.equal(true)

			local soloMultiplier = WaveScaler.healthMultiplier(1)
			local fullPartyMultiplier = WaveScaler.healthMultiplier(4)
			expect(soloMultiplier).to.equal(1)
			expect(fullPartyMultiplier).to.equal(2.2)
			expect(fullPartyMultiplier > soloMultiplier).to.equal(true)
		end)

		it("should never scale below the base count/multiplier even for an invalid party size", function()
			expect(WaveScaler.scaleEnemyCount(3, 0)).to.equal(3)
			expect(WaveScaler.healthMultiplier(0)).to.equal(1)
		end)

		it("should scale monotonically with party size", function()
			local previousCount, previousMultiplier = -1, -1
			for partySize = 1, 4 do
				local count = WaveScaler.scaleEnemyCount(3, partySize)
				local multiplier = WaveScaler.healthMultiplier(partySize)
				expect(count >= previousCount).to.equal(true)
				expect(multiplier > previousMultiplier).to.equal(true)
				previousCount, previousMultiplier = count, multiplier
			end
		end)
	end)
end
