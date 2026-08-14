# TASKS.md — Engineering (Scriptable) Task Breakdown

Derived from `GDD.md` (v0.1, 2026-08-14). This file covers everything buildable in code via Rojo (ModuleScripts, Server/Client scripts, config data, automated tests). Everything that requires hands-on Roblox Studio or website work (building geometry, placing/tagging instances, importing models/animations/audio, creating GamePasses/Developer Products, publishing) lives in `STUDIO_TASKS.md`.

## How the two files fit together

- Every scripted system expects specific Workspace instances to exist and be tagged with `CollectionService` tags. The full tag list and naming convention is defined once, in `STUDIO_TASKS.md` §0 (S-002) — do not redefine tags elsewhere; both files point back to it.
- Tasks reference each other by ID: `T-###` = this file, `S-###` = `STUDIO_TASKS.md`. A task's **Depends on** line lists prerequisites that must be `[x]` before starting.
- Recommended order: Phase 0–1 here (project setup, config) run in parallel with `STUDIO_TASKS.md` Phase 0 (project/tagging setup). After that, engineering phases (combat, enemy AI, weapons, UI logic) and Studio phases (chapter builds, assets, UI layout) proceed in parallel per chapter, converging at Phase 17 (QA) and Phase 18 (pre-launch).
- All gameplay-affecting values must live in the config modules from Phase 1 — no magic numbers in gameplay/UI scripts (GDD §14, hard rule).
- Unit tests use [TestEZ](https://github.com/Roblox/testez) (or equivalent) for pure ModuleScript logic (config schemas, formulas, pure functions). Systems that need live server/client state use an integration test run from the Studio command bar / a dedicated test-mode server script — noted per task where applicable.

**Legend:** `[ ]` not started · `[x]` done.

---

## Phase 0 — Project & Tooling Setup

#### T-000 — Initialize Rojo project structure
**Depends on:** None
**Description:** Set up `rojo.json` / `default.project.json` mapping `src/shared` → `ReplicatedStorage.Shared`, `src/server` → `ServerScriptService`, `src/client` → `StarterPlayer.StarterPlayerScripts`, matching the `src/shared/config/*` layout already specified in GDD §14.1.
**DoD / Expected Output:** `rojo serve` connects to Studio (via S-000) without errors; folder tree exists for `config/`, `services/` (server), `controllers/` (client), `modules/` (shared utility).
**Test Case:** `rojo build` produces a valid `.rbxlx`/place file with no path collisions; manual sync round-trip in Studio preserves folder structure.
- [ ] Done

#### T-001 — Set up automated test harness
**Depends on:** T-000
**Description:** Add TestEZ (or equivalent) under `src/shared/tests` (or a dedicated `tests/` Rojo mount) and a runner script invokable from the Studio command bar and from CI (headless Studio run if available).
**DoD / Expected Output:** Running the harness against an empty test suite reports "0 passed / 0 failed" with no errors.
**Test Case:** A placeholder `SanityTest.spec.lua` asserting `1 + 1 == 2` passes.
- [ ] Done

---

## Phase 1 — Shared Config Modules (GDD §14)

Each config module is pure data (no side effects), matching the example shapes in GDD §14.2–§14.5. Every task below produces one file plus one schema test.

#### T-010 — CombatConfig.lua
**Depends on:** T-000
**DoD / Expected Output:** Returns `Attacks`, `Poise`, `ChiMeter` tables with the fields shown in GDD §14.2 (damage values, `ComboWindow`, `ParryWindow`, `DodgeIFrames`, `DodgeCooldown`, `StaggerThreshold`, `PoiseDecayPerSec`, Chi gain rates).
**Test Case:** TestEZ spec asserts every numeric field is present and `> 0` (or `>= 0` where zero is valid), and table shape matches expected keys exactly (fails on typos/renames).
- [ ] Done

#### T-011 — WeaponConfig.lua
**Depends on:** T-000
**DoD / Expected Output:** One entry per weapon type (Twin Blades, War Staff, Hook Swords, Iron Gauntlets, Battle Glaive per GDD §5.2) with combo string definitions (input sequence → animation ID placeholder → damage multiplier) and an `Ultimate` sub-table (damage, AoE radius/shape, animation ID placeholder, cosmetic FX slot reference).
**DoD note:** Base damage-per-second across all 5 weapons must be within a tunable tolerance band (e.g. ±5%) of each other at default combo efficiency — encodes the "balanced by design" pillar (§5.2) as a checkable constant, not just prose.
**Test Case:** TestEZ spec computes theoretical DPS per weapon from the config and asserts all 5 fall within the tolerance band; fails loudly if a future edit breaks balance.
- [ ] Done

#### T-012 — EnemyConfig.lua
**Depends on:** T-000
**DoD / Expected Output:** Matches GDD §14.3 shape — `ConcurrentAttackerCap`, `AggroRadius`, `AttackTelegraph`, and a `Roles` table for Grunt/Soldier/Heavy/Ranged/Assassin/Elite (+ a `Boss` role added here even though GDD's example omits it, since §4.2 requires one).
**Test Case:** TestEZ spec asserts `ConcurrentAttackerCap` is between 2–3 (per §4.3 design rule) and every role has `Health`, `Damage`, `Poise` at minimum.
- [ ] Done

#### T-013 — ChapterConfig.lua
**Depends on:** T-000
**DoD / Expected Output:** One entry per chapter (8, per GDD §8.1) with: id, display name, difficulty tier (§8.3), level-unlock gate, enemy faction reference (§4.6), signature hazard tag, arena count, boss/mini-boss reference.
**Test Case:** TestEZ spec asserts exactly 8 chapters exist, tiers are one of Novice/Adept/Veteran/Master, and level gates are non-decreasing in chapter order (later chapters never unlock at a lower level than earlier ones).
- [ ] Done

#### T-014 — LootConfig.lua
**Depends on:** T-000
**DoD / Expected Output:** Matches GDD §14.4 — `Containers` (WoodenCrate/ClayUrn/SupplyBarrel/JadeChest with `Hits` + `DropTable`) and `ChestRarityWeights` for Arena/Chapter/Boss/Vault tiers (§10.4).
**Test Case:** TestEZ spec asserts each `ChestRarityWeights` row sums to 100 (fails if a rarity edit breaks the published odds — this table is player-facing per §10.4's transparency rule).
- [ ] Done

#### T-015 — AccessoryConfig.lua
**Depends on:** T-000
**DoD / Expected Output:** Item definitions for Head/Body/Arm/Leg slots (§5.1) with rarity tier (§5.3), unlock source (Shop/BattlePass/Crate/QuestReward), and explicitly **no** combat-stat fields (enforce cosmetic-only by omission).
**Test Case:** TestEZ spec asserts no entry contains a disallowed key (`Damage`, `Health`, `Speed`, etc.) — a lint-style guard against accidental pay-to-win creep.
- [ ] Done

#### T-016 — ProgressionConfig.lua
**Depends on:** T-000
**DoD / Expected Output:** XP formula constants (§9.1 multiplier table), level thresholds, Skill Point costs per node (§9.2), and the capped stat-growth ceiling (must reach its cap by Level 30 per the design rule in §9.2).
**Test Case:** TestEZ spec asserts the stat-growth curve is monotonically non-decreasing and flat (capped) at/after Level 30.
- [ ] Done

#### T-017 — ShopConfig.lua
**Depends on:** T-000
**DoD / Expected Output:** Item definitions, prices (Coins/Jade per §11.2 table), bundle contents, and Jade product references — matches GDD §12.1's "no magic numbers" rule; Combo Scrolls priced here must be Coin-only (cross-check against T-111).
**Test Case:** TestEZ spec asserts every Combo Scroll entry has `Currency = "Coins"` (never `"Jade"`) — encodes the §10.3 rule that technique unlocks are never premium-currency purchasable.
- [ ] Done

#### T-018 — MonetizationConfig.lua
**Depends on:** T-000
**DoD / Expected Output:** Matches GDD §14.5 — `GamePasses` (VIPPassId, BattlePassId), `JadeProducts` (3 tiers), `CoinToJadeRate = nil` (enforced one-way economy), `VIPBoostXP`/`VIPBoostCoins`.
**Test Case:** TestEZ spec asserts `CoinToJadeRate` is `nil`/absent (regression guard against someone "helpfully" adding a conversion rate later). IDs are allowed to be `0` here (filled later per S-084/T-200) but the test flags them as a warning, not a failure, at this stage.
- [ ] Done

#### T-019 — AudioConfig.lua
**Depends on:** T-000
**DoD / Expected Output:** Matches GDD §14.5/§16 — every SFX and Music entry from the §16 table present with `Id`, `Volume`, and `PitchRange` where applicable.
**Test Case:** TestEZ spec asserts every event listed in GDD §16's table has a corresponding config key (catches drift if the GDD's audio list changes without the config being updated).
- [ ] Done

#### T-020 — UIConfig.lua
**Depends on:** T-000
**DoD / Expected Output:** Colors, font sizes, layout anchors, and the responsive breakpoint table (desktop/tablet/portrait per §15.2) plus particle-limit tiers per quality setting (§17.4).
**Test Case:** TestEZ spec asserts breakpoints are strictly ordered (desktop width > tablet width > portrait width).
- [ ] Done

#### T-021 — LocalizationConfig.lua
**Depends on:** T-000
**DoD / Expected Output:** Supported locale list matching §13.1 (8 launch languages) with a fallback chain (unsupported locale → `en`).
**Test Case:** TestEZ spec asserts `en` is always present and is the fallback root (no fallback cycles).
- [ ] Done

#### T-022 — ConfigService.lua aggregator
**Depends on:** T-010–T-021
**DoD / Expected Output:** Matches GDD §14.6 — single `require` point exposing all config modules; no gameplay/UI script requires an individual config file directly.
**Test Case:** TestEZ spec requires `ConfigService` and asserts all 12 sub-keys are non-nil tables. A lint task (T-151) later scans the codebase for direct `config.XConfig` requires bypassing this service.
- [ ] Done

---

## Phase 2 — Movement & Traversal (GDD §3.1)

#### T-030 — CharacterController (client)
**Depends on:** T-010, S-040
**Description:** Run, jump, double-jump (gated by skill tree unlock), ledge grab/climb, wall-run on tagged surfaces.
**DoD / Expected Output:** All movement states work across PC/mobile/console input (via T-130) at the target FPS per platform (§17.4). Double-jump is disabled until the corresponding Skill Point node (T-091) is purchased.
**Test Case:** Manual/integration: spawn character, verify jump count is capped at 1 pre-unlock and 2 post-unlock; wall-run only engages on parts tagged `WallRunnable`.
- [ ] Done

#### T-031 — Dodge roll i-frame system
**Depends on:** T-010, T-030
**Description:** Server-validated invincibility window during dodge roll per `CombatConfig.Attacks.DodgeIFrames`/`DodgeCooldown`.
**DoD / Expected Output:** Damage instances landing within the i-frame window are rejected server-side; cooldown prevents spam-dodging as a de facto invulnerability loop.
**Test Case:** Integration test: simulate an attack timestamp inside vs. outside the i-frame window; assert damage is blocked only in the former.
- [ ] Done

#### T-032 — Traversal interactable framework
**Depends on:** T-000, S-002
**Description:** Generic tag-driven component system for `Lever`, `PressurePlate`, `CollapsingWalkway` (§3.1) — one ModuleScript framework, not per-instance bespoke scripts, so level designers in Studio can drop and configure instances via attributes.
**DoD / Expected Output:** Any Studio-placed instance with one of these tags and the documented attributes (see S-002) activates correctly with no additional script authoring per chapter.
**Test Case:** Integration test: tag a test part `PressurePlate`, verify the bound event fires exactly once per press and respects a configurable reset delay.
- [ ] Done

---

## Phase 3 — Combat System (GDD §3.2–§3.9, §17.1–§17.2)

#### T-040 — Unified input action mapping
**Depends on:** T-000
**Description:** Map raw PC/mobile/console inputs (GDD §6 tables) to a single set of logical actions (`LightAttack`, `HeavyAttack`, `Block`, `Dodge`, `Grab`, `Interact`, `ThrowWeapon`, `Ultimate`, `LockOn`) so all downstream combat code is input-device-agnostic.
**DoD / Expected Output:** Every action in the §6 tables for all three platforms fires the correct logical action; no combat code references raw `UserInputType`/`KeyCode` directly.
**Test Case:** TestEZ-style unit test on the mapping table itself (pure data) plus manual verification per platform (ties into S-110/S-111/S-112).
- [ ] Done

#### T-041 — Combo buffer / attack string system
**Depends on:** T-010, T-011, T-040
**Description:** Buffers Light/Heavy inputs into strings per weapon's combo tree (T-011), respecting `ComboWindow`; string length/finishers gated by owned Combo Scrolls (T-111).
**DoD / Expected Output:** Un-owned combo extensions are simply unavailable (input has no effect past the owned string length) rather than erroring.
**Test Case:** Integration test: feed a scripted input sequence, assert the resulting combo step matches the weapon's combo tree and stops at the player's unlocked depth.
- [ ] Done

#### T-042 — Attack hit detection (client-predicted + server-reconciled)
**Depends on:** T-041, T-060
**Description:** Implements the lag-compensation model from GDD §17.1: client plays hit feedback instantly; server rewinds enemy hitboxes to the attacker's input timestamp before committing damage; client-side speculative FX are silently retracted on server rejection.
**DoD / Expected Output:** No visible rubber-banding/position snapping on rejected hits; server is sole authority on whether damage is applied.
**Test Case:** Integration test with artificial latency injection (e.g. 150ms simulated) confirming hits still register fairly for the attacker and enemy HP only changes after server confirmation.
- [ ] Done

#### T-043 — Block, Parry & Dodge system
**Depends on:** T-010, T-040
**Description:** Hold-to-block damage reduction + stagger-buildup prevention; Perfect Parry timing window (`ParryWindow`) fully negates damage and stuns attacker.
**DoD / Expected Output:** Parry input outside the window degrades to a normal block (partial mitigation), never a whiff-punish for the player.
**Test Case:** Integration test sweeping input timing from -200ms to +200ms relative to impact, asserting Perfect Parry only triggers inside `ParryWindow`.
- [ ] Done

#### T-044 — Grapple, throw & environmental kill system
**Depends on:** T-046 (staggered state), S-002 (HazardZone tag)
**Description:** Grab staggered enemy → throw into another enemy (both take damage) or into a tagged `HazardZone` (instant kill + bonus relic drop per §3.4).
**DoD / Expected Output:** Human-shield behavior (§3.4) absorbs 1–2 ranged hits before the shielded enemy is dropped/killed.
**Test Case:** Integration test: throw a grabbed enemy into a `HazardZone`-tagged part, assert instant death + bonus drop event fires exactly once.
- [ ] Done

#### T-045 — Weapon pickup / disarm / throw system
**Depends on:** T-011, T-060
**Description:** Implements §3.5 — enemy weapon drop on disarm (chance-based on Heavy Attack vs. blocking enemy), environmental weapon pickup, temporary secondary-weapon combo + throw, main weapon is never lost.
**DoD / Expected Output:** A thrown secondary weapon becomes a lootable world item on impact (retrievable) unless it hits an enemy, matching §3.5's "lost unless retrieved" rule.
**Test Case:** Integration test: force a disarm roll to succeed, assert enemy loses block capability and a pickup item spawns at their weapon socket.
- [ ] Done

#### T-046 — Stagger / Poise / Finishing Move system
**Depends on:** T-010, T-042
**Description:** Poise meter fills on hits, decays per `PoiseDecayPerSec` when untouched, triggers Staggered state at `StaggerThreshold`; Staggered enemies accept a context Finishing Move input that grants bonus Coins + guaranteed relic (§3.9, §10.2/§10.4 hookup).
**DoD / Expected Output:** Bosses/Elites use this same Poise system but gate phase transitions instead of an instant finisher (hands off to T-065).
**Test Case:** Integration test: apply hits until Poise crosses threshold, assert Staggered state fires once and Finishing Move input is only accepted in that state.
- [ ] Done

#### T-047 — Chi meter & Ultimate activation
**Depends on:** T-010, T-071
**Description:** Chi fills from `GainPerHitDealt`/`GainPerHitTaken`, caps at `Max`; Ultimate button executes the equipped weapon's Ultimate (T-071/T-072) and resets meter to 0.
**DoD / Expected Output:** Ultimate cannot be triggered below 100 Chi; server is authoritative on the meter value (client only renders it).
**Test Case:** Integration test: attempt Ultimate activation at 99 and 100 Chi, assert rejection/success respectively.
- [ ] Done

#### T-048 — Combo Counter & Style Score tracking
**Depends on:** T-041, T-046
**Description:** Rolling ~2s hit window extends a live Combo Counter (§3.7); counter feeds a per-arena Style Score used for the reward multiplier (§9.1, §10.1).
**DoD / Expected Output:** Combo reset on hit-taken or timeout does not retroactively reduce Style Score already banked from that combo (per §3.7's "does not penalize already-earned rewards" rule).
**Test Case:** Integration test: build a combo, get hit (reset), verify Style Score total is unaffected by the reset event itself.
- [ ] Done

#### T-049 — CombatService (server, authoritative)
**Depends on:** T-042, T-043, T-046, T-047
**Description:** Single server-side service owning all damage resolution, currency/XP grants from combat, and validation against `CombatConfig`/`EnemyConfig` — the enforcement point for §17.2 Anti-Cheat.
**DoD / Expected Output:** No other server script writes damage/currency/XP directly; all combat-sourced state changes route through this service.
**Test Case:** Integration test (see also T-170): attempt to fire a damage-granting RemoteEvent directly bypassing CombatService and assert it is rejected/ignored.
- [ ] Done

#### T-050 — Concurrent-attacker-cap token system
**Depends on:** T-012, T-060
**Description:** Server-side token queue enforcing the 2–3 concurrent-attacker cap (§4.3/§4.4) so only capped enemies are in an "attacking" state at once; others hold in the ring/circling state.
**DoD / Expected Output:** With N enemies aggroed in an arena, at most `EnemyConfig.ConcurrentAttackerCap` are ever in the Attacking state simultaneously, verified under load with the max enemy count expected in a Master-tier wave.
**Test Case:** Integration test: aggro 8 enemies onto one target, assert active-attacker count never exceeds the configured cap across a sampled time window.
- [ ] Done

---

## Phase 4 — Enemy AI System (GDD §4)

#### T-060 — Base EnemyController state machine
**Depends on:** T-012, S-030
**Description:** Server-side state machine (Idle → Aggro → Circling → Attacking → Staggered → Dead) shared by all enemy roles; role-specific behavior (T-062) plugs into this via config, not by forking the state machine.
**DoD / Expected Output:** One controller module handles all 7 roles + reskins purely through `EnemyConfig.Roles` data — no per-faction code duplication (faction reskins are asset-only, per S-031).
**Test Case:** Integration test: spawn a Grunt and a Heavy from the same controller with different config, assert distinct Health/Damage/Poise values are respected.
- [ ] Done

#### T-061 — Arena Gate controller
**Depends on:** T-000, S-002
**Description:** Tag-driven (`ArenaGate` + `ArenaSpawnPoint`) system: seals gates on party entry, sequences wave spawns (next wave a beat after previous clears, §4.1), unseals and spawns loot chest on full clear.
**DoD / Expected Output:** No retreat possible while sealed (gate is physically/collision blocking, not just a soft warning); multi-wave arenas never spawn wave N+1 before wave N is fully cleared.
**Test Case:** Integration test: enter a test arena, verify gate collision engages, kill all wave-1 enemies, assert wave-2 spawns only after a short delay and gate stays sealed until wave-2 also clears.
- [ ] Done

#### T-062 — Enemy role behaviors (data-driven)
**Depends on:** T-060, T-012
**Description:** Implements behavior differences for Grunt/Soldier(blocks)/Heavy(armored, high poise)/Ranged(kites, projectiles)/Assassin(flanks, dodges)/Elite(expanded moveset + Ultimate-style attack)/Boss(multi-phase, hands off to T-065).
**DoD / Expected Output:** Soldier blocks incoming attacks (requiring Heavy Attack or Disarm per §4.2); Ranged maintains `AttackRange` distance instead of closing to melee; Assassin's `MoveSpeedMult` is reflected in actual movement speed.
**Test Case:** Integration test per role: verify the one distinguishing behavior listed in the GDD §4.2 table actually manifests (e.g., a Soldier's block reduces incoming Light Attack damage to near-zero until disarmed).
- [ ] Done

#### T-063 — Attack telegraph system
**Depends on:** T-060
**Description:** Windup flash/audio cue fires `AttackTelegraph` seconds before an enemy's hit lands (§4.4), giving players a fair reaction window.
**DoD / Expected Output:** Telegraph timing is config-driven (not hardcoded per animation), so tuning `EnemyConfig.AttackTelegraph` changes all enemies uniformly.
**Test Case:** Integration test: trigger an enemy attack, measure elapsed time between telegraph event and hit-resolution event, assert it matches config within a small tolerance.
- [ ] Done

#### T-064 — Wave composition & difficulty scaling
**Depends on:** T-012, T-013, T-123
**Description:** Wave enemy count/mix scales by chapter `ChapterConfig` difficulty tier and current party size (§4.3, §12.3 hookup) so solo and full-party runs feel equivalently challenging.
**DoD / Expected Output:** A solo run and a 4-player run of the same arena produce different total enemy HP/count but a comparable per-player difficulty curve (documented scaling formula, not ad hoc per-arena tuning).
**Test Case:** Integration test: request wave composition for the same arena at party size 1 and 4, assert scaling formula output matches expected values.
- [ ] Done

#### T-065 — Boss phase-transition system
**Depends on:** T-046, T-062
**Description:** Splits boss HP into phases (typically 3, §4.5); crossing a threshold triggers a brief invulnerable transition (no damage accepted), then a moveset/environment change; each phase exposes one grab-counter window and one parry-punish window.
**DoD / Expected Output:** Elite Champions reuse this same module with a single-phase configuration (per §4.5's "condensed 1-phase version" rule) rather than a separate implementation.
**Test Case:** Integration test: damage a test boss down to a phase threshold, assert a brief invulnerability window is honored (over-damage during transition is not applied) before phase-2 behavior activates.
- [ ] Done

#### T-066 — Enemy spawn/despawn pooling
**Depends on:** T-060
**Description:** Object-pools enemy instances per arena to avoid Instance-creation spikes during wave spawns, supporting the §17.4 performance targets.
**DoD / Expected Output:** Repeated arena clears in a single session (Practice Mode replay, §7.2) do not leak un-despawned enemy instances.
**Test Case:** Integration test: clear the same arena 5 times in a loop, assert live enemy-instance count returns to 0 after each clear and memory/instance count doesn't grow monotonically.
- [ ] Done

---

## Phase 5 — Weapon & Ultimate System (GDD §5.2, §3.5–§3.6)

#### T-070 — Weapon equip / loadout lock system
**Depends on:** T-011, T-081
**Description:** Server-authoritative Main Weapon selection in the Lobby (§5.2); locked for the duration of a battlefield run once the party enters (no mid-run weapon swap).
**DoD / Expected Output:** A RemoteEvent attempting to change equipped weapon while inside a battlefield instance is rejected server-side.
**Test Case:** Integration test: attempt weapon swap in Lobby (should succeed) vs. inside an active chapter instance (should be rejected).
- [ ] Done

#### T-071 — Per-weapon combo tree + animation hookup
**Depends on:** T-011, S-041, S-042
**Description:** Wires each of the 5 weapon types' combo strings (T-041) to their Studio-authored animation IDs (S-042), including air combo and running-attack variants (§3.2).
**DoD / Expected Output:** Every combo tree node in `WeaponConfig` resolves to a valid, non-placeholder animation ID before this task is marked done.
**Test Case:** TestEZ spec asserts no `AnimationId` field in `WeaponConfig` is still the placeholder value (`0`/empty string) once S-042 delivers real IDs.
- [ ] Done

#### T-072 — Ultimate ability execution framework
**Depends on:** T-047, T-011, S-043
**Description:** Executes the 5 unique Ultimate techniques (Whirlwind Strike, Heaven's Sweep, Serpent's Coil, Mountain Breaker, Dragon's Arc — §5.2) as config-driven damage/AoE effects, with cosmetic FX resolved from a separate skin-layer (§3.6 — function and cosmetics decoupled).
**DoD / Expected Output:** Swapping a player's Ultimate FX skin (purchased cosmetic) never changes the Ultimate's damage/AoE — verified by the same functional test passing regardless of equipped skin.
**Test Case:** Integration test: execute each of the 5 Ultimates against a test dummy cluster, assert damage/AoE matches config; repeat with 2 different FX skins equipped and assert identical functional results.
- [ ] Done

---

## Phase 6 — Character Customization (GDD §5.1, §5.3)

#### T-080 — Accessory equip system
**Depends on:** T-015, S-050–S-053
**Description:** Equip/unequip logic for Head/Body/Arm/Leg slots; purely cosmetic — no stat hook exists anywhere in this system (enforced by T-015's schema already excluding stat fields).
**DoD / Expected Output:** Equipping any combination of accessories produces zero measurable change to `CombatService` outputs (damage, HP, speed).
**Test Case:** Integration test: run a fixed combat scenario with no accessories vs. full Legendary-tier accessories equipped, assert identical damage/HP/timing results.
- [ ] Done

#### T-081 — Inventory system
**Depends on:** T-160
**Description:** Tracks owned accessories, weapon skins, Ultimate FX skins, emotes, Spirit Companions; backed by `PlayerDataService` (T-160).
**DoD / Expected Output:** Inventory grants (from shop purchase, crate, quest reward, chapter completion) are idempotent — granting the same item twice never duplicates an entry, only adjusts a quantity/duplicate-conversion path (T-103).
**Test Case:** Integration test: grant the same cosmetic item twice, assert inventory count logic routes the second grant through duplicate-protection (T-103) rather than creating two entries.
- [ ] Done

#### T-082 — Cosmetic rarity visual tier system
**Depends on:** T-015, S-054–S-057
**Description:** Applies tier-appropriate particle/glow effects (Common → Legendary, §5.3) to equipped cosmetics at render time.
**DoD / Expected Output:** Visual tier is derived purely from the item's `Rarity` field — no separate "is legendary" flags to keep in sync.
**Test Case:** Integration test: equip one item per rarity tier, assert the correct VFX preset is applied for each.
- [ ] Done

---

## Phase 7 — Progression System (GDD §9, §10.1)

#### T-090 — XP & Level system
**Depends on:** T-016, T-048
**Description:** Server-authoritative XP grant using `BaseXP × DifficultyMultiplier × StyleScoreMultiplier` (§9.1); level-up unlocks Skill Points, not raw stats.
**DoD / Expected Output:** XP is only ever written by server code that has validated the source (chapter clear, quest, daily bonus) — never client-supplied.
**Test Case:** Integration test: simulate a Flawless clear vs. a multi-death clear of the same chapter, assert XP output ratio matches the 2.5×/0.5× multiplier table.
- [ ] Done

#### T-091 — Skill Tree system
**Depends on:** T-016, T-090
**Description:** Server-validated Skill Point spend on nodes (extended combos, double-jump, dodge cooldown, parry window, weapon retrieval speed, capped HP/Chi growth) per §9.2.
**DoD / Expected Output:** Stat-growth nodes cannot be purchased past the Level-30 cap defined in `ProgressionConfig` (T-016) even if the player has banked enough points — enforces the "same combat ceiling for everyone" pillar.
**Test Case:** Integration test: attempt to purchase a capped stat node beyond its max rank, assert rejection.
- [ ] Done

#### T-092 — Mastery Stars calculation
**Depends on:** T-048, T-090
**Description:** 0–3 stars per chapter from Style Score, damage taken, and clear time (§9.3); milestone totals (15/40/75/120) unlock permanent cosmetics.
**DoD / Expected Output:** Star calculation is a pure function of the three inputs (testable without live gameplay) so tuning thresholds doesn't require a full replay to verify.
**Test Case:** TestEZ spec feeds boundary-value inputs (just below/at/above each threshold) and asserts correct star count.
- [ ] Done

#### T-093 — Daily / Weekly Quest system
**Depends on:** T-160
**Description:** Quest definitions, progress tracking, and reward grant for the examples in §9.4 (Finishing Moves landed, containers broken, chapterless-death clears, Trial Rush wins, boss variety, hidden containers found).
**DoD / Expected Output:** Quest progress persists across sessions (via T-160) and resets on the correct cadence (daily = midnight UTC per §7.4, weekly = matches §9.7/§7.3 reset).
**Test Case:** Integration test: simulate quest-qualifying actions, assert progress increments correctly and resets at the configured boundary.
- [ ] Done

#### T-094 — Streak system
**Depends on:** T-160
**Description:** Login streak (day 7 = premium drop) and in-run consecutive-Flawless-arena streak bonus (§9.5).
**DoD / Expected Output:** A missed login day resets the streak counter to 0, not to 1 (common off-by-one bug to guard against explicitly).
**Test Case:** Integration test: simulate logins on days 1,2,3, skip day 4, log in day 5 — assert streak counter is 1 (fresh start), not 4.
- [ ] Done

#### T-095 — Leaderboard system
**Depends on:** T-090, T-092
**Description:** Per-chapter best clear time + Style Score (all-time and weekly), friends-prioritized display, separate Trial Rush weekly board (§9.7, §7.3).
**DoD / Expected Output:** Uses `OrderedDataStore` (or equivalent) with weekly boards resetting on schedule without losing all-time records.
**Test Case:** Integration test: submit scores from multiple simulated players, assert correct ordering and that a weekly reset does not clear the all-time board.
- [ ] Done

---

## Phase 8 — Loot & Destructible System (GDD §3.8, §10.2, §10.4)

#### T-100 — Destructible container component
**Depends on:** T-000, S-002
**Description:** Tag-driven (`DestructibleContainer`) component reading `Hits`/`DropTable` attributes (per container type in §10.2); breaks after N hits, respawns only on a fresh map instance (never mid-run, per §3.8).
**DoD / Expected Output:** One generic component handles all 4 container types (Wooden Crate/Clay Urn/Supply Barrel/Jade Chest) purely via attributes — no per-type script forking.
**Test Case:** Integration test: hit a tagged container the configured number of times, assert it breaks exactly on the last hit (not before/after) and does not respawn within the same run.
- [ ] Done

#### T-101 — Drop table roller
**Depends on:** T-014, T-100
**Description:** Server-seeded RNG roll (per-instance seed, per §17.5) consuming `LootConfig` drop tables on container break / enemy kill.
**DoD / Expected Output:** Roll outcomes are logged with the instance seed for anti-cheat auditing (§17.5), and are reproducible given the same seed (supports the Daily Relic Hunt shared-seed requirement, §7.4).
**Test Case:** Integration test: roll the same seed twice, assert identical output sequence.
- [ ] Done

#### T-102 — Chest system (Arena/Chapter/Boss/Vault)
**Depends on:** T-014, T-061
**Description:** Spawns the appropriate chest tier on arena clear / chapter complete / boss defeat / hidden-vault discovery, rolling rarity per §10.4's weight tables.
**DoD / Expected Output:** Chest rarity distribution over a large sample (e.g. 10,000 simulated rolls) matches the published weights within statistical tolerance.
**Test Case:** Integration/statistical test: run 10,000 simulated Arena Chest rolls, assert observed rarity frequencies are within ~2% of the 60/25/10/4/1 table.
- [ ] Done

#### T-103 — Duplicate-protection conversion logic
**Depends on:** T-081, T-102
**Description:** Converts duplicate cosmetic pulls to Coins at a fixed rate (§10.4, §11.6) instead of granting a second copy.
**DoD / Expected Output:** Conversion rate is config-driven (in `ShopConfig` or `LootConfig`), not hardcoded inline.
**Test Case:** Integration test: grant an already-owned cosmetic via a chest roll, assert Coins increase by the configured rate and inventory count for that item does not change.
- [ ] Done

---

## Phase 9 — Reward, Shop & Monetization Scripts (GDD §10.3, §11)

#### T-110 — Currency system
**Depends on:** T-018, T-160
**Description:** Server-authoritative Coins and Jade Shards; enforces the one-way economy (Coins never convert to Jade, per T-018's `CoinToJadeRate = nil` guard).
**DoD / Expected Output:** Every currency mutation goes through one function (`GrantCurrency`/`SpendCurrency`) that logs source and validates against negative balances.
**Test Case:** Integration test: attempt to spend more Coins than the player has, assert rejection with no partial deduction.
- [ ] Done

#### T-111 — Combo Scroll Shop (Sifu's Dojo) purchase logic
**Depends on:** T-017, T-110, T-041
**Description:** Coins-only purchase flow unlocking Combo Scrolls (extended combo strings, finishers, weapon techniques) per §10.3; gated against `ProgressionConfig` prerequisites where applicable.
**DoD / Expected Output:** No code path allows a Combo Scroll purchase using Jade Shards, even via a malformed/replayed client request — server checks `ShopConfig` currency type server-side, not client-declared.
**Test Case:** Integration test: send a purchase request with a spoofed "Jade" currency flag for a Combo Scroll item, assert server rejects it and falls back to the Coins price from config.
- [ ] Done

#### T-112 — Cosmetic Shop purchase logic
**Depends on:** T-017, T-110, T-081
**Description:** Coins/Jade priced cosmetic purchases (§11.2) granting into inventory (T-081).
**DoD / Expected Output:** Purchase price is always read server-side from `ShopConfig`, never trusted from the client request payload.
**Test Case:** Integration test: send a purchase request with a client-supplied price of `0`, assert the server charges the configured price instead.
- [ ] Done

#### T-113 — GamePass purchase handling (VIP)
**Depends on:** T-018, T-110, S-080
**Description:** On VIP GamePass ownership: apply +25% XP/Coin boost (T-090/T-110 hookup), grant VIP Training Hall access, VIP badge, monthly cosmetic drop while active (§11.3).
**DoD / Expected Output:** Boost application checks live ownership via `MarketplaceService:UserOwnsGamePassAsync` (not a cached/DataStore flag alone) to avoid stale-ownership exploits after a potential refund.
**Test Case:** Integration test (mocked `MarketplaceService`): toggle simulated ownership true/false, assert boost application follows it each session.
- [ ] Done

#### T-114 — Developer Product purchase handling (Jade Shards)
**Depends on:** T-018, T-110, S-082
**Description:** `ProcessReceipt` implementation for the 3 Jade Shard product tiers (§14.5); must be idempotent (a receipt is never double-granted, per Roblox's `ProcessReceipt` contract).
**DoD / Expected Output:** Handles the case where `ProcessReceipt` is called again for an already-granted purchase ID (e.g. after a server restart) by returning `PurchaseGranted` without re-granting currency.
**Test Case:** Integration test (mocked receipt): call the handler twice with the same `PurchaseId`, assert Jade Shards are only credited once.
- [ ] Done

#### T-115 — Battle Pass system
**Depends on:** T-090, T-018, S-081
**Description:** 50-tier seasonal pass; free track always active, premium track unlocked via GamePass/Product ownership; tier XP separate from player-level XP (§11.4).
**DoD / Expected Output:** Premium-track rewards are withheld (not previewed as claimable) for non-owners, but tier progress still accrues so a later purchase retroactively unlocks earned tiers.
**Test Case:** Integration test: advance tier progress without premium ownership, then grant ownership, assert all previously-earned premium rewards become claimable immediately (not just future tiers).
- [ ] Done

#### T-116 — Limited-time item rotation system
**Depends on:** T-017
**Description:** 48-hour rotating cosmetics and holiday bundles (§11.5); enforces items never return after their window closes.
**DoD / Expected Output:** A "never returns" list persists server-side so a config revert/typo can't accidentally re-offer an expired item.
**Test Case:** Integration test: expire an item, then attempt to re-add an identical item ID to the active rotation, assert it's blocked by the permanent-expiry record.
- [ ] Done

#### T-117 — Cosmetic Crate opening system
**Depends on:** T-014, T-101, T-103
**Description:** Opens crates earned via gameplay or purchased with Jade Shards, rolling against the published `LootConfig` odds (§11.6); routes through duplicate-protection (T-103).
**DoD / Expected Output:** No direct Robux-to-crate purchase path exists anywhere in the purchase flow (§11.6 policy compliance) — crates are only obtained via gameplay or Jade (itself Robux-purchased, but with a currency step in between, per Roblox UGC policy).
**Test Case:** Integration test / code audit: assert no `ProcessReceipt` handler grants a crate directly; all crate grants trace back to gameplay events or Jade-currency spend.
- [ ] Done

---

## Phase 10 — Lobby, Party & Social Systems (GDD §12)

#### T-120 — Party system
**Depends on:** T-000
**Description:** Party leader invites up to 3 friends (party of 4 total, §12.2); party state (members, leader, ready status) synced across clients.
**DoD / Expected Output:** Leader-only actions (kick, start) are rejected server-side if attempted by a non-leader.
**Test Case:** Integration test: non-leader member attempts to start the chapter, assert rejection; leader attempts same, assert success.
- [ ] Done

#### T-121 — Party teleport to battlefield instance
**Depends on:** T-120, T-013
**Description:** Teleports the full party together into a reserved server for the selected chapter (§12.2); solo players may also launch alone or matchmake into an open party.
**DoD / Expected Output:** All party members land in the same server instance, or the teleport is retried/rolled back for the whole party (no partial-party splits).
**Test Case:** Integration test: simulate a mid-teleport failure for one member, assert the system either retries or returns the whole party to Lobby rather than leaving them split.
- [ ] Done

#### T-122 — Party chat channel persistence
**Depends on:** T-120
**Description:** Party chat channel persists across chapter loads/teleports (§12.2).
**DoD / Expected Output:** Chat history/channel membership survives a teleport without requiring players to re-join manually.
**Test Case:** Integration test: send a party chat message, teleport, assert channel is still active without a rejoin action.
- [ ] Done

#### T-123 — Solo/co-op difficulty scaling hook
**Depends on:** T-064, T-120
**Description:** Exposes current party size to the wave-composition scaler (T-064) so difficulty scales consistently (§4.3, §12.2).
**DoD / Expected Output:** Party-size changes mid-run (a member disconnects) re-scale future waves in the same arena, not just future arenas.
**Test Case:** Integration test: start a 4-player arena, drop to 2 players mid-arena, assert the next wave in that arena scales for 2, not 4.
- [ ] Done

#### T-124 — Revive system
**Depends on:** T-049, T-120
**Description:** Downed players enter "Fallen" state, revivable by a nearby teammate (short animation, vulnerable during, §12.3); whole-party-down restarts the current wave only, not the chapter.
**DoD / Expected Output:** Reviver is vulnerable to interruption (taking damage during revive cancels it) per the "vulnerable during" design note.
**Test Case:** Integration test: start a revive, damage the reviver mid-animation, assert revive is cancelled and target remains Fallen.
- [ ] Done

#### T-125 — Social hook broadcasts
**Depends on:** T-046, T-048, T-065
**Description:** "FINISH!" callout to nearby teammates, party-wide Flawless banner, hub-wide boss-defeat announcement + fireworks (§12.4).
**DoD / Expected Output:** Hub-wide announcements only reach players currently in the Lobby server (§12.4 explicit scope), not a global cross-server broadcast.
**Test Case:** Integration test: trigger a boss defeat, assert the announcement event fires only to Lobby-server-connected clients.
- [ ] Done

#### T-126 — NPC vendor interaction framework
**Depends on:** T-000, S-012, S-013, S-014
**Description:** Generic dialog/purchase-menu trigger system for tagged `NPCVendor` instances (Sifu's Dojo, Cosmetic Shop stall, Battle Pass board), routing to the correct shop UI (T-064/T-134 style) per vendor type attribute.
**DoD / Expected Output:** Adding a new vendor in Studio (tag + attribute) requires no new script — purely config/attribute driven.
**Test Case:** Integration test: interact with each tagged vendor type, assert the correct shop menu opens.
- [ ] Done

#### T-127 — Private server settings
**Depends on:** T-013, T-064
**Description:** Host-configurable chapter selection, difficulty-scaling override, and cosmetic-only "mirror match" dummy settings for private servers (§12.5).
**DoD / Expected Output:** Overrides apply only within that private server instance and never affect public matchmaking pools or leaderboard eligibility (a private-server run should not silently count toward weekly leaderboards if difficulty was overridden — flag and exclude such runs).
**Test Case:** Integration test: run a chapter with an overridden difficulty in a private server, assert the resulting score is excluded from leaderboard submission.
- [ ] Done

---

## Phase 11 — UI/UX Scripts (GDD §15, §6)

#### T-130 — Input scheme auto-detection
**Depends on:** T-040
**Description:** Detects PC/mobile/console input at runtime and switches active control bindings + on-screen prompts accordingly (§6).
**DoD / Expected Output:** Switching input device mid-session (e.g. plugging in a gamepad) live-updates prompts without requiring a rejoin.
**Test Case:** Integration test: simulate an input-type change event, assert control prompt UI updates within one frame.
- [ ] Done

#### T-131 — Combat HUD controller
**Depends on:** T-046, T-047, T-048, S-060
**Description:** Logic layer binding live HP/Chi/Combo/party-frame data to the Studio-built ScreenGui (S-060) per the §15.1 mockup.
**DoD / Expected Output:** HUD stays minimal outside combat and expands (combo counter, party HP bars) exactly on arena-gate-seal (T-061 hookup), not on a fixed timer.
**Test Case:** Integration test: enter an arena, assert HUD expansion event fires in sync with the gate-seal event, not before/after.
- [ ] Done

#### T-132 — Responsive layout manager
**Depends on:** T-020, S-061
**Description:** Detects viewport size/aspect ratio, applies the correct breakpoint (desktop/tablet/portrait, §15.2) from `UIConfig`, respects safe-area insets on notched devices.
**DoD / Expected Output:** No UI script hardcodes a pixel offset; all positioning is anchor/scale-based or breakpoint-table-driven.
**Test Case:** Integration test: simulate 3 representative viewport sizes (ultrawide, standard tablet, narrow portrait), assert the correct breakpoint layout is selected for each.
- [ ] Done

#### T-133 — Menu flow controller
**Depends on:** S-062
**Description:** Drives the Lobby → Chapter Select → Party Setup → Loadout Check → Ready → Load flow (§15.3), with back-navigation from every screen.
**DoD / Expected Output:** No dead-end screen exists — every menu state has a valid back action reachable without a rejoin.
**Test Case:** Integration test: from every menu state, assert a back-navigation path exists back to Lobby.
- [ ] Done

#### T-134 — Settings menu logic
**Depends on:** S-063, T-141, T-150
**Description:** Audio volume (music/SFX separate), control scheme, graphics quality, lock-on assist toggle, language selection (§15.3).
**DoD / Expected Output:** Settings persist via T-160 and apply immediately without requiring a rejoin/reload.
**Test Case:** Integration test: change a setting, assert the corresponding live system (e.g. music volume) updates within the same session, and the value survives a simulated relog.
- [ ] Done

#### T-135 — Feedback FX triggers
**Depends on:** T-046, T-065, T-100, S-065
**Description:** Hit-stop freeze-frame, Finishing Move overlay, Flawless banner, boss-phase-transition screen flash, container-break popup (§15.4, §18).
**DoD / Expected Output:** Hit-stop duration and all overlay timings are config-driven (`UIConfig`/`CombatConfig`), matching the specific values noted in §18 (e.g. ~0.05–0.08s hit-stop).
**Test Case:** Integration test: trigger each feedback event, assert timing/duration matches the configured value within tolerance.
- [ ] Done

#### T-136 — Mobile touch control bindings
**Depends on:** T-040, S-060
**Description:** Virtual joystick, attack/block/dodge/grab/ultimate buttons (§6.2); enforces the ≥44px tap-target rule.
**DoD / Expected Output:** A layout-validation check (can run in Studio or as an automated screenshot/measurement test) confirms every interactive mobile control element meets the 44px minimum at the smallest supported viewport.
**Test Case:** Integration test: measure rendered size of each mobile control button at the smallest supported breakpoint, assert all are ≥44px.
- [ ] Done

---

## Phase 12 — Audio System (GDD §16)

#### T-140 — AudioManager
**Depends on:** T-019, S-070–S-072
**Description:** SFX playback pooling (avoids sound-instance spam), music stem layering (combat vs. exploration swap on arena-gate-seal, §16), per-chapter ambient loop switching.
**DoD / Expected Output:** Combat music stem swap is driven by the same gate-seal/unseal events as T-131's HUD expansion (single source of truth for "in combat" state).
**Test Case:** Integration test: seal an arena gate, assert combat music stem activates within one beat/measure boundary (not an abrupt cut).
- [ ] Done

#### T-141 — Volume settings hookup
**Depends on:** T-140, T-134
**Description:** Independent music/SFX sliders; no audio autoplay on the Roblox game page (policy compliance, §16).
**DoD / Expected Output:** Volume changes apply to already-playing sounds immediately, not only newly-started ones.
**Test Case:** Integration test: start a looping ambient sound, change the SFX/music slider, assert the live sound's volume updates without restart.
- [ ] Done

---

## Phase 13 — Localization System (GDD §13)

#### T-150 — LocalizationService wrapper
**Depends on:** T-021, S-090
**Description:** Wraps `LocalizationService:GetTranslator()` with the fallback chain from `LocalizationConfig` (§13.2).
**DoD / Expected Output:** Any missing translation key falls back to `en` rather than displaying a raw key string to the player.
**Test Case:** Integration test: request a key that only exists in `en`, from a client set to another locale, assert the `en` string is returned (not the key name).
- [ ] Done

#### T-151 — Hardcoded-string lint / audit tool
**Depends on:** T-150
**Description:** CI-style script scanning UI/gameplay source for string literals rendered to players that don't route through the translator (§13.2's "no hardcoded strings" rule).
**DoD / Expected Output:** Produces a report of violations; zero violations required before Phase 18 sign-off.
**Test Case:** Run the lint against a deliberately-seeded hardcoded string, assert it's flagged.
- [ ] Done

#### T-152 — Locale-aware numeric/date formatting utility
**Depends on:** T-021
**Description:** Formats large numbers (currency, Style Score) and dates per locale (decimal/thousands separators, local timezone, §13.2).
**DoD / Expected Output:** Same underlying value renders differently for at least two locales with different separator conventions (e.g. `1,000` vs `1.000`) in a side-by-side test.
**Test Case:** TestEZ spec: format `1234567` under two different locale configs, assert expected separator output for each.
- [ ] Done

---

## Phase 14 — Data Persistence (GDD §17.3)

#### T-160 — PlayerDataService
**Depends on:** T-000
**Description:** `DataStoreService`-backed storage for level, XP, Coins, Jade, inventory, skill tree allocation, chapter progress, quest progress, mastery stars, streak (§17.3).
**DoD / Expected Output:** Single service is the only code path that touches the player DataStore — no other script calls `DataStoreService` directly.
**Test Case:** Integration test: write via the service, simulate a server restart (fresh session), read back, assert values match.
- [ ] Done

#### T-161 — Auto-save hooks
**Depends on:** T-160
**Description:** Saves on chapter completion and Lobby return (§17.3), not only on player-leaving (which risks data loss on crashes).
**DoD / Expected Output:** A simulated ungraceful disconnect immediately after a chapter-complete event still persists that chapter's rewards (because the auto-save already fired before disconnect).
**Test Case:** Integration test: trigger chapter-complete, immediately force-disconnect the simulated session, assert the save already landed.
- [ ] Done

#### T-162 — Retry/backoff + backup store fallback
**Depends on:** T-160
**Description:** Exponential backoff retry on DataStore failure; writes to a backup store on second consecutive failure (§17.3).
**DoD / Expected Output:** A simulated DataStore outage (mocked failure) results in data landing in the backup store rather than being silently dropped.
**Test Case:** Integration test: mock 2 consecutive save failures, assert backup-store write occurs and is logged for reconciliation.
- [ ] Done

#### T-163 — Data migration/versioning scaffold
**Depends on:** T-160
**Description:** Schema version field on saved data plus safe-default logic for new fields added post-launch (not in original GDD but necessary for "without bugs" long-term maintenance — new systems will add save fields over time).
**DoD / Expected Output:** Loading a save written before a new field existed does not error; the field is populated with a safe default and persisted on next save.
**Test Case:** Integration test: load a fixture save payload missing a newer field, assert no error and correct default applied.
- [ ] Done

---

## Phase 15 — Anti-Cheat (GDD §17.2)

#### T-170 — Server-authority audit
**Depends on:** T-049, T-110, T-160
**Description:** Checklist + automated scan confirming no client RemoteEvent can directly mutate Coins/XP/Jade/inventory/chapter-progress without server-side validation (§17.2).
**DoD / Expected Output:** A written audit checklist (one line per RemoteEvent in the game) with each entry marked as validated; automated test suite covers the highest-risk events (currency, purchases, damage).
**Test Case:** Integration test suite: for each currency/XP/inventory RemoteEvent, send a malformed/spoofed payload and assert server-side state is unaffected.
- [ ] Done

#### T-171 — RemoteEvent rate-limiting
**Depends on:** T-000
**Description:** Sanity-bounds/rate-limits on high-frequency RemoteEvents (attack inputs, purchase requests) to blunt spam-based exploits or accidental client bugs from flooding the server.
**DoD / Expected Output:** Exceeding the configured rate for a given event drops excess calls server-side without disconnecting the player or breaking legitimate fast-combo play (rate threshold tuned above realistic max input rate).
**Test Case:** Integration test: fire an event well above the configured rate limit, assert excess calls are dropped and legitimate in-rate calls still succeed.
- [ ] Done

---

## Phase 16 — Performance & Streaming (GDD §17.4)

#### T-180 — LOD system for battlefield props
**Depends on:** S-020–S-027
**Description:** Distance-based level-of-detail swapping for battlefield decoration/props (§17.4).
**DoD / Expected Output:** Frame time impact of LOD swapping itself is negligible (no visible pop-in stutter) at the target FPS per platform.
**Test Case:** Manual profiling pass per platform tier (ties into S-110/S-111/S-112) confirming FPS targets from §17.4's table are met with LOD active.
- [ ] Done

#### T-181 — Particle limit tiers
**Depends on:** T-020
**Description:** Wires hit-particle/trail-particle counts to the quality-tier settings in `UIConfig` (§17.4 — reduced count on Mobile).
**DoD / Expected Output:** Switching graphics quality in Settings (T-134) immediately changes active particle emission rates without a rejoin.
**Test Case:** Integration test: switch quality tier mid-session, assert particle emitter rate properties update accordingly.
- [ ] Done

#### T-182 — Streaming configuration
**Depends on:** S-020–S-027
**Description:** `Workspace.StreamingEnabled` + tuned `StreamingMinRadius`/`StreamingTargetRadius` so chapters load via Roblox streaming rather than full upfront load (§17.4).
**DoD / Expected Output:** No gameplay-critical script assumes a part exists before `PartRequestedByClient`/streamed-in confirmation (guards against streaming-related nil-reference bugs).
**Test Case:** Integration test: with streaming enabled, teleport a player directly into a late-chapter arena (skipping normal traversal) and assert no script errors occur waiting on unstreamed parts.
- [ ] Done

---

## Phase 17 — QA / Automated Tests (cross-cutting)

#### T-190 — Config schema test suite
**Depends on:** T-010–T-022
**Description:** Consolidates all Phase 1 TestEZ specs into a single suite run before every deploy.
**DoD / Expected Output:** Suite runs in under a defined time budget (e.g. <30s) so it's practical to run pre-commit/pre-publish.
**Test Case:** Suite itself is the test artifact; DoD is "all Phase 1 specs pass simultaneously."
- [ ] Done

#### T-191 — Integration test: full arena clear simulation
**Depends on:** T-049, T-061, T-062, T-102
**Description:** Headless (or Studio command-bar-driven) simulation of a full arena: enter, gate seals, waves spawn/clear, gate unseals, chest spawns.
**DoD / Expected Output:** Simulation completes end-to-end without manual intervention and asserts each state transition occurred in the correct order.
**Test Case:** Automated run against at least one arena per difficulty tier (§8.3).
- [ ] Done

#### T-192 — Integration test: purchase flow simulation
**Depends on:** T-113, T-114
**Description:** Mocked `ProcessReceipt`/GamePass-ownership flow validating idempotent grants (ties to T-114's DoD).
**DoD / Expected Output:** Covers both GamePass and Developer Product paths, including the double-call idempotency case.
**Test Case:** As specified in T-114; consolidated here as part of the regression suite.
- [ ] Done

#### T-193 — 4-player combat load test
**Depends on:** T-042, T-050, T-061
**Description:** Automated or scripted-bot 4-client load test of a single arena at full party size, per the §17.6 pre-launch checklist item and §17.1's netcode risk flag.
**DoD / Expected Output:** No desync, no rubber-banding, no server error spikes under sustained 4-player combat load for the duration of a full arena clear.
**Test Case:** Documented load-test run with captured server/client logs showing zero reconciliation-rejection spikes beyond expected baseline.
- [ ] Done

#### T-194 — Weapon DPS balance logging tool
**Depends on:** T-011, T-062
**Description:** Logs realized damage-per-second per weapon type across standard wave compositions (not just the theoretical DPS check in T-011), producing a tuning report per §17.6.
**DoD / Expected Output:** Report output is diffable across builds so a future balance change's impact is visible before merge.
**Test Case:** Run against all 5 weapons on a fixed test wave, output report reviewed against the ±5% tolerance band from T-011.
- [ ] Done

---

## Phase 18 — Pre-Launch Script Checklist (GDD §17.6)

#### T-200 — Placeholder ID startup assertion
**Depends on:** T-018, S-084
**Description:** Startup server script that asserts no `GamePassId`/`ProductId`/critical `AssetId` in `MonetizationConfig`/`AudioConfig` is still `0`, failing loudly in a non-production environment (warn-only in Studio, hard-fail in a pre-publish CI check).
**DoD / Expected Output:** Running this check against the current config immediately after S-084 completes reports zero remaining placeholders.
**Test Case:** Seed one deliberate `0` ID, assert the check flags it; remove it, assert the check passes clean.
- [ ] Done

#### T-201 — Finishing Move intensity toggle
**Depends on:** T-046
**Description:** Config-level toggle for Finishing Move VFX intensity, so a post-review policy requirement (§17.6/§13.3) can be satisfied without a code change, only a config flip.
**DoD / Expected Output:** Toggling the flag changes the visual effect without touching gameplay logic (damage/reward grant unaffected).
**Test Case:** Integration test: trigger a Finishing Move under both toggle states, assert reward grant is identical and only the VFX differs.
- [ ] Done

#### T-202 — IP naming audit lint
**Depends on:** None
**Description:** Lightweight source-scan script checking for a maintained deny-list of trademarked terms (e.g. specific MK character/franchise names) accidentally introduced into source, assets, or UI strings (§17.6).
**DoD / Expected Output:** Clean run against current codebase; wired as a pre-publish check alongside T-151's localization lint.
**Test Case:** Seed a deliberately banned term in a test string, assert the lint flags it.
- [ ] Done

---

*Companion file: `STUDIO_TASKS.md` (manual Roblox Studio / website work). Both files derive from `GDD.md` v0.1 (2026-08-14) and must be updated together if the GDD changes.*
