--!strict
-- T-133 (GDD §15.3). Client menu flow: builds one minimal placeholder Frame
-- per stage (no Studio menu Guis, S-062, exist yet — the same placeholder
-- pattern used throughout this codebase) and drives visibility from the
-- pure MenuFlowStateMachine (T-133). Every screen except Lobby gets a Back
-- button wired to `stateMachine:back()`, satisfying "no dead-end screen" by
-- construction — Lobby has no Back button since it's already the root.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)
local MenuFlowStateMachine = require(ReplicatedStorage.Shared.modules.MenuFlowStateMachine)

local UIConfig = ConfigService.UI
local player = Players.LocalPlayer

local MenuFlowController = Knit.CreateController({
	Name = "MenuFlowController",
})

MenuFlowController.StateChanged = Signal.new() -- (state: string)

local stateMachine = MenuFlowStateMachine.new()
local framesByState: { [string]: Frame } = {}

local function showCurrentState()
	local current = stateMachine:current()
	for state, frame in framesByState do
		frame.Visible = state == current
	end
	MenuFlowController.StateChanged:Fire(current)
end

local function buildScreen(gui: ScreenGui, state: string)
	local frame = Instance.new("Frame")
	frame.Name = state
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = UIConfig.Colors.Background
	frame.Visible = false
	frame.Parent = gui

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.fromScale(1, 0.1)
	title.BackgroundTransparency = 1
	title.TextColor3 = UIConfig.Colors.Text
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Text = state
	title.Parent = frame

	if state ~= "Lobby" then
		local backButton = Instance.new("TextButton")
		backButton.Name = "BackButton"
		backButton.Size = UDim2.fromScale(0.15, 0.06)
		backButton.Position = UDim2.fromOffset(20, 20)
		backButton.BackgroundColor3 = UIConfig.Colors.Secondary
		backButton.TextColor3 = UIConfig.Colors.Background
		backButton.TextScaled = true
		backButton.Font = Enum.Font.GothamBold
		backButton.Text = "Back"
		backButton.Parent = frame

		backButton.Activated:Connect(function()
			if stateMachine:back() then
				showCurrentState()
			end
		end)
	end

	if state ~= "Load" then
		local nextButton = Instance.new("TextButton")
		nextButton.Name = "NextButton"
		nextButton.Size = UDim2.fromScale(0.15, 0.06)
		nextButton.Position = UDim2.new(1, -20, 0, 20)
		nextButton.AnchorPoint = Vector2.new(1, 0)
		nextButton.BackgroundColor3 = UIConfig.Colors.Primary
		nextButton.TextColor3 = UIConfig.Colors.Text
		nextButton.TextScaled = true
		nextButton.Font = Enum.Font.GothamBold
		nextButton.Text = "Next"
		nextButton.Parent = frame

		nextButton.Activated:Connect(function()
			if stateMachine:advance() then
				showCurrentState()
			end
		end)
	end

	framesByState[state] = frame
end

function MenuFlowController:GetCurrentState(): string
	return stateMachine:current()
end

function MenuFlowController:GoToState(state: string): boolean
	local ok = stateMachine:goTo(state)
	if ok then
		showCurrentState()
	end
	return ok
end

function MenuFlowController:KnitStart()
	local gui = Instance.new("ScreenGui")
	gui.Name = "MenuFlow"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	for _, state in MenuFlowStateMachine.ORDER do
		buildScreen(gui, state)
	end

	gui.Parent = player:WaitForChild("PlayerGui")
	showCurrentState()
end

function MenuFlowController:KnitInit() end

return MenuFlowController
