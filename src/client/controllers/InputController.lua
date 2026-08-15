--!strict
-- T-040 (GDD §6). Sole owner of raw PC/Console input on the client: resolves
-- every `InputBegan`/`InputEnded` through InputActionMap and republishes as
-- `ActionPressed`/`ActionReleased` logical-action signals. No other client
-- script may touch `UserInputType`/`KeyCode` for combat purposes — this is
-- the seam (T-040's own DoD).
--
-- Mobile: T-136 (Phase 11) doesn't exist yet, so there are no GUI buttons to
-- wire up. `FireActionPressed`/`FireActionReleased` are the public methods a
-- future touch button calls directly on tap-down/tap-up — they feed the same
-- signals as keyboard/gamepad input, so CombatController never needs to care
-- which platform triggered an action.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local InputActionMap = require(ReplicatedStorage.Shared.modules.InputActionMap)

local InputController = Knit.CreateController({
	Name = "InputController",
})

InputController.ActionPressed = Signal.new()
InputController.ActionReleased = Signal.new()

-- Tracks which actions are currently held so FireActionPressed/Released and
-- raw-input paths can't both fire spurious duplicate press/release events
-- for the same action.
local heldActions: { [string]: boolean } = {}

local function firePressed(action: string)
	if heldActions[action] then
		return
	end
	heldActions[action] = true
	InputController.ActionPressed:Fire(action)
end

local function fireReleased(action: string)
	if not heldActions[action] then
		return
	end
	heldActions[action] = nil
	InputController.ActionReleased:Fire(action)
end

-- Public API for future touch-button GUI (T-136).
function InputController:FireActionPressed(action: string)
	firePressed(action)
end

function InputController:FireActionReleased(action: string)
	fireReleased(action)
end

function InputController:KnitStart()
	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
		if gameProcessedEvent then
			return
		end
		local action = InputActionMap.resolve(input.KeyCode, input.UserInputType)
		if action then
			firePressed(action)
		end
	end)

	UserInputService.InputEnded:Connect(function(input: InputObject, gameProcessedEvent: boolean)
		if gameProcessedEvent then
			return
		end
		local action = InputActionMap.resolve(input.KeyCode, input.UserInputType)
		if action then
			fireReleased(action)
		end
	end)
end

function InputController:KnitInit() end

return InputController
