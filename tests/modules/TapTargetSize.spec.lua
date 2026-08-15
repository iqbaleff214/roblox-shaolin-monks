local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TapTargetSize = require(ReplicatedStorage.Shared.modules.TapTargetSize)

return function()
	describe("TapTargetSize", function()
		it("should accept a button exactly at the 44px minimum", function()
			expect(TapTargetSize.meetsMinimum(44, 44)).to.equal(true)
		end)

		it("should accept a button comfortably above the minimum", function()
			expect(TapTargetSize.meetsMinimum(60, 60)).to.equal(true)
		end)

		it("should reject a button one pixel short on width", function()
			expect(TapTargetSize.meetsMinimum(43, 44)).to.equal(false)
		end)

		it("should reject a button one pixel short on height", function()
			expect(TapTargetSize.meetsMinimum(44, 43)).to.equal(false)
		end)
	end)
end
