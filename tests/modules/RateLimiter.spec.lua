local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RateLimiter = require(ReplicatedStorage.Shared.modules.RateLimiter)

return function()
	describe("RateLimiter", function()
		it("should allow a fresh bucket to burst up to maxTokens calls immediately", function()
			local bucket = RateLimiter.newBucket(3)
			local now = 100

			local allowed1, bucket1 = RateLimiter.tryConsume(bucket, now, 3, 1)
			local allowed2, bucket2 = RateLimiter.tryConsume(bucket1, now, 3, 1)
			local allowed3, bucket3 = RateLimiter.tryConsume(bucket2, now, 3, 1)

			expect(allowed1).to.equal(true)
			expect(allowed2).to.equal(true)
			expect(allowed3).to.equal(true)
			expect(bucket3.tokens).to.equal(0)
		end)

		it("should drop excess calls once the bucket is exhausted", function()
			local bucket = RateLimiter.newBucket(1)
			local now = 100

			local allowed1, bucket1 = RateLimiter.tryConsume(bucket, now, 1, 1)
			local allowed2 = RateLimiter.tryConsume(bucket1, now, 1, 1)

			expect(allowed1).to.equal(true)
			expect(allowed2).to.equal(false)
		end)

		it("should refill tokens over elapsed time, allowing a later call to succeed again", function()
			local bucket = RateLimiter.newBucket(1)
			local _, exhausted = RateLimiter.tryConsume(bucket, 100, 1, 1)

			local deniedTooSoon = RateLimiter.tryConsume(exhausted, 100.5, 1, 1)
			local allowedAfterRefill = RateLimiter.tryConsume(exhausted, 101, 1, 1)

			expect(deniedTooSoon).to.equal(false)
			expect(allowedAfterRefill).to.equal(true)
		end)

		it("should never refill above maxTokens even after a long idle gap", function()
			local bucket = RateLimiter.newBucket(2)
			local _, afterLongIdle = RateLimiter.tryConsume(bucket, 999999, 2, 5)

			expect(afterLongIdle.tokens).to.equal(1) -- consumed one of the capped-at-2 tokens
		end)

		it("should not mutate the bucket state passed in", function()
			local bucket = RateLimiter.newBucket(2)
			RateLimiter.tryConsume(bucket, 100, 2, 1)

			expect(bucket.tokens).to.equal(2)
			expect(bucket.lastRefillTime).to.equal(0)
		end)
	end)
end
