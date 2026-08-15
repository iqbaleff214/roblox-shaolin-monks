local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ComboTreeWalker = require(ReplicatedStorage.Shared.modules.ComboTreeWalker)

local COMBO_WINDOW = 0.6

local function testTree()
	return {
		{ Input = "Light", DamageMultiplier = 1.0, FrameTime = 0.3, AnimationId = 0 },
		{ Input = "Light", DamageMultiplier = 1.0, FrameTime = 0.3, AnimationId = 0 },
		{ Input = "Light", DamageMultiplier = 1.0, FrameTime = 0.3, AnimationId = 0 },
		{ Input = "Heavy", DamageMultiplier = 1.5, FrameTime = 0.6, AnimationId = 0 },
	}
end

return function()
	describe("ComboTreeWalker", function()
		it("should advance through a scripted input sequence matching the combo tree", function()
			local walker = ComboTreeWalker.new(testTree(), COMBO_WINDOW, 4)
			expect(walker:advance("Light", 0)).to.equal(1)
			expect(walker:advance("Light", 0.2)).to.equal(2)
			expect(walker:advance("Light", 0.4)).to.equal(3)
			expect(walker:advance("Heavy", 0.6)).to.equal(4)
		end)

		it("should stop advancing past the player's unlocked depth (T-041 test case)", function()
			local walker = ComboTreeWalker.new(testTree(), COMBO_WINDOW, 2)
			expect(walker:advance("Light", 0)).to.equal(1)
			expect(walker:advance("Light", 0.1)).to.equal(2)
			-- Step 3 is a valid Light in the tree, but unlocked depth caps at 2.
			expect(walker:advance("Light", 0.2)).to.equal(nil)
			expect(walker:getCurrentStepData().DamageMultiplier).to.equal(1.0) -- still parked at step 2
		end)

		it("should use DEFAULT_UNLOCKED_DEPTH (1) when no depth is provided", function()
			local walker = ComboTreeWalker.new(testTree(), COMBO_WINDOW)
			expect(walker:advance("Light", 0)).to.equal(1)
			expect(walker:advance("Light", 0.1)).to.equal(nil)
		end)

		it("should drop a mismatched input type without erasing existing progress", function()
			local walker = ComboTreeWalker.new(testTree(), COMBO_WINDOW, 4)
			expect(walker:advance("Light", 0)).to.equal(1)
			expect(walker:advance("Heavy", 0.1)).to.equal(nil) -- step 2 wants Light, not Heavy
			expect(walker:advance("Light", 0.2)).to.equal(2) -- still able to continue correctly
		end)

		it("should restart from step 1 once the combo window expires", function()
			local walker = ComboTreeWalker.new(testTree(), COMBO_WINDOW, 4)
			expect(walker:advance("Light", 0)).to.equal(1)
			expect(walker:advance("Light", 10)).to.equal(1) -- way past the window; restarts, not step 2
		end)

		it("should reset to no combo in progress on :reset()", function()
			local walker = ComboTreeWalker.new(testTree(), COMBO_WINDOW, 4)
			walker:advance("Light", 0)
			walker:reset()
			expect(walker:getCurrentStepData()).to.equal(nil)
			expect(walker:advance("Light", 100)).to.equal(1)
		end)
	end)
end
