# Contributing

Codex Game Maker is currently `v0.2.0-alpha.1`. Contributions should keep the project approachable, evidence-backed, cross-platform, and Godot-first.

## Priorities

- Improve the supported Godot 4.6/4.7 workflow and keep the recommended version policy current.
- Improve GPT Image 2D asset processing and QA.
- Add small, testable tools and executable evidence for broad process.
- Preserve strict player-ready and declared-platform commercial release gates.

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
python3 codex-game-studio/scripts/cgm.py player-ready --root .
```

Plugin changes must also pass the repository CI contract:

```bash
python3 -m unittest -v tests/test_player_ready_gate.py
python3 tests/validate_repository.py
```

## Style

- Prefer clear templates and deterministic scripts.
- Do not add many default agents unless they are used by the normal workflow.
- Keep Godot as the default for blank projects.
- Preserve existing Unity, Unreal, Phaser, Three.js, PixiJS, and HTML projects when detected.
