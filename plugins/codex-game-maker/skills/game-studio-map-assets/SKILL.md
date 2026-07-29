---
name: game-studio-map-assets
description: "Create game-ready 2D map and level assets with Codex Game Maker. Use for platformer stages, RPG maps, tower-defense maps, parallax backgrounds, prop packs, layered previews, collision metadata, zones, Godot TileMapLayer/Sprite2D/Area2D/StaticBody2D handoff, and map asset QA."
---

# Game Studio Map Assets

Use this for playable 2D maps, stages, rooms, backgrounds, and level asset packs.

## Required Context

Read if present:
- `design/gdd/game-concept.md`
- `design/gdd/systems-index.md`
- `design/art/art-bible.md`
- `design/art/style-lock.json`
- `production/session-state/active.md`
- `docs/architecture/architecture.md`
- `docs/architecture/control-manifest.md`
- `design/assets/asset-manifest.yaml`
- `../../references/templates/map-asset-spec.yaml`
- `../../references/templates/asset-harness-spec.yaml`
- `../../references/templates/scene-scale-plan.yaml`
- `../../references/templates/godot-import-manifest.yaml`
- `../../references/rules/playable-showcase-integration.md`

## Map Is Runtime Data

Run `python3 ../../scripts/cgm.py style-lock verify --root .` before producing map art. Bind foundation, prop, tile, lighting, and UI-map prompts to the current style digest; a later map batch that changes camera, palette, material, or detail density without a versioned style migration is blocked.

Do not treat a playable map as one background image unless the user explicitly asks for a flat visual background. A playable map needs separate runtime objects, collision, triggers, zones, exits, camera bounds, or engine-native map data.

## Mode Selection

Infer the mode from the game:
- platformer / side-scroller -> parallax layers + platform objects + collision metadata
- top-down RPG / monster-taming -> ground-only base + separate props + walk blockers + exits/zones
- tower defense -> terrain/lane base + path metadata + build slots + blockers + tower/enemy hooks
- tactical/grid -> tile/grid data + terrain metadata + blockers/zones
- visual/background-only -> baked raster with optional coarse collision

## Generation Rules

For playable maps:
- Generate foundation/background art first without runtime-controlled objects.
- Use a second in-world reference mockup only to plan final props and object placement.
- Do not draw labels, arrows, circles, UI callouts, numbers, legends, or debug overlays into generated art.
- Keep actors, enemies, projectiles, bosses, UI, pickups, hazards, gates, doors, ladders, and collision-critical objects out of the foundation layer.

For platformers:
- Create a 16:9 scene scale plan before placing generated platform art in a playable showcase.
- Choose one stage canvas before generation.
- Generate scenery-only layers: sky, far background, mid background, near background, optional foreground overlay.
- Generate platforms, hazards, doors, checkpoints, pickups, and occluders as separate assets or strips.
- Record collision, camera bounds, spawn points, exits, and trigger zones as metadata.
- Do not stretch a decorative platform prop into arbitrary widths. Use a tileable platform strip, left/middle/right platform pieces, nine-slice art, or generate the exact platform sizes needed.
- Do not place platform art at raw pixel scale. Assign target in-game width/height from the scene scale plan and scale proportionally.
- Store collision-bearing platforms as top-y plus collision width/height. Do not infer platform top from a visual sprite center after scaling.
- Store platform visual scale and visual top overlap separately from collision. When platform sizes vary, visual overlap must scale with the platform art scale.
- Player grounded visual sink must be validated on both large and small platforms. If one looks right and the other looks wrong, update the grounding contract.
- Keep collision rectangles invisible in runtime builds. Collision debug outlines belong only in review screenshots or editor tools.
- Large platform pieces must have safe padding and should not be extracted from a square prop-pack cell if their edges are cropped.
- Collision-bearing platform art must use a platform harness before generation:

```powershell
../../tools/create-asset-harness.ps1 -Root . -AssetId grass-platform-wide -Kind platform -Rows 1 -Cols 1 -CellWidth 768 -CellHeight 384 -SafeMargin 32 -KeyColor "#FF00FF"
```

Run the harness gate on the raw platform image before adding it to a scene:

```powershell
../../tools/check-asset-harness.ps1 -Spec design/assets/harnesses/grass-platform-wide.harness.json -Input assets/raw/grass-platform-wide.png
```

If the platform art is visually correct but the generator returned the wrong canvas size or left unsafe padding, rectify it into the platform harness before extraction:

```powershell
../../tools/rectify-asset-to-harness.ps1 -Spec design/assets/harnesses/grass-platform-wide.harness.json -Input assets/raw/grass-platform-wide.png -Output assets/raw/grass-platform-wide-rectified.png -Method auto
../../tools/check-asset-harness.ps1 -Spec design/assets/harnesses/grass-platform-wide.harness.json -Input assets/raw/grass-platform-wide-rectified.png
```

If the platform touches disallowed edges, has cropped grass/rocks/underside details, has the wrong silhouette for collision, or cannot match the intended runtime size after rectification, regenerate with a larger exact canvas or split the platform into left/middle/right pieces.

For RPG/tower defense:
- Generate ground-only base first.
- Generate a dressed in-world reference mockup from the visible base.
- Classify visible objects before generating final props.
- Use square prop packs only for compact props like rocks, barrels, crates, shrubs, lamps, and small signs.
- Generate large, tall, wide, collision-bearing, repeatable, or identity-critical objects one-by-one or as strips/custom atlases.
- Use prop packs only for compact non-critical objects. Use one harness per large prop, collision object, door, bridge, platform, or gate.
- In top-down/survivor showcases, tall solid-looking props such as trees, rocks, pillars, crates, walls, and ruins must be imported with collision blockers when they are meant to block movement. Use `StaticBody2D` on a dedicated props layer and a collision shape covering the walk-blocking base/trunk, not the full decorative canopy.
- Update player/enemy collision masks to include the props layer. Do not leave generated blocker props as visual-only `Sprite2D` nodes.
- Generated UI and FX assets used in a playable showcase must be tested at runtime scale: upgrade cards must be clipped to card controls, and gameplay FX must be readable for hits, upgrades, pulses, and kills.

## Processing

For prop packs:

```powershell
../../tools/process-prop-pack.ps1 -Input <prop-pack.png> -OutDir assets/generated/props/<asset-id> -Rows 3 -Cols 3 -AssetId <asset-id>
```

For layered map previews:

```powershell
../../tools/compose-layered-map-preview.ps1 -Base <base.png> -Placements <placements.json> -Out <preview.png>
```

For accepted map assets with preview, props, collision, and zones metadata, create an editable Godot 4.6.2 level scene:

```powershell
../../tools/import-map-to-godot.ps1 -Project . -AssetId <level-id>
```

Expected map deliverables:
- base/background images
- separated props or prop-pack extraction output
- harness specs and harness reports for collision-critical objects
- placement metadata
- collision metadata
- zones/exits metadata
- flattened QA preview
- Godot import manifest when used in a Godot project
- scene scale plan and playable showcase QA evidence when the map is used in a playable demo

## Godot Handoff

Prefer Godot 4.6.2 structures:
- `Sprite2D` for separate props and backgrounds
- `AnimatedSprite2D` for animated objects
- `TileMapLayer` when the map is tile/editing-first
- `StaticBody2D` for collision blockers
- `Area2D` for exits, encounters, checkpoints, pickups, and triggers

Record import and runtime metadata in `design/assets/godot-import-manifest.yaml`.

The generated scene should remain editable: `Sprite2D` visual layers, `StaticBody2D` collision blockers, `Area2D` gameplay zones, and `TileMapLayer` placeholders when tile metadata exists.

## Playable Showcase QA

Before calling a generated map showcase playable, verify:
- Spawn lands on a platform top on frame one.
- The smallest and largest platforms both align visually with player feet.
- Gaps and vertical steps match the player jump arc.
- Every collectible instance animates and can be collected.
- A visible finish object exists and triggers a clear state.
- No collision rectangles, guide boxes, or harness marks render in the runtime layer.
- Web preview preserves the intended 16:9 composition.

