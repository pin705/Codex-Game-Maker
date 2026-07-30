# UI/UX Spec: Vân Mộng Tu Tiên

Status: V3 authored UI/portrait batch passes current parse, native desktop/phone capture and served Chromium checks; independent review pending
Implementation mode: hybrid  
Minimal UI rationale: Not applicable; this game intentionally uses authored ritual objects and chrome.  
Visual quality contract: `production/reviews/visual-quality-contract.json`  
Style lock: `design/art/style-lock.json`  
Style version: 3.0.0
Style SHA-256: 0d1b060efbb561c8625b13cd07912a49808ec704ce1d0db8ebf616d231d109da
Visual/layout smoke command ID: `visual_smoke`

Implementation resources:

- `res://scripts/ui/frontend.gd`
- `res://scripts/ui/hud.gd`
- `res://scripts/ui/raster_button.gd`
- `res://scripts/ui/van_mong_component_kit.gd`
- `res://scripts/ui/cultivation_panel.gd`
- `res://scripts/ui/cultivation_choice_button.gd`
- `res://scripts/ui/mobile_touch_controls.gd`
- `res://scripts/ui/rotate_device_overlay.gd`
- `res://resources/ui/cultivation_theme.tres`
- `res://assets/fonts/BeVietnamPro-Regular.ttf`
- `res://assets/fonts/BeVietnamPro-SemiBold.ttf`
- `res://assets/fonts/Literata-Variable.ttf`

## Visual Language

The interface combines Xuan-paper and dry-brush silhouettes with ink-black lacquer, aged bronze, restrained jade, milestone gold and cinnabar danger states. The user-approved arsenal reference adds dense-but-ordered item slots, an explicit comparison tooltip, a five-skill rail and companion management surfaces without changing the Vân Mộng identity. UIKIT-007 extends those materials into a dedicated title scroll, desktop header, modal guard, result plate, combat rail, boss bar and touch medallions. UIKIT-008 gives primary, secondary, back, stepper, destructive and confirm roles distinct silhouettes. PORTRAIT-001/002 and ACHIEVEICON-001 add dedicated dossier, HUD, boss and milestone identities. Large surfaces are asymmetric scrolls, talisman folios, seals or clipped ritual plaques; equal-weight browser-dashboard cards are forbidden. Typography is project-local: Be Vietnam Pro Regular carries body/HUD copy, Be Vietnam Pro SemiBold carries actions and compact emphasis, and Literata is restricted to large ritual headings. Depth comes from silhouette-matched shadows, inset lacquer, wax seals, pins and sparse ritual rings rather than generic gradients.

Gameplay keeps the center playfield clear. Player status occupies a notched upper-left plaque; timer and active-skill information form a separate upper-right cluster. Pause moves to the upper-right reach zone on touch layouts. Boss attacks use a complete fixed danger boundary plus an advancing timing ring, label and non-color line language.

## Screen Inventory

The evidence paths below are current native captures for the V3 batch. They
prove simulated/native layout and imported rendering, but do not replace clean-
context independent review, cross-browser or physical-device acceptance.

| State ID | Player goal | Required components | Input modes | Evidence |
|---|---|---|---|---|
| title | Enter or continue the cultivation profile | Key art, lacquer vow panel, primary/secondary commands | Keyboard, pointer, controller, touch | `production/playtests/frontend/title.png`; `title-phone.png` |
| hub | Choose the next permanent or run action | Open sect composition, doctrine ritual, expedition dossier, command seals | Keyboard, pointer, controller, touch | `production/playtests/frontend/hub.png`; `hub-phone.png` |
| stages | Compare arena risk, unlock and reward | Three sealed stage talismans, preview art, protected CTA | Keyboard, pointer, controller, touch | `production/playtests/frontend/stages.png`; `stages-phone.png` |
| loadout | Equip one doctrine and enter combat | Three authored doctrine cards, sigils, summary strip | Keyboard, pointer, controller, touch | `production/playtests/frontend/loadout.png`; `loadout-phone.png` |
| inventory | Compare and equip cultivation treasures | Character dossier, rarity grid, item tooltip, before/after deltas, equip action | Keyboard, pointer, controller, touch | `production/playtests/frontend/inventory.png`; `inventory-phone.png` |
| spirit-beast | Inspect and bind one companion | Companion portrait, assist cooldown, bond passive, evolution milestones | Keyboard, pointer, controller, touch | `production/playtests/frontend/spirit-beast.png`; `spirit-beast-phone.png` |
| techniques | Spend Linh Ngọc on persistent evolution | Account ledger, three distinct folios, live previews | Keyboard, pointer, controller, touch | `production/playtests/frontend/techniques.png`; `techniques-phone.png` |
| rank-ascension | Understand the newly unlocked visual tier | Full shade, authored scroll, animated technique preview | Automatic ritual reveal | `production/playtests/frontend/technique-upgrade.png`; `technique-upgrade-phone.png` |
| codex | Inspect known or unknown enemies | Lacquer index, bestiary talisman, paper dossier | Keyboard, pointer, controller, touch | `production/playtests/frontend/codex.png`; `codex-phone.png` |
| achievements | Review milestone progress | Six engraved lacquer records with sigils | Keyboard, pointer, controller, touch | `production/playtests/frontend/achievements.png`; `achievements-phone.png` |
| settings | Configure audio/accessibility/profile | Scrollable phone settings, compact controls, protected profile actions | Keyboard, pointer, controller, touch | `production/playtests/frontend/settings.png`; `settings-phone.png` |
| reset-confirmation | Confirm or cancel destructive deletion | Full-viewport shade, centered lacquer guard, jade/cinnabar actions | Keyboard, pointer, controller, touch | `production/playtests/frontend/reset.png`; `reset-phone.png` |
| combat | Survive, gather qi and use the doctrine | Split HUD, world actors, objective strip, authored VFX | Keyboard, pointer, controller, touch | `production/playtests/overhaul/gameplay-final.png`; `mobile-support/combat-phone.png` |
| combat-upgrade | Choose one in-run insight | Three distinct paper folios, protected type and explicit focus/touch cue | Keyboard 1–3, pointer, controller, touch | `production/playtests/overhaul/upgrade-final.png`; `mobile-support/breakthrough-phone.png` |
| combat-paused | Interrupt and safely resume | Full shade, authored paper scroll, resume/retry actions | Keyboard, controller, pointer, touch | `production/playtests/overhaul/pause-final.png`; `mobile-support/pause-phone.png` |
| results-victory | Read rewards/unlocks and continue | Lacquer outcome frame, scroll stats, hub/retry actions | Keyboard, pointer, controller, touch | `production/playtests/frontend/results.png`; `results-phone.png` |
| results-defeat | Read retained progress and recover | Ash/cinnabar hierarchy, retained reward summary, retry path | Keyboard, pointer, controller, touch | `production/playtests/frontend/results-defeat.png`; `results-defeat-phone.png` |
| portrait-guard | Rotate a phone before combat input continues | Full shade, authored plaque, qi rotation sigil | Device orientation | `production/playtests/mobile-support/portrait-overlay.png` |

## HUD Hierarchy

Critical persistent information: realm, health, qi/level, run timer, kill count and active doctrine cooldown.  
Contextual information: objective strip, transient realm banner, breakthrough choice and boss name/health.  
Center-playfield protection: no persistent command or pause target occupies the center-top or center-bottom sightline; touch controls remain in separate lower thumb zones.

## Component System

Theme/style resources: `CultivationPanel`, `RasterButton`, `VanMongComponentKit`, `CultivationMeter`, `TechniquePreview`, UIKIT-007 ritual surfaces, UIKIT-008 controls, UIKIT-006 arsenal plates, PORTRAIT-001/002, ACHIEVEICON-001, UIICON-001 relics, SKILLICON-001 five-formation glyphs, UIKIT-004 folios, transitional UIKIT-005 controls, the active UIKIT-002 scroll/talisman components, Be Vietnam Pro and Literata.
Panels and frames: UIKIT-007 owns the title scroll, wide desktop header, guarded modal, result plate, five-skill rail, boss bar and touch medallions. Its `wide_header`, `modal_guard` and `result_plate` regions alone are dedicated nine-slices; title, boss and rail regions are aspect-fitted. The current phone capture accepts the near-square touch draw without blocking distortion. UIKIT-005 lacquer and UIKIT-002 paper remain transitional support; aspect-preserved folios and sigils serve irregular ritual objects. Custom drawing remains authoritative for meters, focus rings and combat telegraphs.
Buttons and focus states: `RasterButton` selects distinct UIKIT-008 primary, secondary, back and destructive silhouettes; compact steppers use the UIKIT-008 medallion where space permits. Gold is primary/milestone, jade is safe/selected, ink is secondary and cinnabar is destructive through authored shape plus restrained runtime edge/tint/wording; hover/focus raises frame emphasis, press scales inward, and disabled states dim art while retaining readable text.
Meters, cards, tooltips and prompts: health/qi/cooldown never rely on color alone; talisman cards protect text inside the detected folio silhouette; compact `−/+` controls deliberately use crisp native material drawing and tooltips rather than cropped raster fragments.

| Asset/component ID | Source kind | Render mode | Native/frame size | Runtime/tested size range | Protected text rect | Evidence |
|---|---|---|---|---|---|---|
| `UIKIT-005-lacquer-panel` | dedicated-component | nine-slice | 784×784 RGBA | 600×76 transient notice; 408×278 to 1048×710 meta surfaces; 1004×744 result shell | 34–78 px runtime patch margin by surface class | `production/playtests/frontend/hub.png`, `production/playtests/frontend/results.png` |
| `UIKIT-002-scroll-panel` | dedicated-component | nine-slice | 396×447 | 540×286 to 1034×704 | 12% inset, excluding rollers/flourish | `production/playtests/frontend/settings.png` |
| `UIKIT-002-talisman-card` | dedicated-component | nine-slice | 266×458 | 388×510 to 456×640 | x 12–88%, y 10–92% | `production/playtests/frontend/stages.png` |
| `UIKIT-005-command-ink` | dedicated-component | nine-slice | 656×160 RGBA | 184×64 to 390×66 | 56 px horizontal / 30 px vertical patch margins | `production/playtests/frontend/title.png`, `production/playtests/frontend/stages.png` |
| `RasterButton` compact controls | authored-native | custom/native | logical control | 112×64 to 160×64 | 12 px caption inset; no raster crop | `production/playtests/frontend/settings.png` |
| `UIKIT-004-folio-sword` | dedicated-component | uniform | 759×1342 | 250×260 phone; 330×390 breakthrough; 366×704 meta | 70% of fitted visual width | `production/playtests/overhaul/upgrade-final.png` |
| `UIKIT-004-folio-jade` | dedicated-component | uniform | 703×1399 | 250×260 phone; 330×390 breakthrough; 366×704 meta | 70% of fitted visual width | `production/playtests/frontend/techniques.png` |
| `UIKIT-004-folio-spirit` | dedicated-component | uniform | 917×1458 | 250×260 phone; 330×390 breakthrough; 366×704 meta | 70% of fitted visual width | `production/playtests/overhaul/upgrade-final.png` |
| `PREMIUM-001-sigils` | dedicated-component | uniform | 512×512 | approximately 53×53 to 200×200 | not applicable; icon-only | `production/playtests/frontend/loadout.png` |
| `UIKIT-006-arsenal-plates` | generated-raster-atlas | fixed-ratio/material-chrome | 1254×1254 atlas | item 132×146; tooltip 448×694; rail 860×100 | runtime labels remain outside texture; slot text stays in lower 38% | `production/playtests/frontend/inventory.png`, `spirit-beast.png`, `production/playtests/overhaul/gameplay-final.png` |
| `UIKIT-007-ritual-surface-atlas` | generated-raster-atlas | aspect-fit, three dedicated nine-slices and custom touch draw | 1536×1024 atlas; nine regions | title visual 456×820 in 720×820 bounds; header 820–900×92; rail 800×164; boss 520×122; square safe-area touch targets | all copy/stats/cooldowns remain separate nodes; margins: header 76/38/76/38, modal 66/52/66/52, result 86/52/86/52 | `production/playtests/frontend/title.png`, `title-phone.png`, `production/playtests/overhaul/boss-final.png`, `production/playtests/mobile-support/boss-phone.png` |
| `UIKIT-008-control-silhouettes` | generated-raster-atlas | mixed dedicated nine-slice and uniform | 1536×1024 atlas; six runtime crops | 128×64 back to 390×66 primary; 64–96 px medallions | captions/focus/disabled/destructive state remain live; recorded margins per crop | `production/playtests/frontend/title.png`, `hub.png`, `settings.png`, `title-phone.png`, `hub-phone.png` |
| `PORTRAIT-001/002` | generated-raster-atlas | uniform | six 512×512 dossier cells; two 887×887 HUD cells | 72–260 px by surface | no baked title/stat; portraits never replace combat frames | `production/playtests/frontend/codex.png`, `spirit-beast.png`, `production/playtests/overhaul/boss-final.png` |
| `ACHIEVEICON-001-six-seals` | generated-raster-atlas | uniform | six 512×512 cells | 64–88 px | progress/title/state remain live | `production/playtests/frontend/achievements.png`, `achievements-phone.png` |
| `UIICON-001-relics` | generated-raster-atlas | uniform/fixed-ratio | 1448×1086 atlas; 362×362 cells | item icon 56–104 px | transparent padding is preserved; no baked rarity/title | `production/playtests/frontend/inventory.png`, `inventory-phone.png` |
| `SKILLICON-001-five-formation` | generated-raster-atlas | uniform | 1536×1024 atlas; 512×512 cells plus Linh Phù replacement | skill glyph 54–70 px | icons are separate from medallion/lock chrome; rank/cooldown/key remain live | `production/playtests/overhaul/gameplay-final.png`, `production/playtests/frontend/techniques.png` |
| `FONT-001-be-vietnam-pro` | licensed project-local font family | runtime FontFile | Regular + SemiBold TTF | 14–50 logical px by role | Vietnamese copy remains live; primary font is bundled while the importer permits system fallback | Current native 1600×900/844×390 and served Chromium glyph rendering pass |
| `FONT-002-literata` | licensed project-local variable font | runtime FontFile | roman `opsz,wght` TTF | 25–50 logical px display role | large headings only; body/actions remain Be Vietnam Pro; importer permits system fallback | Current native and served Chromium display-title rendering pass |
| `MobileTouchControls` | procedural plus sigil | custom/uniform | device-space control | minimum 64×64 physical hit targets after expand compensation | label outside hit disc | `production/playtests/mobile-support/combat-phone.png` |

Legacy status: UIKIT-003 command PNGs and UIKIT-002 `ui_lacquer_panel`, compact
button/tab crops and `ui_icon_*` medallions are retained for provenance only and
have no current runtime references. PREMIUM-001 is the sole required technique
icon family. Canonical UIKIT-005 provenance is
`assets/source-prompts/UIKIT-005-restrained-controls.yaml`.

## Input And Focus

Keyboard/mouse: arrows/WASD navigate where appropriate; Enter/A confirms; Escape/B backs out; pointer hover and click remain supported. Combat uses WASD/arrows, Space for the doctrine skill, P for pause and R for retry.  
Controller: all menu Buttons use native focus and the first valid action receives deferred focus after a screen/modal change. Confirm/back prompt wording remains platform-neutral where glyph switching is not available.  
Touch if applicable: joystick, skill and pause targets are independently tracked for multitouch, mirror the existing InputMap, remain disjoint and clamp to asymmetric device safe areas. Pause opens real `TIẾP TỤC` and `NHẬP THẾ LẠI` actions, so touch users never depend on the keyboard-only `P` binding. Portrait blocks combat input.  
Dynamic prompt strategy: keyboard/controller wording is text-based; touch layouts remove the keyboard prefix from the skill cooldown. Shipping glyph-family detection remains a later platform pass.

## Responsive Layout

Reference resolution: 1600×900 logical landscape canvas.  
Safe zones: critical HUD and touch targets remain inside the intersection of platform safe area and a conservative 5% title-safe inset; pause reserves upper-right space.  
UI scale behavior: `canvas_items + expand`; desktop/ultrawide keeps a centered 1600×900 authoring canvas, while 844×390 phone landscape switches to a dedicated device-space canvas with an inverse expand transform. It is not a scaled-down desktop composition. Backgrounds remain aspect-preserving cover and every phone modal uses the same 844×390 local canvas.  
Target resolutions/aspects: verified automated layouts at 1600×900, 1280×720, true 2100×900 ultra-wide, 900×1600 portrait guard and renderer-backed 844×390 landscape meta/combat captures. At 844×390 all 45 meta buttons and the three combat touch zones retain a 64 px physical floor. These captures prove the implementation and simulated geometry; they do not replace physical iOS/Android notch, DPI, thumb-reach, thermal or browser QA.

## Accessibility

Text sizing and contrast: body copy is at least 14 logical px on the reference canvas, titles 24–50 px, paper uses dark ink, lacquer uses warm paper. Be Vietnam Pro Regular/SemiBold and Literata are bundled locally under OFL 1.1; a fresh Vietnamese glyph and longest-copy capture remains required. Final low-DPI phone readability remains part of physical-device QA.
Non-color encoding: selected/disabled/destructive states differ by wording, frame family, brightness and silhouette in addition to color; boss telegraph uses two boundaries and runes.  
Reduced motion: profile setting lowers particle caps, trail lengths, animation timing and screen-motion feedback while retaining state information.  
Remapping and prompt updates: InputMap actions are centralized; a player-facing remapping screen and platform-glyph swap are outside this candidate and must be completed before a broad commercial release claim.

## Motion And Feedback

Transition language: short fades and ritual reveals; persistent screens switch immediately to preserve controller predictability.  
Hover/focus/pressed/disabled states: authored frame brighten, slight lift/scale, protected focus seal for folios, deep press, dim plus explicit disabled label.  
UI audio cues: button presses route through `AudioDirector.play_ui`; title, hub, combat and result loops are distinct. A human listening review is still required.

## Evidence

Runtime captures: `production/playtests/frontend/`, `production/playtests/overhaul/`, `production/playtests/mobile-support/`, `production/playtests/responsive/` contain the current V3 native evidence; title and boss desktop/phone captures were refreshed after the final protected-label and boss-bar position fixes.
Navigation test: `tests/smoke_frontend_flow.tscn`, `tests/smoke_mobile_support.tscn`, `tests/smoke_responsive_layout.tscn`.  
Known findings: Godot 4.6.2 parse plus runtime/mobile/responsive smokes pass; the refreshed Web export renders cleanly at 1600×900 and 844×390 with no console warning/error, and `boss_bar` is bound. `status_plaque` remains intentionally unused. Physical iOS/Android notch, DPI, thumb reach and thermal QA; Firefox/Safari Web matrix and human Web audio output review; manual four-minute feel pass; human audio listening; final platform glyph/remapping pass and clean-context independent visual review remain open. These open gates prevent a commercial-ready claim.
