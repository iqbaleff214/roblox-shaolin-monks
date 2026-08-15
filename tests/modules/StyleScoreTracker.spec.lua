local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StyleScoreTracker = require(ReplicatedStorage.Shared.modules.StyleScoreTracker)

return function()
	describe("StyleScoreTracker", function()
		it("should build a combo, get hit (reset), and leave Style Score unaffected by the reset (T-048 test case)", function()
			local tracker = StyleScoreTracker.new(2)
			tracker:registerHit(0) -- combo 1, score += 1 = 1
			tracker:registerHit(0.1) -- combo 2, score += 2 = 3
			tracker:registerHit(0.2) -- combo 3, score += 3 = 6
			local scoreBeforeReset = tracker.styleScore

			tracker:resetCombo() -- player got hit
			expect(tracker.comboCounter).to.equal(0)
			expect(tracker.styleScore).to.equal(scoreBeforeReset) -- untouched by the reset itself
		end)

		it("should keep accumulating Style Score after a reset via a fresh combo", function()
			local tracker = StyleScoreTracker.new(2)
			tracker:registerHit(0)
			tracker:registerHit(0.1)
			local scoreAfterFirstCombo = tracker.styleScore

			tracker:resetCombo()
			tracker:registerHit(1) -- new combo starts at 1 again
			expect(tracker.comboCounter).to.equal(1)
			expect(tracker.styleScore).to.equal(scoreAfterFirstCombo + 1)
		end)

		it("should auto-restart the combo once the rolling window lapses", function()
			local tracker = StyleScoreTracker.new(2)
			tracker:registerHit(0)
			tracker:registerHit(0.5)
			expect(tracker.comboCounter).to.equal(2)

			tracker:registerHit(10) -- way past the 2s window
			expect(tracker.comboCounter).to.equal(1) -- restarted, not 3
		end)

		it("should score longer combos more per hit than an equivalent number of short ones", function()
			local longCombo = StyleScoreTracker.new(2)
			for i = 0, 4 do
				longCombo:registerHit(i * 0.1)
			end -- one 5-hit combo: 1+2+3+4+5 = 15

			local shortCombos = StyleScoreTracker.new(2)
			for i = 0, 4 do
				shortCombos:registerHit(i * 10) -- each hit >2s apart -> always restarts at 1
			end -- five 1-hit combos: 1*5 = 5

			expect(longCombo.styleScore > shortCombos.styleScore).to.equal(true)
		end)
	end)
end
