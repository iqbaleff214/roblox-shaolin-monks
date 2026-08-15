local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ParryTiming = require(ReplicatedStorage.Shared.modules.ParryTiming)

local PARRY_WINDOW = 0.15 -- matches CombatConfig.Attacks.ParryWindow

return function()
	describe("ParryTiming", function()
		it("should sweep -200ms to +200ms and only Perfect Parry inside the window (T-043 test case)", function()
			-- Well before impact: outside the window, but still a normal block.
			expect(ParryTiming.classify(-0.2, PARRY_WINDOW)).to.equal("Block")
			-- Exactly at the window boundary: still counts as Perfect Parry.
			expect(ParryTiming.classify(-0.15, PARRY_WINDOW)).to.equal("PerfectParry")
			-- Comfortably inside the window.
			expect(ParryTiming.classify(-0.05, PARRY_WINDOW)).to.equal("PerfectParry")
			-- At the moment of impact.
			expect(ParryTiming.classify(0, PARRY_WINDOW)).to.equal("PerfectParry")
			-- After impact: too late, not even a block.
			expect(ParryTiming.classify(0.05, PARRY_WINDOW)).to.equal("None")
			expect(ParryTiming.classify(0.2, PARRY_WINDOW)).to.equal("None")
		end)

		it("should never whiff-punish a block outside the parry window (DoD guarantee)", function()
			expect(ParryTiming.classify(-1, PARRY_WINDOW)).to.equal("Block")
			expect(ParryTiming.classify(-10, PARRY_WINDOW)).to.equal("Block")
		end)

		it("should report None when the player never blocked at all", function()
			expect(ParryTiming.classify(nil, PARRY_WINDOW)).to.equal("None")
		end)
	end)
end
