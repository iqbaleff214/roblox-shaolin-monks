--!strict
-- Runs every TestEZ spec under ServerStorage.Tests (see tests/ at repo root,
-- mounted via default.project.json). Invokable from the Studio command bar:
--   require(game.ReplicatedStorage.Shared.modules.TestRunner).run()
-- or automatically on server start while running in Studio (see src/server/init.server.lua).

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TestEZ = require(ReplicatedStorage.Packages.TestEZ)

local TestRunner = {}

function TestRunner.run()
	local testsRoot = ServerStorage:FindFirstChild("Tests")
	if not testsRoot then
		warn("[TestRunner] ServerStorage.Tests not found — nothing to run.")
		return nil
	end

	return TestEZ.TestBootstrap:run({ testsRoot }, TestEZ.Reporters.TextReporter)
end

function TestRunner.runIfStudio()
	if RunService:IsStudio() then
		TestRunner.run()
	end
end

return TestRunner
