--!strict
-- T-194 (GDD §17.6). Logs REALIZED damage-per-second per weapon type — as
-- opposed to WeaponConfig.spec.lua's theoretical DPS check (T-011), which
-- only evaluates the combo tree's numbers in isolation. This drives the
-- real production attack path (`CombatService.Client:RequestAttack`)
-- against a stationary high-HP dummy, at a realistic input cadence, and
-- measures actual damage landed over actual elapsed time — catching drift
-- from hit-detection range/arc, combo-window timing, or rate-limiting that
-- the theoretical calculation can't see.
--
-- Requires a live Player (Studio Play/solo-test). Invoke from the Studio
-- command bar:
--   require(game.ServerScriptService.Server.testing.WeaponDPSLogger).run()
--
-- Output is one sorted `WeaponId: N.NN DPS` line per weapon — stable
-- ordering makes it diffable across builds/commits per the DoD.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)

local WeaponDPSLogger = {}

local SIM_ORIGIN = Vector3.new(0, 6000, 0) -- distinct altitude from ArenaClearSimulation/CombatLoadTest, avoids any collision if run back-to-back
local DUMMY_OFFSET = Vector3.new(0, 0, -4) -- within every weapon's minimum Range (5 studs)
local DUMMY_COUNT = 3
local DUMMY_HEALTH = 1e6 -- never dies mid-measurement
local ATTACK_INTERVAL_SECONDS = 0.15 -- realistic input cadence, well under RateLimitService's tuned ceiling
local TEST_DURATION_SECONDS = 10

local function spawnDummies(arenaId: string): { Model }
	local EnemyController = Knit.GetService("EnemyController")
	local dummies = {}
	for i = 1, DUMMY_COUNT do
		local offset = DUMMY_OFFSET + Vector3.new((i - 1) * 3, 0, 0)
		local model = EnemyController:Spawn("Grunt", CFrame.new(SIM_ORIGIN + offset), arenaId)
		if model then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.MaxHealth = DUMMY_HEALTH
				humanoid.Health = DUMMY_HEALTH
			end
			table.insert(dummies, model)
		end
	end
	return dummies
end

local function measureWeaponDps(player: Player, weaponId: string, dummies: { Model }): number
	player:SetAttribute("EquippedWeaponId", weaponId)

	local CombatService = Knit.GetService("CombatService")
	local totalDamage = 0
	local connection = CombatService.EnemyDamaged:Connect(function(target: Model, amount: number, hitPlayer: Player?)
		if hitPlayer == player and table.find(dummies, target) then
			totalDamage += amount
		end
	end)

	local startClock = os.clock()
	local endClock = startClock + TEST_DURATION_SECONDS
	local isHeavy = false
	while os.clock() < endClock do
		CombatService.Client:RequestAttack(player, isHeavy)
		isHeavy = not isHeavy
		task.wait(ATTACK_INTERVAL_SECONDS)
	end
	local elapsedSeconds = os.clock() - startClock
	connection:Disconnect()

	return totalDamage / elapsedSeconds
end

-- Runs the realized-DPS measurement against all 5 weapons on a fixed test
-- wave, returning `{ [weaponId]: realizedDps }` and printing a sorted,
-- diffable report. Requires a live Player in the session.
function WeaponDPSLogger.run(): { [string]: number }?
	local player = Players:GetPlayers()[1]
	if not player or not player.Character then
		warn("[WeaponDPSLogger] Requires a live Player with a spawned Character (Studio Play/solo-test) — aborting.")
		return nil
	end

	local arenaId = "DPSTest"
	local originalCFrame = player.Character:GetPivot()
	local originalWeaponId = player:GetAttribute("EquippedWeaponId")

	player.Character:PivotTo(CFrame.lookAt(SIM_ORIGIN, SIM_ORIGIN + DUMMY_OFFSET))
	local dummies = spawnDummies(arenaId)

	local report: { [string]: number } = {}
	for weaponId in ConfigService.Weapon.Weapons do
		report[weaponId] = measureWeaponDps(player, weaponId, dummies)
	end

	local EnemyController = Knit.GetService("EnemyController")
	for _, instance in CollectionService:GetTagged("Enemy") do
		if instance:GetAttribute("ArenaId") == arenaId then
			EnemyController:Despawn(instance)
		end
	end
	if player.Character then
		player.Character:PivotTo(originalCFrame)
	end
	if type(originalWeaponId) == "string" then
		player:SetAttribute("EquippedWeaponId", originalWeaponId)
	end

	local sortedIds = {}
	for weaponId in report do
		table.insert(sortedIds, weaponId)
	end
	table.sort(sortedIds)

	print("[WeaponDPSLogger] Realized DPS report:")
	for _, weaponId in sortedIds do
		print(string.format("  %s: %.2f DPS", weaponId, report[weaponId]))
	end

	return report
end

return WeaponDPSLogger
