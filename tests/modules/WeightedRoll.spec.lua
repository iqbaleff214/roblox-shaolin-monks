local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeightedRoll = require(ReplicatedStorage.Shared.modules.WeightedRoll)

return function()
	describe("WeightedRoll", function()
		it("should always pick the only entry when there's just one", function()
			local rng = Random.new(1)
			local key = WeightedRoll.pick(rng, { { key = "Only", weight = 100 } })
			expect(key).to.equal("Only")
		end)

		it("should be deterministic for the same seed", function()
			local entries = {
				{ key = "Common", weight = 60 },
				{ key = "Uncommon", weight = 25 },
				{ key = "Rare", weight = 10 },
				{ key = "Epic", weight = 4 },
				{ key = "Legendary", weight = 1 },
			}
			local resultsA = {}
			local resultsB = {}
			for i = 1, 20 do
				table.insert(resultsA, WeightedRoll.pick(Random.new(i), entries))
			end
			for i = 1, 20 do
				table.insert(resultsB, WeightedRoll.pick(Random.new(i), entries))
			end
			for i = 1, 20 do
				expect(resultsA[i]).to.equal(resultsB[i])
			end
		end)

		it("should match published weights within tolerance over a large sample (T-102 test case)", function()
			local entries = {
				{ key = "Common", weight = 60 },
				{ key = "Uncommon", weight = 25 },
				{ key = "Rare", weight = 10 },
				{ key = "Epic", weight = 4 },
				{ key = "Legendary", weight = 1 },
			}
			local counts = { Common = 0, Uncommon = 0, Rare = 0, Epic = 0, Legendary = 0 }
			local rng = Random.new(42)
			local sampleSize = 10000
			for _ = 1, sampleSize do
				local key = WeightedRoll.pick(rng, entries)
				counts[key] += 1
			end

			for _, entry in entries do
				local observedPercent = (counts[entry.key] / sampleSize) * 100
				expect(math.abs(observedPercent - entry.weight) < 2).to.equal(true)
			end
		end)

		it("should only ever return the zero-weight entry when it's the sole weight", function()
			local rng = Random.new(7)
			local key = WeightedRoll.pick(rng, { { key = "Zero", weight = 0 }, { key = "All", weight = 100 } })
			expect(key).to.equal("All")
		end)
	end)
end
