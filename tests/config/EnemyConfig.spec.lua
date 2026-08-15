local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnemyConfig = require(ReplicatedStorage.Shared.config.EnemyConfig)

local EXPECTED_ROLES = {
	"Grunt",
	"Soldier",
	"Heavy",
	"Ranged",
	"Assassin",
	"Elite",
	"Boss",
}

return function()
	describe("EnemyConfig", function()
		it("should cap concurrent attackers at 2-3 per §4.3", function()
			expect(EnemyConfig.ConcurrentAttackerCap >= 2).to.equal(true)
			expect(EnemyConfig.ConcurrentAttackerCap <= 3).to.equal(true)
		end)

		it("should define every role from §4.2 (plus Boss per §4.5)", function()
			for _, role in EXPECTED_ROLES do
				expect(EnemyConfig.Roles[role]).to.be.a("table")
			end
		end)

		it("should give every role Health, Damage, and Poise at minimum", function()
			for _, stats in EnemyConfig.Roles do
				expect(stats.Health).to.be.a("number")
				expect(stats.Health > 0).to.equal(true)
				expect(stats.Damage).to.be.a("number")
				expect(stats.Damage > 0).to.equal(true)
				expect(stats.Poise).to.be.a("number")
				expect(stats.Poise > 0).to.equal(true)
			end
		end)

		it("should mark Soldier as blocking and Boss as multi-phase", function()
			expect(EnemyConfig.Roles.Soldier.Blocks).to.equal(true)
			expect(EnemyConfig.Roles.Boss.Phases).to.equal(3)
		end)

		it("should give every AI timing/movement value a strictly positive number (§4.3/§4.4)", function()
			expect(EnemyConfig.AttackCooldown > 0).to.equal(true)
			expect(EnemyConfig.CirclingRadius > 0).to.equal(true)
			expect(EnemyConfig.CirclingSpeed > 0).to.equal(true)
			expect(EnemyConfig.StaggerRecoveryDuration > 0).to.equal(true)
		end)

		it("should give the Boss phase-transition tuning table exactly its 3 fields, all positive (§4.5)", function()
			local expectedKeys = { "PhaseTransitionInvulnerableDuration", "CounterWindowDuration", "ParryPunishWindowDuration" }
			local seen = {}
			for key, value in EnemyConfig.Boss do
				seen[key] = true
				expect(type(value)).to.equal("number")
				expect(value > 0).to.equal(true)
			end
			for _, key in expectedKeys do
				expect(seen[key]).to.equal(true)
			end
			local count = 0
			for _ in EnemyConfig.Boss do
				count += 1
			end
			expect(count).to.equal(#expectedKeys)
		end)
	end)
end
