# Visual Quality Review: Vân Mộng Tu Tiên / Local Candidate

Status: **BLOCKED**  
Reviewed: 2026-07-30T09:53:39+07:00  
Reviewer: Codex clean-context independent visual reviewer (`/root/independent_visual_review_final`)  
Reviewer mode: independent agent; did not author or select the current game, UI, VFX, or art changes  
Method: native-resolution `view_image` inspection of every required desktop and phone capture, both boss-condition captures, rank VFX evidence, portrait/ultrawide diagnostics, and current served Chromium captures

## Evidence First

- Reviewed build fingerprint: `fad372c5a3771e23fce32b12a64f9e9037f311112c2ebfd9ec3d4d84576fa210`
- Reviewed commit: `c5e90f9acc8ba4fc5edd3591459fb0d2af775569` (`git_dirty: false` in the bound quality run)
- Godot: `4.6.2.stable.official.71f334935`
- Quality evidence: `production/evidence/quality-run.json`, SHA-256 `bacbbe75859125d76a2493af245a12871327aee124115e1c1370e50ed37d00bc`
- Visual-smoke command SHA-256: `c6dec56e4025779e124de21f23f0d9b38d66e2c6b112b60dfbe107f04822c987`
- Capture integrity: PASS — all 30 required captures, both boss-condition captures, and all three look-dev candidate files match the SHA-256 values in `production/reviews/visual-quality-contract.json`.
- Style lock: PASS — style `van-mong-living-ink-lacquer` version `2.0.0`, digest `0c5290bf863761218e7a7a0e995c18cf07409a4137907ae34a350a72d179ac9c`.
- `cgm doctor`: PASS_WITH_WARNINGS only for unavailable PowerShell and optional Pillow/numpy dependencies; no visual evidence blocker.
- `cgm player-ready --skip-quality`: BLOCKED as expected by the still-open visual, manual-playtest, listening, and physical-device requirements.

## Blocking Findings

| Severity | Scope | Finding | Evidence | Required resolution |
|---|---|---|---|---|
| High | Settings / 844×390 phone | The settings scroll/panel continues below the viewport. `RUNG MÀN HÌNH` and all three bottom navigation actions are absent from the capture, so required content is clipped with no visible scrolling/paging affordance. | `production/playtests/frontend/settings-phone.png`, SHA-256 `3bb91db516c79aba1cfc09de2c9e542146c8bf51bb6304d50d3b030a808d12d9` | Fit every row and required action in device space, or provide and capture an obvious operable scroll/page affordance without frame clipping. |
| High | Served Web / Chromium | Functional symbols use missing-glyph boxes. The Linh Ngọc diamond is broken on Hub desktop/phone, and Hiểm Họa rank diamonds appear as boxes on Stage Select. This is placeholder/fallback rendering, not authored final UI. | `web-hub.png` `daf2bd…`, `web-hub-phone.png` `dcab86…`, `web-stages.png` `26b396…` under `production/evidence/platforms/` | Ship font coverage or authored icon textures, then recapture served Chromium and bind the corrected hashes. |

No other required desktop or simulated-phone surface shows a blocking overlap, clipped frame, stretched material, unreadable primary action, placeholder actor, or broken hierarchy.

## Required Surface Status

| Required state | Desktop 1600×900 | Phone 844×390 | Independent finding |
|---|---:|---:|---|
| title | PASS | PASS | Strong key-art hierarchy; lacquer panel and selected action are coherent and contained. |
| hub | PASS | PASS | Desktop editorial three-island hierarchy translates to a dedicated phone composition without edge collision. |
| stages | PASS | PASS | Three choices remain distinct; locked/danger states use restrained cinnabar and clear disabled treatment. |
| loadout | PASS | PASS | Authored talisman cards, icons, selection state, and primary action fit cleanly. |
| techniques | PASS | PASS | Distinct folio silhouettes avoid a flat dashboard grid; primary upgrade actions remain visible. |
| rank-ascension | PASS | PASS | Post-upgrade modal contrast and focus are clear; the phone modal stays within device bounds. |
| codex | PASS | PASS | Bestiary asset, title, classification, and counterplay remain coherent; phone uses a compact summary rather than shrinking the full scroll. |
| achievements | PASS | PASS | Completion/progress hierarchy and six-card grid remain distinguishable. |
| settings | PASS | **BLOCKED** | Phone content/navigation is vertically clipped below the viewport. |
| reset-confirmation | PASS | PASS | Destructive/non-destructive actions have distinct cinnabar/jade material cues and safe margins. |
| combat | PASS | PASS | Player, ordinary enemies, boss, pickups, sword, jade effects, and complete danger radius separate by value, silhouette, and functional color. Touch controls remain outside the central combat lane. |
| combat-upgrade | PASS | PASS | Three breakthrough choices are distinct, readable as interactive folios, and fully contained. |
| combat-paused | PASS | PASS | Pause veil suppresses the arena while preserving clear resume/restart hierarchy. |
| results-victory | PASS | PASS | Gold/jade outcome hierarchy and both actions fit without overlap. |
| results-defeat | PASS | PASS | Cinnabar defeat hierarchy remains distinct from victory without losing text/action contrast. |

## Cross-Surface Assessment

- Art direction: PASS. Warm paper, blue-black ink/lacquer, aged bronze, restrained gold, jade safety, and cinnabar threat roles stay coherent across meta UI and combat.
- Authored asset/material coherence: PASS. Key art, arena, actors, icon medallions, talisman folios, scrolls, plaques, and HUD islands form one family; the rejected glossy-dashboard direction is not present in the current set.
- Composition and hierarchy: PASS for 14/15 required surfaces. Settings phone is the sole required-surface composition failure.
- Combat readability: PASS in still evidence. The player light plane, hostile dark/cinnabar silhouettes, boss mass, full danger boundary, and jade/qi feedback remain separable against the quiet arena center.
- VFX language: PASS_WITH_WARNING. Sword and qi rank escalation are clear; jade rank 1 versus rank 5 is comparatively subtle at runtime scale.
- Typography: BLOCKED cross-platform. Native desktop hierarchy is clear, but phone supporting copy is visibly softened/small, and served Chromium has missing functional glyphs.
- Texture integrity: PASS. No stretched folios, distorted plaques, obvious nine-slice damage, baked pseudo-calligraphy, visible debug geometry, or primitive-only final actors were found.
- Phone safe area: PASS in simulated combat/title/hub/modal evidence, except the settings overflow. Physical notch/home-indicator and real-size target verification remains external.

## Non-Blocking Warnings

| Severity | Scope | Finding |
|---|---|---|
| Medium | All simulated phone captures | Primary labels and actions remain recognizable, but supporting copy is visibly softened and several controls are small at the native 844×390 capture size. Physical-size review is required before accepting mobile legibility/touch targets. |
| Low | Combat VFX | Jade rank escalation is subtler than sword and qi escalation in the rank-1/rank-5 stills. |

## External Blockers Still Open

- Physical iOS and Android landscape QA: DPI, notch/home-indicator safe areas, thumb reach, touch-target size, sustained touch, device rendering, and thermal behavior.
- Firefox and Safari served-Web visual/input/focus review. Chromium is the only browser with current served evidence, and its glyph blocker must be fixed first.
- Human audio listening: outside this visual review, but still a separate player-ready requirement.

## Verdict

**BLOCKED**

The bounded visual gate does not pass because one required phone surface is clipped and current served Chromium evidence contains unsupported-glyph placeholders. Fourteen of fifteen required surfaces otherwise pass the independent capture review, with coherent authored materials, readable combat silhouettes, complete boss telegraph boundaries, and no blocking desktop overlap or texture distortion.
