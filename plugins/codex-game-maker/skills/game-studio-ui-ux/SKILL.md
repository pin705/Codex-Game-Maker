---
name: game-studio-ui-ux
description: "Design, implement, and visually verify premium game-native UI for Godot games. Use for HUDs, title screens, pause/settings/results screens, tutorials, inventory or upgrade interfaces, controller focus, responsive layouts, accessibility, UI art direction, and game feel; especially when current UI looks like plain HTML, a generic dashboard, default engine controls, flat plastic cards, or an unfinished mock."
---

# Game Studio UI UX

Make the interface feel authored for the game world. Protect gameplay visibility while making every required action readable and reachable.

## Required Context

Read:

- `design/art/art-bible.md`
- `design/art/style-lock.json`
- `production/session-state/active.md`
- `design/game-state-matrix.json`
- `design/ui/ui-ux-spec.md`
- `docs/architecture/control-manifest.md`
- `design/assets/asset-coverage.json`
- relevant system GDDs and current runtime screenshots
- `production/reviews/visual-quality-contract.json`

Create `design/ui/ui-ux-spec.md` from `../../references/templates/ui-ux-spec.md` if absent. Choose and justify `godot-theme`, `diegetic`, `custom-draw`, `hybrid`, or `intentionally-minimal`; reference real project-local implementation resources. A prose-only style description cannot pass player-ready.
Run `python3 ../../scripts/cgm.py style-lock verify --root .` before implementing production surfaces. Record the current style version and digest in the UI spec; do not silently restyle a later screen or component family.
Route full barrier/conformance testing to `game-studio-accessibility`; UI focus and contrast alone do not constitute a complete accessibility pass.

## Visual Direction Contract

- Derive shape language, materials, palette, typography, icon style, borders, depth, motion, and feedback from the art bible.
- Build reusable presentation resources appropriate to the chosen mode: Godot `Theme`, diegetic scenes, custom draw/shader resources, or a deliberate hybrid. Avoid per-surface styling drift.
- Prefer engine-native `Control` composition, anchors, containers, `StyleBox` resources, nine-slice assets, custom drawing, restrained shaders, and authored texture/icon layers.
- Reject default gray panels, generic rounded SaaS cards, dashboard grids, neon gradients without narrative purpose, and stock web-form layouts as final presentation.
- Use generated or authored decorative assets only when they improve identity and remain legible. Do not skin weak hierarchy with ornament.
- Prove hierarchy first with an unskinned layout/wireframe, then apply authored materials. Ornament cannot repair weak composition, cramped copy or equal-weight cards.
- Generate scalable panels/buttons as dedicated components. Use `NinePatchRect` only with verified patch margins and a tested size range; do not nine-slice arbitrary prop-pack crops. Preserve aspect ratio for icons and fixed-shape controls, and document intentional cover crops.
- Keep text runtime-rendered in a protected content rect. Test the longest localized copy, font fallback and text scale so labels never collide with seals, borders, icons or adjacent controls.
- Avoid reusing one ornate frame for navigation, HUD, cards, headers and results. A component family should share materials while varying silhouette and density according to hierarchy.

## Required Surface Pass

Implement and capture every state marked `ui_surface` in the game-specific state graph. The screen inventory must use the exact state IDs. Derive navigation, guidance, configuration, interruption, results, inventory, dialogue, confirmation, diegetic, and accessibility surfaces from the GDD; conventional screens are neither automatically required nor automatically optional.

## Interaction Standards

- Design controller-first focus order, a visible non-color-only focus state, and an escape path from every menu.
- Resolve button prompts from input actions and the active device; never hardcode “Press A/Space” as final UI.
- Keep static critical UI inside a 90% title-safe region and action UI inside a 93% action-safe region.
- Use anchors, containers, and scale rules; validate at 1280x720 and 1920x1080 plus the actual target device/aspect.
- Keep body text at least 16 px at 1080p and critical text at least 24 px, scaled for viewing distance.
- Encode meaning with icon/shape/text as well as color.
- Keep critical HUD readable under motion with outline, shadow, or a controlled contrast panel.
- Provide reduced-motion behavior and avoid shaking the UI layer.
- Use motion to explain state changes; prefer fast, restrained transitions over decorative bouncing.

## Visual QA Loop

1. Capture every declared `ui_surface`, the busiest visual state, each modal/overlay, and every required target viewport.
2. Run a project-owned visual/layout smoke command that produces and binds those current captures.
3. Inspect the pixels at full frame and actual display scale; review hierarchy, art-bible and cross-asset coherence, gameplay obstruction, scale, clipping, overlap, safe zones, text contrast, focus, input prompts and texture distortion.
4. Reject “technically present” UI that still resembles generic HTML/dashboard composition, or ornate UI whose text, frame and content fight each other.
5. Fix blocker/high findings and recapture the affected states.
6. Have a human or clean-context independent agent review the final captures; the agent that authored the surfaces cannot self-certify final visual PASS. Complete both `production/reviews/visual-quality-contract.json` from `../../references/templates/visual-quality-contract.json` and the concise human review from `../../references/templates/visual-quality-review.md`. Every state × viewport capture is hash-bound; every check is `PASS` or justified `NOT_APPLICABLE`; every high/blocker is resolved.
7. Record evidence paths in `design/game-state-matrix.json` and `production/evidence/player-ready.json`.

Do not mark UI complete from scene-tree inspection alone. Require runtime captures and controller/keyboard navigation evidence.
