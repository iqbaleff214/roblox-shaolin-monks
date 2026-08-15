local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RotationSchedule = require(ReplicatedStorage.Shared.modules.RotationSchedule)

return function()
	describe("RotationSchedule", function()
		describe("isExpired", function()
			it("should not be expired one second before the duration elapses", function()
				expect(RotationSchedule.isExpired(0, 48 * 3600 - 1, 48)).to.equal(false)
			end)

			it("should be expired exactly at the duration boundary", function()
				expect(RotationSchedule.isExpired(0, 48 * 3600, 48)).to.equal(true)
			end)
		end)

		describe("pickRotation", function()
			it("should never pick more items than the pool has available after exclusions", function()
				local picked = RotationSchedule.pickRotation({ "A", "B" }, { A = true }, 5, 1)
				expect(#picked).to.equal(1)
				expect(picked[1]).to.equal("B")
			end)

			it("should never include an excluded item", function()
				local picked = RotationSchedule.pickRotation({ "A", "B", "C", "D" }, { B = true, D = true }, 2, 7)
				for _, id in picked do
					expect(id == "B" or id == "D").to.equal(false)
				end
			end)

			it("should never pick duplicates", function()
				local picked = RotationSchedule.pickRotation({ "A", "B", "C", "D", "E" }, {}, 3, 42)
				local seen = {}
				for _, id in picked do
					expect(seen[id]).to.equal(nil)
					seen[id] = true
				end
			end)

			it("should be deterministic for the same seed", function()
				local pool = { "A", "B", "C", "D", "E" }
				local first = RotationSchedule.pickRotation(pool, {}, 2, 99)
				local second = RotationSchedule.pickRotation(pool, {}, 2, 99)
				expect(first[1]).to.equal(second[1])
				expect(first[2]).to.equal(second[2])
			end)

			it("should return an empty list when everything is excluded", function()
				local picked = RotationSchedule.pickRotation({ "A", "B" }, { A = true, B = true }, 2, 5)
				expect(#picked).to.equal(0)
			end)
		end)
	end)
end
