-- T-040 (GDD §6). Raw PC/Console input -> one of 9 logical combat actions.
-- This is the ONLY place raw `KeyCode`/`UserInputType` values may appear in
-- combat-adjacent code; everything downstream (CombatController, etc.) only
-- ever sees action names.
--
-- Mobile isn't representable here: GDD §6.2's controls are named GUI buttons
-- (Attack/Shield/Dodge/Grab/Ultimate buttons), not fixed input identifiers —
-- those buttons don't exist until Phase 11 (T-136). Mobile buttons call
-- `InputController:FireAction(actionName)` directly instead of going through
-- this resolver; when T-136 lands, it just needs to call that same method.
--
-- `resolve` takes plain KeyCode/UserInputType values rather than a live
-- InputObject (which has no public constructor and so can't be unit-tested)
-- so this table — and the resolution logic — stays fully testable.

local InputActionMap = {}

InputActionMap.Actions = {
	"LightAttack",
	"HeavyAttack",
	"Block",
	"Dodge",
	"Grab",
	"Interact",
	"ThrowWeapon",
	"Ultimate",
	"LockOn",
}

-- §6.1 PC (Mouse + Keyboard)
InputActionMap.PC = {
	[Enum.UserInputType.MouseButton1] = "LightAttack",
	[Enum.UserInputType.MouseButton2] = "HeavyAttack",
	[Enum.KeyCode.LeftShift] = "Block",
	[Enum.KeyCode.RightShift] = "Block",
	[Enum.KeyCode.LeftControl] = "Dodge",
	[Enum.KeyCode.F] = "Grab",
	[Enum.KeyCode.E] = "Interact",
	[Enum.KeyCode.Q] = "ThrowWeapon",
	[Enum.KeyCode.R] = "Ultimate",
	[Enum.UserInputType.MouseButton3] = "LockOn",
}

-- §6.3 Console (Gamepad)
InputActionMap.Console = {
	[Enum.KeyCode.ButtonX] = "LightAttack",
	[Enum.KeyCode.ButtonY] = "HeavyAttack",
	[Enum.KeyCode.ButtonL2] = "Block",
	[Enum.KeyCode.ButtonB] = "Dodge",
	[Enum.KeyCode.ButtonR1] = "Grab",
	[Enum.KeyCode.ButtonA] = "Interact",
	[Enum.KeyCode.ButtonL1] = "ThrowWeapon",
	[Enum.KeyCode.ButtonR2] = "Ultimate",
	[Enum.KeyCode.ButtonR3] = "LockOn",
}

-- Resolves a raw input pair to a logical action name, or nil if unmapped.
-- KeyCode is checked first (keyboard/gamepad); UserInputType is the
-- fallback for device-level inputs that have no KeyCode (mouse buttons).
function InputActionMap.resolve(keyCode: Enum.KeyCode, userInputType: Enum.UserInputType): string?
	if keyCode ~= Enum.KeyCode.None then
		local action = InputActionMap.PC[keyCode] or InputActionMap.Console[keyCode]
		if action then
			return action
		end
	end
	return InputActionMap.PC[userInputType] or InputActionMap.Console[userInputType]
end

return InputActionMap
