-- T-091 (GDD §9.2). Pure max-rank rule for Skill Tree nodes: the two
-- capped-stat nodes (HealthGrowth/ChiGrowth) may be purchased up to
-- ProgressionConfig.StatGrowth.MaxRankLevel times (the "reaches its ceiling
-- by Level 30" rule); every other node is a single, one-time unlock.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProgressionConfig = require(ReplicatedStorage.Shared.config.ProgressionConfig)

local SkillNodeRules = {}

local STAT_GROWTH_NODES = { HealthGrowth = true, ChiGrowth = true }

function SkillNodeRules.maxRank(node: string): number
	if STAT_GROWTH_NODES[node] then
		return ProgressionConfig.StatGrowth.MaxRankLevel
	end
	return 1
end

function SkillNodeRules.canPurchase(node: string, currentRank: number): boolean
	return currentRank < SkillNodeRules.maxRank(node)
end

return SkillNodeRules
