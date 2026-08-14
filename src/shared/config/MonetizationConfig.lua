-- GDD §14.5 / §11. GamePass and Developer Product IDs — filled in by Studio
-- work (STUDIO_TASKS.md S-080-S-083 create them, S-084 fills the IDs here).
-- Placeholder 0s are expected before launch (see T-200's startup assertion,
-- which hard-fails on them pre-publish); this module only warns about them.
--
-- CoinToJadeRate is deliberately absent/nil: Coins can NEVER convert to Jade
-- (§11.1 one-way economy, §9.2/§11 "skill over spend" pillar). Do not add a
-- conversion rate here.

return {
	GamePasses = {
		VIPPassId = 0, -- fill before launch, S-080
		BattlePassId = 0, -- fill before launch, S-081
	},

	JadeProducts = {
		{ ProductId = 0, Jade = 100, Robux = 80 },
		{ ProductId = 0, Jade = 550, Robux = 400 },
		{ ProductId = 0, Jade = 1200, Robux = 800 },
	},

	CoinToJadeRate = nil, -- Coins NOT convertible to Jade (one-way economy, §11.1)

	VIPBoostXP = 0.25, -- §11.3: +25% XP (time-saver, no combat power)
	VIPBoostCoins = 0.25, -- §11.3: +25% Coins
}
