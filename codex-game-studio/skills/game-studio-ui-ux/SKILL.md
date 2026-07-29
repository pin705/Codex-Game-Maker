---
name: game-studio-ui-ux
description: "Design, implement, and visually verify premium game-native UI for Godot games. Use for HUDs, title screens, pause/settings/results screens, tutorials, inventory or upgrade interfaces, controller focus, responsive layouts, accessibility, UI art direction, and game feel; especially when current UI looks like plain HTML, a generic dashboard, default engine controls, flat plastic cards, or an unfinished mock."
---

# Game Studio UI UX

Make the interface feel authored for the game world. Protect gameplay visibility while making every required action readable and reachable.

## Required Context

Read:

- `design/art/art-bible.md`
- `design/game-state-matrix.json`
- `design/ui/ui-ux-spec.md`
- `docs/architecture/control-manifest.md`
- `design/assets/asset-coverage.json`
- relevant system GDDs and current runtime screenshots

Create `design/ui/ui-ux-spec.md` from `../../references/templates/ui-ux-spec.md` if absent.

## Visual Direction Contract

- Derive shape language, materials, palette, typography, icon style, borders, depth, motion, and feedback from the art bible.
- Build a reusable Godot `Theme`, style tokens, component scripts, and shared containers. Avoid per-screen styling drift.
- Prefer engine-native `Control` composition, anchors, containers, `StyleBox` resources, nine-slice assets, custom drawing, restrained shaders, and authored texture/icon layers.
- Reject default gray panels, generic rounded SaaS cards, dashboard grids, neon gradients without narrative purpose, and stock web-form layouts as final presentation.
- Use generated or authored decorative assets only when they improve identity and remain legible. Do not skin weak hierarchy with ornament.

## Required Surface Pass

Implement and capture every required state from the game-state matrix, including at minimum:

- title/start and first-time control guidance
- gameplay HUD and contextual prompts
- pause/resume
- settings for audio, display/UI scale, controls, and accessibility
- failure/defeat and recovery
- victory/results and replay/continue
- every modal introduced by gameplay, such as upgrades, inventory, dialogue, or confirmation

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

1. Capture title, gameplay, busiest combat, each modal, pause, settings, victory, and defeat.
2. Review hierarchy, art-bible coherence, gameplay obstruction, scale, clipping, safe zones, text contrast, focus, and input prompts.
3. Reject “technically present” UI that still resembles generic HTML/dashboard composition.
4. Fix blocker/high findings and recapture the affected states.
5. Record evidence paths in `design/game-state-matrix.json` and `production/evidence/player-ready.json`.

Do not mark UI complete from scene-tree inspection alone. Require runtime captures and controller/keyboard navigation evidence.
