# System GDD: Player Movement

Status: Draft  
Source concept: `design/gdd/game-concept.md`

## Overview

The player can run, jump, release jump for shorter height, use coyote time after leaving a platform, buffer a jump before landing, and perform one extra air jump.

## Player Fantasy

Nimble platforming with enough forgiveness that inputs feel respected.

## Detailed Rules

- Horizontal input accelerates toward a target speed.
- Grounded movement uses stronger acceleration and friction than air movement.
- Jump can fire while grounded, during coyote time, or while extra air jumps remain.
- Releasing jump while rising cuts upward velocity for variable jump height.
- Falling below the level respawns the player.

## Formulas And Tuning

| Value | Formula / Range | Source | Notes |
|---|---|---|---|
| Max speed | 220 px/s | `resources/tuning/player_movement.tres` | Horizontal target velocity |
| Jump velocity | -430 px/s | `resources/tuning/player_movement.tres` | Negative Y is up |
| Gravity | 1150 px/s/s | `resources/tuning/player_movement.tres` | Applied in `_physics_process` |
| Coyote time | 0.10 s | `resources/tuning/player_movement.tres` | Forgiveness after leaving floor |
| Jump buffer | 0.12 s | `resources/tuning/player_movement.tres` | Forgiveness before landing |

## Acceptance Criteria

- [x] Player moves left and right.
- [x] Player jumps from ground.
- [x] Player can jump just after leaving a platform.
- [x] Player can buffer jump just before landing.
- [x] Player respawns when falling below the level.

## Godot Notes

Likely scene/resource structure: `Player.tscn`, `player.gd`, `MovementTuning` resource.  
Web export risks: Keep input and physics standard; avoid platform-specific APIs.  
Official docs verified: Godot `CharacterBody2D` and `move_and_slide()`.

