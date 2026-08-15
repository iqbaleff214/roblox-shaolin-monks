--!strict
-- T-072 (GDD §5.2, §3.6). Executes the 5 Ultimate techniques as config-driven
-- damage/AoE, triggered by CombatService.UltimateActivated (Phase 3's
-- already-built Chi-gate hookup point). Damage resolution here reads
-- exclusively from `ultimateData` (WeaponConfig's Ultimate sub-table) —
-- nothing in this file ever looks at an equipped cosmetic skin, which is
-- what makes the function/cosmetics decoupling (§3.6) true by construction
-- rather than by convention: there is no code path left for a skin to
-- influence damage even accidentally.
--
-- Cosmetic FX layer: `UltimateExecutedRemote` broadcasts (player, weaponId)
-- to every client; UltimateFXController (client) resolves which visual to
-- play from that, currently always the weapon's base FxSlot since the
-- Ultimate FX skin shop (§11.2, Phase 9) doesn't exist yet — swapping in a
-- real owned-skin lookup later only touches that client-side resolution,
-- never this file.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local AreaOfEffectShape = require(ReplicatedStorage.Shared.modules.AreaOfEffectShape)

local ENEMY_TAG = "Enemy"

local UltimateService = Knit.CreateService({
	Name = "UltimateService",
})

local ultimateExecutedRemote = Instance.new("RemoteEvent")
ultimateExecutedRemote.Name = "UltimateExecutedRemote"
ultimateExecutedRemote.Parent = ReplicatedStorage

type UltimateData = {
	Damage: number,
	AreaShape: AreaOfEffectShape.Shape,
	AreaRadius: number,
	ConeAngle: number?,
	LineWidth: number?,
}

local function findTargetsInArea(origin: Vector3, forward: Vector3, ultimateData: UltimateData): { Model }
	local targets: { Model } = {}
	for _, enemy in CollectionService:GetTagged(ENEMY_TAG) do
		if enemy:IsA("Model") then
			local root = enemy:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				local isHit = AreaOfEffectShape.isWithin(
					ultimateData.AreaShape,
					origin,
					forward,
					root.Position,
					ultimateData.AreaRadius,
					ultimateData.ConeAngle,
					ultimateData.LineWidth
				)
				if isHit then
					table.insert(targets, enemy)
				end
			end
		end
	end
	return targets
end

local function onUltimateActivated(player: Player, weaponId: string, ultimateData: UltimateData)
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then
		return
	end

	local targets = findTargetsInArea(rootPart.Position, rootPart.CFrame.LookVector, ultimateData)

	local CombatService = Knit.GetService("CombatService")
	for _, target in targets do
		CombatService:ApplyDamageToEnemy(target, ultimateData.Damage, player)
	end

	ultimateExecutedRemote:FireAllClients(player, weaponId)
end

function UltimateService:KnitStart()
	local CombatService = Knit.GetService("CombatService")
	CombatService.UltimateActivated:Connect(onUltimateActivated)
end

return UltimateService
