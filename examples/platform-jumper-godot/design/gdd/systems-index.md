# Systems Index

Status: Draft  
Source concept: `design/gdd/game-concept.md`

## MVP Systems

| System | Priority | Depends On | Output |
|---|---:|---|---|
| Player movement | P0 | Godot `CharacterBody2D`, movement tuning resource | Responsive run, jump, air jump, respawn |
| Level geometry | P0 | Static collision bodies | Platforms and traversal route |
| Hazards and respawn | P0 | Player body, area triggers | Death count and quick reset |
| Collectibles and goal | P0 | Area triggers, HUD | Crystal count and win state |
| HUD | P1 | Gameplay state | Onscreen progress feedback |

## Dependency Order

1. Player movement.
2. Level geometry.
3. Hazards and respawn.
4. Collectibles and goal.
5. HUD polish and tuning.

