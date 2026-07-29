---
name: game-studio-compliance
description: "Prepare and verify commercial game compliance. Use for asset and dependency licenses, AI provenance, privacy/data inventories, consent, children and age-related rules, content ratings, EULA/terms, open-source notices, accessibility/store declarations, refund/commerce rules, regional requirements, and legal-review evidence."
---

# Game Studio Compliance

Create evidence and surface risk; do not impersonate legal counsel or a rating/store authority.

## Required Outputs

- `production/compliance-manifest.json` from `../../references/templates/compliance-manifest.json`
- `docs/legal/third-party-notices.md`
- `docs/legal/data-inventory.md`
- external approvals/evidence under `production/evidence/compliance/`

## Workflow

1. Inventory every code dependency, font, image, audio, video, dataset, generated asset, SDK, service, trademark, and external reference.
2. Record license, source, commercial-use basis, attribution, modification rules, redistribution obligations, and provenance.
3. Inventory data collected, generated, stored, transmitted, retained, deleted, and shared by the game and third-party SDKs.
4. Determine required privacy policy, consent, age/children safeguards, content rating, commerce disclosures, export declarations, and regional reviews from current official sources.
5. Ensure store declarations match runtime behavior. A “no data collected” claim must be verified against every SDK and network call.
6. Obtain dated owner/counsel approval for items marked `external_approval_required`. Do not leave `external_approvals` empty: the commercial gate derives mandatory owner IDs from the platform, store, business model, data practices, and audience.

## Blockers

Unknown asset rights, unapproved SDKs, missing privacy/data declarations, inaccurate ratings, missing required notices, secrets in source, or unresolved legal review block commercial release. A URL alone is not evidence of permission; record the applicable license and artifact version.
