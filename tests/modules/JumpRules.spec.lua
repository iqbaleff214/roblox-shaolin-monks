local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JumpRules = require(ReplicatedStorage.Shared.modules.JumpRules)

return function()
	describe("JumpRules", function()
		it("should cap max jumps at 1 pre-unlock and 2 post-unlock (T-030 test case)", function()
			expect(JumpRules.getMaxJumps(false)).to.equal(1)
			expect(JumpRules.getMaxJumps(true)).to.equal(2)
		end)

		it("should allow jumping from the ground pre-unlock but not a second air jump", function()
			expect(JumpRules.canJump(0, false)).to.equal(true)
			expect(JumpRules.canJump(1, false)).to.equal(false)
		end)

		it("should allow exactly one extra air jump post-unlock", function()
			expect(JumpRules.canJump(0, true)).to.equal(true)
			expect(JumpRules.canJump(1, true)).to.equal(true)
			expect(JumpRules.canJump(2, true)).to.equal(false)
		end)
	end)
end
