# Godot Code Rules

- Prefer Godot 4.4-compatible patterns for new blank projects.
- Keep gameplay values data-driven in resources/config files.
- Use signals or event buses for UI-to-gameplay communication; UI must not own game state.
- Keep scenes small and composable.
- Use typed GDScript where practical.
- Separate pure gameplay logic from node presentation enough to test it.
- For web export, avoid platform APIs that do not work in browsers without a fallback.
- Verify version-specific APIs against official Godot docs when uncertain.
