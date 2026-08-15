-- T-162 (GDD §17.3). Pure exponential backoff delay calculator. Takes
-- `attemptNumber`/`baseDelaySeconds`/`maxDelaySeconds` as explicit
-- arguments rather than reading any config or timing state itself, so it
-- stays testable without touching DataStoreService or waiting in real time.

local DataStoreRetry = {}

function DataStoreRetry.computeBackoffDelay(attemptNumber: number, baseDelaySeconds: number, maxDelaySeconds: number): number
	local delay = baseDelaySeconds * (2 ^ (attemptNumber - 1))
	return math.min(delay, maxDelaySeconds)
end

return DataStoreRetry
