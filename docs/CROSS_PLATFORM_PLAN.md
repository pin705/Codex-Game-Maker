# Cross-Platform Runtime

Updated: 2026-07-29

Codex Game Maker supports Windows, macOS, and Linux through the Python `cgm.py` entry point, with PowerShell wrappers retained for the detailed asset toolchain.

## Supported Baseline

- Windows: Windows PowerShell 5.1 or PowerShell 7.
- macOS: PowerShell 7 (`pwsh`).
- Linux: PowerShell 7 (`pwsh`).
- Godot: Godot 4.7.1 standard editor/CLI, installed manually or through `tools/install-godot.ps1`.

## Automatic Detection

All shared scripts should use:

```text
codex-game-studio/scripts/lib/cgs_platform.ps1
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
powershell -ExecutionPolicy Bypass -File tools\check-install.ps1
```

macOS/Linux:

```bash
pwsh -File tools/check-install.ps1
```

After the first command, wrappers should call nested scripts with the right PowerShell executable automatically.

## Godot Install Behavior

`tools/install-godot.ps1` should detect OS and download the matching official Godot 4.7.1 asset:

- Windows x86_64: `Godot_v4.7.1-stable_win64.exe.zip`
- Windows arm64: `Godot_v4.7.1-stable_windows_arm64.exe.zip`
- macOS: `Godot_v4.7.1-stable_macos.universal.zip`
- Linux x86_64: `Godot_v4.7.1-stable_linux.x86_64.zip`
- Linux arm64: `Godot_v4.7.1-stable_linux.arm64.zip`

Install layout:

```text
.tools/godot/
  bin/
    godot / godot.cmd
  windows|macos|linux/
    downloaded Godot files
```

PATH behavior:

- Windows: add `.tools/godot/bin` to User PATH.
- macOS/Linux: add `.tools/godot/bin` to the detected shell profile (`.zshrc`, `.bash_profile`, `.bashrc`, or `.profile`).
- `-NoPath` skips persistent PATH changes.

## Hook Behavior

Professional git hooks remain opt-in. Installed hooks should:

- Prefer `pwsh`.
- Fall back to `powershell.exe`/`powershell` when available.
- Add `-ExecutionPolicy Bypass` only for Windows-style Git shells.
- Fail with a clear message if PowerShell is unavailable.

## Validation Plan

Required before public release:

- Parse all PowerShell scripts on Windows.
- Run `tools/check-install.ps1` on Windows.
- Run `pwsh -File tools/check-install.ps1` on macOS.
- Run `pwsh -File tools/check-install.ps1` on Linux.
- Install Godot on at least one machine per OS with `tools/install-godot.ps1 -WithExportTemplates`.
- Export and serve the sample Godot Web project on each OS.

Current local validation is Windows-only; macOS/Linux behavior is implemented by shared detection logic but still needs real machine testing.

