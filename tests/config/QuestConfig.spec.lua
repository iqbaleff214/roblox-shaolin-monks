local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuestConfig = require(ReplicatedStorage.Shared.config.QuestConfig)

local function assertValidEntry(entry)
	expect(type(entry.Id)).to.equal("string")
	expect(type(entry.Description)).to.equal("string")
	expect(entry.Goal > 0).to.equal(true)
	expect(type(entry.RewardType)).to.equal("string")
end

return function()
	describe("QuestConfig", function()
		it("should keep the daily reset hour within a valid 0-23 range", function()
			expect(QuestConfig.ResetHourUTC >= 0 and QuestConfig.ResetHourUTC <= 23).to.equal(true)
		end)

		it("should define valid Daily quest entries", function()
			expect(#QuestConfig.Daily > 0).to.equal(true)
			for _, entry in QuestConfig.Daily do
				assertValidEntry(entry)
			end
		end)

		it("should define valid Weekly quest entries", function()
			expect(#QuestConfig.Weekly > 0).to.equal(true)
			for _, entry in QuestConfig.Weekly do
				assertValidEntry(entry)
			end
		end)

		it("should never repeat a quest Id across Daily and Weekly", function()
			local seen = {}
			for _, entry in QuestConfig.Daily do
				expect(seen[entry.Id]).to.equal(nil)
				seen[entry.Id] = true
			end
			for _, entry in QuestConfig.Weekly do
				expect(seen[entry.Id]).to.equal(nil)
				seen[entry.Id] = true
			end
		end)

		it("should give every Coins/XP reward a positive RewardAmount", function()
			for _, list in { QuestConfig.Daily, QuestConfig.Weekly } do
				for _, entry in list do
					if entry.RewardType == "Coins" or entry.RewardType == "XP" then
						expect(entry.RewardAmount > 0).to.equal(true)
					end
				end
			end
		end)
	end)
end
