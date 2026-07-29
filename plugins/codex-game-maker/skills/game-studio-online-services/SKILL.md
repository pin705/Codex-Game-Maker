---
name: game-studio-online-services
description: "Design and verify secure game backends, multiplayer, accounts, cloud saves, matchmaking, leaderboards, commerce entitlements, remote config, and networked gameplay. Use when a game sends data, requires servers, supports online identity, or needs abuse, cheat, privacy, load, backup, and outage controls."
---

# Game Studio Online Services

Any network dependency expands the commercial, security, privacy, cost, and operations scope.

## Required Outputs

- `docs/online/online-services-plan.md` from `../../references/templates/online-services-plan.md`
- `docs/security/threat-model.md` from `../../references/templates/security-threat-model.md`
- load, failure, backup, and restore evidence under `production/evidence/online/`

## Workflow

1. Define authoritative ownership, trust boundaries, protocols, data model, identity, session lifecycle, regional needs, and offline degradation.
2. Keep secrets and privileged decisions server-side. Validate inputs, authorization, replay resistance, rate limits, and abuse reporting.
3. Define save conflict/versioning, entitlement verification, idempotency, migration, deletion/export, retention, and audit behavior.
4. Model concurrency, cost, latency, capacity, DDoS/provider failure, maintenance, and disaster recovery.
5. Test packet loss, disconnect/reconnect, duplicated/out-of-order messages, clock drift, server restart, partial outage, load, backup, and restore.
6. Feed data collection into compliance and operational signals into live-ops.

Block release on client-trusted purchases/results, exposed secrets, missing authorization, untested restore, no outage behavior, unknown data handling, or capacity below the declared launch envelope.
