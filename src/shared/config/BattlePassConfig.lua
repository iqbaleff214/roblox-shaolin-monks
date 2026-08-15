-- GDD §11.4. 50-tier seasonal Battle Pass. Free track is always active;
-- Premium track requires GamePass ownership (MonetizationConfig.GamePasses.
-- BattlePassId). Tier XP is tracked separately from player-level XP
-- (ProgressionConfig) — leveling and pass progress never share a counter.
--
-- Reward tables are generated here (not hand-authored per tier) so 50
-- entries stay consistent and driftless; every 10th Premium tier grants a
-- Cosmetic slot instead of Coins, echoing §11.4's "exclusive weapon skin,
-- Ultimate FX..." flavor without inventing specific unbuilt item catalogs.

local TIER_COUNT = 50
local XP_PER_TIER = 200
local COSMETIC_TIER_INTERVAL = 10

local freeTrackRewards = {}
local premiumTrackRewards = {}

for tier = 1, TIER_COUNT do
	freeTrackRewards[tier] = { Type = "Coins", Amount = 50 + tier * 5 }
	premiumTrackRewards[tier] = { Type = "Coins", Amount = 100 + tier * 10 }
end

for tier = COSMETIC_TIER_INTERVAL, TIER_COUNT, COSMETIC_TIER_INTERVAL do
	premiumTrackRewards[tier] = { Type = "Cosmetic", Category = "WeaponSkin" }
end

return {
	TierCount = TIER_COUNT,
	XPPerTier = XP_PER_TIER,
	FreeTrackRewards = freeTrackRewards,
	PremiumTrackRewards = premiumTrackRewards,
}
