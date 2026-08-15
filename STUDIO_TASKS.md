# STUDIO_TASKS.md — Manual Roblox Studio / Website Task Breakdown

Derived from `GDD.md` (v0.1, 2026-08-14). This file covers everything that must be done by hand — in Roblox Studio's editor (building geometry, placing/tagging instances, importing/rigging models, animating, laying out UI) or on the Roblox website (creating GamePasses/Developer Products, universe settings, publishing). Everything scriptable lives in `TASKS.md`.

## How the two files fit together

- Tasks reference each other by ID: `S-###` = this file, `T-###` = `TASKS.md`. A task's **Depends on** line lists prerequisites that must be `[x]` before starting.
- §0 below (S-002 specifically) defines the **shared tagging/attribute convention** that every scripted system in `TASKS.md` consumes. Treat it as the contract between level designers and engineers — if a tag or attribute name changes here, every dependent `T-###` task must be re-verified.
- Recommended order: do §0 first (parallel with `TASKS.md` Phase 0). Then Lobby (§1) and the first 1–2 chapters (§2) can proceed while engineers build core combat/enemy systems (`TASKS.md` Phases 2–4) — chapters need the Arena Gate controller (T-061) at least stubbed to be play-testable, but geometry/dressing can be built before the script is finished.
- "Verification / Acceptance Check" replaces a unit test where one doesn't apply (you can't unit-test level geometry) — it's the manual equivalent: what to check before ticking the box.

**Legend:** `[ ]` not started · `[x]` done.

---

## Phase 0 — Studio Project & Tagging Setup

#### S-000 — Install & connect Rojo plugin
**Depends on:** T-000
**Description:** Install the Rojo Studio plugin, connect to the local `rojo serve` session from T-000, verify two-way sync.
**Verification / Acceptance Check:** Edit a file in the code editor, confirm it appears in Studio's Explorer within the sync session; confirm Studio-side changes to non-script instances survive a sync (Rojo should not delete non-mapped instances).
- [ ] Done

#### S-001 — Workspace top-level folder structure
**Depends on:** S-000
**Description:** Create top-level `Workspace` folders: `Lobby`, `Chapters` (with one subfolder per chapter, matching `ChapterConfig` ids from T-013), `_Templates` (for reusable arena/prop templates).
**Verification / Acceptance Check:** Folder names exactly match the `id` field engineers use in `ChapterConfig.lua` (T-013) — mismatches break chapter loading.
- [ ] Done

#### S-002 — Define CollectionService tag & attribute convention
**Depends on:** S-000
**Description:** This is the authoritative reference for every tag/attribute name used by scripted systems. Document it (in a Studio `StringValue`/notes object or a shared doc) and apply consistently across all builds.

| Tag | Applies to | Required Attributes | Consumed by |
|---|---|---|---|
| `ArenaGate` | Gate part(s) sealing an arena | `ArenaId` (string) | T-061 |
| `ArenaSpawnPoint` | Enemy spawn markers inside an arena | `ArenaId`, `WaveIndex` (int) | T-061, T-064 |
| `Enemy` | Any enemy Model (Grunt/Soldier/Heavy/Ranged/Assassin/Elite/Boss) | `Role` (string, matches an `EnemyConfig.Roles` key), `IsBlocking` (bool, optional — set live by role AI, e.g. Soldier) | T-042, T-044, T-045, T-046, T-050, T-060, T-062 |
| `DestructibleContainer` | Wooden Crate / Clay Urn / Supply Barrel / Jade Chest models | `ContainerType` (string: `WoodenCrate`\|`ClayUrn`\|`SupplyBarrel`\|`JadeChest`) | T-100 |
| `HazardZone` | Spikes, fire pits, chasms, temple bells, etc. | `HazardType` (string) | T-044 |
| `NPCVendor` | Sifu's Dojo, Cosmetic Shop stall, Battle Pass board | `VendorType` (string: `ComboScroll`\|`Cosmetic`\|`BattlePass`) | T-126 |
| `Lever` | Interactable lever/switch | `ResetDelay` (number, optional, default 1s), `TargetId` (string, optional) — interaction style auto-detects a descendant `ProximityPrompt` or `ClickDetector`, falling back to walk-into (`Touched`) if neither is present | T-032 |
| `PressurePlate` | Floor plate triggered by walking onto it | `ResetDelay` (number, optional, default 1s), `TargetId` (string, optional) | T-032 |
| `CollapsingWalkway` | Floor part that gives way after being stepped on | `CollapseDelay` (number, optional, default 0.4s — trigger to giving way), `ResetDelay` (number, optional, default 5s — giving way to respawn), `TargetId` (string, optional) | T-032 |
| `WallRunnable` | Surfaces allowing wall-run | — | T-030 |
| `LootRoom` | Hidden side-room trigger volume | `ArenaId` | S-020–S-027, T-102 |
| `BossArena` | Boss/mini-boss fight zone | `ChapterId`, `BossId` | T-065 |
| `Checkpoint` | Mid-chapter respawn/save point | `ChapterId`, `Order` (int) | T-161 |

**Verification / Acceptance Check:** A short in-Studio test place with one instance per tag validates that each scripted system (once available) correctly picks it up. Re-run this check any time a tag/attribute is added or renamed.
- [ ] Done

#### S-003 — ServerScriptService / ReplicatedStorage / StarterGui skeleton
**Depends on:** S-000
**Description:** Confirm the Rojo-synced folder skeleton (`ServerScriptService`, `ServerStorage`, `ReplicatedStorage.Shared`, `StarterGui`, `StarterPlayer`) matches what T-000 expects, and add any Studio-only containers (e.g. `ServerStorage.EnemyTemplates`, `ServerStorage.PropTemplates`) not covered by Rojo.
**Verification / Acceptance Check:** No orphaned/duplicate folders after a full sync cycle.
- [ ] Done

---

## Phase 1 — Lobby (Temple Hub) Build (GDD §12.1)

#### S-010 — Temple Hub base geometry
**Depends on:** S-001
**Description:** Build the courtyard layout, boundaries, and player spawn points for the shared safe hub (post-liberation temple mood, §12.1).
**Verification / Acceptance Check:** Walkable area supports up to 20 concurrent players (§ header max) without visible geometry gaps or z-fighting; spawn points don't overlap.
- [ ] Done

#### S-011 — Training dummies
**Depends on:** S-010
**Description:** Place freely-punchable training dummies for warm-up practice (§18 nuance note).
**Verification / Acceptance Check:** At least 2–4 dummies placed with clear approach space for multiple players at once.
- [ ] Done

#### S-012 — Sifu's Dojo vendor NPC
**Depends on:** S-010, S-002
**Description:** Place and tag the Combo Scroll shop NPC (`NPCVendor`, `VendorType = "ComboScroll"`, §10.3, §12.1).
**Verification / Acceptance Check:** Tag/attribute present and correctly typed; interaction prompt visible on approach once T-126 is live.
- [ ] Done

#### S-013 — Cosmetic Shop stall NPC
**Depends on:** S-010, S-002
**Description:** Place and tag the Cosmetic Shop vendor (`NPCVendor`, `VendorType = "Cosmetic"`, §11.2).
**Verification / Acceptance Check:** Same as S-012.
- [ ] Done

#### S-014 — Battle Pass board
**Depends on:** S-010, S-002
**Description:** Place and tag the Battle Pass interactable board (`NPCVendor`, `VendorType = "BattlePass"`, §11.4).
**Verification / Acceptance Check:** Same as S-012.
- [ ] Done

#### S-015 — Chapter Select gate(s)
**Depends on:** S-010, T-013
**Description:** Build 8 chapter entry portals/triggers in the hub, one per `ChapterConfig` entry, visually reflecting difficulty tier (§8.3) and lock state below the player's level gate.
**Verification / Acceptance Check:** Each portal's linked chapter id matches `ChapterConfig` exactly; locked chapters are visually distinct (e.g. sealed/dimmed) even before the unlock-gate script is wired.
- [ ] Done

#### S-016 — VIP Training Hall
**Depends on:** S-010
**Description:** Build a separate connected area (§12.1) with a gate condition placeholder for GamePass-check (wired later by T-113); include target dummies for private practice.
**Verification / Acceptance Check:** Physically connected to main hub but visually distinguished as a premium space.
- [ ] Done

#### S-017 — Hub lighting/atmosphere/skybox
**Depends on:** S-010
**Description:** Author `Lighting`/`Atmosphere`/`Sky` settings for the hub matching the "liberated temple, calm" mood.
**Verification / Acceptance Check:** Readable at all times of the in-game day/night cycle (if used); no blown-out or overly dark zones.
- [ ] Done

#### S-018 — Lobby music zone
**Depends on:** S-010, S-070
**Description:** Set up the ambient/looping Lobby music zone (§16 table, `AudioConfig.Music.Lobby`).
**Verification / Acceptance Check:** Music loops seamlessly with no audible seam; volume respects the independent music slider once T-141 is live.
- [ ] Done

---

## Phase 2 — Chapter Battlefield Builds (GDD §8)

### Chapter build template (applies to every S-020–S-027 task below)

Every chapter build must include, before it can be marked done:
1. One traversal-intro segment (light platforming/exploration, §8.2) leading into the first arena.
2. 3–5 gated combat arenas, each with an `ArenaGate` + tagged `ArenaSpawnPoint`s per wave (§8.2, feeds T-061/T-064).
3. Destructible containers scattered per arena, tagged `DestructibleContainer` with correct `ContainerType` (§10.2).
4. At least one hidden `DestructibleContainer` (`ContainerType = "JadeChest"`) off the critical path (§8.4).
5. At least one `LootRoom` behind a puzzle or Elite Champion guard (§8.2).
6. One mini-boss or boss arena (`BossArena` tag) at the end, with no side containers inside it (§4.5, §8.2).
7. The chapter's signature hazard/gimmick from the §8.1 table, built as tagged `HazardZone` instances or bespoke mechanisms (fire spread, ice friction, wind gusts, etc.) as appropriate.
8. Theme-appropriate `Lighting`/`Atmosphere`/`Sky` and ambient audio zone (§16).
9. Enemy faction dressing per §4.6 (base role rigs from S-030, reskinned per S-031) placed at the tagged spawn points.
10. Playtested on PC, mobile, and console control schemes before final sign-off (§8.4) — tracked separately in S-110–S-112, but a first-pass check happens here.

Sign off a chapter task only when all 10 items are satisfied — partial builds should stay unchecked.

#### S-020 — Chapter 1: Temple Courtyard (Novice)
**Depends on:** S-001, S-002, T-061 (stub acceptable for early geometry work)
**Description:** Build per the template above. Signature hazard: collapsing scaffolding, temple bells (throw-kill hazard). Faction: Jade Serpent Cultists (Cultist Soldier signature enemy).
**Verification / Acceptance Check:** Template checklist items 1–10 all satisfied; this is also the tutorial chapter, so ensure difficulty is genuinely gentle (Grunt/Soldier only, per §8.3).
- [ ] Done

#### S-021 — Chapter 2: Burning Village (Novice)
**Depends on:** S-020 (as a build reference), T-061
**Description:** Signature hazard: spreading fire zones, collapsing rooftops. Faction: Raider Warband (Torch Raider sets terrain on fire).
**Verification / Acceptance Check:** Template checklist 1–10; fire-spread hazard must be clearly telegraphed before it damages players (fairness rule, §8.4).
- [ ] Done

#### S-022 — Chapter 3: Bamboo Forest (Adept)
**Depends on:** S-021, T-061
**Description:** Signature hazard: breakable bamboo cover, ambush ranged enemies. Faction: Shadow Stalkers (Camouflaged Assassin).
**Verification / Acceptance Check:** Template checklist 1–10; enemy mix includes Ranged/Assassin per Adept tier (§8.3).
- [ ] Done

#### S-023 — Chapter 4: Mountain Pass (Adept)
**Depends on:** S-022, T-061
**Description:** Signature hazard: ice surfaces (reduced footing), rockslide hazard. Faction: Frost Wardens (Ice Archer, slowing arrows).
**Verification / Acceptance Check:** Template checklist 1–10; ice friction change must be visually distinct (texture/particle) so players can anticipate footing loss.
- [ ] Done

#### S-024 — Chapter 5: Ancient Catacombs (Veteran)
**Depends on:** S-023, T-061
**Description:** Signature hazard: darkness pockets, bone-trap floor tiles. Faction: Restless Dead (Bone Grappler, grabs from off-screen).
**Verification / Acceptance Check:** Template checklist 1–10; darkness pockets must still allow players to read enemy telegraphs (T-063) — don't let atmosphere break fairness (§8.4).
- [ ] Done

#### S-025 — Chapter 6: Sky Pagoda (Veteran)
**Depends on:** S-024, T-061
**Description:** Signature hazard: wind-gust platforming, fall hazards. Faction: Wind Monks corrupted (Aerial Duelist, air-combo specialist).
**Verification / Acceptance Check:** Template checklist 1–10; fall hazards need a fair recovery window (ledge grab per T-030) and clear visual cliff-edge telegraphing.
- [ ] Done

#### S-026 — Chapter 7: Underworld Gate (Master)
**Depends on:** S-025, T-061
**Description:** Signature hazard: corrupted ground damage-over-time zones. Faction: Nezhar's Legion (Wraith Bruiser, phases through blocks).
**Verification / Acceptance Check:** Template checklist 1–10; enemy mix at full Master-tier density (§8.3) — verify readability with 4 players + 6+ enemies onscreen per §8.4.
- [ ] Done

#### S-027 — Chapter 8: Warlord's Throne (Master, Final)
**Depends on:** S-026, T-061, T-065
**Description:** Multi-phase boss arena, escort gauntlet leading up to it. Faction: Nezhar's Honor Guard (Elite Champion escort) → Nezhar (final boss).
**Verification / Acceptance Check:** Template checklist items 1–9 apply to the escort gauntlet; the final `BossArena` itself deliberately omits side containers per §4.5. Boss must have exactly one grab-counter window and one parry-punish window authored per phase (3 phases, §4.5) working with T-065.
- [ ] Done

---

## Phase 3 — Enemy & Boss Asset Setup

#### S-030 — Base enemy role rigs (7 roles)
**Depends on:** S-002
**Description:** Model/rig/import base bodies for Grunt, Soldier, Heavy, Ranged, Assassin, Elite, Boss (§4.2); attach the `Enemy` tag + `Role` attribute so T-060's controller can bind generically.
**Verification / Acceptance Check:** All 7 rigs import cleanly with consistent bone/attachment naming so a single animation set can theoretically retarget across them where roles share a body type.
- [ ] Done

#### S-031 — Faction reskin variants (8 factions)
**Depends on:** S-030
**Description:** Apply cosmetic model/texture swaps over the base role rigs for each of the 8 chapter factions (§4.6), tagged with a `Faction` attribute — pure asset swap, no new behavior.
**Verification / Acceptance Check:** A reskinned enemy still triggers identical `EnemyConfig`-driven behavior as its base role (spot-check against T-062's tests).
- [ ] Done

#### S-032 — Boss unique models & phase animations
**Depends on:** S-030
**Description:** Model and animate the 8 chapter-ending bosses/mini-bosses (one per chapter, culminating in Nezhar), with distinct animation sets per phase (§4.5).
**Verification / Acceptance Check:** Each boss has at minimum: idle, 3 phase-specific attack patterns, one grab-counter-able animation, one parry-punishable animation, and a defeat animation.
- [ ] Done

#### S-033 — Attack telegraph VFX per role
**Depends on:** S-030
**Description:** Windup glow/flash VFX per enemy role (§4.4, §18 "telegraph flash" nuance note) timed to match `AttackTelegraph` in `EnemyConfig`.
**Verification / Acceptance Check:** VFX is visually distinct enough to read at a glance in a crowd of 6+ enemies (§8.4 readability rule).
- [ ] Done

---

## Phase 4 — Player Character & Weapon Assets

#### S-040 — Player character base body
**Depends on:** S-002
**Description:** Import/rig the monk player character base body with attachment points for Head/Body/Arm/Leg accessory slots (§5.1).
**Verification / Acceptance Check:** All 4 accessory slots can be equipped simultaneously without clipping in at least the default pose.
- [ ] Done

#### S-041 — Weapon models (5 types)
**Depends on:** S-040
**Description:** Model and import Twin Blades, War Staff, Hook Swords, Iron Gauntlets, Battle Glaive (§5.2) with correct viewmodel/hand attachment points.
**Verification / Acceptance Check:** Each weapon attaches cleanly to the character rig at the correct grip point for both idle and combat poses.
- [ ] Done

#### S-042 — Combo string animations per weapon
**Depends on:** S-041
**Description:** Animate light/heavy combo chains, air combo, and running attack (§3.2) for all 5 weapons; export animation IDs for T-011/T-071.
**Verification / Acceptance Check:** Animation IDs handed off to engineering (feeds T-071's DoD directly — no placeholder IDs remaining).
- [ ] Done

#### S-043 — Ultimate technique animations + FX layers
**Depends on:** S-041
**Description:** Animate the 5 unique Ultimates (Whirlwind Strike, Heaven's Sweep, Serpent's Coil, Mountain Breaker, Dragon's Arc, §5.2) plus separate cosmetic FX variant layers (aura color/trail/impact) that don't alter the base animation (§11.2, §3.6 — function/cosmetic decoupling).
**Verification / Acceptance Check:** Base Ultimate animation plays identically regardless of which FX skin is layered on top.
- [ ] Done

#### S-044 — Finishing Move animations + FX variants
**Depends on:** S-041
**Description:** Animate the stylized light-dissolve takedown (§3.9, §13.3 — no gore) plus alternate FX style variants for monetization (§11.2).
**Verification / Acceptance Check:** Effect reads clearly as non-graphic/stylized at a glance; passes an internal content-policy self-check ahead of the formal S-115 review.
- [ ] Done

#### S-045 — Support animation set
**Depends on:** S-041
**Description:** Animate Block/Parry (incl. distinct Perfect Parry flourish)/Dodge/Grapple/Throw/Revive/base emote set (bow, taunt, victory pose, meditation idle, §11.2).
**Verification / Acceptance Check:** Revive animation duration matches the "vulnerable during" window expected by T-124.
- [ ] Done

---

## Phase 5 — Accessory & Cosmetic Assets

#### S-050 — Head accessory catalog
**Depends on:** S-040
**Description:** Author/upload initial Head accessory set across rarity tiers (§5.1, §5.3) — headbands, monk hoods, masks, horned helms.
**Verification / Acceptance Check:** No clipping with base rig across a sample of other equipped accessories; rarity-tier VFX slot present for T-082.
- [ ] Done

#### S-051 — Body accessory catalog
**Depends on:** S-040
**Description:** Robes, armor sets, sashes across rarity tiers.
**Verification / Acceptance Check:** Same as S-050.
- [ ] Done

#### S-052 — Arm accessory catalog
**Depends on:** S-040
**Description:** Bracers, wraps, gauntlet skins across rarity tiers.
**Verification / Acceptance Check:** Same as S-050; also verify no visual conflict with equipped weapon models (S-041).
- [ ] Done

#### S-053 — Leg accessory catalog
**Depends on:** S-040
**Description:** Sash-wraps, greaves, sandals across rarity tiers.
**Verification / Acceptance Check:** Same as S-050.
- [ ] Done

#### S-054 — Weapon skin variants
**Depends on:** S-041
**Description:** Recolors/particle trims/animated finishes per rarity tier for all 5 weapons (§11.2).
**Verification / Acceptance Check:** Skins swap the material/texture/FX layer only — underlying weapon collision/attachment geometry unchanged (protects T-072's function/cosmetic decoupling test).
- [ ] Done

#### S-055 — Ultimate FX skin variants
**Depends on:** S-043
**Description:** Aura color/impact effect/trail variants layered on the base Ultimate animations.
**Verification / Acceptance Check:** Same functional decoupling check as S-043.
- [ ] Done

#### S-056 — Spirit Companion models
**Depends on:** S-040
**Description:** Cosmetic animal spirit companion models that follow the player in Lobby and battlefield, visual only (§11.2).
**Verification / Acceptance Check:** Follow-behavior pathing doesn't clip through walls/gates; purely decorative, no collision with combat.
- [ ] Done

#### S-057 — Emote animation set (extended)
**Depends on:** S-045
**Description:** Additional purchasable emotes beyond the base set (§11.2).
**Verification / Acceptance Check:** Playable in both Lobby and (non-combat-blocking) battlefield contexts.
- [ ] Done

---

## Phase 6 — UI Screen Layouts

#### S-060 — Combat HUD ScreenGui
**Depends on:** S-002
**Description:** Build the ScreenGui hierarchy for the §15.1 mockup: HP/Chi bars, combo counter, party frames, mobile control buttons (joystick + attack/heavy/block/dodge/grab/ultimate).
**Verification / Acceptance Check:** All mobile control buttons meet the ≥44px tap-target rule (§6.2) at the smallest supported viewport — cross-check against T-136.
- [ ] Done

#### S-061 — Responsive breakpoint layout variants
**Depends on:** S-060, T-020
**Description:** Build/configure desktop widescreen, tablet/landscape, and portrait mobile layout variants (§15.2), using `UIAspectRatioConstraint`/scale-based sizing exclusively — no fixed pixel offsets.
**Verification / Acceptance Check:** Visually inspect all 3 breakpoints at their reference resolutions; no element clips or overlaps at any of them.
- [ ] Done

#### S-062 — Menu flow screens
**Depends on:** S-002
**Description:** Build Lobby menu, Chapter Select, Party Setup, Loadout Check, Ready/Load screens (§15.3).
**Verification / Acceptance Check:** Every screen has a visible back-navigation element (feeds T-133's DoD).
- [ ] Done

#### S-063 — Settings menu screen
**Depends on:** S-062
**Description:** Build the Settings screen: audio sliders (music/SFX), control scheme selector, graphics quality, lock-on assist toggle, language dropdown (§15.3).
**Verification / Acceptance Check:** All controls present and laid out per the responsive rules from S-061.
- [ ] Done

#### S-064 — Shop / Combo Scroll / Battle Pass UI screens
**Depends on:** S-062, T-017
**Description:** Build purchase-flow screens for the Cosmetic Shop, Combo Scroll shop (Sifu's Dojo), and Battle Pass tier board (§10.3, §11.2, §11.4).
**Verification / Acceptance Check:** Combo Scroll screen visually/structurally cannot present a Jade price option (matches T-111's Coins-only server rule — UI shouldn't even offer what the server would reject).
- [ ] Done

#### S-065 — Feedback overlay elements
**Depends on:** S-060
**Description:** Build Finishing Move overlay, Flawless banner, boss-phase-transition flash, container-break popup elements (§15.4).
**Verification / Acceptance Check:** Elements layer correctly above the Combat HUD without blocking critical HP/Chi visibility.
- [ ] Done

---

## Phase 7 — Audio Asset Upload

#### S-070 — SFX catalog upload
**Depends on:** None
**Description:** Upload/catalog every SFX from the §16 table (Light/Heavy attack, Block/Parry, Dodge, Finishing Move, container break variants, enemy hit/death per role, boss phase transition, Ultimate activation, Chi full, chapter complete, UI click).
**Verification / Acceptance Check:** Record every resulting Asset ID into a hand-off list for `AudioConfig.lua` (T-019); no missing entries versus the §16 table.
- [ ] Done

#### S-071 — Per-chapter music loop pairs
**Depends on:** None
**Description:** Upload/catalog combat + exploration music stem pairs for all 8 chapters + Lobby (§16).
**Verification / Acceptance Check:** Each pair loops seamlessly and the combat/exploration stems are tempo/key-compatible for a clean swap (§17.1's music-swap-on-gate-seal requirement).
- [ ] Done

#### S-072 — Ambient sound loops per chapter
**Depends on:** None
**Description:** Upload/catalog ambient loops (temple wind, village fire crackle, forest rustle, cave drips, etc., §16) per chapter.
**Verification / Acceptance Check:** IDs recorded for `AudioConfig.lua`.
- [ ] Done

---

## Phase 8 — Monetization Setup (Roblox Website)

#### S-080 — VIP Game Pass creation
**Depends on:** None
**Description:** Create the VIP Game Pass on the Roblox website (§11.3), set price, icon, description.
**Verification / Acceptance Check:** GamePass ID recorded and handed off for `MonetizationConfig.VIPPassId` (T-018).
- [ ] Done

#### S-081 — Battle Pass Game Pass creation
**Depends on:** None
**Description:** Create the premium-track unlock Game Pass (§11.4).
**Verification / Acceptance Check:** ID recorded for `MonetizationConfig.BattlePassId`.
- [ ] Done

#### S-082 — Jade Shard Developer Products (3 tiers)
**Depends on:** None
**Description:** Create the 3 Jade Shard product tiers per §14.5 (100/550/1200 Jade at 80/400/800 Robux, or final tuned pricing).
**Verification / Acceptance Check:** All 3 Product IDs recorded for `MonetizationConfig.JadeProducts`.
- [ ] Done

#### S-083 — Chapter Cosmetic Pass products
**Depends on:** None
**Description:** Create Robux products for early-access chapter-tied cosmetic passes as new chapters release (§11.2).
**Verification / Acceptance Check:** One product created per released Chapter Cosmetic Pass, ID recorded.
- [ ] Done

#### S-084 — Verify all monetization IDs entered
**Depends on:** S-080, S-081, S-082, S-083, T-018
**Description:** Cross-check every ID created above is correctly entered into `MonetizationConfig.lua`, no `0` placeholders remain.
**Verification / Acceptance Check:** Run T-200's startup assertion script and confirm a clean pass — this task and T-200 gate each other.
- [ ] Done

---

## Phase 9 — Localization Import

#### S-090 — LocalizationTable population (8 languages)
**Depends on:** T-021
**Description:** Populate Roblox's `LocalizationTable`/CSV for English, Indonesian, Spanish, Portuguese (BR), French, German, Russian, Chinese Simplified (§13.1), using the namespaced keys defined by engineering (`ui.button.play`, `enemy.name.wraithbruiser`, `hud.label.combo`, etc., §13.2).
**Verification / Acceptance Check:** Every key referenced by T-150's wrapper has an entry (or intentionally falls back to `en`); no orphaned keys with no `en` source.
- [ ] Done

#### S-091 — Native-speaker review pass
**Depends on:** S-090
**Description:** Review translations per language for natural terminology, not literal transliteration (§13.2) — especially combat/enemy terms.
**Verification / Acceptance Check:** Sign-off per language from a native/fluent reviewer.
- [ ] Done

#### S-092 — Cultural sensitivity review
**Depends on:** S-090
**Description:** Review avatar items and chapter content per major market (§13.3) — confirm no unintended religious-symbol reference, culturally insensitive humor, etc.
**Verification / Acceptance Check:** Sign-off checklist per major market covered in §13.1.
- [ ] Done

---

## Phase 10 — Lighting, Atmosphere & Skybox

#### S-100 — Per-chapter Lighting/Atmosphere/Skybox authoring
**Depends on:** S-020–S-027
**Description:** Author final `Lighting`/`Atmosphere`/`Sky` settings for all 8 chapters + Lobby, matching each theme (§8.1 table) and performance targets (§17.4 — avoid overly expensive post-processing on Mobile).
**Verification / Acceptance Check:** Visual pass per chapter at each graphics quality tier (High/Mobile) confirming acceptable look and FPS impact.
- [ ] Done

---

## Phase 11 — Playtesting & Manual QA

#### S-110 — PC control scheme playtest (all chapters)
**Depends on:** S-020–S-027, T-040
**Description:** Full playtest pass per chapter using Mouse+Keyboard (§6.1).
**Verification / Acceptance Check:** Every control in the §6.1 table functions as documented; no un-completable sections.
- [ ] Done

#### S-111 — Mobile control scheme playtest (all chapters)
**Depends on:** S-020–S-027, T-040, T-136
**Description:** Full playtest pass per chapter using touch controls (§6.2), including the ≥44px tap-target and no-simultaneous-multi-touch-required rules.
**Verification / Acceptance Check:** Every control in the §6.2 table functions; playable one-handed-adjacent (per mobile UX rules) without accidental mis-taps in dense combat.
- [ ] Done

#### S-112 — Console control scheme playtest (all chapters)
**Depends on:** S-020–S-027, T-040
**Description:** Full playtest pass per chapter using gamepad (§6.3).
**Verification / Acceptance Check:** Every control in the §6.3 table functions as documented.
- [ ] Done

#### S-113 — 4-player co-op load test session (manual)
**Depends on:** T-193
**Description:** Manual companion to T-193's automated load test — a real 4-human playtest session on at least one arena per difficulty tier, watching for anything an automated bot wouldn't catch (feel, readability, fun).
**Verification / Acceptance Check:** Session notes captured; no showstopper desync/crash observed; subjective "does this feel good with real people" sign-off.
- [ ] Done

#### S-114 — Enemy readability check (crowded arenas)
**Depends on:** S-020–S-027
**Description:** Verify enemy silhouettes and attack telegraphs (S-033) stay legible with 4 players and 6+ enemies onscreen simultaneously (§8.4 construction rule).
**Verification / Acceptance Check:** Spot-check the busiest wave in each chapter's hardest arena; if telegraphs are lost in visual noise, flag for VFX/lighting adjustment (loop back to S-033/S-100).
- [ ] Done

#### S-115 — Content policy compliance review
**Depends on:** S-044, T-201
**Description:** Review the Finishing Move effect and audio-autoplay behavior against current Roblox community guidelines shortly before launch (§17.6 pre-launch checklist item, §13.3).
**Verification / Acceptance Check:** Written sign-off that content is compliant as of the review date (policies can shift — re-check close to actual launch date, not just at design time).
- [ ] Done

---

## Phase 12 — Publishing & Release

#### S-120 — Universe/game settings configuration
**Depends on:** S-010–S-027 (core content complete)
**Description:** Configure max players, genre tags, thumbnail, description, age rating on the Roblox website for the game universe.
**Verification / Acceptance Check:** Settings reviewed against Roblox's current publishing requirements; age rating reflects the stylized-violence content (§13.3, §19).
- [ ] Done

#### S-121 — Final IP naming audit sign-off
**Depends on:** T-202
**Description:** Manual final pass cross-referencing all in-game names (characters, factions, locations, marketing copy) against known trademarks before any public marketing goes out (§17.6).
**Verification / Acceptance Check:** Written sign-off; pairs with T-202's automated lint as a belt-and-suspenders check.
- [ ] Done

#### S-122 — Closed testing publish (private/unlisted)
**Depends on:** S-115, S-121, T-190–T-194
**Description:** Publish to a private/unlisted state for closed testing before public release.
**Verification / Acceptance Check:** All Phase 17 (`TASKS.md`) automated tests passing and all Phase 11 (this file) manual QA sign-offs complete before this step.
- [ ] Done

#### S-123 — Public release publish
**Depends on:** S-122
**Description:** Publish the game publicly.
**Verification / Acceptance Check:** Closed testing period completed with no unresolved showstopper issues; final go/no-go sign-off recorded.
- [ ] Done

---

*Companion file: `TASKS.md` (scriptable engineering work). Both files derive from `GDD.md` v0.1 (2026-08-14) and must be updated together if the GDD changes.*
