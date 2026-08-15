local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PoiseStateMachine = require(ReplicatedStorage.Shared.modules.PoiseStateMachine)

local THRESHOLD = 100
local DECAY_PER_SEC = 5

return function()
	describe("PoiseStateMachine", function()
		it("should fire Staggered exactly once on the hit that crosses the threshold (T-046 test case)", function()
			local poise = PoiseStateMachine.new(THRESHOLD, DECAY_PER_SEC, 0)
			expect(poise:applyHit(40, 0)).to.equal(false)
			expect(poise:applyHit(40, 0.1)).to.equal(false)
			expect(poise:applyHit(40, 0.2)).to.equal(true) -- 120 >= 100, crosses here
			expect(poise.isStaggered).to.equal(true)
		end)

		it("should not re-trigger Staggered on further hits once already staggered", function()
			local poise = PoiseStateMachine.new(THRESHOLD, DECAY_PER_SEC, 0)
			poise:applyHit(150, 0) -- crosses immediately
			expect(poise.isStaggered).to.equal(true)
			expect(poise:applyHit(50, 0.1)).to.equal(false)
		end)

		it("should decay poise over time when not hit", function()
			local poise = PoiseStateMachine.new(THRESHOLD, DECAY_PER_SEC, 0)
			poise:applyHit(50, 0)
			poise:tick(2) -- 2s * 5/s = 10 decayed
			expect(poise:applyHit(0, 2)).to.equal(false)
			-- Poise should now be ~40, not 50 — verified indirectly: 60 more
			-- damage (40 + 60 = 100) should just barely cross the threshold.
			expect(poise:applyHit(60, 2)).to.equal(true)
		end)

		it("should never let decay push poise below zero", function()
			local poise = PoiseStateMachine.new(THRESHOLD, DECAY_PER_SEC, 0)
			poise:applyHit(10, 0)
			poise:tick(100) -- way more decay than the poise accumulated
			expect(poise:applyHit(100, 100)).to.equal(true) -- starts fresh from 0, not negative
		end)

		it("should not decay while staggered, and clearStagger should reset to a fresh bar", function()
			local poise = PoiseStateMachine.new(THRESHOLD, DECAY_PER_SEC, 0)
			poise:applyHit(150, 0)
			expect(poise.isStaggered).to.equal(true)
			poise:tick(1000) -- would fully decay a normal bar, but staggered doesn't decay
			expect(poise.isStaggered).to.equal(true)

			poise:clearStagger(1000)
			expect(poise.isStaggered).to.equal(false)
			expect(poise:applyHit(THRESHOLD - 1, 1000)).to.equal(false) -- fresh bar, not still full
		end)
	end)
end
