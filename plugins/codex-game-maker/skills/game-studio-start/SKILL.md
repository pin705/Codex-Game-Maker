---
name: game-studio-start
description: "Start, route, or audit a game project with Codex Game Maker. Use when the user wants to begin, build, finish, sell, or release a game; organize an existing project; detect engine/stage/readiness; or choose the next workflow. Broad build requests route to player-ready, while commercial/store/launch requests route through the strict commercial release workflow."
---

# Game Studio Start

Use this as the entry point for Codex Game Maker.

## Collaboration Rule

Before creating files or implementing a game from a broad request, follow the collaboration policy:
- repo-local `../../references/policies/collaboration-policy.md`
- installed-skill `../../references/policies/collaboration-policy.md`
- repo-local `../../references/templates/kickoff-brief.md`
- installed-skill `../../references/templates/kickoff-brief.md`
- `../../references/contracts/player-journey-schema.md` for player-ready scope audits

For a new project, blank folder, broad idea, or request that touches multiple systems/assets/workflows, enter a planning handshake before writing files. If the Codex host offers true Plan mode, use it; otherwise simulate it in chat with the kickoff brief. Ask at most 3 high-impact questions and offer `go with defaults`. Do not silently create a full project unless the user explicitly accepts defaults, answers the brief, or asks for autonomous execution.

When the user asks for autonomous execution, accepts defaults, or says to make/build/finish the game, route to `game-studio-build` and continue through its bounded player-ready loop. If the request includes selling, store launch, commercial release, gold master, or shipping to customers, continue with `game-studio-commercial-release`. Do not repeatedly pause for routine choices after autonomous execution has been approved; pause only for scope/brand decisions, credentials, external approvals, legal decisions, or irreversible publication.

Codex Game Maker cannot force the host session context window from repo files. When the host supports it, prefer the largest available context window, with 1M tokens as the recommended target for long-running game projects. When it is unavailable, keep continuity through `production/session-state/active.md`, planning docs, manifests, and brief implementation summaries.

On every fresh task, read `design/art/style-lock.json` and `production/session-state/active.md` before visual, UI, audio, or content work. Run `python3 ../../scripts/cgm.py style-lock verify --root .`; stop production generation when the stored digest is missing or stale. A requested style change must bump `style_version`, record change control, reseal the lock, and migrate affected families explicitly.

## Required First Step

Run or mentally follow the engine detector before recommending an engine:
- repo-local `../../scripts/guards/detect_engine.ps1`
- installed-skill `../../scripts/guards/detect_engine.ps1`

Engine decision rules:
- If `project.godot` or `.godot/` exists, treat the project as Godot.
- If Unity or Unreal project files exist, respect the existing engine.
- If a web stack exists, respect it, but do not recommend Phaser, Three.js, or PixiJS unless the user asks for pure web tech.
- If the project is blank, recommend Godot 4.6.2 + Web export.
- Godot CLI is optional for design work but required for verified builds. Read `../../references/policies/godot-version-policy.json`; install the recommended supported version with `python3 ../../scripts/cgm.py install-godot --with-export-templates` when missing.
- If engine version, plugin compatibility, export behavior, or API usage is uncertain, use web search and prioritize official docs.

## Stage Detection

Check these artifacts:
- `design/gdd/game-concept.md`
- `design/gdd/systems-index.md`
- `design/art/art-bible.md`
- `design/art/style-lock.json`
- `production/session-state/active.md`
- `production/player-ready-contract.md`
- `design/game-state-matrix.json`
- `design/assets/asset-coverage.json`
- `design/ui/ui-ux-spec.md`
- `design/audio/audio-manifest.json`
- `production/evidence/player-ready.json`
- `production/reviews/visual-quality-contract.json`
- `production/commercial-release-contract.json`
- `production/build-matrix.json`
- `production/compliance-manifest.json`
- `production/performance-budget.json`
- `marketing/store-manifest.json`
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

Never infer `PLAYER_READY` from scene count, screenshots, code volume, or a booting build. That state requires the player-ready contract, complete state/asset/UI/audio coverage, locked look-dev and structured visual QA, automated checks, runtime captures, and a manual playtest.

## Request Routing

- Idea, concept, GDD, or brainstorming only -> `game-studio-design`.
- One explicitly requested prototype or technical experiment -> the relevant design/architecture/implementation skill, labeled `PROTOTYPE`.
- Make, build, complete, polish, finish, or autonomously create a game -> `game-studio-build`.
- Gameplay/runtime implementation -> `game-studio-implementation`.
- HUD, menus, controls presentation, or generic-looking UI -> `game-studio-ui-ux`.
- Music, SFX, ambience, mixing, or silent gameplay -> `game-studio-audio`.
- QA, readiness, regression, or release review -> `game-studio-review`.
- Market, pricing, scope economics, or monetization -> `game-studio-business`.
- Store/platform build, signing, packaging, or CI -> `game-studio-platforms`.
- Privacy, licensing, ratings, terms, or data declarations -> `game-studio-compliance`.
- Commercial/store/launch/gold-master request -> `game-studio-commercial-release`.

## Default Recommendations

Blank project:
1. Recommend the current supported version from `godot-version-policy.json` and declare target platforms; do not assume Web is the commercial target.
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
