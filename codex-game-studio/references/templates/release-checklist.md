# Release Checklist: [Version]

Status: Draft
Version:
Build commit/hash:
Targets/stores:
Owner:
Gate: [PASS | BLOCKED]

## Player-Ready Evidence

- [ ] Shell-free quality commands passed on the current code fingerprint.
- [ ] Player-ready gate passed with valid distinct runtime media.
- [ ] Manual playtest, visual review, and audio listening review passed.

## Build Evidence

- [ ] Every declared target has a current artifact hash.
- [ ] Build and smoke command IDs passed.
- [ ] Target-device/OS/browser coverage is recorded.
- [ ] Signing/notarization/package identity is verified where required.
- [ ] Store review package is submission-ready.

## Commercial Readiness

- [ ] Product/business and monetization decisions are approved.
- [ ] Performance budgets pass on current artifacts.
- [ ] Asset/dependency rights, AI provenance, notices, privacy/data, ratings, platform terms, commerce, and secrets checks pass.
- [ ] Localization and accessibility conformance pass for release scope.
- [ ] Store assets and claims match the current build.
- [ ] Telemetry/crash, support, incident, rollback, save migration, and post-launch ownership are ready.
- [ ] Online security/load/backup/restore evidence passes when applicable.

## External Approvals

| Approval | Owner | Status | Dated evidence |
|---|---|---|---|

## Player-Facing Notes

Release summary:
Known issues/waivers:
Download/store link:

## Gate Results

Command: `python3 scripts/cgm.py commercial-release --root .`
Report: `production/evidence/commercial-release-gate.json`
