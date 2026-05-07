---
name: game-studio-review
description: "Review a game project with Codex Game Maker. Use for QA gates, playtest readiness, MVP/release review, smoke checks, bug-risk triage, six-role review lenses, and creating review reports with concrete evidence. Godot-first: detect engine files and use official docs when version/export/runtime details are uncertain."
---

# Game Studio Review

Use this after a concept, architecture pass, prototype, MVP, or release candidate needs a reality check.

## Required First Step

Run or mentally follow the review gate before making claims:
- repo-local `codex-game-studio/scripts/guards/review_gate.ps1`
- installed-skill `scripts/guards/review_gate.ps1`
- repo wrapper `tools/check-review-gate.ps1`

Also detect the current engine:
- repo-local `codex-game-studio/scripts/guards/detect_engine.ps1`
- installed-skill `scripts/guards/detect_engine.ps1`

Do not claim the game was tested, exported, or playable unless there is evidence from a command, editor run, browser run, screenshot, playtest note, or user confirmation.

## Context To Read

Read if present:
- `design/gdd/game-concept.md`
- `design/gdd/systems-index.md`
- `design/gdd/systems/*.md`
- `design/art/art-bible.md`
- `design/assets/asset-manifest.yaml`
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
- `README.md`
- engine files detected by the guard scripts

Use templates:
- `codex-game-studio/references/templates/review-report.md` or installed `references/templates/review-report.md`
- `codex-game-studio/references/templates/playtest-evidence.md` or installed `references/templates/playtest-evidence.md`
- `codex-game-studio/references/templates/implementation-story.md` or installed `references/templates/implementation-story.md`
- `codex-game-studio/references/templates/epic.md` or installed `references/templates/epic.md`
- `codex-game-studio/references/templates/sprint-plan.md` or installed `references/templates/sprint-plan.md`
- `codex-game-studio/references/templates/smoke-test.md` or installed `references/templates/smoke-test.md`
- `codex-game-studio/references/templates/regression-checklist.md` or installed `references/templates/regression-checklist.md`
- `codex-game-studio/references/templates/release-checklist.md` or installed `references/templates/release-checklist.md`
- `codex-game-studio/references/templates/changelog.md` or installed `references/templates/changelog.md`
- `codex-game-studio/references/templates/patch-notes.md` or installed `references/templates/patch-notes.md`
- `codex-game-studio/references/templates/hotfix-report.md` or installed `references/templates/hotfix-report.md`
- `codex-game-studio/references/commands/catalog.yaml` for explicit professional-mode aliases.

## Review Workflow

1. Run engine detection and review gate checks.
2. If implementation work is requested, require a small story under `production/stories/` and run `tools/check-story-gate.ps1 -Mode Ready`.
3. If a story is being closed, run `tools/check-story-gate.ps1 -Mode Done`.
4. If generated assets exist or an art pass is being reviewed, run `tools/check-asset-gate.ps1 -Root .`.
5. If accepted runtime assets exist, run `tools/check-asset-qa.ps1 -Root .`.
6. Run `tools/check-godot-lint.ps1 -Root .` for Godot projects with code changes.
7. Run `tools/check-production-gate.ps1 -Root .` when epics/sprints exist.
8. Run `tools/check-release-gate.ps1 -Root .` only when `/release`, `/hotfix`, or release candidate review is explicitly requested.
9. Summarize evidence first: what was read, what was run, what could not be verified.
10. Apply the six useful role lenses plus asset-specific QA lenses when assets are in scope:
   - Creative: pillar/hook/fantasy coherence.
   - Game Design: rules, loop, tuning knobs, MVP boundaries, acceptance criteria.
   - Art: art bible alignment, readability, asset coverage, prompt/provenance gaps.
   - Technical: engine/version/API/export risks, scene/resource structure, error-prone code.
   - Production: scope, sequence, dependency risk, smallest useful next step.
   - QA: smoke coverage, regression risk, playtest evidence, blockers.
   - Sprite QA: frame count, alpha, chroma-key cleanup, edge touch, GIF preview, Godot pivot/frame metadata.
   - Map/Level Asset QA: preview, separated runtime objects, collision, zones, camera bounds, Godot scene/import readiness.
   - Godot Import QA: accepted assets resolve to project files, import intent is recorded, `res://` references are valid.
11. Classify the gate:
   - `PASS`: no blockers, evidence covers core play path.
   - `PASS_WITH_WARNINGS`: no blockers, but missing non-critical evidence or docs.
   - `BLOCKED`: crash risk, missing playable root, missing main scene, broken required files, or unsupported claims.
12. Write or update `production/reviews/review-[YYYYMMDD-HHMM].md` when the user asks for a formal review or when preparing a release/demo.
13. Update `production/session-state/active.md` with gate result, blockers, and next step.

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
- Browser preview uses `tools/preview-godot-web.ps1 -Project .` when Godot CLI/export templates are available.
- Core input path is documented.
- At least one core loop playthrough is recorded in `production/playtests/`.
- Known blockers and warnings are listed.

## Story Gate

Use a story gate to prevent broad, vague implementation:
- Ready mode checks player value, goal, acceptance criteria, files to touch, and verification plan.
- Done mode also requires checked acceptance criteria and concrete evidence.
- Keep stories small enough to verify in one focused pass.
- Do not mark a story done because code was written; mark it done because acceptance criteria and evidence pass.

## Professional Mode

Treat aliases in `references/commands/catalog.yaml` such as `/release`, `/team-ui`, and `/audio-pass` as explicit professional-mode triggers. Do not enter these modes during the default flow.

`/release` and `/hotfix` are professional mode. Use release templates and `tools/check-release-gate.ps1`.

Hooks are also professional mode. Install them only when the user explicitly asks, using `tools/install-professional-hooks.ps1`.

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


