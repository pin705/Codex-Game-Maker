# UI/UX Spec: Vân Mộng Tu Tiên

Status: Verified  
Implementation mode: hybrid  
Minimal UI rationale: Not applicable; this game intentionally uses authored ritual objects and chrome.  
Visual quality contract: `production/reviews/visual-quality-contract.json`  
Style lock: `design/art/style-lock.json`  
Style version: 2.0.0  
Style SHA-256: 0c5290bf863761218e7a7a0e995c18cf07409a4137907ae34a350a72d179ac9c  
Visual/layout smoke command ID: `visual_smoke`

Implementation resources:

- `res://scripts/ui/frontend.gd`
- `res://scripts/ui/hud.gd`
- `res://scripts/ui/raster_button.gd`
- `res://scripts/ui/cultivation_panel.gd`
- `res://scripts/ui/cultivation_choice_button.gd`
- `res://scripts/ui/mobile_touch_controls.gd`
- `res://scripts/ui/rotate_device_overlay.gd`
- `res://resources/ui/cultivation_theme.tres`

## Visual Language

The interface combines Xuan-paper and dry-brush silhouettes with ink-black lacquer, aged bronze, restrained jade, milestone gold and cinnabar danger states. Large surfaces are asymmetric scrolls, talisman folios, seals or clipped ritual plaques; equal-weight browser-dashboard cards are forbidden. Typography uses warm paper/ink contrast with concise Vietnamese uppercase eyebrows, a strong title line and quieter explanatory copy. Depth comes from silhouette-matched shadows, inset lacquer, wax seals, pins and sparse ritual rings rather than generic gradients.

Gameplay keeps the center playfield clear. Player status occupies a notched upper-left plaque; timer and active-skill information form a separate upper-right cluster. Pause moves to the upper-right reach zone on touch layouts. Boss attacks use a complete fixed danger boundary plus an advancing timing ring, label and non-color line language.

## Screen Inventory

| State ID | Player goal | Required components | Input modes | Evidence |
|---|---|---|---|---|
| title | Enter or continue the cultivation profile | Key art, lacquer vow panel, primary/secondary commands | Keyboard, pointer, controller, touch | `production/playtests/frontend/title.png`; `title-phone.png` |
| hub | Choose the next permanent or run action | Open sect composition, doctrine ritual, expedition dossier, command seals | Keyboard, pointer, controller, touch | `production/playtests/frontend/hub.png`; `hub-phone.png` |
| stages | Compare arena risk, unlock and reward | Three sealed stage talismans, preview art, protected CTA | Keyboard, pointer, controller, touch | `production/playtests/frontend/stages.png`; `stages-phone.png` |
| loadout | Equip one doctrine and enter combat | Three authored doctrine cards, sigils, summary strip | Keyboard, pointer, controller, touch | `production/playtests/frontend/loadout.png`; `loadout-phone.png` |
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

Theme/style resources: `CultivationPanel`, `RasterButton`, `CultivationMeter`, `TechniquePreview`, the PREMIUM-001 sigils, UIKIT-004 folios, UIKIT-005 restrained controls and only the active UIKIT-002 scroll/talisman components.  
Panels and frames: UIKIT-005 supplies the matte blue-black nine-slice lacquer shell; UIKIT-002 scroll/talisman paper remains active; aspect-preserved folios and sigils serve irregular ritual objects. Custom drawing remains authoritative for meters, focus rings and combat telegraphs.  
Buttons and focus states: one UIKIT-005 matte ink plaque replaces separate glossy gold/jade/ink assets. Gold is primary/milestone, jade is safe/selected, ink is secondary and cinnabar is destructive through restrained runtime edge/tint/wording; hover/focus raises frame emphasis, press scales inward, and disabled states dim art while retaining readable text.  
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

Text sizing and contrast: body copy is at least 14 logical px on the reference canvas, titles 24–50 px, paper uses dark ink, lacquer uses warm paper. Final low-DPI phone readability remains part of physical-device QA.  
Non-color encoding: selected/disabled/destructive states differ by wording, frame family, brightness and silhouette in addition to color; boss telegraph uses two boundaries and runes.  
Reduced motion: profile setting lowers particle caps, trail lengths, animation timing and screen-motion feedback while retaining state information.  
Remapping and prompt updates: InputMap actions are centralized; a player-facing remapping screen and platform-glyph swap are outside this candidate and must be completed before a broad commercial release claim.

## Motion And Feedback

Transition language: short fades and ritual reveals; persistent screens switch immediately to preserve controller predictability.  
Hover/focus/pressed/disabled states: authored frame brighten, slight lift/scale, protected focus seal for folios, deep press, dim plus explicit disabled label.  
UI audio cues: button presses route through `AudioDirector.play_ui`; title, hub, combat and result loops are distinct. A human listening review is still required.

## Evidence

Runtime captures: `production/playtests/frontend/`, `production/playtests/overhaul/`, `production/playtests/mobile-support/`, `production/playtests/responsive/`.  
Navigation test: `tests/smoke_frontend_flow.tscn`, `tests/smoke_mobile_support.tscn`, `tests/smoke_responsive_layout.tscn`.  
Known findings: physical iOS/Android notch, DPI, thumb reach and thermal QA; Firefox/Safari Web matrix and human Web audio output review; manual four-minute feel pass; human audio listening; final platform glyph/remapping pass. Godot 4.6.2 served Chromium smoke is recorded in `production/evidence/platforms/web-browser-review.md`; these remaining findings prohibit a commercial-ready claim.
