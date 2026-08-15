local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HardcodedStringLint = require(ReplicatedStorage.Shared.modules.HardcodedStringLint)

return function()
	describe("HardcodedStringLint", function()
		it("should flag a deliberately-seeded hardcoded .Text assignment (T-151 test case)", function()
			local source = 'label.Text = "Hello, player!"'
			local violations = HardcodedStringLint.scan(source)
			expect(#violations).to.equal(1)
			expect(violations[1].line).to.equal(1)
		end)

		it("should flag hardcoded ActionText/PlaceholderText/ObjectText the same way", function()
			expect(#HardcodedStringLint.scan('prompt.ActionText = "Open"')).to.equal(1)
			expect(#HardcodedStringLint.scan('box.PlaceholderText = "Enter name"')).to.equal(1)
			expect(#HardcodedStringLint.scan('part.ObjectText = "Press E"')).to.equal(1)
		end)

		it("should not flag a .Text assignment routed through the translator", function()
			local source = 'label.Text = LocalizationController:Translate("ui.button.play")'
			expect(#HardcodedStringLint.scan(source)).to.equal(0)
		end)

		it("should not flag a .Text assignment from a variable or expression", function()
			expect(#HardcodedStringLint.scan("label.Text = someVariable")).to.equal(0)
			expect(#HardcodedStringLint.scan("label.Text = tostring(count)")).to.equal(0)
		end)

		it("should not flag an empty string assignment", function()
			expect(#HardcodedStringLint.scan('label.Text = ""')).to.equal(0)
		end)

		it("should not flag a line with an explicit lint-disable marker", function()
			expect(#HardcodedStringLint.scan('label.Text = "Debug only" -- lint-disable')).to.equal(0)
		end)

		it("should report the correct line number across multiple lines", function()
			local source = table.concat({
				"local x = 1",
				'label.Text = "Second line"',
				"local y = 2",
			}, "\n")
			local violations = HardcodedStringLint.scan(source)
			expect(#violations).to.equal(1)
			expect(violations[1].line).to.equal(2)
		end)

		it("should flag multiple violations across a multi-line source", function()
			local source = table.concat({
				'a.Text = "One"',
				'b.Text = "Two"',
			}, "\n")
			expect(#HardcodedStringLint.scan(source)).to.equal(2)
		end)
	end)
end
