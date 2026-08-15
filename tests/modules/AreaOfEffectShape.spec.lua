local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AreaOfEffectShape = require(ReplicatedStorage.Shared.modules.AreaOfEffectShape)

local ORIGIN = Vector3.new(0, 0, 0)

return function()
	describe("AreaOfEffectShape", function()
		describe("Circle", function()
			it("should include points within the radius and exclude points beyond it", function()
				expect(AreaOfEffectShape.isWithin("Circle", ORIGIN, Vector3.new(0, 0, -1), Vector3.new(5, 0, 0), 10)).to.equal(true)
				expect(AreaOfEffectShape.isWithin("Circle", ORIGIN, Vector3.new(0, 0, -1), Vector3.new(15, 0, 0), 10)).to.equal(false)
			end)

			it("should include the exact boundary", function()
				expect(AreaOfEffectShape.isWithin("Circle", ORIGIN, Vector3.new(0, 0, -1), Vector3.new(10, 0, 0), 10)).to.equal(true)
			end)

			it("should be direction-independent (a full circle around the origin)", function()
				expect(AreaOfEffectShape.isWithin("Circle", ORIGIN, Vector3.new(0, 0, -1), Vector3.new(0, 0, 5), 10)).to.equal(true) -- "behind" the forward vector
			end)
		end)

		describe("Cone", function()
			local forward = Vector3.new(0, 0, -1)

			it("should include a target directly ahead, within range", function()
				expect(AreaOfEffectShape.isWithin("Cone", ORIGIN, forward, Vector3.new(0, 0, -5), 10, 90)).to.equal(true)
			end)

			it("should exclude a target directly behind, even within range", function()
				expect(AreaOfEffectShape.isWithin("Cone", ORIGIN, forward, Vector3.new(0, 0, 5), 10, 90)).to.equal(false)
			end)

			it("should exclude a target ahead but beyond the radius", function()
				expect(AreaOfEffectShape.isWithin("Cone", ORIGIN, forward, Vector3.new(0, 0, -20), 10, 90)).to.equal(false)
			end)

			it("should exclude a target within range but outside the cone angle", function()
				-- 90 degrees off-axis (directly to the side) is well outside a 90-degree-wide cone.
				expect(AreaOfEffectShape.isWithin("Cone", ORIGIN, forward, Vector3.new(5, 0, 0), 10, 90)).to.equal(false)
			end)

			it("should fall back to a sane default cone angle when omitted", function()
				expect(AreaOfEffectShape.isWithin("Cone", ORIGIN, forward, Vector3.new(0, 0, -5), 10)).to.equal(true)
			end)
		end)

		describe("Line", function()
			local forward = Vector3.new(1, 0, 0)

			it("should include a target on the line, within its length", function()
				expect(AreaOfEffectShape.isWithin("Line", ORIGIN, forward, Vector3.new(5, 0, 0), 10, nil, 2)).to.equal(true)
			end)

			it("should include a target near the line, within its width", function()
				expect(AreaOfEffectShape.isWithin("Line", ORIGIN, forward, Vector3.new(5, 1, 0), 10, nil, 2)).to.equal(true)
			end)

			it("should exclude a target too far from the line perpendicular to it", function()
				expect(AreaOfEffectShape.isWithin("Line", ORIGIN, forward, Vector3.new(5, 5, 0), 10, nil, 2)).to.equal(false)
			end)

			it("should exclude a target beyond the line's length", function()
				expect(AreaOfEffectShape.isWithin("Line", ORIGIN, forward, Vector3.new(15, 0, 0), 10, nil, 2)).to.equal(false)
			end)

			it("should exclude a target behind the line's start", function()
				expect(AreaOfEffectShape.isWithin("Line", ORIGIN, forward, Vector3.new(-5, 0, 0), 10, nil, 2)).to.equal(false)
			end)
		end)
	end)
end
