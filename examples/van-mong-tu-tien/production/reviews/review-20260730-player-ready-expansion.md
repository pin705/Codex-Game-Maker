# Audit mở rộng PLAYER_READY — Vân Mộng Tu Tiên

Date: 2026-07-30  
Reviewer role: Game Director / Senior Game Designer / UI-UX Director / Technical Artist / Combat Designer / Godot Lead  
Runtime baseline: Godot 4.6.2 quality runner and served Chromium; native captures use Godot 4.4 Compatibility on the same project feature baseline  
Gate: BLOCKED — project is a strong bounded cultivation-survivor candidate, but it does not yet satisfy the expanded five-skill, loot/equipment and spirit-beast player promise.

## Runtime evidence read and run

- Read the complete concept/system GDD set, state graph, art bible/style lock, UI spec, architecture/control manifest, save/migration code, input map, balance data, asset coverage and current reviews.
- Ran 15-command quality manifest: all commands passed before the expanded scope was accepted.
- Independent capture review passed 14/15 existing surfaces and found two internal high issues: phone Settings scrolling and unsupported Web glyphs.
- Batch-1 targeted lint, responsive layout, Web export and browser smoke passed after both issues were fixed. Current served Chromium captures contain no missing-glyph boxes.

## Existing player loops

- Core fantasy: a fragile kiếm tu becomes the center of an increasingly elaborate sword formation in a four-minute tribulation.
- 30-second loop: reposition, auto-fire phi kiếm, time Chấn Khí, collect linh khí, choose a breakthrough.
- Session loop: Title → Sect Hub → Stage → Doctrine → Combat → Breakthrough/Pause → Victory/Defeat → Reward → Hub/Retry.
- Meta loop: earn Linh Ngọc, unlock stages, purchase three permanent technique tracks, fill bestiary and achievements, change settings or reset the profile.

## Existing player journey and surfaces

Existing and functioning: title, hub, stage select, doctrine loadout, permanent techniques, rank ascension, bestiary, achievements, settings, protected reset, combat HUD, breakthrough, pause, victory result, defeat result and portrait guard.

Required by the expanded player promise but absent: five-slot skill loadout/status, inventory, equipment comparison, item tooltip, loot notification/claim, post-run loot resolution, spirit-beast stable/loadout, spirit-beast evolution and an explicit run-build summary.

## Severity findings

### P0 — blockers / broken release evidence

- Existing phone Settings capture did not visibly expose its lower actions. Fixed in Batch 1 with a contained viewport frame, an actual scrollbar and a visible swipe affordance.
- Served Chromium rendered unsupported diamond glyphs as fallback boxes. Fixed in Batch 1 by replacing functional Unicode ornament with Vietnamese text and authored/runtime iconography.
- Expanded Definition of Done has no implemented inventory/equipment, loot or spirit-beast runtime path; PLAYER_READY cannot pass until these journeys exist and affect combat.

### P1 — shallow or disconnected systems

- Combat currently has one auto attack and one manual radial skill, not five equipped active skills.
- Upgrade catalog is embedded in `main.gd`; rank behavior is mostly multiplicative stats and does not implement five milestone behaviors/evolutions per skill.
- Level is not capped at 20 and the offer generator is not yet driven by unlocked/equipped/max-rank rules, reroll or skip economy.
- Loot does not exist; results grant only currency. There is no ItemDefinition/ItemInstance split, affix/set logic, compare/equip/salvage loop or encounter-aware loot table.
- Permanent techniques are three isolated multiplier tracks; they are not linked to skill tags, equipment or spirit beasts.
- No equipped spirit beast, assist cooldown, targeting, bond, evolution or cleanup lifecycle exists.
- Boss has a readable telegraph and slam, but no explicit phase transition or build-changing mechanic.
- `main.gd` and `frontend.gd` have grown into large orchestration files; data definitions and presentation builders need incremental extraction, not a rewrite.

### P2 — polish, balance and platform evidence

- Human four-minute balance playtest, human audio listening, physical iOS/Android QA and Firefox/Safari matrix remain open.
- Phone support copy is readable but softened at 844×390; physical DPI validation is still required.
- Headless UI harnesses emit renderer teardown warnings at process exit; no growth or runtime crash is observed, but they should remain tracked.
- Controller prompt glyph switching and player-facing remapping remain outside the current implementation.

## Keep / refactor / replace

- Keep: scene composition, profile corruption recovery, stage/doctrine records, existing actor/environment/UI assets, VFX tiers, input context gating, responsive phone canvas, audio buses and the current four-minute escalation.
- Refactor incrementally: skill definitions/offers, run loadout/cooldowns, item/loot data, permanent modifier composition, HUD skill row and front-end screen registry.
- Replace: unsupported text ornaments, hard-coded upgrade catalog, currency-only reward payload and one-phase boss decision model.
- Do not replace: locked living-ink/lacquer direction or accepted actor/environment families unless a runtime composite proves a better coherent direction.

## Reference decision

Quỷ Cốc Bát Hoang is used only for high-level lessons: compact resource grouping, a legible skill strip, parchment information density and clear separation between world combat and deep management screens. Vân Mộng retains its own asymmetric lacquer/scroll silhouettes, palette, icon family, terminology, VFX and layout.

## Batch sequence

1. Audit, blocker fixes, expanded contracts and reusable component foundation.
2. Data-driven five-skill run system, level 1–20, milestone upgrades/evolutions and combat feedback.
3. Loot/items/equipment, meaningful techniques, spirit beast, save v3 migration and economy.
4. Enemy/elite/boss phases, balance and all missing journeys.
5. Final art/audio/accessibility/performance regression, full captures and player-ready gates.

