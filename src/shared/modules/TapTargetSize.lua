-- T-136 (GDD §6.2). Pure ≥44px tap-target validation. Takes measured pixel
-- dimensions as explicit arguments rather than reading a live GuiObject's
-- AbsoluteSize itself, so the rule is testable without rendering anything.

local TapTargetSize = {}

TapTargetSize.MINIMUM_PIXELS = 44

function TapTargetSize.meetsMinimum(widthPixels: number, heightPixels: number): boolean
	return widthPixels >= TapTargetSize.MINIMUM_PIXELS and heightPixels >= TapTargetSize.MINIMUM_PIXELS
end

return TapTargetSize
