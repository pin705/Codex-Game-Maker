# Contributing

Codex Game Maker is currently `v1.0.0`. Contributions should preserve the stable contracts while keeping the project approachable, evidence-backed, cross-platform, and Godot-first.

## Priorities

- Improve the supported Godot 4.6 workflow and keep stable/prerelease/EOL policy data current.
- Improve GPT Image 2D asset processing and QA.
- Add small, testable tools and executable evidence for broad process.
- Preserve strict player-ready and declared-platform commercial release gates.

## Before Sending Changes

Run:

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-install.ps1
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-asset-tools.ps1
```

For Godot projects, also run:

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-godot-lint.ps1 -Root .
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-review-gate.ps1 -Root .
python3 plugins/codex-game-maker/scripts/cgm.py player-ready --root .
```

Plugin changes must also pass the repository CI contract:

```bash
python3 -m unittest discover -v tests
python3 evals/run_eval.py validate
python3 tests/validate_repository.py
python3 tests/validate_plugin_contract.py plugins/codex-game-maker
```

## Style

- Prefer clear templates and deterministic scripts.
- Do not add many default agents unless they are used by the normal workflow.
- Keep Godot as the default for blank projects.
- Preserve existing Unity, Unreal, Phaser, Three.js, PixiJS, and HTML projects when detected.
