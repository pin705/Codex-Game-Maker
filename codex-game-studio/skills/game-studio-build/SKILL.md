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
- `design/assets/asset-coverage.json` from `../../references/templates/asset-coverage.json`
- `design/ui/ui-ux-spec.md` from `../../references/templates/ui-ux-spec.md`
- `design/audio/audio-manifest.json` from `../../references/templates/audio-manifest.json`
- `production/evidence/player-ready.json` from `../../references/templates/player-ready-evidence.json`
- `production/quality-command-manifest.json` from `../../references/templates/quality-command-manifest.json`
- `production/reviews/visual-quality.md` from `../../references/templates/visual-quality-review.md`
- `production/reviews/audio-listening.md` from `../../references/templates/audio-listening-review.md`

Also read the concept, systems GDDs, art bible, architecture, control manifest, active session state, and existing playtest evidence.

## Scope Decision

- If the user explicitly asks for an idea, document, mockup, or prototype only, stop at that named outcome and label it accurately.
- If the user asks to make/build a game without narrowing the outcome, enter `player-ready` mode.
- If the user asks for commercial release, complete player-ready first, then route to `game-studio-commercial-release`. Do not equate player-ready with store-ready.
- Ask at most three high-impact kickoff questions. Offer an autonomous defaults path. Once the user approves autonomous/default operation, continue through small batches without repeatedly asking for routine choices.

## Player-Ready Loop

1. Define release profile, target device, core fantasy, core loop, content boundary, and quality bar.
2. Inventory every player-visible state in `game-state-matrix.json`.
3. Inventory all required art and audio in coverage manifests before bulk generation.
4. Build one representative vertical slice to test the fun hypothesis.
5. Continue beyond the slice: implement the complete bounded core loop, all required states, controls, settings, feedback, failure, victory, and restart paths.
6. Route gameplay code to `game-studio-implementation`.
7. Route visual production to the art, sprite, map, and asset-QA skills.
8. Route HUD, menus, onboarding, settings, focus, and responsive presentation to `game-studio-ui-ux`.
9. Route music, ambience, SFX, buses, and trigger integration to `game-studio-audio`.
10. Configure and execute Godot import, core-loop, and long-run commands through the shell-free quality runner.
11. Capture distinct valid runtime media and complete visual/audio reviews for every required state.
12. Route accessibility coverage to `game-studio-accessibility`.
13. Run review, asset, story, runtime, and player-ready gates.
14. Iterate on blockers and high-severity visual/playtest findings. Do not stop at the first technically working version.

Run the cross-platform final gate:

```bash
python3 ../../scripts/cgm.py player-ready --root .
```

## No-Early-Stop Rules

- One scene, one room, one arena, or one screen is not a complete game unless the agreed scope explicitly defines it as the whole experience.
- Mock, placeholder, draft, or merely generated assets do not satisfy coverage. Required assets must be integrated and visually verified in runtime.
- A title screen plus gameplay HUD is not complete UI. Cover pause, settings, onboarding/controls, failure, victory/results, and every modal required by the design.
- Default engine controls, flat gray panels, generic cards, dashboard grids, and unrelated web-app styling are not acceptable final art direction.
- Code completion is not player readiness. Require hashed command evidence, valid distinct runtime media, input, feedback, audio, readable UI, state transitions, visual/audio reviews, and a manual core-loop playtest.
- Never claim commercial readiness without a target-platform release profile and release evidence.

## Completion States

- `PROTOTYPE`: the core idea runs; coverage may be incomplete.
- `VERTICAL_SLICE`: one representative path has near-final quality; the complete player journey may be incomplete.
- `PLAYER_READY`: the bounded game is complete, coherent, integrated, and verified by `cgm.py player-ready` plus actual playtest evidence.
- `RELEASE_CANDIDATE`: player-ready plus platform build, performance, legal, packaging, and release gates.

When blocked, update `production/session-state/active.md` with the exact remaining phase and next action. Never collapse an unfinished phase into “done.”
