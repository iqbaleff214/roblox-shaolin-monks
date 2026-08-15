--!strict
-- T-132 (GDD §15.2). Detects viewport size/aspect ratio live via the current
-- Camera's ViewportSize and applies the correct breakpoint (desktop/tablet/
-- portrait) from UIConfig — pure selection logic lives in BreakpointSelector
-- (T-132) so it's testable without a live Camera. Respects safe-area insets
-- on notched devices via `GuiService:GetGuiInset()`.
--
-- No UI script anywhere should read a hardcoded pixel offset; every
-- consumer of `BreakpointChanged` positions itself via UIConfig.LayoutAnchors
-- / scale, matching §13.4's anchored-positioning rule.

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)
local BreakpointSelector = require(ReplicatedStorage.Shared.modules.BreakpointSelector)

local UIConfig = ConfigService.UI

local ResponsiveLayoutController = Knit.CreateController({
	Name = "ResponsiveLayoutController",
})

ResponsiveLayoutController.BreakpointChanged = Signal.new() -- (breakpoint: string)

local currentBreakpoint: string? = nil

local function getViewportWidth(): number
	local camera = Workspace.CurrentCamera
	return if camera then camera.ViewportSize.X else UIConfig.Breakpoints.Desktop
end

local function refresh()
	local breakpoint = BreakpointSelector.select(getViewportWidth(), UIConfig.Breakpoints)
	if breakpoint ~= currentBreakpoint then
		currentBreakpoint = breakpoint
		ResponsiveLayoutController.BreakpointChanged:Fire(breakpoint)
	end
end

local function watchCamera(camera: Camera)
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(refresh)
end

function ResponsiveLayoutController:GetCurrentBreakpoint(): string?
	return currentBreakpoint
end

-- (topLeftInset: Vector2, bottomRightInset: Vector2)
function ResponsiveLayoutController:GetSafeAreaInsets(): (Vector2, Vector2)
	return GuiService:GetGuiInset()
end

function ResponsiveLayoutController:KnitStart()
	refresh()
	if Workspace.CurrentCamera then
		watchCamera(Workspace.CurrentCamera)
	end
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		if Workspace.CurrentCamera then
			watchCamera(Workspace.CurrentCamera)
		end
		refresh()
	end)
end

function ResponsiveLayoutController:KnitInit() end

return ResponsiveLayoutController
