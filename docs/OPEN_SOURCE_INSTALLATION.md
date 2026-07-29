# Open Source Installation Plan

Codex Game Maker should be easy to try before it becomes a formal plugin.

## Lessons From Claude Code Game Studios

Claude Code Game Studios keeps the public install path simple:

1. Clone or use the repository as a template.
2. Open the AI coding tool in that folder.
3. Run the start command.
4. Optional validation tools are helpful, but missing optional tools should not block the first session.

Codex Game Maker should follow the same shape. The first user experience should not require users to understand plugin internals, marketplace files, global skill paths, or hook systems.

## Recommended User Paths

### 1. GitHub Template Mode

Best for most users.

User flow:

```powershell
git clone https://github.com/0xnickmortal/Codex-Game-Maker.git my-game
cd my-game
```

Then in Codex:

```text
Use Codex Game Maker to start this game project.
```

Optional setup check:

```powershell
powershell -ExecutionPolicy Bypass -File tools\check-install.ps1
```

macOS/Linux:

```bash
pwsh -File tools/check-install.ps1
```

This check may warn that Godot CLI is missing. Run `tools/install-godot.ps1`; it detects the operating system, installs Godot 4.4 into the Codex Game Maker folder, creates a `godot` wrapper, and adds it to PATH unless `-NoPath` is provided.

For browser preview, run this once:

```powershell
powershell -ExecutionPolicy Bypass -File tools\install-godot.ps1 -WithExportTemplates
```

macOS/Linux:

```bash
pwsh -File tools/install-godot.ps1 -WithExportTemplates
```

Then generated Godot projects can be previewed with:

```powershell
powershell -ExecutionPolicy Bypass -File tools\preview-godot-web.ps1 -Project .
```

macOS/Linux:

```bash
pwsh -File tools/preview-godot-web.ps1 -Project .
```

For game-ready GPT Image 2D assets, users should also install the lightweight Python processor dependencies:

```powershell
python -m pip install -r requirements-asset-tools.txt
powershell -ExecutionPolicy Bypass -File tools\check-asset-tools.ps1
```

macOS/Linux:

```bash
python3 -m pip install -r requirements-asset-tools.txt
pwsh -File tools/check-asset-tools.ps1
```

Why this is the best first experience:
- The game project and studio workflow live together.
- Shared references, templates, and scripts always resolve by relative path.
- Users can inspect and edit the workflow like normal repo files.
- No global install step is required.

### 2. Global Skills Install

Best for users who want Codex Game Maker available in every project.

User flow:

```powershell
git clone https://github.com/0xnickmortal/Codex-Game-Maker.git
cd Codex-Game-Maker
powershell -ExecutionPolicy Bypass -File tools\install-codex-skills.ps1
```

macOS/Linux:

```bash
pwsh -File tools/install-codex-skills.ps1
```

Then restart Codex.

The installer copies each `codex-game-studio/skills/*` directory into:

```text
%USERPROFILE%\.codex\skills\ on Windows
~/.codex/skills/ on macOS/Linux
```

It also copies shared `references/` and `scripts/` into each installed skill folder so the skill works outside this repository.

### 3. Plugin Marketplace Mode

This repository is also a Codex marketplace. Add it once, then install the
plugin from the discovered catalog:

```bash
codex plugin marketplace add https://github.com/pin705/Codex-Game-Maker
codex plugin add codex-game-maker@codex-game-maker
```

The catalog is stored in `.agents/plugins/marketplace.json`, and packaged
plugins are stored under `plugins/`. After a new plugin or update is pushed,
refresh the repository snapshot with:

```bash
codex plugin marketplace upgrade codex-game-maker
```

Keep the template and global-skill installation routes available for users who
do not want to install through the plugin marketplace.

## README Quickstart Shape

The eventual README should lead with:

```text
1. Clone or download this repo as your game project.
2. Run tools/check-install.ps1.
3. Open it in Codex.
4. Ask: "Use Codex Game Maker to start."
5. For blank projects, it recommends Godot 4.4 + Web export.
6. Before demos/exports, run `tools/check-review-gate.ps1`.
7. Before implementing features, create a story and run `tools/check-story-gate.ps1`.
8. For GPT Image runtime assets, run `tools/process-sprite-sheet.ps1` or `tools/process-prop-pack.ps1`, then record outputs in `design/assets/asset-manifest.yaml`.
9. After accepting generated assets, run `tools/check-asset-qa.ps1`.
10. To preview in browser, run `tools/preview-godot-web.ps1 -Project .`.
```

The first Codex response should not immediately create a full game. It should use the lean kickoff from `references/policies/collaboration-policy.md`: summarize the idea, propose defaults, ask at most 3 questions, and offer "go with defaults".

Then include optional global install:

```powershell
powershell -ExecutionPolicy Bypass -File tools\install-codex-skills.ps1
```

Use `pwsh -File tools/install-codex-skills.ps1` on macOS/Linux.

## Test Commands For Users

Windows:

```powershell
powershell -ExecutionPolicy Bypass -File tools\check-install.ps1
powershell -ExecutionPolicy Bypass -File tools\check-asset-tools.ps1
powershell -ExecutionPolicy Bypass -File tools\check-asset-gate.ps1 -Root .
powershell -ExecutionPolicy Bypass -File tools\check-asset-qa.ps1 -Root .
powershell -ExecutionPolicy Bypass -File tools\check-godot-lint.ps1 -Root .
powershell -ExecutionPolicy Bypass -File tools\check-production-gate.ps1 -Root .
powershell -ExecutionPolicy Bypass -File tools\check-release-gate.ps1 -Root .
powershell -ExecutionPolicy Bypass -File tools\check-story-gate.ps1 -Root .
powershell -ExecutionPolicy Bypass -File tools\check-review-gate.ps1 -Root .
powershell -ExecutionPolicy Bypass -File tools\preview-godot-web.ps1 -Project .
```

macOS/Linux:

```bash
pwsh -File tools/check-install.ps1
pwsh -File tools/check-asset-tools.ps1
pwsh -File tools/check-asset-gate.ps1 -Root .
pwsh -File tools/check-asset-qa.ps1 -Root .
pwsh -File tools/check-godot-lint.ps1 -Root .
pwsh -File tools/check-production-gate.ps1 -Root .
pwsh -File tools/check-release-gate.ps1 -Root .
pwsh -File tools/check-story-gate.ps1 -Root .
pwsh -File tools/check-review-gate.ps1 -Root .
pwsh -File tools/preview-godot-web.ps1 -Project .
```

## Release Checklist

- `plugin.json` parses as JSON.
- `UPGRADING.md` explains how to update local template installs and global skills.
- `docs/PROJECT_MIGRATION.md` explains how existing projects adopt the workflow safely.
- `docs/ASSET_PIPELINE_COMPLETION_PLAN.md` tracks the game-ready 2D asset pipeline roadmap.
- Every skill passes `quick_validate.py`.
- `tools/check-install.ps1` runs without Python on Windows/macOS/Linux.
- `tools/check-godot.ps1` detects repo-local Godot, `GODOT_BIN`, PATH, and common OS install locations.
- `tools/install-godot.ps1` detects OS, installs Godot 4.4, and creates `godot`/`godot.cmd`.
- `tools/install-godot-export-templates.ps1` installs matching Godot export templates.
- `tools/export-godot-web.ps1` exports a Godot Web build when Godot CLI/templates are available.
- `tools/serve-godot-web.ps1` serves Web builds with `.wasm` MIME and isolation headers.
- `tools/preview-godot-web.ps1` chains export + local browser preview.
- `tools/check-asset-tools.ps1` verifies Python, Pillow, numpy, and the local asset processor.
- `tools/suggest-key-color.ps1` suggests a chroma-key background color from an asset description before image generation.
- `tools/process-sprite-sheet.ps1` extracts transparent sprite frames, atlas, GIF preview, and `pipeline-meta.json`.
- `tools/process-prop-pack.ps1` extracts transparent prop pack slices and metadata.
- `tools/compose-layered-map-preview.ps1` composes map previews from base art and placement metadata.
- `tools/check-asset-gate.ps1` checks generated asset manifest/provenance consistency and runtime asset metadata.
- `tools/check-asset-qa.ps1` runs the asset QA gate for accepted runtime assets.
- `tools/check-godot-lint.ps1` checks common Godot generated-code mistakes.
- `tools/check-production-gate.ps1` checks lightweight epics/sprints/stories.
- `tools/check-release-gate.ps1` checks professional-mode release readiness.
- `tools/check-story-gate.ps1` checks implementation story readiness/done evidence.
- `tools/check-review-gate.ps1` runs and returns JSON.
- `tools/install-professional-hooks.ps1` and `tools/uninstall-professional-hooks.ps1` manage optional professional hooks.
- `tools/install-codex-skills.ps1` installs into a clean Codex home.
- `game-studio-review` passes `quick_validate.py`.
- Blank project detection recommends Godot 4.4 + Web export.
- Godot project detection recognizes `project.godot`.
- Review gate recognizes Godot main scene, export presets, docs, and playtest evidence.
- Story gate recognizes `production/stories/*.md` and acceptance criteria evidence.
- Asset gate recognizes accepted generated assets, manifest entries, and prompt/provenance records.
- Godot lint gate and production gate are wired into review/install checks.
- Professional command aliases are tracked in `codex-game-studio/references/commands/catalog.yaml`.
- README shows both template and global install paths.
- `docs/CROSS_PLATFORM_PLAN.md` is updated when platform behavior changes.

