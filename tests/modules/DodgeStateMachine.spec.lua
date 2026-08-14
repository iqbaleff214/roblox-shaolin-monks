local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DodgeStateMachine = require(ReplicatedStorage.Shared.modules.DodgeStateMachine)

local IFRAMES = 0.2
local COOLDOWN = 0.8

return function()
	describe("DodgeStateMachine", function()
		it("should allow the first dodge to start immediately", function()
			local machine = DodgeStateMachine.new(IFRAMES, COOLDOWN)
			expect(machine:tryDodge(0)).to.equal(true)
		end)

		it("should reject a second dodge attempted before the cooldown elapses (no spam-dodging)", function()
			local machine = DodgeStateMachine.new(IFRAMES, COOLDOWN)
			expect(machine:tryDodge(0)).to.equal(true)
			expect(machine:tryDodge(0.5)).to.equal(false) -- 0.5s < 0.8s cooldown
		end)

		it("should allow a new dodge once the cooldown has fully elapsed", function()
			local machine = DodgeStateMachine.new(IFRAMES, COOLDOWN)
			expect(machine:tryDodge(0)).to.equal(true)
			expect(machine:tryDodge(0.8)).to.equal(true) -- exactly at cooldown boundary
		end)

		it("should report invulnerable only inside the i-frame window (T-031 test case)", function()
			local machine = DodgeStateMachine.new(IFRAMES, COOLDOWN)
			machine:tryDodge(10)

			expect(machine:isInvulnerable(10)).to.equal(true) -- at dodge start
			expect(machine:isInvulnerable(10.1)).to.equal(true) -- inside window (0.1s < 0.2s)
			expect(machine:isInvulnerable(10.2)).to.equal(false) -- exactly at the boundary, window closed
			expect(machine:isInvulnerable(10.5)).to.equal(false) -- well outside the window
		end)

		it("should never report invulnerable before any dodge has happened", function()
			local machine = DodgeStateMachine.new(IFRAMES, COOLDOWN)
			expect(machine:isInvulnerable(0)).to.equal(false)
		end)
	end)
end
