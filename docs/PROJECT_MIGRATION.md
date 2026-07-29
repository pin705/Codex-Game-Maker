# Project Migration Guide

Use this guide when adopting Codex Game Maker into an existing game project or moving a prototype onto the Godot-first workflow.

## Migration Goals

- Detect the existing engine instead of forcing a new one.
- Preserve user-authored scenes, scripts, art, and docs.
- Add Codex Game Maker workflow files incrementally.
- Make generated assets traceable, processed, and Godot-ready.
- Keep QA light enough for small teams and early projects.

## Supported Starting Points

### Blank Folder

Expected direction:

- Recommend Godot 4.7.1.
- Create concept, art bible, architecture notes, and first implementation story.
- Install Godot only when validation/export/browser preview is needed.

First checks:

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\scripts\guards\detect_engine.ps1 -Root .
```

### Existing Godot Project

Expected direction:

- Keep `project.godot`, scenes, scripts, resources, and import settings.
- Add Codex Game Maker design/production/asset metadata around the existing project.
- Use Godot 4.7.1 guidance unless the project clearly targets another Godot 4.x version.
- Use web search for official Godot docs when version-specific APIs or export behavior matter.

First checks:

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-godot-lint.ps1 -Root .
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-review-gate.ps1 -Root .
```

### Existing Unity, Unreal, Or Web Project

Expected direction:

- Respect the detected engine.
- Do not convert the engine automatically.
- Use Codex Game Maker docs, production gates, asset processing, and review lenses where they fit.
- Only migrate to Godot if the user explicitly asks.

## Add The Minimal Workflow Skeleton

Add only what the project needs:

```text
design/
  gdd/
  art/
  assets/
assets/
  raw/
  generated/
  source-prompts/
production/
  stories/
  smoke-tests/
  regression/
  reviews/
docs/
  architecture/
```

Use templates from:

```text
plugins/codex-game-maker/references/templates/
```

## Adopt Existing Art Assets

For each existing runtime asset:

1. Move or copy the source image into `assets/raw/` if it is still needed.
2. Process it into `assets/generated/<category>/<asset-id>/`.
3. Add a prompt/provenance file under `assets/source-prompts/`.
4. Add an entry to `design/assets/asset-manifest.yaml`.
5. Run asset QA.

Example:

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\process-sprite-sheet.ps1 -Input assets\raw\hero-idle.png -OutDir assets\generated\characters\hero-idle -Rows 2 -Cols 3 -AssetId hero-idle -ExpectedFrames 6 -KeyColor auto
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-asset-qa.ps1 -Root .
```

Use `-KeyColor auto` for old assets only when the original key color is unknown and the raw image has a flat chroma-key border.

## Adopt New Generated Assets

Before generating:

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\suggest-key-color.ps1 -Description "<asset description>"
```

Then use the returned key color in the image prompt and processor command.

Required accepted asset outputs:

```text
raw source
processed transparent sheet or prop pack
frames or props directory
GIF preview for animated sprites
pipeline-meta.json
asset-manifest.yaml entry
source prompt/provenance file
Godot import manifest entry when used in a Godot project
```

## Adopt Existing Gameplay Work

Before changing code:

1. Create a small story in `production/stories/`.
2. Run the story gate in Ready mode.
3. Keep the write scope small.
4. Run Godot lint and review gate after implementation.

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-story-gate.ps1 -Root . -Mode Ready
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-godot-lint.ps1 -Root .
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-review-gate.ps1 -Root .
```

## Godot Import Handoff

Current alpha behavior:

- `design/assets/godot-import-manifest.yaml` records import intent.
- Asset QA checks that accepted assets have enough metadata for Godot use.
- Automatic `.tres` / `.tscn` generation is planned, but not implemented yet.

Recommended manual handoff for now:

- Sprites: import `sheet-transparent.png` or `frames/*.png`.
- Animated characters: create `SpriteFrames` in Godot and map per-action animations.
- Props: use sliced PNGs under `props/`.
- Maps: use preview images only for review; use separate props/collision/zones metadata for gameplay.

## Migration Gates

Minimum checks before calling a migrated project ready:

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-install.ps1
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-asset-tools.ps1
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-asset-qa.ps1 -Root .
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-production-gate.ps1 -Root .
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-review-gate.ps1 -Root .
```

For demos or public builds, also run:

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\preview-godot-web.ps1 -Project .
```

## What Not To Migrate Yet

Postpone until the project needs it:

- Large team workflow aliases.
- Release/store metadata.
- Audio/narrative/localization/accessibility specialist passes.
- Heavy regression or soak testing.
- Marketplace/plugin packaging.


