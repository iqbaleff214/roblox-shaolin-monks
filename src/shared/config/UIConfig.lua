-- GDD §14 / §15.2 / §17.4. Colors, fonts, layout anchors, the responsive
-- breakpoint table, and particle-limit quality tiers. §15.2: all UI scripts
-- read breakpoints/sizes from here — no hardcoded pixel offsets anywhere.

return {
	Colors = {
		Primary = Color3.fromRGB(196, 30, 58), -- lacquer red
		Secondary = Color3.fromRGB(212, 175, 55), -- temple gold
		Background = Color3.fromRGB(20, 18, 16),
		Text = Color3.fromRGB(240, 235, 225),
		TextMuted = Color3.fromRGB(160, 152, 140),
		Success = Color3.fromRGB(80, 200, 120),
		Danger = Color3.fromRGB(220, 70, 60),
		RarityCommon = Color3.fromRGB(180, 180, 180),
		RarityUncommon = Color3.fromRGB(90, 200, 110),
		RarityRare = Color3.fromRGB(70, 150, 230),
		RarityEpic = Color3.fromRGB(170, 90, 220),
		RarityLegendary = Color3.fromRGB(230, 170, 40),
	},

	FontSizes = {
		Small = 14,
		Medium = 18,
		Large = 24,
		Title = 32,
	},

	-- §13.4: anchored/relative presets only — never hardcoded pixel offsets.
	LayoutAnchors = {
		TopLeft = Vector2.new(0, 0),
		TopCenter = Vector2.new(0.5, 0),
		TopRight = Vector2.new(1, 0),
		Center = Vector2.new(0.5, 0.5),
		BottomLeft = Vector2.new(0, 1),
		BottomCenter = Vector2.new(0.5, 1),
		BottomRight = Vector2.new(1, 1),
	},

	-- §15.2: three breakpoints, widest to narrowest, in pixels of viewport width.
	Breakpoints = {
		Desktop = 1280,
		Tablet = 768,
		Portrait = 480,
	},

	-- §17.4: particle counts scale down per quality tier (Mobile uses Low/Medium).
	ParticleLimits = {
		High = 200,
		Medium = 100,
		Low = 40,
	},

	-- §5.3/T-082: glow/particle intensity per cosmetic rarity tier. Colors
	-- live in Colors.RarityXxx above (referenced by name, not duplicated
	-- here) — this table only adds the numeric VFX-intensity axis.
	RarityTiers = {
		Common = { GlowIntensity = 0, ParticleDensity = 0 },
		Uncommon = { GlowIntensity = 0.15, ParticleDensity = 1 },
		Rare = { GlowIntensity = 0.35, ParticleDensity = 2 },
		Epic = { GlowIntensity = 0.6, ParticleDensity = 3 },
		Legendary = { GlowIntensity = 1, ParticleDensity = 5 },
	},

	-- T-135 (§15.4/§18). Every feedback FX trigger's on-screen duration.
	FeedbackTimings = {
		HitStopDuration = 0.065, -- seconds; §18 "~0.05-0.08s" on Heavy Attack/Finishing Move impacts
		FinishingMoveOverlayDuration = 1.5,
		BossPhaseFlashDuration = 0.5,
		ContainerPopupDuration = 1,
		FlawlessBannerDuration = 3,
	},
}
