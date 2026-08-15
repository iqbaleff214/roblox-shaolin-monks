--!strict
-- T-031 (GDD §3.3 / §17.1). Server-authoritative dodge-roll timing: gates
-- how often a player can start a dodge (cooldown) and answers whether a
-- given moment falls inside that dodge's i-frame window.
--
-- Scope note: the actual roll movement/repositioning belongs to the Block/
-- Parry/Dodge combat system (§3.3, T-043, Phase 3) — this service only owns
-- the invulnerability-window bookkeeping so it exists ahead of, and is
-- reusable by, that system. `IsInvulnerable` is the hookup point CombatService
-- (T-049, not yet built) will call before applying damage.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)
local DodgeStateMachine = require(ReplicatedStorage.Shared.modules.DodgeStateMachine)

local DodgeConfig = ConfigService.Combat.Attacks

local DodgeService = Knit.CreateService({
	Name = "DodgeService",
	Client = {},
})

local machinesByPlayer: { [Player]: DodgeStateMachine.DodgeStateMachine } = {}

local MIN_DODGE_COOLDOWN = 0.1 -- seconds; floor so DodgeCooldownReduction can never enable spam-dodge i-frames

local function getMachine(player: Player): DodgeStateMachine.DodgeStateMachine
	local machine = machinesByPlayer[player]
	if not machine then
		-- T-091: SkillTreeService's DodgeCooldownReduction node sets this
		-- attribute (a negative seconds value).
		local cooldownBonus = player:GetAttribute("DodgeCooldownBonus")
		local cooldown = DodgeConfig.DodgeCooldown + (if type(cooldownBonus) == "number" then cooldownBonus else 0)
		machine = DodgeStateMachine.new(DodgeConfig.DodgeIFrames, math.max(cooldown, MIN_DODGE_COOLDOWN))
		machinesByPlayer[player] = machine
	end
	return machine
end

-- Server-internal API (called by other server services, e.g. the future
-- CombatService) — not exposed to clients.
function DodgeService:IsInvulnerable(player: Player): boolean
	local machine = machinesByPlayer[player]
	if not machine then
		return false
	end
	return machine:isInvulnerable(os.clock())
end

-- Client-callable: attempts to start a dodge. Returns false if still on
-- cooldown, in which case the client must not play the roll.
function DodgeService.Client:RequestDodge(player: Player): boolean
	if not Knit.GetService("RateLimitService"):TryConsume(player, "DodgeService.RequestDodge") then
		return false
	end
	local machine = getMachine(player)
	return machine:tryDodge(os.clock())
end

function DodgeService:KnitInit()
	Players.PlayerRemoving:Connect(function(player)
		machinesByPlayer[player] = nil
	end)
end

return DodgeService
