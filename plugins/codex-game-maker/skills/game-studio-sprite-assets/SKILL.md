---
name: game-studio-sprite-assets
description: "Create game-ready 2D sprite assets with Codex Game Maker. Use for GPT Image 2 sprite sheets, characters, enemies, NPCs, props, projectiles, impacts, FX, frame extraction, transparent PNG outputs, GIF previews, Godot sprite import metadata, and sprite asset QA."
---

# Game Studio Sprite Assets

Use this for isolated 2D game assets and animated sprite sheets.

## Required Context

Read if present:
- `design/art/art-bible.md`
- `design/art/style-lock.json`
- `production/session-state/active.md`
- `design/assets/asset-manifest.yaml`
- `../../references/templates/sprite-asset-spec.yaml`
- `../../references/templates/asset-harness-spec.yaml`
- `../../references/templates/scene-scale-plan.yaml`
- `../../references/templates/asset-prompt-spec.yaml`
- `../../references/templates/topdown-survivor-character-contract.yaml`
- `../../references/rules/generated-assets.md`
- `../../references/rules/playable-showcase-integration.md`
- `../../references/rules/topdown-survivor-character-assets.md`
- `../../scripts/assets/cgs_asset_processor.py`
- `../../scripts/assets/cgs_asset_harness.py`

If no art bible exists, use `game-studio-art-assets` first.
Before production generation, run `python3 ../../scripts/cgm.py style-lock verify --root .`. Every prompt and pipeline metadata file must carry the current `style_version`, style-lock SHA-256, art-bible SHA-256, and locked reference paths. Use candidate/look-dev mode only before a lock; never accept unlocked output as production art.

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
../../tools/create-asset-harness.ps1 -Root . -AssetId cultivator-hero-run -Kind sprite -Action run -Rows 3 -Cols 4 -CellWidth 384 -CellHeight 384 -SafeMargin 48 -KeyColor "#FF00FF" -Loop
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
../../tools/check-asset-harness.ps1 -Spec design/assets/harnesses/cultivator-hero-run.harness.json -Input assets/raw/cultivator-hero-run-sheet.png
```

If the raw image has the right subject and motion but the generator missed exact canvas size, row/column layout, or safe-zone placement, run deterministic rectification before processing:

```powershell
../../tools/rectify-asset-to-harness.ps1 -Spec design/assets/harnesses/cultivator-hero-run.harness.json -Input assets/raw/cultivator-hero-run-sheet.png -Output assets/raw/cultivator-hero-run-rectified.png
../../tools/check-asset-harness.ps1 -Spec design/assets/harnesses/cultivator-hero-run.harness.json -Input assets/raw/cultivator-hero-run-rectified.png
```

Rectification is only for geometry: exact canvas, grid normalization, safe padding, pivot/bottom alignment, foreground-mask isolation, and component placement. The rectified output must not preserve rectangular chroma-key gradient blocks around the subject; if it does, fix the rectifier or rerun with stricter key tolerance before processing. Regenerate instead of rectifying when identity drifts, the action is not a real loop, a run/walk does not alternate feet, a jump pose sequence is wrong, limbs are missing, or neighboring-frame fragments are baked into the subject.

## Generation Rules

- Use built-in image generation for raw raster art.
- Use a flat solid chroma-key background for assets that need transparency, unless the user explicitly chooses another workflow.
- Before writing the final image prompt, run `../../tools/suggest-key-color.ps1 -Description "<asset description>"` when available.
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
- Use `2x4` only for compact first-pass jump, cast, death, or secondary motion.
- Use `3x4` for 12-frame run, attack, death, hero signature actions, and polished core loops.
- Use `3x4` for side-view playable hero walk/run by default. Do not ship a side-view 2x4 locomotion sheet for a showcase unless the user explicitly accepts rough animation.
- For top-down survivor / arena games, do not use side-view platformer run sheets. Use `ViewProfile top_down_survivor`, separate idle loops, and either full directional states or an explicit side-only survivor model.
- For polished directional top-down survivor heroes, use restrained `2x4` 8-frame shuffle loops per direction (`move_down`, `move_side`, `move_up`) or a canonical `4x4` four-direction sheet. Keep the head, torso, tail, equipment, pivot, and foot baseline stable; animate hand/foot alternation instead of translating, scaling, or globally warping the whole character.
- If north/south variants are weak or not needed, choose `direction_model: side_only_last_horizontal`: generate only `idle_side` and `move_side`, flip left/right in runtime, and preserve the last horizontal facing during vertical movement. Do not force poor up/down art into the game.
- Use `4x4` for canonical top-down four-direction walk sheets.

Default action frame counts:
- `idle`: 6-8 frames
- `walk`: 12 frames for playable heroes, 8 frames only for rough or secondary characters
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
- Idle is a real runtime state, not a fallback to frame 0 of walk/run. For playable characters, provide an accepted idle loop and add a smoke test that proves the state machine returns from movement to idle when input stops.
- A run/walk action must be a real loop: first and last poses should connect cleanly, foot contact should alternate predictably, and the body should not scale or drift between frames.
- Do not fake locomotion by stacking a second full-body character, duplicated limbs, or unmasked limb crops on top of the base frame. Reference-guided derived animation must either regenerate clean frames, repaint the old limb region, or use a local warp/deformation pass that moves one visible body.
- When repairing animation locally, never keep both the old foot/hand/limb and the shifted replacement visible. Clear or repaint the original pixels before pasting the moved part, then review the GIF for a single clean character silhouette.
- If the repair moves or repaints feet, hands, limbs, tails, weapons, or props, add `local_repair` to the harness spec and point it at a repair manifest. Rerun `../../tools/check-asset-harness.ps1` after that; the accepted report must include `harness.local_repair.pixel_erasure`, `harness.local_repair.paw_blob_scan` for foot/leg repairs, and `harness.local_repair.evidence`, not just geometry evidence.
- For local foot repairs, never paste replacement feet under the old generated feet. Erase old paw/shin pixels back to the selected key color, repaint only the necessary seam, and keep one connected leg-and-paw setup per side in the original footprint. Large robe-colored rectangles or mask patches are blockers.
- When removing old pixels from a chroma-key raw sheet, erase them to the selected key color, not transparent black. Transparent black becomes false opaque residue after RGB export.
- Do not accept whole-body shake, sprite wobble, camera jitter, or pivot jitter as a walk/run loop. Top-down survivor movement still needs visible foot and/or hand alternation.
- For top-down survivor movement, harness geometry PASS is not enough. Require lower-body motion-phase evidence; if several adjacent frames are visually near-neutral, curate the strongest generated poses into a readable loop or regenerate with stricter phase prompts.
- Do not place semi-transparent shadows, glows, dust, or motion trails directly on a chroma-key raw locomotion sheet. They can become near-key residue after alpha cleanup; make them separate FX assets or opaque runtime elements.
- Design locomotion characters so the feet can animate: short jacket or shorts, separated visible feet, and no robe, skirt, staff, cape, or prop that covers foot contact poses.
- If the concept hides the feet or the foot masks are repeatedly dirty, regenerate a movement-friendly variant instead of continuing local repairs.
- Actions in the same playable character bundle must share target height, foot baseline, pivot, and runtime scale. If `move` switches to `idle` and the character grows or shrinks, regenerate or normalize the sheets before import.
- In top-down survivor games, stopped characters must use idle animation, not frame 0 of walk/run. Full-direction runtimes choose idle_down, idle_side, idle_up, move_down, move_side, or move_up from velocity direction.
- For `side_only_last_horizontal`, the runtime state machine must choose only `idle_side` or `move_side`, flip left/right, and keep vertical movement from switching to unapproved north/south frames.
- For `side_only_last_horizontal`, verify `idle_side -> move_side -> idle_side` in a runtime smoke test. Residual velocity, collision pushback, or dash cooldown must not keep the character visually stuck in move_side after input stops.
- Do not include long staffs, large weapons, dust clouds, magic trails, or oversized tails in a locomotion sheet if they threaten the cell boundary. Put them in `attack`, `cast`, or `fx` sheets.
- If any tail, weapon, cape, or effect appears inside a neighboring cell after slicing, the raw sheet is rejected even if the contact sheet looks visually attractive.
- A jump action should usually be split into pose phases: anticipation/takeoff, rise, apex, fall, and land. If only one `jump` sheet exists, the runtime state machine must select or hold phase frames instead of blindly looping the sheet.
- If generated run/jump frames are cropped, have tail/feet crossing cell edges, or do not loop, regenerate with stricter safe-padding and pose instructions before using them in a showcase.
- If a jump frame shows a tail, limb, weapon, or effect from a neighboring frame, treat it as a harness failure and regenerate with larger cell size or safe margin.
- If the generator returns a portrait sheet, wrong pixel dimensions, or a contact-sheet layout that still contains all expected frames, use `../../tools/rectify-asset-to-harness.ps1` to isolate components into the harness canvas, then rerun the harness gate.

## Runtime Integration Rules

For a generated player/enemy that enters Godot gameplay:
- Create or update a 16:9 scene scale plan before placing the asset in a playable scene.
- Define target in-game pixel height/width from the scene plan; do not render sprites at raw processed PNG scale.
- Scale frames proportionally from their transparent bounds and preserve the runtime pivot.
- Normalize frames to a fixed canvas before import.
- Record pivot, foot line, frame size, action FPS, loop/non-loop, and state-machine mapping.
- Use `AnimatedSprite2D` or `SpriteFrames` only after the normalized frames pass QA.
- For generated art used in a playable showcase, apply `../../references/rules/playable-showcase-integration.md` before declaring the scene ready.
- Add a small motion state machine for controllable characters. Minimum states: idle, run, jump-rise, jump-fall, land, hurt/dead when relevant.
- Do not treat one global foot offset as enough when platform sizes vary. Grounded visual foot sink must derive from the current floor/platform visual scale.
- If a character looks correct on large platforms but sinks into small platforms, fix the runtime grounding contract instead of only tuning the sprite.
- Use explicit project gameplay actions such as `move_left`, `move_right`, `jump`, and `restart`; do not drive shipped gameplay from Godot default `ui_*` actions.
- Bind every key shown in HUD/control text, including WASD and arrow keys when both are advertised.
- Use coyote time and jump buffering for platformers unless the user explicitly wants strict arcade input.
- Do not draw collision rectangles as visual art. Collision and generated visual props must be separate nodes/layers.
- Do not stretch props into arbitrary aspect ratios. Use aspect-preserving draw, nine-slice/tileable pieces, or generate the exact platform/prop size needed.
- Runtime pickups, goals, and hazards must use generated assets unless the current pass is explicitly greybox. Every repeated instance must have stable group/metadata behavior and be tested individually.

## Action Bundles

For a player, enemy, NPC, summon, or important animated object with multiple actions, create the bundle spec first:

```powershell
../../tools/create-action-bundle.ps1 -Root . -AssetId cultivator-hero -Description "original ink-and-jade cultivator with a readable runtime silhouette" -Actions "idle,run,cast,attack,hurt"
```

This writes:
- `design/assets/action-bundles/<asset-id>.yaml`
- one harness spec, guide, and prompt contract per action under `design/assets/harnesses/`
- one prompt spec per action under `assets/source-prompts/`
- manifest entries for each action
- an action bundle report under `production/reviews/`

After raw sheets are saved under `assets/raw/<asset-id>-<action>-sheet.png`, rerun with `-ProcessExistingRaw` to run the harness gate and process every passing action in one pass. Harness-blocked actions may be rectified only when the issue is geometry; motion, identity, and loop failures must be regenerated before processing.

## Processing

After the raw or rectified sheet passes `../../tools/check-asset-harness.ps1`, run:

```powershell
../../tools/process-sprite-sheet.ps1 -Input <raw.png> -OutDir assets/generated/<category>/<asset-id> -Rows <rows> -Cols <cols> -AssetId <asset-id> -KeyColor "<selected-key-color>"
```

Use `-KeyColor auto` only as a fallback when the selected key color is unknown; it samples the raw sheet border to infer the chroma key.

Expected outputs:
- `raw-sheet-clean.png`
- `sheet-transparent.png`
- `frames/frame-000.png` and siblings
- `animation.gif`
- optional `direction-strips/*.png`
- `pipeline-meta.json`

For accepted Godot sprite bundles, create Godot 4.6.2 resources:

```powershell
../../tools/import-sprite-to-godot.ps1 -Project . -BundleId cultivator-hero
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
../../tools/check-asset-harness.ps1 -Spec <harness.json> -Input <raw.png>
../../tools/check-asset-qa.ps1 -Root .
```

If QA finds residue or edge-touch issues that can be repaired deterministically, try:

```powershell
../../tools/repair-asset-processing.ps1 -Root .
../../tools/repair-asset-processing.ps1 -Root . -Apply
```

Block or regenerate when:
- harness canvas, grid, cell size, safe zone, edge guard, or foot line checks fail
- frame count is wrong
- transparent output is missing
- visible chroma-key residue remains on non-transparent pixels
- frames touch cell edges
- scale or anchor drifts across frames
- metadata is missing
- runtime scale, pivot, or state-machine mapping is missing for playable characters
- the asset passes extraction but fails in-scene grounding, route readability, or collection/finish behavior
