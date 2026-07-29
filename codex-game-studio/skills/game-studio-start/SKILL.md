---
name: game-studio-start
description: "Start, route, or audit a game project with Codex Game Maker. Use when the user wants to begin or build a game, organize an existing project, detect the current engine/stage/readiness, choose an engine, or get the next recommended workflow step. Broad make/build/finish requests route to the complete player-ready workflow instead of ending at a one-screen prototype."
---

# Game Studio Start

Use this as the entry point for Codex Game Maker.

## Collaboration Rule

Before creating files or implementing a game from a broad request, follow the collaboration policy:
- repo-local `../../references/policies/collaboration-policy.md`
- installed-skill `../../references/policies/collaboration-policy.md`
- repo-local `../../references/templates/kickoff-brief.md`
- installed-skill `../../references/templates/kickoff-brief.md`

For a new project, blank folder, broad idea, or request that touches multiple systems/assets/workflows, enter a planning handshake before writing files. If the Codex host offers true Plan mode, use it; otherwise simulate it in chat with the kickoff brief. Ask at most 3 high-impact questions and offer `go with defaults`. Do not silently create a full project unless the user explicitly accepts defaults, answers the brief, or asks for autonomous execution.

When the user asks for autonomous execution, accepts defaults, or says to make/build/finish the game, route to `game-studio-build` and continue through its bounded player-ready loop. Do not repeatedly pause for routine implementation, asset, UI, or audio choices after autonomous execution has been approved.

Codex Game Maker cannot force the host session context window from repo files. When the host supports it, prefer the largest available context window, with 1M tokens as the recommended target for long-running game projects. When it is unavailable, keep continuity through `production/session-state/active.md`, planning docs, manifests, and brief implementation summaries.

## Required First Step

Run or mentally follow the engine detector before recommending an engine:
- repo-local `../../scripts/guards/detect_engine.ps1`
- installed-skill `../../scripts/guards/detect_engine.ps1`

Engine decision rules:
- If `project.godot` or `.godot/` exists, treat the project as Godot.
- If Unity or Unreal project files exist, respect the existing engine.
- If a web stack exists, respect it, but do not recommend Phaser, Three.js, or PixiJS unless the user asks for pure web tech.
- If the project is blank, recommend Godot 4.4 + Web export.
- Godot CLI is optional for design work, but recommended for validation/export. If it is missing, guide the user to run `../../../tools/install-godot.ps1` from the Codex Game Maker root. The tool auto-detects Windows/macOS/Linux; on macOS/Linux, run it with `pwsh -File ../../../tools/install-godot.ps1`.
- If engine version, plugin compatibility, export behavior, or API usage is uncertain, use web search and prioritize official docs.

## Stage Detection

Check these artifacts:
- `design/gdd/game-concept.md`
- `design/gdd/systems-index.md`
- `design/art/art-bible.md`
- `production/player-ready-contract.md`
- `design/game-state-matrix.json`
- `design/assets/asset-coverage.json`
- `design/ui/ui-ux-spec.md`
- `design/audio/audio-manifest.json`
- `production/evidence/player-ready.json`
- `docs/architecture/adr-*.md`
- `production/epics/**`
- `src/**`
- engine files detected by the guard script

Report:
- Detected engine
- Detected stage: Blank, Concept, Systems Design, Technical Setup, Pre-Production, Production, Polish, Release
- Detected delivery state: `PROTOTYPE`, `VERTICAL_SLICE`, `PLAYER_READY`, or `RELEASE_CANDIDATE`
- Missing highest-value artifact
- Single recommended next skill

Never infer `PLAYER_READY` from scene count, screenshots, code volume, or a booting build. That state requires the player-ready contract, complete state/asset/UI/audio coverage, automated checks, runtime captures, and a manual playtest.

## Request Routing

- Idea, concept, GDD, or brainstorming only -> `game-studio-design`.
- One explicitly requested prototype or technical experiment -> the relevant design/architecture/implementation skill, labeled `PROTOTYPE`.
- Make, build, complete, polish, finish, or autonomously create a game -> `game-studio-build`.
- Gameplay/runtime implementation -> `game-studio-implementation`.
- HUD, menus, controls presentation, or generic-looking UI -> `game-studio-ui-ux`.
- Music, SFX, ambience, mixing, or silent gameplay -> `game-studio-audio`.
- QA, readiness, regression, or release review -> `game-studio-review`.

## Default Recommendations

Blank project:
1. Recommend Godot 4.4 + Web export.
2. Run the lean kickoff before writing files.
3. For a broad game-building request, route to `game-studio-build`; it will invoke design, implementation, art, UI, audio, and review in sequence.
4. For a design-only request, start with `game-studio-design` and stop at the requested artifact.

Existing project:
1. Do not overwrite existing structure.
2. Identify the engine from files.
3. Audit existing states, assets, UI, audio, tests, and evidence before choosing the smallest useful adoption step.
4. If the user asks to finish or improve the whole game, route to `game-studio-build`; never present a one-screen/mock milestone as complete.

## Prototype Boundary

A booting scene, one playable room, a few mocked assets, default controls, or a flat HUD proves only a prototype. Clearly label it, record what remains in `production/session-state/active.md`, and continue when the agreed outcome is player-ready.

## Web Search Triggers

Use web search when:
- The user says generated resources are unsatisfactory.
- The user needs many assets or references and online sourcing would reduce waste.
- The engine version appears newer or mismatched with local knowledge.
- Godot export, plugin, API, renderer, shader, mobile, or web deployment details are uncertain.
- There is a specific bug/error message from the engine.

For engine questions, use official documentation first.


