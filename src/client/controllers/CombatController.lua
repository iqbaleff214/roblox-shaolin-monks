--!strict
-- T-041/042/043/047/048 (client half). Turns InputController's logical
-- actions into combat requests, and plays the "instant" side of GDD §17.1's
-- client-predicted model: the swing itself (animation/sound trigger point)
-- fires the moment the input lands, never waiting on the server.
--
-- Scope note on §17.1: this controller does not speculatively predict
-- *impacts* client-side (no local hit-scan against enemy positions) — doing
-- that correctly needs real animation timing (S-042) and enemy models
-- (S-030), neither of which exist yet. What §17.1 and T-042's DoD actually
-- require — the server being sole authority on whether damage lands, and no
-- rubber-banding on rejection — both hold here by construction: this
-- controller never applies damage or moves anything based on a guessed hit,
-- so there is nothing to retract. `AttackHitConfirmed` fires once the server
-- responds, ready for impact VFX/audio to hook into later.
--
-- All server calls go through Knit's Promise-wrapped Client methods
-- (Knit.Start defaults `ServicePromises` to true) — fire-and-forget with
-- :andThen, never yielding the input-handling thread.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)

local Movement = ConfigService.Combat.Movement
local DASH_DURATION = 0.3 -- seconds; dodge roll travels Movement.DodgeRoll.Distance over this window
local LOCK_ON_RANGE = 40 -- studs
local ENEMY_TAG = "Enemy"

local player = Players.LocalPlayer

local CombatController = Knit.CreateController({
	Name = "CombatController",
})

-- Local UI/feedback signals — T-131 (Phase 11) and the audio system (T-140,
-- Phase 12) bind to these once they exist; this controller only fires them.
CombatController.AttackSwung = Signal.new() -- (isHeavy: boolean)
CombatController.AttackHitConfirmed = Signal.new() -- (hits: number)
CombatController.ComboUpdated = Signal.new() -- (comboCount: number)
CombatController.UltimateFired = Signal.new() -- ()
CombatController.LockedTargetChanged = Signal.new() -- (target: Model?)

local isGrabbing = false
local hasSecondaryWeapon = false
local lockedTarget: Model? = nil

local function getRootPart(): BasePart?
	local character = player.Character
	return character and (character:FindFirstChild("HumanoidRootPart") :: BasePart?)
end

--// Attacks \\--

local function performAttack(isHeavy: boolean)
	CombatController.AttackSwung:Fire(isHeavy)

	local CombatService = Knit.GetService("CombatService")
	CombatService:RequestAttack(isHeavy):andThen(function(result)
		if result.hits > 0 then
			CombatController.AttackHitConfirmed:Fire(result.hits)
		end
		CombatController.ComboUpdated:Fire(result.comboCount)
	end)
end

--// Block \\--

local function setBlocking(isBlocking: boolean)
	local CombatService = Knit.GetService("CombatService")
	CombatService:SetBlocking(isBlocking)
end

--// Dodge (§3.3 — movement trigger gated by DodgeService's server-side i-frame/cooldown state from T-031) \\--

local function performDodge()
	local DodgeService = Knit.GetService("DodgeService")
	DodgeService:RequestDodge():andThen(function(granted: boolean)
		if not granted then
			return
		end
		local rootPart = getRootPart()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not rootPart or not humanoid then
			return
		end

		local direction = humanoid.MoveDirection
		if direction.Magnitude < 1e-3 then
			direction = rootPart.CFrame.LookVector
		end
		direction = Vector3.new(direction.X, 0, direction.Z).Unit

		local speed = Movement.DodgeRoll.Distance / DASH_DURATION
		local velocity = rootPart.AssemblyLinearVelocity
		rootPart.AssemblyLinearVelocity = Vector3.new(direction.X * speed, velocity.Y, direction.Z * speed)
	end)
end

--// Grapple (§3.4) \\--

local function performGrab()
	local GrappleService = Knit.GetService("GrappleService")
	GrappleService:RequestGrab():andThen(function(granted: boolean)
		isGrabbing = granted
	end)
end

--// Throw (grabbed enemy, §3.4, or secondary weapon, §3.5) \\--

local function performThrow()
	local rootPart = getRootPart()
	if not rootPart then
		return
	end
	local direction = rootPart.CFrame.LookVector

	if isGrabbing then
		local GrappleService = Knit.GetService("GrappleService")
		GrappleService:RequestThrow(direction):andThen(function()
			isGrabbing = false
		end)
	elseif hasSecondaryWeapon then
		local WeaponPickupService = Knit.GetService("WeaponPickupService")
		WeaponPickupService:RequestThrowSecondary(direction):andThen(function()
			hasSecondaryWeapon = false
		end)
	end
end

--// Ultimate (§3.6) \\--

local function performUltimate()
	local CombatService = Knit.GetService("CombatService")
	CombatService:RequestUltimate():andThen(function(activated: boolean)
		if activated then
			CombatController.UltimateFired:Fire()
		end
	end)
end

--// Lock-on (targeting assist; read-only, no server round-trip needed) \\--

local function toggleLockOn()
	if lockedTarget then
		lockedTarget = nil
		CombatController.LockedTargetChanged:Fire(nil)
		return
	end

	local rootPart = getRootPart()
	if not rootPart then
		return
	end

	local CollectionService = game:GetService("CollectionService")
	local nearest: Model? = nil
	local nearestDistance = LOCK_ON_RANGE
	for _, enemy in CollectionService:GetTagged(ENEMY_TAG) do
		if enemy:IsA("Model") then
			local enemyRoot = enemy:FindFirstChild("HumanoidRootPart") :: BasePart?
			if enemyRoot then
				local distance = (enemyRoot.Position - rootPart.Position).Magnitude
				if distance <= nearestDistance then
					nearest = enemy
					nearestDistance = distance
				end
			end
		end
	end

	lockedTarget = nearest
	CombatController.LockedTargetChanged:Fire(nearest)
end

--// Input wiring \\--

local ACTION_PRESSED_HANDLERS: { [string]: () -> () } = {
	LightAttack = function() performAttack(false) end,
	HeavyAttack = function() performAttack(true) end,
	Block = function() setBlocking(true) end,
	Dodge = performDodge,
	Grab = performGrab,
	ThrowWeapon = performThrow,
	Ultimate = performUltimate,
	LockOn = toggleLockOn,
}

local ACTION_RELEASED_HANDLERS: { [string]: () -> () } = {
	Block = function() setBlocking(false) end,
}

function CombatController:KnitStart()
	local InputController = Knit.GetController("InputController")

	InputController.ActionPressed:Connect(function(action: string)
		local handler = ACTION_PRESSED_HANDLERS[action]
		if handler then
			handler()
		end
	end)

	InputController.ActionReleased:Connect(function(action: string)
		local handler = ACTION_RELEASED_HANDLERS[action]
		if handler then
			handler()
		end
	end)
end

function CombatController:KnitInit() end

return CombatController
