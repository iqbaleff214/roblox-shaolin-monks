--!strict
-- T-030 (GDD §3.1). Run/jump come from Roblox's default Humanoid + PlayerModule
-- for free (this controller only applies the tuned WalkSpeed/JumpPower from
-- CombatConfig.Movement); everything below adds the custom mechanics Roblox
-- doesn't provide out of the box: double-jump (gated by a Skill Tree unlock),
-- wall-run (only on `WallRunnable`-tagged parts), and ledge grab/climb.
--
-- Skill Tree hookup note: Phase 7 (T-091) doesn't exist yet. Rather than
-- reach into an unbuilt service, double-jump unlock state is read from a
-- boolean `DoubleJumpUnlocked` Attribute on the Player instance — a stable,
-- decoupled seam. T-091 just needs to set that attribute on purchase; this
-- controller never has to change.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ConfigService = require(ReplicatedStorage.Shared.ConfigService)
local JumpRules = require(ReplicatedStorage.Shared.modules.JumpRules)

local Movement = ConfigService.Combat.Movement
local WALL_RUNNABLE_TAG = "WallRunnable"

local player = Players.LocalPlayer

local CharacterController = Knit.CreateController({
	Name = "CharacterController",
})

type CharacterState = {
	humanoid: Humanoid,
	rootPart: BasePart,
	heartbeatConnection: RBXScriptConnection,
	jumpCount: number,
	isWallRunning: boolean,
	wallRunStartedAt: number,
	wallRunForce: VectorForce?,
	wallRunAttachment: Attachment?,
	isLedgeHanging: boolean,
	ledgeWallNormal: Vector3?,
}

local activeState: CharacterState? = nil

local function getDoubleJumpUnlocked(): boolean
	return player:GetAttribute("DoubleJumpUnlocked") == true
end

-- Raycasts that ignore the player's own character.
local function raycast(origin: Vector3, direction: Vector3, character: Model): RaycastResult?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	return workspace:Raycast(origin, direction, params)
end

--// Wall-run \\--

local function endWallRun(state: CharacterState)
	if not state.isWallRunning then
		return
	end
	state.isWallRunning = false
	if state.wallRunForce then
		state.wallRunForce:Destroy()
		state.wallRunForce = nil
	end
	if state.wallRunAttachment then
		state.wallRunAttachment:Destroy()
		state.wallRunAttachment = nil
	end
end

local function startWallRun(state: CharacterState, wallNormal: Vector3)
	state.isWallRunning = true
	state.wallRunStartedAt = os.clock()

	local attachment = Instance.new("Attachment")
	attachment.Name = "WallRunAttachment"
	attachment.Parent = state.rootPart

	local force = Instance.new("VectorForce")
	force.Name = "WallRunForce"
	force.Attachment0 = attachment
	force.RelativeTo = Enum.ActuatorRelativeTo.World
	force.ApplyAtCenterOfMass = true
	-- Counteract a portion of gravity so the fall is slowed, not stopped.
	local mass = state.rootPart.AssemblyMass
	local counteract = workspace.Gravity * mass * (1 - Movement.WallRun.GravityScale)
	force.Force = Vector3.new(0, counteract, 0)
	force.Parent = state.rootPart

	state.wallRunAttachment = attachment
	state.wallRunForce = force

	-- Tangent along the wall, biased toward the player's current horizontal heading.
	local horizontalVelocity = Vector3.new(state.rootPart.AssemblyLinearVelocity.X, 0, state.rootPart.AssemblyLinearVelocity.Z)
	local up = Vector3.new(0, 1, 0)
	local tangent = up:Cross(wallNormal)
	if tangent.Magnitude < 1e-3 then
		endWallRun(state)
		return
	end
	tangent = tangent.Unit
	if tangent:Dot(horizontalVelocity) < 0 then
		tangent = -tangent
	end

	local velocity = state.rootPart.AssemblyLinearVelocity
	state.rootPart.AssemblyLinearVelocity = Vector3.new(tangent.X * Movement.WallRun.Speed, velocity.Y, tangent.Z * Movement.WallRun.Speed)
end

local function tryStartWallRun(state: CharacterState)
	if state.isWallRunning or state.isLedgeHanging then
		return
	end
	if state.humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
		return
	end

	local velocity = state.rootPart.AssemblyLinearVelocity
	local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
	if horizontalVelocity.Magnitude < Movement.WallRun.MinEntrySpeed then
		return
	end

	local character = assert(state.rootPart.Parent :: Model?, "CharacterState.rootPart has no parent")
	local direction = horizontalVelocity.Unit
	local result = raycast(state.rootPart.Position, direction * 3, character)
	if result and CollectionService:HasTag(result.Instance, WALL_RUNNABLE_TAG) then
		startWallRun(state, result.Normal)
	end
end

local function updateWallRun(state: CharacterState)
	if not state.isWallRunning then
		return
	end

	local elapsed = os.clock() - state.wallRunStartedAt
	if elapsed >= Movement.WallRun.Duration or state.humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
		endWallRun(state)
		return
	end

	-- Detach if the wall runs out beneath the player.
	local character = assert(state.rootPart.Parent :: Model?, "CharacterState.rootPart has no parent")
	local velocity = state.rootPart.AssemblyLinearVelocity
	local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
	if horizontalVelocity.Magnitude > 1e-3 then
		local result = raycast(state.rootPart.Position, horizontalVelocity.Unit * 3, character)
		if not result or not CollectionService:HasTag(result.Instance, WALL_RUNNABLE_TAG) then
			endWallRun(state)
		end
	end
end

--// Ledge grab \\--

local function dropLedge(state: CharacterState)
	if not state.isLedgeHanging then
		return
	end
	state.isLedgeHanging = false
	state.ledgeWallNormal = nil
	state.rootPart.Anchored = false
	state.humanoid.AutoRotate = true
end

local function startLedgeHang(state: CharacterState, wallNormal: Vector3)
	state.isLedgeHanging = true
	state.ledgeWallNormal = wallNormal
	state.rootPart.Anchored = true
	state.humanoid.AutoRotate = false
end

local function climbLedge(state: CharacterState)
	if not state.isLedgeHanging then
		return
	end

	local wallNormal = state.ledgeWallNormal :: Vector3
	local startCFrame = state.rootPart.CFrame
	local targetCFrame = startCFrame + Vector3.new(0, Movement.LedgeGrab.DetectionHeight, 0) - wallNormal * Movement.LedgeGrab.DetectionDistance

	-- Anchored for the whole climb so nothing else can move the character mid-tween.
	local tween = TweenService:Create(state.rootPart, TweenInfo.new(Movement.LedgeGrab.ClimbDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = targetCFrame,
	})
	tween:Play()
	tween.Completed:Once(function()
		dropLedge(state)
	end)
end

local function tryStartLedgeHang(state: CharacterState)
	if state.isLedgeHanging or state.isWallRunning then
		return
	end
	if state.humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
		return
	end
	if state.rootPart.AssemblyLinearVelocity.Y >= 0 then
		return -- only grab while falling, not while still rising
	end

	local character = assert(state.rootPart.Parent :: Model?, "CharacterState.rootPart has no parent")
	local lookDirection = state.rootPart.CFrame.LookVector

	local chestResult = raycast(state.rootPart.Position, lookDirection * Movement.LedgeGrab.DetectionDistance, character)
	if not chestResult then
		return
	end

	local headOrigin = state.rootPart.Position + Vector3.new(0, Movement.LedgeGrab.DetectionHeight, 0)
	local headResult = raycast(headOrigin, lookDirection * Movement.LedgeGrab.DetectionDistance, character)
	if headResult then
		return -- wall continues above head height, no ledge lip to grab
	end

	startLedgeHang(state, chestResult.Normal)
end

local function updateLedgeGrab(state: CharacterState)
	if not state.isLedgeHanging then
		return
	end
	local moveDirection = state.humanoid.MoveDirection
	if moveDirection.Magnitude < 1e-3 then
		return
	end
	local wallNormal = state.ledgeWallNormal :: Vector3
	if moveDirection.Unit:Dot(wallNormal) > 0.3 then
		dropLedge(state)
	end
end

--// Jump (double-jump patch on top of the default single jump) \\--

local function handleJumpRequest(state: CharacterState)
	if state.isLedgeHanging then
		climbLedge(state)
		return
	end

	if state.isWallRunning then
		endWallRun(state)
		state.jumpCount = 1
		local velocity = state.rootPart.AssemblyLinearVelocity
		state.rootPart.AssemblyLinearVelocity = Vector3.new(velocity.X, Movement.DoubleJump.Impulse, velocity.Z)
		return
	end

	if state.humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
		return -- grounded jump requests are handled natively by the Humanoid
	end

	if not JumpRules.canJump(state.jumpCount, getDoubleJumpUnlocked()) then
		return
	end

	state.jumpCount += 1
	local velocity = state.rootPart.AssemblyLinearVelocity
	state.rootPart.AssemblyLinearVelocity = Vector3.new(velocity.X, Movement.DoubleJump.Impulse, velocity.Z)
end

--// Character lifecycle \\--

local function teardownCharacter()
	if not activeState then
		return
	end
	endWallRun(activeState)
	dropLedge(activeState)
	activeState.heartbeatConnection:Disconnect()
	activeState = nil
end

local function setupCharacter(character: Model)
	teardownCharacter()

	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local rootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

	humanoid.WalkSpeed = Movement.WalkSpeed
	humanoid.JumpPower = Movement.JumpPower
	humanoid.UseJumpPower = true

	local state: CharacterState = {
		humanoid = humanoid,
		rootPart = rootPart,
		heartbeatConnection = nil :: any,
		jumpCount = 0,
		isWallRunning = false,
		wallRunStartedAt = 0,
		wallRunForce = nil,
		wallRunAttachment = nil,
		isLedgeHanging = false,
		ledgeWallNormal = nil,
	}

	state.heartbeatConnection = RunService.Heartbeat:Connect(function()
		if state.humanoid:GetState() == Enum.HumanoidStateType.Freefall then
			if not state.isWallRunning and not state.isLedgeHanging then
				tryStartWallRun(state)
				tryStartLedgeHang(state)
			end
			updateWallRun(state)
			updateLedgeGrab(state)
		else
			endWallRun(state)
			dropLedge(state)
			state.jumpCount = 0
		end
	end)

	activeState = state
end

function CharacterController:KnitStart()
	UserInputService.JumpRequest:Connect(function()
		if activeState then
			handleJumpRequest(activeState)
		end
	end)

	if player.Character then
		setupCharacter(player.Character)
	end
	player.CharacterAdded:Connect(setupCharacter)
	player.CharacterRemoving:Connect(teardownCharacter)
end

function CharacterController:KnitInit() end

return CharacterController
