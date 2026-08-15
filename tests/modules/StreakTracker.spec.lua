local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StreakTracker = require(ReplicatedStorage.Shared.modules.StreakTracker)

return function()
	describe("StreakTracker", function()
		describe("login streak", function()
			it("should build a streak across consecutive days and reset to 1 (fresh start) after a missed day (T-094 test case)", function()
				local tracker = StreakTracker.new()
				local streak
				streak = tracker:registerLogin(1, 7)
				expect(streak).to.equal(1)
				streak = tracker:registerLogin(2, 7)
				expect(streak).to.equal(2)
				streak = tracker:registerLogin(3, 7)
				expect(streak).to.equal(3)
				-- day 4 skipped
				streak = tracker:registerLogin(5, 7)
				expect(streak).to.equal(1)
			end)

			it("should not change the streak on a same-day relogin", function()
				local tracker = StreakTracker.new()
				tracker:registerLogin(1, 7)
				local streak, milestone = tracker:registerLogin(1, 7)
				expect(streak).to.equal(1)
				expect(milestone).to.equal(false)
			end)

			it("should report a milestone exactly every Nth consecutive day", function()
				local tracker = StreakTracker.new()
				local milestone
				for day = 1, 6 do
					_, milestone = tracker:registerLogin(day, 7)
					expect(milestone).to.equal(false)
				end
				_, milestone = tracker:registerLogin(7, 7)
				expect(milestone).to.equal(true)
				for day = 8, 13 do
					_, milestone = tracker:registerLogin(day, 7)
					expect(milestone).to.equal(false)
				end
				_, milestone = tracker:registerLogin(14, 7)
				expect(milestone).to.equal(true)
			end)
		end)

		describe("in-run Flawless arena streak", function()
			it("should grant no bonus on the first Flawless clear, then an escalating bonus after", function()
				local tracker = StreakTracker.new()
				local streak, bonus

				streak, bonus = tracker:registerArenaClear(true, 50, 25)
				expect(streak).to.equal(1)
				expect(bonus).to.equal(0)

				streak, bonus = tracker:registerArenaClear(true, 50, 25)
				expect(streak).to.equal(2)
				expect(bonus).to.equal(50)

				streak, bonus = tracker:registerArenaClear(true, 50, 25)
				expect(streak).to.equal(3)
				expect(bonus).to.equal(75)
			end)

			it("should reset the arena streak and grant no bonus on a non-Flawless clear", function()
				local tracker = StreakTracker.new()
				tracker:registerArenaClear(true, 50, 25)
				tracker:registerArenaClear(true, 50, 25)
				local streak, bonus = tracker:registerArenaClear(false, 50, 25)
				expect(streak).to.equal(0)
				expect(bonus).to.equal(0)
			end)
		end)
	end)
end
