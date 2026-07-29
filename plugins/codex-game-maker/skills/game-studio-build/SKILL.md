---
name: game-studio-build
description: "Build a complete Godot-first game from an idea through a player-ready candidate. Use when the user asks to make, build, finish, polish, or ship a whole game; asks Codex to work autonomously end to end; or is dissatisfied with a one-screen prototype, incomplete/mock assets, generic HUD, missing menus, weak game feel, or an unfinished player journey."
---

# Game Studio Build

Own the end-to-end player outcome. Treat a prototype as a milestone, never as the final deliverable, unless the user explicitly requests only a prototype.

## Required Files

Create these from the shared templates before broad implementation:

- `production/player-ready-contract.md` from `../../references/templates/player-ready-contract.md`
- `design/game-state-matrix.json` from `../../references/templates/game-state-matrix.json`
- `../../references/contracts/player-journey-schema.md`
- `design/assets/asset-coverage.json` from `../../references/templates/asset-coverage.json`
- `design/ui/ui-ux-spec.md` from `../../references/templates/ui-ux-spec.md`
- `design/audio/audio-manifest.json` from `../../references/templates/audio-manifest.json`
- `production/evidence/player-ready.json` from `../../references/templates/player-ready-evidence.json`
- `production/quality-command-manifest.json` from `../../references/templates/quality-command-manifest.json`
- `production/reviews/visual-quality.md` from `../../references/templates/visual-quality-review.md`
- `production/reviews/visual-quality-contract.json` from `../../references/templates/visual-quality-contract.json`
- `production/reviews/audio-listening.md` from `../../references/templates/audio-listening-review.md`

Also read the concept, systems GDDs, art bible, architecture, control manifest, active session state, and existing playtest evidence.

## Scope Decision

- If the user explicitly asks for an idea, document, mockup, or prototype only, stop at that named outcome and label it accurately.
- If the user asks to make/build a game without narrowing the outcome, enter `player-ready` mode.
- If the user asks for commercial release, complete player-ready first, then route to `game-studio-commercial-release`. Do not equate player-ready with store-ready.
- Ask at most three high-impact kickoff questions. Offer an autonomous defaults path. Once the user approves autonomous/default operation, continue through small batches without repeatedly asking for routine choices.

## Player-Ready Loop

1. Define release profile, target device, core fantasy, core loop, content boundary, and quality bar.
2. Derive a schema-v2 state graph from this game's GDD: custom state IDs, transitions, required journeys, completion conditions, recovery paths, experience requirements, and executable journey tests. Never copy a universal title/pause/victory list.
3. Derive game-specific art and audio coverage policies from the state graph, systems, UI surfaces, and target devices before bulk generation.
4. Lock a coherent look-dev direction across the visual families this game actually uses. Generated/mixed art compares multiple candidates in a runtime composite; the first plausible image is not a production style lock.
5. Build one representative vertical slice to test the fun hypothesis and presentation quality at actual runtime scale.
6. Continue beyond the slice until every state, transition, completion condition, and recovery path declared by this game's required journeys is implemented.
7. Route gameplay code to `game-studio-implementation`.
8. Route visual production to the art, sprite, map, and asset-QA skills.
9. Route every state marked `ui_surface`, plus presentation resources and interaction behavior, to `game-studio-ui-ux`.
10. Route every declared audio coverage requirement, bus, event, provenance record, and trigger to `game-studio-audio`.
11. Configure and execute the state contract's engine-import, static-analysis, reliability, journey, recovery and visual-smoke commands through the shell-free quality runner.
12. Capture distinct valid runtime media and complete structured visual/audio reviews for every required state and target viewport.
13. Route accessibility coverage to `game-studio-accessibility`.
14. Run review, asset, story, runtime, and player-ready gates.
15. Iterate on blockers and high-severity visual/playtest findings. Do not stop at the first technically working version.

Run the cross-platform final gate:

```bash
python3 ../../scripts/cgm.py player-ready --root .
```

## No-Early-Stop Rules

- One scene, one room, one arena, or one screen is not a complete game unless the agreed scope explicitly defines it as the whole experience.
- Mock, placeholder, draft, or merely generated assets do not satisfy coverage. Required assets must be integrated and visually verified in runtime.
- Do not infer completeness from conventional menu names. Complete UI means every `ui_surface` and interaction requirement declared by this game's graph is implemented and evidenced; omitted conventional surfaces need an explicit game-specific rationale.
- Default engine controls, flat gray panels, generic cards, dashboard grids, and unrelated web-app styling are not acceptable final art direction.
- Code completion is not player readiness. Require hashed command evidence, valid distinct runtime media, input, feedback, audio, readable UI, state transitions, visual/audio reviews, and a manual core-loop playtest.
- Never claim commercial readiness without a target-platform release profile and release evidence.

## Completion States

- `PROTOTYPE`: the core idea runs; coverage may be incomplete.
- `VERTICAL_SLICE`: one representative path has near-final quality; the complete player journey may be incomplete.
- `PLAYER_READY`: the bounded game is complete, coherent, integrated, and verified by `cgm.py player-ready` plus actual playtest evidence.
- `RELEASE_CANDIDATE`: player-ready plus platform build, performance, legal, packaging, and release gates.

When blocked, update `production/session-state/active.md` with the exact remaining phase and next action. Never collapse an unfinished phase into “done.”
