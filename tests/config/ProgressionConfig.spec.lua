local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProgressionConfig = require(ReplicatedStorage.Shared.config.ProgressionConfig)

return function()
	describe("ProgressionConfig", function()
		it("should define the §9.1 performance multipliers used for XP scaling", function()
			expect(ProgressionConfig.XP.StyleScoreMultiplier.Flawless).to.equal(2.5)
			expect(ProgressionConfig.XP.StyleScoreMultiplier.HighCombo).to.equal(2.0)
			expect(ProgressionConfig.XP.StyleScoreMultiplier.Standard).to.equal(1.0)
			expect(ProgressionConfig.XP.StyleScoreMultiplier.MultipleDeaths).to.equal(0.5)
		end)

		it("should keep the stat-growth curve monotonically non-decreasing", function()
			local previousHealth, previousChi = -1, -1
			for level = 1, 40 do
				local health = ProgressionConfig.StatGrowth.HealthBonusAtLevel(level)
				local chi = ProgressionConfig.StatGrowth.ChiBonusAtLevel(level)
				expect(health >= previousHealth).to.equal(true)
				expect(chi >= previousChi).to.equal(true)
				previousHealth, previousChi = health, chi
			end
		end)

		it("should flatten (cap) stat growth at and after Level 30 per §9.2", function()
			local capLevel = ProgressionConfig.StatGrowth.MaxRankLevel
			expect(capLevel).to.equal(30)

			local healthAtCap = ProgressionConfig.StatGrowth.HealthBonusAtLevel(capLevel)
			local chiAtCap = ProgressionConfig.StatGrowth.ChiBonusAtLevel(capLevel)

			for level = capLevel, capLevel + 10 do
				expect(ProgressionConfig.StatGrowth.HealthBonusAtLevel(level)).to.equal(healthAtCap)
				expect(ProgressionConfig.StatGrowth.ChiBonusAtLevel(level)).to.equal(chiAtCap)
			end
		end)

		it("should produce a strictly increasing XP threshold curve", function()
			local previous = -1
			for level = 1, 30 do
				local threshold = ProgressionConfig.XP.ThresholdForLevel(level)
				expect(threshold > previous).to.equal(true)
				previous = threshold
			end
		end)

		it("should define positive Skill Effect magnitudes (§9.2)", function()
			expect(ProgressionConfig.SkillEffects.DodgeCooldownReductionSeconds > 0).to.equal(true)
			expect(ProgressionConfig.SkillEffects.ParryWindowExtensionSeconds > 0).to.equal(true)
		end)

		it("should define Mastery Star thresholds and an ascending milestone list (§9.3)", function()
			local mastery = ProgressionConfig.Mastery
			expect(mastery.StyleScoreThreshold > 0).to.equal(true)
			expect(mastery.MaxDamageTakenForStar >= 0).to.equal(true)
			expect(mastery.ClearTimeThresholdSeconds > 0).to.equal(true)

			local previous = 0
			for _, total in mastery.MilestoneTotals do
				expect(total > previous).to.equal(true)
				previous = total
			end
		end)

		it("should define positive Streak tuning values (§9.5)", function()
			expect(ProgressionConfig.Streak.LoginStreakMilestoneDays > 0).to.equal(true)
			expect(ProgressionConfig.Streak.FlawlessArenaBaseBonus > 0).to.equal(true)
			expect(ProgressionConfig.Streak.FlawlessArenaBonusPerStreak > 0).to.equal(true)
		end)
	end)
end
