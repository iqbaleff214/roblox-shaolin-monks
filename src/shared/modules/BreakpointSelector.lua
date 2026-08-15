-- T-132 (GDD §15.2). Pure breakpoint selection given a viewport width and
-- UIConfig's Breakpoints table — no Roblox service dependency, so it's
-- testable at every representative viewport size without a live Camera.

local BreakpointSelector = {}

export type Breakpoints = { Desktop: number, Tablet: number, Portrait: number }

function BreakpointSelector.select(viewportWidth: number, breakpoints: Breakpoints): string
	if viewportWidth >= breakpoints.Desktop then
		return "Desktop"
	elseif viewportWidth >= breakpoints.Tablet then
		return "Tablet"
	end
	return "Portrait"
end

return BreakpointSelector
