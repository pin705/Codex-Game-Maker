# Changelog

## Unreleased

- Replaced fixed title/onboarding/gameplay/pause/settings/victory/defeat assumptions with a schema-v2, game-specific directed state graph covering custom journeys, completion states, recovery paths, experience requirements, and per-journey commands.
- Replaced fixed asset groups, Godot Theme-only UI, fixed audio event IDs, and fixed evidence check IDs with game-specific coverage contracts while preserving strict integration/evidence validation.
- Added adversarial graph tests, including an endless sandbox without conventional state names, an unreachable-state failure case, and rejection of the legacy fixed dictionary; the suite now contains 14 gate tests.
- Added semantic CI guards that prevent fixed state/group/audio constants from returning and require routing skills to reference the dynamic journey contract.
- Removed the duplicate `codex-game-studio/`, root `tools/`, and root asset-requirements copies. `plugins/codex-game-maker/` is now the only implementation source of truth.
- Added an evidence-backed commercial studio workflow spanning product/business planning, platforms, performance, compliance, localization, accessibility, narrative, online services, marketing, telemetry, support, live operations, and rollback.
- Added 11 commercial specialist skills, bringing the plugin to 23 skills.
- Added `cgm.py`, a cross-platform CLI for diagnostics, command-backed quality evidence, player-ready validation, commercial release validation, Godot installation, and exports.
- Added a strict `commercial_release_gate.py` and strengthened `player_ready_gate.py` with real media validation, asset provenance/runtime references, project fingerprints, artifact hashes, visual/audio reviews, and linked manual playtest evidence.
- Added commercial release, build matrix, performance, compliance, localization, accessibility, marketing, online/security, telemetry, narrative, business, and live-operations templates.
- Added a verified Godot version policy recommending 4.7.1 and supporting the 4.6/4.7 release lines.
- Added 20 studio aliases and deterministic mappings for quality, player-ready, and commercial release commands.
- Hardened the player-ready gate with mandatory onboarding, approved non-placeholder design docs, a real Godot Theme resource, explicit required-asset inventories, distinct art/audio coverage, supported-engine probing, project-local evidence, structural PNG checks, and SHA-256-bound visual/audio/playtest reviews.
- Hardened the quality runner against unsafe IDs, shell snippets, no-op commands, empty evidence, out-of-project artifacts, stale command rows, unsupported timeouts, and mismatched commercial engine probes.
- Added an end-to-end `game-studio-build` workflow that treats broad build requests as bounded player-ready work instead of stopping at a prototype.
- Added dedicated Godot implementation, game-native UI/UX, and audio skills.
- Added state, asset-coverage, UI, audio, player-ready contract, and evidence templates.
- Added the cross-platform `player_ready_gate.py` guard for complete states, integrated assets, UI/audio coverage, tests, captures, and manual playtest evidence.
- Added `/player-ready`; enabled focused UI, level, combat, audio, and accessibility passes.

## 0.1.0-alpha

- Added Codex Game Maker public branding.
- Added Godot 4.4 install, register, Web export, and browser preview tools.
- Added GPT Image-ready sprite sheet processing, prop pack slicing, layered map preview, metadata, and GIF previews.
- Added action bundle planning and batch processing.
- Added deterministic asset QA repair.
- Added Godot sprite and map import helpers.
- Added lightweight production, story, release, asset, Godot lint, and review gates.
- Added optional professional command aliases and git hooks.
