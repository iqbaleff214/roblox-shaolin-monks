-- T-180/T-182 (GDD §17.4). Battlefield-prop LOD tuning and Workspace
-- streaming radii. Kept separate from `UIConfig` (which already owns
-- `ParticleLimits`, the per-quality-tier axis of §17.4) because these values
-- are never player-facing settings — they're fixed engine/level tuning.

return {
	LOD = {
		-- Studs from the camera at which a `LODProp`-tagged instance swaps
		-- from its `Near` (detailed) child to its `Far` (simplified) child.
		-- Overridable per-instance via a `LODDistance` attribute (S-020–S-027).
		DefaultSwapDistance = 80,
		-- How often LODController re-checks distances. Deliberately not every
		-- Heartbeat — the LOD system's own cost must be negligible (§17.4's
		-- DoD), so a coarse poll is enough for a check that only toggles
		-- decorative detail, not gameplay state.
		CheckIntervalSeconds = 0.5,
	},

	Streaming = {
		-- Workspace.StreamingMinRadius/StreamingTargetRadius (studs). Tuned
		-- so a player's immediate arena is always fully streamed in before
		-- gameplay-critical systems (gates, spawn points, containers) need
		-- it, while distant chapter geometry stays unloaded.
		MinRadius = 128,
		TargetRadius = 512,
	},
}
