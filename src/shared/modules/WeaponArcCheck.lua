-- T-100/T-101 (GDD §3.2, §3.8). Pure weapon-arc/range geometry check,
-- extracted so it's shared between CombatService's enemy hit detection and
-- DestructibleContainerService's container hit detection instead of being
-- duplicated. Vector3-only math — no Roblox service dependency.

local WeaponArcCheck = {}

function WeaponArcCheck.isWithinArc(attackerPosition: Vector3, attackerLookVector: Vector3, targetPosition: Vector3, range: number, arcDegrees: number): boolean
	local offset = targetPosition - attackerPosition
	local distance = offset.Magnitude
	if distance > range or distance <= 0 then
		return false
	end

	local halfArcCos = math.cos(math.rad(arcDegrees / 2))
	local facingDot = attackerLookVector:Dot(offset.Unit)
	return facingDot >= halfArcCos
end

return WeaponArcCheck
