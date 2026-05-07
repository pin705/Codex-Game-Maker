# Control Manifest

Status: Draft
Generated from: `docs/architecture/adr-*.md`

## Required Patterns

- Use Godot signals/events for UI-to-gameplay communication.
- Keep gameplay tuning in resources/config/data files.
- Keep UI display-only; it emits requests and receives state.
- Keep pure gameplay logic separate enough to test without full scenes.

## Forbidden Patterns

- No hardcoded gameplay balance values in node scripts.
- No UI node directly owning gameplay state.
- No version-specific Godot API assumptions without checking docs when uncertain.
- No project asset references pointing to Codex generated-image temp folders.

## Asset Rules

- Accepted generated assets live under `assets/generated/`.
- Prompt/provenance records live under `assets/source-prompts/`.
- Import settings must be documented for sprites, textures, and UI icons.

## Testing And Evidence

- Logic systems need automated tests or deterministic manual checks.
- Visual/feel changes need screenshot, video, or playtest evidence.
- Web export risks need a browser-run verification note.
