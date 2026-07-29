---
name: game-studio-architecture
description: "Plan commercial-grade technical architecture for a Godot-first game project. Use for supported engine/version policy, target platforms, export/build matrices, CI quality commands, scene/resource boundaries, controls, save migration, performance budgets, online/data boundaries, and technical risk reviews."
---

# Game Studio Architecture

Use after `game-studio-design` has produced at least a concept and initial systems list, or when an existing project needs technical organization.

## Required First Step

Detect the current engine before recommending architecture:

- Repo-local: `../../scripts/guards/detect_engine.ps1`
- Installed skill: `../../scripts/guards/detect_engine.ps1`

Rules:
- Blank project: use the recommended stable patch in `../../references/policies/godot-version-policy.json` and declare actual release targets.
- Existing Godot: continue with Godot.
- Existing Unity/Unreal/Web: respect current engine unless the user asks to migrate.
- Godot CLI is required for runtime/build verification. Install it cross-platform with `python3 ../../scripts/cgm.py install-godot --with-export-templates` or record an existing executable.

## Required Context

Read if present:
- `design/gdd/game-concept.md`
- `design/gdd/systems-index.md`
- `design/art/art-bible.md`
- `../../references/policies/collaboration-policy.md` or `../../references/policies/collaboration-policy.md`
- `../../references/policies/engine-selection.md` or `../../references/policies/engine-selection.md`
- `../../references/policies/web-search-policy.md` or `../../references/policies/web-search-policy.md`
- `../../references/rules/godot-code.md` or `../../references/rules/godot-code.md`
- `../../references/policies/godot-version-policy.json`
- `production/commercial-release-contract.json`
- `production/quality-command-manifest.json`
- `production/build-matrix.json`
- `docs/architecture/architecture.md`
- `docs/architecture/adr-*.md`

## Web Search Requirement

Use web search and prioritize official docs when:
- Godot version, API, renderer, export preset, input, filesystem, audio, or shader details matter.
- The user reports a build/export/import/runtime error.
- Existing code references APIs that may have changed.
- A plugin or asset pipeline decision depends on compatibility.

Do not invent Godot API details when official docs can be checked.

## Godot Version Requirement

For new projects, use the recommended supported patch from the version policy. If the local Godot CLI is missing, EOL, or outside a fully supported line:
- Warn, but continue with docs and source generation.
- Run or provide `python3 ../../scripts/cgm.py install-godot --with-export-templates`.
- Ask for the Godot executable path if they want Codex to run validation/export.
- Avoid claiming export/runtime verification was completed.
- Require an approved migration plan before commercial release from an EOL engine line.

## Outputs

Common outputs:
- `docs/architecture/architecture.md`
- `docs/architecture/adr-0001-[decision].md`
- `docs/architecture/control-manifest.md`
- `docs/architecture/godot-web-export-notes.md`
- `production/quality-command-manifest.json`
- `production/build-matrix.json` when commercial targets are declared
- `production/stories/STORY-[id]-[slug].md` for the next implementation slice when the user is ready to build.

Use templates:
- `../../references/templates/architecture.md`
- `../../references/templates/adr.md`
- `../../references/templates/control-manifest.md`

## Architecture Workflow

1. Detect engine and summarize evidence.
2. If blank, choose the supported engine patch and declared release targets; explain compatibility and maintenance assumptions.
3. Map systems to Godot scene/resource/autoload boundaries.
4. Identify technical risks:
   - Web export constraints
   - save/load
   - input remapping
   - explicit gameplay input actions and Web canvas focus
   - asset import settings
   - renderer/shader assumptions
   - performance budget
   - CI/build reproducibility, signing, store SDKs, secrets, telemetry, privacy, and rollback
5. Create or update `docs/architecture/architecture.md`.
6. Create ADRs only for decisions that matter.
7. Create `control-manifest.md` with concrete implementation rules.
   - Gameplay code must use project-specific actions like `move_left`, `move_right`, `jump`, and `restart`; do not rely on Godot default `ui_*` actions.
   - If visible control text mentions WASD, arrows, Space, R, Esc, gamepad, or touch controls, those inputs must be explicitly bound and browser-verified.
8. Before implementing gameplay code, create one small story from `../../references/templates/implementation-story.md`.
9. Configure executable argv arrays in `production/quality-command-manifest.json`; never use shell strings or record secrets.
10. Run `python3 ../../scripts/cgm.py quality --root .` after implementation changes.
11. If export is unavailable, report the missing engine/template/preset/credential explicitly.
12. Export declared presets cross-platform with `python3 ../../scripts/cgm.py export --root . --preset <name> --output <path>`.
13. Route commercial platform work to `game-studio-platforms` and online/data work to `game-studio-online-services`.
14. Update production/session-state/active.md.

Do not create a new Godot project or implementation files from a one-line idea before the kickoff/defaults have been confirmed.

## Lean Review Lens

Apply the six core roles:
- Creative: does architecture preserve the intended feel?
- Game Design: do technical boundaries support the core systems?
- Art: does the asset pipeline support the art bible?
- Technical: are Godot/Web risks explicit and verified?
- Production: is the implementation sequence realistic?
- QA: are technical decisions testable?
