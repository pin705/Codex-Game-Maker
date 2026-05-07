---
name: game-studio-asset-qa
description: "Validate Codex Game Maker generated 2D assets. Use for checking accepted sprite sheets, transparent PNGs, frames, GIF previews, prop packs, layered map previews, pipeline metadata, chroma-key cleanup, edge cropping, Godot import readiness, and asset gate failures."
---

# Game Studio Asset QA

Use this before generated assets enter gameplay, demos, review, or release.

## Required First Step

Run:

```powershell
tools/check-asset-qa.ps1 -Root .
```

Also run `tools/check-asset-tools.ps1` if Python processors or dependencies may be missing.

When QA failures are processor-level issues such as chroma-key residue or safe-padding edge touch, run a dry repair pass before asking the user to regenerate:

```powershell
tools/repair-asset-processing.ps1 -Root .
```

Apply only deterministic repairs:

```powershell
tools/repair-asset-processing.ps1 -Root . -Apply
```

## Context To Read

Read if present:
- `design/assets/asset-manifest.yaml`
- `design/assets/godot-import-manifest.yaml`
- `assets/source-prompts/**`
- `assets/generated/**/pipeline-meta.json`
- `production/reviews/*.md`
- `codex-game-studio/references/templates/asset-qa-report.md`

## QA Checks

For accepted assets:
- prompt/provenance file exists
- raw source file exists
- processed output exists
- pipeline metadata exists
- selected files are under `assets/generated/`
- no accepted file points to Codex temporary generated-image folders

For sprite assets:
- transparent output has alpha
- expected frame count matches extracted frames
- frames directory exists
- GIF preview exists
- visible chroma-key residue is zero or explained
- edge-touch warnings are reviewed
- frame size, pivot/anchor, and Godot import target are recorded

For map assets:
- QA preview exists
- props/object metadata exists when the map is playable
- collision/zones metadata exists when gameplay needs collision or triggers
- Godot import manifest exists for Godot projects

## Outcomes

- `PASS`: accepted assets have source, processed outputs, metadata, and QA evidence.
- `PASS_WITH_WARNINGS`: usable but missing non-critical previews, optional Godot import notes, or edge warnings.
- `BLOCKED`: accepted runtime asset lacks prompt, processed output, metadata, frame outputs, or required map/collision deliverables.

Use repair for cleanup parameters only. Regenerate instead when identity drifts, the raw sheet contains mixed actions, required frames are missing, the background is not flat, or the raw art is severely cropped.

Write `production/reviews/asset-qa-[YYYYMMDD-HHMM].md` only when the user asks for a formal report or before release/demo handoff.


