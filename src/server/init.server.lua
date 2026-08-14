--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)

Knit.AddServices(script.services)

Knit.Start():andThen(function()
	if RunService:IsStudio() then
		local TestRunner = require(ReplicatedStorage.Shared.modules.TestRunner)
		TestRunner.runIfStudio()
	end
end):catch(warn)
