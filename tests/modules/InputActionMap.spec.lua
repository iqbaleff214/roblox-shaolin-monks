local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InputActionMap = require(ReplicatedStorage.Shared.modules.InputActionMap)

return function()
	describe("InputActionMap", function()
		it("should resolve every PC action from GDD §6.1", function()
			expect(InputActionMap.resolve(Enum.KeyCode.None, Enum.UserInputType.MouseButton1)).to.equal("LightAttack")
			expect(InputActionMap.resolve(Enum.KeyCode.None, Enum.UserInputType.MouseButton2)).to.equal("HeavyAttack")
			expect(InputActionMap.resolve(Enum.KeyCode.LeftShift, Enum.UserInputType.Keyboard)).to.equal("Block")
			expect(InputActionMap.resolve(Enum.KeyCode.RightShift, Enum.UserInputType.Keyboard)).to.equal("Block")
			expect(InputActionMap.resolve(Enum.KeyCode.LeftControl, Enum.UserInputType.Keyboard)).to.equal("Dodge")
			expect(InputActionMap.resolve(Enum.KeyCode.F, Enum.UserInputType.Keyboard)).to.equal("Grab")
			expect(InputActionMap.resolve(Enum.KeyCode.E, Enum.UserInputType.Keyboard)).to.equal("Interact")
			expect(InputActionMap.resolve(Enum.KeyCode.Q, Enum.UserInputType.Keyboard)).to.equal("ThrowWeapon")
			expect(InputActionMap.resolve(Enum.KeyCode.R, Enum.UserInputType.Keyboard)).to.equal("Ultimate")
			expect(InputActionMap.resolve(Enum.KeyCode.None, Enum.UserInputType.MouseButton3)).to.equal("LockOn")
		end)

		it("should resolve every Console action from GDD §6.3", function()
			expect(InputActionMap.resolve(Enum.KeyCode.ButtonX, Enum.UserInputType.Gamepad1)).to.equal("LightAttack")
			expect(InputActionMap.resolve(Enum.KeyCode.ButtonY, Enum.UserInputType.Gamepad1)).to.equal("HeavyAttack")
			expect(InputActionMap.resolve(Enum.KeyCode.ButtonL2, Enum.UserInputType.Gamepad1)).to.equal("Block")
			expect(InputActionMap.resolve(Enum.KeyCode.ButtonB, Enum.UserInputType.Gamepad1)).to.equal("Dodge")
			expect(InputActionMap.resolve(Enum.KeyCode.ButtonR1, Enum.UserInputType.Gamepad1)).to.equal("Grab")
			expect(InputActionMap.resolve(Enum.KeyCode.ButtonA, Enum.UserInputType.Gamepad1)).to.equal("Interact")
			expect(InputActionMap.resolve(Enum.KeyCode.ButtonL1, Enum.UserInputType.Gamepad1)).to.equal("ThrowWeapon")
			expect(InputActionMap.resolve(Enum.KeyCode.ButtonR2, Enum.UserInputType.Gamepad1)).to.equal("Ultimate")
			expect(InputActionMap.resolve(Enum.KeyCode.ButtonR3, Enum.UserInputType.Gamepad1)).to.equal("LockOn")
		end)

		it("should return nil for unmapped input (e.g. WASD, camera movement)", function()
			expect(InputActionMap.resolve(Enum.KeyCode.W, Enum.UserInputType.Keyboard)).to.equal(nil)
			expect(InputActionMap.resolve(Enum.KeyCode.None, Enum.UserInputType.MouseMovement)).to.equal(nil)
		end)

		it("should expose exactly the 9 logical actions named in T-040's DoD", function()
			local expectedActions = {
				LightAttack = true,
				HeavyAttack = true,
				Block = true,
				Dodge = true,
				Grab = true,
				Interact = true,
				ThrowWeapon = true,
				Ultimate = true,
				LockOn = true,
			}
			expect(#InputActionMap.Actions).to.equal(9)
			for _, action in InputActionMap.Actions do
				expect(expectedActions[action]).to.equal(true)
			end
		end)
	end)
end
