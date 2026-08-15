--!strict
-- T-066 (GDD §17.4). Object-pools enemy Models per Role so repeated arena
-- clears (Practice Mode replay, §7.2) don't churn Instance.new/Destroy.
--
-- Template lookup: `ServerStorage.EnemyTemplates.<Role>` — Studio drops real
-- rigs there (S-030). Until then, `Acquire` falls back to a simple
-- placeholder Model (Humanoid + a couple of Parts) so EnemyController and
-- everything downstream is fully functional and testable today, the same
-- pragmatic stand-in already used for WeaponPickupService's pickup items.

local ServerStorage = game:GetService("ServerStorage")
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local EnemyPoolService = Knit.CreateService({
	Name = "EnemyPoolService",
})

local pools: { [string]: { Model } } = {}
local poolFolder: Folder

local function getTemplate(role: string): Model?
	local templatesFolder = ServerStorage:FindFirstChild("EnemyTemplates")
	local template = templatesFolder and templatesFolder:FindFirstChild(role)
	if template and template:IsA("Model") then
		return template
	end
	return nil
end

local function createPlaceholderEnemy(role: string): Model
	local model = Instance.new("Model")
	model.Name = role

	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(2, 2, 1)
	rootPart.Transparency = 1
	rootPart.CanCollide = false
	rootPart.Anchored = false
	rootPart.Parent = model

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(2, 4, 1)
	body.Color = Color3.fromRGB(150, 40, 40)
	body.CanCollide = true
	body.Parent = model

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = rootPart
	weld.Part1 = body
	weld.Parent = rootPart
	body.CFrame = rootPart.CFrame

	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = model

	model.PrimaryPart = rootPart
	return model
end

function EnemyPoolService:Acquire(role: string, cframe: CFrame): Model
	local pool = pools[role]
	local model: Model
	if pool and #pool > 0 then
		model = table.remove(pool) :: Model
	else
		local template = getTemplate(role)
		model = if template then template:Clone() else createPlaceholderEnemy(role)
	end

	model.Parent = workspace
	if model.PrimaryPart then
		model:PivotTo(cframe)
	end
	return model
end

function EnemyPoolService:Release(role: string, model: Model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = humanoid.MaxHealth
	end
	model.Parent = poolFolder
	if not pools[role] then
		pools[role] = {}
	end
	table.insert(pools[role], model)
end

function EnemyPoolService:KnitInit()
	poolFolder = Instance.new("Folder")
	poolFolder.Name = "EnemyPool"
	poolFolder.Parent = ServerStorage
end

return EnemyPoolService
