local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AttackerTokenPool = require(ReplicatedStorage.Shared.modules.AttackerTokenPool)

local function makeEnemies(count: number)
	local enemies = {}
	for i = 1, count do
		enemies[i] = { id = i } -- opaque key; any table works
	end
	return enemies
end

return function()
	describe("AttackerTokenPool", function()
		it("should never grant more tokens than the cap when 8 enemies aggro at once (T-050 test case)", function()
			local pool = AttackerTokenPool.new(3)
			local enemies = makeEnemies(8)

			local grantedCount = 0
			for _, enemy in enemies do
				if pool:request(enemy) then
					grantedCount += 1
				end
			end

			expect(grantedCount).to.equal(3)
			expect(pool:activeCount()).to.equal(3)
		end)

		it("should free a slot on release so a waiting enemy can then be granted one", function()
			local pool = AttackerTokenPool.new(2)
			local enemies = makeEnemies(3)

			expect(pool:request(enemies[1])).to.equal(true)
			expect(pool:request(enemies[2])).to.equal(true)
			expect(pool:request(enemies[3])).to.equal(false) -- pool full

			pool:release(enemies[1])
			expect(pool:request(enemies[3])).to.equal(true) -- slot freed up
			expect(pool:activeCount()).to.equal(2)
		end)

		it("should be idempotent: requesting an already-held token doesn't consume a second slot", function()
			local pool = AttackerTokenPool.new(1)
			local enemy = { id = 1 }
			expect(pool:request(enemy)).to.equal(true)
			expect(pool:request(enemy)).to.equal(true)
			expect(pool:activeCount()).to.equal(1)
		end)

		it("should be safe to release a token that was never held", function()
			local pool = AttackerTokenPool.new(3)
			local enemy = { id = 1 }
			pool:release(enemy) -- no error
			expect(pool:activeCount()).to.equal(0)
		end)

		it("should report holding status accurately", function()
			local pool = AttackerTokenPool.new(1)
			local enemy = { id = 1 }
			expect(pool:isHolding(enemy)).to.equal(false)
			pool:request(enemy)
			expect(pool:isHolding(enemy)).to.equal(true)
			pool:release(enemy)
			expect(pool:isHolding(enemy)).to.equal(false)
		end)
	end)
end
