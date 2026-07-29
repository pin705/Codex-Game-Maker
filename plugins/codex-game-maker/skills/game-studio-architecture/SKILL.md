---
name: game-studio-architecture
description: "Plan the technical architecture for a Godot-first game project. Use for engine setup, Godot version and Web export decisions, ADRs, scene/resource structure, control manifests, and technical risk reviews. Always detect existing engine files first and use official web documentation when version/API/export details are uncertain."
---

# Game Studio Architecture

Use after `game-studio-design` has produced at least a concept and initial systems list, or when an existing project needs technical organization.

## Required First Step

Detect the current engine before recommending architecture:

- Repo-local: `../../scripts/guards/detect_engine.ps1`
- Installed skill: `../../scripts/guards/detect_engine.ps1`

Rules:
- Blank project: recommend Godot 4.4 + Web export.
- Existing Godot: continue with Godot.
- Existing Unity/Unreal/Web: respect current engine unless the user asks to migrate.
- Godot CLI is strongly recommended. If missing, guide the user to install Godot 4.4 or provide the full executable path; do not create a non-Godot web fallback.

## Required Context

Read if present:
- `design/gdd/game-concept.md`
- `design/gdd/systems-index.md`
- `design/art/art-bible.md`
- `../../references/policies/collaboration-policy.md` or `../../references/policies/collaboration-policy.md`
- `../../references/policies/engine-selection.md` or `../../references/policies/engine-selection.md`
- `../../references/policies/web-search-policy.md` or `../../references/policies/web-search-policy.md`
- `../../references/rules/godot-code.md` or `../../references/rules/godot-code.md`
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

For new projects, target Godot 4.4. If the local Godot CLI is missing or not 4.4:
- Warn, but continue with docs and source generation.
- Tell the user how to run `../../tools/install-godot.ps1 -WithExportTemplates` or open the project manually in Godot 4.4.
- Ask for the Godot executable path if they want Codex to run validation/export.
- Avoid claiming export/runtime verification was completed.

## Outputs

Common outputs:
- `docs/architecture/architecture.md`
- `docs/architecture/adr-0001-[decision].md`
- `docs/architecture/control-manifest.md`
- `docs/architecture/godot-web-export-notes.md`
- `production/stories/STORY-[id]-[slug].md` for the next implementation slice when the user is ready to build.

Use templates:
- `../../references/templates/architecture.md`
- `../../references/templates/adr.md`
- `../../references/templates/control-manifest.md`

## Architecture Workflow

1. Detect engine and summarize evidence.
2. If blank, recommend Godot 4.4 + Web export and explain why.
3. Map systems to Godot scene/resource/autoload boundaries.
4. Identify technical risks:
   - Web export constraints
   - save/load
   - input remapping
   - explicit gameplay input actions and Web canvas focus
   - asset import settings
   - renderer/shader assumptions
   - performance budget
5. Create or update `docs/architecture/architecture.md`.
6. Create ADRs only for decisions that matter.
7. Create `control-manifest.md` with concrete implementation rules.
   - Gameplay code must use project-specific actions like `move_left`, `move_right`, `jump`, and `restart`; do not rely on Godot default `ui_*` actions.
   - If visible control text mentions WASD, arrows, Space, R, Esc, gamepad, or touch controls, those inputs must be explicitly bound and browser-verified.
8. Before implementing gameplay code, create one small story from `../../references/templates/implementation-story.md`.
9. Run `../../tools/check-story-gate.ps1 -Mode Ready` for the story.
10. Run `../../tools/check-godot-lint.ps1 -Root .` after Godot code changes.
11. If Godot export is unavailable, report exactly what is missing and how to install/configure Godot 4.4.
12. For browser preview, prefer `../../tools/preview-godot-web.ps1 -Project .` after Godot CLI/templates are available.
13. Update production/session-state/active.md.

Do not create a new Godot project or implementation files from a one-line idea before the kickoff/defaults have been confirmed.

## Lean Review Lens

Apply the six core roles:
- Creative: does architecture preserve the intended feel?
- Game Design: do technical boundaries support the core systems?
- Art: does the asset pipeline support the art bible?
- Technical: are Godot/Web risks explicit and verified?
- Production: is the implementation sequence realistic?
- QA: are technical decisions testable?
