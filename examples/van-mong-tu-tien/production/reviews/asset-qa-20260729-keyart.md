# Asset QA Report: Vân Mộng Tu Tiên / KEYART-001

Status: Complete  
Gate: PASS_WITH_WARNINGS  
Date: 2026-07-29  
Reviewer: Codex Game Maker

## Evidence

Read:

- `design/art/art-bible.md`
- `design/assets/asset-manifest.yaml`
- `design/assets/godot-import-manifest.yaml`
- `assets/source-prompts/KEYART-001.yaml`
- `assets/generated/key-art/KEYART-001-pipeline-meta.json`

Ran:

- `sips` dimension checks → raw `1672x941`, processed `1280x720`, preview `320x180`.
- SHA-256 checks → raw and processed hashes recorded in pipeline metadata.
- Godot 4.4 import/runtime load → WebP imported and rendered in native title capture.
- Visual review at full size and 320x180 intent → readable hero/monster, clean upper-left title-safe zone, no text/logo/watermark.

Could not verify:

- Repository PowerShell asset gate/QA scripts because `pwsh` is unavailable.

## Blockers

- None.

## Warnings

- Eight swords are visually distinct instead of the nine requested; accepted because this is decorative title art, not a gameplay-frame contract.
- The retained intermediate 1280x720 PNG is larger than the target; runtime uses the processed 154,912-byte WebP.

## Key-Art QA

- [x] Prompt/provenance exists.
- [x] Raw source exists under `assets/raw/`.
- [x] Accepted source and processed output live under `assets/generated/`.
- [x] Processed 1280x720 WebP and 320x180 preview exist.
- [x] Pipeline metadata, dimensions, hashes and provider are recorded.
- [x] No visible generated text, watermark or copied IP target.
- [x] Godot import intent and optional fallback behavior are recorded.
- [x] Runtime capture proves aspect-covered title use at target size.

Sprite QA: not applicable; gameplay sprites are procedural.  
Map QA: not applicable; arena visuals/runtime data are procedural.

## Decision

Ready for in-game use: **Yes, as optional title presentation.**  
Next action: keep runtime bound to the 1280x720 WebP and retain procedural fallback.

