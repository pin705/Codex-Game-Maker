# Engine Selection Policy

Codex Game Maker is Godot-first and targets Godot 4.4 for new projects.

## Detection First

Before recommending an engine, inspect the current project:

- Godot: `project.godot`, `.godot/`, `*.tscn`, `*.tres`, `*.gd`
- Unity: `Assets/`, `ProjectSettings/ProjectVersion.txt`, `Packages/manifest.json`, `*.unity`, `*.prefab`
- Unreal: `*.uproject`, `Config/DefaultEngine.ini`, `Content/`, `Source/*.Build.cs`
- Web: `package.json`, `vite.config.*`, `next.config.*`, `src/App.*`, `public/`

## Recommendation Rules

- Blank folder: recommend Godot 4.4 with Web export.
- Existing Godot project: stay on Godot.
- Existing Unity/Unreal project: stay on the existing engine unless the user asks to migrate.
- Existing web project: stay on web stack, but do not recommend Phaser, Three.js, or PixiJS unless already present or requested.
- Browser prototype request: recommend Godot Web export first.

## Godot CLI Policy

Godot CLI is strongly recommended for a smooth first-run experience.

- If CLI is available, use it to check version, run validation, and export when possible.
- If CLI is missing, guide the user to run `tools/install-godot.ps1`. It detects Windows/macOS/Linux, installs Godot 4.4 under the Codex Game Maker folder, creates a `godot`/`godot.cmd` wrapper, and adds `.tools/godot/bin` to PATH unless `-NoPath` is provided. Manual editor steps if needed:
  1. Download Godot 4.4 from the official Godot website.
  2. Put the executable somewhere stable, such as `C:\Tools\Godot\Godot_v4.4-stable_win64.exe`, `/Applications/Godot.app`, or `~/Tools/Godot/Godot_v4.4-stable_linux.x86_64`.
  3. Optionally add that folder to PATH, or tell Codex the full executable path.
  4. Open the generated project folder.
  5. Open `project.godot`.
  6. Run the main scene documented in the project README.
- Generated projects should include a clear README telling users which scene to run.
- For browser preview, prefer `tools/preview-godot-web.ps1 -Project .` after Godot and export templates are installed.
- First-time browser setup can use `tools/install-godot.ps1 -WithExportTemplates`.
- Prefer Godot 4.4 for new projects. Use another 4.x version only if the user explicitly chooses it or an existing project already uses it.
- On macOS/Linux, run tools through PowerShell 7: `pwsh -File tools/check-install.ps1`.

## Web Search

Search official docs when:
- Godot version is unknown or newer than local confidence.
- Web export, renderer, input, plugin, mobile, or shader behavior is relevant.
- The user provides an engine error or complains that generated code/resources do not work.

Official starting points:
- Godot 4.4 release page: https://godotengine.org/releases/4.4/
- Godot 4.4 docs: https://docs.godotengine.org/en/4.4/
- Godot 4.4 command line docs: https://docs.godotengine.org/en/4.4/tutorials/editor/command_line_tutorial.html
- Godot 4.4 Web export docs: https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_web.html
- Godot 4.4 stable download archive: https://godotengine.org/download/archive/4.4-stable/


