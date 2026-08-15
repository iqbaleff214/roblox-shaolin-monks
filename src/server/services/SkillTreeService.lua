--!strict
-- T-091 (GDD §9.2). Server-validated Skill Point spend on nodes, gated by
-- SkillNodeRules's max-rank check and ProgressionService's banked-points
-- check. Every node purchase sets a uniform `SkillRank_<Node>` Player
-- attribute (queryable by any future system) plus, for the nodes with a
-- concrete hookup available today, the real functional effect:
--   * DoubleJump   -> `DoubleJumpUnlocked` attribute, already read by
--                     CharacterController (T-030, Phase 2).
--   * HealthGrowth -> directly raises the player's Humanoid.MaxHealth via
--                     ProgressionConfig.StatGrowth.HealthBonusAtLevel.
--   * ChiGrowth    -> `ChiBonus` attribute, read by CombatService when it
--                     constructs a player's ChiMeterState.
--   * DodgeCooldownReduction -> `DodgeCooldownBonus` attribute, read by
--                     DodgeService when it constructs a player's dodge timer.
--   * ParryWindowExtension   -> `ParryWindowBonus` attribute, read by
--                     CombatService's parry-timing check.
-- ExtendedCombo and WeaponRetrievalSpeed have no live system to hook into yet
-- (combo depth is currently Combo-Scroll-gated per T-041/§10.3, and no
-- retrieval-speed mechanic exists in WeaponPickupService) — they still bank a
-- real rank and expose it via the uniform attribute, ready for whichever
-- future system reconciles §9.2's skill-tree wording with §10.3's shop.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)
local SkillNodeRules = require(ReplicatedStorage.Shared.modules.SkillNodeRules)

local ProgressionConfig = ConfigService.Progression
local PLAYER_BASE_HEALTH = 100 -- Roblox Humanoid default; players are never `Enemy`-tagged so CombatService's health seeding never touches them

local SkillTreeService = Knit.CreateService({
	Name = "SkillTreeService",
	Client = {},
})

-- (player: Player, node: string, newRank: number)
SkillTreeService.NodePurchased = Signal.new()

local ranksByPlayer: { [Player]: { [string]: number } } = {}

local function getRanks(player: Player): { [string]: number }
	local ranks = ranksByPlayer[player]
	if not ranks then
		ranks = {}
		ranksByPlayer[player] = ranks
	end
	return ranks
end

local function applyHealthBonus(player: Player, bonus: number)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local newMax = PLAYER_BASE_HEALTH + bonus
	local delta = newMax - humanoid.MaxHealth
	humanoid.MaxHealth = newMax
	humanoid.Health = math.min(newMax, humanoid.Health + math.max(delta, 0))
end

local function applyNodeEffect(player: Player, node: string, rank: number)
	player:SetAttribute("SkillRank_" .. node, rank)

	if node == "DoubleJump" then
		player:SetAttribute("DoubleJumpUnlocked", true)
	elseif node == "HealthGrowth" then
		local bonus = ProgressionConfig.StatGrowth.HealthBonusAtLevel(rank)
		player:SetAttribute("HealthBonus", bonus)
		applyHealthBonus(player, bonus)
	elseif node == "ChiGrowth" then
		player:SetAttribute("ChiBonus", ProgressionConfig.StatGrowth.ChiBonusAtLevel(rank))
	elseif node == "DodgeCooldownReduction" then
		player:SetAttribute("DodgeCooldownBonus", -ProgressionConfig.SkillEffects.DodgeCooldownReductionSeconds)
	elseif node == "ParryWindowExtension" then
		player:SetAttribute("ParryWindowBonus", ProgressionConfig.SkillEffects.ParryWindowExtensionSeconds)
	end
end

function SkillTreeService.Client:RequestPurchaseNode(player: Player, node: string): boolean
	if not Knit.GetService("RateLimitService"):TryConsume(player, "SkillTreeService.RequestPurchaseNode") then
		return false
	end
	local cost = ProgressionConfig.SkillPoints.NodeCosts[node]
	if not cost then
		return false
	end

	local ranks = getRanks(player)
	local currentRank = ranks[node] or 0
	if not SkillNodeRules.canPurchase(node, currentRank) then
		return false
	end

	local ProgressionService = Knit.GetService("ProgressionService")
	if not ProgressionService:SpendSkillPoints(player, cost) then
		return false
	end

	local newRank = currentRank + 1
	ranks[node] = newRank
	applyNodeEffect(player, node, newRank)
	SkillTreeService.NodePurchased:Fire(player, node, newRank)
	return true
end

function SkillTreeService.Client:GetRank(player: Player, node: string): number
	return getRanks(player)[node] or 0
end

function SkillTreeService:KnitInit()
	Players.PlayerRemoving:Connect(function(player)
		ranksByPlayer[player] = nil
	end)

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			local bonus = player:GetAttribute("HealthBonus")
			if type(bonus) == "number" and bonus > 0 then
				local humanoid = character:WaitForChild("Humanoid") :: Humanoid
				humanoid.MaxHealth = PLAYER_BASE_HEALTH + bonus
				humanoid.Health = humanoid.MaxHealth
			end
		end)
	end)
end

return SkillTreeService
