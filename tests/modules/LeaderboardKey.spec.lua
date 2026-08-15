local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LeaderboardKey = require(ReplicatedStorage.Shared.modules.LeaderboardKey)

return function()
	describe("LeaderboardKey", function()
		it("should keep the All-Time store name stable across different week ids", function()
			local nameWeek1 = LeaderboardKey.storeName("ClearTime", "Chapter1", "AllTime", 1)
			local nameWeek2 = LeaderboardKey.storeName("ClearTime", "Chapter1", "AllTime", 2)
			expect(nameWeek1).to.equal(nameWeek2)
		end)

		it("should change the Weekly store name when the week id changes", function()
			local nameWeek1 = LeaderboardKey.storeName("ClearTime", "Chapter1", "Weekly", 1)
			local nameWeek2 = LeaderboardKey.storeName("ClearTime", "Chapter1", "Weekly", 2)
			expect(nameWeek1).never.to.equal(nameWeek2)
		end)

		it("should never collide All-Time and Weekly store names for the same week id", function()
			local allTime = LeaderboardKey.storeName("ClearTime", "Chapter1", "AllTime", 1)
			local weekly = LeaderboardKey.storeName("ClearTime", "Chapter1", "Weekly", 1)
			expect(allTime).never.to.equal(weekly)
		end)

		it("should treat a lower ClearTime as better", function()
			expect(LeaderboardKey.isBetter("ClearTime", 90, 100)).to.equal(true)
			expect(LeaderboardKey.isBetter("ClearTime", 110, 100)).to.equal(false)
		end)

		it("should treat a higher StyleScore as better", function()
			expect(LeaderboardKey.isBetter("StyleScore", 500, 400)).to.equal(true)
			expect(LeaderboardKey.isBetter("StyleScore", 300, 400)).to.equal(false)
		end)

		it("should sort ClearTime ascending and everything else descending", function()
			expect(LeaderboardKey.sortAscending("ClearTime")).to.equal(true)
			expect(LeaderboardKey.sortAscending("StyleScore")).to.equal(false)
		end)
	end)
end
