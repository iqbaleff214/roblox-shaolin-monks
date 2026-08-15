--!strict
-- T-102 (GDD §10.4). Spawns tier-appropriate loot chests on the three real
-- triggers available today (Arena clear, Boss defeat, LootRoom discovery)
-- and rolls their rarity via ChestRarityRoller (T-101/T-102) on open.
--
-- No chest asset exists in Studio yet — falls back to a simple placeholder
-- Part + ProximityPrompt, the same pragmatic stand-in EnemyPoolService (T-066)
-- uses for enemy rigs; `ServerStorage.ChestTemplates.<Tier>` is checked first
-- so dropping a real model there needs no code change.
--
-- Chapter tier has no live trigger yet (the chapter-clear flow is Phase 10,
-- not built) — `SpawnChapterChest` is the real, ready server-internal method
-- awaiting that caller, the same forward-dependency seam used throughout
-- this codebase.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ChestRarityRoller = require(ReplicatedStorage.Shared.modules.ChestRarityRoller)

local LOOT_ROOM_TAG = "LootRoom"
local CHEST_PROMPT_ACTION_TEXT = "Open Chest"
local CHEST_PROMPT_HOLD_DURATION = 0.5

local ChestService = Knit.CreateService({
	Name = "ChestService",
})

-- (player: Player, tier: string, rarity: string)
ChestService.ChestOpened = Signal.new()

local sessionSeed = Random.new():NextInteger(1, 2 ^ 31 - 1)
local rollCounter = 0
local lootRoomOpened: { [Instance]: boolean } = {}

local function nextSeed(): number
	rollCounter += 1
	return sessionSeed + rollCounter
end

local function getTemplate(tier: string): Model?
	local templatesFolder = ServerStorage:FindFirstChild("ChestTemplates")
	local template = templatesFolder and templatesFolder:FindFirstChild(tier)
	if template and template:IsA("Model") then
		return template
	end
	return nil
end

local function createPlaceholderChest(tier: string): Model
	local model = Instance.new("Model")
	model.Name = tier .. "Chest"

	local part = Instance.new("Part")
	part.Name = "ChestPart"
	part.Size = Vector3.new(3, 2, 2)
	part.Color = Color3.fromRGB(120, 90, 40)
	part.Anchored = true
	part.CanCollide = true
	part.Parent = model

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = CHEST_PROMPT_ACTION_TEXT
	prompt.HoldDuration = CHEST_PROMPT_HOLD_DURATION
	prompt.Parent = part

	model.PrimaryPart = part
	return model
end

local function openChest(chest: Model, tier: string, player: Player)
	local seed = nextSeed()
	local rarity = ChestRarityRoller.roll(seed, tier)
	if rarity then
		ChestService.ChestOpened:Fire(player, tier, rarity)
	end
	chest:Destroy()
end

local function spawnChest(tier: string, cframe: CFrame)
	local template = getTemplate(tier)
	local chest = if template then template:Clone() else createPlaceholderChest(tier)
	chest.Parent = workspace
	if chest.PrimaryPart then
		chest:PivotTo(cframe)
	end

	local prompt = chest:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then
		local opened = false
		prompt.Triggered:Connect(function(player)
			if opened then
				return
			end
			opened = true
			openChest(chest, tier, player)
		end)
	end
end

-- Server-internal: awaiting the chapter-clear flow (Phase 10, not built yet).
function ChestService:SpawnChapterChest(cframe: CFrame)
	spawnChest("Chapter", cframe)
end

local function onArenaCleared(_arenaId: string, centerPosition: Vector3)
	spawnChest("Arena", CFrame.new(centerPosition))
end

local function onEnemyDefeated(target: Model, _player: Player?)
	if target:GetAttribute("Role") ~= "Boss" then
		return
	end
	local rootPart = target:FindFirstChild("HumanoidRootPart") :: BasePart?
	if rootPart then
		spawnChest("Boss", rootPart.CFrame)
	end
end

local function onLootRoomTouched(instance: Instance, toucher: BasePart)
	if lootRoomOpened[instance] then
		return
	end
	local character = toucher.Parent
	local player = character and Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end
	lootRoomOpened[instance] = true
	spawnChest("Vault", if instance:IsA("BasePart") then instance.CFrame else CFrame.new())
end

local function registerLootRoom(instance: Instance)
	if not instance:IsA("BasePart") then
		return
	end
	instance.Touched:Connect(function(toucher)
		onLootRoomTouched(instance, toucher)
	end)
end

function ChestService:KnitInit()
	for _, instance in CollectionService:GetTagged(LOOT_ROOM_TAG) do
		registerLootRoom(instance)
	end
	CollectionService:GetInstanceAddedSignal(LOOT_ROOM_TAG):Connect(registerLootRoom)
end

function ChestService:KnitStart()
	local ArenaGateController = Knit.GetService("ArenaGateController")
	ArenaGateController.ArenaCleared:Connect(onArenaCleared)

	local CombatService = Knit.GetService("CombatService")
	CombatService.EnemyDefeated:Connect(onEnemyDefeated)
end

return ChestService
