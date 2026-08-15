local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BreakpointSelector = require(ReplicatedStorage.Shared.modules.BreakpointSelector)
local UIConfig = require(ReplicatedStorage.Shared.config.UIConfig)

return function()
	describe("BreakpointSelector", function()
		it("should select Desktop for an ultrawide viewport (T-132 test case)", function()
			expect(BreakpointSelector.select(2560, UIConfig.Breakpoints)).to.equal("Desktop")
		end)

		it("should select Tablet for a standard tablet viewport (T-132 test case)", function()
			expect(BreakpointSelector.select(1024, UIConfig.Breakpoints)).to.equal("Tablet")
		end)

		it("should select Portrait for a narrow portrait viewport (T-132 test case)", function()
			expect(BreakpointSelector.select(375, UIConfig.Breakpoints)).to.equal("Portrait")
		end)

		it("should select Desktop exactly at the Desktop threshold, not one pixel before", function()
			local breakpoints = UIConfig.Breakpoints
			expect(BreakpointSelector.select(breakpoints.Desktop - 1, breakpoints)).to.equal("Tablet")
			expect(BreakpointSelector.select(breakpoints.Desktop, breakpoints)).to.equal("Desktop")
		end)

		it("should select Tablet exactly at the Tablet threshold, not one pixel before", function()
			local breakpoints = UIConfig.Breakpoints
			expect(BreakpointSelector.select(breakpoints.Tablet - 1, breakpoints)).to.equal("Portrait")
			expect(BreakpointSelector.select(breakpoints.Tablet, breakpoints)).to.equal("Tablet")
		end)
	end)
end
