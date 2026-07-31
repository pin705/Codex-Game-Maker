# UI/UX Spec: Vân Mộng Tu Tiên V4.1 / V5 Corrective Art Pass

Status: implemented; current V5 corrective renderer evidence refreshed, independent visual review pending
Implementation mode: hybrid — native Godot interaction/layout with complete fixed-aspect authored command, ritual, folio, hub/ledger and HUD objects; all copy, values, focus and input remain live
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
  or custom-drawn controls. V5 complete buttons replace manually assembled caps
  and clasps; fixed-shape art is uniformly fitted and never arbitrary nine-sliced.
  Runtime text, values, focus and input remain native.
- Meta screens share one subdued sect backing. Stage paintings appear only in
  contained previews or actual combat and preserve aspect ratio.
- The hub has three unequal priorities: a cultivator-led equipped identity,
  current expedition and a compact command rail. The discipline sigil remains
  secondary to the accepted player portrait.
- Lĩnh Ngộ, Tĩnh Tâm, Phi Thăng and Đạo Tâm Tan Vỡ use four state-specific
  silhouettes. Loadout/techniques/breakthrough share illustrated school manuals,
  while Thiên Mệnh Lục is one physical open ledger rather than equal cards.
- Combat keeps compact edge islands and a low five-skill rail; the movement lane
  and boss telegraph remain visually dominant.
- Phone landscape is a dedicated 844×390 device-space layout. Optional copy is
  removed before labels are reduced; 64 px hit targets retain compact inset art
  instead of filling their entire interaction rectangle.
- Runtime Vietnamese text uses bundled Be Vietnam Pro; Literata is reserved for
  ritual headings. No generated image owns readable text.

## Required Surfaces

| State ID | Primary composition | Desktop / phone evidence |
|---|---|---|
| `title` | Key art, quiet vow plate, primary/secondary actions | `frontend/title.png`; `title-phone.png` |
| `hub` | Identity folio, expedition dossier, command rail | `frontend/hub.png`; `hub-phone.png` |
| `stages` | Sequential three-stage route with completed/current/next state and one continue action | `frontend/stages.png`; `stages-phone.png` |
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
| `results-victory` | Gold/jade summary, Ngọc/Mảnh rewards, unlocks and recovery actions | `frontend/results.png`; `results-phone.png` |
| `results-defeat` | Cinnabar summary with retained Ngọc/Mảnh progression | `frontend/results-defeat.png`; `results-defeat-phone.png` |
| `portrait-guard` | Orientation block and rotation instruction | `mobile-support/portrait-overlay.png` |

## Component System

| Component | Runtime role |
|---|---|
| `RitualSurface` | Custom-drawn clipped command/panel silhouette with ink, paper, bronze, focus, pressed and disabled states |
| `RasterButton` | Compatibility API over native V4 commands; live caption, focus and guaranteed Web marker glyph |
| `VanMongComponentKit` | Shared scalable panels, tabs, item slots, icons and legacy-compatible helpers |
| `CultivationPanel` | Major ink/paper modal and HUD surfaces |
| `CultivationMeter` | Health, qi, cooldown and progress with label/shape cues |
| `CultivationChoiceButton` | Fixed-aspect illustrated UIKIT-014 manual with protected live text and an art-fitted non-color focus bracket |
| `CultivationActionButton` | Compact combat/result actions |
| `MobileTouchControls` | Device-safe joystick, pulse and pause zones |

V4.1 authored raster families:

- `UIKIT-009-v4-structural`: major lacquer panel, paper folio, header plaque and result frame.
- `UIKIT-010-v4-controls`: fixed-aspect command caps/ornaments, tabs, inventory slot, comparison frame and meter frame.
- `UIKIT-011-v4-hud`: player plaque, timer plaque, boss crest/channel, five-skill rail and touch medallions.
- `UIKIT-012-v5-command-tabs`: complete command/tab textures inside native `BaseButton`; no cap/clasp reconstruction.
- `UIKIT-013-v5-ritual-modals`: distinct breakthrough, wide pause, victory and defeat silhouettes.
- `UIKIT-014-v5-technique-folios`: six illustrated sword, jade-body and spirit-vortex manuals.
- `UIKIT-015-v5-ledger-hub`: open achievement ledger plus unequal identity, expedition and command artifacts.
- `UIKIT-016-v5-combat-hud`: compact player/timer/skill rail and mobile medallions; generated boss channel is intentionally unused until its centered crest matches runtime layout.

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
  renderer-backed 844×390 viewport. Their authored chrome is inset 3×5 px so
  accessibility size does not become visual bulk.
- Critical state uses labels, icons, silhouette and border treatment in addition
  to functional color.

## Responsive Contract

- Desktop authoring canvas: 1600×900; validated at 1280×720 and 2100×900.
- Phone landscape: native 844×390 device-space composition with 44 px horizontal
  and 18 px vertical meta inset.
- The phone hub aspect-fits the identity dossier inside 120×164 and the
  expedition window inside 278×164, leaving a separate command rail instead of
  shrinking a desktop dashboard.
- Platform safe area is authoritative for touch combat. Joystick, attack and
  pause remain disjoint and outside the central lane. At 844×390 the joystick
  and attack ornaments render at approximately 73 px and 55 px inside larger
  138 px and 92 px hit zones; the five-skill rail is 260×58.
- Background art is aspect-preserved. Phone layouts may extend ink fields but
  cannot crop away the focal subject or stretch UI chrome.
- Portrait orientation blocks combat input and requests landscape rotation.

## Typography And Content

- Desktop body copy targets 17–19 px; major headings 30–46 px.
- Phone body copy targets 13–16 px where retained. Compact artifact captions may
  use 10–12 px only inside secondary title/action cartouches; optional prose is
  removed first and all action targets remain at least 64 px.
- Text never collides with a frame, seal, icon or button. Result copy owns a
  dedicated field above the action row.
- The 844×390 route folios reserve independent status, stage-name, threat and
  reward troughs. Full stage prose lives only in the footer so record/reward
  copy cannot rise into the threat line.
- Unsupported decorative diamonds/chevrons are not used as runtime font glyphs;
  served Chromium captures confirm clean Vietnamese rendering.

## Motion And Feedback

- Screen changes use short ritual fades/reveals; reduced motion preserves all
  state information.
- HUD never shakes with the world layer.
- Boss warnings use distinct broken-brush radial, directional-rift and summon
  seal shapes, phase banners and a visible post-cast punish window.
- Runtime skills expose explicit cast, travel and impact presentation beats.
  Sword/fork/pierce, jade ward/heal, qi collapse, cloud-step afterimage,
  phoenix blade and companion claw marks use broken arcs, brush trails, seals
  and shards rather than a shared full neon ring.
- UI audio is supplemental; all critical state remains visible.

## Accessibility Boundary

Current automation verifies focusable native actions, keyboard/controller
recovery, 64 px phone targets, reduced motion, screen-shake settings, non-color
state cues and visible alternatives to critical audio. Input remapping,
assistive-technology evaluation, formal physical-size checks and review by
players with relevant lived experience remain open; see
`design/accessibility/accessibility-conformance.json`.

## Final Evidence

- Desktop affected-surface review: `design/art/lookdev/v5/runtime-review-frontend-desktop.png` and `design/art/lookdev/v5/runtime-review-combat-desktop.png`
- Phone affected-surface review: `design/art/lookdev/v5/runtime-review-frontend-phone.png` and `design/art/lookdev/v5/runtime-review-combat-phone.png`
- Current renderer matrix: refreshed and bound; independent clean-context verdict pending
- Godot import/parse, runtime, frontend flow, mobile support, responsive layout
  and visual evidence smokes: PASS
- Style-lock verification: PASS
- Prior Web export/Chromium evidence predates the V5 corrective pass and must be
  refreshed before any player-ready claim.

Physical iOS/Android, Safari/Firefox, human audio listening and manual
feel/balance remain release gates. This spec does not claim commercial release
readiness.
