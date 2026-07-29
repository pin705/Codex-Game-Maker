---
name: game-studio-liveops
description: "Prepare and operate a released game. Use for telemetry schemas, privacy-safe analytics, crash reporting, dashboards, alerts, incident response, rollback, patch cadence, save migrations, remote configuration, customer support, community/review handling, status communication, backups, service levels, and post-launch retrospectives."
---

# Game Studio LiveOps

Design operations before launch so failures have owners, signals, and reversible responses.

## Required Outputs

- `production/liveops-plan.md` from `../../references/templates/liveops-plan.md`
- `production/telemetry-crash-plan.md` from `../../references/templates/telemetry-crash-plan.md`
- runbooks and evidence under `production/evidence/liveops/`

## Workflow

1. Define launch KPIs that answer product/quality questions without collecting unnecessary personal data.
2. Version event schemas; document purpose, fields, consent basis, retention, sampling, and owners.
3. Integrate crash/error reporting with build, platform, stack, reproduction breadcrumbs, symbol handling, and privacy filtering.
4. Define dashboards, alert thresholds, on-call owner, severity, communication channels, incident timeline, rollback, and hotfix paths.
5. Test rollback, save migration, remote-config kill switches, backup/restore, degraded service, and support escalation before launch.
6. Prepare support FAQs, known issues, accessibility contact path, refund/escalation boundaries, and respectful community/review practices.
7. Run launch-day and post-launch reviews; turn evidence into prioritized patches rather than vanity metrics.

Online/live-service commercial release blocks without monitoring, incident ownership, rollback, support, and tested recovery.
