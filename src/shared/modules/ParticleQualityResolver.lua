--!strict
-- T-181 (GDD §17.4). Pure scaling function: given a particle emitter's
-- authored (High-quality) rate and the player's current graphics-quality
-- tier, returns the rate that tier should actually emit at — proportional
-- to `UIConfig.ParticleLimits`' High/Medium/Low counts, so tuning those
-- three numbers is the only place particle density is ever adjusted.

local ParticleQualityResolver = {}

export type ParticleLimits = {
	High: number,
	Medium: number,
	Low: number,
}

function ParticleQualityResolver.resolveRate(baseRate: number, tier: string, particleLimits: ParticleLimits): number
	if particleLimits.High <= 0 then
		return 0
	end
	local tierValue = (particleLimits :: any)[tier]
	if type(tierValue) ~= "number" then
		tierValue = particleLimits.High -- unknown tier: never emit more than the authored rate
	end
	return baseRate * (tierValue / particleLimits.High)
end

return ParticleQualityResolver
