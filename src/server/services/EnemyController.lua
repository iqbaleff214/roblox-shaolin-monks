--!strict
-- T-060/062/063/065 (GDD §4). The base state machine (T-060) is shared by
-- every role; role differences (T-062) come entirely from EnemyConfig.Roles
-- data read at spawn time — there is no per-faction branch anywhere in this
-- file (faction reskins are Studio asset swaps over the same role, §4.6).
--
-- State ownership:
--   Idle/Aggro/Circling  -> driven by the per-frame Heartbeat loop below.
--   Attacking             -> driven by its own telegraph timer (T-063).
--   Staggered              -> driven by CombatService.EnemyStaggered and a
--                            recovery timer (§3.9), or (Boss/Elite) by the
--                            HP-threshold phase-transition hook (T-065)
--                            instead of ever becoming finisher-eligible.
--   Dead                   -> terminal; CombatService.EnemyDefeated despawns.
--
-- Boss/Elite phase transitions are HP-threshold-driven (§4.5), independent
-- of the Poise/Stagger system — BossPhaseTracker is checked on every
-- CombatService.EnemyDamaged tick for Boss/Elite targets.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)
local EnemyStateMachine = require(ReplicatedStorage.Shared.modules.EnemyStateMachine)
local BossPhaseTracker = require(ReplicatedStorage.Shared.modules.BossPhaseTracker)

local EnemyConfig = ConfigService.Enemy
local ENEMY_TAG = "Enemy"
local DEFAULT_POOL_ID = "__unassigned__" -- attacker-token pool for enemies spawned without an arena (e.g. manual test placement)

local EnemyController = Knit.CreateService({
	Name = "EnemyController",
})

-- (target: Model) — T-135 (Phase 11): FeedbackFXService relays this to
-- nearby clients for the boss-phase-transition screen flash (§15.4/§18).
EnemyController.BossPhaseTransition = Signal.new()

type EnemyRecord = {
	role: string,
	roleData: { [string]: any },
	stateMachine: EnemyStateMachine.EnemyStateMachine,
	arenaId: string?,
	target: Player?,
	lastAttackAt: number,
	orbitAngle: number,
	bossPhaseTracker: BossPhaseTracker.BossPhaseTracker?,
	staggerRecoveryThread: thread?,
}

local enemies: { [Model]: EnemyRecord } = {}

--// Spawn / Despawn (T-066 hookup) \\--

function EnemyController:Spawn(role: string, cframe: CFrame, arenaId: string?): Model?
	local roleData = EnemyConfig.Roles[role]
	if not roleData then
		warn(`[EnemyController] Unknown role "{role}"`)
		return nil
	end

	local EnemyPoolService = Knit.GetService("EnemyPoolService")
	local model = EnemyPoolService:Acquire(role, cframe)

	model:SetAttribute("Role", role)
	model:SetAttribute("ArenaId", arenaId)
	model:SetAttribute("IsBlocking", false)
	model:SetAttribute("IsInvulnerable", false)
	CollectionService:AddTag(model, ENEMY_TAG) -- CombatService registers it automatically

	local bossPhaseTracker = nil
	if role == "Boss" or role == "Elite" then
		bossPhaseTracker = BossPhaseTracker.new(roleData.Health, roleData.Phases or 1)
	end

	enemies[model] = {
		role = role,
		roleData = roleData,
		stateMachine = EnemyStateMachine.new("Idle"),
		arenaId = arenaId,
		target = nil :: Player?,
		lastAttackAt = 0,
		orbitAngle = math.random() * math.pi * 2,
		bossPhaseTracker = bossPhaseTracker,
		staggerRecoveryThread = nil :: thread?,
	}

	return model
end

function EnemyController:Despawn(model: Model)
	local record = enemies[model]
	if not record then
		return
	end
	if record.staggerRecoveryThread then
		task.cancel(record.staggerRecoveryThread)
	end

	local AttackerTokenService = Knit.GetService("AttackerTokenService")
	AttackerTokenService:ReleaseToken(record.arenaId or DEFAULT_POOL_ID, model)

	enemies[model] = nil
	CollectionService:RemoveTag(model, ENEMY_TAG) -- CombatService unregisters it automatically

	local EnemyPoolService = Knit.GetService("EnemyPoolService")
	EnemyPoolService:Release(record.role, model)
end

--// CombatService event handlers \\--

local function onEnemyDefeated(target: Model, _player: Player?)
	if enemies[target] then
		EnemyController:Despawn(target)
	end
end

local function onEnemyStaggered(target: Model, _player: Player?)
	local record = enemies[target]
	if not record then
		return
	end
	if record.role == "Boss" or record.role == "Elite" then
		-- Not finisher-eligible; phase transitions are HP-driven (below),
		-- not Poise-driven, for these roles.
		return
	end

	if not record.stateMachine:transition("Staggered") then
		return
	end
	if record.staggerRecoveryThread then
		task.cancel(record.staggerRecoveryThread)
	end
	record.staggerRecoveryThread = task.delay(EnemyConfig.StaggerRecoveryDuration, function()
		record.staggerRecoveryThread = nil
		if enemies[target] ~= record then
			return -- despawned (e.g. finished off) since the timer started
		end
		local CombatService = Knit.GetService("CombatService")
		CombatService:ClearStagger(target)
		record.stateMachine:transition("Circling")
	end)
end

-- §4.5: HP-threshold phase transitions for Boss/Elite, independent of Poise.
local function onEnemyDamaged(target: Model, _amount: number, _player: Player?)
	local record = enemies[target]
	if not record or not record.bossPhaseTracker then
		return
	end
	local humanoid = target:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local tracker = record.bossPhaseTracker
	local now = os.clock()
	local crossed = tracker:checkPhaseTransition(humanoid.Health, now, EnemyConfig.Boss.PhaseTransitionInvulnerableDuration)
	if not crossed then
		return
	end

	target:SetAttribute("IsInvulnerable", true)
	tracker:openCounterWindow(now, EnemyConfig.Boss.CounterWindowDuration)
	tracker:openParryPunishWindow(now, EnemyConfig.Boss.ParryPunishWindowDuration)
	EnemyController.BossPhaseTransition:Fire(target)

	task.delay(EnemyConfig.Boss.PhaseTransitionInvulnerableDuration, function()
		if enemies[target] ~= record then
			return
		end
		tracker:updateInvulnerability(os.clock())
		target:SetAttribute("IsInvulnerable", tracker.isInvulnerable)
	end)
end

--// Attack resolution (T-063 telegraph + damage) \\--

local function resolveAttack(model: Model, record: EnemyRecord, target: Player)
	local character = target.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	if record.role == "Ranged" then
		local GrappleService = Knit.GetService("GrappleService")
		if GrappleService:AbsorbRangedHit(target) then
			return -- human shield absorbed it (§3.4 hookup)
		end
	end

	local CombatService = Knit.GetService("CombatService")
	CombatService:ApplyDamageToPlayer(target, record.roleData.Damage, os.clock(), model)
end

local function beginAttack(model: Model, record: EnemyRecord, target: Player)
	if not record.stateMachine:transition("Attacking") then
		return
	end

	if record.roleData.Blocks then
		model:SetAttribute("IsBlocking", false) -- opens up while swinging (§4.2)
	end

	-- Windup flash placeholder (§4.4, §18 "telegraph flash" nuance note) —
	-- no real animation/VFX asset exists yet (S-042); a Highlight pulse is a
	-- clear, functional stand-in that still gives players a fair read.
	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.fromRGB(255, 220, 60)
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 0
	highlight.Parent = model

	task.delay(EnemyConfig.AttackTelegraph, function()
		highlight:Destroy()
		if enemies[model] ~= record or not record.stateMachine:is("Attacking") then
			return -- despawned or staggered mid-windup; the hit doesn't land
		end

		resolveAttack(model, record, target)

		record.lastAttackAt = os.clock()
		local AttackerTokenService = Knit.GetService("AttackerTokenService")
		AttackerTokenService:ReleaseToken(record.arenaId or DEFAULT_POOL_ID, model)
		record.stateMachine:transition("Circling")
	end)
end

--// Circling movement (T-062 — role-flavored via EnemyConfig data) \\--

local function findNearestPlayer(position: Vector3, maxDistance: number): Player?
	local nearest: Player? = nil
	local nearestDistance = maxDistance
	for _, plr in Players:GetPlayers() do
		local character = plr.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			local distance = (root.Position - position).Magnitude
			if distance <= nearestDistance then
				nearest = plr
				nearestDistance = distance
			end
		end
	end
	return nearest
end

local function updateCircling(record: EnemyRecord, humanoid: Humanoid, dt: number)
	local target = record.target
	local targetRoot = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not targetRoot then
		return
	end

	-- Ranged (§4.2 "kites at range") orbits at its attack range instead of
	-- the default melee circling distance, so it never has to close in.
	local radius = if record.role == "Ranged" then record.roleData.AttackRange * 0.8 else EnemyConfig.CirclingRadius
	local speed = EnemyConfig.CirclingSpeed * (record.roleData.MoveSpeedMult or 1) -- Assassin (§4.2)
	humanoid.WalkSpeed = speed

	record.orbitAngle += (speed / math.max(radius, 1)) * dt
	local offset = Vector3.new(math.cos(record.orbitAngle), 0, math.sin(record.orbitAngle)) * radius
	humanoid:MoveTo(targetRoot.Position + offset)
end

--// Main AI loop \\--

local function updateEnemy(model: Model, record: EnemyRecord, now: number, dt: number)
	if record.stateMachine:is("Dead") then
		return
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local rootPart = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not rootPart or humanoid.Health <= 0 then
		return
	end

	if record.stateMachine:is("Idle") then
		local nearestPlayer = findNearestPlayer(rootPart.Position, EnemyConfig.AggroRadius)
		if nearestPlayer then
			record.target = nearestPlayer
			record.stateMachine:transition("Aggro")
		end
		return
	end

	if record.stateMachine:is("Aggro") then
		record.stateMachine:transition("Circling")
		return
	end

	if record.stateMachine:is("Circling") then
		local target = record.target
		local targetHumanoid = target and target.Character and target.Character:FindFirstChildOfClass("Humanoid")
		if not target or not targetHumanoid or targetHumanoid.Health <= 0 then
			record.target = nil
			record.stateMachine:transition("Idle")
			return
		end

		updateCircling(record, humanoid, dt)
		if record.roleData.Blocks then
			model:SetAttribute("IsBlocking", true) -- §4.2: Soldier blocks while not mid-swing
		end

		if now - record.lastAttackAt >= EnemyConfig.AttackCooldown then
			local AttackerTokenService = Knit.GetService("AttackerTokenService")
			if AttackerTokenService:RequestToken(record.arenaId or DEFAULT_POOL_ID, model) then
				beginAttack(model, record, target)
			end
		end
		return
	end

	-- Attacking and Staggered are driven by their own timers/signal
	-- handlers above, not polled here.
end

--// Lifecycle \\--

function EnemyController:KnitInit()
	Players.PlayerRemoving:Connect(function(player)
		for _, record in enemies do
			if record.target == player then
				record.target = nil
			end
		end
	end)
end

function EnemyController:KnitStart()
	local CombatService = Knit.GetService("CombatService")
	CombatService.EnemyDefeated:Connect(onEnemyDefeated)
	CombatService.EnemyStaggered:Connect(onEnemyStaggered)
	CombatService.EnemyDamaged:Connect(onEnemyDamaged)

	RunService.Heartbeat:Connect(function(dt: number)
		local now = os.clock()
		for model, record in enemies do
			updateEnemy(model, record, now, dt)
		end
	end)
end

return EnemyController
