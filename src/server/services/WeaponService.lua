--!strict
-- T-070 (GDD §5.2). Server-authoritative Main Weapon selection, freely
-- swappable in the Lobby, locked for the duration of a battlefield run.
--
-- "Duration of a battlefield run" seam: the Party/Teleport system
-- (T-120/T-121, Phase 10) that would normally define Lobby-vs-battlefield
-- context doesn't exist yet. ArenaGateController:HasPlayerEnteredAnyArena
-- (added in Phase 4 for this purpose) is the concrete, already-functional
-- stand-in — once a player has touched any arena gate in this server
-- instance, they're locked for its remaining lifetime, matching the DoD's
-- intent without waiting on Phase 10.
--
-- Sets the same `EquippedWeaponId` Player attribute CombatService (T-049)
-- already reads — this is that seam's completion, not a new one.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)

local WeaponConfig = ConfigService.Weapon
local DEFAULT_WEAPON_ID = "TwinBlades"

local WeaponService = Knit.CreateService({
	Name = "WeaponService",
	Client = {},
})

local equippedWeaponByPlayer: { [Player]: string } = {}

local function setEquippedWeapon(player: Player, weaponId: string)
	equippedWeaponByPlayer[player] = weaponId
	player:SetAttribute("EquippedWeaponId", weaponId)
end

function WeaponService.Client:RequestEquipWeapon(player: Player, weaponId: string): boolean
	if type(weaponId) ~= "string" or not WeaponConfig.Weapons[weaponId] then
		return false
	end

	local ArenaGateController = Knit.GetService("ArenaGateController")
	if ArenaGateController:HasPlayerEnteredAnyArena(player) then
		return false -- locked for the duration of the battlefield run
	end

	setEquippedWeapon(player, weaponId)
	return true
end

-- Server-internal read, e.g. for future UI/quest systems that need the
-- current loadout without a client round-trip.
function WeaponService:GetEquippedWeaponId(player: Player): string
	return equippedWeaponByPlayer[player] or DEFAULT_WEAPON_ID
end

function WeaponService:KnitInit()
	Players.PlayerAdded:Connect(function(player)
		setEquippedWeapon(player, DEFAULT_WEAPON_ID)
	end)
	Players.PlayerRemoving:Connect(function(player)
		equippedWeaponByPlayer[player] = nil
	end)

	-- Players already in the server when this service initializes (e.g. a
	-- script reload in Studio) still get a valid default loadout.
	for _, player in Players:GetPlayers() do
		if not equippedWeaponByPlayer[player] then
			setEquippedWeapon(player, DEFAULT_WEAPON_ID)
		end
	end
end

return WeaponService
