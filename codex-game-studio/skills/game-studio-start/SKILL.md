---
name: game-studio-start
description: "Start or audit a game project with Codex Game Maker. Use when the user wants to begin a new game, organize an existing game project, detect the current engine/stage, choose an engine, or get the next recommended workflow step. Godot-first: detect existing engine files before recommending anything; for empty projects recommend Godot 4.4 with Web export."
---

# Game Studio Start

Use this as the entry point for Codex Game Maker.

## Collaboration Rule

Before creating files or implementing a game from a broad request, follow the collaboration policy:
- repo-local `codex-game-studio/references/policies/collaboration-policy.md`
- installed-skill `references/policies/collaboration-policy.md`
- repo-local `codex-game-studio/references/templates/kickoff-brief.md`
- installed-skill `references/templates/kickoff-brief.md`

For a vague request like "make a platformer", produce a lean kickoff brief, ask at most 3 high-impact questions, and offer "go with defaults". Do not silently create a full project unless the user explicitly accepts defaults or asks for no questions.

## Required First Step

Run or mentally follow the engine detector before recommending an engine:
- repo-local `codex-game-studio/scripts/guards/detect_engine.ps1`
- installed-skill `scripts/guards/detect_engine.ps1`

Engine decision rules:
- If `project.godot` or `.godot/` exists, treat the project as Godot.
- If Unity or Unreal project files exist, respect the existing engine.
- If a web stack exists, respect it, but do not recommend Phaser, Three.js, or PixiJS unless the user asks for pure web tech.
- If the project is blank, recommend Godot 4.4 + Web export.
- Godot CLI is optional for design work, but recommended for validation/export. If it is missing, guide the user to run `tools/install-godot.ps1` from the Codex Game Maker root. The tool auto-detects Windows/macOS/Linux; on macOS/Linux, run it with `pwsh -File tools/install-godot.ps1`.
- If engine version, plugin compatibility, export behavior, or API usage is uncertain, use web search and prioritize official docs.

## Stage Detection

Check these artifacts:
- `design/gdd/game-concept.md`
- `design/gdd/systems-index.md`
- `design/art/art-bible.md`
- `docs/architecture/adr-*.md`
- `production/epics/**`
- `src/**`
- engine files detected by the guard script

Report:
- Detected engine
- Detected stage: Blank, Concept, Systems Design, Technical Setup, Pre-Production, Production, Polish, Release
- Missing highest-value artifact
- Single recommended next skill

## Default Recommendations

Blank project:
1. Recommend Godot 4.4 + Web export.
2. Run the lean kickoff before writing files.
3. Start with `game-studio-design` for concept and systems.
4. Then use `game-studio-art-assets` for art bible and first generated assets.

Existing project:
1. Do not overwrite existing structure.
2. Identify the engine from files.
3. Suggest the smallest useful adoption step, usually creating missing design docs or an art bible.

## Web Search Triggers

Use web search when:
- The user says generated resources are unsatisfactory.
- The user needs many assets or references and online sourcing would reduce waste.
- The engine version appears newer or mismatched with local knowledge.
- Godot export, plugin, API, renderer, shader, mobile, or web deployment details are uncertain.
- There is a specific bug/error message from the engine.

For engine questions, use official documentation first.



