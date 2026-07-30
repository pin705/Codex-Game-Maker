# Active Session State: Vân Mộng Tu Tiên

Updated: 2026-07-31
Current phase: V4 user-approved whole-game UI is implemented and passes the bounded independent desktop/simulated-phone visual gate; external device, browser, human-play and accessibility gates remain open.

## Implemented V4 Scope

- Every declared frontend surface uses the V4 system: title, hub, stages,
  loadout, inventory, spirit beast, techniques, rank ascension, codex,
  achievements, settings, reset confirmation, victory and defeat.
- Combat HUD, boss bar, five-skill rail, breakthrough, pause, transient banners
  and mobile touch controls use the same restrained ink/paper/bronze language.
- Shared controls are scalable Godot-native/custom-drawn silhouettes. Legacy
  UIKIT-006/007/008 raster chrome remains only for provenance/fallback and is no
  longer the production default.
- Meta screens share the subdued sect-world backing. Stage art is contained and
  aspect-preserved; phone layouts use dedicated 844×390 composition rather than
  a shrunken desktop canvas.
- Be Vietnam Pro and Literata remain project-local runtime fonts. The unsupported
  diamond/chevron markers were replaced with guaranteed Web glyphs.
- Phone meta surfaces use an 18 px vertical visual inset; all tested action
  targets remain at least 64 px. Touch combat controls remain in separated thumb
  zones and preserve the center lane.
- Boss telegraph geometry uses irregular broken-brush arcs, non-color timing
  structure and a complete danger boundary.

## Locked Direction

- Master board: `design/art/lookdev/v4/master-board-candidate-01.png`
- User reference: `design/art/lookdev/v4/user-commercial-ui-reference.png`
- Style version: `4.1.0`
- Style digest: `f3860c3b2de68a5241f5705b66e1c0c327c94a14ad13a99e50898f76914b6024`

## Current Verification

- Independent clean-context visual verdict: PASS; 17/17 required surfaces, no
  blocker or high finding.
- Fresh galleries:
  - `production/playtests/ui-review/v4-all-desktop.png`
  - `production/playtests/ui-review/v4-all-phone.png`
- Godot 4.6.2 import/parse: PASS.
- `smoke_runtime`, `smoke_frontend_flow`, `smoke_mobile_support`,
  `smoke_responsive_layout`, and `smoke_visual_evidence`: PASS.
- Visual evidence: 49 current artifacts; all declared phone BaseButtons retain a
  64 px target floor.
- Style-lock verify: PASS.
- Web export: PASS.
- Playwright served Chromium smoke: PASS 1/1 with no console, page or request
  errors; current Web captures contain no missing-glyph boxes.
- `git diff --check`: PASS.

## Remaining Gates

- Physical iOS/Android landscape QA: DPI, notch/home indicator, thumb reach,
  sustained multitouch, rendering and thermal behavior.
- Safari and Firefox served-Web visual/input/focus verification.
- Human listening on representative outputs and Web audio-unlock review.
- Manual four-minute feel/balance, boss-kill and death/retry sessions.
- Player-facing input remapping, assistive-technology checks and review by
  players with relevant accessibility lived experience.

Do not call the project commercial-ready or release-ready until these external
and human gates are complete.

## Important Runtime Files

- `scripts/ui/frontend.gd`
- `scripts/ui/hud.gd`
- `scripts/ui/raster_button.gd`
- `scripts/ui/ritual_surface.gd`
- `scripts/ui/van_mong_component_kit.gd`
- `scripts/ui/mobile_touch_controls.gd`
- `scripts/gameplay/enemy.gd`
- `resources/ui/cultivation_theme.tres`
