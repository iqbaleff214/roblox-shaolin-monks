--!strict
-- T-044 (GDD §3.4). Grab a Staggered enemy (CombatService:IsStaggered),
-- then either throw them into another enemy or a `HazardZone` (instant kill
-- + bonus drop signal), or hold them as a human shield that absorbs 1-2
-- ranged hits. Damage application routes through CombatService — this
-- service owns the grab/throw *interaction*, not damage-writing itself
-- (T-049's "single writer" rule).
--
-- Ranged-attack hookup: enemy ranged attacks don't exist yet (T-062/T-063,
-- Phase 4). `AbsorbRangedHit` is the ready seam — future ranged-attack code
-- calls it before CombatService:ApplyDamageToPlayer; a held shield consumes
-- one hit and the attack never reaches the player.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)

local CombatConfig = ConfigService.Combat
local ENEMY_TAG = "Enemy"
local HAZARD_ZONE_TAG = "HazardZone"
local GRAB_RANGE = 8 -- studs
local THROW_RANGE = 20 -- studs

local GrappleService = Knit.CreateService({
	Name = "GrappleService",
	Client = {},
})

-- (target: Model, hazard: Instance, player: Player) — Phase 8's loot system
-- grants the guaranteed bonus relic drop this describes (§3.4); this
-- service only detects and fires it.
GrappleService.EnvironmentalKill = Signal.new()

type GrabState = {
	target: Model,
	shieldHitsRemaining: number,
}

local grabsByPlayer: { [Player]: GrabState } = {}
local grabbedEnemies: { [Model]: Player } = {}

local function findNearestStaggeredEnemy(origin: Vector3): Model?
	local CombatService = Knit.GetService("CombatService")
	local nearest: Model? = nil
	local nearestDistance = GRAB_RANGE

	for _, enemy in CollectionService:GetTagged(ENEMY_TAG) do
		if enemy:IsA("Model") and not grabbedEnemies[enemy] and CombatService:IsStaggered(enemy) then
			local rootPart = enemy:FindFirstChild("HumanoidRootPart") :: BasePart?
			if rootPart then
				local distance = (rootPart.Position - origin).Magnitude
				if distance <= nearestDistance then
					nearest = enemy
					nearestDistance = distance
				end
			end
		end
	end

	return nearest
end

local function releaseGrab(player: Player)
	local grab = grabsByPlayer[player]
	if not grab then
		return
	end
	grabbedEnemies[grab.target] = nil
	grabsByPlayer[player] = nil
end

local function raycastAlong(origin: Vector3, direction: Vector3, ignore: { Instance }): RaycastResult?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	return workspace:Raycast(origin, direction.Unit * THROW_RANGE, params)
end

--// Client-facing API \\--

function GrappleService.Client:RequestGrab(player: Player): boolean
	if grabsByPlayer[player] then
		return false -- already holding something
	end
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then
		return false
	end

	local target = findNearestStaggeredEnemy(rootPart.Position)
	if not target then
		return false
	end

	grabsByPlayer[player] = {
		target = target,
		shieldHitsRemaining = CombatConfig.Grapple.HumanShieldHitCapacity,
	}
	grabbedEnemies[target] = player
	return true
end

function GrappleService.Client:RequestThrow(player: Player, direction: Vector3): boolean
	local grab = grabsByPlayer[player]
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not grab or not rootPart then
		return false
	end

	local CombatService = Knit.GetService("CombatService")
	local hit = raycastAlong(rootPart.Position, direction, { character :: Instance, grab.target })

	if hit then
		if CollectionService:HasTag(hit.Instance, HAZARD_ZONE_TAG) then
			local humanoid = grab.target:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid:TakeDamage(humanoid.Health) -- instant kill
			end
			GrappleService.EnvironmentalKill:Fire(grab.target, hit.Instance, player)
			CombatService.EnemyDefeated:Fire(grab.target, player)
		elseif CollectionService:HasTag(hit.Instance, ENEMY_TAG) then
			CombatService:ApplyDamageToEnemy(hit.Instance :: Model, CombatConfig.Grapple.ThrowDamage, player)
			CombatService:ApplyDamageToEnemy(grab.target, CombatConfig.Grapple.ThrowDamage, player)
		end
	end

	releaseGrab(player)
	return true
end

function GrappleService.Client:RequestReleaseGrab(player: Player)
	releaseGrab(player)
end

--// Server-internal API \\--

-- Consumes one shield hit if the player is currently holding a grabbed
-- enemy with hits remaining. Returns true if the hit was absorbed.
function GrappleService:AbsorbRangedHit(player: Player): boolean
	local grab = grabsByPlayer[player]
	if not grab or grab.shieldHitsRemaining <= 0 then
		return false
	end
	grab.shieldHitsRemaining -= 1
	if grab.shieldHitsRemaining <= 0 then
		releaseGrab(player) -- shield exhausted; the grabbed enemy drops
	end
	return true
end

function GrappleService:KnitInit()
	Players.PlayerRemoving:Connect(releaseGrab)
end

return GrappleService
