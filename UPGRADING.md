# Upgrading Codex Game Maker

Codex Game Maker `v1.0.0` stabilizes the Godot-first commercial 2D workflow and its documented contracts. This guide keeps plugin installations and game projects upgradeable without losing game work.

## Upgrade Principles

- Do not overwrite a user's game files blindly.
- Keep accepted generated assets under `assets/generated/`.
- Keep prompts and provenance under `assets/source-prompts/`.
- Run gates before and after upgrading a project.
- Treat `tmp/`, discarded drafts, and Codex default generated-image folders as non-production locations.

## Before Upgrading

From the project root:

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-install.ps1
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-asset-qa.ps1 -Root .
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-review-gate.ps1 -Root .
```

If the project is not already under version control, make a copy before changing files.

## Upgrade The Plugin Package

The repository has one canonical implementation:

```text
plugins/codex-game-maker/
```

### Marketplace URL Installation

Refresh the Git marketplace, reinstall the refreshed package, and inspect the installed version:

```bash
codex plugin marketplace upgrade codex-game-maker
codex plugin add codex-game-maker@codex-game-maker
codex plugin list --marketplace codex-game-maker
```

`marketplace upgrade` updates the repository snapshot; `plugin add` is still required to replace the installed cached package. Confirm the expected version, then start a **new Codex task** so it loads the updated skills.

Do not copy files from the refreshed plugin directly over a game project. Plugin-package update and game-project schema migration are separate operations.

### Source Checkout

If you develop from a clone, update the clone using the version-control workflow appropriate for that checkout, preserve local work, and validate `plugins/codex-game-maker/`. Do not maintain a second copied studio tree.

Do not replace project-specific game folders unless you intend to:

```text
assets/
design/
docs/architecture/
production/
project.godot
scenes/
scripts/
```

### Global Skill Copies

If you installed the skills globally, reinstall them after updating this repo:

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\install-codex-skills.ps1 -Force
```

macOS/Linux:

```bash
pwsh -File plugins/codex-game-maker/tools/install-codex-skills.ps1 -Force
```

Global skill copies are not managed by `codex plugin add/remove`. Back up any user-modified skill directories before `-Force`, then restart Codex or start a new task after reinstalling. Prefer the marketplace installation for normal use and avoid enabling both copies unless duplicate routing is intentional.

## Roll Back Or Uninstall

Remove the installed plugin without removing its marketplace:

```bash
codex plugin remove codex-game-maker@codex-game-maker
```

Remove the marketplace separately only when it is no longer needed:

```bash
codex plugin marketplace remove codex-game-maker
```

To roll back, pin the marketplace to a known-good Git tag or commit containing the marketplace catalog:

```bash
codex plugin remove codex-game-maker@codex-game-maker
codex plugin marketplace remove codex-game-maker
codex plugin marketplace add https://github.com/pin705/Codex-Game-Maker --ref <known-good-tag-or-commit>
codex plugin add codex-game-maker@codex-game-maker
codex plugin list --marketplace codex-game-maker
```

Start a new Codex task after uninstall or rollback. These commands change the Codex plugin installation only; they do not delete, downgrade, or migrate files already written into a game. Restore project files from version control or use a documented reverse migration when project contracts changed too.

## v0.2 State Contract Migration

`design/game-state-matrix.json` schema v1 used a fixed object of conventional state names. Schema v2 is a game-specific directed graph and is required by the player-ready gate.

From the plugin root, preview the conservative migration without writing files:

```bash
python3 scripts/cgm.py migrate --root /path/to/game --dry-run
```

When the report is understood and the game is committed or backed up, apply it with an additional project-local backup:

```bash
python3 scripts/cgm.py migrate --root /path/to/game --backup
```

The backup is written under `.cgm-backups/` (backup is also the default for non-dry runs), and the applied run writes `production/evidence/migration-report.json`. Use `--no-backup` only when another verified snapshot already exists and the operator intentionally accepts that responsibility. A `BLOCKED` result after conversion is expected when game-specific journeys, style-lock bindings, or reviews still need human/agent work; the migration tool deliberately does not invent approval evidence.

For each game:

1. Set `schema_version` to `2` and convert `states` to unique state rows with transitions and evidence.
2. Derive state IDs from the GDD; do not preserve old title/pause/victory names unless they actually apply.
3. Declare required journeys, completion states, recovery paths, and their executable command IDs.
4. Declare game-specific experience, UI, asset, audio, and evidence requirements.
5. Rerun quality commands and recapture evidence; v1 PASS labels are not carried forward automatically.

Use `plugins/codex-game-maker/references/contracts/player-journey-schema.md` as the field and invariant reference.

## v0.2 Visual Contract Migration

Player-ready projects now need `production/reviews/visual-quality-contract.json` from the plugin template. A prose review that says PASS is no longer sufficient.

1. Declare the actual target viewports and every required state from the schema-v2 graph.
2. Lock project-local look-dev references. Generated or mixed art records at least two compared candidates plus accepted/rejected IDs and rationale.
3. Add a current hash-bound capture for every required state × viewport and bind those files to a real `visual_smoke` quality command.
4. Complete the per-surface and cross-surface checks; resolve every blocker/high finding instead of relabeling it.
5. Add `presentation` usages to every asset-coverage row: state IDs, runtime reference, render mode, rendered size, rationale and composite evidence. Dedicated nine-slices also need margins and tested size ranges; cover/tile/sprite-frame modes need their specific evidence.
6. Rerun quality and player-ready gates. Previous visual PASS prose does not migrate automatically.

## Upgrade Asset Tool Dependencies

The runtime asset processor depends on Pillow and numpy:

```powershell
python -m pip install -r plugins/codex-game-maker/requirements-asset-tools.txt
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-asset-tools.ps1
```

macOS/Linux:

```bash
python3 -m pip install -r plugins/codex-game-maker/requirements-asset-tools.txt
pwsh -File plugins/codex-game-maker/tools/check-asset-tools.ps1
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
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\suggest-key-color.ps1 -Description "green forest slime enemy with moss and leaves"
```

Use the returned `key_color` in the image prompt and processing command:

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\process-sprite-sheet.ps1 -Input assets\raw\slime-run.png -OutDir assets\generated\characters\slime-run -Rows 3 -Cols 4 -AssetId slime-run -ExpectedFrames 12 -KeyColor "#FF00FF"
```

Use `-KeyColor auto` only when the raw image exists but the selected key color was not recorded.

## Godot Version

Blank projects should use `plugins/codex-game-maker/references/policies/godot-version-policy.json`, currently recommending Godot 4.6.2. Check local Godot availability:

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-godot.ps1
```

Install the recommended Godot version and matching export templates when browser preview/export matters:

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\install-godot.ps1 -WithExportTemplates
```

Cross-platform Python entry point:

```bash
python3 plugins/codex-game-maker/scripts/cgm.py install-godot --with-export-templates
```

## After Upgrading

Run:

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-install.ps1
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-asset-tools.ps1
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-asset-qa.ps1 -Root .
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-godot-lint.ps1 -Root .
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-review-gate.ps1 -Root .
```

Expected project-setup warnings:

- Godot CLI missing if Godot is not installed.
- Asset manifest missing if no generated assets have entered the project.
- Smoke/playtest evidence missing before a demo pass has been recorded.

## Breaking Change Policy

For stable 1.x releases:

- Backward-compatible template fields may be added, but the changelog and this guide must identify newly required fields.
- Gate warnings may become stricter; a former PASS is not carried forward without rerunning current evidence.
- Tool parameters should remain backward compatible whenever practical.
- Existing accepted assets should not be invalidated without a clear migration or documented rollback path.
- Schema-breaking releases need a dry-run migration tool or a complete manual migration procedure with backup, validation, and failure recovery.

Migration success means the current project-bound gates pass after conversion; it does not prove taste, fun, market success, certification, or legal approval. Do not use a self-authored PASS or stale screenshot as migration evidence.

The 1.x compatibility promise is for the declared Godot-first commercial 2D workflow. Incompatible plugin, command, or project-schema changes require the next major version. 3D pipelines, console SDK/certification, hosted backends, store accounts, signing credentials, ratings, legal decisions, and publishing remain conditional or externally owned and must not be implied by a successful plugin upgrade.
