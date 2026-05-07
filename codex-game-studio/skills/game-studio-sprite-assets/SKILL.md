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
- `codex-game-studio/references/templates/asset-prompt-spec.yaml`
- `codex-game-studio/references/rules/generated-assets.md`
- `codex-game-studio/scripts/assets/cgs_asset_processor.py`

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

## Runtime Integration Rules

For a generated player/enemy that enters Godot gameplay:
- Normalize frames to a fixed canvas before import.
- Record pivot, foot line, frame size, action FPS, loop/non-loop, and state-machine mapping.
- Use `AnimatedSprite2D` or `SpriteFrames` only after the normalized frames pass QA.
- Add a small motion state machine for controllable characters. Minimum states: idle, run, jump-rise, jump-fall, land, hurt/dead when relevant.
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
- one prompt spec per action under `assets/source-prompts/`
- manifest entries for each action
- an action bundle report under `production/reviews/`

After raw sheets are saved under `assets/raw/<asset-id>-<action>-sheet.png`, rerun with `-ProcessExistingRaw` to process every available action in one pass.

## Processing

After accepting a raw generated sprite sheet, run:

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
- frame count and frame size
- Godot import target when used in a Godot project

## QA

Before using the asset in-game, run:

```powershell
tools/check-asset-qa.ps1 -Root .
```

If QA finds residue or edge-touch issues that can be repaired deterministically, try:

```powershell
tools/repair-asset-processing.ps1 -Root .
tools/repair-asset-processing.ps1 -Root . -Apply
```

Block or regenerate when:
- frame count is wrong
- transparent output is missing
- visible chroma-key residue remains on non-transparent pixels
- frames touch cell edges
- scale or anchor drifts across frames
- metadata is missing


