--!strict
-- T-193 (GDD §17.6/§17.1). Server-side combat load/stress harness for a
-- single arena at sustained combat load, over the duration of a full arena
-- clear.
--
-- Scope note: a literal 4-concurrent-Roblox-client desync/rubber-banding
-- test requires Roblox Studio's own multi-player Test tab (Players: 4,
-- Start) — real distinct `Player` instances can only be created by the
-- engine when a client connects, never by a script, so no single command-bar
-- script can fully stand in for that manual step. What THIS harness
-- automates is the server-side half of the DoD that genuinely can be:
-- sustained attack load against the concurrent-attacker-cap system (T-050)
-- and a server error-log watch for the run's duration, giving the
-- "documented load-test run... showing zero reconciliation-rejection
-- spikes beyond expected baseline" artifact the Test Case asks for. Run
-- this alongside a real 4-player Studio Test-tab session for full coverage.
--
-- Requires a live Player. Invoke from the Studio command bar:
--   require(game.ServerScriptService.Server.testing.CombatLoadTest).run()

local CollectionService = game:GetService("CollectionService")
local LogService = game:GetService("LogService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)

local CombatLoadTest = {}

local SIM_ORIGIN = Vector3.new(0, 7000, 0) -- distinct altitude from the other testing/ harnesses
local ENEMY_COUNT = 8 -- matches T-050's own "aggro 8 enemies" cap-stress scenario
local ATTACK_INTERVAL_SECONDS = 0.15
local SAMPLE_INTERVAL_SECONDS = 0.5
local DEFAULT_DURATION_SECONDS = 15 -- approximates a full arena-clear window (§7 session-length target scaled down)

local function spawnLoadEnemies(arenaId: string): { Model }
	local EnemyController = Knit.GetService("EnemyController")
	local enemies = {}
	for i = 1, ENEMY_COUNT do
		local angle = (i - 1) * (2 * math.pi / ENEMY_COUNT)
		local offset = Vector3.new(math.cos(angle), 0, math.sin(angle)) * 6
		local model = EnemyController:Spawn("Grunt", CFrame.new(SIM_ORIGIN + offset), arenaId)
		if model then
			table.insert(enemies, model)
		end
	end
	return enemies
end

local function countActiveAttackers(arenaId: string, enemies: { Model }): number
	local AttackerTokenService = Knit.GetService("AttackerTokenService")
	local count = 0
	for _, enemy in enemies do
		if enemy.Parent and AttackerTokenService:IsHoldingToken(arenaId, enemy) then
			count += 1
		end
	end
	return count
end

-- Runs a sustained combat load against `ENEMY_COUNT` enemies for
-- `durationSeconds` (default ~a full arena clear), sampling the
-- concurrent-attacker-cap invariant (T-050) and watching for new
-- server-logged errors throughout. Requires a live Player.
function CombatLoadTest.run(durationSeconds: number?): boolean
	local player = Players:GetPlayers()[1]
	if not player or not player.Character then
		warn("[CombatLoadTest] Requires a live Player with a spawned Character (Studio Play/solo-test) — aborting.")
		return false
	end

	local duration = durationSeconds or DEFAULT_DURATION_SECONDS
	local arenaId = "LoadTestArena"
	local cap = ConfigService.Enemy.ConcurrentAttackerCap

	local originalCFrame = player.Character:GetPivot()
	player.Character:PivotTo(CFrame.new(SIM_ORIGIN))

	local errorCount = 0
	local logConnection = LogService.MessageOut:Connect(function(_message: string, messageType: Enum.MessageType)
		if messageType == Enum.MessageType.MessageError then
			errorCount += 1
		end
	end)

	local enemies = spawnLoadEnemies(arenaId)

	local attacksFired = 0
	local maxObservedAttackers = 0
	local capBreaches = 0

	local samplerThread = task.spawn(function()
		while true do
			local active = countActiveAttackers(arenaId, enemies)
			maxObservedAttackers = math.max(maxObservedAttackers, active)
			if active > cap then
				capBreaches += 1
			end
			task.wait(SAMPLE_INTERVAL_SECONDS)
		end
	end)

	local CombatService = Knit.GetService("CombatService")
	local startClock = os.clock()
	local endClock = startClock + duration
	local isHeavy = false
	while os.clock() < endClock do
		CombatService.Client:RequestAttack(player, isHeavy)
		isHeavy = not isHeavy
		attacksFired += 1
		task.wait(ATTACK_INTERVAL_SECONDS)
	end

	task.cancel(samplerThread)
	logConnection:Disconnect()

	local EnemyController = Knit.GetService("EnemyController")
	for _, instance in CollectionService:GetTagged("Enemy") do
		if instance:GetAttribute("ArenaId") == arenaId then
			EnemyController:Despawn(instance)
		end
	end
	if player.Character then
		player.Character:PivotTo(originalCFrame)
	end

	local capHeld = capBreaches == 0
	local noNewErrors = errorCount == 0

	print(`[CombatLoadTest] Duration: {duration}s, attacks fired: {attacksFired}`)
	print(`[CombatLoadTest] Max concurrent attackers observed: {maxObservedAttackers} (cap: {cap}, breaches: {capBreaches})`)
	print(`[CombatLoadTest] Server errors logged during run: {errorCount}`)
	print(`[CombatLoadTest] Overall: {if capHeld and noNewErrors then "PASS" else "FAIL"}`)

	return capHeld and noNewErrors
end

return CombatLoadTest
