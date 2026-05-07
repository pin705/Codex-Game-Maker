# Upgrading Codex Game Maker

Codex Game Maker is currently a v0.1 alpha project. Expect fast iteration around tools, templates, and asset metadata. This guide keeps local projects upgradeable without losing game work.

## Upgrade Principles

- Do not overwrite a user's game files blindly.
- Keep accepted generated assets under `assets/generated/`.
- Keep prompts and provenance under `assets/source-prompts/`.
- Run gates before and after upgrading a project.
- Treat `tmp/`, discarded drafts, and Codex default generated-image folders as non-production locations.

## Before Upgrading

From the project root:

```powershell
powershell -ExecutionPolicy Bypass -File tools\check-install.ps1
powershell -ExecutionPolicy Bypass -File tools\check-asset-qa.ps1 -Root .
powershell -ExecutionPolicy Bypass -File tools\check-review-gate.ps1 -Root .
```

If the project is not already under version control, make a copy before changing files.

## Upgrade The Studio Files

If you use this repository as the game template, pull or copy the new studio files into the project:

```text
codex-game-studio/
tools/
requirements-asset-tools.txt
README.md
docs/
```

Do not replace project-specific game folders unless you intend to:

```text
assets/
design/
docs/architecture/
examples/
production/
project.godot
scenes/
scripts/
```

## Upgrade Global Skills

If you installed the skills globally, reinstall them after updating this repo:

```powershell
powershell -ExecutionPolicy Bypass -File tools\install-codex-skills.ps1 -Force
```

macOS/Linux:

```bash
pwsh -File tools/install-codex-skills.ps1 -Force
```

Restart Codex after reinstalling.

## Upgrade Asset Tool Dependencies

The runtime asset processor depends on Pillow and numpy:

```powershell
python -m pip install -r requirements-asset-tools.txt
powershell -ExecutionPolicy Bypass -File tools\check-asset-tools.ps1
```

macOS/Linux:

```bash
python3 -m pip install -r requirements-asset-tools.txt
pwsh -File tools/check-asset-tools.ps1
```

## v0.1 Asset Metadata Changes

Accepted runtime assets should now record:

```yaml
raw_file: assets/raw/<asset>.png
selected_file: assets/generated/<category>/<asset>/sheet-transparent.png
processed_file: assets/generated/<category>/<asset>/sheet-transparent.png
frames_dir: assets/generated/<category>/<asset>/frames
gif_preview: assets/generated/<category>/<asset>/animation.gif
pipeline_meta: assets/generated/<category>/<asset>/pipeline-meta.json
source_prompt: assets/source-prompts/<asset>.yaml
expected_frames: 6
key_color: "#FF00FF"
```

`pipeline-meta.json` now records the chroma key used by the processor:

```json
{
  "chroma_key": {
    "key_color": "#FF00FF",
    "key_color_source": "explicit"
  },
  "qa": {
    "opaque_key_pixels": 0
  }
}
```

Older metadata with only `opaque_magenta_pixels` is still understood as a fallback, but new assets should use `opaque_key_pixels`.

## Key Color Selection

Before generating transparent sprite or prop assets, suggest a key color from the asset description:

```powershell
powershell -ExecutionPolicy Bypass -File tools\suggest-key-color.ps1 -Description "green forest slime enemy with moss and leaves"
```

Use the returned `key_color` in the image prompt and processing command:

```powershell
powershell -ExecutionPolicy Bypass -File tools\process-sprite-sheet.ps1 -Input assets\raw\slime-run.png -OutDir assets\generated\characters\slime-run -Rows 3 -Cols 4 -AssetId slime-run -ExpectedFrames 12 -KeyColor "#FF00FF"
```

Use `-KeyColor auto` only when the raw image exists but the selected key color was not recorded.

## Godot Version

Blank projects should target Godot 4.4. Check local Godot availability:

```powershell
powershell -ExecutionPolicy Bypass -File tools\check-godot.ps1
```

Install Godot 4.4 and export templates when browser preview/export matters:

```powershell
powershell -ExecutionPolicy Bypass -File tools\install-godot.ps1 -WithExportTemplates
```

## After Upgrading

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools\check-install.ps1
powershell -ExecutionPolicy Bypass -File tools\check-asset-tools.ps1
powershell -ExecutionPolicy Bypass -File tools\check-asset-qa.ps1 -Root .
powershell -ExecutionPolicy Bypass -File tools\check-godot-lint.ps1 -Root .
powershell -ExecutionPolicy Bypass -File tools\check-review-gate.ps1 -Root .
```

Expected alpha-state warnings:

- Godot CLI missing if Godot is not installed.
- Asset manifest missing if no generated assets have entered the project.
- Smoke/playtest evidence missing before a demo pass has been recorded.

## Breaking Change Policy

Until v1.0:

- Template fields may be added.
- Gate warnings may become stricter.
- Tool parameters should remain backward compatible whenever practical.
- Existing accepted assets should not be invalidated without a clear migration path.

If a future change needs a migration script, it should be added under `tools/` and documented here.


