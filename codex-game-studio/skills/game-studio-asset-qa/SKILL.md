---
name: game-studio-asset-qa
description: "Validate Codex Game Maker generated 2D assets. Use for checking accepted sprite sheets, transparent PNGs, frames, GIF previews, prop packs, layered map previews, pipeline metadata, chroma-key cleanup, edge cropping, Godot import readiness, and asset gate failures."
---

# Game Studio Asset QA

Use this before generated assets enter gameplay, demos, review, or release.

## Required First Step

Run:

```powershell
../../../tools/check-asset-qa.ps1 -Root .
```

For any accepted runtime sprite, platform, large prop, map object, or collision-bearing asset, also run the harness gate against the raw image:

```powershell
../../../tools/check-asset-harness.ps1 -Spec <harness.json> -Input <raw.png>
```

Also run `../../../tools/check-asset-tools.ps1` if Python processors or dependencies may be missing.

When QA failures are processor-level issues such as chroma-key residue or safe-padding edge touch, run a dry repair pass before asking the user to regenerate:

```powershell
../../../tools/repair-asset-processing.ps1 -Root .
```

Apply only deterministic repairs:

```powershell
../../../tools/repair-asset-processing.ps1 -Root . -Apply
```

## Context To Read

Read if present:
- `design/assets/asset-manifest.yaml`
- `design/assets/godot-import-manifest.yaml`
- `assets/source-prompts/**`
- `design/assets/harnesses/**`
- `assets/generated/**/pipeline-meta.json`
- `production/reviews/*.md`
- `../../references/templates/asset-qa-report.md`

## QA Checks

For accepted assets:
- prompt/provenance file exists
- raw source file exists
- processed output exists
- pipeline metadata exists
- selected files are under `assets/generated/`
- no accepted file points to Codex temporary generated-image folders

For sprite assets:
- harness spec exists for runtime sprites
- raw sheet passes exact canvas, grid, cell size, safe-zone, edge-guard, and foot-line checks
- transparent output has alpha
- expected frame count matches extracted frames
- frames directory exists
- GIF preview exists
- visible chroma-key residue is zero or explained
- edge-touch warnings are reviewed
- frame size, pivot/anchor, and Godot import target are recorded
- playable character frames have no edge-touch warnings
- run/walk GIF previews are reviewed for loop seams, foot sliding, body scale drift, and pose popping
- jump/fall/land frames are mapped to runtime state phases instead of being blindly looped
- normalized runtime frames exist when the same character uses multiple actions

For map assets:
- collision-critical platform/prop/object raw images pass their harness checks
- QA preview exists
- props/object metadata exists when the map is playable
- collision/zones metadata exists when gameplay needs collision or triggers
- Godot import manifest exists for Godot projects
- collision visuals are not rendered as debug rectangles in the playable scene
- platforms and large props are not stretched into mismatched aspect ratios unless they are designed as nine-slice/tileable assets
- large or collision-critical platforms are generated as dedicated pieces or tileable segments, not extracted from a cramped square prop pack

## Outcomes

- `PASS`: accepted assets have source, processed outputs, metadata, and QA evidence.
- `PASS_WITH_WARNINGS`: usable but missing non-critical previews, optional Godot import notes, or edge warnings.
- `BLOCKED`: accepted runtime asset lacks prompt, processed output, metadata, frame outputs, or required map/collision deliverables.

Use repair for cleanup parameters only. Regenerate instead when identity drifts, the raw sheet contains mixed actions, required frames are missing, the background is not flat, the raw art is severely cropped, or the GIF preview shows a broken gameplay loop.
Regenerate instead of repairing when the harness report blocks on canvas size, cell size, safe-zone exits, neighbor-frame fragments, platform crop, foot-line drift, or scale drift.

Write `production/reviews/asset-qa-[YYYYMMDD-HHMM].md` only when the user asks for a formal report or before release/demo handoff.


