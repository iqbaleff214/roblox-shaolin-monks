--!strict
-- T-171 (GDD §17.2). Pure token-bucket rate limiter: a bucket holds up to
-- `maxTokens` tokens, refills continuously at `refillPerSecond`, and each
-- call consumes exactly one token. Bursts up to `maxTokens` succeed
-- immediately (so a legitimate fast combo never gets clipped); sustained
-- spam beyond `refillPerSecond` gets its excess calls dropped.
--
-- Deliberately stateless/pure — `tryConsume` takes the previous bucket state
-- and `now`, returns whether this call is allowed plus the next state, and
-- never mutates its input. Callers (RateLimitService) own the actual
-- per-player storage.

local RateLimiter = {}

export type BucketState = {
	tokens: number,
	lastRefillTime: number,
}

function RateLimiter.newBucket(maxTokens: number): BucketState
	return { tokens = maxTokens, lastRefillTime = 0 }
end

function RateLimiter.tryConsume(bucket: BucketState, now: number, maxTokens: number, refillPerSecond: number): (boolean, BucketState)
	local elapsed = math.max(now - bucket.lastRefillTime, 0)
	local refilled = math.min(maxTokens, bucket.tokens + elapsed * refillPerSecond)

	if refilled >= 1 then
		return true, { tokens = refilled - 1, lastRefillTime = now }
	end
	return false, { tokens = refilled, lastRefillTime = now }
end

return RateLimiter
