---
name: game-studio-implementation
description: "Implement and verify complete Godot gameplay slices and player-facing systems. Use when creating or changing scenes, GDScript, resources, state machines, controls, save/load, gameplay systems, progression, enemies, levels, menus wired to runtime state, or automated Godot tests; especially when a project must advance beyond a mock or one-screen prototype."
---

# Game Studio Implementation

Implement the smallest complete player-visible slice, then continue story by story until the agreed game-state and system matrices are complete.

## Required Context

Read:

- `production/player-ready-contract.md`
- `design/game-state-matrix.json`
- `design/gdd/systems-index.md` and relevant system GDDs
- `docs/architecture/architecture.md`
- `docs/architecture/control-manifest.md`
- `design/assets/asset-coverage.json`
- `design/ui/ui-ux-spec.md`
- `design/audio/audio-manifest.json`
- current story and active session state
- `../../references/rules/godot-code.md`

## Implementation Loop

1. Create or select one small implementation story with player value and testable acceptance criteria.
2. Identify the complete runtime path: input -> state/rules -> presentation -> audio/UI feedback -> terminal or persistent result.
3. Implement engine-native scenes, scripts, resources, and signals with explicit ownership.
4. Keep tuning in resources/data instead of scattering constants through node scripts.
5. Integrate accepted runtime assets; retain fallbacks only for resilience, not as the intended final presentation.
6. Add or update a headless test under `tests/` for the changed core path.
7. Run Godot import/parse, the focused headless test, and lint checks.
8. Run the scene or build and capture evidence for the player-visible result.
9. Mark the story done only after acceptance criteria and evidence pass.
10. Update game-state and asset coverage statuses after integration.

## Required Runtime Coverage

Unless the contract explicitly excludes them, implement:

- boot/title/start
- onboarding or discoverable controls
- complete core gameplay loop
- pause/resume
- settings with persisted audio/display/input preferences
- failure and recovery/restart
- victory/results and replay/continue
- save/load and versioning when progress outlives a session
- deterministic cleanup when changing states or restarting

## Godot Quality Rules

- Keep gameplay state out of UI scripts; communicate through signals or narrow interfaces.
- Define explicit input actions and resolve displayed prompts from current bindings.
- Use a state machine for modal/terminal states; freeze all mutable clocks consistently.
- Keep scenes composable and dependencies explicit. Avoid giant main scripts and fragile absolute node paths.
- Provide graceful missing-asset behavior, but block player-ready while required coverage still depends on it.
- Treat warnings, runtime errors, missing `res://` paths, and unhandled state transitions as blockers.

## Definition Of Done

A feature is done only when code, visuals, audio/UI feedback, input, tests, and runtime evidence agree. “The script exists” or “the scene opens” is insufficient.
