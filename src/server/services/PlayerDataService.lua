--!strict
-- T-160/161/162/163 (GDD §17.3). The single code path that touches the
-- per-player profile DataStore (level, XP, Coins, Jade, inventory, skill
-- tree, chapter progress, quest progress, mastery stars, streak, Battle
-- Pass tier). This is narrower than "the only thing in this codebase that
-- ever calls DataStoreService" — LeaderboardService's OrderedDataStores
-- (public scores), JadeProductService's receipt-idempotency store, and
-- SettingsService's settings store are each their own self-contained
-- concern with a different purpose and a different key space; §17.3's list
-- is specifically the player PROFILE, which is this file's job alone.
--
-- `GetProfile` returns the SAME mutable table for a player every time,
-- created immediately (safe defaults) and updated *in place* once the real
-- DataStore load resolves — so a consumer that calls it before loading
-- finishes never gets nil, and automatically sees the loaded values the
-- moment they land, with no polling or callback needed.
--
-- T-162: `Save` tries the primary store, retrying once with an exponential
-- backoff (DataStoreRetry, pure); two consecutive failures fall through to
-- a backup store instead of a third primary attempt, logged for
-- reconciliation.
-- T-163: every load runs through PlayerProfileMigration (pure), so a save
-- from an older schema version never errors — missing fields get their
-- safe default and persist for real on the next save.
--
-- T-161 auto-save: PlayerRemoving (final safety net) and
-- ArenaGateController.ArenaCleared (the closest concrete "meaningful
-- progress" checkpoint that exists today — Phase 10's chapter-clear/
-- lobby-return flows aren't built, so `SaveOnChapterComplete`/
-- `SaveOnLobbyReturn` are real, ready methods awaiting those callers, the
-- same forward-dependency seam used throughout this codebase).
--
-- Consumer integration: CurrencyService and ProgressionService (this same
-- phase) hydrate from and persist to `GetProfile(player).Coins/Jade` and
-- `.Level/.TotalXP` — the reference pattern for the rest of §17.3's list.
-- InventoryService/SkillTreeService/QuestService/StreakService/
-- MasteryService/BattlePassService each already have a matching profile
-- field (Inventory/SkillTree/ChapterProgress/QuestProgress/MasteryStars/
-- LoginStreak+LastLoginPeriodId/BattlePassTierXP+BattlePassClaimed) ready
-- for the same hydrate-on-create + sync-after-mutate treatment.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local DataStoreRetry = require(ReplicatedStorage.Shared.modules.DataStoreRetry)
local PlayerProfileMigration = require(ReplicatedStorage.Shared.modules.PlayerProfileMigration)

local PRIMARY_STORE_NAME = "SMA_PlayerProfiles"
local BACKUP_STORE_NAME = "SMA_PlayerProfiles_Backup"
local MAX_PRIMARY_ATTEMPTS = 2
local RETRY_BASE_DELAY = 1 -- seconds
local RETRY_MAX_DELAY = 10 -- seconds
local AUTOSAVE_INTERVAL = 300 -- seconds; periodic defensive save on top of the event-driven hooks

local primaryStore = DataStoreService:GetDataStore(PRIMARY_STORE_NAME)
local backupStore = DataStoreService:GetDataStore(BACKUP_STORE_NAME)

local PlayerDataService = Knit.CreateService({
	Name = "PlayerDataService",
})

local profiles: { [Player]: PlayerProfileMigration.PlayerProfile } = {}

local function keyFor(player: Player): string
	return tostring(player.UserId)
end

function PlayerDataService:GetProfile(player: Player): PlayerProfileMigration.PlayerProfile
	local profile = profiles[player]
	if not profile then
		profile = PlayerProfileMigration.migrate(nil)
		profiles[player] = profile
	end
	return profile
end

local function loadProfile(player: Player)
	local profile = PlayerDataService:GetProfile(player) -- ensures a default exists immediately
	local key = keyFor(player)

	local ok, saved = pcall(function()
		return primaryStore:GetAsync(key)
	end)
	if not ok then
		warn(`[PlayerDataService] load failed for {player.Name}, using defaults this session: {tostring(saved)}`)
	end

	local migrated = PlayerProfileMigration.migrate(if ok then saved else nil)
	-- Mutate the already-published table in place, so anything that called
	-- GetProfile before this finished sees the real values automatically.
	for k, v in migrated :: { [string]: any } do
		(profile :: { [string]: any })[k] = v
	end
end

-- Server-internal: real save-now. Retries once on the primary store with
-- backoff; two consecutive failures fall through to the backup store.
function PlayerDataService:Save(player: Player): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	local key = keyFor(player)

	for attempt = 1, MAX_PRIMARY_ATTEMPTS do
		local ok = pcall(function()
			primaryStore:SetAsync(key, profile)
		end)
		if ok then
			return true
		end
		if attempt < MAX_PRIMARY_ATTEMPTS then
			task.wait(DataStoreRetry.computeBackoffDelay(attempt, RETRY_BASE_DELAY, RETRY_MAX_DELAY))
		end
	end

	local backupOk = pcall(function()
		backupStore:SetAsync(key, profile)
	end)
	if backupOk then
		warn(`[PlayerDataService] primary save failed {MAX_PRIMARY_ATTEMPTS}x for {player.Name}; wrote to backup store for reconciliation`)
	else
		warn(`[PlayerDataService] primary AND backup save failed for {player.Name}; data not persisted this attempt`)
	end
	return backupOk
end

-- Real, ready seams awaiting their concrete triggers (see file header).
function PlayerDataService:SaveOnChapterComplete(player: Player)
	self:Save(player)
end

function PlayerDataService:SaveOnLobbyReturn(player: Player)
	self:Save(player)
end

function PlayerDataService:KnitInit()
	for _, player in Players:GetPlayers() do
		task.spawn(loadProfile, player)
	end
	Players.PlayerAdded:Connect(function(player)
		task.spawn(loadProfile, player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:Save(player)
		profiles[player] = nil
	end)
end

function PlayerDataService:KnitStart()
	local ArenaGateController = Knit.GetService("ArenaGateController")
	ArenaGateController.ArenaCleared:Connect(function(_arenaId: string, _centerPosition: Vector3)
		for player in profiles do
			task.spawn(function()
				self:Save(player)
			end)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for player in profiles do
				task.spawn(function()
					self:Save(player)
				end)
			end
		end
	end)
end

return PlayerDataService
