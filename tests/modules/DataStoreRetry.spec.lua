local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataStoreRetry = require(ReplicatedStorage.Shared.modules.DataStoreRetry)

return function()
	describe("DataStoreRetry", function()
		it("should return the base delay on the first attempt", function()
			expect(DataStoreRetry.computeBackoffDelay(1, 2, 60)).to.equal(2)
		end)

		it("should double the delay each subsequent attempt", function()
			expect(DataStoreRetry.computeBackoffDelay(2, 2, 60)).to.equal(4)
			expect(DataStoreRetry.computeBackoffDelay(3, 2, 60)).to.equal(8)
			expect(DataStoreRetry.computeBackoffDelay(4, 2, 60)).to.equal(16)
		end)

		it("should cap the delay at maxDelaySeconds", function()
			expect(DataStoreRetry.computeBackoffDelay(10, 2, 60)).to.equal(60)
		end)
	end)
end
