--!strict
-- T-131 (GDD §15.1). Client-facing HUD logic layer: binds live HP/Chi/Combo
-- data to a ScreenGui. No Studio-built HUD (S-060) exists yet, so this
-- builds its own minimal placeholder — the same pragmatic stand-in pattern
-- used for every other missing Studio asset in this codebase (e.g.
-- EnemyPoolService's placeholder rig, ChestService's placeholder chest).
-- Swapping in a real S-060 ScreenGui later only means changing
-- `buildPlaceholderHud`'s instance construction, not this file's binding
-- logic.
--
-- HUD expansion is driven by ArenaGateController's GateSealed/GateUnsealed
-- signals (T-061 hookup) — never combat activity or a fixed timer — so the
-- HUD expands in the same frame the gate visibly seals, exactly the DoD's
-- requirement.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)
local LocaleFormat = require(ReplicatedStorage.Shared.modules.LocaleFormat)

local UIConfig = ConfigService.UI
local CombatConfig = ConfigService.Combat
local player = Players.LocalPlayer

local CombatHUDController = Knit.CreateController({
	Name = "CombatHUDController",
})

local healthBarFill: Frame
local chiBarFill: Frame
local comboLabel: TextLabel
local expandedFrame: Frame

local function buildPlaceholderHud()
	local gui = Instance.new("ScreenGui")
	gui.Name = "CombatHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	local barsFrame = Instance.new("Frame")
	barsFrame.Name = "MinimalBars"
	barsFrame.Size = UDim2.fromScale(0.25, 0.08)
	barsFrame.Position = UDim2.new(0, 20, 1, -20)
	barsFrame.AnchorPoint = Vector2.new(0, 1)
	barsFrame.BackgroundColor3 = UIConfig.Colors.Background
	barsFrame.BackgroundTransparency = 0.3
	barsFrame.BorderSizePixel = 0
	barsFrame.Parent = gui

	local healthBarBack = Instance.new("Frame")
	healthBarBack.Name = "HealthBarBack"
	healthBarBack.Size = UDim2.new(1, -10, 0.5, -5)
	healthBarBack.Position = UDim2.fromOffset(5, 5)
	healthBarBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	healthBarBack.BorderSizePixel = 0
	healthBarBack.Parent = barsFrame

	healthBarFill = Instance.new("Frame")
	healthBarFill.Name = "Fill"
	healthBarFill.Size = UDim2.fromScale(1, 1)
	healthBarFill.BackgroundColor3 = UIConfig.Colors.Danger
	healthBarFill.BorderSizePixel = 0
	healthBarFill.Parent = healthBarBack

	local chiBarBack = Instance.new("Frame")
	chiBarBack.Name = "ChiBarBack"
	chiBarBack.Size = UDim2.new(1, -10, 0.5, -5)
	chiBarBack.Position = UDim2.new(0, 5, 0.5, 0)
	chiBarBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	chiBarBack.BorderSizePixel = 0
	chiBarBack.Parent = barsFrame

	chiBarFill = Instance.new("Frame")
	chiBarFill.Name = "Fill"
	chiBarFill.Size = UDim2.fromScale(0, 1)
	chiBarFill.BackgroundColor3 = UIConfig.Colors.Secondary
	chiBarFill.BorderSizePixel = 0
	chiBarFill.Parent = chiBarBack

	comboLabel = Instance.new("TextLabel")
	comboLabel.Name = "ComboCounter"
	comboLabel.Size = UDim2.fromScale(0.2, 0.06)
	comboLabel.Position = UDim2.new(0.5, 0, 0, 20)
	comboLabel.AnchorPoint = Vector2.new(0.5, 0)
	comboLabel.BackgroundTransparency = 1
	comboLabel.TextColor3 = UIConfig.Colors.Text
	comboLabel.TextScaled = true
	comboLabel.Font = Enum.Font.GothamBold
	comboLabel.Text = ""
	comboLabel.Visible = false
	comboLabel.Parent = gui

	expandedFrame = Instance.new("Frame")
	expandedFrame.Name = "PartyFrames"
	expandedFrame.Size = UDim2.fromScale(0.3, 0.15)
	expandedFrame.Position = UDim2.new(1, -20, 0, 20)
	expandedFrame.AnchorPoint = Vector2.new(1, 0)
	expandedFrame.BackgroundTransparency = 1
	expandedFrame.Visible = false
	expandedFrame.Parent = gui

	gui.Parent = player:WaitForChild("PlayerGui")
end

local function updateHealth(humanoid: Humanoid)
	local fraction = if humanoid.MaxHealth > 0 then humanoid.Health / humanoid.MaxHealth else 0
	healthBarFill.Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1)
end

local function bindCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	updateHealth(humanoid)
	humanoid:GetPropertyChangedSignal("Health"):Connect(function()
		updateHealth(humanoid)
	end)
	humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
		updateHealth(humanoid)
	end)
end

local function updateChi(chi: number)
	local fraction = math.clamp(chi / CombatConfig.ChiMeter.Max, 0, 1)
	chiBarFill.Size = UDim2.fromScale(fraction, 1)
end

local function expandHud()
	expandedFrame.Visible = true
	comboLabel.Visible = true
end

local function collapseHud()
	expandedFrame.Visible = false
	comboLabel.Visible = false
	comboLabel.Text = ""
end

function CombatHUDController:KnitStart()
	buildPlaceholderHud()
	collapseHud()

	if player.Character then
		bindCharacter(player.Character)
	end
	player.CharacterAdded:Connect(bindCharacter)

	local CombatService = Knit.GetService("CombatService")
	CombatService.Chi:Observe(updateChi)

	local LocalizationController = Knit.GetController("LocalizationController")
	local CombatController = Knit.GetController("CombatController")
	CombatController.ComboUpdated:Connect(function(comboCount: number)
		if comboCount > 0 then
			local label = LocalizationController:Translate("hud.label.combo")
			local locale = LocalizationController:GetLocale()
			comboLabel.Text = `{label}: {LocaleFormat.formatNumber(comboCount, locale)}`
		else
			comboLabel.Text = ""
		end
	end)

	local ArenaGateController = Knit.GetService("ArenaGateController")
	ArenaGateController.GateSealed:Connect(expandHud)
	ArenaGateController.GateUnsealed:Connect(collapseHud)
end

function CombatHUDController:KnitInit() end

return CombatHUDController
