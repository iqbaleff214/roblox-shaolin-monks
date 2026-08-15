--!strict
-- T-072 (GDD §3.6, §11.2). Purely cosmetic reaction to UltimateExecutedRemote
-- — resolves which FX slot to play and plays it. Deliberately the ONLY place
-- a cosmetic skin choice would ever be read; UltimateService's damage/AoE
-- resolution (server) never touches this file or anything like it, which is
-- what makes the function/cosmetics decoupling real rather than assumed.
--
-- Always resolves to the weapon's base FxSlot today — the Ultimate FX skin
-- shop (§11.2) is Phase 9 work, not built yet. Wiring in a real owned-skin
-- lookup later only changes `resolveFxSlot` below.
--
-- No real VFX asset exists yet (S-043); an expanding, fading Highlight is a
-- clear, functional placeholder every nearby client can see.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)

local WeaponConfig = ConfigService.Weapon

local UltimateFXController = Knit.CreateController({
	Name = "UltimateFXController",
})

local function resolveFxSlot(weaponId: string): string?
	local weapon = WeaponConfig.Weapons[weaponId]
	return weapon and weapon.Ultimate.FxSlot
end

local function playPlaceholderFx(character: Model, fxSlot: string)
	if not character:FindFirstChild("HumanoidRootPart") then
		return
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = fxSlot
	highlight.FillColor = Color3.fromRGB(255, 245, 200)
	highlight.FillTransparency = 0.2
	highlight.OutlineTransparency = 0
	highlight.Parent = character

	local tween = TweenService:Create(highlight, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		FillTransparency = 1,
		OutlineTransparency = 1,
	})
	tween:Play()
	tween.Completed:Once(function()
		highlight:Destroy()
	end)
end

function UltimateFXController:KnitStart()
	local remote = ReplicatedStorage:WaitForChild("UltimateExecutedRemote") :: RemoteEvent
	remote.OnClientEvent:Connect(function(player: Player, weaponId: string)
		local character = player.Character
		local fxSlot = character and resolveFxSlot(weaponId)
		if character and fxSlot then
			playPlaceholderFx(character, fxSlot)
		end
	end)
end

function UltimateFXController:KnitInit() end

return UltimateFXController
