--!strict
-- T-127 (GDD §12.5). Host-configurable overrides for a genuine Roblox
-- Private Server (a player-purchased persistent server —
-- `game.PrivateServerOwnerId ~= 0`), distinct from T-121's automatic
-- per-party reserved battlefield instances (which also carry a
-- PrivateServerId under the hood, but have PrivateServerOwnerId == 0 since
-- no player owns them). Only the server's owner may set overrides.
--
-- `IsOverridden` is the enforcement point: LeaderboardService (T-095) checks
-- it before every submission and skips entirely when true, so an overridden
-- run never silently counts toward weekly leaderboards (§12.5's explicit
-- requirement). It never affects public matchmaking pools either, since a
-- private server was never part of one to begin with.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)

local ChapterConfig = ConfigService.Chapter

local VALID_DIFFICULTY_TIERS: { [string]: boolean } = {}
for _, chapter in ChapterConfig do
	VALID_DIFFICULTY_TIERS[chapter.DifficultyTier] = true
end

local PrivateServerSettingsService = Knit.CreateService({
	Name = "PrivateServerSettingsService",
	Client = {},
})

local chapterOverride: string? = nil
local difficultyOverride: string? = nil
local mirrorMatchEnabled = false

local function isPrivateServer(): boolean
	return game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0
end

local function isOwner(player: Player): boolean
	return isPrivateServer() and player.UserId == game.PrivateServerOwnerId
end

function PrivateServerSettingsService.Client:RequestSetChapterOverride(player: Player, chapterId: string?): boolean
	if not isOwner(player) then
		return false
	end
	if chapterId ~= nil then
		local exists = false
		for _, chapter in ChapterConfig do
			if chapter.Id == chapterId then
				exists = true
				break
			end
		end
		if not exists then
			return false
		end
	end
	chapterOverride = chapterId
	return true
end

function PrivateServerSettingsService.Client:RequestSetDifficultyOverride(player: Player, tier: string?): boolean
	if not isOwner(player) then
		return false
	end
	if tier ~= nil and not VALID_DIFFICULTY_TIERS[tier] then
		return false
	end
	difficultyOverride = tier
	return true
end

function PrivateServerSettingsService.Client:RequestSetMirrorMatchEnabled(player: Player, enabled: boolean): boolean
	if not isOwner(player) then
		return false
	end
	mirrorMatchEnabled = enabled
	return true
end

function PrivateServerSettingsService.Client:GetSettings(_player: Player)
	return {
		IsPrivateServer = isPrivateServer(),
		ChapterOverride = chapterOverride,
		DifficultyOverride = difficultyOverride,
		MirrorMatchEnabled = mirrorMatchEnabled,
	}
end

-- Server-internal: true whenever ANY override is active in this private
-- server — the single check LeaderboardService (T-095) guards submission with.
function PrivateServerSettingsService:IsOverridden(): boolean
	return isPrivateServer() and (chapterOverride ~= nil or difficultyOverride ~= nil or mirrorMatchEnabled)
end

return PrivateServerSettingsService
