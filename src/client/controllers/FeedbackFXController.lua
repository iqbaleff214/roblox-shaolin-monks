--!strict
-- T-135 (GDD §15.4, §18). Client side of FeedbackFXService's (T-135) relay:
-- plays the actual freeze-frame/overlay/flash/popup effects. No Studio FX
-- assets (S-065) exist yet, so this builds its own minimal placeholder
-- ScreenGui — the same pattern as every other missing-Studio-asset system
-- in this codebase. Every timing comes from UIConfig.FeedbackTimings
-- (T-135), never hardcoded here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)

local Timings = ConfigService.UI.FeedbackTimings
local player = Players.LocalPlayer

local FeedbackFXController = Knit.CreateController({
	Name = "FeedbackFXController",
})

local flashFrame: Frame
local messageLabel: TextLabel
local messageHideThread: thread?

local function buildPlaceholderOverlay()
	local gui = Instance.new("ScreenGui")
	gui.Name = "FeedbackFX"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 10

	flashFrame = Instance.new("Frame")
	flashFrame.Name = "Flash"
	flashFrame.Size = UDim2.fromScale(1, 1)
	flashFrame.BackgroundColor3 = Color3.new(1, 1, 1)
	flashFrame.BackgroundTransparency = 1
	flashFrame.ZIndex = 10
	flashFrame.Parent = gui

	messageLabel = Instance.new("TextLabel")
	messageLabel.Name = "Message"
	messageLabel.Size = UDim2.fromScale(0.6, 0.1)
	messageLabel.Position = UDim2.fromScale(0.5, 0.25)
	messageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	messageLabel.BackgroundTransparency = 1
	messageLabel.TextColor3 = Color3.new(1, 1, 1)
	messageLabel.TextScaled = true
	messageLabel.Font = Enum.Font.GothamBold
	messageLabel.Text = ""
	messageLabel.Visible = false
	messageLabel.ZIndex = 11
	messageLabel.Parent = gui

	gui.Parent = player:WaitForChild("PlayerGui")
end

local function flash(duration: number)
	flashFrame.BackgroundTransparency = 0.5
	task.delay(duration, function()
		flashFrame.BackgroundTransparency = 1
	end)
end

local function showMessage(text: string, duration: number)
	if messageHideThread then
		task.cancel(messageHideThread)
	end
	messageLabel.Text = text
	messageLabel.Visible = true
	messageHideThread = task.delay(duration, function()
		messageLabel.Visible = false
		messageHideThread = nil
	end)
end

local function applyHitStop()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local originalWalkSpeed = humanoid.WalkSpeed
	humanoid.WalkSpeed = 0
	task.delay(Timings.HitStopDuration, function()
		if humanoid.Parent then
			humanoid.WalkSpeed = originalWalkSpeed
		end
	end)
end

function FeedbackFXController:KnitStart()
	buildPlaceholderOverlay()

	local FeedbackFXService = Knit.GetService("FeedbackFXService")
	FeedbackFXService.HitStop:Connect(function(_target: Model)
		applyHitStop()
	end)
	FeedbackFXService.FinishingMoveOverlay:Connect(function(_target: Model)
		showMessage("FINISHING MOVE", Timings.FinishingMoveOverlayDuration)
	end)
	FeedbackFXService.BossPhaseFlash:Connect(function(_target: Model)
		flash(Timings.BossPhaseFlashDuration)
	end)
	FeedbackFXService.ContainerBreakPopup:Connect(function(containerType: string)
		showMessage(containerType .. " broken!", Timings.ContainerPopupDuration)
	end)

	local SocialHookService = Knit.GetService("SocialHookService")
	SocialHookService.FlawlessBanner:Connect(function()
		showMessage("FLAWLESS!", Timings.FlawlessBannerDuration)
	end)
end

function FeedbackFXController:KnitInit() end

return FeedbackFXController
