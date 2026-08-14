-- GDD §3.1 / T-030. Pure jump-count rules shared by CharacterController
-- (client) — kept separate from the controller so the cap logic is
-- unit-testable without a live Humanoid/character.

local JumpRules = {}

function JumpRules.getMaxJumps(doubleJumpUnlocked: boolean): number
	return if doubleJumpUnlocked then 2 else 1
end

function JumpRules.canJump(currentJumpCount: number, doubleJumpUnlocked: boolean): boolean
	return currentJumpCount < JumpRules.getMaxJumps(doubleJumpUnlocked)
end

return JumpRules
