-- T-064 (GDD §4.3, §12.2). Documented wave-scaling formula — not ad hoc
-- per-arena tuning, per the DoD. Two knobs: extra enemy count for larger
-- parties, and an effective-HP multiplier so a bigger party doesn't trivialize
-- a wave sized for one player. ArenaGateController calls this with the
-- number of players currently inside the sealed arena; T-123 (Phase 10, not
-- built yet) will eventually feed it real Party data instead — same input
-- shape, no change needed here.

local WaveScaler = {}

-- +1 enemy per 2 players beyond solo (rounded down), so a full 4-player
-- party sees meaningfully more targets without every single extra player
-- adding a full enemy.
function WaveScaler.scaleEnemyCount(baseCount: number, partySize: number): number
	local clampedPartySize = math.max(partySize, 1)
	return baseCount + math.floor((clampedPartySize - 1) / 2)
end

-- Each additional player scales the effective HP pool so total time-to-kill
-- per wave stays comparable solo through full party, per the DoD's "comparable
-- per-player difficulty curve" requirement.
function WaveScaler.healthMultiplier(partySize: number): number
	local clampedPartySize = math.max(partySize, 1)
	return 1 + (clampedPartySize - 1) * 0.4
end

return WaveScaler
