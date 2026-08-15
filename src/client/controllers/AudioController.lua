--!strict
-- T-140 (GDD §16). Client-side AudioManager:
--   * SFX playback pooling — a small reusable Sound pool per event, so
--     combo-heavy combat never spikes Instance.new for every hit.
--   * Music stem layering — combat vs exploration, swapped by the SAME
--     ArenaGateController.GateSealed/GateUnsealed signals T-131's HUD
--     expansion uses (the DoD's single source of truth for "in combat"),
--     crossfaded over AudioConfig.MusicCrossfadeDuration rather than an
--     abrupt cut.
--   * Per-chapter ambient loop switching via `SetChapter`.
--
-- Every Sound this controller creates is parented into SettingsController's
-- (T-134) MusicGroup/SfxGroup — the forward seam that controller documented
-- explicitly for this file to close. SoundGroup.Volume applies live to its
-- whole subtree continuously, so T-141's "volume changes apply to
-- already-playing sounds immediately" holds by construction with no extra
-- code here.
--
-- Policy note (T-141, §16 "no audio autoplay on the game page"): every
-- sound here is started by an explicit `:Play()` call from KnitStart or a
-- live gameplay event, never a persisted `Playing = true` on a saved
-- Instance — so nothing can play before a real player session begins.
--
-- Placeholder IDs (0, until S-070–S-072 fill them) are silently skipped
-- rather than erroring, the same convention T-200's startup check expects.
--
-- Coverage: LightAttack/HeavyAttack/UltimateActivation/FinishingMove/
-- BossPhaseTransition/ContainerBreakWood-Clay-Chest/Block/DodgeRoll/
-- ChiMeterFull/UIClick/EnemyHit/EnemyDeath are all wired to real, live
-- signals. PerfectParry and ChapterComplete have no live trigger yet (parry
-- classification is server-only and never relayed; chapter-clear is the
-- same Phase 10 flow gap noted throughout this codebase) — `PlaySfx` is
-- ready for whichever future system supplies those.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)

local AudioConfig = ConfigService.Audio
local SFX_POOL_SIZE = 4 -- concurrent instances per event before the oldest is reused

local AudioController = Knit.CreateController({
	Name = "AudioController",
})

local pitchRng = Random.new()
local sfxPools: { [string]: { Sound } } = {}
local currentChapterId: string? = nil
local currentMusicStem: Sound? = nil
local currentAmbient: Sound? = nil

local function getSfxGroup(): SoundGroup
	return Knit.GetController("SettingsController"):GetSfxSoundGroup()
end

local function getMusicGroup(): SoundGroup
	return Knit.GetController("SettingsController"):GetMusicSoundGroup()
end

-- Server-internal-style public API: plays `eventName` from AudioConfig.SFX,
-- reusing a pooled Sound instance for that event rather than always
-- creating a new one.
function AudioController:PlaySfx(eventName: string)
	local definition = AudioConfig.SFX[eventName]
	if not definition or definition.Id == 0 then
		return -- unknown event, or a placeholder ID not filled in yet
	end

	local pool = sfxPools[eventName]
	if not pool then
		pool = {}
		sfxPools[eventName] = pool
	end

	local sound: Sound? = nil
	for _, candidate in pool do
		if not candidate.IsPlaying then
			sound = candidate
			break
		end
	end
	if not sound then
		if #pool < SFX_POOL_SIZE then
			sound = Instance.new("Sound")
			sound.Parent = getSfxGroup()
			table.insert(pool, sound)
		else
			sound = pool[1] -- pool exhausted; steal the oldest rather than growing unbounded
		end
	end

	sound.SoundId = `rbxassetid://{definition.Id}`
	sound.Volume = definition.Volume
	if definition.PitchRange then
		sound.PlaybackSpeed = pitchRng:NextNumber(definition.PitchRange[1], definition.PitchRange[2])
	else
		sound.PlaybackSpeed = 1
	end
	sound:Play()
end

-- Crossfades `channel` (an upvalue cell holding the currently-playing Sound
-- for that channel) to `definition`, fading the previous one out and
-- destroying it once silent. Shared by the music-stem and ambient channels.
local function crossfade(previous: Sound?, definition: { Id: number, Volume: number, Looped: boolean }?): Sound?
	local nextSound: Sound? = nil
	if definition and definition.Id ~= 0 then
		nextSound = Instance.new("Sound")
		nextSound.SoundId = `rbxassetid://{definition.Id}`
		nextSound.Looped = definition.Looped
		nextSound.Volume = 0
		nextSound.Parent = getMusicGroup()
		nextSound:Play()
		TweenService:Create(nextSound, TweenInfo.new(AudioConfig.MusicCrossfadeDuration), { Volume = definition.Volume }):Play()
	end

	if previous then
		local fadeOut = TweenService:Create(previous, TweenInfo.new(AudioConfig.MusicCrossfadeDuration), { Volume = 0 })
		fadeOut.Completed:Connect(function()
			previous:Destroy()
		end)
		fadeOut:Play()
	end

	return nextSound
end

local function playExplorationStem()
	local music = if currentChapterId then AudioConfig.Music[currentChapterId] else AudioConfig.Music.Lobby
	local definition = if currentChapterId then music and music.Exploration else music
	currentMusicStem = crossfade(currentMusicStem, definition)
end

local function playCombatStem()
	if not currentChapterId then
		return -- no combat stem in the Lobby
	end
	local music = AudioConfig.Music[currentChapterId]
	currentMusicStem = crossfade(currentMusicStem, music and music.Combat)
end

-- Real, ready public API: switches the ambient loop and (since combat only
-- ever happens inside a chapter) resets to the exploration stem for the new
-- chapter — awaiting a live chapter-load caller (Phase 10's chapter-select/
-- teleport flow doesn't expose a client-side "current chapter" yet).
function AudioController:SetChapter(chapterId: string?)
	currentChapterId = chapterId
	currentAmbient = crossfade(currentAmbient, chapterId and AudioConfig.Ambient[chapterId])
	playExplorationStem()
end

local function bindChiMeterFull()
	local CombatService = Knit.GetService("CombatService")
	local wasFull = false
	CombatService.Chi:Observe(function(chi: number)
		local CombatConfig = ConfigService.Combat
		local isFull = chi >= CombatConfig.ChiMeter.Max
		if isFull and not wasFull then
			AudioController:PlaySfx("ChiMeterFull")
		end
		wasFull = isFull
	end)
end

local CONTAINER_SFX: { [string]: string } = {
	WoodenCrate = "ContainerBreakWood",
	ClayUrn = "ContainerBreakClay",
	SupplyBarrel = "ContainerBreakWood",
	JadeChest = "ContainerBreakChest",
}

function AudioController:KnitStart()
	playExplorationStem()

	local ArenaGateController = Knit.GetService("ArenaGateController")
	ArenaGateController.GateSealed:Connect(playCombatStem)
	ArenaGateController.GateUnsealed:Connect(playExplorationStem)

	local FeedbackFXService = Knit.GetService("FeedbackFXService")
	FeedbackFXService.FinishingMoveOverlay:Connect(function(_target: Model)
		AudioController:PlaySfx("FinishingMove")
	end)
	FeedbackFXService.BossPhaseFlash:Connect(function(_target: Model)
		AudioController:PlaySfx("BossPhaseTransition")
	end)
	FeedbackFXService.ContainerBreakPopup:Connect(function(containerType: string)
		local eventName = CONTAINER_SFX[containerType]
		if eventName then
			AudioController:PlaySfx(eventName)
		end
	end)
	FeedbackFXService.EnemyHitFX:Connect(function(_target: Model)
		AudioController:PlaySfx("EnemyHit")
	end)
	FeedbackFXService.EnemyDeathFX:Connect(function(_target: Model)
		AudioController:PlaySfx("EnemyDeath")
	end)

	local CombatController = Knit.GetController("CombatController")
	CombatController.AttackSwung:Connect(function(isHeavy: boolean)
		AudioController:PlaySfx(if isHeavy then "HeavyAttack" else "LightAttack")
	end)
	CombatController.UltimateFired:Connect(function()
		AudioController:PlaySfx("UltimateActivation")
	end)

	local InputController = Knit.GetController("InputController")
	InputController.ActionPressed:Connect(function(action: string)
		if action == "Block" then
			AudioController:PlaySfx("Block")
		elseif action == "Dodge" then
			AudioController:PlaySfx("DodgeRoll")
		end
	end)

	bindChiMeterFull()
end

function AudioController:KnitInit() end

return AudioController
