---
name: game-studio-asset-qa
description: "Validate Codex Game Maker generated 2D assets and their in-game presentation. Use for accepted sprite sheets, transparent PNGs, frames, GIF previews, prop packs, layered maps, pipeline metadata, chroma-key cleanup, edge cropping, style/coherence drift, cheap or generic art, distorted scaling, nine-slice/crop/tile misuse, runtime composition, Godot import readiness, and asset gate failures."
---

# Game Studio Asset QA

Use this before generated assets enter gameplay, demos, review, or release.

## Required First Step

Run:

```powershell
../../tools/check-asset-qa.ps1 -Root .
```

Also run `python3 ../../scripts/cgm.py style-lock verify --root .`. A technically valid asset is blocked when its prompt, manifest entry, pipeline metadata, family contact sheet, or runtime usage is not bound to the current style digest.

For any accepted runtime sprite, platform, large prop, map object, or collision-bearing asset, also run the harness gate against the raw image:

```powershell
../../tools/check-asset-harness.ps1 -Spec <harness.json> -Input <raw.png>
```

Also run `../../tools/check-asset-tools.ps1` if Python processors or dependencies may be missing.

When QA failures are processor-level issues such as chroma-key residue or safe-padding edge touch, run a dry repair pass before asking the user to regenerate:

```powershell
../../tools/repair-asset-processing.ps1 -Root .
```

Apply only deterministic repairs:

```powershell
../../tools/repair-asset-processing.ps1 -Root . -Apply
```

## Context To Read

Read if present:
- `design/art/art-bible.md`
- `design/art/style-lock.json`
- `production/session-state/active.md`
- `design/assets/asset-manifest.yaml`
- `design/assets/godot-import-manifest.yaml`
- `assets/source-prompts/**`
- `design/assets/harnesses/**`
- `assets/generated/**/pipeline-meta.json`
- `production/reviews/*.md`
- `production/reviews/visual-quality-contract.json`
- `../../references/templates/asset-qa-report.md`

## QA Checks

For accepted assets:
- prompt/provenance file exists
- raw source file exists
- processed output exists
- pipeline metadata exists
- selected files are under `assets/generated/`
- no accepted file points to Codex temporary generated-image folders
- every asset has a presentation source kind and runtime usages tied to declared state IDs
- uniform/native/sprite-frame uses preserve the authored aspect ratio
- nine-slice assets are dedicated components with valid margins and tested size ranges
- tiled and cover assets have seam or crop-safe evidence
- every usage is visible in a current runtime composite

For cross-asset quality:
- compare the complete visible family, not isolated source files
- verify camera/view, light direction, palette roles, material language, edge treatment and detail density agree
- verify actors, props and FX read at their real runtime scale against the world
- reject generic first-pass art, inconsistent AI styles, repeated one-size-fits-all panels, text/ornament collisions, stretched frames and decorative density that destroys hierarchy
- keep blocker/high findings open until the affected runtime captures are replaced

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

- `PASS`: accepted assets have source, processed outputs, metadata, presentation usages, cross-family coherence, and current runtime QA evidence.
- `PASS_WITH_WARNINGS`: usable but missing non-critical previews, optional Godot import notes, or edge warnings.
- `BLOCKED`: accepted runtime asset lacks prompt, processed output, metadata, frame outputs, or required map/collision deliverables.

Use repair for cleanup parameters only. Regenerate instead when identity drifts, the raw sheet contains mixed actions, required frames are missing, the background is not flat, the raw art is severely cropped, the GIF preview shows a broken gameplay loop, or the asset looks cheap/off-style beside the locked look-dev references.
Regenerate instead of repairing when the harness report blocks on canvas size, cell size, safe-zone exits, neighbor-frame fragments, platform crop, foot-line drift, or scale drift.

Write `production/reviews/asset-qa-[YYYYMMDD-HHMM].md` only when the user asks for a formal report or before release/demo handoff.
