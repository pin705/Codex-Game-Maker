# Contributing

Codex Game Maker is currently `v0.1-alpha`. Contributions should keep the project beginner-friendly and Godot-first.

## Priorities

- Improve the Godot 4.4 workflow.
- Improve GPT Image 2D asset processing and QA.
- Add small, testable tools before adding broad process.
- Keep professional workflows explicit and optional.

## Before Sending Changes

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools\check-install.ps1
powershell -ExecutionPolicy Bypass -File tools\check-asset-tools.ps1
```

For Godot projects, also run:

```powershell
powershell -ExecutionPolicy Bypass -File tools\check-godot-lint.ps1 -Root .
powershell -ExecutionPolicy Bypass -File tools\check-review-gate.ps1 -Root .
```

## Style

- Prefer clear templates and deterministic scripts.
- Do not add many default agents unless they are used by the normal workflow.
- Keep Godot as the default for blank projects.
- Preserve existing Unity, Unreal, Phaser, Three.js, PixiJS, and HTML projects when detected.

