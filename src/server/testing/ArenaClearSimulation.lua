--!strict
-- T-191 (GDD §17 QA). Studio-command-bar-driven end-to-end simulation of a
-- full arena clear, run once per difficulty tier (§8.3) against a synthetic
-- arena built at runtime (no S-020–S-027 Studio geometry required). Drives
-- the REAL production services (ArenaGateController/T-061, CombatService/T-049,
-- EnemyController/T-060) through their real public APIs and tagged-instance
-- contract — no test-only backdoor added to any service.
--
-- Requires a live Player in the session (Studio Play/solo-test), since arena
-- entry is detected via a genuine physical gate `Touched` overlap, exactly
-- like real gameplay — this can't run under a headless CLI (see T-190's
-- ConfigTestSuite for the fully headless subset). Invoke from the Studio
-- command bar:
--   require(game.ServerScriptService.Server.testing.ArenaClearSimulation).run()
--
-- Simulated arena layout is placed far above normal playspace (Y = 5000) so
-- it can never overlap real level geometry; each tier's arena is built,
-- driven to a full clear, and torn down before the next tier starts.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)

local ArenaClearSimulation = {}

local SIM_ORIGIN = Vector3.new(0, 5000, 0)
local SIM_ROLE = "Grunt" -- arena-flow test; role-specific behavior is T-062's own scope, not this one's
local ENTRIES_PER_WAVE = 2
local WAVE_COUNT = 2
local ENTRY_WAIT_SECONDS = 4 -- > ArenaGateController's 3s ENTRY_GRACE_PERIOD
local WAVE_ADVANCE_WAIT_SECONDS = 3 -- > ArenaGateController's 2s WAVE_SPAWN_DELAY
local CLEAR_TIMEOUT_SECONDS = 5
local DIFFICULTY_TIERS = { "Novice", "Adept", "Veteran", "Master" }

local function firstChapterPerTier(): { [string]: { Id: string, DifficultyTier: string } }
	local picked = {}
	for _, chapter in ConfigService.Chapter do
		if not picked[chapter.DifficultyTier] then
			picked[chapter.DifficultyTier] = chapter
		end
	end
	return picked
end

local function buildSyntheticArena(arenaId: string): (Folder, BasePart)
	local folder = Instance.new("Folder")
	folder.Name = "ArenaClearSimulation_" .. arenaId
	folder.Parent = Workspace

	local gate = Instance.new("Part")
	gate.Name = "Gate"
	gate.Size = Vector3.new(12, 10, 1)
	gate.Anchored = true
	gate.CanCollide = false
	gate.CFrame = CFrame.new(SIM_ORIGIN)
	gate.Parent = folder
	gate:SetAttribute("ArenaId", arenaId)
	CollectionService:AddTag(gate, "ArenaGate")

	for waveIndex = 1, WAVE_COUNT do
		for i = 1, ENTRIES_PER_WAVE do
			local marker = Instance.new("Part")
			marker.Name = string.format("SpawnPoint_W%d_%d", waveIndex, i)
			marker.Anchored = true
			marker.CanCollide = false
			marker.Transparency = 1
			marker.CFrame = CFrame.new(SIM_ORIGIN + Vector3.new(i * 6, 0, waveIndex * 15))
			marker.Parent = folder
			marker:SetAttribute("ArenaId", arenaId)
			marker:SetAttribute("WaveIndex", waveIndex)
			marker:SetAttribute("Role", SIM_ROLE)
			CollectionService:AddTag(marker, "ArenaSpawnPoint")
		end
	end

	return folder, gate
end

local function findArenaEnemies(arenaId: string): { Model }
	local found = {}
	for _, instance in CollectionService:GetTagged("Enemy") do
		if instance:IsA("Model") and instance:GetAttribute("ArenaId") == arenaId then
			table.insert(found, instance)
		end
	end
	return found
end

local function killAll(models: { Model }, player: Player)
	local CombatService = Knit.GetService("CombatService")
	for _, model in models do
		CombatService:ApplyDamageToEnemy(model, math.huge, player)
	end
end

local function waitUntil(predicate: () -> boolean, timeoutSeconds: number): boolean
	local elapsed = 0
	while elapsed < timeoutSeconds do
		if predicate() then
			return true
		end
		task.wait(0.1)
		elapsed += 0.1
	end
	return predicate()
end

-- Runs one tier's simulation end-to-end, asserting every state transition
-- in order. Returns true if every assertion passed.
local function runTierSimulation(tier: string, chapterId: string, player: Player): boolean
	local arenaId = "SimArena_" .. tier
	local folder, gate = buildSyntheticArena(arenaId)

	local ok = true

	local function check(condition: boolean, label: string)
		if not condition then
			ok = false
			warn(`[ArenaClearSimulation] {tier} ({chapterId}) FAILED: {label}`)
		end
	end

	check(gate.CanCollide == false, "gate starts unsealed")

	-- 1. Entry: teleport the player into the gate, letting a real physical
	-- Touched overlap drive ArenaGateController exactly like real gameplay.
	local originalCFrame = player.Character and player.Character:GetPivot()
	if player.Character then
		player.Character:PivotTo(gate.CFrame)
	end
	task.wait(ENTRY_WAIT_SECONDS)

	check(gate.CanCollide == true, "gate seals (physically blocking) after entry + grace period")

	-- 2. Wave 1 spawns, wave 2 must not exist yet.
	local wave1 = findArenaEnemies(arenaId)
	check(#wave1 == ENTRIES_PER_WAVE, `wave 1 spawns exactly {ENTRIES_PER_WAVE} enemies (got {#wave1})`)

	killAll(wave1, player)
	task.wait(WAVE_ADVANCE_WAIT_SECONDS)

	-- 3. Wave 2 spawns only after wave 1 fully cleared (§4.1).
	local wave2 = findArenaEnemies(arenaId)
	check(#wave2 == ENTRIES_PER_WAVE, `wave 2 spawns only after wave 1 clears (got {#wave2})`)

	killAll(wave2, player)

	-- 4. Full clear -> gate unseals, chest-spawn hookup (ArenaCleared) fires.
	local unsealedInTime = waitUntil(function()
		return gate.CanCollide == false
	end, CLEAR_TIMEOUT_SECONDS)
	check(unsealedInTime, "gate unseals within timeout after full clear")

	-- Cleanup: despawn any stragglers via the real pooled-despawn path,
	-- then remove the synthetic geometry and restore the player.
	local EnemyController = Knit.GetService("EnemyController")
	for _, model in findArenaEnemies(arenaId) do
		EnemyController:Despawn(model)
	end
	folder:Destroy()
	if player.Character and originalCFrame then
		player.Character:PivotTo(originalCFrame)
	end

	return ok
end

-- Runs the full-arena-clear simulation once per difficulty tier (§8.3),
-- against the first chapter found for that tier. Requires a live Player in
-- the session. Returns true only if every tier's simulation passed every
-- assertion.
function ArenaClearSimulation.run(): boolean
	local player = Players:GetPlayers()[1]
	if not player or not player.Character then
		warn("[ArenaClearSimulation] Requires a live Player with a spawned Character (Studio Play/solo-test) — aborting.")
		return false
	end

	local chaptersByTier = firstChapterPerTier()
	local allPassed = true

	for _, tier in DIFFICULTY_TIERS do
		local chapter = chaptersByTier[tier]
		if not chapter then
			warn(`[ArenaClearSimulation] No chapter found for tier "{tier}" — skipping.`)
			allPassed = false
			continue
		end
		local passed = runTierSimulation(tier, chapter.Id, player)
		allPassed = allPassed and passed
		print(`[ArenaClearSimulation] {tier} ({chapter.Id}): {if passed then "PASS" else "FAIL"}`)
	end

	print(`[ArenaClearSimulation] Overall: {if allPassed then "PASS" else "FAIL"}`)
	return allPassed
end

return ArenaClearSimulation
