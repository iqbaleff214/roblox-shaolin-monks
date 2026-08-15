--!strict
-- T-135 (GDD §15.4, §18). Relays already-existing server-internal combat/
-- enemy/loot signals into Client-facing FX triggers, centralizing every
-- "server event -> client FX" translation in one place rather than adding a
-- Client table to CombatService/EnemyController/DestructibleContainerService
-- individually. Every payload carries only what the client needs to play
-- the effect — timings themselves are never sent, since UIConfig already
-- has them (`FeedbackTimings`) and the client reads the same config
-- directly, so there's no server-computed duration to drift out of sync
-- with the client's own copy.
--
-- Fired to every client in this server instance rather than filtered by
-- proximity: a battlefield instance caps at 4 players (GDD header), so
-- "nearby" and "everyone present" are effectively the same set here.
-- (§12.4's Flawless banner already has its own Client signal on
-- SocialHookService — not duplicated here.)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local FeedbackFXService = Knit.CreateService({
	Name = "FeedbackFXService",
	Client = {
		HitStop = Knit.CreateSignal(), -- (target: Model)
		FinishingMoveOverlay = Knit.CreateSignal(), -- (target: Model)
		BossPhaseFlash = Knit.CreateSignal(), -- (target: Model)
		ContainerBreakPopup = Knit.CreateSignal(), -- (containerType: string)
	},
})

local function onHeavyAttackLanded(target: Model, _player: Player)
	FeedbackFXService.Client.HitStop:FireAll(target)
end

local function onFinishingMoveLanded(target: Model, _player: Player)
	FeedbackFXService.Client.FinishingMoveOverlay:FireAll(target)
end

local function onBossPhaseTransition(target: Model)
	FeedbackFXService.Client.BossPhaseFlash:FireAll(target)
end

local function onContainerBroken(_instance: Instance, containerType: string, _player: Player?)
	FeedbackFXService.Client.ContainerBreakPopup:FireAll(containerType)
end

function FeedbackFXService:KnitStart()
	local CombatService = Knit.GetService("CombatService")
	CombatService.HeavyAttackLanded:Connect(onHeavyAttackLanded)
	CombatService.FinishingMoveLanded:Connect(onFinishingMoveLanded)

	local EnemyController = Knit.GetService("EnemyController")
	EnemyController.BossPhaseTransition:Connect(onBossPhaseTransition)

	local DestructibleContainerService = Knit.GetService("DestructibleContainerService")
	DestructibleContainerService.ContainerBroken:Connect(onContainerBroken)
end

return FeedbackFXService
