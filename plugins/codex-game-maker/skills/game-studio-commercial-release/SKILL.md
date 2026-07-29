---
name: game-studio-commercial-release
description: "Prepare and gate a game for real commercial release after player-ready passes. Use for release candidates, store submission, gold master, launch approval, commercial readiness audits, build evidence, platform certification, signing, compliance, performance, localization, accessibility, marketing, telemetry, support, and go/no-go decisions."
---

# Game Studio Commercial Release

Treat commercial release as a separate evidence gate. Never equate a playable build with a shippable product.

## Required Inputs

Read all applicable contracts and manifests under `production/`, `business/`, `design/`, `docs/`, and `marketing/`. Create missing commercial files from templates referenced by `../../references/workflows/catalog.yaml`.

## Release Sequence

1. Require `PLAYER_READY` with current runtime, visual, audio, controls, automated-command, and manual-playtest evidence.
2. Lock an approved `production/commercial-release-contract.json` with target platforms, stores, audience, business model, online/data features, languages, and release type.
3. Route product economics to `game-studio-business`.
4. Route native/store builds, signing, CI, and device matrices to `game-studio-platforms`.
5. Route licenses, privacy, ratings, terms, and platform declarations to `game-studio-compliance`.
6. Route measured budgets and stability to `game-studio-performance`.
7. Route accessibility, localization, narrative, marketing, online services, and live operations to their dedicated skills when applicable.
8. Run quality commands and the commercial gate. Fix blockers; do not downgrade them to launch notes.

```bash
python3 ../../scripts/cgm.py quality --root .
python3 ../../scripts/cgm.py commercial-release --root .
```

## Approval Boundary

Codex may prepare artifacts, builds, and evidence. It must not claim to supply legal advice, accept store agreements, create developer accounts, use signing credentials, publish paid products, or submit ratings without the authorized human owner. Record named owners, approval dates, and project-local evidence. `release-owner` and `legal-owner` are always required; commerce, store-account, signing, console-certification, privacy, and child-safety owners become mandatory from the declared contract.

Only call a build `RELEASE_CANDIDATE` when the commercial gate passes. Only call it `RELEASED` after store/platform acceptance and post-release monitoring are confirmed.
