--!strict
-- T-061/T-064 (GDD §4.1, §4.3). Tag-driven (`ArenaGate` + `ArenaSpawnPoint`,
-- see STUDIO_TASKS.md S-002) arena sealing and wave sequencing. Applies
-- WaveScaler's (T-064) scaling formula using the number of players who
-- entered before the gate sealed as the party-size input — the natural
-- stand-in until the Party system (T-120/T-123, Phase 10) exists to supply
-- real party data through the same input shape.
--
-- Loot chest hookup: `ArenaCleared` fires (arenaId, centerPosition) on full
-- clear; T-102 (Chest system, Phase 8, not built yet) is what actually spawns
-- a chest. This service only detects and reports the clear.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local WaveScaler = require(ReplicatedStorage.Shared.modules.WaveScaler)

local ARENA_GATE_TAG = "ArenaGate"
local ARENA_SPAWN_POINT_TAG = "ArenaSpawnPoint"
local ENTRY_GRACE_PERIOD = 3 -- seconds; other players can still enter before the gate seals behind the first
local WAVE_SPAWN_DELAY = 2 -- seconds "beat" between a wave clearing and the next spawning (§4.1)

local ArenaGateController = Knit.CreateService({
	Name = "ArenaGateController",
	Client = {
		GateSealed = Knit.CreateSignal(), -- () — T-131 (Phase 11): HUD expands exactly on this, not a fixed timer
		GateUnsealed = Knit.CreateSignal(), -- ()
	},
})

ArenaGateController.ArenaCleared = Signal.new() -- (arenaId: string, centerPosition: Vector3)

type SpawnDefinition = { role: string, cframe: CFrame }

type ArenaState = {
	arenaId: string,
	gates: { BasePart },
	wavesByIndex: { [number]: { SpawnDefinition } },
	maxWaveIndex: number,
	currentWaveIndex: number,
	aliveInWave: number,
	isSealed: boolean,
	playersInside: { [Player]: boolean },
	sealTimerThread: thread?,
}

local arenas: { [string]: ArenaState } = {}
local enemyArenaId: { [Model]: string } = {}

--// Registration \\--

local function getOrCreateArena(arenaId: string): ArenaState
	local arena = arenas[arenaId]
	if not arena then
		arena = {
			arenaId = arenaId,
			gates = {},
			wavesByIndex = {},
			maxWaveIndex = 0,
			currentWaveIndex = 0,
			aliveInWave = 0,
			isSealed = false,
			playersInside = {},
			sealTimerThread = nil :: thread?,
		}
		arenas[arenaId] = arena
	end
	return arena
end

local function computeArenaCenter(arena: ArenaState): Vector3
	local total = Vector3.new()
	local count = 0
	for _, spawns in arena.wavesByIndex do
		for _, spawn in spawns do
			total += spawn.cframe.Position
			count += 1
		end
	end
	if count == 0 then
		return Vector3.new()
	end
	return total / count
end

--// Sealing / unsealing (physically collision-blocking, not a soft warning) \\--

-- T-123: prefers PartyService's (T-120) live party size — which shrinks
-- immediately if a member disconnects mid-run — over the raw playersInside
-- count, since that set is never pruned on disconnect (see its own comment
-- below). Falls back to counting still-connected entrants for scenarios
-- with no tracked party at all (e.g. a bare test arena).
local function computePartySize(arena: ArenaState): number
	local representative = next(arena.playersInside)
	if not representative then
		return 0
	end

	local PartyService = Knit.GetService("PartyService")
	local partySize = PartyService:GetPartySize(representative)
	if partySize > 0 then
		return partySize
	end

	local count = 0
	for player in arena.playersInside do
		if player.Parent then
			count += 1
		end
	end
	return count
end

local function spawnWave(arena: ArenaState, waveIndex: number)
	local spawns = arena.wavesByIndex[waveIndex]
	if not spawns or #spawns == 0 then
		return
	end

	local partySize = computePartySize(arena)

	local EnemyController = Knit.GetService("EnemyController")
	local baseCount = #spawns
	local scaledCount = WaveScaler.scaleEnemyCount(baseCount, partySize)
	local healthMultiplier = WaveScaler.healthMultiplier(partySize)

	arena.aliveInWave = 0
	for i = 1, scaledCount do
		local spawnDefinition = spawns[((i - 1) % baseCount) + 1] -- cycle through base points if scaled above the authored count
		local model = EnemyController:Spawn(spawnDefinition.role, spawnDefinition.cframe, arena.arenaId)
		if model then
			arena.aliveInWave += 1
			enemyArenaId[model] = arena.arenaId

			if healthMultiplier ~= 1 then
				local humanoid = model:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.MaxHealth *= healthMultiplier
					humanoid.Health = humanoid.MaxHealth
				end
			end
		end
	end
end

local function sealArena(arena: ArenaState)
	if arena.isSealed then
		return
	end
	arena.isSealed = true
	for _, gate in arena.gates do
		gate.CanCollide = true
		gate.Transparency = 0
	end
	for player in arena.playersInside do
		ArenaGateController.Client.GateSealed:Fire(player)
	end

	arena.currentWaveIndex = 1
	spawnWave(arena, 1)
end

local function unsealArena(arena: ArenaState)
	arena.isSealed = false
	for _, gate in arena.gates do
		gate.CanCollide = false
		gate.Transparency = 0.6
	end
	for player in arena.playersInside do
		ArenaGateController.Client.GateUnsealed:Fire(player)
	end
end

local function onGateTouched(arena: ArenaState, toucher: BasePart)
	if arena.isSealed then
		return
	end
	local character = toucher.Parent
	local player = character and Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end

	arena.playersInside[player] = true

	if not arena.sealTimerThread then
		arena.sealTimerThread = task.delay(ENTRY_GRACE_PERIOD, function()
			arena.sealTimerThread = nil
			sealArena(arena)
		end)
	end
end

--// Wave-clear tracking \\--

local function onEnemyDefeated(target: Model, _player: Player?)
	local arenaId = enemyArenaId[target]
	if not arenaId then
		return
	end
	enemyArenaId[target] = nil

	local arena = arenas[arenaId]
	if not arena then
		return
	end
	arena.aliveInWave -= 1
	if arena.aliveInWave > 0 then
		return -- §4.1: multi-wave arenas never advance before the current wave is fully cleared
	end

	if arena.currentWaveIndex < arena.maxWaveIndex then
		task.delay(WAVE_SPAWN_DELAY, function()
			if arenas[arenaId] ~= arena then
				return -- torn down since
			end
			arena.currentWaveIndex += 1
			spawnWave(arena, arena.currentWaveIndex)
		end)
	else
		unsealArena(arena)
		ArenaGateController.ArenaCleared:Fire(arenaId, computeArenaCenter(arena))
	end
end

--// Tag registration \\--

local function registerGate(instance: Instance)
	if not instance:IsA("BasePart") then
		return
	end
	local arenaId = instance:GetAttribute("ArenaId")
	if type(arenaId) ~= "string" then
		return
	end

	local arena = getOrCreateArena(arenaId)
	table.insert(arena.gates, instance)
	instance.CanCollide = false
	instance.Transparency = 0.6

	instance.Touched:Connect(function(toucher)
		onGateTouched(arena, toucher)
	end)
end

local function registerSpawnPoint(instance: Instance)
	local arenaId = instance:GetAttribute("ArenaId")
	local waveIndex = instance:GetAttribute("WaveIndex")
	local role = instance:GetAttribute("Role")
	if type(arenaId) ~= "string" or type(waveIndex) ~= "number" or type(role) ~= "string" then
		warn(`[ArenaGateController] ArenaSpawnPoint "{instance:GetFullName()}" is missing a required attribute (ArenaId/WaveIndex/Role)`)
		return
	end
	-- Attachment.CFrame is parent-relative, not world space — WorldCFrame is
	-- required there, while a BasePart's .CFrame is already world space.
	local worldCFrame: CFrame
	if instance:IsA("BasePart") then
		worldCFrame = instance.CFrame
	elseif instance:IsA("Attachment") then
		worldCFrame = instance.WorldCFrame
	else
		return
	end

	local arena = getOrCreateArena(arenaId)
	if not arena.wavesByIndex[waveIndex] then
		arena.wavesByIndex[waveIndex] = {}
	end
	table.insert(arena.wavesByIndex[waveIndex], {
		role = role,
		cframe = worldCFrame,
	})
	arena.maxWaveIndex = math.max(arena.maxWaveIndex, waveIndex)
end

-- Server-internal: true once `player` has touched at least one arena gate in
-- this server instance, and stays true afterward (an arena's `playersInside`
-- set is never cleared, including after it unseals) — used by WeaponService
-- (T-070) as the "duration of a battlefield run" signal for the loadout
-- lock, since the Party/Teleport system (T-120/T-121, Phase 10) that would
-- normally define battlefield-instance context doesn't exist yet.
function ArenaGateController:HasPlayerEnteredAnyArena(player: Player): boolean
	for _, arena in arenas do
		if arena.playersInside[player] then
			return true
		end
	end
	return false
end

-- Server-internal: the currently-sealed arena `player` is inside, if any —
-- T-124's ReviveService uses this to find which arena needs its wave
-- restarted on a whole-party-down.
function ArenaGateController:GetArenaIdForPlayer(player: Player): string?
	for arenaId, arena in arenas do
		if arena.isSealed and arena.playersInside[player] then
			return arenaId
		end
	end
	return nil
end

-- Server-internal: despawns every enemy currently alive in `arenaId`'s wave
-- and respawns the same wave index fresh — T-124's "whole-party-down
-- restarts the current wave only, not the chapter" (§12.3).
function ArenaGateController:RestartCurrentWave(arenaId: string)
	local arena = arenas[arenaId]
	if not arena or not arena.isSealed then
		return
	end

	local EnemyController = Knit.GetService("EnemyController")
	for enemy, mappedArenaId in enemyArenaId do
		if mappedArenaId == arenaId then
			enemyArenaId[enemy] = nil
			EnemyController:Despawn(enemy)
		end
	end

	spawnWave(arena, arena.currentWaveIndex)
end

function ArenaGateController:KnitInit()
	for _, instance in CollectionService:GetTagged(ARENA_SPAWN_POINT_TAG) do
		registerSpawnPoint(instance)
	end
	for _, instance in CollectionService:GetTagged(ARENA_GATE_TAG) do
		registerGate(instance)
	end
	CollectionService:GetInstanceAddedSignal(ARENA_SPAWN_POINT_TAG):Connect(registerSpawnPoint)
	CollectionService:GetInstanceAddedSignal(ARENA_GATE_TAG):Connect(registerGate)
end

function ArenaGateController:KnitStart()
	local CombatService = Knit.GetService("CombatService")
	CombatService.EnemyDefeated:Connect(onEnemyDefeated)
end

return ArenaGateController
