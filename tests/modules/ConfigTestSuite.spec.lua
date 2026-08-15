local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigTestSuite = require(ReplicatedStorage.Shared.modules.ConfigTestSuite)

return function()
	describe("ConfigTestSuite", function()
		it("should report within budget when elapsed time is under the budget", function()
			expect(ConfigTestSuite.isWithinBudget(10, 30)).to.equal(true)
		end)

		it("should report within budget exactly at the budget boundary", function()
			expect(ConfigTestSuite.isWithinBudget(30, 30)).to.equal(true)
		end)

		it("should report over budget when elapsed time exceeds the budget", function()
			expect(ConfigTestSuite.isWithinBudget(31, 30)).to.equal(false)
		end)

		it("should default TimeBudgetSeconds to 30", function()
			expect(ConfigTestSuite.TimeBudgetSeconds).to.equal(30)
		end)
	end)
end
