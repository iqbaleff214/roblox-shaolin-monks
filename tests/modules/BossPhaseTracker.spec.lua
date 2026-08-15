local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BossPhaseTracker = require(ReplicatedStorage.Shared.modules.BossPhaseTracker)

local MAX_HEALTH = 1500 -- matches EnemyConfig.Roles.Boss.Health
local INVULN_DURATION = 2

return function()
	describe("BossPhaseTracker", function()
		it("should start in phase 1", function()
			local tracker = BossPhaseTracker.new(MAX_HEALTH, 3)
			expect(tracker.currentPhase).to.equal(1)
		end)

		it("should cross into phase 2 and open an invulnerability window honored until it expires (T-065 test case)", function()
			local tracker = BossPhaseTracker.new(MAX_HEALTH, 3)
			-- Damage the boss down into the phase-2 HP band (clearly below
			-- the 1000 threshold, avoiding the exact boundary value).
			local crossed = tracker:checkPhaseTransition(900, 0, INVULN_DURATION)
			expect(crossed).to.equal(true)
			expect(tracker.currentPhase).to.equal(2)
			expect(tracker.isInvulnerable).to.equal(true)

			-- Still within the window: not yet vulnerable again.
			tracker:updateInvulnerability(1)
			expect(tracker.isInvulnerable).to.equal(true)

			-- Window has elapsed: vulnerable again, phase-2 behavior is live.
			tracker:updateInvulnerability(2)
			expect(tracker.isInvulnerable).to.equal(false)
		end)

		it("should not re-trigger a transition for further damage within the same phase band", function()
			local tracker = BossPhaseTracker.new(MAX_HEALTH, 3)
			expect(tracker:checkPhaseTransition(900, 0, INVULN_DURATION)).to.equal(true)
			expect(tracker:checkPhaseTransition(850, 1, INVULN_DURATION)).to.equal(false)
			expect(tracker.currentPhase).to.equal(2)
		end)

		it("should progress through all 3 phases and never transition again once in the final phase", function()
			local tracker = BossPhaseTracker.new(MAX_HEALTH, 3)
			tracker:checkPhaseTransition(900, 0, INVULN_DURATION)
			expect(tracker.currentPhase).to.equal(2)
			tracker:checkPhaseTransition(400, 1, INVULN_DURATION)
			expect(tracker.currentPhase).to.equal(3)

			expect(tracker:checkPhaseTransition(10, 2, INVULN_DURATION)).to.equal(false)
			expect(tracker.currentPhase).to.equal(3)
		end)

		it("should support a condensed 1-phase configuration for Elite Champions (§4.5)", function()
			local eliteTracker = BossPhaseTracker.new(300, 1) -- matches EnemyConfig.Roles.Elite.Health
			expect(eliteTracker.currentPhase).to.equal(1)
			expect(eliteTracker:checkPhaseTransition(1, 0, INVULN_DURATION)).to.equal(false) -- never transitions
		end)

		it("should open and close the grab-counter and parry-punish windows independently", function()
			local tracker = BossPhaseTracker.new(MAX_HEALTH, 3)
			expect(tracker:isCounterWindowOpen(0)).to.equal(false)
			expect(tracker:isParryPunishWindowOpen(0)).to.equal(false)

			tracker:openCounterWindow(0, 1)
			expect(tracker:isCounterWindowOpen(0.5)).to.equal(true)
			expect(tracker:isCounterWindowOpen(1.5)).to.equal(false)
			expect(tracker:isParryPunishWindowOpen(0.5)).to.equal(false) -- unaffected by the counter window

			tracker:openParryPunishWindow(2, 1)
			expect(tracker:isParryPunishWindowOpen(2.5)).to.equal(true)
			expect(tracker:isParryPunishWindowOpen(3.5)).to.equal(false)
		end)
	end)
end
