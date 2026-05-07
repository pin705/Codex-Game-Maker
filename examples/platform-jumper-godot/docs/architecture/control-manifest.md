# Control Manifest

Status: Draft  
Generated from: `docs/architecture/adr-0001-godot4-web.md`

## Required Patterns

- Use Godot signals/events for gameplay-to-HUD communication when the project grows.
- Keep gameplay tuning in resources/config/data files.
- Keep UI display-only; it receives state from the main scene.
- Keep pure movement behavior isolated in `player.gd`.

## Forbidden Patterns

- No UI node directly owning gameplay state.
- No version-specific Godot API assumptions without checking docs when uncertain.
- No project asset references pointing to temporary generated-image folders.
- No hidden hazards in the playable level.

## Asset Rules

- MVP shape assets are authored in code through Godot primitives.
- Accepted generated assets live under `assets/generated/`.
- Prompt/provenance records live under `assets/source-prompts/`.

## Testing And Evidence

- Logic systems need deterministic manual checks until automated Godot test setup exists.
- Visual/feel changes need editor playtest evidence.
- Web export risks need a browser-run verification note once Godot export templates are installed.

