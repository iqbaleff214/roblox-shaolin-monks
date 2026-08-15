--!strict
-- T-042/043/046/047/049 (GDD §3.2-3.9, §17.1-§17.2). The single authoritative
-- combat service: no other server script writes damage, Chi, Poise, or
-- combat-sourced currency/XP (T-049's DoD). Composes the pure modules from
-- Phase 3 with live Player/Enemy state.
--
-- Forward-dependency seams (documented once here, referenced throughout):
--   * Equipped weapon: read from `player:GetAttribute("EquippedWeaponId")`,
--     defaulting to "TwinBlades" until the Weapon Loadout system (T-070,
--     Phase 5) exists and starts setting it.
--   * Enemy targets: any `Enemy`-tagged Model with a Humanoid and a `Role`
--     attribute (see STUDIO_TASKS.md S-002) — works with a bare test dummy
--     today and with real EnemyController-driven enemies (T-060, Phase 4)
--     later without this file changing.
--   * Rewards: this service never grants Coins/XP directly (those systems,
--     T-090/T-110, don't exist yet). It fires server-internal Signals
--     (EnemyDamaged/EnemyDefeated/FinishingMoveLanded/UltimateActivated)
--     that Phase 7/9 services subscribe to instead — the correct dependency
--     direction regardless of build order (economy depends on combat, not
--     the other way around).
--   * Ultimate execution: `UltimateActivated` carries the weapon's Ultimate
--     config; T-072 (Phase 5) is what actually applies its damage/AoE. This
--     service only owns the Chi gate (T-047's exact scope).
--
-- Damage model: every Light/Heavy attack always deals at least the flat
-- CombatConfig base damage — combos are a bonus layer, not a gate. If the
-- player's ComboTreeWalker successfully advances (input matched the next
-- tree step, within the combo window and their unlocked depth), that step's
-- DamageMultiplier replaces the flat base for this hit. An unlocked-depth or
-- mistimed input never blocks the basic attack itself (§3.2's Light/Heavy
-- Attack are always-available moves; the combo TREE is what's gated).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)
local ComboTreeWalker = require(ReplicatedStorage.Shared.modules.ComboTreeWalker)
local ChiMeterState = require(ReplicatedStorage.Shared.modules.ChiMeterState)
local StyleScoreTracker = require(ReplicatedStorage.Shared.modules.StyleScoreTracker)
local PoiseStateMachine = require(ReplicatedStorage.Shared.modules.PoiseStateMachine)
local LagCompensationHistory = require(ReplicatedStorage.Shared.modules.LagCompensationHistory)
local ParryTiming = require(ReplicatedStorage.Shared.modules.ParryTiming)

local CombatConfig = ConfigService.Combat
local WeaponConfig = ConfigService.Weapon
local EnemyConfig = ConfigService.Enemy
local ShopConfig = ConfigService.Shop

local ENEMY_TAG = "Enemy"
local DEFAULT_WEAPON_ID = "TwinBlades"
local FINISHING_MOVE_MAX_DISTANCE = 10 -- studs; prevents a finish-from-across-the-map exploit
local MAX_REWIND_SECONDS = 1 -- clamp on GetNetworkPing-derived rewind, matches LagCompensationHistory's buffer

local CombatService = Knit.CreateService({
	Name = "CombatService",
	Client = {
		Chi = Knit.CreateProperty(0), -- T-131 (Phase 11): live per-player Chi meter for the Combat HUD
	},
})

-- Server-internal signals. Deliberately not exposed via Client — future
-- Phase 4/5/7/9 systems `require` this service and connect directly.
CombatService.EnemyDamaged = Signal.new() -- (target: Model, amount: number, player: Player)
CombatService.EnemyDefeated = Signal.new() -- (target: Model, player: Player)
CombatService.FinishingMoveLanded = Signal.new() -- (target: Model, player: Player)
CombatService.UltimateActivated = Signal.new() -- (player: Player, weaponId: string, ultimateData: {any})
CombatService.PlayerDamaged = Signal.new() -- (player: Player, amount: number, source: any)
CombatService.HeavyHitOnBlockingEnemy = Signal.new() -- (target: Model, player: Player) — §3.5 disarm precondition, WeaponPickupService (T-045) rolls the chance
CombatService.EnemyStaggered = Signal.new() -- (target: Model, player: Player?) — fires exactly on the hit that crosses the Stagger threshold; EnemyController (T-060/T-065) decides finisher-eligible vs. phase-transition
CombatService.PlayerFallen = Signal.new() -- (player: Player, source: any) — T-124: fired instead of letting a lethal hit kill the player; ReviveService owns them from here
CombatService.HeavyAttackLanded = Signal.new() -- (target: Model, player: Player) — T-135 (Phase 11): FeedbackFXService relays this for the hit-stop freeze-frame

--// Player combat state \\--

type PlayerState = {
	comboWalker: ComboTreeWalker.ComboTreeWalker,
	weaponId: string,
	chi: ChiMeterState.ChiMeterState,
	styleScore: StyleScoreTracker.StyleScoreTracker,
	isBlocking: boolean,
	blockStartedAt: number?,
}

local playerStates: { [Player]: PlayerState } = {}

local function getEquippedWeaponId(player: Player): string
	local attribute = player:GetAttribute("EquippedWeaponId")
	if type(attribute) == "string" and WeaponConfig.Weapons[attribute] then
		return attribute
	end
	return DEFAULT_WEAPON_ID
end

-- T-111: full combo-tree depth once the matching Combo Scroll is owned
-- (InventoryService, "ComboScroll" category); otherwise ComboTreeWalker's
-- own default (step 1 only — Light/Heavy attacks remain always-available at
-- flat damage regardless, per this file's header note).
local function getUnlockedComboDepth(player: Player, weaponId: string): number
	local InventoryService = Knit.GetService("InventoryService")
	for _, scroll in ShopConfig.ComboScrolls do
		if scroll.WeaponId == weaponId and InventoryService:IsOwned(player, "ComboScroll", scroll.Id) then
			return #WeaponConfig.Weapons[weaponId].ComboTree
		end
	end
	return ComboTreeWalker.DEFAULT_UNLOCKED_DEPTH
end

local function getPlayerState(player: Player): PlayerState
	local state = playerStates[player]
	if state then
		return state
	end
	local weaponId = getEquippedWeaponId(player)
	-- T-091: SkillTreeService's ChiGrowth node sets this attribute; absent
	-- (or non-numeric) means no rank purchased yet, i.e. the original,
	-- unmodified Chi cap.
	local chiBonus = player:GetAttribute("ChiBonus")
	local chiMax = CombatConfig.ChiMeter.Max + (if type(chiBonus) == "number" then chiBonus else 0)
	state = {
		comboWalker = ComboTreeWalker.new(
			WeaponConfig.Weapons[weaponId].ComboTree,
			CombatConfig.Attacks.ComboWindow,
			getUnlockedComboDepth(player, weaponId)
		),
		weaponId = weaponId,
		chi = ChiMeterState.new(chiMax),
		styleScore = StyleScoreTracker.new(),
		isBlocking = false,
		blockStartedAt = nil :: number?,
	}
	playerStates[player] = state
	CombatService.Client.Chi:SetFor(player, state.chi.value)
	return state
end

-- T-131: keeps the HUD's replicated Chi property in sync with the
-- authoritative server value after every mutation.
local function syncChi(player: Player, state: PlayerState)
	CombatService.Client.Chi:SetFor(player, state.chi.value)
end

--// Enemy target state \\--

type EnemyState = {
	poise: PoiseStateMachine.PoiseStateMachine,
	history: LagCompensationHistory.LagCompensationHistory,
}

local enemyStates: { [Model]: EnemyState } = {}

local function getPoiseThreshold(enemy: Model): number
	local role = enemy:GetAttribute("Role")
	local roleData = type(role) == "string" and EnemyConfig.Roles[role]
	if roleData then
		return roleData.Poise
	end
	return CombatConfig.Poise.StaggerThreshold
end

local function configureHumanoidDefaults(enemy: Model, humanoid: Humanoid)
	local role = enemy:GetAttribute("Role")
	local roleData = type(role) == "string" and EnemyConfig.Roles[role]
	if roleData and humanoid.MaxHealth == 100 then
		-- Untouched Roblox default; nothing else has configured this enemy's
		-- health yet, so seed it from EnemyConfig.
		humanoid.MaxHealth = roleData.Health
		humanoid.Health = roleData.Health
	end
end

local function registerEnemy(enemy: Instance)
	if not enemy:IsA("Model") then
		return
	end
	local humanoid = enemy:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	configureHumanoidDefaults(enemy, humanoid)
	enemyStates[enemy] = {
		poise = PoiseStateMachine.new(getPoiseThreshold(enemy), CombatConfig.Poise.PoiseDecayPerSec, os.clock()),
		history = LagCompensationHistory.new(),
	}
end

local function unregisterEnemy(enemy: Instance)
	enemyStates[enemy] = nil
end

--// Hit detection (§17.1 favor-the-attacker lag compensation) \\--

type HitResult = { target: Model, distance: number }

local function findValidTargets(attackerPosition: Vector3, attackerLookVector: Vector3, weapon: { Range: number, Arc: number }, rewindTime: number): { HitResult }
	local halfArcCos = math.cos(math.rad(weapon.Arc / 2))
	local hits: { HitResult } = {}

	for enemy, state in enemyStates do
		local rewoundPosition = state.history:rewind(rewindTime)
		if rewoundPosition then
			local offset = rewoundPosition - attackerPosition
			local distance = offset.Magnitude
			if distance <= weapon.Range and distance > 0 then
				local facingDot = attackerLookVector:Dot(offset.Unit)
				if facingDot >= halfArcCos then
					table.insert(hits, { target = enemy, distance = distance })
				end
			end
		end
	end

	return hits
end

--// Damage application \\--

-- Reusable by GrappleService/WeaponPickupService as well as this service's
-- own attack resolution — the single writer T-049's DoD requires.
function CombatService:ApplyDamageToEnemy(target: Model, amount: number, player: Player?)
	local state = enemyStates[target]
	local humanoid = target:FindFirstChildOfClass("Humanoid")
	if not state or not humanoid or humanoid.Health <= 0 then
		return
	end
	if target:GetAttribute("IsInvulnerable") == true then
		-- §4.5: no damage accepted during a boss/Elite phase-transition
		-- window. EnemyController (T-065) sets this attribute.
		return
	end

	local mitigated = amount
	if target:GetAttribute("IsBlocking") == true then
		mitigated = amount * (1 - CombatConfig.Attacks.BlockDamageReduction)
	end

	humanoid:TakeDamage(mitigated)
	-- Poise damage mirrors dealt damage — GDD doesn't specify a separate
	-- curve, and reusing the damage number avoids introducing an unrelated
	-- balance knob with no design guidance behind it.
	local justStaggered = state.poise:applyHit(mitigated, os.clock())

	CombatService.EnemyDamaged:Fire(target, mitigated, player)

	if player then
		local playerState = getPlayerState(player)
		playerState.chi:gain(CombatConfig.ChiMeter.GainPerHitDealt)
		playerState.styleScore:registerHit(os.clock())
		syncChi(player, playerState)
	end

	if humanoid.Health <= 0 then
		CombatService.EnemyDefeated:Fire(target, player)
	elseif justStaggered then
		-- Still alive but crossed the threshold: eligible for
		-- RequestFinishingMove for a regular enemy, or a phase-transition
		-- trigger for a Boss/Elite — EnemyController (T-060/T-065) decides
		-- which by listening here.
		CombatService.EnemyStaggered:Fire(target, player)
	end
end

-- Server-internal: clears a target's Staggered state without a Finishing
-- Move having landed — used by EnemyController for the non-boss auto-recovery
-- timer (§3.9) and for a Boss/Elite's phase transition consuming the stagger
-- (§4.5) instead of leaving it finisher-eligible.
function CombatService:ClearStagger(target: Model)
	local state = enemyStates[target]
	if state then
		state.poise:clearStagger(os.clock())
	end
end

-- Server-internal: lets other services (GrappleService, WeaponPickupService,
-- future EnemyController) query Poise state without duplicating the
-- registry. Returns false for anything not currently a registered target.
function CombatService:IsStaggered(target: Model): boolean
	local state = enemyStates[target]
	return state ~= nil and state.poise.isStaggered
end

-- Server-internal: grants bonus Chi outside normal combat gain (e.g. a Chi
-- Orb pickup, T-101/Phase 8). Clamped by the player's ChiMeterState cap.
function CombatService:GrantChi(player: Player, amount: number)
	local state = getPlayerState(player)
	state.chi:gain(amount)
	syncChi(player, state)
end

-- Server-internal: applies damage to a player, checking dodge invulnerability
-- (T-031) and block/parry mitigation (T-043) first. Called by EnemyController
-- (T-062/T-063, Phase 4) for enemy attacks.
--
-- T-124 (Phase 10): a hit that would drop the player to 0 HP instead leaves
-- them at 1 HP and enters the "Fallen" state (`IsFallen` attribute) rather
-- than letting Roblox's default Humanoid death/respawn take over — Fallen
-- players are ReviveService's responsibility from here, not this function's.
function CombatService:ApplyDamageToPlayer(player: Player, amount: number, impactTime: number, source: any)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	if player:GetAttribute("IsFallen") == true then
		return -- already down; ReviveService owns them until revived
	end

	local DodgeService = Knit.GetService("DodgeService")
	if DodgeService:IsInvulnerable(player) then
		return -- i-frames absorbed it entirely
	end

	local state = getPlayerState(player)
	local timingDelta = if state.isBlocking and state.blockStartedAt then state.blockStartedAt - impactTime else nil
	-- T-091: SkillTreeService's ParryWindowExtension node sets this attribute.
	local parryWindowBonus = player:GetAttribute("ParryWindowBonus")
	local parryWindow = CombatConfig.Attacks.ParryWindow + (if type(parryWindowBonus) == "number" then parryWindowBonus else 0)
	local parryResult = ParryTiming.classify(timingDelta, parryWindow)

	local finalDamage = amount
	if parryResult == "PerfectParry" then
		finalDamage = 0 -- fully negated; attacker stun is handled by the caller (enemy AI, Phase 4)
	elseif parryResult == "Block" then
		finalDamage = amount * (1 - CombatConfig.Attacks.BlockDamageReduction)
	end

	if finalDamage > 0 then
		if finalDamage >= humanoid.Health then
			humanoid.Health = 1
			player:SetAttribute("IsFallen", true)
			CombatService.PlayerFallen:Fire(player, source)
		else
			humanoid:TakeDamage(finalDamage)
		end
		state.chi:gain(CombatConfig.ChiMeter.GainPerHitTaken)
		state.styleScore:resetCombo() -- getting hit breaks the live combo (§3.7)
		syncChi(player, state)
		CombatService.PlayerDamaged:Fire(player, finalDamage, source)
	end
end

--// Client-facing API \\--

function CombatService.Client:RequestAttack(player: Player, isHeavy: boolean)
	if not Knit.GetService("RateLimitService"):TryConsume(player, "CombatService.RequestAttack") then
		return { hits = 0, comboCount = 0 }
	end

	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then
		return { hits = 0, comboCount = 0 }
	end

	local state = getPlayerState(player)
	local weapon = WeaponConfig.Weapons[state.weaponId]
	local inputType = if isHeavy then "Heavy" else "Light"
	local now = os.clock()

	local damageMultiplier = 1
	state.comboWalker:advance(inputType, now) -- advances if it can; ignored (nil) otherwise, see file header
	local stepData = state.comboWalker:getCurrentStepData()
	if stepData and stepData.Input == inputType then
		damageMultiplier = stepData.DamageMultiplier
	end

	local baseDamage = if isHeavy then CombatConfig.Attacks.HeavyDamage else CombatConfig.Attacks.LightDamage
	local damage = baseDamage * damageMultiplier

	local ping = player:GetNetworkPing()
	local rewindTime = now - math.clamp(ping, 0, MAX_REWIND_SECONDS)

	local targets = findValidTargets(rootPart.Position, rootPart.CFrame.LookVector, weapon, rewindTime)
	for _, hit in targets do
		if isHeavy and hit.target:GetAttribute("IsBlocking") == true then
			CombatService.HeavyHitOnBlockingEnemy:Fire(hit.target, player)
		end
		CombatService:ApplyDamageToEnemy(hit.target, damage, player)
		if isHeavy then
			-- T-135 (Phase 11): FeedbackFXService relays this for the
			-- Heavy Attack hit-stop freeze-frame (§18).
			CombatService.HeavyAttackLanded:Fire(hit.target, player)
		end
	end

	-- T-100 (Phase 8): the same swing also checks nearby destructible
	-- containers, using the attacker's live (non-rewound) position — unlike
	-- enemies, containers don't move, so no lag-compensation rewind is needed.
	Knit.GetService("DestructibleContainerService"):CheckHits(rootPart.Position, rootPart.CFrame.LookVector, weapon, player)

	return { hits = #targets, comboCount = state.styleScore.comboCounter }
end

function CombatService.Client:SetBlocking(player: Player, isBlocking: boolean)
	local state = getPlayerState(player)
	if isBlocking and not state.isBlocking then
		state.blockStartedAt = os.clock()
	elseif not isBlocking then
		state.blockStartedAt = nil
	end
	state.isBlocking = isBlocking
end

function CombatService.Client:RequestFinishingMove(player: Player, target: Model): boolean
	if not Knit.GetService("RateLimitService"):TryConsume(player, "CombatService.RequestFinishingMove") then
		return false
	end

	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local enemyState = enemyStates[target]
	local targetRoot = target:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart or not enemyState or not targetRoot then
		return false
	end
	if not enemyState.poise.isStaggered then
		return false
	end
	if (targetRoot.Position - rootPart.Position).Magnitude > FINISHING_MOVE_MAX_DISTANCE then
		return false
	end
	local role = target:GetAttribute("Role")
	if role == "Boss" or role == "Elite" then
		-- §4.5/§4.2: bosses and Elite Champions are never one-shot-finished
		-- off a Poise stagger — being staggered gates their phase transition
		-- (T-065) instead, handled by EnemyController.
		return false
	end

	local humanoid = target:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:TakeDamage(humanoid.Health) -- Finishing Move always defeats the target
	end
	enemyState.poise:clearStagger(os.clock())

	CombatService.FinishingMoveLanded:Fire(target, player)
	CombatService.EnemyDefeated:Fire(target, player)
	return true
end

function CombatService.Client:RequestUltimate(player: Player): boolean
	if not Knit.GetService("RateLimitService"):TryConsume(player, "CombatService.RequestUltimate") then
		return false
	end

	local state = getPlayerState(player)
	if not state.chi:tryActivate() then
		return false
	end
	syncChi(player, state)
	local weapon = WeaponConfig.Weapons[state.weaponId]
	CombatService.UltimateActivated:Fire(player, state.weaponId, weapon.Ultimate)
	return true
end

--// Lifecycle \\--

function CombatService:KnitInit()
	Players.PlayerRemoving:Connect(function(player)
		playerStates[player] = nil
	end)

	for _, enemy in CollectionService:GetTagged(ENEMY_TAG) do
		registerEnemy(enemy)
	end
	CollectionService:GetInstanceAddedSignal(ENEMY_TAG):Connect(registerEnemy)
	CollectionService:GetInstanceRemovedSignal(ENEMY_TAG):Connect(unregisterEnemy)

	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		for enemy, state in enemyStates do
			local rootPart = enemy:FindFirstChild("HumanoidRootPart") :: BasePart?
			if rootPart then
				state.history:record(rootPart.Position, now)
				state.poise:tick(now)
			end
		end
	end)
end

return CombatService
