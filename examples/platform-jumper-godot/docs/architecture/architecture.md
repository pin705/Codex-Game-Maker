# Architecture: Platform Jumper

Status: Draft  
Engine: Godot 4

## Engine Detection

Detected engine: Blank project before scaffold.  
Evidence: No `project.godot`, Unity, Unreal, or web stack files at the workspace root.  
Recommendation: Godot 4 + Web export.

## Architecture Goals

- Keep the MVP playable from one main scene.
- Keep player movement tuning in a resource file.
- Use small Godot nodes and built-in physics for Web export compatibility.

## Godot Project Structure

```text
project.godot
scenes/
  main/Main.tscn
  gameplay/Player.tscn
scripts/
  gameplay/main.gd
  gameplay/player.gd
  resources/movement_tuning.gd
resources/
  tuning/player_movement.tres
```

## System Boundaries

| System | Godot Representation | Owns | Emits | Depends On |
|---|---|---|---|---|
| Player movement | `Player.tscn` + `player.gd` | Velocity, jump timers | `died` | Movement tuning |
| Level geometry | Runtime-created `StaticBody2D` nodes | Collision layout | None | Main scene |
| Hazards | Runtime-created `Area2D` nodes | Trigger areas | Body entered callback | Player body |
| Collectibles | Runtime-created `Area2D` nodes | Crystal state | Body entered callback | HUD state |
| HUD | `CanvasLayer` and `Label` | Display only | None | Main state |

## Data And Tuning

Gameplay values live in:

```text
resources/tuning/player_movement.tres
```

Node scripts own behavior, but movement numbers are exported through the resource.

## Asset Pipeline

Generated assets: Not used in MVP.  
Prompt provenance: Required once generated raster assets are accepted.  
Import settings: Future sprite sheets should document filtering and atlas sizing.  
Web export considerations: Keep first version shape-based and lightweight.

## Save/Load

Format: None in MVP.  
Location: N/A.  
Versioning: N/A.  
Web export risks: Browser storage not needed yet.

## Input

Keyboard: Godot built-in `ui_left`, `ui_right`, and `ui_accept`; runtime-added `restart` action for R.  
Gamepad: Godot built-in UI actions can map to controller defaults.  
Remapping: Deferred.  
Touch/mobile: Deferred.

## Performance Budget

Target platform: Desktop editor and Web export.  
FPS: 60.  
Memory: Minimal; no raster production assets in MVP.  
Asset limits: Keep future sprite atlas under one small texture page for the first level.

## Technical Risks

| Risk | Severity | Verification Plan | Source |
|---|---|---|---|
| Jump tuning may not fit all platform gaps | Medium | Play in editor and tune resource values | Local playtest |
| Manual scene generation can become hard to maintain | Low | Move to authored `.tscn` or tilemap once level count grows | Architecture review |
| Web export renderer differences | Low | Use compatibility renderer and browser smoke test after export | Godot docs |

## Required ADRs

- [x] ADR-0001: Use Godot 4 with Web export target.
