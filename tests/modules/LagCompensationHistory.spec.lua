local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LagCompensationHistory = require(ReplicatedStorage.Shared.modules.LagCompensationHistory)

return function()
	describe("LagCompensationHistory", function()
		it("should return nil when nothing has been recorded yet", function()
			local history = LagCompensationHistory.new(1)
			expect(history:rewind(0)).to.equal(nil)
		end)

		it("should rewind to an interpolated position between two recorded snapshots (150ms latency scenario)", function()
			local history = LagCompensationHistory.new(1)
			history:record(Vector3.new(0, 0, 0), 0)
			history:record(Vector3.new(10, 0, 0), 1) -- moved 10 studs over 1s

			-- Attacker's reported timestamp is 150ms in the past relative to "now".
			local rewound = history:rewind(0.15)
			expect(rewound).never.to.equal(nil)
			local position = rewound :: Vector3
			expect(math.abs(position.X - 1.5) < 1e-6).to.equal(true) -- 15% of the way from 0 -> 10
		end)

		it("should clamp to the oldest snapshot when targetTime is before all recorded history", function()
			local history = LagCompensationHistory.new(1)
			history:record(Vector3.new(5, 0, 0), 1)
			history:record(Vector3.new(15, 0, 0), 2)

			local position = history:rewind(0) :: Vector3
			expect(position).to.equal(Vector3.new(5, 0, 0))
		end)

		it("should clamp to the newest snapshot when targetTime is after all recorded history", function()
			local history = LagCompensationHistory.new(1)
			history:record(Vector3.new(5, 0, 0), 1)
			history:record(Vector3.new(15, 0, 0), 2)

			local position = history:rewind(100) :: Vector3
			expect(position).to.equal(Vector3.new(15, 0, 0))
		end)

		it("should trim snapshots older than the buffer duration on every record", function()
			local history = LagCompensationHistory.new(1)
			history:record(Vector3.new(0, 0, 0), 0)
			history:record(Vector3.new(1, 0, 0), 0.5)
			history:record(Vector3.new(2, 0, 0), 2.5) -- more than 1s after the first snapshot

			-- The t=0 snapshot should have been trimmed; rewinding to t=0 now
			-- clamps to the oldest surviving snapshot instead.
			local position = history:rewind(0) :: Vector3
			expect(position).never.to.equal(Vector3.new(0, 0, 0))
		end)
	end)
end
