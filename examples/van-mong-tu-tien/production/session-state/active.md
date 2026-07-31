# Active Session State: Vân Mộng Tu Tiên

Updated: 2026-07-31
Current phase: V4.1 style lock with the V5 corrective UI/art pass is implemented and freshly captured on desktop/simulated phone; final clean-context visual review and external device/browser/human gates remain open.

## Implemented V5 Corrective Scope

- Every declared frontend surface uses the V4 system: title, hub, stages,
  loadout, inventory, spirit beast, techniques, rank ascension, codex,
  achievements, settings, reset confirmation, victory and defeat.
- Combat HUD, boss bar, five-skill rail, breakthrough, pause, transient banners
  and mobile touch controls use the same restrained ink/paper/bronze language.
- Shared controls remain native Godot actions, but visible buttons and tabs use
  complete fixed-aspect UIKIT-012 components. The rejected cap/clasp assembly
  path has been removed, which fixes the cross-screen optical misalignment.
- Meta screens share the subdued sect-world backing. Stage art is contained and
  aspect-preserved; phone layouts use dedicated 844×390 composition rather than
  a shrunken desktop canvas.
- Be Vietnam Pro and Literata remain project-local runtime fonts. The unsupported
  diamond/chevron markers were replaced with guaranteed Web glyphs.
- Source-backed corrective runtime art is integrated through
  `UIKIT-012-v5-command-tabs`, `UIKIT-013-v5-ritual-modals`,
  `UIKIT-014-v5-technique-folios`, `UIKIT-015-v5-ledger-hub` and
  `UIKIT-016-v5-combat-hud`; prompt provenance, transparent crops, rejected
  replacements and pipeline metadata are recorded under `assets/`.
- Phone meta surfaces use an 18 px vertical visual inset; all tested action
  targets remain at least 64 px while authored chrome is visually compact. The
  hub dossier/window are bounded to 120×164/278×164, the skill rail is 260×58,
  and joystick/attack ornaments are approximately 73/55 px inside unchanged
  138/92 px hit zones.
- Hub identity, expedition and command artifacts are intentionally unequal;
  Thiên Mệnh Lục is one physical ledger. Loadout, Công Pháp Các and in-run
  breakthrough use the six illustrated UIKIT-014 manuals with phone-specific
  short titles and optional copy removed.
- Lĩnh Ngộ, Tĩnh Tâm, Phi Thăng and Đạo Tâm Tan Vỡ use distinct complete
  silhouettes. Results and pause place native actions over the plaques already
  authored into their shrine instead of drawing another button texture on top.
- Boss telegraph geometry uses irregular broken-brush arcs, non-color timing
  structure and a complete danger boundary.

## Locked Direction

- Master board: `design/art/lookdev/v4/master-board-candidate-01.png`
- User reference: `design/art/lookdev/v4/user-commercial-ui-reference.png`
- Style version: `4.1.0`
- Style digest: `f3860c3b2de68a5241f5705b66e1c0c327c94a14ad13a99e50898f76914b6024`

## Current Verification

- Fresh affected-surface native captures are complete; the prior independent
  verdict is superseded and a clean-context review is pending.
- Review composites:
  - `design/art/lookdev/v5/runtime-review-frontend-desktop.png`
  - `design/art/lookdev/v5/runtime-review-frontend-phone.png`
  - `design/art/lookdev/v5/runtime-review-combat-desktop.png`
  - `design/art/lookdev/v5/runtime-review-combat-phone.png`
- Godot 4.6.2 import/parse: PASS.
- `smoke_runtime`, `smoke_frontend_flow`, `smoke_mobile_support` and
  `smoke_responsive_layout`: PASS after the final V5 compact/mobile-art pass.
- Visual evidence: 49 current artifacts; all declared phone BaseButtons retain a
  64 px target floor.
- Style-lock verify: PASS.
- Prior Web export/Chromium evidence predates this corrective pass; refresh is
  still required before player-ready or release-ready status.
- The plugin PowerShell asset-QA runner is unavailable in this environment;
  style-lock verification, pipeline metadata, alpha/chroma inspection, Godot
  import and native runtime evidence provide the local equivalent, with the
  formal independent visual verdict still pending.
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
