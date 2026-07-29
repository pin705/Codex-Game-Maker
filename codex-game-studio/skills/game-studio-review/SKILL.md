---
name: game-studio-review
description: "Review a game project with Codex Game Maker. Use for prototype, vertical-slice, player-ready, MVP, or release review; QA gates; playtests; visual/UI/audio quality; smoke checks; bug-risk triage; and evidence-backed reports. One-screen builds, mock assets, generic UI, incomplete player journeys, and unsupported readiness claims are blockers for player-ready work."
---

# Game Studio Review

Use this after a concept, architecture pass, prototype, MVP, or release candidate needs a reality check.

## Required First Step

Run or mentally follow the review gate before making claims:
- repo-local `../../scripts/guards/review_gate.ps1`
- installed-skill `../../scripts/guards/review_gate.ps1`
- repo wrapper `../../../tools/check-review-gate.ps1`

Also detect the current engine:
- repo-local `../../scripts/guards/detect_engine.ps1`
- installed-skill `../../scripts/guards/detect_engine.ps1`

Do not claim the game was tested, exported, or playable unless there is evidence from a command, editor run, browser run, screenshot, playtest note, or user confirmation.

If `production/player-ready-contract.md` exists, run the cross-platform player-ready gate before classifying completion:

```bash
python3 ../../scripts/guards/player_ready_gate.py --root .
```

## Context To Read

Read if present:
- `design/gdd/game-concept.md`
- `design/gdd/systems-index.md`
- `design/gdd/systems/*.md`
- `design/art/art-bible.md`
- `design/assets/asset-manifest.yaml`
- `design/assets/asset-coverage.json`
- `design/game-state-matrix.json`
- `design/ui/ui-ux-spec.md`
- `design/audio/audio-manifest.json`
- `production/player-ready-contract.md`
- `production/evidence/player-ready.json`
- `docs/architecture/architecture.md`
- `docs/architecture/control-manifest.md`
- `docs/architecture/adr-*.md`
- `production/playtests/*.md`
- `production/reviews/*.md`
- `production/stories/*.md`
- `production/epics/*.md`
- `production/sprints/*.md`
- `production/smoke-tests/*.md`
- `production/regression/*.md`
- `production/releases/*.md`
- `CHANGELOG.md`
- `assets/generated/**`
- `assets/source-prompts/**`
- `assets/generated/**/pipeline-meta.json`
- `design/assets/godot-import-manifest.yaml`
- `design/scene-scale-plan.yaml`
- `design/assets/scene-scale-plan.yaml`
- `README.md`
- engine files detected by the guard scripts

Use templates:
- `../../references/templates/review-report.md` or installed `../../references/templates/review-report.md`
- `../../references/templates/playtest-evidence.md` or installed `../../references/templates/playtest-evidence.md`
- `../../references/templates/player-ready-contract.md` or installed `../../references/templates/player-ready-contract.md`
- `../../references/templates/player-ready-evidence.json` or installed `../../references/templates/player-ready-evidence.json`
- `../../references/templates/implementation-story.md` or installed `../../references/templates/implementation-story.md`
- `../../references/templates/epic.md` or installed `../../references/templates/epic.md`
- `../../references/templates/sprint-plan.md` or installed `../../references/templates/sprint-plan.md`
- `../../references/templates/smoke-test.md` or installed `../../references/templates/smoke-test.md`
- `../../references/templates/regression-checklist.md` or installed `../../references/templates/regression-checklist.md`
- `../../references/templates/playable-showcase-qa.md` or installed `../../references/templates/playable-showcase-qa.md`
- `../../references/templates/release-checklist.md` or installed `../../references/templates/release-checklist.md`
- `../../references/templates/changelog.md` or installed `../../references/templates/changelog.md`
- `../../references/templates/patch-notes.md` or installed `../../references/templates/patch-notes.md`
- `../../references/templates/hotfix-report.md` or installed `../../references/templates/hotfix-report.md`
- `../../references/commands/catalog.yaml` for explicit professional-mode aliases.
- `../../references/rules/playable-showcase-integration.md` for generated-asset playable demo checks.

## Review Workflow

1. Run engine detection and review gate checks.
2. If implementation work is requested, require a small story under `production/stories/` and run `../../../tools/check-story-gate.ps1 -Mode Ready`.
3. If a story is being closed, run `../../../tools/check-story-gate.ps1 -Mode Done`.
4. If generated assets exist or an art pass is being reviewed, run `../../../tools/check-asset-gate.ps1 -Root .`.
5. If accepted runtime assets exist, run `../../../tools/check-asset-qa.ps1 -Root .`.
6. Run `../../../tools/check-godot-lint.ps1 -Root .` for Godot projects with code changes.
7. For generated-asset playable showcases, check the scene scale plan and `playable-showcase-qa.md` evidence.
8. Run `../../../tools/check-production-gate.ps1 -Root .` when epics/sprints exist.
9. Run `../../../tools/check-release-gate.ps1 -Root .` only when `/release`, `/hotfix`, or release candidate review is explicitly requested.
10. If a player-ready contract exists, run `python3 ../../scripts/guards/player_ready_gate.py --root .`.
11. Summarize evidence first: what was read, what was run, what could not be verified.
12. Apply the six useful role lenses plus player-journey, UI, audio, and asset-specific QA lenses:
   - Creative: pillar/hook/fantasy coherence.
   - Game Design: rules, loop, tuning knobs, MVP boundaries, acceptance criteria.
   - Art: art bible alignment, readability, asset coverage, prompt/provenance gaps.
   - Technical: engine/version/API/export risks, scene/resource structure, error-prone code.
   - Production: scope, sequence, dependency risk, smallest useful next step.
   - QA: smoke coverage, regression risk, playtest evidence, blockers.
   - Player Journey: boot-to-title, onboarding, complete core loop, pause/settings, failure/recovery, victory/results, replay/continue, and clean restart.
   - UI/UX: art-bible coherence, hierarchy, safe zones, responsive layout, focus order, input prompts, accessibility, modal completeness, and runtime captures.
   - Audio: event coverage, buses, persisted settings, mix readability, provenance, pause/restart cleanup, and listening evidence.
   - Sprite QA: frame count, alpha, chroma-key cleanup, edge touch, GIF preview, Godot pivot/frame metadata.
   - Map/Level Asset QA: preview, separated runtime objects, collision, zones, camera bounds, Godot scene/import readiness.
   - Godot Import QA: accepted assets resolve to project files, import intent is recorded, `res://` references are valid.
   - Playable Showcase QA: scene scale, grounding on large and small platforms, state machine, all pickup instances, finish trigger, web preview.
13. Classify the gate:
   - `PASS`: no blockers, evidence covers core play path.
   - `PASS_WITH_WARNINGS`: no blockers, but missing non-critical evidence or docs.
   - `BLOCKED`: crash risk, missing playable root/main scene, broken required files, unsupported claims, incomplete player journey, one-screen-only scope outside the agreed contract, mock/placeholder required assets, generic/default UI presented as final, missing required audio, missing state captures, or no manual core-loop playtest.
14. Write or update `production/reviews/review-[YYYYMMDD-HHMM].md` when the user asks for a formal review or when preparing a release/demo.
15. Update `production/session-state/active.md` with gate result, blockers, and next step.

## Player-Ready Classification

- `PROTOTYPE`: a technical/core-loop proof; incomplete content, presentation, or state coverage is expected and explicitly reported.
- `VERTICAL_SLICE`: one representative path approaches final quality, but the full bounded journey may remain incomplete.
- `PLAYER_READY`: the complete bounded journey is coherent and integrated; all required state, asset, UI, audio, test, runtime, and manual-playtest evidence passes.
- `RELEASE_CANDIDATE`: player-ready plus target-platform build, performance, packaging, legal/licensing, and release evidence.

Never upgrade a result based only on effort or visual impression. Use the contract and evidence.

## Smoke Check Evidence

Prefer evidence in this order:
1. Automated command output.
2. Godot editor or CLI run notes.
3. Browser/Web export run notes.
4. Screenshot or short screen recording path.
5. User-confirmed manual playtest notes.

Minimum Godot MVP smoke checklist:
- Project root has `project.godot`.
- Main scene exists and is documented.
- Godot version is checked or the missing CLI is explicitly reported.
- Browser preview uses `../../../tools/preview-godot-web.ps1 -Project .` when Godot CLI/export templates are available.
- Core input path is documented.
- At least one core loop playthrough is recorded in `production/playtests/`.
- Known blockers and warnings are listed.

Minimum player-ready evidence adds:

- Runtime captures for title, gameplay, busiest action, pause, settings, victory, defeat, and every required modal.
- Complete asset coverage with accepted assets integrated into current runtime scenes.
- Keyboard and controller navigation evidence where the target supports both.
- Audio listening evidence for menu, gameplay, busiest action, pause/restart, victory, and defeat.
- Automated core-loop and long-run results plus a human/manual core-loop playtest.

Generated-asset playable showcase checklist:
- Scene scale plan exists and defines target runtime size for player, platforms, pickups, and finish.
- Player starts grounded and does not visually float or sink on large and small platforms.
- Idle is the default no-input state.
- Run/walk alternates feet and does not scale-pop.
- Jump uses phase frames for rise/apex/fall/land instead of a blind loop.
- Every repeated pickup instance animates and can be collected.
- Finish object is visibly anchored and triggers a clear state.
- Collision/debug rectangles are not visible in runtime.
- Web preview has been hard-refreshed after export so the current `.pck` is being tested.

## Story Gate

Use a story gate to prevent broad, vague implementation:
- Ready mode checks player value, goal, acceptance criteria, files to touch, and verification plan.
- Done mode also requires checked acceptance criteria and concrete evidence.
- Keep stories small enough to verify in one focused pass.
- Do not mark a story done because code was written; mark it done because acceptance criteria and evidence pass.

## Professional Mode

Treat aliases in `../../references/commands/catalog.yaml` such as `/release`, `/team-ui`, and `/audio-pass` as explicit professional-mode triggers. Do not enter these modes during the default flow.

`/release` and `/hotfix` are professional mode. Use release templates and `../../../tools/check-release-gate.ps1`.

Hooks are also professional mode. Install them only when the user explicitly asks, using `../../../tools/install-professional-hooks.ps1`.

## Web Search Requirement

Use web search and prioritize official docs when:
- Godot CLI/export commands, renderer behavior, input, web export, platform support, or API details are uncertain.
- The project uses a newer/different engine version than the local policy.
- The review concerns an engine error, export error, plugin compatibility issue, or generated asset import behavior.
- The user says generated assets or implementation results are unsatisfactory.

Record source links in the review report when they influence a finding.

## Output Style

- Lead with findings ordered by severity.
- Include file paths or evidence names.
- Separate blockers from warnings and improvements.
- Keep summaries short.
- Do not invent test results.

