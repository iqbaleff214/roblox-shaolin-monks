--!strict
-- T-136 (GDD §6.2). Attack/Block/Dodge/Grab/Ultimate touch buttons. No
-- Studio mobile HUD (S-060) exists yet, so this builds its own placeholder —
-- the same pattern as every other missing-Studio-asset system here. Every
-- button is sized with a pure Offset (not Scale) component at/above
-- TapTargetSize.MINIMUM_PIXELS (T-136), so the ≥44px rule holds by
-- construction on every device rather than needing a runtime measurement
-- pass to catch a regression.
--
-- Movement ("Left virtual joystick", §6.2) is Roblox's own default touch
-- joystick (StarterPlayer's built-in PlayerModule) — already fully
-- functional with zero custom code, so this file only owns the action
-- buttons Roblox doesn't provide.
--
-- The Attack button distinguishes Light (tap) from Heavy (hold) per §6.2's
-- "Heavy Attack = Hold Attack button" — a short hold-duration timer, not a
-- second button.
--
-- Only visible while InputSchemeController (T-130) reports the "Mobile"
-- scheme, live — plugging in a touch screen or switching away from one
-- mid-session shows/hides this without a rejoin.
--
-- Buttons call InputController:FireActionPressed/FireActionReleased
-- directly (T-040's documented mobile hookup point).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)
local TapTargetSize = require(ReplicatedStorage.Shared.modules.TapTargetSize)

local UIConfig = ConfigService.UI
local BUTTON_SIZE = TapTargetSize.MINIMUM_PIXELS + 16 -- pixels of headroom above the 44px floor for comfortable thumb reach
local HEAVY_HOLD_THRESHOLD = 0.3 -- seconds; holding Attack this long triggers Heavy instead of Light

local player = Players.LocalPlayer

local MobileControlsController = Knit.CreateController({
	Name = "MobileControlsController",
})

local gui: ScreenGui

local function isTouchOrClick(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1
end

local function makeButton(parent: Instance, name: string, position: UDim2, anchorPoint: Vector2, color: Color3, text: string): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.fromOffset(BUTTON_SIZE, BUTTON_SIZE)
	button.Position = position
	button.AnchorPoint = anchorPoint
	button.BackgroundColor3 = color
	button.BackgroundTransparency = 0.2
	button.TextColor3 = UIConfig.Colors.Text
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.Parent = parent
	return button
end

local function bindTapButton(button: TextButton, action: string)
	local InputController = Knit.GetController("InputController")
	button.InputBegan:Connect(function(input: InputObject)
		if isTouchOrClick(input) then
			InputController:FireActionPressed(action)
			InputController:FireActionReleased(action)
		end
	end)
end

local function bindHoldButton(button: TextButton, action: string)
	local InputController = Knit.GetController("InputController")
	button.InputBegan:Connect(function(input: InputObject)
		if isTouchOrClick(input) then
			InputController:FireActionPressed(action)
		end
	end)
	button.InputEnded:Connect(function(input: InputObject)
		if isTouchOrClick(input) then
			InputController:FireActionReleased(action)
		end
	end)
end

local function bindAttackButton(button: TextButton)
	local InputController = Knit.GetController("InputController")
	local pressActive = false
	local firedHeavy = false

	button.InputBegan:Connect(function(input: InputObject)
		if not isTouchOrClick(input) then
			return
		end
		pressActive = true
		firedHeavy = false
		task.delay(HEAVY_HOLD_THRESHOLD, function()
			if pressActive then
				firedHeavy = true
				InputController:FireActionPressed("HeavyAttack")
			end
		end)
	end)

	button.InputEnded:Connect(function(input: InputObject)
		if not isTouchOrClick(input) or not pressActive then
			return
		end
		pressActive = false
		if firedHeavy then
			InputController:FireActionReleased("HeavyAttack")
		else
			InputController:FireActionPressed("LightAttack")
			InputController:FireActionReleased("LightAttack")
		end
	end)
end

local function buildControls()
	gui = Instance.new("ScreenGui")
	gui.Name = "MobileControls"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Enabled = false

	local attackButton = makeButton(gui, "AttackButton", UDim2.new(1, -20, 1, -20), Vector2.new(1, 1), UIConfig.Colors.Primary, "Attack")
	bindAttackButton(attackButton)

	local ultimateButton = makeButton(gui, "UltimateButton", UDim2.new(1, -20, 1, -20 - BUTTON_SIZE - 16), Vector2.new(1, 1), UIConfig.Colors.Secondary, "Ult")
	bindTapButton(ultimateButton, "Ultimate")

	local grabButton = makeButton(gui, "GrabButton", UDim2.new(1, -20 - BUTTON_SIZE - 16, 1, -20), Vector2.new(1, 1), UIConfig.Colors.TextMuted, "Grab")
	bindTapButton(grabButton, "Grab")

	local dodgeButton = makeButton(gui, "DodgeButton", UDim2.new(1, -20 - BUTTON_SIZE - 16, 1, -20 - BUTTON_SIZE - 16), Vector2.new(1, 1), UIConfig.Colors.TextMuted, "Dodge")
	bindTapButton(dodgeButton, "Dodge")

	local shieldButton = makeButton(gui, "ShieldButton", UDim2.new(1, -20 - (BUTTON_SIZE + 16) * 2, 1, -20), Vector2.new(1, 1), UIConfig.Colors.Success, "Shield")
	bindHoldButton(shieldButton, "Block")

	gui.Parent = player:WaitForChild("PlayerGui")
end

function MobileControlsController:KnitStart()
	buildControls()

	local InputSchemeController = Knit.GetController("InputSchemeController")
	gui.Enabled = InputSchemeController:GetCurrentScheme() == "Mobile"
	InputSchemeController.SchemeChanged:Connect(function(scheme: string)
		gui.Enabled = scheme == "Mobile"
	end)
end

function MobileControlsController:KnitInit() end

return MobileControlsController
