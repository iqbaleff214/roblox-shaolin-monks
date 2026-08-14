local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DebounceGate = require(ReplicatedStorage.Shared.modules.DebounceGate)

return function()
	describe("DebounceGate", function()
		it("should fire exactly once per press (T-032 test case)", function()
			local gate = DebounceGate.new(1)
			expect(gate:tryFire(0)).to.equal(true)
			expect(gate:tryFire(0.1)).to.equal(false)
			expect(gate:tryFire(0.5)).to.equal(false)
		end)

		it("should respect a configurable reset delay before firing again", function()
			local shortGate = DebounceGate.new(0.5)
			local longGate = DebounceGate.new(5)

			expect(shortGate:tryFire(0)).to.equal(true)
			expect(shortGate:tryFire(0.5)).to.equal(true) -- exactly at boundary

			expect(longGate:tryFire(0)).to.equal(true)
			expect(longGate:tryFire(0.5)).to.equal(false) -- same elapsed time, longer delay
		end)

		it("should treat each gate instance independently", function()
			local gateA = DebounceGate.new(1)
			local gateB = DebounceGate.new(1)

			expect(gateA:tryFire(0)).to.equal(true)
			expect(gateB:tryFire(0)).to.equal(true) -- unaffected by gateA's state
		end)
	end)
end
