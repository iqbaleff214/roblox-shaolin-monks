local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InputSchemeClassifier = require(ReplicatedStorage.Shared.modules.InputSchemeClassifier)

return function()
	describe("InputSchemeClassifier", function()
		it("should classify Touch as Mobile", function()
			expect(InputSchemeClassifier.classify(Enum.UserInputType.Touch)).to.equal("Mobile")
		end)

		it("should classify every Gamepad slot as Console", function()
			expect(InputSchemeClassifier.classify(Enum.UserInputType.Gamepad1)).to.equal("Console")
			expect(InputSchemeClassifier.classify(Enum.UserInputType.Gamepad8)).to.equal("Console")
		end)

		it("should classify keyboard and mouse input as PC", function()
			expect(InputSchemeClassifier.classify(Enum.UserInputType.Keyboard)).to.equal("PC")
			expect(InputSchemeClassifier.classify(Enum.UserInputType.MouseButton1)).to.equal("PC")
			expect(InputSchemeClassifier.classify(Enum.UserInputType.MouseMovement)).to.equal("PC")
		end)

		it("should default anything unrecognized to PC", function()
			expect(InputSchemeClassifier.classify(Enum.UserInputType.TextInput)).to.equal("PC")
		end)
	end)
end
