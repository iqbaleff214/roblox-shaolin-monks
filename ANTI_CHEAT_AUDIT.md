# Anti-Cheat Audit — Server Authority (T-170, GDD §17.2)

One line per client-invokable RemoteEvent/RemoteFunction in the game (every
`Service.Client:Method` and `Knit.CreateSignal()`/`Knit.CreateProperty()`
entry across `src/server/services/*.lua`), confirming no client call can
directly mutate Coins/XP/Jade/inventory/chapter-progress (or any other
server-authoritative state) without server-side validation.

Regenerate the "Client-invokable surface" section's method list with
`lune run scripts/audit-remote-events.luau` (T-170's automated scan) whenever
a service adds/removes/renames a `Client:` method — it fails if the source
tree and this file's rows have drifted apart.

Legend: **Risk** = worst-case impact of an unvalidated spoofed call.
**Validated** = every mutating input (price, amount, id, target) is looked
up or computed server-side, never trusted from the client, per the Notes.

## Client-invokable surface

| Service | Method | Risk | Validated | Notes |
|---|---|---|---|---|
| CombatService | RequestAttack | High (damage) | Yes | Damage = server `CombatConfig` base value × server combo-walker's own multiplier; targets resolved via server-side lag-compensated raycast/history, never client-supplied. Rate-limited (`CombatService.RequestAttack`). |
| CombatService | SetBlocking | Low (local combat state) | Yes | Boolean toggle only, no numeric/economic input. |
| CombatService | RequestFinishingMove | High (damage/kill) | Yes | Requires server-tracked `enemyState.poise.isStaggered`, server-measured range, and rejects Boss/Elite roles server-side. Rate-limited. |
| CombatService | RequestUltimate | Medium (combat resource) | Yes | Gated by server `state.chi:tryActivate()`; no client-supplied amount. Rate-limited. |
| CurrencyService | GetBalance | Read-only | Yes | Returns `profile[currency]`; no mutation path. |
| AccessoryService | RequestEquip | Low (cosmetic only) | Yes | Slot/item validated against `AccessoryConfig` + `InventoryService:IsOwned`; schema structurally excludes stat fields (verified by `AccessoryConfig.spec.lua`), so equip can never affect combat stats. |
| AccessoryService | RequestUnequip | Low (cosmetic only) | Yes | Slot-validated attribute clear only. |
| WeaponService | RequestEquipWeapon | Medium (loadout) | Yes | Weapon id validated against `WeaponConfig`; locked server-side once `ArenaGateController:HasPlayerEnteredAnyArena` is true. |
| WeaponPickupService | RequestPickup | Low (temporary pickup) | Yes | Grants a fixed server `CombatConfig.WeaponPickup.MeleeSwings` count; no client-supplied amount. |
| WeaponPickupService | RequestSecondaryAttack | Medium (damage) | Yes | Damage = server `CombatConfig.WeaponPickup.MeleeDamage`; target = nearest server-tracked enemy in range. Rate-limited. |
| WeaponPickupService | RequestThrowSecondary | Medium (damage) | Yes | Damage = server config value; hit resolved via server raycast. Rate-limited. |
| DodgeService | RequestDodge | Low (i-frame timing) | Yes | Cooldown/i-frame window computed entirely server-side (`DodgeStateMachine`); client only requests, never supplies timing. Rate-limited. |
| GrappleService | RequestGrab | Medium (crowd-control) | Yes | Target must be a server-tracked Staggered enemy within server-measured `GRAB_RANGE`. Rate-limited. |
| GrappleService | RequestThrow | High (damage/instant-kill) | Yes | Damage = server `CombatConfig.Grapple.ThrowDamage`; hazard-zone instant-kill gated on a server-tagged `HazardZone` Instance found via server raycast, not a client claim. Rate-limited. |
| GrappleService | RequestReleaseGrab | Low | Yes | No numeric input. |
| ReviveService | RequestRevive | Medium (run-state) | Yes | Requires server-verified `IsFallen`/range/not-already-reviving state; heal amount is a server config fraction of `MaxHealth`. |
| InventoryService | IsOwned | Read-only | Yes | No mutation path. |
| InventoryService | GetOwnedItemIds | Read-only | Yes | No mutation path. |
| ComboScrollShopService | RequestPurchase | High (currency + inventory) | Yes | Price/currency always read server-side from `ShopConfig` by id; spend is hard-coded to `"Coins"` regardless of config, per file header. Ownership double-charge guarded via `InventoryService:IsOwned`. Rate-limited. |
| ComboScrollShopService | IsOwned | Read-only | Yes | No mutation path. |
| CosmeticShopService | RequestPurchase | High (currency + inventory) | Yes | Price/currency read server-side from `ShopConfig` by id; client only ever sends an id. Rate-limited. |
| CosmeticShopService | RequestPurchaseBundle | High (currency + inventory) | Yes | Same as above, bundle contents resolved server-side. Rate-limited. |
| CrateOpeningService | RequestPurchaseCrate | High (currency + inventory) | Yes | Price/currency from `ShopConfig`; rarity rolled server-side via `ChestRarityRoller`, no client input into the roll. Rate-limited. |
| SkillTreeService | RequestPurchaseNode | High (skill points + stats) | Yes | Cost from server `ProgressionConfig`; rank/eligibility gated by `SkillNodeRules.canPurchase` and `ProgressionService:SpendSkillPoints`, both server-side. Rate-limited. |
| SkillTreeService | GetRank | Read-only | Yes | No mutation path. |
| BattlePassService | GetCurrentTier | Read-only | Yes | No mutation path. |
| BattlePassService | HasPremium | Read-only | Yes | Live `MarketplaceService:UserOwnsGamePassAsync` check, never a cached/client-supplied flag. |
| BattlePassService | RequestClaimReward | High (currency reward) | Yes | Tier/track/claimed-state and reward table all resolved server-side from `BattlePassConfig`; Premium track re-verified live via `ownsPremium`. Rate-limited. |
| ProgressionService | GetLevel | Read-only | Yes | No mutation path. |
| ProgressionService | GetXP | Read-only | Yes | No mutation path. |
| ProgressionService | GetAvailableSkillPoints | Read-only | Yes | No mutation path. |
| QuestService | GetProgress | Read-only | Yes | No mutation path. |
| MasteryService | GetChapterStars | Read-only | Yes | No mutation path. |
| MasteryService | GetTotalStars | Read-only | Yes | No mutation path. |
| StreakService | GetLoginStreak | Read-only | Yes | No mutation path. |
| VIPService | RequestRefreshVIPStatus | Low (external API call) | Yes | Re-runs the same live `MarketplaceService` ownership check; can't set VIP true without genuine ownership. Not spam-critical to game state, but see Follow-ups. |
| VIPService | IsVIP | Read-only | Yes | No mutation path. |
| LeaderboardService | GetTopEntries | Read-only | Yes | No mutation path. |
| LeaderboardService | GetTrialRushTopEntries | Read-only | Yes | No mutation path. |
| LeaderboardService | GetFriendsEntries | Read-only | Yes | No mutation path. |
| LimitedRotationService | GetActiveRotation | Read-only | Yes | No mutation path. |
| SettingsService | LoadSettings | Read-only | Yes | Falls back to `DEFAULT_SETTINGS` on any invalid/missing stored value. |
| SettingsService | SaveSettings | Low (own-client-only preferences) | Yes | `isValidSettings` type/range-checks every field; per file header, settings never affect server-authoritative gameplay, so no deeper validation is needed. |
| PrivateServerSettingsService | RequestSetChapterOverride | Medium (server config, private-server scoped) | Yes | `isOwner` requires `player.UserId == game.PrivateServerOwnerId`; chapter id validated against `ChapterConfig`. |
| PrivateServerSettingsService | RequestSetDifficultyOverride | Medium (server config, private-server scoped) | Yes | Owner-gated; tier validated against `ChapterConfig`-derived set. |
| PrivateServerSettingsService | RequestSetMirrorMatchEnabled | Low | Yes | Owner-gated boolean. |
| PrivateServerSettingsService | GetSettings | Read-only | Yes | No mutation path. |
| PartyService | CreateParty | Low (social state) | Yes | No economic input. |
| PartyService | InviteToParty | Low (social state) | Yes | Leader-only (`roster:isLeader`), capacity-checked server-side. |
| PartyService | AcceptInvite | Low (social state) | Yes | Requires a server-recorded pending invite for that exact party id. |
| PartyService | DeclineInvite | Low (social state) | Yes | No mutation beyond clearing own pending invite. |
| PartyService | KickMember | Low (social state) | Yes | Leader-only, target-membership-checked server-side. |
| PartyService | SetReady | Low (social state) | Yes | No economic input. |
| PartyService | LeaveParty | Low (social state) | Yes | No economic input. |
| PartyService | SetOpenToMatchmaking | Low (social state) | Yes | Leader-only. |
| PartyService | RequestQuickJoin | Low (social state) | Yes | Only joins parties server-flagged `openToMatchmaking` with server-checked room. |
| PartyService | RequestStartChapter | Medium (run start) | Yes | Leader-only; only fires a signal, no state mutation of its own. |

## Server → client broadcast signals (not client-invokable; listed for completeness)

These are `Knit.CreateSignal()`/`Knit.CreateProperty()` entries fired only
server→client (`Service.Client.X:Fire(player, ...)` /`:FireAll(...)`/
`:SetFor(player, ...)`); no server code anywhere connects to a client-side
`:Fire` on them, so there is no code path for a spoofed client call to feed
back into server state. Validated by construction (absence of a server-side
listener), not by per-line logic.

`ArenaGateController.GateSealed/GateUnsealed`, `FeedbackFXService.HitStop/
FinishingMoveOverlay/BossPhaseFlash/ContainerBreakPopup/EnemyHitFX/
EnemyDeathFX`, `CombatService.Chi` (RemoteProperty), `NPCVendorService.
VendorInteracted`, `SocialHookService.FinishCallout/FlawlessBanner/
HubAnnouncement`, `PartyService.PartyUpdated/PartyInviteReceived`.

## Highest-risk coverage (currency, purchases, damage)

Server-authority for every row tagged **High** above is additionally backed
by construction guarantees documented in each service's own file header
(e.g. `ComboScrollShopService`'s hard-coded `"Coins"` spend, `CrateOpeningService`'s
config-only price/roll) and by the existing TestEZ coverage of the pure
modules they delegate to for the actual math/rolls (`ChestRarityRoller.spec.lua`,
`XPCalculator.spec.lua`, `InventoryRecord.spec.lua`, `SkillNodeRules.spec.lua`).
Live network-level fuzzing of RemoteEvents (firing malformed payloads at a
running server) isn't reproducible outside Roblox Studio/a live server in
this environment — the same constraint noted for every other "Integration
test" Test Case across this project's task list — so this audit substitutes
(1) the per-line server-authority review above and (2) the automated
source-scan drift guard (`scripts/audit-remote-events.luau`) that fails the
moment a new Client-exposed method is added without a matching row here.

## Follow-ups (not blocking, noted for a future pass)

- `CosmeticShopService.RequestPurchase`/`RequestPurchaseBundle` don't check
  prior ownership before charging (unlike `ComboScrollShopService`) — a
  player can legitimately buy the same cosmetic more than once, spending
  their own currency each time. Product-design question, not a spoofing
  vector (currency is still correctly deducted every time), so left as-is.
- `VIPService.RequestRefreshVIPStatus` isn't in T-171's rate-limited set
  (it isn't an "attack input" or "purchase request"), but a spam-fired
  client could still generate repeated `MarketplaceService` calls. Low
  priority since it can never grant unearned VIP status, only worth
  revisiting if `MarketplaceService` throttling becomes an observed issue.
