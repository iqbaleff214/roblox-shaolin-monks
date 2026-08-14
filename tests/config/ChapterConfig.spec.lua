local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ChapterConfig = require(ReplicatedStorage.Shared.config.ChapterConfig)

local VALID_TIERS = {
	Novice = true,
	Adept = true,
	Veteran = true,
	Master = true,
}

return function()
	describe("ChapterConfig", function()
		it("should define exactly 8 chapters per §8.1", function()
			expect(#ChapterConfig).to.equal(8)
		end)

		it("should give every chapter a valid difficulty tier from §8.3", function()
			for _, chapter in ChapterConfig do
				expect(VALID_TIERS[chapter.DifficultyTier]).to.equal(true)
			end
		end)

		it("should keep ArenaCount within the 3-5 range from §8.1", function()
			for _, chapter in ChapterConfig do
				expect(chapter.ArenaCount >= 3).to.equal(true)
				expect(chapter.ArenaCount <= 5).to.equal(true)
			end
		end)

		it("should never let a later chapter unlock at a lower level than an earlier one", function()
			local previousGate = -1
			for _, chapter in ChapterConfig do
				expect(chapter.LevelGate >= previousGate).to.equal(true)
				previousGate = chapter.LevelGate
			end
		end)

		it("should give every chapter a unique Id, Faction, and BossId", function()
			local seenIds, seenBosses = {}, {}
			for _, chapter in ChapterConfig do
				expect(chapter.Id).to.be.a("string")
				expect(seenIds[chapter.Id]).to.equal(nil)
				seenIds[chapter.Id] = true

				expect(chapter.BossId).to.be.a("string")
				expect(seenBosses[chapter.BossId]).to.equal(nil)
				seenBosses[chapter.BossId] = true

				expect(chapter.Faction).to.be.a("string")
			end
		end)

		it("should end on Warlord's Throne with the final boss Nezhar (§1, §4.6)", function()
			local finalChapter = ChapterConfig[#ChapterConfig]
			expect(finalChapter.Id).to.equal("WarlordsThrone")
			expect(finalChapter.BossId).to.equal("Nezhar")
		end)
	end)
end
