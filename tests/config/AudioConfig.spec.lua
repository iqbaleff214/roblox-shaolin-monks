local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AudioConfig = require(ReplicatedStorage.Shared.config.AudioConfig)
local ChapterConfig = require(ReplicatedStorage.Shared.config.ChapterConfig)

-- Every SFX event named in the GDD §16 table.
local EXPECTED_SFX = {
	"LightAttack",
	"HeavyAttack",
	"Block",
	"PerfectParry",
	"DodgeRoll",
	"FinishingMove",
	"ContainerBreakWood",
	"ContainerBreakClay",
	"ContainerBreakChest",
	"EnemyHit",
	"EnemyDeath",
	"BossPhaseTransition",
	"UltimateActivation",
	"ChiMeterFull",
	"ChapterComplete",
	"UIClick",
}

return function()
	describe("AudioConfig", function()
		it("should define every SFX event listed in GDD §16", function()
			for _, key in EXPECTED_SFX do
				local entry = AudioConfig.SFX[key]
				expect(entry).to.be.a("table")
				expect(entry.Id).never.to.equal(nil)
				expect(entry.Volume).to.be.a("number")
			end
		end)

		it("should define the Lobby music loop", function()
			expect(AudioConfig.Music.Lobby).to.be.a("table")
			expect(AudioConfig.Music.Lobby.Looped).to.equal(true)
		end)

		it("should give every ChapterConfig chapter a Combat+Exploration music pair and an Ambient loop (§16)", function()
			for _, chapter in ChapterConfig do
				local music = AudioConfig.Music[chapter.Id]
				expect(music).to.be.a("table")
				expect(music.Combat).to.be.a("table")
				expect(music.Exploration).to.be.a("table")
				expect(music.Combat.Looped).to.equal(true)
				expect(music.Exploration.Looped).to.equal(true)

				local ambient = AudioConfig.Ambient[chapter.Id]
				expect(ambient).to.be.a("table")
				expect(ambient.Looped).to.equal(true)
			end
		end)

		it("should define a positive MusicCrossfadeDuration (T-140)", function()
			expect(AudioConfig.MusicCrossfadeDuration > 0).to.equal(true)
		end)

		it("should not define music/ambient for a chapter Id that doesn't exist in ChapterConfig (drift guard)", function()
			local validIds = {}
			for _, chapter in ChapterConfig do
				validIds[chapter.Id] = true
			end
			for chapterId in AudioConfig.Music do
				if chapterId ~= "Lobby" then
					expect(validIds[chapterId]).to.equal(true)
				end
			end
			for chapterId in AudioConfig.Ambient do
				expect(validIds[chapterId]).to.equal(true)
			end
		end)
	end)
end
