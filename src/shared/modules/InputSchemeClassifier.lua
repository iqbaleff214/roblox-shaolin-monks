-- T-130 (GDD §6). Pure classification of a raw `Enum.UserInputType` into one
-- of the three control schemes. Takes the value as an explicit argument
-- (rather than reading `UserInputService.LastInputType` itself) so it stays
-- testable without any live input device.

local InputSchemeClassifier = {}

local MOBILE_TYPES: { [Enum.UserInputType]: boolean } = {
	[Enum.UserInputType.Touch] = true,
}

local CONSOLE_TYPES: { [Enum.UserInputType]: boolean } = {
	[Enum.UserInputType.Gamepad1] = true,
	[Enum.UserInputType.Gamepad2] = true,
	[Enum.UserInputType.Gamepad3] = true,
	[Enum.UserInputType.Gamepad4] = true,
	[Enum.UserInputType.Gamepad5] = true,
	[Enum.UserInputType.Gamepad6] = true,
	[Enum.UserInputType.Gamepad7] = true,
	[Enum.UserInputType.Gamepad8] = true,
}

-- Anything not Touch/Gamepad (Keyboard, MouseButtonX, MouseWheel,
-- MouseMovement, Focus, TextInput, ...) is PC.
function InputSchemeClassifier.classify(lastInputType: Enum.UserInputType): string
	if MOBILE_TYPES[lastInputType] then
		return "Mobile"
	elseif CONSOLE_TYPES[lastInputType] then
		return "Console"
	end
	return "PC"
end

return InputSchemeClassifier
