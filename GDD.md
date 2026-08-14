# Shaolin Monks Adventure — Game Design Document

**Version:** 0.1
**Platform:** Roblox
**Genre:** Action-Adventure / Hack-and-Slash / Co-op Multiplayer
**Target Audience:** 10+, fans of combo-driven brawlers and adventure games
**Max Players per Lobby Server:** 20
**Max Players per Battlefield Instance:** 4 (co-op party)

---

## Table of Contents

1. [Vision & Concept](#1-vision--concept)
2. [Core Loop](#2-core-loop)
3. [Combat Mechanics](#3-combat-mechanics)
4. [Enemy System](#4-enemy-system)
5. [Character Customization](#5-character-customization)
6. [Controls (Cross-Platform)](#6-controls-cross-platform)
7. [Game Modes](#7-game-modes)
8. [Battlefield Map Design](#8-battlefield-map-design)
9. [Progression & Retention](#9-progression--retention)
10. [Reward System](#10-reward-system)
11. [Monetization](#11-monetization)
12. [Lobby, Social & Multiplayer](#12-lobby-social--multiplayer)
13. [Localization](#13-localization)
14. [Asset Configuration](#14-asset-configuration)
15. [UI/UX](#15-uiux)
16. [Audio](#16-audio)
17. [Technical Notes](#17-technical-notes)
18. [Nuance & Feel](#18-nuance--feel)
19. [Out of Scope (v1)](#19-out-of-scope-v1)

---

## 1. Vision & Concept

**One-line pitch:** A combo-driven hack-and-slash adventure where Shaolin monks battle an invading demon army through gated combat arenas — built as a spiritual successor to *Mortal Kombat: Shaolin Monks*, reforged for co-op Roblox play.

**Core fantasy:** A Shaolin disciple wielding a chosen weapon and forbidden ultimate technique, smashing through waves of enemies, cracking open temple treasuries for relics, and growing from novice to legendary master — solo or with up to 3 friends.

**Story pillar:** The Jade Serpent Clan, an army of corrupted warriors and undead soldiers led by the warlord Nezhar, has invaded the Shaolin temple grounds. Player-monks fight through the temple, surrounding villages, forests, mountains, and finally the Clan's underworld stronghold to repel the invasion and defeat Nezhar.

**Design pillars:**
1. **Combo mastery** — attack strings, counters, and weapon combos are simple to start, deep to master
2. **Gated spectacle** — combat arenas lock players in until cleared, escalating tension wave by wave, mirroring MKSM's signature encounter design
3. **Loot the world** — nearly everything in a battlefield is breakable and rewards the player for breaking it
4. **Skill over spend** — combat power comes from player skill and unlocked technique, never from a purchase; money buys looks and time saved, not strength

**Differentiators:**
- Authentic MKSM-style gated arena combat with weapon pickup/disarm/throw and environmental finishers
- Deep 4-slot cosmetic customization (Head / Body / Arm / Leg) independent of combat loadout
- Weapon + Ultimate loadout choice changes playstyle, not power level
- Destructible-everything battlefields feeding a relic-based combo unlock economy, just like the original game's Koins-for-combos shop

---

## 2. Core Loop

```
Lobby (customize, shop, train, socialize)
    │
    ▼
Select Chapter → Form Party (solo or up to 4)
    │
    ▼
Enter Battlefield Map
    │
    ▼
Traversal Segment (platforming, exploration, hidden relics)
    │
    ▼
Arena Gate Seals ── Combat Wave(s) ── Gate Opens on Clear
    │
    ├── Loop through multiple arenas per chapter
    ▼
Mini-Boss / Boss Arena
    │
    ▼
Chapter Complete → Reward Screen (XP, Coins, Relics, Gear)
    │
    ▼
Return to Lobby
```

### Per-Arena Combat Loop

```
Enter arena zone
    │
    ▼
Gate seals behind party (no retreat, no reinforcements from outside)
    │
    ▼
Enemies spawn in wave(s) ── Player(s) fight, break crates for drops
    │
    ▼
Enemy staggered → Finishing Move available (bonus reward)
    │
    ▼
All waves cleared → Gate unseals → Loot chest spawns
    │
    ▼
Continue to next arena / traversal segment
```

**Session length target:** 10–20 min per chapter (short chapter ~10 min, boss chapter ~20 min).

**Dopamine hooks per encounter:**
- Combo milestone (10/25/50 hit combo) → on-screen counter flashes, screen shake, unique callout
- Finishing move on staggered enemy → brief slow-mo + particle burst + bonus relic drop
- Crate/urn break → coin/relic pop-out with satisfying crunch sound and item fly-to-HUD animation
- Flawless arena clear (no damage taken) → "Flawless!" banner + bonus Coins
- Boss defeat → full-screen victory cinematic + party-wide reward pulse

---

## 3. Combat Mechanics

### 3.1 Movement & Traversal

- Run, jump, double-jump (unlocked via skill tree), ledge grab/climb, wall-run on marked surfaces
- Dodge roll with brief invincibility frames (i-frames ~0.2s)
- Traversal segments between arenas include light platforming and environmental puzzles (levers, pressure plates, collapsing walkways) — echoes MKSM's exploration beats between fights

### 3.2 Basic Attacks

- **Light Attack** — fast, low damage, chains into long combo strings
- **Heavy Attack** — slow, high damage, breaks enemy block/guard
- Attack inputs buffer into combo strings; string length and finisher unlock via the Combo Scroll system (§10.3)
- Air combo: light/heavy attacks usable on airborne enemies or after a launcher hit
- Running attack: sprint + attack triggers a forward lunge strike, good for closing distance or interrupting ranged enemies

### 3.3 Block, Parry & Dodge

- Hold Block to reduce incoming damage and prevent stagger buildup
- **Perfect Parry** — block input timed within a short window before impact fully negates damage and stuns the attacker, opening a free hit
- Dodge roll avoids damage entirely and repositions the player; spammable but has a short cooldown to prevent invincibility abuse

### 3.4 Grapple, Throw & Environmental Kills

- Grab a staggered enemy to throw them into another enemy (damages both) or into an environmental hazard (spikes, fire pits, chasms, temple bells) for an instant kill and bonus relic drop — signature MKSM mechanic
- Grabbed enemies can also be used as a human shield against ranged attacks for 1–2 hits

### 3.5 Weapon System

- Player equips one **Main Weapon** from the Weapon Loadout (§5.2); it defines their combo tree and Ultimate flavor
- **Weapon Pickup** — dropped/disarmed enemy weapons and environmental weapons (spears off racks, torches, prop staffs) can be picked up as a temporary secondary weapon with its own short combo and a throw option
- **Disarm** — landing a Heavy Attack on a blocking weapon-enemy has a chance to knock their weapon free, leaving them vulnerable and the weapon pickable
- **Weapon Throw** — thrown weapons deal solid ranged damage but are lost on impact unless retrieved from the enemy/ground afterward
- Main Weapon can never be lost; only picked-up secondary weapons are consumable

### 3.6 Ultimate Attack

- Each Main Weapon has one **Ultimate Technique** — a screen-clearing, cinematic special move unique to that weapon category (see §5.2 table)
- **Chi Meter** fills by landing hits, chaining combos, and taking damage; caps at 100
- Activating the Ultimate at full meter unleashes the technique and resets the meter
- Ultimate power is fixed by design — only its visual effect (aura color, particle trail, impact FX) is cosmetically customizable via the shop

### 3.7 Combo & Style Score

- Every hit within a rolling ~2s window extends the player's live Combo Counter (HUD, top-center)
- Combo Counter contributes to a per-arena **Style Score**, which scales bonus Coin/relic rewards (see §10.1)
- Dropping combo (getting hit, or idle too long) resets the counter but does not penalize already-earned rewards

### 3.8 Destructible Objects

- Battlefields are scattered with breakable containers: wooden crates, clay urns, supply barrels, and locked jade chests
- Each container has a hit-point pool (1–4 hits) and a themed drop table (see §10.2)
- Some containers are hidden behind traversal puzzles or off the main path — rewards exploration, same spirit as a secret shortcut
- Containers respawn only on a fresh run of the map; they do not regenerate mid-run

### 3.9 Stagger, Poise & Finishing Moves

- Enemies have a hidden Poise meter; sustained hits fill it and trigger a **Staggered** state (visual stumble, glowing outline)
- Staggered enemies can be Finished with a context Finishing Move input — a short scripted takedown animation (stylized light-dissolve effect, no gore, Roblox-safe) that grants bonus Coins and guarantees a relic drop
- Bosses use Poise thresholds to gate phase transitions instead of a one-shot finisher (see §4.5)

---

## 4. Enemy System

Modeled directly on *Mortal Kombat: Shaolin Monks'* gated-arena combat: players are sealed into a combat zone until every enemy in the current wave is defeated, enemies attack in a rotating ring rather than all at once, and breaking scenery for currency is core to the loop.

### 4.1 Arena Gate Encounters

- Entering a marked arena zone seals invisible gates behind and ahead of the party
- Gates do not open until all active wave(s) are cleared — no retreating, no outside reinforcements
- Multi-wave arenas spawn the next wave a beat after the previous is cleared (brief breather, not instant)
- Arena floor is littered with destructible containers players can break mid-fight for sustain (coins, occasional health/chi orb)

### 4.2 Enemy Roles

| Role | Behavior | Notes |
|---|---|---|
| Grunt | Basic melee, simple 1-hit attack pattern | Fodder, low health, teaches combo timing |
| Soldier | Blocks incoming attacks, punishes unsafe strings | Requires Heavy Attack or Disarm to open up |
| Heavy Bruiser | Slow, armored, high damage, high poise | Interrupts player combos if not staggered first |
| Ranged Archer | Kites at range, fires arrows/throwing blades | Priority target; closing distance is key |
| Assassin | Fast, low health, flanks and dodges | Punishes players who stand still |
| Elite Champion | Mini-boss variant of any role with an expanded moveset and a unique Ultimate-style attack | Appears mid-chapter, guards a loot vault |
| Boss | Full arena-ending unique enemy with multi-phase moveset | One per chapter, see §4.5 |

### 4.3 Crowd Behavior & Wave Composition

- Only 2–3 enemies actively attack the player at once; the rest circle at range (the MKSM "ring" behavior) — keeps fights readable in co-op with up to 4 players and multiple enemies on screen
- Wave composition scales with chapter difficulty tier: early chapters lean Grunt/Soldier heavy, later chapters mix in Heavy/Ranged/Assassin, endgame chapters regularly field Elite Champions mid-wave
- In co-op, wave enemy count and health scale with party size so difficulty stays consistent solo through full party

### 4.4 AI Behavior Rules

- Aggro radius: enemies engage once a player enters detection range or deals/receives damage nearby
- Attack cooldown per enemy prevents overlapping hits from feeling like a stun-lock
- Concurrent attacker cap (2–3) enforced server-side via an attack queue token system
- Anticipation tells (windup flash, audio cue) telegraph attacks ~0.3–0.5s before impact so reads are fair, not memorization-only

### 4.5 Mini-Boss & Boss Design

- Bosses fight in a dedicated arena with no destructible containers mid-fight (focus on the duel) but drop a large loot burst on defeat
- Health is split into phases (typically 3); crossing a phase threshold triggers a brief invulnerable transition animation and a moveset/environment change (e.g., arena hazards activate, adds spawn)
- Every boss has one grab-counter window and one parry-punish window per phase, rewarding players who learned the boss's patterns
- Elite Champions use a condensed 1-phase version of this same structure

### 4.6 Enemy Factions per Chapter

| Chapter | Faction Reskin | Signature Enemy |
|---|---|---|
| Temple Courtyard | Jade Serpent Cultists | Cultist Soldier (blocks, chants buffs) |
| Burning Village | Raider Warband | Torch Raider (sets terrain on fire) |
| Bamboo Forest | Shadow Stalkers | Camouflaged Assassin |
| Mountain Pass | Frost Wardens | Ice Archer (slowing arrows) |
| Ancient Catacombs | Restless Dead | Bone Grappler (grabs from off-screen) |
| Sky Pagoda | Wind Monks (corrupted) | Aerial Duelist (air-combo specialist) |
| Underworld Gate | Nezhar's Legion | Wraith Bruiser (phases through blocks) |
| Warlord's Throne | Nezhar's Honor Guard | Elite Champion escort → Nezhar (final boss) |

---

## 5. Character Customization

### 5.1 Accessory Slots

| Slot | Examples | Affects Gameplay? |
|---|---|---|
| Head | Headbands, monk hoods, masks, horned helms | No — cosmetic only |
| Body | Robes, armor sets, sashes | No — cosmetic only |
| Arm | Bracers, wraps, gauntlet skins | No — cosmetic only |
| Leg | Sash-wraps, greaves, sandals | No — cosmetic only |

Accessories are obtained from the Cosmetic Shop, Battle Pass, crates, and chapter-completion rewards. Rarity is purely visual flair (particle trims, glow tiers).

### 5.2 Weapon Loadout

One Main Weapon equipped at a time; swappable freely in the Lobby, locked for the duration of a battlefield run.

| Weapon Type | Playstyle | Ultimate Technique |
|---|---|---|
| Twin Blades | Fast, low-reach combo strings | Whirlwind Strike — spinning AoE flurry |
| War Staff | Medium reach, sweeping crowd control | Heaven's Sweep — knockback shockwave |
| Hook Swords | High mobility, chain-grapple pulls enemies in | Serpent's Coil — pulls all nearby enemies then multi-hits |
| Iron Gauntlets | Slow, highest poise damage | Mountain Breaker — single massive ground-slam nova |
| Battle Glaive | Longest reach, arcing sweeps | Dragon's Arc — spinning traveling slash line |

All five weapons deal balanced effective damage-per-second when played well — the choice is playstyle, not power. Weapon **skins** (recolors/effects) are the monetized layer, not the weapon's stats.

### 5.3 Cosmetic Rarity Tiers

Common → Uncommon → Rare → Epic → Legendary, applied to accessories, weapon skins, and Ultimate visual effects. Higher tiers add richer particle/glow effects only.

---

## 6. Controls (Cross-Platform)

All three platforms reach full feature parity before launch. No feature locked to one platform.

### 6.1 PC (Mouse + Keyboard)

| Action | Input |
|---|---|
| Move | WASD |
| Light Attack | Left mouse button |
| Heavy Attack | Right mouse button |
| Block / Parry | Hold Shift |
| Dodge Roll | Ctrl / Spacebar-tap-direction |
| Grab / Throw | F |
| Pick Up / Interact | E |
| Throw Held Weapon | Q |
| Ultimate | R (when charged) |
| Camera | Mouse move |
| Lock-on Target | Middle mouse click |
| Party / Scoreboard | Tab |

### 6.2 Mobile (Touch)

| Action | Input |
|---|---|
| Move | Left virtual joystick |
| Light Attack | Attack button (bottom-right) |
| Heavy Attack | Hold Attack button |
| Block / Parry | Shield button |
| Dodge Roll | Swipe on joystick / Dodge button |
| Grab / Throw | Grab button |
| Ultimate | Ultimate button (glows when charged) |
| Camera | Right-side drag |
| Lock-on Target | Tap enemy portrait / auto-assist |

**Mobile UX rules:**
- All interactive buttons ≥ 44px tap target
- Auto-lock-on assist ON by default on mobile; toggle in Settings
- Simplified single-tap combo access — no required multi-touch gestures for core combos (two-finger inputs reserved for optional advanced techniques only)

### 6.3 Console (Gamepad)

| Action | Input |
|---|---|
| Move | Left stick |
| Light Attack | X / Square |
| Heavy Attack | Y / Triangle |
| Block / Parry | Left trigger (hold) |
| Dodge Roll | B / Circle |
| Grab / Throw | Right bumper |
| Pick Up / Interact | A / Cross |
| Throw Held Weapon | Left bumper |
| Ultimate | Right trigger (when charged) |
| Camera | Right stick |
| Lock-on Target | Click right stick |

---

## 7. Game Modes

### 7.1 Story Chapters (Default)
Solo or co-op (up to 4). Linear arena-gated progression through the chapter list (§8.1). Full rewards.

### 7.2 Practice / Free Roam
Replay any previously cleared chapter solo, free retry, reduced rewards (50%). Used for farming Combo Scroll relics or mastering a boss.

### 7.3 Trial Rush (Weekly)
Fixed-seed gauntlet of back-to-back arenas with no traversal filler, ranked by clear time and combo score on a weekly leaderboard. Top finishers earn an exclusive seasonal accessory.

### 7.4 Daily Relic Hunt
One randomly modified chapter per day (extra hidden crates, remixed enemy waves). One bonus-reward attempt per account per day. Resets midnight UTC.

### 7.5 Boss Rematch
Replay any defeated boss directly, skip traversal and prior arenas. Reduced but guaranteed rare+ relic reward. Good for Ultimate/skin farming and speedrun practice.

---

## 8. Battlefield Map Design

### 8.1 Chapters

Each chapter is a self-contained linear battlefield: traversal segments connecting 3–5 combat arenas, ending in a mini-boss or boss arena. See §4.6 for enemy faction per chapter.

| Chapter | Setting | Signature Hazard/Gimmick |
|---|---|---|
| Temple Courtyard | Opening tutorial temple grounds | Collapsing scaffolding, temple bells (throw kill) |
| Burning Village | Village under siege | Spreading fire zones, collapsing rooftops |
| Bamboo Forest | Dense bamboo groves | Breakable bamboo cover, ambush ranged enemies |
| Mountain Pass | Icy cliffside trail | Ice surfaces (reduced footing), rockslide hazard |
| Ancient Catacombs | Underground tomb | Darkness pockets, bone-trap floor tiles |
| Sky Pagoda | Vertical pagoda tower | Wind-gust platforming, fall hazards |
| Underworld Gate | Demon threshold realm | Corrupted ground damage-over-time zones |
| Warlord's Throne | Nezhar's final stronghold | Multi-phase boss arena, escort gauntlet |

### 8.2 Arena Anatomy

- **Traversal Segment** — platforming/exploration between fights, light puzzle gating, hidden relic containers off the main path
- **Combat Arena** — gated zone, one or more enemy waves, destructible containers scattered throughout
- **Loot Room** — optional side room behind a puzzle or Elite Champion guard, contains a guaranteed rare+ chest
- **Boss Arena** — dedicated multi-phase duel space, no side containers, big reward burst on clear

### 8.3 Difficulty Tiers

| Tier | Chapters | Enemy Mix | Unlock |
|---|---|---|---|
| Novice | Temple Courtyard, Burning Village | Grunt/Soldier | Default |
| Adept | Bamboo Forest, Mountain Pass | + Ranged/Assassin | Level 8 |
| Veteran | Ancient Catacombs, Sky Pagoda | + Heavy/Elite Champion | Level 18 |
| Master | Underworld Gate, Warlord's Throne | Full mix + Boss gauntlet | Level 30 |

### 8.4 Construction Rules

- Every arena must be clearable at intended party size without unavoidable damage — enemy tells must always be fair
- At least one hidden relic container per chapter, off the critical path
- Every chapter playtested on all three control schemes before release
- Arenas must read clearly in 4-player co-op — enemy silhouettes and telegraphs stay legible even with 4 players and 6+ enemies on screen

---

## 9. Progression & Retention

### 9.1 Player Level (XP)

XP per chapter = `BaseXP × DifficultyMultiplier × StyleScoreMultiplier`

| Performance | Multiplier |
|---|---|
| Flawless clear (no damage taken) | 2.5× |
| High combo average | 2× |
| Standard clear | 1× |
| Multiple deaths/retries | 0.5× |

Leveling grants **Skill Points**, not raw stat power (see §9.2). Combat power stays skill-driven; leveling unlocks playstyle depth and content gates: new chapters, game modes, cosmetic slots, seasonal content.

### 9.2 Skill Tree

- Skill Points spent on: extended combo strings, double-jump, faster dodge cooldown, longer parry window, throw-weapon retrieval speed, minor capped health/chi pool growth (small, reaches its ceiling by Level 30 — a F2P player and a top spender arrive at the same combat ceiling)
- Tree is shared across all weapons for universal nodes; each weapon also has a small weapon-specific branch (extra combo finisher, unique juggle starter)

### 9.3 Mastery Stars

- Each chapter: 0–3 stars based on Style Score, damage taken, and clear time
- Milestone star totals (15, 40, 75, 120) unlock exclusive permanent cosmetics

### 9.4 Daily / Weekly Quests

Daily examples:
- "Land 5 Finishing Moves" → 200 Coins
- "Break 20 destructible containers" → 150 Coins
- "Clear a chapter without dying" → 300 XP

Weekly examples:
- "Clear Trial Rush" → exclusive title
- "Defeat 3 different bosses" → rare cosmetic crate
- "Find 3 hidden relic containers" → 1000 Coins

### 9.5 Streak System

- Login streak tracked; day 7 = premium drop
- In-run: consecutive Flawless arena clears grant an escalating Coin bonus per arena after the first

### 9.6 Seasonal Events

- Tied to real-world calendar (Lunar New Year, Halloween, Summer)
- Event-exclusive chapter with limited-time boss and exclusive cosmetics/titles

### 9.7 Leaderboards

- Per-chapter best clear time and Style Score: all-time and weekly
- Friends leaderboard (prioritized in display)
- Trial Rush weekly leaderboard, separate

---

## 10. Reward System

### 10.1 Style Score → Reward Scaling

Every arena tracks a live Style Score built from combo length, Finishing Moves landed, and damage avoided. On arena clear, Style Score converts into a Coin/relic multiplier (see §9.1 table) applied to that arena's base reward.

### 10.2 Destructible Container Drop Table

| Container | HP | Drop Table |
|---|---|---|
| Wooden Crate | 1 hit | Coins (common), small chance Health Orb |
| Clay Urn | 1 hit | Coins (common), small chance Chi Orb |
| Supply Barrel | 2 hits | Coins, small chance throwable weapon (spear/torch) |
| Jade Chest (hidden) | 3 hits | Guaranteed relic; chance for cosmetic drop |

### 10.3 Combo Scroll Shop (Homage to the Koins-for-Combos system)

- Coins earned from containers, enemy kills, and chapter clears are spent at the Lobby's **Sifu's Dojo** vendor
- Coins unlock **Combo Scrolls** — new attack strings, finishers, and weapon techniques per weapon type
- This is a direct callback to the source material's relic-for-combo shop: breaking the world open funds becoming stronger at what you already know how to do, not a stat purchase
- Combo Scrolls are Coin-only — never purchasable with premium currency, keeping technique unlocks fully skill-economy driven

### 10.4 Chest Tiers & Rarity

| Chest | Source | Rarity Weights (Common/Uncommon/Rare/Epic/Legendary) |
|---|---|---|
| Arena Chest | Clearing a combat arena | 60/25/10/4/1 |
| Chapter Chest | Chapter completion | 40/30/18/9/3 |
| Boss Chest | Boss defeat | 20/30/28/16/6 |
| Vault Chest | Hidden Jade Chest / Loot Room | 10/25/30/25/10 |

- Duplicate cosmetic pulls convert to Coins at a fixed rate
- Drop tables are published in-game for full transparency (no hidden odds)

---

## 11. Monetization

**Philosophy:** Cosmetic and time-saving only. Combat power — weapon damage, Ultimate strength, skill tree ceiling — is never purchasable. Money buys looks and speed of unlocking things you could earn for free.

### 11.1 Currency

| Currency | Earn | Spend |
|---|---|---|
| Coins | Gameplay: containers, enemies, chapters, quests | Combo Scrolls, basic cosmetic shop items |
| Jade Shards | Robux purchase, rare quest reward | Premium cosmetics, bundles, crates |

One-way economy: Coins cannot convert to Jade Shards.

### 11.2 Cosmetic Categories

| Category | Examples | Currency |
|---|---|---|
| Head / Body / Arm / Leg accessories | Themed sets, seasonal exclusives | Coins / Jade |
| Weapon skins | Recolors, particle trims, animated finishes | Jade |
| Ultimate FX skins | Aura color, impact effect, trail | Jade |
| Finishing Move FX | Alternate takedown light-effect styles | Jade |
| Emotes | Bow, taunt, victory pose, meditation idle | Jade |
| Spirit Companions | Cosmetic animal spirit that follows player in lobby and battlefield (visual only) | Jade / Bundle |
| Titles | Displayed under username ("Flawless Disciple") | Quest / Event |
| Chapter Cosmetic Pass | Early-access exclusive skin tied to new chapter release | Robux |

### 11.3 VIP Game Pass (Robux, one-time)

- +25% XP and +25% Coin gain (time-saver, no combat power)
- Access to VIP Training Hall in Lobby (private practice arena vs. target dummies)
- VIP badge on scoreboard and above head
- Monthly exclusive cosmetic drop while active

### 11.4 Battle Pass (Seasonal, ~60 days)

- 50 tiers
- Free track: Coins, XP boosts, basic cosmetics
- Premium track (Robux): exclusive weapon skin, Ultimate FX, Spirit Companion, seasonal title
- Seasonal theme matches the current event chapter

### 11.5 Limited Items

- Rotating 48-hour limited cosmetics
- Holiday bundles (Lunar New Year, Halloween, Summer)
- Items never return after the window closes
- All limited items are cosmetic only

### 11.6 Cosmetic Crates

- Earned via gameplay or purchased with Jade Shards
- Fixed drop table published publicly (§10.4)
- Duplicate protection: repeat pulls convert to Coins
- No Robux-direct-to-crate path, complying with Roblox UGC policy

---

## 12. Lobby, Social & Multiplayer

### 12.1 Lobby (Temple Hub)

- Shared safe hub styled as the (liberated) temple courtyard: training dummies, Sifu's Dojo vendor, Cosmetic Shop stall, Battle Pass board, chapter select gate
- Players visible, can emote, chat, inspect others' loadouts and cosmetics
- VIP Training Hall accessible to GamePass holders (separate area connected to main hub)

### 12.2 Party System

- Party leader invites up to 3 friends (party of 4 total)
- Party teleports together into the selected chapter's battlefield instance
- Party chat channel persists across chapter loads
- Solo players can matchmake into an open party or run fully solo — chapter difficulty scales to actual party size (§4.3)

### 12.3 Co-op Support & Revive

- Downed players enter a "Fallen" state and can be revived by a nearby teammate (short revive animation, vulnerable during)
- If the whole party is downed, the arena's current wave restarts (not the full chapter) — keeps failure low-friction

### 12.4 Social Hooks

- Finishing Move landed → nearby teammates see a brief "FINISH!" callout
- Flawless arena clear → party-wide banner
- Boss defeat → full hub-wide announcement banner (visible to players currently in the Lobby) + fireworks over the chapter-select gate

### 12.5 Private Servers

- Standard Roblox private server (Robux or free per platform policy)
- Host sets: chapter, party difficulty scaling override, cosmetic-only "mirror match" dummy settings for practice

---

## 13. Localization

### 13.1 Supported Languages (Launch)

| Language | Code | Notes |
|---|---|---|
| English | en | Source language |
| Indonesian | id | Developer locale, strong Roblox market |
| Spanish | es | Large Roblox demographic (LatAm + ES) |
| Portuguese (BR) | pt-BR | Brazil = top Roblox market |
| French | fr | EU coverage |
| German | de | EU coverage |
| Russian | ru | Large Roblox player base |
| Chinese Simplified | zh-CN | Growing market |

Post-launch priority: Japanese (`ja`), Thai (`th`), Turkish (`tr`), Korean (`ko`).

### 13.2 Localization System

- All user-facing strings in Roblox `LocalizationTable`
- String keys use namespace prefix: `ui.button.play`, `enemy.name.wraithbruiser`, `hud.label.combo`
- No hardcoded strings in UI scripts — always via `LocalizationService:GetTranslator()`
- Numeric formatting respects locale (decimal/thousands separators)
- Combat/enemy terminology localized with natural equivalents, not just transliterated

### 13.3 Cultural Sensitivity

- Combat is stylized (light-dissolve Finishing Moves, no blood/gore) to stay broadly appropriate and Roblox-policy-safe
- No themes referencing specific real-world religious practice — the "Shaolin" framing draws on wuxia/kung-fu action fiction tropes, not real religious depiction
- Avatar items and chapter content reviewed per major market before release

### 13.4 RTL Preparedness

- Arabic/Hebrew not in v1 scope
- UI layout uses anchored/relative positioning — no hardcoded LTR pixel offsets
- Allows future RTL flip without layout rewrite

---

## 14. Asset Configuration

> **Rule: All tunable values live in one config file per domain. No magic numbers in gameplay or UI scripts. All asset IDs centralized.**

### 14.1 Config File Structure

```
src/
  shared/
    config/
      CombatConfig.lua         -- attack damage, combo timing windows, stagger/poise thresholds
      WeaponConfig.lua         -- weapon type stats, combo trees, Ultimate definitions
      EnemyConfig.lua          -- enemy stats, AI behavior params, aggro/attacker-cap values
      ChapterConfig.lua        -- chapter metadata, arena refs, difficulty tier gates
      LootConfig.lua           -- destructible container drop tables, chest tiers, rarity weights
      AccessoryConfig.lua      -- accessory slot items, rarity, unlock source
      ProgressionConfig.lua    -- XP formula, level thresholds, skill tree node costs
      ShopConfig.lua           -- item definitions, prices, bundle contents, Jade product IDs
      MonetizationConfig.lua   -- Robux product IDs, GamePass IDs, currency exchange rates
      AudioConfig.lua          -- all sound asset IDs, volumes, pitch ranges
      UIConfig.lua             -- colors, font sizes, layout anchors, responsive breakpoints
      LocalizationConfig.lua   -- supported locales, fallback chain
```

### 14.2 CombatConfig.lua (example shape)

```lua
return {
  Attacks = {
    LightDamage       = 8,
    HeavyDamage       = 20,
    ComboWindow       = 0.6,   -- seconds to chain next input
    ParryWindow       = 0.15,  -- seconds before impact for a perfect parry
    DodgeIFrames      = 0.2,
    DodgeCooldown     = 0.8,
  },
  Poise = {
    StaggerThreshold  = 100,
    PoiseDecayPerSec  = 5,     -- poise bar drains if not hit
  },
  ChiMeter = {
    Max               = 100,
    GainPerHitDealt   = 4,
    GainPerHitTaken   = 6,
  },
}
```

### 14.3 EnemyConfig.lua (example shape)

```lua
return {
  ConcurrentAttackerCap = 3,
  AggroRadius            = 24,   -- studs
  AttackTelegraph        = 0.4,  -- seconds windup before hit
  Roles = {
    Grunt    = { Health = 40,  Damage = 6,  Poise = 20 },
    Soldier  = { Health = 60,  Damage = 8,  Poise = 40, Blocks = true },
    Heavy    = { Health = 120, Damage = 16, Poise = 90 },
    Ranged   = { Health = 35,  Damage = 10, Poise = 15, AttackRange = 30 },
    Assassin = { Health = 30,  Damage = 9,  Poise = 15, MoveSpeedMult = 1.4 },
    Elite    = { Health = 300, Damage = 18, Poise = 200, UltimateAttack = true },
  },
}
```

### 14.4 LootConfig.lua (example shape)

```lua
return {
  Containers = {
    WoodenCrate = { Hits = 1, DropTable = "Common" },
    ClayUrn     = { Hits = 1, DropTable = "Common" },
    SupplyBarrel= { Hits = 2, DropTable = "Uncommon" },
    JadeChest   = { Hits = 3, DropTable = "Rare", Hidden = true },
  },
  ChestRarityWeights = {
    Arena   = { Common = 60, Uncommon = 25, Rare = 10, Epic = 4, Legendary = 1 },
    Chapter = { Common = 40, Uncommon = 30, Rare = 18, Epic = 9, Legendary = 3 },
    Boss    = { Common = 20, Uncommon = 30, Rare = 28, Epic = 16, Legendary = 6 },
    Vault   = { Common = 10, Uncommon = 25, Rare = 30, Epic = 25, Legendary = 10 },
  },
}
```

### 14.5 MonetizationConfig.lua (example shape)

```lua
return {
  GamePasses = {
    VIPPassId    = 0,  -- fill before launch
    BattlePassId = 0,
  },
  JadeProducts = {
    { ProductId = 0, Jade = 100,  Robux = 80  },
    { ProductId = 0, Jade = 550,  Robux = 400 },
    { ProductId = 0, Jade = 1200, Robux = 800 },
  },
  CoinToJadeRate = nil,  -- Coins NOT convertible to Jade (one-way economy)
  VIPBoostXP     = 0.25,
  VIPBoostCoins  = 0.25,
}
```

### 14.6 Config Access Pattern

```lua
-- src/shared/ConfigService.lua
local Config = {
  Combat       = require(script.Parent.config.CombatConfig),
  Weapon       = require(script.Parent.config.WeaponConfig),
  Enemy        = require(script.Parent.config.EnemyConfig),
  Chapter      = require(script.Parent.config.ChapterConfig),
  Loot         = require(script.Parent.config.LootConfig),
  Accessory    = require(script.Parent.config.AccessoryConfig),
  Progression  = require(script.Parent.config.ProgressionConfig),
  Shop         = require(script.Parent.config.ShopConfig),
  Monetization = require(script.Parent.config.MonetizationConfig),
  Audio        = require(script.Parent.config.AudioConfig),
  UI           = require(script.Parent.config.UIConfig),
  Localization = require(script.Parent.config.LocalizationConfig),
}
return Config
```

---

## 15. UI/UX

### 15.1 HUD (in-battlefield)

```
┌──────────────────────────────────────────────────────┐
│ [Chapter 3 · Bamboo Forest]      Combo: 24    [Party] │
│ ▓▓▓▓▓▓▓░░░ HP     ▓▓▓▓░░░░░░ Chi                      │
│                                                        │
│                  [3D battlefield view]                 │
│                                                        │
│  [Move stick]        [Grab] [Attack] [Heavy] [Ult]    │
└──────────────────────────────────────────────────────┘
```

- HUD stays minimal outside combat, expands (combo counter, party HP bars) once an arena gate seals
- Party frames show teammate HP/Chi and "Fallen — needs revive" status
- Combo counter pulses and scales up briefly on milestone thresholds
- Style Score / reward multiplier shown at arena-clear summary, not mid-fight (keeps combat screen clean)

### 15.2 Responsive UI

- All layouts built on Roblox `UIAspectRatioConstraint` / anchor-point scaling — no fixed pixel positions
- Safe-area insets respected on notched mobile devices
- HUD reflows for three breakpoints: desktop widescreen, tablet/landscape mobile, portrait mobile (combat controls shift to bottom-corner thumb zones)
- Text and icon sizes scale via `UIConfig.lua` breakpoint table, never hardcoded per-screen
- Menus tested at ultrawide and narrow portrait extremes before release

### 15.3 Menus

Flow: Lobby → Chapter Select → Party Setup (solo/co-op) → Loadout Check (weapon/Ultimate/accessories) → Ready → Load

- All menus have back navigation (no dead ends)
- Settings: Audio volume (music/SFX separate), control scheme, graphics quality, lock-on assist toggle, language

### 15.4 Feedback Principles

- Every hit: visual (impact particle, hit-stop frame) + audio (weapon-specific impact sound)
- Finishing Move: brief slow-mo + distinct light-burst + unique sound, visible to whole party
- Flawless arena clear: banner + distinct fanfare
- Boss phase transition: screen flash + tone shift in music
- Container break: satisfying crunch/shatter sound + item pop animation toward HUD currency counter

---

## 16. Audio

All sound asset IDs live in `AudioConfig.lua`. No IDs anywhere else in code.

| Event | Sound |
|---|---|
| Light attack | Quick whoosh/strike, pitch varies per weapon |
| Heavy attack | Heavier impact thud/clang |
| Block / Parry | Metallic clash; perfect parry has a distinct "chime" variant |
| Dodge roll | Cloth whoosh |
| Finishing Move | Light-dissolve chime + brief musical sting |
| Container break | Wood crack / clay shatter / chest unlock jingle |
| Enemy hit / death | Per-role grunt/impact set |
| Boss phase transition | Musical tone shift + roar/impact |
| Ultimate activation | Weapon-specific charged release sound |
| Chi meter full | Tension sting |
| Chapter complete | Victory fanfare |
| UI click | Soft tap |
| Background music | Per-chapter combat + exploration loop pair |
| Ambient sounds | Per-chapter (temple wind, village fire crackle, forest rustle, cave drips) |

- Music and SFX volumes independently adjustable in Settings
- Combat music intensifies when an arena gate seals (layered stem swap), returns to exploration theme after clear
- No audio autoplays on the Roblox game page (follows Roblox audio policy)

---

## 17. Technical Notes

### 17.1 Architecture

- **Client:** Rendering, input handling, local UI, camera, hit-stop/impact FX, HUD
- **Server:** Authoritative hit detection, damage resolution, drop rolls, DataStore writes, anti-cheat
- **Shared:** Config (via ConfigService), utility modules, types

Attacks register client-side for responsiveness → server validates hit registration and damage → reconcile if delta exceeds threshold.

**Combat netcode approach (higher stakes than a physics-only game — hit timing must feel fair to all 4 players):**
- Each client runs local hit detection for instant attack feedback (swing animation, hit-stop, impact FX play immediately, no wait for server)
- Server re-runs the swing against its own enemy positions with a small lag-compensation window (rewind enemy hitboxes to the attacker's timestamp, standard favor-the-attacker model) before committing damage
- If server rejects a hit the client thought landed, the impact FX is silently retracted next frame (no rubber-banding — enemy just didn't take damage, no position snap)
- Enemy AI state and movement are server-owned and replicated down, not client-simulated, so all 4 players see the same enemy behavior
- Combat netcode is flagged as the highest-risk technical system in this GDD — prototype and load-test a single arena at full 4-player co-op before building out further chapters

### 17.2 Anti-Cheat

- Server owns all damage, currency, and XP writes; client cannot increment any of them directly
- Attack damage and cooldowns capped/validated server-side against `CombatConfig.lua`
- Drop rolls resolved server-side against `LootConfig.lua`, never client-asserted
- Concurrent attacker cap and enemy AI state are server-authoritative to prevent client-side enemy manipulation

### 17.3 Data Persistence

- `DataStoreService` stores: level, XP, Coins, Jade Shards, inventory (accessories/weapon skins), skill tree allocation, chapter progress, quest progress, mastery stars, streak
- Auto-save on chapter completion and lobby return
- Retry with exponential backoff on DataStore failure; backup store on second failure

### 17.4 Performance Targets

| Platform | Target FPS | Notes |
|---|---|---|
| PC | 60 | Full particles, shadows |
| Mobile | 30+ | Reduced hit-particle count (via `UIConfig`), simplified shadows |
| Console | 60 | Full particles, dynamic resolution allowed |

- LOD system for battlefield props at distance
- Enemy count and particle limits bounded per `EnemyConfig.lua` / `UIConfig.lua` per quality tier
- Max 4 players per battlefield instance; enemy AI complexity bounded by design
- Chapters load via Roblox streaming (not full upfront load)

### 17.5 Wave & Drop Determinism

- Enemy wave compositions and drop rolls use a server-seeded RNG per instance, logged for anti-cheat auditing
- Daily Relic Hunt modifiers use a shared daily seed so all players get the same remix that day

### 17.6 Pre-Launch Checklist

Open items that must close before ship, tracked here so they don't silently slip:

| Item | Risk if skipped | Owner action |
|---|---|---|
| All `0`-placeholder GamePass/Product/Asset IDs in configs | Purchases fail silently, zero revenue | Fill every ID in `MonetizationConfig.lua` / `AudioConfig.lua` and test each purchase flow in Studio before release |
| Weapon DPS balance pass | "Balanced by design" (§5.2) is a target, not a measured fact | Run combat logging across all 5 weapons vs. standard wave compositions; tune `WeaponConfig.lua` off real numbers, not intent |
| Finishing Move / violence content re-check | Roblox content policy shifts over time | Re-review the light-dissolve Finishing Move effect against current Roblox community guidelines shortly before launch, not just at design time |
| IP naming audit | Trademark/likeness risk | Confirm no character, faction, or location name (Nezhar, Jade Serpent Clan, etc.) collides with existing MK or other IP before marketing materials go out |
| 4-player combat load test | Netcode approach (§17.1) unproven at scale | Run a full arena at 4 concurrent players before greenlighting additional chapters |

---

## 18. Nuance & Feel

Small details that separate "feels great" from "just works":

- **Hit-stop:** Brief freeze-frame (~0.05–0.08s) on Heavy Attack and Finishing Move impacts sells weight
- **Camera punch-in:** Subtle zoom on boss phase transitions and Finishing Moves for cinematic emphasis
- **Ring behavior:** Non-attacking enemies visibly circle rather than idle — keeps crowds feeling alive, not decorative
- **Telegraph flash:** Attack windup has a brief material glow so reads are learnable, not memorized
- **Container feedback:** Items visibly pop and arc toward the player before flying to the HUD counter — feels earned, not just numbers ticking
- **Combo drop grace:** Short grace window before combo counter resets, so a stray dodge doesn't feel punishing
- **Revive urgency:** Fallen-teammate icon pulses and grows more urgent the longer they're down, without being anxiety-inducing
- **Boss defeat weight:** Slow-mo final blow + brief silence before victory fanfare hits — a breath before the payoff
- **Lobby training dummies:** Freely punchable; light XP-free combo practice keeps players warmed up between chapters
- **Style Score reveal:** Shown as a satisfying tally-up animation on the arena-clear screen, not a flat number dump

---

## 19. Out of Scope (v1)

Deferred to prevent scope creep:

- PvP arena mode
- Chapter/level editor or user-generated content
- Clan / guild system
- Real-money auction house for cosmetics
- Voice chat integration
- Replay export to video
- Arabic / Hebrew RTL layout
- Ranked matchmaking / ELO
- Mobile AR mode
- Graphic gore/violence beyond stylized light-dissolve effects (policy constraint, not just scope)

---

*Document maintained by: M. Iqbal Effendi*
*Last updated: 2026-08-14*
