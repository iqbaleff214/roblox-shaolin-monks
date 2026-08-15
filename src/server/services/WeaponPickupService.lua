--!strict
-- T-045 (GDD §3.5). Enemy weapon drop on disarm (rolled off CombatService's
-- HeavyHitOnBlockingEnemy signal), environmental/dropped weapon pickup, and
-- a temporary secondary weapon with a fixed number of melee swings (its
-- "short combo") plus a throw option. Main Weapon (WeaponConfig loadout) is
-- never touched by any of this — secondary weapons are strictly additive.
--
-- Pickup items are plain tagged Parts with a ProximityPrompt; Studio art
-- (S-041) swaps the visual later without touching this script, same as
-- every other tag-driven system in this codebase.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)

local CombatConfig = ConfigService.Combat
local ENEMY_TAG = "Enemy"
local PICKUP_TAG = "WeaponPickupItem"
local PICKUP_RANGE = 6 -- studs
local THROW_RANGE = 20 -- studs

local WeaponPickupService = Knit.CreateService({
	Name = "WeaponPickupService",
	Client = {},
})

type SecondaryWeaponState = {
	swingsRemaining: number,
}

local secondaryWeapons: { [Player]: SecondaryWeaponState } = {}

local function spawnPickupItem(position: Vector3): BasePart
	local part = Instance.new("Part")
	part.Name = "WeaponPickupItem"
	part.Size = Vector3.new(1, 1, 3)
	part.Anchored = true
	part.CanCollide = false
	part.Position = position
	CollectionService:AddTag(part, PICKUP_TAG)

	local prompt = Instance.new("ProximityPrompt")
	-- T-151/§13.2: server-set ProximityPrompt text replicates identically to
	-- every client, so it can't route through the client-only translator
	-- (LocalizationController) the way UI scripts do — true per-player
	-- localization of it needs a client-side override system, out of scope
	-- here. Deliberate, explicit lint exemption, not an oversight.
	prompt.ActionText = "Pick Up Weapon" -- lint-disable
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = PICKUP_RANGE
	prompt.Parent = part

	part.Parent = workspace

	prompt.Triggered:Connect(function(player: Player)
		if secondaryWeapons[player] then
			return -- already holding one; leave the item for someone else
		end
		secondaryWeapons[player] = { swingsRemaining = CombatConfig.WeaponPickup.MeleeSwings }
		part:Destroy()
	end)

	return part
end

local function raycastAlong(origin: Vector3, direction: Vector3, ignore: { Instance }): RaycastResult?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	return workspace:Raycast(origin, direction.Unit * THROW_RANGE, params)
end

--// Disarm hookup (§3.5) \\--

local function onHeavyHitOnBlockingEnemy(target: Model, _player: Player)
	if math.random() > CombatConfig.Disarm.ChanceOnHeavyVsBlocking then
		return -- roll failed
	end

	target:SetAttribute("IsBlocking", false)
	-- VulnerableDuration (CombatConfig.Disarm) is advisory for the future
	-- role AI (T-062, Phase 4) — how long it should wait before blocking
	-- again — not enforced by a timer here, since nothing re-enables
	-- blocking on its own yet.

	local rootPart = target:FindFirstChild("HumanoidRootPart") :: BasePart?
	if rootPart then
		-- "weapon socket": no rigged attachment point exists without
		-- Studio-authored assets (S-041) yet, so this drops at the
		-- enemy's root position with a small offset as a clear stand-in.
		spawnPickupItem(rootPart.Position + rootPart.CFrame.RightVector * 2)
	end
end

--// Client-facing API \\--

function WeaponPickupService.Client:RequestPickup(player: Player): boolean
	if secondaryWeapons[player] then
		return false
	end
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then
		return false
	end

	for _, item in CollectionService:GetTagged(PICKUP_TAG) do
		if item:IsA("BasePart") and (item.Position - rootPart.Position).Magnitude <= PICKUP_RANGE then
			secondaryWeapons[player] = { swingsRemaining = CombatConfig.WeaponPickup.MeleeSwings }
			item:Destroy()
			return true
		end
	end
	return false
end

function WeaponPickupService.Client:RequestSecondaryAttack(player: Player): boolean
	local state = secondaryWeapons[player]
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not state or not rootPart then
		return false
	end

	local CombatService = Knit.GetService("CombatService")
	local closest: Model? = nil
	local closestDistance = math.huge
	for _, enemy in CollectionService:GetTagged(ENEMY_TAG) do
		if enemy:IsA("Model") then
			local enemyRoot = enemy:FindFirstChild("HumanoidRootPart") :: BasePart?
			if enemyRoot then
				local distance = (enemyRoot.Position - rootPart.Position).Magnitude
				if distance < closestDistance then
					closest = enemy
					closestDistance = distance
				end
			end
		end
	end

	if closest and closestDistance <= 6 then
		CombatService:ApplyDamageToEnemy(closest, CombatConfig.WeaponPickup.MeleeDamage, player)
	end

	state.swingsRemaining -= 1
	if state.swingsRemaining <= 0 then
		secondaryWeapons[player] = nil
	end
	return true
end

function WeaponPickupService.Client:RequestThrowSecondary(player: Player, direction: Vector3): boolean
	local state = secondaryWeapons[player]
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not state or not rootPart then
		return false
	end
	secondaryWeapons[player] = nil -- thrown; consumed regardless of outcome

	local CombatService = Knit.GetService("CombatService")
	local hit = raycastAlong(rootPart.Position, direction, { character :: Instance })

	if hit and CollectionService:HasTag(hit.Instance, ENEMY_TAG) then
		-- §3.5: lost on impact with an enemy, no pickup left behind.
		CombatService:ApplyDamageToEnemy(hit.Instance :: Model, CombatConfig.WeaponPickup.ThrowDamage, player)
	else
		-- Missed everything (or hit scenery): becomes a lootable world item
		-- where it landed, retrievable per §3.5.
		local landingPosition = if hit then hit.Position else rootPart.Position + direction.Unit * THROW_RANGE
		spawnPickupItem(landingPosition)
	end

	return true
end

function WeaponPickupService:KnitInit()
	Players.PlayerRemoving:Connect(function(player)
		secondaryWeapons[player] = nil
	end)
end

function WeaponPickupService:KnitStart()
	local CombatService = Knit.GetService("CombatService")
	CombatService.HeavyHitOnBlockingEnemy:Connect(onHeavyHitOnBlockingEnemy)
end

return WeaponPickupService
