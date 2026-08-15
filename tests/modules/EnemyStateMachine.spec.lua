local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnemyStateMachine = require(ReplicatedStorage.Shared.modules.EnemyStateMachine)

return function()
	describe("EnemyStateMachine", function()
		it("should start in Idle by default", function()
			local machine = EnemyStateMachine.new()
			expect(machine:is("Idle")).to.equal(true)
		end)

		it("should walk the full happy path: Idle -> Aggro -> Circling -> Attacking -> Circling", function()
			local machine = EnemyStateMachine.new()
			expect(machine:transition("Aggro")).to.equal(true)
			expect(machine:transition("Circling")).to.equal(true)
			expect(machine:transition("Attacking")).to.equal(true)
			expect(machine:transition("Circling")).to.equal(true)
			expect(machine:is("Circling")).to.equal(true)
		end)

		it("should reject an illegal jump (e.g. Idle straight to Attacking)", function()
			local machine = EnemyStateMachine.new()
			expect(machine:transition("Attacking")).to.equal(false)
			expect(machine:is("Idle")).to.equal(true) -- unchanged
		end)

		it("should allow Staggered from any active-combat state", function()
			for _, startState in { "Aggro", "Circling", "Attacking" } do
				local machine = EnemyStateMachine.new(startState :: any)
				expect(machine:transition("Staggered")).to.equal(true)
			end
		end)

		it("should allow Dead from any non-terminal state", function()
			for _, startState in { "Idle", "Aggro", "Circling", "Attacking", "Staggered" } do
				local machine = EnemyStateMachine.new(startState :: any)
				expect(machine:transition("Dead")).to.equal(true)
			end
		end)

		it("should treat Dead as terminal — no legal transitions out", function()
			local machine = EnemyStateMachine.new("Dead" :: any)
			expect(machine:transition("Idle")).to.equal(false)
			expect(machine:transition("Circling")).to.equal(false)
			expect(machine:is("Dead")).to.equal(true)
		end)

		it("should allow losing aggro back to Idle from Aggro or Circling", function()
			local fromAggro = EnemyStateMachine.new("Aggro" :: any)
			expect(fromAggro:transition("Idle")).to.equal(true)

			local fromCircling = EnemyStateMachine.new("Circling" :: any)
			expect(fromCircling:transition("Idle")).to.equal(true)
		end)

		it("should recover from Staggered back to Circling, not directly to Attacking", function()
			local machine = EnemyStateMachine.new("Staggered" :: any)
			expect(machine:transition("Attacking")).to.equal(false)
			expect(machine:transition("Circling")).to.equal(true)
		end)
	end)
end
