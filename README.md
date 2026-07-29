# Codex Game Maker

**Languages:** [English](README.md) | [简体中文](README.zh-CN.md)

![Codex Game Maker banner](assets/brand/banner.png)

**Codex skills for building complete, polished, player-ready Godot games—not just one-screen prototypes.**

**Quick links:** [Install](#quick-start) · [Player-Ready Mode](#player-ready-mode) · [Asset Pipeline](#gpt-image-2d-asset-pipeline) · [Skills](#whats-included) · [Safety Gates](#safety-and-gates) · [Prompts](#suggested-prompts)

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
![Status](https://img.shields.io/badge/status-v0.1--alpha-orange)
![Godot](https://img.shields.io/badge/Godot-4.4-blue)
![Platforms](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey)
![Assets](https://img.shields.io/badge/GPT%20Image-2D%20assets-purple)
![Tools](https://img.shields.io/badge/tools-32-blue)
![Skills](https://img.shields.io/badge/skills-12-blueviolet)
![AI Built For](https://img.shields.io/badge/AI%20built%20for-Codex-111827)

Turn a single Codex session into a Godot-first game making workspace.

Godot-first workflows. Complete gameplay states. Production assets. Game-native UI. Integrated audio. Runtime and playtest evidence.

> Status: `v0.1-alpha`. The core workflow is usable, but this is still an early preview. Use it as a template, inspect what it writes, and expect the showcase layer to evolve.

Codex Game Maker turns a Codex session into an end-to-end game-making workspace: guided design, Godot setup, complete gameplay implementation, sprite/map/UI asset production, game-native HUD and menus, controls, audio, automated checks, runtime capture, and manual playtest evidence.

## Table Of Contents

- [What Makes It Different](#what-makes-it-different)
- [Showcase Plans](#showcase-plans)
- [Player-Ready Mode](#player-ready-mode)
- [What's Included](#whats-included)
- [Engine Support](#engine-support)
- [Quick Start](#quick-start)
- [GPT Image 2D Asset Pipeline](#gpt-image-2d-asset-pipeline)
- [What It Can Generate](#what-it-can-generate)
- [What You Get](#what-you-get)
- [Professional Features](#professional-features)
- [How It Works](#how-it-works)
- [Safety And Gates](#safety-and-gates)
- [Suggested Prompts](#suggested-prompts)
- [Repository Layout](#repository-layout)

## What Makes It Different

Codex Game Maker is not just a prompt pack. It is a Codex-first game workflow where the agent plans the project, image generation creates raw assets, and deterministic local tools turn those assets into reusable game files.

| Pillar | What It Means |
|---|---|
| Godot-first projects | Blank folders default to Godot 4.4 + Web export, with installer/register/preview tools. |
| Game-ready 2D assets | Sprite sheets become transparent frames, GIF previews, metadata, QA reports, and Godot resources. |
| End-to-end ownership | Broad build requests continue through complete gameplay, states, assets, UI, audio, tests, captures, and playtest. |
| Authored presentation | A coherent art bible drives the HUD, menus, controls, feedback, icons, typography, motion, and audio identity. |
| Evidence gates | One screen, placeholder assets, default controls, generic dashboard UI, silence, or untested claims cannot pass player-ready. |
| Web-aware troubleshooting | Use web search for official docs when engine versions, APIs, export errors, or resource issues matter. |

## Showcase Plans

Generated showcase projects are treated as local output and are not committed to the repository by default. Planned before a polished public release:

- Cat platformer asset showcase with generated action bundle.
- Real Godot Web export evidence.
- 12-20 second demo GIF.
- Workflow diagram: prompt -> GPT Image -> processor -> QA -> Godot -> browser preview.

## Player-Ready Mode

A broad request such as “make this game,” “finish this prototype,” or “build it autonomously” routes to the `game-studio-build` skill. Unless the user explicitly asks for only a prototype, the default outcome is a bounded `PLAYER_READY` game.

The workflow continues through:

1. Concept, systems, art direction, target device, controls, and an explicit player-ready contract.
2. A complete state matrix: boot, title, onboarding, gameplay, pause, settings, failure, victory/results, restart, and any game-specific modals.
3. A representative vertical slice, followed by the rest of the agreed core loop and content boundary.
4. Full asset coverage for characters, environments, gameplay feedback, UI, and release branding; accepted assets must be integrated and seen in runtime.
5. A reusable Godot UI theme and authored game-native HUD/menus rather than default controls, HTML-like cards, or dashboard layouts.
6. Integrated music, ambience, SFX, UI feedback, buses, and persisted audio settings—or a documented, playtested intentional-silence design.
7. Automated core-loop and long-run checks, captures for every required state, visual/audio review, controls verification, and a manual playtest.
8. The cross-platform `player_ready_gate.py`; blockers are fixed and rechecked instead of being relabeled as done.

The gate enforces coverage and evidence. Taste-level commercial quality still depends on reviewing the actual running game and testing with real players, so the workflow records captures and playtest findings instead of promising quality from files alone.

## What's Included

| Category | Count | Description |
|---|---:|---|
| Core skills | 12 | Start, build orchestration, design, implementation, art, sprite/map assets, asset QA, UI/UX, audio, architecture, review. |
| Tool scripts | 32 | Install, register, export, preview, asset processing, gates, hooks, imports. |
| Guard scripts | 8 | Engine, asset, story, production, release, Godot lint, review, and cross-platform player-ready gates. |
| Templates | 40 | GDDs, art briefs, state/coverage contracts, UI/audio specs, stories, production, release, QA, import manifests. |
| Asset processors/workflows | 2 | Pixel processing plus higher-level bundle/import/repair orchestration. |
| Professional aliases | 10 | `/release`, `/hotfix`, `/team-*`, `/audio-pass`, `/localization-pass`, and more. |

## Engine Support

| Engine / Stack | Support Level | What Works Now |
|---|---:|---|
| Godot 4.4 | First-class | Detection, installer/register tool, Web export, browser preview, GDScript lint, sprite import, map scene import. |
| Phaser / Three.js / PixiJS / HTML canvas | Basic/adoptable | Existing web projects are detected and respected; Codex can work in those stacks, but Godot remains the default for blank projects. |
| Unity | Detect/adopt only | Existing Unity projects are recognized and preserved; no Unity specialist pipeline yet. |
| Unreal | Detect/adopt only | Existing Unreal projects are recognized and preserved; no Unreal specialist pipeline yet. |

Blank folders default to Godot 4.4 + Web export. Existing projects keep their current engine unless the user asks to migrate.

## Quick Start

### Option 1: Install As A Codex Plugin

Add this repository as a Codex marketplace:

```bash
codex plugin marketplace add https://github.com/pin705/Codex-Game-Maker
codex plugin add codex-game-maker@codex-game-maker
```

Start a new Codex task after installation so the bundled skills are loaded.
When this repository publishes an update or adds another plugin, refresh it with:

```bash
codex plugin marketplace upgrade codex-game-maker
```

The marketplace catalog lives at `.agents/plugins/marketplace.json`, and plugin
packages live under `plugins/`.

### Option 2: Use As A Game Template

```powershell
git clone https://github.com/0xnickmortal/Codex-Game-Maker.git my-game
cd my-game
powershell -ExecutionPolicy Bypass -File tools\check-install.ps1
```

macOS/Linux:

```bash
pwsh -File tools/check-install.ps1
```

Open Codex in the folder and ask:

```text
Use Codex Game Maker to start this game project.
```

For a blank folder, new project, or broad multi-system request, Codex Game Maker uses a lean kickoff: it summarizes the idea, detects project context, proposes defaults, and asks at most three important questions. Say “go with defaults and build it player-ready” to approve bounded autonomous execution; routine asset, UI, audio, and implementation choices then proceed without repeated confirmation.

For long-running projects, use the largest context window your Codex environment supports. A 1M-token context window is recommended when available; the repository cannot force that setting, so Codex Game Maker also records continuity in planning docs, manifests, and `production/session-state/active.md`.

### Option 3: Install The Skills Globally

```powershell
powershell -ExecutionPolicy Bypass -File tools\install-codex-skills.ps1
```

macOS/Linux:

```bash
pwsh -File tools/install-codex-skills.ps1
```

Restart Codex after installing.

## Install Or Register Godot

Install Godot 4.4 and matching export templates:

```powershell
powershell -ExecutionPolicy Bypass -File tools\install-godot.ps1 -WithExportTemplates
```

macOS/Linux:

```bash
pwsh -File tools/install-godot.ps1 -WithExportTemplates
```

If Godot is already installed somewhere else, register it instead:

```powershell
powershell -ExecutionPolicy Bypass -File tools\register-godot.ps1 -GodotPath "F:\Godot_v4.4-stable_mono_win64\Godot_v4.4-stable_mono_win64"
```

Verify:

```powershell
powershell -ExecutionPolicy Bypass -File tools\check-godot.ps1
```

Preview a Godot project in browser:

```powershell
powershell -ExecutionPolicy Bypass -File tools\preview-godot-web.ps1 -Project . -CreatePresetIfMissing
```

## GPT Image 2D Asset Pipeline

Install local processing dependencies:

```powershell
python -m pip install -r requirements-asset-tools.txt
powershell -ExecutionPolicy Bypass -File tools\check-asset-tools.ps1
```

Pipeline:

```text
natural language request
  -> action bundle / map spec
  -> GPT Image raw sheet or map source
  -> chroma-key cleanup
  -> transparent PNG frames / prop slices
  -> GIF preview + pipeline-meta.json
  -> asset QA + deterministic repair
  -> Godot SpriteFrames / AnimatedSprite2D / editable level scene
  -> Godot Web preview
```

Plan a multi-action character bundle:

```powershell
powershell -ExecutionPolicy Bypass -File tools\create-action-bundle.ps1 -Root . -AssetId hero-cat -Description "cute orange tabby cat game hero with a blue backpack" -Actions "idle,run,jump,attack,hurt"
```

Save GPT Image raw sheets as:

```text
assets/raw/hero-cat-idle-sheet.png
assets/raw/hero-cat-run-sheet.png
assets/raw/hero-cat-jump-sheet.png
```

Process every available raw sheet:

```powershell
powershell -ExecutionPolicy Bypass -File tools\create-action-bundle.ps1 -Root . -AssetId hero-cat -Description "cute orange tabby cat game hero with a blue backpack" -Actions "idle,run,jump,attack,hurt" -ProcessExistingRaw
```

Run QA and deterministic repair:

```powershell
powershell -ExecutionPolicy Bypass -File tools\check-asset-qa.ps1 -Root .
powershell -ExecutionPolicy Bypass -File tools\repair-asset-processing.ps1 -Root . -Apply
```

Import accepted frames into Godot:

```powershell
powershell -ExecutionPolicy Bypass -File tools\import-sprite-to-godot.ps1 -Project . -BundleId hero-cat
```

For maps:

```powershell
powershell -ExecutionPolicy Bypass -File tools\process-prop-pack.ps1 -Input .\assets\raw\forest-props.png -OutDir .\assets\generated\props\forest -Rows 3 -Cols 3 -AssetId forest-props -ExpectedProps 9
powershell -ExecutionPolicy Bypass -File tools\compose-layered-map-preview.ps1 -Base .\assets\raw\map-base.png -Placements .\assets\raw\map-placements.json -Out .\assets\generated\maps\forest\preview.png
powershell -ExecutionPolicy Bypass -File tools\import-map-to-godot.ps1 -Project . -AssetId forest-level
```

## What It Can Generate

- Playable characters, enemies, NPCs, summons, monsters, and animated props.
- Action sheets: idle, walk, run, jump, attack, hurt, death, cast.
- Projectile, impact, muzzle flash, dust, spell, and hit FX.
- Reference-guided variants and identity-locked action sheets.
- Prop packs with extracted transparent props.
- Layered platformer, RPG, tower defense, and arena map assets.
- Collision, zones, exits, checkpoints, and placement metadata.
- Godot-ready `AnimatedSprite2D`, `SpriteFrames`, `Sprite2D`, `StaticBody2D`, `Area2D`, and `TileMapLayer` handoff files.

## What You Get

For a typical sprite action:

```text
raw-sheet-clean.png
sheet-transparent.png
frames/frame-000.png
frames/frame-001.png
animation.gif
pipeline-meta.json
asset-manifest.yaml entry
source prompt/provenance file
```

For a Godot sprite bundle:

```text
resources/animations/<bundle-id>_spriteframes.tres
scenes/characters/<bundle-id>.tscn
design/assets/godot-import-manifest.yaml
```

For a layered map:

```text
base image
dressed reference
prop pack or separated props
placement metadata
collision metadata
zones metadata
flattened preview
scenes/levels/<level-id>.tscn
```

## Professional Features

Professional workflows are explicit and opt-in.

| Alias | Status | Purpose |
|---|---:|---|
| `/release` | Available | Release checklist, changelog, patch notes, release gate. |
| `/hotfix` | Available | Small urgent fix flow with focused verification. |
| `/hooks-on` | Available | Install optional professional git hooks. |
| `/player-ready` | Available | Run the complete build and evidence loop. |
| `/team-ui` | Available | Authored UI/UX, Godot Control implementation, responsive/focus/accessibility QA. |
| `/team-level` | Available | Level implementation, environment integration, transitions, and playtest evidence. |
| `/team-combat` | Available | Combat implementation, feedback, tuning, tests, and QA. |
| `/audio-pass` | Available | Audio inventory, sourcing/creation, integration, buses, settings, mix, and listening QA. |
| `/narrative-pass` | Planned | Story, dialogue, worldbuilding, narrative delivery. |
| `/localization-pass` | Planned | Text surfaces, fonts, string length, localization readiness. |
| `/accessibility-pass` | Planned | Input, readability, subtitles, assists, motion comfort. |

Aliases live in:

```text
codex-game-studio/references/commands/catalog.yaml
```

Optional hooks:

```powershell
powershell -ExecutionPolicy Bypass -File tools\install-professional-hooks.ps1
powershell -ExecutionPolicy Bypass -File tools\uninstall-professional-hooks.ps1
```

## How It Works

1. Codex detects the engine, project stage, and current delivery state.
2. The kickoff defines a bounded outcome; broad build requests default to player-ready.
3. The build orchestrator creates state, asset, UI, audio, and evidence contracts.
4. Specialized skills implement complete gameplay slices and production presentation.
5. Automated and runtime checks expose gaps after every integration pass.
6. Visual, audio, controls, long-run, and manual playtests drive polish iterations.
7. Player-ready and release gates prevent prototypes or unsupported claims from being handed off as finished.

The user controls scope and can request checkpoints. Once autonomous/default execution is approved, the plugin is designed to continue through the bounded workflow instead of stopping after the first scene.

## Safety And Gates

| Gate | Tool | What It Checks |
|---|---|---|
| Install | `tools/check-install.ps1` | Skills, scripts, templates, Godot availability, setup health. |
| Asset tools | `tools/check-asset-tools.ps1` | Python, Pillow, numpy, processor/workflow scripts. |
| Asset QA | `tools/check-asset-qa.ps1` | Alpha, frame count, GIF, metadata, chroma-key residue, map metadata. |
| Story | `tools/check-story-gate.ps1` | Acceptance criteria, files to touch, verification plan, done evidence. |
| Production | `tools/check-production-gate.ps1` | Lightweight epic/sprint/story structure. |
| Godot lint | `tools/check-godot-lint.ps1` | Missing `res://`, unused `delta`, tuning hardcodes, UI/gameplay coupling. |
| Review | `tools/check-review-gate.ps1` | Smoke evidence, playtest evidence, project structure, export readiness. |
| Player-ready | `python3 scripts/guards/player_ready_gate.py --root .` | Complete states, integrated asset coverage, authored UI spec, audio events/buses, tests, runtime artifacts, and manual playtest evidence. |
| Release | `tools/check-release-gate.ps1` | Professional release readiness. |

## Suggested Prompts

Start a new project:

```text
Use Codex Game Maker to build a small cozy platformer player-ready from start to finish. Go with defaults, continue autonomously, and do not stop at a one-screen prototype or mock assets.
```

Create a sprite bundle:

```text
Use Codex Game Maker to create a cute cat platformer hero with idle, run, jump, attack, and hurt animations.
```

Create a map:

```text
Use Codex Game Maker to create a Godot-editable forest shrine map with separated props, collision blockers, exit zones, and a debug player scene.
```

Review before a demo:

```text
Use Codex Game Maker to review this project before I export a browser demo.
```

Finish a weak prototype:

```text
/player-ready Audit this prototype, then finish every gameplay state, replace incomplete assets, redesign the HTML-like UI as game-native UI, integrate audio, run tests, capture every state, playtest it, and keep iterating until the player-ready gate passes.
```

Professional release mode:

```text
/release Prepare this Godot Web demo for a public alpha release.
```

## Repository Layout

```text
codex-game-studio/
  .codex-plugin/
  skills/
  references/
  scripts/
tools/
docs/
assets/
  brand/
production/
requirements-asset-tools.txt
README.md
README.zh-CN.md
LICENSE
```

## More Docs

- [Chinese README](README.zh-CN.md)
- [Changelog](CHANGELOG.md)
- [Contributing](CONTRIBUTING.md)
- [Open source installation](docs/OPEN_SOURCE_INSTALLATION.md)
- [Project migration](docs/PROJECT_MIGRATION.md)
- [Playable asset integration playbook](docs/PLAYABLE_ASSET_INTEGRATION.md)
- [Asset pipeline completion plan](docs/ASSET_PIPELINE_COMPLETION_PLAN.md)
- [Release assets checklist](docs/RELEASE_ASSETS.md)

## License

MIT. See [LICENSE](LICENSE).
