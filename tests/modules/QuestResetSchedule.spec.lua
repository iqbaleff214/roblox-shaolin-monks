local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuestResetSchedule = require(ReplicatedStorage.Shared.modules.QuestResetSchedule)

local SECONDS_PER_DAY = 86400
local SECONDS_PER_WEEK = SECONDS_PER_DAY * 7

return function()
	describe("QuestResetSchedule", function()
		it("should keep the same daily period id within one calendar day (midnight UTC reset)", function()
			expect(QuestResetSchedule.dailyPeriodId(0, 0)).to.equal(QuestResetSchedule.dailyPeriodId(SECONDS_PER_DAY - 1, 0))
		end)

		it("should flip the daily period id exactly at midnight UTC", function()
			local before = QuestResetSchedule.dailyPeriodId(SECONDS_PER_DAY - 1, 0)
			local after = QuestResetSchedule.dailyPeriodId(SECONDS_PER_DAY, 0)
			expect(after).to.equal(before + 1)
		end)

		it("should honor a non-zero reset hour offset", function()
			local resetHour = 5
			local resetSecond = resetHour * 3600
			local before = QuestResetSchedule.dailyPeriodId(resetSecond - 1, resetHour)
			local after = QuestResetSchedule.dailyPeriodId(resetSecond, resetHour)
			expect(after).to.equal(before + 1)
		end)

		it("should flip the weekly period id exactly at Monday 00:00 UTC (epoch is a Thursday, +4 days)", function()
			local mondayUnix = 4 * SECONDS_PER_DAY
			local before = QuestResetSchedule.weeklyPeriodId(mondayUnix - 1)
			local after = QuestResetSchedule.weeklyPeriodId(mondayUnix)
			expect(after).to.equal(before + 1)
		end)

		it("should keep the same weekly period id across a full 7-day span", function()
			local mondayUnix = 4 * SECONDS_PER_DAY
			local id = QuestResetSchedule.weeklyPeriodId(mondayUnix)
			expect(QuestResetSchedule.weeklyPeriodId(mondayUnix + SECONDS_PER_WEEK - 1)).to.equal(id)
		end)
	end)
end
