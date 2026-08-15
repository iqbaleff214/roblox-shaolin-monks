local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ChiMeterState = require(ReplicatedStorage.Shared.modules.ChiMeterState)

local MAX_CHI = 100

return function()
	describe("ChiMeterState", function()
		it("should reject activation at 99 Chi and accept it at 100 (T-047 test case)", function()
			local meter = ChiMeterState.new(MAX_CHI)
			meter:gain(99)
			expect(meter:tryActivate()).to.equal(false)

			meter:gain(1) -- now at 100
			expect(meter:tryActivate()).to.equal(true)
		end)

		it("should reset the meter to 0 after a successful activation", function()
			local meter = ChiMeterState.new(MAX_CHI)
			meter:gain(MAX_CHI)
			meter:tryActivate()
			expect(meter.value).to.equal(0)
			expect(meter:tryActivate()).to.equal(false) -- can't activate again immediately
		end)

		it("should cap gains at Max and never go negative", function()
			local meter = ChiMeterState.new(MAX_CHI)
			meter:gain(500)
			expect(meter.value).to.equal(MAX_CHI)

			meter:gain(-1000)
			expect(meter.value).to.equal(0)
		end)

		it("should leave the meter untouched when activation is rejected", function()
			local meter = ChiMeterState.new(MAX_CHI)
			meter:gain(50)
			meter:tryActivate()
			expect(meter.value).to.equal(50)
		end)
	end)
end
