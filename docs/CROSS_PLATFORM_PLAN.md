# Cross-Platform Runtime

Updated: 2026-07-29

Codex Game Maker supports Windows, macOS, and Linux through the Python `cgm.py` entry point, with PowerShell wrappers retained for the detailed asset toolchain.

## Supported Baseline

- Windows: Windows PowerShell 5.1 or PowerShell 7.
- macOS: PowerShell 7 (`pwsh`).
- Linux: PowerShell 7 (`pwsh`).
- Godot: Godot 4.6.2 standard editor/CLI, installed manually or through `plugins/codex-game-maker/tools/install-godot.ps1`.

## Automatic Detection

All shared scripts should use:

```text
plugins/codex-game-maker/scripts/lib/cgs_platform.ps1
```

The helper owns:

- OS detection: `windows`, `macos`, `linux`.
- CPU architecture detection: `x86_64`, `arm64`, `x86_32`.
- PowerShell invocation: `pwsh`, `powershell`, or `powershell.exe`.
- Godot discovery from `GODOT_BIN`, repo-local `.tools/godot`, PATH, and common OS install locations.
- Godot export template path detection per OS.

## User Commands

Windows:

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-install.ps1
```

macOS/Linux:

```bash
pwsh -File plugins/codex-game-maker/tools/check-install.ps1
```

After the first command, wrappers should call nested scripts with the right PowerShell executable automatically.

## Godot Install Behavior

`plugins/codex-game-maker/scripts/install_godot.py` detects the OS and downloads the matching official Godot 4.6.2 asset only after resolving a policy-pinned SHA-512 value:

- Windows x86_64: `Godot_v4.6.2-stable_win64.exe.zip`
- Windows arm64: `Godot_v4.6.2-stable_windows_arm64.exe.zip`
- macOS: `Godot_v4.6.2-stable_macos.universal.zip`
- Linux x86_64: `Godot_v4.6.2-stable_linux.x86_64.zip`
- Linux arm64: `Godot_v4.6.2-stable_linux.arm64.zip`

The default install is a stable per-user cache that survives plugin upgrades:

```text
macOS:  ~/Library/Caches/CodexGameMaker/godot/
Windows: %LOCALAPPDATA%\CodexGameMaker\godot\
Linux:  ${XDG_CACHE_HOME:-~/.cache}/codex-game-maker/godot/

<cache>/
  bin/
    godot / godot.cmd
  windows|macos|linux/
    verified Godot files
  downloads/
    verified archives only when --keep-downloads is requested
  install-manifest.json
```

PATH behavior:

- The Python installer and normal `cgm.py install-godot` flow do not edit shell profiles.
- The PowerShell wrapper changes PATH only when `-AddToPath` is explicitly supplied together with a stable `-InstallDir`.
- `CODEX_GAME_MAKER_CACHE` can override the cache parent for controlled CI or team environments.
- Existing editors and export templates are reused only when their trusted install marker and current hashes still match; otherwise reinstall with `--force` after review.

## Hook Behavior

Professional git hooks remain opt-in. Installed hooks should:

- Prefer `pwsh`.
- Fall back to `powershell.exe`/`powershell` when available.
- Add `-ExecutionPolicy Bypass` only for Windows-style Git shells.
- Fail with a clear message if PowerShell is unavailable.

## Validation Gates

- Pull-request CI runs the full Python/adversarial suite, repository/plugin/skill validation, PowerShell parsing, and asset dependency checks on Windows, macOS, and Linux.
- Release CI downloads checksum-verified Godot and export templates on all three operating systems, imports the tracked fixture, launches it headlessly, observes its runtime marker, and performs a real Web export before publishing artifacts.
- The weekly nightly repeats the three-OS runtime matrix to detect upstream or runner regressions.
- Project releases still require their own target-device, signing, packaging, performance, controller, and player evidence; the repository fixture proves the plugin runtime path, not an arbitrary game's quality.
