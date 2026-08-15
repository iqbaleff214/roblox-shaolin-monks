-- T-082 (GDD §5.3). Resolves a cosmetic's Rarity string directly into its
-- VFX preset (color + glow intensity + particle density) — the ONLY place
-- that interprets Rarity for visual purposes. No separate "is legendary" (or
-- any other tier) flag exists anywhere in this codebase to drift out of
-- sync with an item's actual Rarity field, which is exactly what T-082's
-- DoD requires.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)

local UIConfig = ConfigService.UI

local RarityVisualPreset = {}

export type Preset = {
	Color: Color3,
	GlowIntensity: number,
	ParticleDensity: number,
}

function RarityVisualPreset.resolve(rarity: string): Preset
	local tier = UIConfig.RarityTiers[rarity] or UIConfig.RarityTiers.Common
	local color = UIConfig.Colors["Rarity" .. rarity] or UIConfig.Colors.RarityCommon
	return {
		Color = color,
		GlowIntensity = tier.GlowIntensity,
		ParticleDensity = tier.ParticleDensity,
	}
end

return RarityVisualPreset
