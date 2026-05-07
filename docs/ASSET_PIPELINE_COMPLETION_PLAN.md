# Asset Pipeline Completion Plan

This is the priority plan for making Codex Game Maker's 2D asset workflow feel complete. It focuses on game-ready sprite, map, prop, and Godot handoff capabilities. Multilingual README work and public branding are intentionally postponed until before release.

## Current Baseline

Already implemented:

- Sprite sheet processing.
- Prop pack slicing.
- Layered map preview composition.
- Configurable chroma-key cleanup.
- Key color suggestion from asset descriptions.
- `-KeyColor auto` fallback for raw images with flat key borders.
- Transparent sheets and frame PNG output.
- GIF previews.
- `pipeline-meta.json`.
- `asset-manifest.yaml` templates and gate checks.
- `godot-import-manifest.yaml` template.
- Asset QA gate.
- Action bundle planning and batch processing wrapper.
- Deterministic asset repair dry-run/apply wrapper.
- Godot `SpriteFrames` + `AnimatedSprite2D` scene writer.
- Godot map scene writer for previews, props, collision, zones, and optional `TileMapLayer`.
- Reference-guided variant spec writer.
- Playable showcase skeleton generator.

## Target Outcome

A user should be able to say:

```text
Use Codex Game Maker to make a cute cat platformer character.
```

Codex should produce:

```text
cat_idle/
cat_run/
cat_jump/
cat_attack/
cat_hurt/
```

Each action should have:

```text
raw generated source
selected key color
processed transparent sheet
frames/
animation.gif
pipeline-meta.json
manifest entry
Godot import metadata
QA result
```

For Godot projects, the final handoff should create usable Godot resources instead of only documentation.

## Phase 1: Action Bundle Orchestration

Status: alpha implemented.

Goal: generate and process a complete character action set rather than one sheet at a time.

Add:

- `tools/create-action-bundle.ps1`
- `codex-game-studio/references/templates/action-bundle-spec.yaml`
- `codex-game-studio/references/templates/action-bundle-report.md`
- `codex-game-studio/scripts/assets/cgs_asset_workflows.py action-bundle`

Inputs:

```yaml
asset_id: cute-cat
character_description: cute orange tabby cat with blue backpack
view: side
actions:
  - name: idle
    rows: 2
    cols: 3
    expected_frames: 6
  - name: run
    rows: 3
    cols: 4
    expected_frames: 12
  - name: jump
    rows: 2
    cols: 4
    expected_frames: 8
  - name: attack
    rows: 3
    cols: 4
    expected_frames: 12
```

Workflow:

1. Suggest key color per action from description.
2. Write generation prompts per action.
3. Process each accepted raw sheet.
4. Run asset QA.
5. Generate an action bundle report.

Acceptance:

- Bundle can pass with partial warnings.
- Failed actions are isolated; one bad action does not invalidate accepted actions.
- Manifest entries are deterministic and stable.

## Phase 2: Asset QA Auto-Repair

Status: alpha implemented.

Goal: when QA catches common processor-level issues, Codex should try deterministic fixes before asking for regeneration.

Auto-repair candidates:

- Increase key tolerance/softness when residue is small.
- Re-run with `-KeyColor auto` when key color was not recorded.
- Reduce `FitScale` when frames touch cell edges after processing.
- Switch anchor from `center` to `feet` for grounded character actions.
- Re-run prop pack extraction with different grid values only when the manifest/spec clearly says the first grid was wrong.

Do not auto-repair:

- Wrong character identity.
- Missing frames in the generated image.
- Mixed actions in one raw sheet.
- Severe cropping in the raw image.
- Non-flat background.

Add:

- `tools/repair-asset-processing.ps1`
- `asset-qa-report.md` section for attempted repair steps.
- `codex-game-studio/scripts/assets/cgs_asset_workflows.py repair-assets`

Acceptance:

- Repair attempts are recorded in `pipeline-meta.json` or a sibling repair report.
- The gate distinguishes repaired pass from clean pass.

## Phase 3: Godot Sprite Importer

Status: alpha implemented.

Goal: turn processed frames into Godot 4.4 resources.

Add:

- `tools/import-sprite-to-godot.ps1`
- `codex-game-studio/scripts/assets/cgs_asset_workflows.py godot-sprite`
- `codex-game-studio/references/templates/godot-sprite-import-spec.yaml`

Outputs:

```text
resources/animations/<asset-id>_spriteframes.tres
scenes/characters/<asset-id>.tscn
```

Godot nodes:

- `AnimatedSprite2D` for animated characters/FX.
- `Sprite2D` for single-frame props.

Required metadata:

- action name
- frame paths
- FPS
- loop setting
- pivot/anchor
- collision role

Acceptance:

- Generated `.tres` or `.tscn` loads in Godot 4.4.
- The review gate can detect the imported resource.
- If Godot CLI is available, run an import/open validation command.

## Phase 4: Map-To-Godot Scene Handoff

Status: alpha implemented.

Goal: make generated map assets usable as editable Godot scenes.

Add:

- `tools/import-map-to-godot.ps1`
- `codex-game-studio/references/templates/map-scene-import-spec.yaml`
- `codex-game-studio/scripts/assets/cgs_asset_workflows.py godot-map`

Inputs:

```text
base layer
parallax layers
prop slices
placement metadata
collision metadata
zones metadata
camera bounds
spawn/exit points
```

Godot outputs:

```text
scenes/levels/<level-id>.tscn
```

Godot nodes:

- `Node2D` level root.
- `Sprite2D` for placed props.
- `StaticBody2D` + `CollisionShape2D` for solid collision.
- `Area2D` for pickups, checkpoints, exits, encounters, triggers.
- `Parallax2D` or equivalent Godot 4.4 parallax setup when needed.
- `TileMapLayer` when tile metadata exists.

Acceptance:

- A playable map is not a single baked background.
- Collision and zones are editable in Godot.
- Review gate reports whether a map is preview-only or gameplay-ready.

## Phase 5: Reference-Guided Consistency

Status: alpha implemented as a spec workflow.

Goal: preserve character identity across separate action sheets.

Add workflow rules for:

- character identity sheet
- front/side/back reference
- action prompt reuse
- visual drift review
- acceptable variation thresholds
- `tools/create-reference-variant-spec.ps1`
- `codex-game-studio/references/templates/reference-variant-spec.yaml`

Possible metadata:

```yaml
identity_reference: assets/generated/characters/cute-cat/identity.png
identity_lock_notes: "orange tabby, cream muzzle, amber eyes, blue backpack"
allowed_variation: "pose and expression only"
```

Acceptance:

- Action bundle reports identity drift risks.
- Regeneration prompts include stable identity anchors.
- User can approve or reject action sheets independently.

## Phase 6: Showcase Demo

Status: alpha implemented as a generated Godot 4.4 showcase skeleton.

Goal: prove the pipeline by shipping a small playable Godot sample.

Candidate:

- Cat platformer.

Demo should include:

- Generated character action bundle.
- Generated props.
- Generated level preview plus editable collision.
- Godot 4.4 Web export.
- Browser preview command.
- Asset QA report.
- README with exact reproduction commands.

Current tool:

```powershell
tools/create-playable-showcase.ps1 -Root . -Name asset-pipeline-showcase
```

Acceptance:

- A new user can clone, run setup checks, export/preview the demo, and inspect generated asset metadata.

## Deferred Until Release Prep

Postpone:

- Multilingual README.
- Project logo/banner.
- Promotional GIFs.
- Marketplace packaging polish.
- Public website.
- Full release trailer or social media assets.

These matter for launch, but they should not block the core pipeline.

## Suggested Build Order

1. Action bundle templates and manifest generation.
2. Deterministic asset QA repair loop.
3. Godot `AnimatedSprite2D` importer.
4. Godot map scene importer.
5. Reference-guided consistency workflow.
6. Cat platformer showcase demo.

This order keeps the work grounded: each phase turns generated art into something closer to a playable Godot project.


