--!strict
-- T-116 (GDD §11.5). Rotates ShopConfig.LimitedRotation.ActiveCount items
-- every DurationHours. Every item that was ever active gets added to
-- `everExpired` before the next rotation is picked (RotationSchedule.
-- pickRotation excludes it), so an item can never come back — the "never
-- returns" record is what makes a config revert/typo unable to accidentally
-- re-offer an expired item, not just a fresh random draw that happens to
-- avoid it.
--
-- Persistence seam: `everExpired`/`activeItemIds` are in-memory this
-- session, same interim pattern as every other player-data-adjacent system
-- here; T-160 (Phase 14) will make the "never returns" record durable across
-- server restarts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)
local RotationSchedule = require(ReplicatedStorage.Shared.modules.RotationSchedule)

local ShopConfig = ConfigService.Shop
local CHECK_INTERVAL = 60 -- seconds between expiry checks; rotation windows are hours-long, so this granularity is plenty

local LimitedRotationService = Knit.CreateService({
	Name = "LimitedRotationService",
	Client = {},
})

-- (activeItemIds: {string})
LimitedRotationService.RotationRefreshed = Signal.new()

local activeItemIds: { string } = {}
local startedAt = 0
local everExpired: { [string]: boolean } = {}

local function rotate()
	for _, id in activeItemIds do
		everExpired[id] = true
	end

	local rotation = ShopConfig.LimitedRotation
	local seed = Random.new():NextInteger(1, 2 ^ 31 - 1)
	activeItemIds = RotationSchedule.pickRotation(rotation.Pool, everExpired, rotation.ActiveCount, seed)
	startedAt = os.time()

	LimitedRotationService.RotationRefreshed:Fire(activeItemIds)
end

function LimitedRotationService.Client:GetActiveRotation(): { string }
	return activeItemIds
end

function LimitedRotationService:KnitStart()
	rotate()
	task.spawn(function()
		while true do
			task.wait(CHECK_INTERVAL)
			if RotationSchedule.isExpired(startedAt, os.time(), ShopConfig.LimitedRotation.DurationHours) then
				rotate()
			end
		end
	end)
end

return LimitedRotationService
