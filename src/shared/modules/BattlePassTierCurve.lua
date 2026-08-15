-- T-115 (GDD §11.4). Pure tier-from-XP math, mirroring LevelCurve's (T-090)
-- precedent: current tier is always derived live from banked tier XP, never
-- stored separately — that's what makes retroactive premium unlocks on a
-- later purchase automatic rather than a special-cased migration.

local BattlePassTierCurve = {}

function BattlePassTierCurve.tierForXP(tierXP: number, xpPerTier: number, tierCount: number): number
	local tier = math.floor(tierXP / xpPerTier)
	return math.clamp(tier, 0, tierCount)
end

return BattlePassTierCurve
