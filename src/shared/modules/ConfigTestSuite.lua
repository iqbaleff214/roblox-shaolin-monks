--!strict
-- T-190 (GDD §17 QA). Consolidates every Phase 1 (+ since-added) config
-- schema TestEZ spec under tests/config/ into one fast, dedicated suite —
-- separate from TestRunner's (T-001) full sweep of everything under tests/,
-- since config schema validation alone is cheap enough to run before every
-- commit/publish, not just in CI. Invokable from the Studio command bar:
--   require(game.ReplicatedStorage.Shared.modules.ConfigTestSuite).run()

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TestEZ = require(ReplicatedStorage.Packages.TestEZ)

local ConfigTestSuite = {}

-- Seconds; the suite's own DoD ("practical to run pre-commit/pre-publish").
ConfigTestSuite.TimeBudgetSeconds = 30

function ConfigTestSuite.isWithinBudget(elapsedSeconds: number, budgetSeconds: number): boolean
	return elapsedSeconds <= budgetSeconds
end

function ConfigTestSuite.run(): (any, number, boolean)
	local testsRoot = ServerStorage:FindFirstChild("Tests")
	local configRoot = testsRoot and testsRoot:FindFirstChild("config")
	if not configRoot then
		warn("[ConfigTestSuite] ServerStorage.Tests.config not found — nothing to run.")
		return nil, 0, false
	end

	local startClock = os.clock()
	local results = TestEZ.TestBootstrap:run({ configRoot }, TestEZ.Reporters.TextReporter)
	local elapsedSeconds = os.clock() - startClock

	local withinBudget = ConfigTestSuite.isWithinBudget(elapsedSeconds, ConfigTestSuite.TimeBudgetSeconds)
	if withinBudget then
		print(`[ConfigTestSuite] Completed in {elapsedSeconds}s (budget: {ConfigTestSuite.TimeBudgetSeconds}s)`)
	else
		warn(`[ConfigTestSuite] Took {elapsedSeconds}s, over the {ConfigTestSuite.TimeBudgetSeconds}s budget`)
	end

	return results, elapsedSeconds, withinBudget
end

return ConfigTestSuite
