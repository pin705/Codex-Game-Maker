# Control Manifest

Status: Draft
Generated from: `docs/architecture/adr-*.md`

## Required Patterns

- Define project-specific gameplay input actions such as `move_left`, `move_right`, `jump`, `attack`, `interact`, `pause`, and `restart`.
- Bind keyboard defaults explicitly, including WASD and arrow keys for movement when both are shown in UI text.
- For Web previews, ensure the canvas receives focus and verify keyboard control in the browser build.
- Use Godot signals/events for UI-to-gameplay communication.
- Keep gameplay tuning in resources/config/data files.
- Keep UI display-only; it emits requests and receives state.
- Keep pure gameplay logic separate enough to test without full scenes.

## Forbidden Patterns

- No hardcoded gameplay balance values in node scripts.
- No UI node directly owning gameplay state.
- No version-specific Godot API assumptions without checking docs when uncertain.
- No project asset references pointing to Codex generated-image temp folders.
- No relying on Godot default `ui_left`, `ui_right`, `ui_accept`, or `ui_cancel` for shipped gameplay controls.
- No HUD/control text that advertises an unbound key.

## Asset Rules

- Accepted generated assets live under `assets/generated/`.
- Prompt/provenance records live under `assets/source-prompts/`.
- Import settings must be documented for sprites, textures, and UI icons.

## Testing And Evidence

- Logic systems need automated tests or deterministic manual checks.
- Visual/feel changes need screenshot, video, or playtest evidence.
- Web export risks need a browser-run verification note.
