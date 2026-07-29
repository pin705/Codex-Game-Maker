# Codex Game Maker

**Languages:** [English](README.md) | [简体中文](README.zh-CN.md)

![Codex Game Maker banner](assets/brand/banner.png)

**Codex skills for building complete, polished, player-ready Godot games—not just one-screen prototypes.**

**Quick links:** [Install](#quick-start) · [Update](#update-an-installed-plugin) · [Player-Ready Mode](#player-ready-mode) · [Commercial Release Mode](#commercial-release-mode) · [1.0 Scope](#10-scope-and-evidence-standard) · [Asset Pipeline](#gpt-image-2d-asset-pipeline) · [Skills](#whats-included) · [Safety Gates](#safety-and-gates) · [Prompts](#suggested-prompts)

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
![Status](https://img.shields.io/badge/status-v1.0.0-stable-brightgreen)
![Godot](https://img.shields.io/badge/Godot-4.6.2-blue)
![Platforms](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey)
![Assets](https://img.shields.io/badge/GPT%20Image-2D%20assets-purple)
![Tools](https://img.shields.io/badge/tools-32-blue)
![Skills](https://img.shields.io/badge/skills-23-blueviolet)
![AI Built For](https://img.shields.io/badge/AI%20built%20for-Codex-111827)

Turn a single Codex session into a Godot-first game making workspace.

Godot-first workflows. Product and game design. Complete gameplay states. Production assets. Game-native UI. Integrated audio. Accessibility and localization. Verified builds. Store and launch readiness.

> Status: `v1.0.0`. The Godot-first commercial 2D workflow, project contracts, migration path, and release tooling are stable. A passing gate means the declared scope has current verifiable evidence; it does not replace platform certification, legal counsel, signing authorities, store review, independent visual judgment, or real-player testing.

Codex Game Maker turns a Codex session into an end-to-end game studio workspace: product planning, game design, Godot setup, complete gameplay implementation, sprite/map/UI asset production, game-native HUD and menus, controls, audio, automated checks, runtime capture, manual playtesting, performance, builds, compliance, localization, accessibility, store marketing, telemetry, support, and rollback planning.

## Table Of Contents

- [What Makes It Different](#what-makes-it-different)
- [Evaluation And Showcase Evidence](#evaluation-and-showcase-evidence)
- [Player-Ready Mode](#player-ready-mode)
- [Commercial Release Mode](#commercial-release-mode)
- [1.0 Scope And Evidence Standard](#10-scope-and-evidence-standard)
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
| Godot-first projects | Blank folders use the verified Godot version policy, currently recommending 4.6.2 on the supported 4.6 line. |
| Game-ready 2D assets | Sprite sheets become transparent frames, GIF previews, metadata, QA reports, and Godot resources. |
| End-to-end ownership | Broad build requests continue through complete gameplay, states, assets, UI, audio, tests, captures, and playtest. |
| Authored presentation | A coherent art bible drives the HUD, menus, controls, feedback, icons, typography, motion, and audio identity. |
| Evidence gates | One screen, placeholder assets, default controls, generic dashboard UI, silence, or untested claims cannot pass player-ready. |
| Commercial lifecycle | Business, platform, performance, compliance, localization, accessibility, marketing, online, launch, support, telemetry, and rollback workstreams converge on one release contract. |
| Web-aware troubleshooting | Use web search for official docs when engine versions, APIs, export errors, or resource issues matter. |

## Evaluation And Showcase Evidence

The repository tracks a versioned benchmark corpus, routing and hard-negative cases, a weighted rubric, run schema, scorer, and adversarial gate fixtures under `evals/` and `tests/`. Use `python3 evals/run_eval.py validate` to validate the corpus and `aggregate` only after real blind runs have been collected.

Generated game projects and large capture media stay outside the plugin package by default. Publish them as GitHub release artifacts or Git LFS evidence with their brief, plugin commit, run metadata, hashes, reviewer provenance, and score. A demo GIF or showcase is useful presentation, but is not accepted as general quality proof by itself.

## Player-Ready Mode

A broad request such as “make this game,” “finish this prototype,” or “build it autonomously” routes to the `game-studio-build` skill. Unless the user explicitly asks for only a prototype, the default outcome is a bounded `PLAYER_READY` game.

The workflow continues through:

1. Concept, systems, art direction, target device, controls, and an explicit player-ready contract.
2. A schema-v2 game-specific state graph: custom states, transitions, required journeys, completion conditions, recovery paths, experience requirements, and executable journey tests. Conventional title/pause/settings/victory screens are included only when the game's GDD requires them.
3. A representative vertical slice, followed by the rest of the agreed core loop and content boundary.
4. A game-specific asset coverage policy derived from its graph, systems, UI, content boundary, and target surfaces; accepted assets must be integrated, presentation-safe, and seen in runtime.
5. Look-dev locks a coherent direction across the visual families the game actually uses. Generated/mixed art compares candidates in runtime composites before bulk production instead of accepting the first plausible image.
6. Authored presentation through a declared Godot Theme, diegetic, custom-draw, hybrid, or intentionally minimal mode—never generic HTML/dashboard styling presented as final.
7. A game-specific audio coverage contract for the states/actions/mix that actually exist—or a documented, playtested intentional-silence design.
8. Executable engine-import, static-analysis, reliability, journey, recovery, and visual-smoke checks; distinct evidence for every declared state; structured visual/audio review and a manual journey playtest.
9. The cross-platform `player_ready_gate.py`; blockers are fixed and rechecked instead of being relabeled as done.

The gate validates real media signatures, distinct runtime states, integrated asset provenance and runtime references, hashed command results tied to the current project fingerprint, visual/audio reviews, and manual playtest evidence. Taste-level quality still depends on reviewing the running game and testing with real players.

### How The Flow Is Verified

The template suggests examples; the gate never treats their names or counts as universal truth. Each game must declare its own graph and contracts. Validation then checks:

- transition targets, reachability, completion conditions, and recovery paths;
- exact coverage of every required state by a required journey;
- a passing executable command for each journey and required recovery path;
- distinct per-state media, or distinct markers when states share a video;
- UI inventory coverage for every state marked `ui_surface`;
- asset/audio groups, minimums, and inventory sources declared for that game;
- asset presentation usages: runtime state, render mode, aspect ratio, dedicated/tested nine-slices, crop/tile/frame rules, and composite evidence;
- a structured visual contract covering every required state × target viewport, locked look-dev references, current capture hashes, cross-family coherence, unresolved findings, and capture-producing command evidence;
- adversarial regression cases, including an endless sandbox with no conventional state names, unreachable state/recovery failures, reused evidence, distorted runtime assets, under-declared inventories, fake look-dev comparison, unresolved high visual findings, and unbound captures.

This proves internal consistency and evidence coverage. It cannot mathematically prove that a GDD itself is fun, tasteful, or commercially successful, so visual review and real-player testing remain required.

## Commercial Release Mode

`/commercial-release` extends a passing player-ready candidate into a release candidate for explicitly declared platforms, locales, business model, online scope, and launch tier. It does not claim that one generic build is universally commercial-ready.

The workflow adds:

1. Product thesis, audience, market position, scope, budget, pricing, monetization, and go/no-go assumptions.
2. Version-pinned platform build matrices, reproducible exports, artifact hashes, signing/notarization status, smoke tests, and store-specific readiness.
3. Measured target-device frame time, memory, loading, stability, and regression budgets.
4. Rights/provenance, privacy/data, ratings, terms, commerce, age-related obligations, and an auditable approval register.
5. Externalized strings, locale coverage, fonts, overflow captures, linguistic review, accessibility conformance, and target-device tests.
6. Truthful rights-cleared store assets and claims, launch operations, telemetry/crash handling, support, incident response, rollback, and patch plans.
7. Conditional narrative continuity and online-service security/load/backup/restore evidence when those features are in scope.

Run the cross-platform CLI from the plugin root:

```bash
python3 scripts/cgm.py doctor --root /path/to/game
python3 scripts/cgm.py quality --root /path/to/game
python3 scripts/cgm.py player-ready --root /path/to/game
python3 scripts/cgm.py commercial-release --root /path/to/game
```

The commercial gate intentionally blocks on external actions that Codex cannot truthfully perform: legal or ratings approval, confidential console certification, store-account decisions, signing credentials, and irreversible publishing.

## 1.0 Scope And Evidence Standard

The intended 1.0 product is a dependable **Godot-first commercial 2D game-production toolkit**. Its first-party completion bar covers bounded 2D gameplay, game-specific player journeys, authored UI, 2D asset integration, audio, accessibility, localization, reproducible quality evidence, and declared desktop/Web release preparation.

Some adjacent work is deliberately conditional rather than bundled as a universal promise:

- 3D projects may use the planning, architecture, review, performance, compliance, and release contracts, but a complete first-party 3D asset/runtime pipeline is outside the 1.0 core. Use project-appropriate external 3D tools and specialists.
- Console work requires platform-holder approval, NDA material, licensed SDKs, development hardware, certification access, and authorized owners. The plugin may prepare non-confidential plans and evidence, but cannot certify or submit a console title.
- Online services and backends are included only when declared in scope. The plugin can design and verify provider-specific security, data, load, backup, restore, and failure evidence; it does not bundle or operate a hosted backend.
- Store accounts, signing/notarization credentials, ratings, tax/payment setup, platform agreements, legal advice, and irreversible publishing remain external human-authority steps.

Evidence claims stay narrow and reproducible. Repository validators and regression tests prove that declared contracts and guardrails behave as tested; they do not prove that a game is fun, visually excellent, commercially successful, certified, or legally approved. A player-ready or commercial PASS requires current project-bound artifacts and honest reviews. Benchmark or quality claims should be published only with reproducible eval inputs, outputs, scoring rules, and reviewer provenance; planned showcases, self-authored PASS labels, and one successful example are not proof of general quality.

## What's Included

| Category | Count | Description |
|---|---:|---|
| Core skills | 23 | Player-ready production plus business, commercial release, platforms, compliance, performance, localization, accessibility, narrative, online services, live operations, and marketing. |
| Tool scripts | 32 | Install, register, export, preview, asset processing, gates, hooks, imports. |
| Top-level Python CLI scripts | 7 | Cross-platform orchestration, quality, verified Godot install/export, style lock, audio QA, and migration. |
| Guard scripts | 9 | Engine, asset, story, production, release, Godot lint, review, player-ready, and strict commercial gates. |
| Templates | 60 | GDD/art/style/session/UI/audio, structured visual-quality and evidence contracts plus business, builds, performance, compliance, localization, accessibility, marketing, security, telemetry, and live operations. |
| Asset processors/workflows | 2 | Pixel processing plus higher-level bundle/import/repair orchestration. |
| Natural-language aliases | 20 | `/player-ready`, `/commercial-release`, `/quality`, and focused studio passes. |

## Engine Support

| Engine / Stack | Support Level | What Works Now |
|---|---:|---|
| Godot 4.6.2 | Recommended | Cross-platform installer/exporter, export templates, detection/register tools, Web preview, GDScript lint, sprite import, map scene import. |
| Godot 4.6 | Supported | Use the latest verified patch and pin the exact project/export-template version for reproducible releases. |
| Godot 4.5 | Security/platform fixes only | Existing projects may remain temporarily, but new work should use 4.6 and commercial releases need an explicit migration/risk decision. |
| Godot 4.7 development builds | Not production-supported | Pre-release builds may be evaluated separately, but cannot satisfy player-ready or commercial engine gates. |
| Phaser / Three.js / PixiJS / HTML canvas | Basic/adoptable | Existing web projects are detected and respected; Codex can work in those stacks, but Godot remains the default for blank projects. |
| Unity | Detect/adopt only | Existing Unity projects are recognized and preserved; no Unity specialist pipeline yet. |
| Unreal | Detect/adopt only | Existing Unreal projects are recognized and preserved; no Unreal specialist pipeline yet. |

Blank folders use `references/policies/godot-version-policy.json`; it currently recommends Godot 4.6.2. Existing projects keep their engine until compatibility and migration are reviewed. Release candidates pin the exact engine version and export templates.

## Quick Start

### Option 1: Install As A Codex Plugin

Add this repository as a Codex marketplace:

```bash
codex plugin marketplace add https://github.com/pin705/Codex-Game-Maker
codex plugin add codex-game-maker@codex-game-maker
codex plugin list --marketplace codex-game-maker
```

Confirm that `codex-game-maker@codex-game-maker` is shown as installed and enabled, then start a **new Codex task** so the bundled skills are loaded. An already-open task may continue using the previous skill snapshot.

#### Update An Installed Plugin

Refreshing the marketplace snapshot alone does not reinstall an already-cached plugin package. Run the complete update flow:

```bash
codex plugin marketplace upgrade codex-game-maker
codex plugin add codex-game-maker@codex-game-maker
codex plugin list --marketplace codex-game-maker
```

Confirm that the installed version changed as expected, then start a new Codex task.

#### Uninstall Or Roll Back

Remove the plugin while keeping the marketplace available:

```bash
codex plugin remove codex-game-maker@codex-game-maker
```

If this repository is no longer needed as a marketplace, remove it separately:

```bash
codex plugin marketplace remove codex-game-maker
```

To roll back, use a known-good Git tag or commit that contains the marketplace catalog. Removing and re-adding the marketplace makes the selected ref explicit:

```bash
codex plugin remove codex-game-maker@codex-game-maker
codex plugin marketplace remove codex-game-maker
codex plugin marketplace add https://github.com/pin705/Codex-Game-Maker --ref <known-good-tag-or-commit>
codex plugin add codex-game-maker@codex-game-maker
codex plugin list --marketplace codex-game-maker
```

Start a new Codex task after uninstalling or rolling back. Back up or commit the game project first; plugin removal does not migrate or delete files already created in that project.

The marketplace catalog lives at `.agents/plugins/marketplace.json`, and plugin
packages live under `plugins/`.

### Option 2: Develop Or Validate The Plugin Source

```powershell
git clone https://github.com/pin705/Codex-Game-Maker.git
cd Codex-Game-Maker
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-install.ps1 -Root plugins\codex-game-maker
```

macOS/Linux:

```bash
pwsh -File plugins/codex-game-maker/tools/check-install.ps1 -Root plugins/codex-game-maker
```

Install the plugin, then open Codex in the actual game project folder and ask:

```text
Use Codex Game Maker to start this game project.
```

For a blank folder, new project, or broad multi-system request, Codex Game Maker uses a lean kickoff: it summarizes the idea, detects project context, proposes defaults, and asks at most three important questions. Say “go with defaults and build it player-ready” to approve bounded autonomous execution; routine asset, UI, audio, and implementation choices then proceed without repeated confirmation.

For long-running projects, use the largest context window your Codex environment supports. A 1M-token context window is recommended when available; the repository cannot force that setting, so Codex Game Maker also records continuity in planning docs, manifests, and `production/session-state/active.md`.

### Option 3: Install The Skills Globally

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\install-codex-skills.ps1
```

macOS/Linux:

```bash
pwsh -File plugins/codex-game-maker/tools/install-codex-skills.ps1
```

Restart Codex after installing.

## Install Or Register Godot

Install the policy-recommended Godot and matching export templates on Windows, macOS, or Linux:

```bash
python3 plugins/codex-game-maker/scripts/cgm.py install-godot --with-export-templates
```

Preview the resolved download without changing the machine:

```bash
python3 plugins/codex-game-maker/scripts/cgm.py install-godot --dry-run
```

Legacy PowerShell wrapper:

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\install-godot.ps1 -WithExportTemplates
```

macOS/Linux:

```bash
pwsh -File plugins/codex-game-maker/tools/install-godot.ps1 -WithExportTemplates
```

If Godot is already installed somewhere else, register it instead:

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\register-godot.ps1 -GodotPath "F:\Godot_v4.6.2-stable_win64.exe"
```

Verify:

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-godot.ps1
```

Preview a Godot project in browser:

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\preview-godot-web.ps1 -Project . -CreatePresetIfMissing
```

## GPT Image 2D Asset Pipeline

Install local processing dependencies:

```powershell
python -m pip install -r plugins/codex-game-maker/requirements-asset-tools.txt
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-asset-tools.ps1
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
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\create-action-bundle.ps1 -Root . -AssetId hero-cat -Description "cute orange tabby cat game hero with a blue backpack" -Actions "idle,run,jump,attack,hurt"
```

Save GPT Image raw sheets as:

```text
assets/raw/hero-cat-idle-sheet.png
assets/raw/hero-cat-run-sheet.png
assets/raw/hero-cat-jump-sheet.png
```

Process every available raw sheet:

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\create-action-bundle.ps1 -Root . -AssetId hero-cat -Description "cute orange tabby cat game hero with a blue backpack" -Actions "idle,run,jump,attack,hurt" -ProcessExistingRaw
```

Run QA and deterministic repair:

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-asset-qa.ps1 -Root .
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\repair-asset-processing.ps1 -Root . -Apply
```

Import accepted frames into Godot:

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\import-sprite-to-godot.ps1 -Project . -BundleId hero-cat
```

For maps:

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\process-prop-pack.ps1 -Input .\assets\raw\forest-props.png -OutDir .\assets\generated\props\forest -Rows 3 -Cols 3 -AssetId forest-props -ExpectedProps 9
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\compose-layered-map-preview.ps1 -Base .\assets\raw\map-base.png -Placements .\assets\raw\map-placements.json -Out .\assets\generated\maps\forest\preview.png
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\import-map-to-godot.ps1 -Project . -AssetId forest-level
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
| `/commercial-release` | Available | Run the full declared-platform commercial workflow and strict gate. |
| `/quality` | Available | Execute argv-based quality commands and record hashed evidence. |
| `/release` | Available | Prepare builds, compliance, store package, launch operations, and go/no-go evidence. |
| `/hotfix` | Available | Small urgent fix flow with focused verification. |
| `/hooks-on` | Available | Install optional professional git hooks. |
| `/player-ready` | Available | Run the complete build and evidence loop. |
| `/business-pass` | Available | Validate audience, market, scope, price, budget, economics, and go/no-go assumptions. |
| `/team-ui` | Available | Authored UI/UX, Godot Control implementation, responsive/focus/accessibility QA. |
| `/team-level` | Available | Level implementation, environment integration, transitions, and playtest evidence. |
| `/team-combat` | Available | Combat implementation, feedback, tuning, tests, and QA. |
| `/audio-pass` | Available | Audio inventory, sourcing/creation, integration, buses, settings, mix, and listening QA. |
| `/narrative-pass` | Available | Narrative state, dialogue IDs, runtime branches, continuity, and content QA. |
| `/localization-pass` | Available | String externalization, fonts, locale coverage, overflow captures, and linguistic approval. |
| `/accessibility-pass` | Available | Input, readability, subtitles, assists, motion comfort, captures, and player evidence. |
| `/platform-pass` | Available | Export, package, sign, hash, smoke test, and prepare each target/store independently. |
| `/performance-pass` | Available | Measure target-device performance and enforce regression budgets. |
| `/compliance-pass` | Available | Rights, privacy, ratings, commerce, data, terms, and approval blockers. |
| `/online-pass` | Available | Online identity, data, security, load, failure, backup, and restore. |
| `/liveops-pass` | Available | Telemetry, crash handling, support, incidents, rollback, and patches. |
| `/marketing-pass` | Available | Truthful, current, localized, rights-cleared store and launch assets. |

Aliases live in:

```text
plugins/codex-game-maker/references/commands/catalog.yaml
```

Optional hooks:

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\install-professional-hooks.ps1
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\uninstall-professional-hooks.ps1
```

## How It Works

1. Codex detects the engine, project stage, and current delivery state.
2. The kickoff defines a bounded outcome; broad build requests default to player-ready.
3. The build orchestrator creates state, asset, UI, audio, and evidence contracts.
4. Specialized skills implement complete gameplay slices and production presentation.
5. Automated and runtime checks expose gaps after every integration pass.
6. Visual, audio, controls, long-run, and manual playtests drive polish iterations.
7. Player-ready and commercial gates prevent prototypes, stale evidence, fake media, unsigned builds, or unsupported claims from being handed off as finished.

The user controls scope and can request checkpoints. Once autonomous/default execution is approved, the plugin is designed to continue through the bounded workflow instead of stopping after the first scene.

## Safety And Gates

| Gate | Tool | What It Checks |
|---|---|---|
| Install | `plugins/codex-game-maker/tools/check-install.ps1` | Skills, scripts, templates, Godot availability, setup health. |
| Asset tools | `plugins/codex-game-maker/tools/check-asset-tools.ps1` | Python, Pillow, numpy, processor/workflow scripts. |
| Asset QA | `plugins/codex-game-maker/tools/check-asset-qa.ps1` | Alpha, frame count, GIF, metadata, chroma-key residue, map metadata, presentation usage and runtime composition. |
| Story | `plugins/codex-game-maker/tools/check-story-gate.ps1` | Acceptance criteria, files to touch, verification plan, done evidence. |
| Production | `plugins/codex-game-maker/tools/check-production-gate.ps1` | Lightweight epic/sprint/story structure. |
| Godot lint | `plugins/codex-game-maker/tools/check-godot-lint.ps1` | Missing `res://`, unused `delta`, tuning hardcodes, UI/gameplay coupling. |
| Review | `plugins/codex-game-maker/tools/check-review-gate.ps1` | Smoke evidence, playtest evidence, project structure, export readiness. |
| Player-ready | `python3 scripts/guards/player_ready_gate.py --root .` | Dynamic journeys, integrated asset/audio coverage, aspect/nine-slice/crop/tile presentation, structured state × viewport visual QA, authored UI, executable tests, bound runtime artifacts, and manual playtest evidence. |
| Commercial release | `python3 scripts/cgm.py commercial-release --root .` | Strict player-ready result plus clean/versioned source, builds, hashes, signing/store status, performance, compliance, localization, accessibility, marketing, online/liveops, telemetry, and external approvals. |
| Release wrapper | `plugins/codex-game-maker/tools/check-release-gate.ps1` | Legacy PowerShell entry point for the cross-platform commercial gate. |

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

Commercial release mode:

```text
/commercial-release Prepare this game for commercial release on its declared platforms. Continue until every automatable gate passes and report only the external approvals that still require their authorized owner.
```

## Repository Layout

```text
plugins/codex-game-maker/
  .codex-plugin/
  skills/
  references/
  scripts/
  tools/
  requirements-asset-tools.txt
docs/
assets/
  brand/
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
