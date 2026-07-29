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
- `../../references/contracts/player-journey-schema.md`
- `design/gdd/systems-index.md` and relevant system GDDs
- `docs/architecture/architecture.md`
- `docs/architecture/control-manifest.md`
- `design/assets/asset-coverage.json`
- `design/art/style-lock.json`
- `design/ui/ui-ux-spec.md`
- `design/audio/audio-manifest.json`
- current story and active session state
- `../../references/rules/godot-code.md`
- `production/quality-command-manifest.json`
- `production/reviews/visual-quality-contract.json`

## Implementation Loop

1. Create or select one small implementation story with player value and testable acceptance criteria.
2. Verify the style lock and active-session digest before touching any player-visible surface; stop if the task is continuing from stale style context.
3. Identify the complete runtime path: input -> state/rules -> presentation -> audio/UI feedback -> terminal or persistent result.
4. Implement engine-native scenes, scripts, resources, and signals with explicit ownership.
5. Keep tuning in resources/data instead of scattering constants through node scripts.
6. Integrate accepted runtime assets using their declared presentation usages: preserve uniform aspect, use only tested dedicated nine-slices, respect crop-safe/tile/frame contracts, and retain fallbacks only for resilience rather than intended final presentation.
7. Add or update a headless test under `tests/` for the changed core path.
8. Configure argv-only commands for Godot import/parse and focused tests, then run them through `python3 ../../scripts/cgm.py quality --root .`. `godot_import` must invoke `{godot}`; shell snippets, no-op commands, empty logs, unsupported Godot probes, stale command hashes, and external evidence paths are rejected.
9. Run the scene or build at every affected required viewport, capture evidence for the player-visible result, and update the structured visual contract without hiding open high/blocker findings.
10. Mark the story done only after acceptance criteria and evidence pass.
11. Update game-state and asset coverage statuses after integration.

## Required Runtime Coverage

Implement the schema-v2 graph in `design/game-state-matrix.json`, not a fixed genre-agnostic checklist:

- every required state and declared transition
- every required journey from its start to at least one completion state
- every declared recovery/retry/continue/return/save-exit path
- every experience requirement mapped to real fulfilling states and evidence
- every journey and recovery path backed by its declared executable command
- deterministic cleanup across transitions that reset, unload, reconnect, or resume mutable state

Derive guidance, configuration, interruption, persistence, failure, success, hub, narrative, and live-session behavior from the GDD and target platform. Include only what applies, but record material exclusions with rationale.

## Godot Quality Rules

- Keep gameplay state out of UI scripts; communicate through signals or narrow interfaces.
- Define explicit input actions and resolve displayed prompts from current bindings.
- Use a state machine for modal/terminal states; freeze all mutable clocks consistently.
- Keep scenes composable and dependencies explicit. Avoid giant main scripts and fragile absolute node paths.
- Provide graceful missing-asset behavior, but block player-ready while required coverage still depends on it.
- Treat warnings, runtime errors, missing `res://` paths, and unhandled state transitions as blockers.

## Definition Of Done

A feature is done only when code, visuals, audio/UI feedback, input, executable tests, hashed logs, and runtime evidence agree. “The script exists” or “the scene opens” is insufficient.
