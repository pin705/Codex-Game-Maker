# Art Bible: Platform Jumper

Status: Draft  
Source concept: `design/gdd/game-concept.md`

## Visual Identity

One-line rule: Clean neon arcade shapes on a dark readable background.  
Target feeling: Clear, fast, slightly electric.  
Reference directions: Abstract arcade platformers, high-contrast training-course UI.

## Shape Language

Characters: Rounded rectangle or capsule silhouette.  
Environments: Stable rectangles with cyan fill and darker outlines.  
UI: Compact text in the corners, no decorative panels.  
VFX: Small rings, sparkles, and color pulses in later polish.

## Color System

| Role | Palette | Usage |
|---|---|---|
| Player safety | `#FFD166`, `#FFF3B0` | Player body and jump feedback |
| Threat | `#FF5C7A`, `#B82E4A` | Spikes and death cues |
| Reward | `#F7F06D`, `#FFFFFF` | Crystals |
| Neutral world | `#101820`, `#1D2D36`, `#87E3FF` | Background and platforms |
| Completion | `#35D07F`, `#C8FFE1` | Beacon and win cue |

## Rendering Style

Flat vector-like 2D shapes built directly in Godot using `Polygon2D` and collision primitives.

## UI And Icon Standards

Target sizes: HUD text 18-24 px equivalent.  
Silhouette rules: Hazards must remain triangular; rewards must remain diamond shaped.  
Text policy: Minimal HUD only.  
Accessibility: High contrast between player, hazards, rewards, and platforms.

## Asset Generation Rules

- Current MVP uses engine-native placeholder shapes, not generated raster art.
- Future accepted generated assets must live under `assets/generated/`.
- Prompt/provenance records must live under `assets/source-prompts/`.
- No text or watermark in generated sprites unless explicitly required.

## Godot Import Notes

Texture filtering: Use nearest or linear consistently once raster art is introduced.  
Sprite scale: Keep world scale around 32 px tiles.  
Tile/sprite sheet conventions: Align terrain to 32 px multiples.  
Web export constraints: Prefer compressed, small raster atlases later.

