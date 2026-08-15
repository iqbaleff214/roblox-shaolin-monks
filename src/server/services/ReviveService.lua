--!strict
-- T-124 (GDD §12.3). Fallen/revive mechanic layered on top of CombatService's
-- (T-049) Fallen-state intercept — a lethal hit already leaves the target at
-- 1 HP with `IsFallen` set instead of dying, so this service only owns the
-- revive channel itself. A nearby teammate channels a revive over
-- CombatConfig.Revive.Duration seconds; taking damage during that channel
-- cancels it (subscribing to CombatService.PlayerDamaged and checking
-- whether the damaged player is a reviver currently mid-channel) — the
-- "vulnerable during" design note.
--
-- Whole-party-down: every `PlayerFallen` checks whether every member of that
-- player's party (PartyService, T-120) is now Fallen; if so, the current
-- arena wave restarts (ArenaGateController:RestartCurrentWave, T-061/T-123)
-- rather than the full chapter, and every member is revived back into it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)

local ReviveConfig = ConfigService.Combat.Revive

local ReviveService = Knit.CreateService({
	Name = "ReviveService",
	Client = {},
})

-- (target: Player, reviver: Player)
ReviveService.ReviveCompleted = Signal.new()
-- (target: Player, reviver: Player)
ReviveService.ReviveCancelled = Signal.new()
-- (members: {Player})
ReviveService.WholePartyDown = Signal.new()

type ReviveState = { reviver: Player, thread: thread }
local activeRevives: { [Player]: ReviveState } = {} -- keyed by target (the Fallen player)
local reviverToTarget: { [Player]: Player } = {}

local function isFallen(player: Player): boolean
	return player:GetAttribute("IsFallen") == true
end

local function distanceBetween(a: Player, b: Player): number?
	local aRoot = a.Character and a.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local bRoot = b.Character and b.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not aRoot or not bRoot then
		return nil
	end
	return (aRoot.Position - bRoot.Position).Magnitude
end

local function cancelRevive(target: Player)
	local revive = activeRevives[target]
	if not revive then
		return
	end
	task.cancel(revive.thread)
	revive.reviver:SetAttribute("IsReviving", false)
	reviverToTarget[revive.reviver] = nil
	activeRevives[target] = nil
	ReviveService.ReviveCancelled:Fire(target, revive.reviver)
end

local function completeRevive(target: Player)
	local revive = activeRevives[target]
	if not revive then
		return
	end
	activeRevives[target] = nil
	reviverToTarget[revive.reviver] = nil
	revive.reviver:SetAttribute("IsReviving", false)

	local character = target.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = math.max(humanoid.Health, humanoid.MaxHealth * ReviveConfig.HealthRestoreFraction)
	end
	target:SetAttribute("IsFallen", false)

	ReviveService.ReviveCompleted:Fire(target, revive.reviver)
end

function ReviveService.Client:RequestRevive(reviver: Player, target: Player): boolean
	if reviver == target then
		return false
	end
	if not isFallen(target) or isFallen(reviver) then
		return false
	end
	if activeRevives[target] or reviverToTarget[reviver] then
		return false -- target already being revived, or reviver already reviving someone
	end

	local distance = distanceBetween(reviver, target)
	if not distance or distance > ReviveConfig.Range then
		return false
	end

	reviver:SetAttribute("IsReviving", true)
	local thread = task.delay(ReviveConfig.Duration, function()
		completeRevive(target)
	end)
	activeRevives[target] = { reviver = reviver, thread = thread }
	reviverToTarget[reviver] = target
	return true
end

local function onPlayerDamaged(player: Player, _amount: number, _source: any)
	local target = reviverToTarget[player]
	if target then
		cancelRevive(target)
	end
end

local function checkWholePartyDown(fallenPlayer: Player)
	local PartyService = Knit.GetService("PartyService")
	local members = PartyService:GetPartyMembers(fallenPlayer)
	if #members == 0 then
		return
	end
	for _, member in members do
		if not isFallen(member) then
			return -- at least one member is still up
		end
	end

	local ArenaGateController = Knit.GetService("ArenaGateController")
	local arenaId = ArenaGateController:GetArenaIdForPlayer(fallenPlayer)
	if not arenaId then
		return
	end
	ArenaGateController:RestartCurrentWave(arenaId)

	for _, member in members do
		local character = member.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = humanoid.MaxHealth
		end
		member:SetAttribute("IsFallen", false)
	end

	ReviveService.WholePartyDown:Fire(members)
end

function ReviveService:KnitInit()
	Players.PlayerRemoving:Connect(function(player)
		cancelRevive(player) -- if they were the target of an active revive
		local target = reviverToTarget[player]
		if target then
			cancelRevive(target) -- if they were reviving someone
		end
	end)
end

function ReviveService:KnitStart()
	local CombatService = Knit.GetService("CombatService")
	CombatService.PlayerDamaged:Connect(onPlayerDamaged)
	CombatService.PlayerFallen:Connect(function(player: Player, _source: any)
		checkWholePartyDown(player)
	end)
end

return ReviveService
