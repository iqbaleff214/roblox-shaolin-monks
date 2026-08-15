local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponArcCheck = require(ReplicatedStorage.Shared.modules.WeaponArcCheck)

return function()
	describe("WeaponArcCheck", function()
		it("should accept a target directly ahead within range", function()
			local hit = WeaponArcCheck.isWithinArc(Vector3.new(0, 0, 0), Vector3.new(0, 0, -1), Vector3.new(0, 0, -5), 10, 90)
			expect(hit).to.equal(true)
		end)

		it("should reject a target beyond range", function()
			local hit = WeaponArcCheck.isWithinArc(Vector3.new(0, 0, 0), Vector3.new(0, 0, -1), Vector3.new(0, 0, -20), 10, 90)
			expect(hit).to.equal(false)
		end)

		it("should reject a target directly behind the attacker", function()
			local hit = WeaponArcCheck.isWithinArc(Vector3.new(0, 0, 0), Vector3.new(0, 0, -1), Vector3.new(0, 0, 5), 10, 90)
			expect(hit).to.equal(false)
		end)

		it("should reject a target outside a narrow arc even within range", function()
			local hit = WeaponArcCheck.isWithinArc(Vector3.new(0, 0, 0), Vector3.new(0, 0, -1), Vector3.new(5, 0, -0.1), 10, 30)
			expect(hit).to.equal(false)
		end)

		it("should reject a target at the attacker's exact position", function()
			local hit = WeaponArcCheck.isWithinArc(Vector3.new(0, 0, 0), Vector3.new(0, 0, -1), Vector3.new(0, 0, 0), 10, 90)
			expect(hit).to.equal(false)
		end)
	end)
end
