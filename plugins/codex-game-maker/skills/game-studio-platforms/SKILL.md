---
name: game-studio-platforms
description: "Build, package, sign, test, and submit Godot games for declared target platforms. Use for Web, Windows, macOS, Linux, Android, iOS, Steam, custom storefronts, CI/CD build matrices, export presets, signing/notarization, store SDKs, platform services, device coverage, and certification evidence."
---

# Game Studio Platforms

Build each target independently; one successful Web export does not prove another platform.

## Required Outputs

- `production/build-matrix.json` from `../../references/templates/build-matrix.json`
- `production/quality-command-manifest.json` from `../../references/templates/quality-command-manifest.json`
- platform evidence under `production/evidence/platforms/`

## Workflow

1. Read the commercial release contract and select only declared targets.
2. Verify current engine/export/store requirements from official documentation at release time.
3. Create reproducible debug, release, and symbol-bearing build commands in CI. Keep credentials in the CI/store secret manager, never in the repo or evidence logs.
4. Configure package identifiers, versions, icons, permissions, architecture, renderer, save paths, and platform services.
5. Sign/notarize where required. Record certificate identity and result without private keys.
6. Test clean install, upgrade, uninstall/reinstall, first boot, suspend/resume, controller/device changes, offline behavior, save compatibility, and crash recovery.
7. Record artifact hashes, sizes, command outputs, device/OS coverage, store review state, and owner approval. The build command's `expected_artifacts` must include the exact release artifact so quality evidence and the build-matrix SHA-256 converge on the same file.
8. Record the official HTTPS requirements source and verification date; refresh it when older than 180 days.

## Target Rules

- Web: browser matrix, HTTPS/cross-origin assumptions, persistent storage, focus/audio unlock, memory/threading limits.
- Windows/macOS/Linux: clean-machine launch, architecture, dependencies, signing decision, save/log paths, display/controller matrix.
- Android/iOS: current target SDK, package identity, signing, permissions, lifecycle, thermal/memory, touch, store declarations.
- Steam: depot/build, store page, capsules, controller claims, cloud/achievements only when integrated, review readiness.
- Console: block until the authorized developer has SDK access, platform documentation, credentials, and certification evidence.

Never invent a platform pass from an artifact filename. Require a current build, smoke result, and target-device evidence.
