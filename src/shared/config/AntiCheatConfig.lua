-- T-171 (GDD §17.2). Per-RemoteEvent rate limits consumed by
-- RateLimitService/RateLimiter. Keys are `ServiceName.MethodName` (matching
-- two different services' own same-named method, e.g. ComboScrollShopService
-- and CosmeticShopService both expose `RequestPurchase`, needs the service
-- name to disambiguate).
--
-- MaxTokens is the burst allowance (how many calls can land back-to-back
-- before limiting kicks in) and RefillPerSecond is the sustained rate
-- afterward — both tuned comfortably above the realistic max input rate for
-- each action (§17.2's DoD) so legitimate fast-combo play is never clipped.

return {
	RateLimits = {
		-- Attack inputs (§3, combat feel: Light Attack can chain multiple
		-- times per second during a combo).
		["CombatService.RequestAttack"] = { MaxTokens = 12, RefillPerSecond = 8 },
		["CombatService.RequestFinishingMove"] = { MaxTokens = 4, RefillPerSecond = 2 },
		["CombatService.RequestUltimate"] = { MaxTokens = 2, RefillPerSecond = 0.5 },
		["DodgeService.RequestDodge"] = { MaxTokens = 6, RefillPerSecond = 4 },
		["GrappleService.RequestGrab"] = { MaxTokens = 4, RefillPerSecond = 2 },
		["GrappleService.RequestThrow"] = { MaxTokens = 4, RefillPerSecond = 2 },
		["WeaponPickupService.RequestSecondaryAttack"] = { MaxTokens = 10, RefillPerSecond = 6 },
		["WeaponPickupService.RequestThrowSecondary"] = { MaxTokens = 4, RefillPerSecond = 2 },

		-- Purchase requests (§10, §11: menu-driven, never legitimately rapid).
		["ComboScrollShopService.RequestPurchase"] = { MaxTokens = 5, RefillPerSecond = 1 },
		["CosmeticShopService.RequestPurchase"] = { MaxTokens = 5, RefillPerSecond = 1 },
		["CosmeticShopService.RequestPurchaseBundle"] = { MaxTokens = 5, RefillPerSecond = 1 },
		["CrateOpeningService.RequestPurchaseCrate"] = { MaxTokens = 5, RefillPerSecond = 1 },
		["SkillTreeService.RequestPurchaseNode"] = { MaxTokens = 5, RefillPerSecond = 1 },
		["BattlePassService.RequestClaimReward"] = { MaxTokens = 5, RefillPerSecond = 1 },
	},

	-- Fallback applied by RateLimitService for any actionKey not listed
	-- above, so a future call site that forgets to add a tuned entry still
	-- gets a sane default instead of being unlimited.
	DefaultRateLimit = { MaxTokens = 10, RefillPerSecond = 5 },
}
