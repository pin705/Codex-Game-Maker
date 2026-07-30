# UI/UX Spec: Vân Mộng Tu Tiên V4

Status: implemented; bounded independent visual PASS
Implementation mode: hybrid — scalable Godot-native/custom-drawn controls with authored icons, portraits and environment art
Style version: `4.1.0`
Style digest: `f3860c3b2de68a5241f5705b66e1c0c327c94a14ad13a99e50898f76914b6024`
Visual contract: `production/reviews/visual-quality-contract.json`

Approved target: `design/art/lookdev/v4/master-board-candidate-01.png`

## V4 Direction

The interface uses one authored material family across meta and combat: matte
blue-black ink, warm muted paper, thin aged bronze, restrained jade focus and
cinnabar danger. Hierarchy comes from composition, type, negative space and
component silhouette before ornament.

- Production buttons, panels, tabs, meters, slots and modals are scalable native
  or custom-drawn controls. Generated chrome atlases are provenance/fallback,
  not the default layer.
- Meta screens share one subdued sect backing. Stage paintings appear only in
  contained previews or actual combat and preserve aspect ratio.
- The hub has three unequal priorities: equipped identity, current expedition
  and a compact command rail.
- Combat keeps compact edge islands and a five-skill rail; the movement lane and
  boss telegraph remain visually dominant.
- Phone landscape is a dedicated 844×390 device-space layout. Optional copy is
  removed before labels are reduced.
- Runtime Vietnamese text uses bundled Be Vietnam Pro; Literata is reserved for
  ritual headings. No generated image owns readable text.

## Required Surfaces

| State ID | Primary composition | Desktop / phone evidence |
|---|---|---|
| `title` | Key art, quiet vow plate, primary/secondary actions | `frontend/title.png`; `title-phone.png` |
| `hub` | Identity folio, expedition dossier, command rail | `frontend/hub.png`; `hub-phone.png` |
| `stages` | Three contained arena choices with lock/risk/reward | `frontend/stages.png`; `stages-phone.png` |
| `loadout` | Three doctrine cards and protected enter action | `frontend/loadout.png`; `loadout-phone.png` |
| `inventory` | Character dossier, relic grid and compare/equip plate | `frontend/inventory.png`; `inventory-phone.png` |
| `spirit-beast` | Companion portrait, assist, passive and evolution strip | `frontend/spirit-beast.png`; `spirit-beast-phone.png` |
| `techniques` | Three permanent technique folios | `frontend/techniques.png`; `techniques-phone.png` |
| `rank-ascension` | Shaded ritual reveal and live technique preview | `frontend/technique-upgrade.png`; `technique-upgrade-phone.png` |
| `codex` | Threat index and readable dossier | `frontend/codex.png`; `codex-phone.png` |
| `achievements` | Two-column milestone ledger | `frontend/achievements.png`; `achievements-phone.png` |
| `settings` | Audio, motion, shake and protected profile actions | `frontend/settings.png`; `settings-phone.png` |
| `reset-confirmation` | Guarded destructive modal | `frontend/reset.png`; `reset-phone.png` |
| `combat` | Status island, timer/action state, skill rail, touch zones | `overhaul/gameplay-final.png`; `mobile-support/combat-phone.png` |
| `combat-upgrade` | Three in-run insight folios | `overhaul/upgrade-final.png`; `mobile-support/breakthrough-phone.png` |
| `combat-paused` | Quiet interruption modal with recovery actions | `overhaul/pause-final.png`; `mobile-support/pause-phone.png` |
| `results-victory` | Gold/jade summary, stats and recovery actions | `frontend/results.png`; `results-phone.png` |
| `results-defeat` | Cinnabar summary with retained progression | `frontend/results-defeat.png`; `results-defeat-phone.png` |
| `portrait-guard` | Orientation block and rotation instruction | `mobile-support/portrait-overlay.png` |

## Component System

| Component | Runtime role |
|---|---|
| `RitualSurface` | Custom-drawn clipped command/panel silhouette with ink, paper, bronze, focus, pressed and disabled states |
| `RasterButton` | Compatibility API over native V4 commands; live caption, focus and guaranteed Web marker glyph |
| `VanMongComponentKit` | Shared scalable panels, tabs, item slots, icons and legacy-compatible helpers |
| `CultivationPanel` | Major ink/paper modal and HUD surfaces |
| `CultivationMeter` | Health, qi, cooldown and progress with label/shape cues |
| `CultivationChoiceButton` | Breakthrough folio with protected text and selected state |
| `CultivationActionButton` | Compact combat/result actions |
| `MobileTouchControls` | Device-safe joystick, pulse and pause zones |

Primary runtime resources:

- `res://scripts/ui/frontend.gd`
- `res://scripts/ui/hud.gd`
- `res://scripts/ui/ritual_surface.gd`
- `res://scripts/ui/raster_button.gd`
- `res://scripts/ui/van_mong_component_kit.gd`
- `res://scripts/ui/mobile_touch_controls.gd`
- `res://resources/ui/cultivation_theme.tres`
- `res://assets/fonts/BeVietnamPro-Regular.ttf`
- `res://assets/fonts/BeVietnamPro-SemiBold.ttf`
- `res://assets/fonts/Literata-Variable.ttf`

## Interaction And Focus

- Every action remains a native `BaseButton` with visible non-color focus,
  hover, pressed, disabled and destructive treatment.
- Keyboard and controller focus are deterministic; each screen/modal has a
  first action and an escape/recovery path.
- Gameplay actions remain centralized through the InputMap. Touch mirrors the
  same movement, pulse and pause actions.
- Phone buttons retain a tested minimum 64×64 logical/physical target at the
  renderer-backed 844×390 viewport.
- Critical state uses labels, icons, silhouette and border treatment in addition
  to functional color.

## Responsive Contract

- Desktop authoring canvas: 1600×900; validated at 1280×720 and 2100×900.
- Phone landscape: native 844×390 device-space composition with 44 px horizontal
  and 18 px vertical meta inset.
- Platform safe area is authoritative for touch combat. Joystick, attack and
  pause remain disjoint and outside the central lane.
- Background art is aspect-preserved. Phone layouts may extend ink fields but
  cannot crop away the focal subject or stretch UI chrome.
- Portrait orientation blocks combat input and requests landscape rotation.

## Typography And Content

- Desktop body copy targets 17–19 px; major headings 30–46 px.
- Phone body copy targets 15–16 px where retained; actions keep protected live
  captions and optional prose is removed first.
- Text never collides with a frame, seal, icon or button. Result copy owns a
  dedicated field above the action row.
- Unsupported decorative diamonds/chevrons are not used as runtime font glyphs;
  served Chromium captures confirm clean Vietnamese rendering.

## Motion And Feedback

- Screen changes use short ritual fades/reveals; reduced motion preserves all
  state information.
- HUD never shakes with the world layer.
- Boss warning shows a complete danger boundary, an advancing broken-brush
  timing ring and non-color rune/tick structure.
- UI audio is supplemental; all critical state remains visible.

## Accessibility Boundary

Current automation verifies focusable native actions, keyboard/controller
recovery, 64 px phone targets, reduced motion, screen-shake settings, non-color
state cues and visible alternatives to critical audio. Input remapping,
assistive-technology evaluation, formal physical-size checks and review by
players with relevant lived experience remain open; see
`design/accessibility/accessibility-conformance.json`.

## Final Evidence

- Desktop gallery: `production/playtests/ui-review/v4-all-desktop.png`
- Phone gallery: `production/playtests/ui-review/v4-all-phone.png`
- Independent verdict: PASS, no blocker/high finding
- Godot import/parse, runtime, frontend flow, mobile support, responsive layout
  and visual evidence smokes: PASS
- Style-lock verification: PASS
- Web export and Playwright Chromium smoke: PASS, 1/1

Physical iOS/Android, Safari/Firefox, human audio listening and manual
feel/balance remain release gates. This spec does not claim commercial release
readiness.
