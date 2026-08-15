--!strict
-- T-071 (GDD §3.2). Resolves and plays the correct animation for each
-- attack: air combo and running-attack variants take priority over the
-- grounded combo tree step, matching §3.2's "Air combo... usable on
-- airborne enemies or after a launcher hit" and "Running attack: sprint +
-- attack" rules.
--
-- Client-only and purely cosmetic — this never touches damage (that stays
-- 100% server-authoritative via CombatService, Phase 3). A local
-- ComboTreeWalker mirror decides ONLY which animation to play the instant
-- input lands (§17.1's "client plays hit feedback instantly"); if it ever
-- drifts from the server's own combo state, the only consequence is a
-- slightly-wrong animation for a single swing — never a damage discrepancy,
-- so there is nothing to reconcile or retract.
--
-- Placeholder guard: WeaponConfig's AnimationId fields are still `0` until
-- Studio (S-042) delivers real asset ids (see T-071's DoD) — playing
-- animation id 0 is skipped rather than erroring.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)
local ComboTreeWalker = require(ReplicatedStorage.Shared.modules.ComboTreeWalker)

local CombatConfig = ConfigService.Combat
local WeaponConfig = ConfigService.Weapon
local DEFAULT_WEAPON_ID = "TwinBlades"

local player = Players.LocalPlayer

local WeaponAnimationController = Knit.CreateController({
	Name = "WeaponAnimationController",
})

local loadedTracks: { [number]: AnimationTrack } = {}
local comboWalker: ComboTreeWalker.ComboTreeWalker? = nil
local comboWalkerWeaponId: string? = nil

local function getEquippedWeaponId(): string
	local id = player:GetAttribute("EquippedWeaponId")
	if type(id) == "string" and WeaponConfig.Weapons[id] then
		return id
	end
	return DEFAULT_WEAPON_ID
end

local function getAnimator(): Animator?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid and humanoid:FindFirstChildOfClass("Animator")
end

local function playAnimationId(animationId: number)
	if animationId == 0 then
		return -- placeholder; S-042 hasn't delivered a real asset yet
	end
	local animator = getAnimator()
	if not animator then
		return
	end

	local track = loadedTracks[animationId]
	if not track or track.Animator ~= animator then
		local animation = Instance.new("Animation")
		animation.AnimationId = `rbxassetid://{animationId}`
		track = animator:LoadAnimation(animation)
		loadedTracks[animationId] = track
	end
	track:Play()
end

local function getComboWalker(): ComboTreeWalker.ComboTreeWalker
	local weaponId = getEquippedWeaponId()
	if not comboWalker or comboWalkerWeaponId ~= weaponId then
		local weapon = WeaponConfig.Weapons[weaponId]
		comboWalker = ComboTreeWalker.new(weapon.ComboTree, CombatConfig.Attacks.ComboWindow)
		comboWalkerWeaponId = weaponId
	end
	return comboWalker :: ComboTreeWalker.ComboTreeWalker
end

local function isAirborne(humanoid: Humanoid): boolean
	return humanoid:GetState() == Enum.HumanoidStateType.Freefall
end

-- §3.2: "Running attack: sprint + attack" — GDD has no separate sprint
-- input, so "sprinting" is read as "currently moving" at the moment of the
-- attack press.
local function isMoving(humanoid: Humanoid): boolean
	return humanoid.MoveDirection.Magnitude > 0
end

local function onAttackInput(isHeavy: boolean)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local weaponId = getEquippedWeaponId()
	local weapon = WeaponConfig.Weapons[weaponId]
	local inputType = if isHeavy then "Heavy" else "Light"

	if isAirborne(humanoid) then
		playAnimationId(weapon.AirComboAnimationId)
		return
	end

	if isMoving(humanoid) then
		playAnimationId(weapon.RunningAttackAnimationId)
		return
	end

	local walker = getComboWalker()
	walker:advance(inputType, os.clock())
	local stepData = walker:getCurrentStepData()
	if stepData then
		playAnimationId(stepData.AnimationId)
	end
end

function WeaponAnimationController:KnitStart()
	local InputController = Knit.GetController("InputController")
	InputController.ActionPressed:Connect(function(action: string)
		if action == "LightAttack" then
			onAttackInput(false)
		elseif action == "HeavyAttack" then
			onAttackInput(true)
		end
	end)

	player.CharacterAdded:Connect(function()
		comboWalker = nil -- fresh combo state on respawn
		loadedTracks = {}
	end)
end

function WeaponAnimationController:KnitInit() end

return WeaponAnimationController
