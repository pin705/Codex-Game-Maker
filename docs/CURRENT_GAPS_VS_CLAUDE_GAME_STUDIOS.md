# Current Gaps vs Claude Code Game Studios

Date: 2026-05-06

Reference: https://github.com/Donchitos/Claude-Code-Game-Studios

## Current Codex Game Maker Coverage

Implemented:

- Lean skill set: 8 skills.
- Lean role model: 6 review lenses instead of many runtime agents.
- Godot-first engine detection.
- Godot 4.4 local installer and PATH setup.
- Cross-platform helper for Windows/macOS/Linux OS detection, PowerShell invocation, Godot discovery, and export template paths.
- Godot export template installer.
- Godot Web export and local browser preview.
- Guided kickoff brief before broad implementation.
- Concept, system GDD, art bible, asset prompt, architecture, ADR, control manifest templates.
- Game-ready 2D asset pipeline for sprites, prop packs, layered map previews, transparent frames, GIF previews, and `pipeline-meta.json`.
- Generated asset manifest/provenance/runtime QA gate.
- Small implementation story template and story gate.
- Godot generated-code lint gate.
- Lightweight production templates and production gate.
- Smoke/regression QA templates wired into review gate.
- Review/QA gate with playtest evidence templates.
- Optional professional git hooks.
- Professional command alias registry for `/release`, `/team-ui`, `/audio-pass`, and related advanced modes.
- Lightweight release templates and release gate behind `/release` and `/hotfix`.
- Global Codex skill installer.
- Web search policy for official docs, engine mismatch, asset dissatisfaction, and version/API uncertainty.

Current counts:

- Skills: 8
- Guard scripts: 7
- Tool scripts: 29
- Helper scripts: 2
- Asset processors/workflows: 2
- Templates: 30
- Policies: 3
- Rules: 2

## Major Source Features Not Yet Implemented

### 1. Production Planning

Implemented lightly:

- Epic template.
- Sprint plan/status templates.
- Production gate for epics, sprints, and stories.
- One-story-at-a-time `implementation-story.md`.
- `check-story-gate.ps1` for Ready/Done checks.
- `check-production-gate.ps1` for lightweight epic/sprint structure.

Still missing:

- Automatic epic generation from GDD/ADR.
- Story batch generation from GDD/ADR.
- Milestone review.
- Retrospective.
- Estimates.

Recommended next:

- Add milestone review and retrospective templates only after real user projects need them.

### 2. Release Management

Implemented lightly:

- Release checklist template.
- Changelog template.
- Patch notes template.
- Hotfix report template.
- `check-release-gate.ps1`.
- `/release` and `/hotfix` are available professional-mode aliases.

Still missing:

- Platform-specific launch checklist.
- Store page metadata workflow.
- Full hotfix branch/release automation.

Recommended next:

- Keep release workflow template-driven until a real public release needs platform-specific steps.

### 3. QA Depth

Implemented lightly:

- Smoke test template.
- Regression checklist template.
- Review gate checks smoke evidence and story/review evidence.
- Godot lint gate catches common generated-code risks.

Still missing:

- Automated regression suite.
- Soak test.
- Test setup and helpers.
- Test flakiness workflow.

Current replacement:

- `review_gate.ps1`
- `story_gate.ps1`
- `godot_lint_gate.ps1`
- `playtest-evidence.md`
- `smoke-test.md`
- `regression-checklist.md`

Recommended next:

- Keep QA light until a real Godot project needs more automation.

### 3a. Runtime Asset Pipeline

Detailed plan: `docs/ASSET_PIPELINE_COMPLETION_PLAN.md`

Implemented:

- `game-studio-sprite-assets` for character/enemy/NPC/prop/FX sprite sheets.
- `game-studio-map-assets` for platform/RPG/tower-defense maps, parallax layers, props, collision, and zones.
- `game-studio-asset-qa` for alpha, frame count, chroma-key cleanup, metadata, and Godot import readiness.
- Local processor for configurable chroma-key cleanup, transparent output, sprite frame extraction, prop pack slicing, GIF preview, layered map preview, and `pipeline-meta.json`.
- Tool wrappers: `check-asset-tools.ps1`, `suggest-key-color.ps1`, `process-sprite-sheet.ps1`, `process-prop-pack.ps1`, `compose-layered-map-preview.ps1`, `check-asset-qa.ps1`.
- Action bundle wrapper: `create-action-bundle.ps1`.
- Deterministic repair wrapper: `repair-asset-processing.ps1`.
- Godot import wrappers: `import-sprite-to-godot.ps1`, `import-map-to-godot.ps1`.
- Reference variant and showcase wrappers: `create-reference-variant-spec.ps1`, `create-playable-showcase.ps1`.
- Asset gate now checks accepted runtime assets for prompt/provenance, raw file, processed output, metadata, sprite frames, GIF preview, alpha, chroma-key residue, map preview, collision/zones metadata, and Godot import manifest coverage.

Still missing:

- Direct GPT Image API orchestration around generation jobs.
- Full visual model job queue, retry, and cost tracking around action bundle generation.
- Godot CLI validation that generated `.tres`/`.tscn` loads cleanly in editor.
- Rich parallax scene writing beyond basic visual/prop/collision/zone handoff.
- Reference-image visual drift scoring.
- A polished playable showcase with generated final art and Web export evidence.
- Visual similarity or animation smoothness scoring.
- TexturePacker/Aseprite import/export integrations.

Decision:

- Keep the processor self-contained and deterministic. It should prepare image outputs for Godot, not replace Godot scene authoring.
- Prioritize the asset completion plan before adding multilingual README, branding, or release marketing material.

### 4. Path-Scoped Code Rules

Implemented lightly:

- `godot_lint_gate.ps1` checks unused `delta`, hardcoded gameplay tuning, missing `res://` paths, naming mismatch, UI/gameplay coupling, and Web export preset status.

Still missing:

- Full path-scoped rules for gameplay/core/AI/network/UI/test/prototype folders.
- Required design doc section checks.
- AST-level GDScript analysis.

Recommended next:

- Add more heuristics only when false positives/false negatives appear in real projects.

### 5. Hook Automation

Implemented as optional professional mode:

- `install-professional-hooks.ps1`
- `uninstall-professional-hooks.ps1`
- pre-commit lightweight checks: asset/story/Godot lint.
- pre-push heavier checks: review gate and optional Web export.

Still missing:

- Post-write asset validation.
- Session start/stop hooks.
- Pre/post compaction reminders.
- Notification hook.
- Agent audit trail.
- Skill change reminder hook.

Decision:

- Keep hooks optional. Do not enable them in the default flow.

### 6. Team Orchestration

Missing:

- Team workflows such as combat, UI, level, audio, narrative, release, polish, QA, live ops.
- Multi-agent delegation templates.
- Domain ownership boundaries for parallel workers.

Current replacement:

- Six review lenses in one Codex workflow.
- Professional command aliases in `references/commands/catalog.yaml`.

Decision:

- Keep optional. Only add if users explicitly trigger `/team-*` professional modes.

### 7. Specialist Domains

Missing or only lightly covered:

- Audio direction.
- Narrative design.
- Localization.
- Accessibility.
- UX/interface design.
- Economy/balance deep checks.
- Analytics/live ops/community.
- Security/networking.

Current replacement:

- These can be reviewed under Creative/Game Design/Technical/QA lenses.
- Professional aliases exist for audio, narrative, localization, and accessibility passes.

Decision:

- Add first-class workflows only when real user projects need them.

### 8. Engine Breadth

Missing:

- Unity specialist workflows.
- Unreal specialist workflows.
- Engine-specific rules for Unity/Unreal.

Current replacement:

- Existing Unity/Unreal projects are detected and respected, but blank projects default to Godot 4.4.

Decision:

- Intentional. Codex Game Maker is Godot-first.

### 9. Skill Testing Framework

Missing:

- Machine-readable coverage specs for every skill.
- Skill quality rubric.
- Fixtures.
- Automated skill-test and skill-improve workflows.

Current replacement:

- `quick_validate.py` validation and manual script tests.

Recommended next:

- Add a lightweight `tools/check-skills.ps1` before adding many more skills.

### 10. Upgrade / Distribution Polish

Implemented:

- `UPGRADING.md`.
- `docs/PROJECT_MIGRATION.md`.

Still missing:

- Release notes flow.
- Marketplace packaging checklist.
- Versioned migration rules.

Current replacement:

- `docs/OPEN_SOURCE_INSTALLATION.md`
- global skill installer
- `.codex-plugin/plugin.json`
- `UPGRADING.md`
- `docs/PROJECT_MIGRATION.md`

Recommended next:

- Add `CHANGELOG.md`, release notes flow, and marketplace packaging checklist before public release.

### 11. Cross-Platform Runtime Proof

Implemented in scripts:

- `codex-game-studio/scripts/lib/cgs_platform.ps1`.
- Tool wrappers call nested scripts through the detected PowerShell executable.
- Godot install/download paths are selected for Windows, macOS, and Linux.
- Godot lookup checks `GODOT_BIN`, repo-local `.tools/godot`, PATH, and common OS locations.
- Export template paths are OS-aware.
- Professional hooks prefer `pwsh` and only use Windows execution-policy flags on Windows-style Git shells.

Still missing:

- Real macOS install/export smoke test.
- Real Linux install/export smoke test.
- CI matrix for script parser and lightweight gates.

Recommended next:

- Test `pwsh -File tools/check-install.ps1` and `pwsh -File tools/install-godot.ps1 -WithExportTemplates` on macOS/Linux before public release.

## Deliberately Not Copied

These are intentionally not priorities:

- 49 runtime agents.
- 72 slash commands as the default UX.
- Large team workflows by default.
- Unity/Unreal parity in v0.1.
- Mandatory hook system.

Reason:

Codex Game Maker should stay approachable and Godot-first. The first version should help users make and preview games, not maintain a large process framework.

## Suggested Next Build Order

1. Run real Godot install + export templates + Web preview on the sample project on Windows.
2. Run the same Godot install/export/browser preview path on macOS and Linux.
3. Add optional professional mode templates for `/team-ui`, `/team-level`, and `/audio-pass`.
4. Add lightweight skill self-test coverage.
5. Add optional session-state helpers after real user testing.


