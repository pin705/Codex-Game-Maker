---
name: game-studio-sprite-assets
description: "Create game-ready 2D sprite assets with Codex Game Maker. Use for GPT Image 2 sprite sheets, characters, enemies, NPCs, props, projectiles, impacts, FX, frame extraction, transparent PNG outputs, GIF previews, Godot sprite import metadata, and sprite asset QA."
---

# Game Studio Sprite Assets

Use this for isolated 2D game assets and animated sprite sheets.

## Required Context

Read if present:
- `design/art/art-bible.md`
- `design/assets/asset-manifest.yaml`
- `codex-game-studio/references/templates/sprite-asset-spec.yaml`
- `codex-game-studio/references/templates/asset-harness-spec.yaml`
- `codex-game-studio/references/templates/scene-scale-plan.yaml`
- `codex-game-studio/references/templates/asset-prompt-spec.yaml`
- `codex-game-studio/references/rules/generated-assets.md`
- `codex-game-studio/scripts/assets/cgs_asset_processor.py`
- `codex-game-studio/scripts/assets/cgs_asset_harness.py`

If no art bible exists, use `game-studio-art-assets` first.

## Planning Rules

Infer the smallest useful asset plan from the user's request:
- `asset_kind`: player, enemy, npc, prop, projectile, impact, fx, ui_icon
- `action`: single, idle, walk, run, jump, attack, hurt, death, cast, projectile, impact
- `view`: side, topdown, three_quarter, ui
- `sheet`: 2x3, 2x4, 3x3, 3x4, 4x4, custom
- `anchor`: center, bottom, feet
- `key_color`: suggest automatically from the asset description, then record the selected flat chroma key
- `bundle`: single_asset, unit_bundle, spell_bundle, hero_action_bundle

Do not force the user to choose rows, columns, or frame counts when the request implies them.

## Harness First

Before generating any sprite that may enter gameplay, create an asset harness:

```powershell
tools/create-asset-harness.ps1 -Root . -AssetId hero-cat-run -Kind sprite -Action run -Rows 3 -Cols 4 -CellWidth 384 -CellHeight 384 -SafeMargin 48 -KeyColor "#FF00FF" -Loop
```

Use the generated files as the source of truth:
- `design/assets/harnesses/<asset-id>.harness.json`
- `design/assets/harnesses/<asset-id>.harness.png`
- `design/assets/harnesses/<asset-id>.prompt.md`

The final image prompt must include the harness contract:
- exact total canvas size
- exact row/column grid
- exact cell size
- safe zone and edge guard
- selected chroma-key background
- pivot/foot line
- action phase plan
- no crossing cell boundaries

After saving a raw sheet, run the harness gate before processing:

```powershell
tools/check-asset-harness.ps1 -Spec design/assets/harnesses/hero-cat-run.harness.json -Input assets/raw/hero-cat-run-sheet.png
```

If the raw image has the right subject and motion but the generator missed exact canvas size, row/column layout, or safe-zone placement, run deterministic rectification before processing:

```powershell
tools/rectify-asset-to-harness.ps1 -Spec design/assets/harnesses/hero-cat-run.harness.json -Input assets/raw/hero-cat-run-sheet.png -Output assets/raw/hero-cat-run-rectified.png
tools/check-asset-harness.ps1 -Spec design/assets/harnesses/hero-cat-run.harness.json -Input assets/raw/hero-cat-run-rectified.png
```

Rectification is only for geometry: exact canvas, grid normalization, safe padding, pivot/bottom alignment, and component isolation. Regenerate instead of rectifying when identity drifts, the action is not a real loop, a run/walk does not alternate feet, a jump pose sequence is wrong, limbs are missing, or neighboring-frame fragments are baked into the subject.

## Generation Rules

- Use built-in image generation for raw raster art.
- Use a flat solid chroma-key background for assets that need transparency, unless the user explicitly chooses another workflow.
- Before writing the final image prompt, run `tools/suggest-key-color.ps1 -Description "<asset description>"` when available.
- Use the suggested key color in the prompt. Example: green slime/forest assets should usually use `#FF00FF`; purple/pink magic FX should usually use `#00FF00`.
- If the user explicitly asks for a specific background/key color, honor it and record the reason.
- Record the chosen key color in the prompt spec, asset manifest notes, and `pipeline-meta.json`.
- Require no text, no labels, no watermark, no visible grid lines, no borders, and no frame labels.
- Require the same identity, scale, and bounding box across frames.
- Require generous safe padding; no body parts, weapons, tails, wings, projectiles, trails, or FX may cross cell edges.
- Runtime sprites must be generated with explicit pivot intent: feet/bottom for characters, center for projectiles/FX, and custom anchors for weapons or large props.
- Character sheets must include enough empty margin for tails, ears, weapons, dust, and anticipation poses. Edge-touch warnings are not acceptable for playable characters.
- Do not accept a sheet just because it looks good as a contact sheet. Check the GIF preview for loop cadence, foot sliding, pose popping, identity drift, and cropped silhouettes.
- Do not generate free-form sprite sheets without a harness when the result will be used in a playable prototype or showcase.

For characters, enemies, NPCs, summons, animated props, and body actions:
- Prefer multi-row grids. Do not use raw `1xN` strips as the default.
- Use `2x3` for 6-frame idle, jump, hurt, compact attack, impact, or first-pass motion.
- Use `2x4` for 8-frame walk, jump, attack, cast, death, or richer motion.
- Use `3x4` for 12-frame run, attack, death, hero signature actions, and polished core loops.
- Use `4x4` for canonical top-down four-direction walk sheets.

Default action frame counts:
- `idle`: 6-8 frames
- `walk`: 8 frames
- `run`: 8-12 frames
- `jump`: 6-8 frames
- `attack`: 8-12 frames
- `hurt`: 3-5 frames
- `death`: 8-12 frames
- `fx`: 8-16 frames

For controllable heroes with multiple actions:
- Generate one raw grid per action first.
- Process and QA each action independently.
- Keep projectile, muzzle flash, impact, dust, and detached FX separate unless tightly attached.
- Assemble a final Godot atlas only after per-action QC passes.
- Use an action bundle for multi-action characters instead of one-off prompt drift.
- Treat `idle`, `run`, `jump`, `fall`, `land`, `attack`, and `hurt` as state-machine inputs, not just art files. If an action does not have stable timing/pivot metadata, it is not runtime-ready.
- A run/walk action must be a real loop: first and last poses should connect cleanly, foot contact should alternate predictably, and the body should not scale or drift between frames.
- A jump action should usually be split into pose phases: anticipation/takeoff, rise, apex, fall, and land. If only one `jump` sheet exists, the runtime state machine must select or hold phase frames instead of blindly looping the sheet.
- If generated run/jump frames are cropped, have tail/feet crossing cell edges, or do not loop, regenerate with stricter safe-padding and pose instructions before using them in a showcase.
- If a jump frame shows a tail, limb, weapon, or effect from a neighboring frame, treat it as a harness failure and regenerate with larger cell size or safe margin.
- If the generator returns a portrait sheet, wrong pixel dimensions, or a contact-sheet layout that still contains all expected frames, use `tools/rectify-asset-to-harness.ps1` to isolate components into the harness canvas, then rerun the harness gate.

## Runtime Integration Rules

For a generated player/enemy that enters Godot gameplay:
- Create or update a 16:9 scene scale plan before placing the asset in a playable scene.
- Define target in-game pixel height/width from the scene plan; do not render sprites at raw processed PNG scale.
- Scale frames proportionally from their transparent bounds and preserve the runtime pivot.
- Normalize frames to a fixed canvas before import.
- Record pivot, foot line, frame size, action FPS, loop/non-loop, and state-machine mapping.
- Use `AnimatedSprite2D` or `SpriteFrames` only after the normalized frames pass QA.
- Add a small motion state machine for controllable characters. Minimum states: idle, run, jump-rise, jump-fall, land, hurt/dead when relevant.
- Use explicit project gameplay actions such as `move_left`, `move_right`, `jump`, and `restart`; do not drive shipped gameplay from Godot default `ui_*` actions.
- Bind every key shown in HUD/control text, including WASD and arrow keys when both are advertised.
- Use coyote time and jump buffering for platformers unless the user explicitly wants strict arcade input.
- Do not draw collision rectangles as visual art. Collision and generated visual props must be separate nodes/layers.
- Do not stretch props into arbitrary aspect ratios. Use aspect-preserving draw, nine-slice/tileable pieces, or generate the exact platform/prop size needed.

## Action Bundles

For a player, enemy, NPC, summon, or important animated object with multiple actions, create the bundle spec first:

```powershell
tools/create-action-bundle.ps1 -Root . -AssetId hero-cat -Description "cute orange tabby cat with blue backpack" -Actions "idle,run,jump,attack,hurt"
```

This writes:
- `design/assets/action-bundles/<asset-id>.yaml`
- one harness spec, guide, and prompt contract per action under `design/assets/harnesses/`
- one prompt spec per action under `assets/source-prompts/`
- manifest entries for each action
- an action bundle report under `production/reviews/`

After raw sheets are saved under `assets/raw/<asset-id>-<action>-sheet.png`, rerun with `-ProcessExistingRaw` to run the harness gate and process every passing action in one pass. Harness-blocked actions may be rectified only when the issue is geometry; motion, identity, and loop failures must be regenerated before processing.

## Processing

After the raw or rectified sheet passes `tools/check-asset-harness.ps1`, run:

```powershell
tools/process-sprite-sheet.ps1 -Input <raw.png> -OutDir assets/generated/<category>/<asset-id> -Rows <rows> -Cols <cols> -AssetId <asset-id> -KeyColor "<selected-key-color>"
```

Use `-KeyColor auto` only as a fallback when the selected key color is unknown; it samples the raw sheet border to infer the chroma key.

Expected outputs:
- `raw-sheet-clean.png`
- `sheet-transparent.png`
- `frames/frame-000.png` and siblings
- `animation.gif`
- optional `direction-strips/*.png`
- `pipeline-meta.json`

For accepted Godot sprite bundles, create Godot 4.4 resources:

```powershell
tools/import-sprite-to-godot.ps1 -Project . -BundleId hero-cat
```

Expected Godot outputs:
- `resources/animations/<bundle-id>_spriteframes.tres`
- `scenes/characters/<bundle-id>.tscn`
- `design/assets/godot-import-manifest.yaml`

## Manifest

Update:
- `design/assets/asset-manifest.yaml`
- `assets/source-prompts/<asset-id>.yaml`

Accepted sprite assets must record:
- raw file
- processed transparent sheet
- frames directory
- GIF preview
- pipeline metadata
- harness spec
- harness report
- frame count and frame size
- Godot import target when used in a Godot project

## QA

Before using the asset in-game, run:

```powershell
tools/check-asset-harness.ps1 -Spec <harness.json> -Input <raw.png>
tools/check-asset-qa.ps1 -Root .
```

If QA finds residue or edge-touch issues that can be repaired deterministically, try:

```powershell
tools/repair-asset-processing.ps1 -Root .
tools/repair-asset-processing.ps1 -Root . -Apply
```

Block or regenerate when:
- harness canvas, grid, cell size, safe zone, edge guard, or foot line checks fail
- frame count is wrong
- transparent output is missing
- visible chroma-key residue remains on non-transparent pixels
- frames touch cell edges
- scale or anchor drifts across frames
- metadata is missing


