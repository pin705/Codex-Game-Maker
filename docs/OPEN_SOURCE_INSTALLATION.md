# Open Source Installation

This repository is both the canonical Codex Game Maker source tree and a Codex plugin marketplace. Installing the plugin from the repository URL is the recommended user path. A source checkout remains useful for contributors and for people who want to run the bundled scripts directly.

## Prerequisites

- A Codex CLI/App build that provides `codex plugin` commands.
- Git access to `https://github.com/pin705/Codex-Game-Maker`.
- Python 3 for `cgm.py`, the cross-platform gates, installation, export, and asset processors.
- PowerShell on Windows, or PowerShell 7 (`pwsh`) on macOS/Linux, for the detailed legacy asset/import/preview wrappers.
- Pillow and numpy only when using local 2D asset processing.
- A policy-supported Godot version when engine import, runtime capture, export, or release evidence is required.

The plugin can still help with planning when optional runtime tools are absent, but it must not claim verified builds or runtime evidence until the required tools have actually run.

## Recommended: Install From The Marketplace URL

Add the repository once, install the plugin, and inspect the resolved installation:

```bash
codex plugin marketplace add https://github.com/pin705/Codex-Game-Maker
codex plugin add codex-game-maker@codex-game-maker
codex plugin list --marketplace codex-game-maker
```

Confirm that `codex-game-maker@codex-game-maker` is installed and enabled. Start a **new Codex task** after installation; an already-open task may keep the previous skill snapshot.

Open Codex in the actual game project directory and ask:

```text
Use Codex Game Maker to start this game project.
```

For a bounded autonomous build:

```text
Use Codex Game Maker to build this game player-ready. Go with sensible defaults, continue through the complete declared scope, and do not stop at a one-screen prototype or mock assets.
```

## Update An Installed Plugin

Marketplace upgrade refreshes the repository snapshot. Re-running `plugin add` installs that refreshed package into the Codex cache:

```bash
codex plugin marketplace upgrade codex-game-maker
codex plugin add codex-game-maker@codex-game-maker
codex plugin list --marketplace codex-game-maker
```

Check that the installed version changed as expected, then start a new Codex task. Updating the marketplace without reinstalling may leave the installed plugin on its previous cached version.

Plugin update and game-project migration are separate operations. Commit or back up the game before adopting new templates or schema versions, and follow [UPGRADING.md](../UPGRADING.md).

## Uninstall

Remove the installed plugin while keeping the marketplace configured:

```bash
codex plugin remove codex-game-maker@codex-game-maker
```

Remove the marketplace only when no plugin from this repository is still needed:

```bash
codex plugin marketplace remove codex-game-maker
```

Start a new Codex task after removal. Uninstalling the plugin removes its Codex installation/cache entry; it does not delete or rewrite files previously created in a game project.

## Roll Back To A Known-Good Ref

Use a Git tag or commit that contains a valid `.agents/plugins/marketplace.json` and plugin package. Make the ref explicit by removing and re-adding the Git marketplace:

```bash
codex plugin remove codex-game-maker@codex-game-maker
codex plugin marketplace remove codex-game-maker
codex plugin marketplace add https://github.com/pin705/Codex-Game-Maker --ref <known-good-tag-or-commit>
codex plugin add codex-game-maker@codex-game-maker
codex plugin list --marketplace codex-game-maker
```

Start a new Codex task after rollback. Rolling back the plugin does not automatically downgrade project contracts or generated files; restore the game from version control or follow a documented reverse migration when project data also changed.

## Source Checkout For Development

Clone the canonical repository without turning it into the game project itself:

```bash
git clone https://github.com/pin705/Codex-Game-Maker.git
cd Codex-Game-Maker
```

Validate the package on Windows:

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\check-install.ps1 -Root plugins\codex-game-maker
```

On macOS/Linux:

```bash
pwsh -File plugins/codex-game-maker/tools/check-install.ps1 -Root plugins/codex-game-maker
```

The main cross-platform CLI can be run from the repository checkout root:

```bash
python3 plugins/codex-game-maker/scripts/cgm.py doctor --root /path/to/game
python3 plugins/codex-game-maker/scripts/cgm.py quality --root /path/to/game
python3 plugins/codex-game-maker/scripts/cgm.py player-ready --root /path/to/game
python3 plugins/codex-game-maker/scripts/cgm.py commercial-release --root /path/to/game
```

Install local 2D asset-processing dependencies only when needed:

```bash
python3 -m pip install -r plugins/codex-game-maker/requirements-asset-tools.txt
```

Use the repository validation commands in [CONTRIBUTING.md](../CONTRIBUTING.md) before proposing plugin changes.

## Advanced: Global Skill Copies

The PowerShell global-skill installer remains available for older setups that cannot use plugins:

```powershell
powershell -ExecutionPolicy Bypass -File plugins\codex-game-maker\tools\install-codex-skills.ps1
```

macOS/Linux:

```bash
pwsh -File plugins/codex-game-maker/tools/install-codex-skills.ps1
```

This route copies standalone skills into the Codex home and is **not managed by `codex plugin add/remove`**. It can collide with skills of the same name, and updates require rerunning the installer with `-Force` after backing up user-modified skill directories. Prefer the marketplace plugin for normal use and do not combine both installation modes unless duplicate routing is intentional.

## Godot And Asset Tooling

Install the policy-recommended Godot editor and matching export templates from a source checkout or through the bundled skill workflow:

```bash
python3 plugins/codex-game-maker/scripts/cgm.py install-godot --with-export-templates
```

The installer uses a stable per-user cache rather than a versioned plugin directory, verifies archives against policy-pinned SHA-512 values before extraction, and writes an install manifest into that cache.

Preview the plan without changing the machine:

```bash
python3 plugins/codex-game-maker/scripts/cgm.py install-godot --dry-run
```

Detailed asset, import, and browser-preview commands remain under `plugins/codex-game-maker/tools/`. On macOS/Linux invoke their `.ps1` files through `pwsh`.

## Installation Verification

An installation is healthy when:

- `codex plugin list --marketplace codex-game-maker` reports the expected installed version and enabled status;
- a new task exposes the `codex-game-maker:` skills;
- the plugin package validator and every skill validator pass in the source checkout;
- required local dependencies are available for the selected workflow;
- Godot import/export commands run against the exact declared engine version when runtime or release evidence is claimed.

The repository's validators check structure and contract invariants. They do not prove that every generated game is fun, visually strong, commercially successful, platform-certified, or legally approved. Publish quality claims only with reproducible eval inputs, outputs, scoring rules, current build-bound evidence, and reviewer provenance.

## Intended 1.0 Boundary

Codex Game Maker 1.0 is scoped as Godot-first commercial **2D** production tooling. Existing 3D projects may reuse planning and release disciplines, but require external 3D pipelines. Console SDKs/certification, hosted backends, store accounts, signing credentials, ratings, legal approvals, and irreversible publishing remain conditional or external responsibilities owned by authorized people and providers.
