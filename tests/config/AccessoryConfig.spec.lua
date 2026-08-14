local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AccessoryConfig = require(ReplicatedStorage.Shared.config.AccessoryConfig)

local VALID_SLOTS = { Head = true, Body = true, Arm = true, Leg = true }
local VALID_RARITIES = { Common = true, Uncommon = true, Rare = true, Epic = true, Legendary = true }
local VALID_SOURCES = { Shop = true, BattlePass = true, Crate = true, QuestReward = true }

-- §5.1: accessories affect appearance only. Any of these keys showing up on
-- an entry would mean a stat accidentally leaked into a cosmetic slot.
local DISALLOWED_KEYS = {
	Damage = true,
	Health = true,
	Speed = true,
	Armor = true,
	Defense = true,
	MoveSpeedMult = true,
	Poise = true,
}

return function()
	describe("AccessoryConfig", function()
		it("should give every item a valid Slot, Rarity, and UnlockSource", function()
			for _, item in AccessoryConfig do
				expect(VALID_SLOTS[item.Slot]).to.equal(true)
				expect(VALID_RARITIES[item.Rarity]).to.equal(true)
				expect(VALID_SOURCES[item.UnlockSource]).to.equal(true)
			end
		end)

		it("should cover all 4 slots from §5.1", function()
			local seenSlots = {}
			for _, item in AccessoryConfig do
				seenSlots[item.Slot] = true
			end
			for slot in VALID_SLOTS do
				expect(seenSlots[slot]).to.equal(true)
			end
		end)

		it("should never contain a combat-stat field (cosmetic-only guard)", function()
			for _, item in AccessoryConfig do
				for key in item do
					expect(DISALLOWED_KEYS[key]).never.to.equal(true)
				end
			end
		end)
	end)
end
