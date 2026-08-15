-- T-072 (GDD §5.2, §3.6). Pure geometry for the 3 Ultimate area shapes.
-- Deliberately has no idea what an "Ultimate" or "damage" is — it only
-- answers "is this point within this shape" — which is what keeps
-- UltimateService's damage/AoE resolution free of any cosmetic concerns.

local AreaOfEffectShape = {}

export type Shape = "Circle" | "Cone" | "Line"

local DEFAULT_CONE_ANGLE = 90 -- degrees; used only if a Cone Ultimate omits ConeAngle
local DEFAULT_LINE_WIDTH = 6 -- studs; used only if a Line Ultimate omits LineWidth

-- `forward` must be a unit vector. `radius` is the shape's reach (circle
-- radius, cone reach, or line length). `coneAngleDegrees`/`lineWidth` are
-- shape-specific and ignored for the other two shapes.
function AreaOfEffectShape.isWithin(
	shape: Shape,
	origin: Vector3,
	forward: Vector3,
	targetPosition: Vector3,
	radius: number,
	coneAngleDegrees: number?,
	lineWidth: number?
): boolean
	local offset = targetPosition - origin
	local distance = offset.Magnitude

	if shape == "Circle" then
		return distance <= radius
	elseif shape == "Cone" then
		if distance > radius then
			return false
		end
		if distance == 0 then
			return true -- exactly at the origin; inside any cone
		end
		local halfAngleCos = math.cos(math.rad((coneAngleDegrees or DEFAULT_CONE_ANGLE) / 2))
		return forward:Dot(offset.Unit) >= halfAngleCos
	elseif shape == "Line" then
		local width = lineWidth or DEFAULT_LINE_WIDTH
		local t = math.clamp(forward:Dot(offset), 0, radius)
		local closestPointOnLine = origin + forward * t
		return (targetPosition - closestPointOnLine).Magnitude <= width
	end

	return false
end

return AreaOfEffectShape
