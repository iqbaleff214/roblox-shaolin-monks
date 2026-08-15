local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuFlowStateMachine = require(ReplicatedStorage.Shared.modules.MenuFlowStateMachine)

return function()
	describe("MenuFlowStateMachine", function()
		it("should start at Lobby", function()
			local machine = MenuFlowStateMachine.new()
			expect(machine:current()).to.equal("Lobby")
		end)

		it("should advance through every stage in order", function()
			local machine = MenuFlowStateMachine.new()
			for i = 2, #MenuFlowStateMachine.ORDER do
				expect(machine:advance()).to.equal(true)
				expect(machine:current()).to.equal(MenuFlowStateMachine.ORDER[i])
			end
		end)

		it("should refuse to advance past the final stage", function()
			local machine = MenuFlowStateMachine.new()
			for _ = 1, #MenuFlowStateMachine.ORDER - 1 do
				machine:advance()
			end
			expect(machine:current()).to.equal("Load")
			expect(machine:advance()).to.equal(false)
			expect(machine:current()).to.equal("Load")
		end)

		it("should have a back-navigation path to Lobby from every stage (T-133 test case)", function()
			for startIndex = 1, #MenuFlowStateMachine.ORDER do
				local machine = MenuFlowStateMachine.new()
				for _ = 1, startIndex - 1 do
					machine:advance()
				end
				expect(machine:current()).to.equal(MenuFlowStateMachine.ORDER[startIndex])

				local guard = 0
				while machine:current() ~= "Lobby" and guard < #MenuFlowStateMachine.ORDER do
					local moved = machine:back()
					expect(moved).to.equal(true)
					guard += 1
				end
				expect(machine:current()).to.equal("Lobby")
			end
		end)

		it("should refuse to go back past Lobby", function()
			local machine = MenuFlowStateMachine.new()
			expect(machine:back()).to.equal(false)
			expect(machine:current()).to.equal("Lobby")
		end)

		it("should jump directly to a named state via goTo", function()
			local machine = MenuFlowStateMachine.new()
			expect(machine:goTo("Ready")).to.equal(true)
			expect(machine:current()).to.equal("Ready")
		end)

		it("should reject goTo for an unrecognized state", function()
			local machine = MenuFlowStateMachine.new()
			expect(machine:goTo("NotAState")).to.equal(false)
			expect(machine:current()).to.equal("Lobby")
		end)
	end)
end
