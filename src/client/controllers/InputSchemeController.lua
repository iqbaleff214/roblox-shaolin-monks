--!strict
-- T-130 (GDD §6). Detects PC/Mobile/Console input live via
-- `UserInputService.LastInputType` and republishes as a single
-- `SchemeChanged` signal — the seam other controllers (T-136's mobile
-- buttons, a future on-screen prompt HUD) read instead of querying
-- UserInputService directly. Switching device mid-session (e.g. plugging in
-- a gamepad) updates `LastInputType` live, and this controller reacts to
-- that property-changed signal, so no rejoin is ever needed.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local InputSchemeClassifier = require(ReplicatedStorage.Shared.modules.InputSchemeClassifier)

local InputSchemeController = Knit.CreateController({
	Name = "InputSchemeController",
})

InputSchemeController.SchemeChanged = Signal.new() -- (scheme: string)

local currentScheme = InputSchemeClassifier.classify(UserInputService.LastInputType)

function InputSchemeController:GetCurrentScheme(): string
	return currentScheme
end

function InputSchemeController:KnitStart()
	UserInputService:GetPropertyChangedSignal("LastInputType"):Connect(function()
		local scheme = InputSchemeClassifier.classify(UserInputService.LastInputType)
		if scheme ~= currentScheme then
			currentScheme = scheme
			InputSchemeController.SchemeChanged:Fire(scheme)
		end
	end)
end

function InputSchemeController:KnitInit() end

return InputSchemeController
