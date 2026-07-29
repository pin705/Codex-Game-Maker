---
name: game-studio-art-assets
description: Build the visual identity and AI asset pipeline for a game. Use for art bible creation, asset manifests, GPT Image 2 prompt specs, generated image review, asset sourcing, and fixing unsatisfactory generated assets. Requires provenance records for project-bound generated assets.
---

# Game Studio Art Assets

Use this for visual direction and generated asset workflows.

## Required Context

Read if present:
- `design/gdd/game-concept.md`
- `design/gdd/systems-index.md`
- `design/art/art-bible.md`
- `design/assets/asset-manifest.yaml`
- `design/assets/asset-coverage.json`
- `production/reviews/visual-quality-contract.json`
- repo-local `../../references/policies/collaboration-policy.md` or installed-skill `../../references/policies/collaboration-policy.md`
- repo-local `../../references/templates/art-bible.md` or installed-skill `../../references/templates/art-bible.md`
- repo-local `../../references/templates/asset-prompt-spec.yaml` or installed-skill `../../references/templates/asset-prompt-spec.yaml`
- repo-local `../../references/templates/asset-coverage.json` or installed-skill `../../references/templates/asset-coverage.json`
- repo-local `../../references/policies/web-search-policy.md` or installed-skill `../../references/policies/web-search-policy.md`
- repo-local `../../scripts/guards/asset_gate.ps1` or installed-skill `../../scripts/guards/asset_gate.ps1`

If no art bible exists, create or draft `design/art/art-bible.md` before generating production assets.

## Asset Lifecycle

Use this lifecycle for project-bound assets:

1. Art bible and game-specific visual identity rule
2. Full asset coverage inventory
3. Look-dev set spanning every visual family that actually exists in the game, such as world, actors, FX and UI
4. Multiple candidates for generated/mixed look-dev, compared together in a runtime composite at target scale
5. Locked accepted references plus recorded rejected candidates and decision rationale
6. Family-aware asset brief and prompt spec
7. Production generation using the locked references, camera, lighting, scale, material and palette anchors
8. Post-process or slicing
9. Cross-family contact sheet and coherence review
10. Manifest, coverage and presentation-usage update
11. In-game integration and runtime verification
12. Asset and player-ready gates

Never leave a project-used generated asset only in Codex's default generated image directory. Move or copy accepted outputs into `assets/generated/`.

Before bulk generation, build a representative look-dev set from the visual families this game actually needs; do not use a fixed asset count or validate only a hero portrait while the shipped world and UI use unrelated styles. For generated or mixed art, compare at least two candidates, composite the candidates at actual runtime scale, reject weak/generic directions, and lock accepted project-local reference images in `production/reviews/visual-quality-contract.json`. Ask for confirmation unless the user already approved autonomous execution; in autonomous mode, record the selection and rejection evidence, then continue without routine approval pauses.

## Coverage Contract

For player-ready work, create `design/assets/asset-coverage.json` before bulk production. Derive groups from this game's state graph, system GDDs, art bible, UI inventory, feedback vocabulary, content boundary, and target-platform surfaces. Do not copy character/environment/UI/branding groups into a game where those concepts do not apply, and do not omit custom groups such as cards, vehicles, construction pieces, dialogue portraits, procedural materials, or live-event content when they do.

Set `coverage_policy.minimum_distinct_assets` to a justified game-specific floor and cite its `inventory_sources`. Every required group records a concrete `coverage_basis` and exhaustive `required_asset_ids`; every listed ID must have a matching asset row. Every required group and asset must move through `planned -> draft -> accepted -> integrated -> verified`. Each asset row records `path`, `provenance`, and one or more `runtime_refs`. `mock`, `placeholder`, `draft`, `generated`, or `accepted` alone never satisfies player-ready coverage. If a deliberately invisible or procedural asset is appropriate, record the rationale, rights/source decision, runtime references, and evidence instead of inventing a raster file requirement.

Every production asset also declares `presentation.source_kind` and one or more usages. Each usage maps to real state IDs, a runtime reference, render mode, rendered size, rationale and runtime composite evidence. Preserve aspect ratio for uniform/native assets. Use `nine-slice` only for a dedicated component with verified margins and tested minimum/maximum sizes; never promote a random prop-pack crop into a scalable panel. Cover/tile/sprite-frame modes need their crop-safe area, seam evidence or source frame size as applicable.

## Route Detailed Asset Work

Use this skill as the art direction and asset planning entrypoint. For production asset execution, route to the specialized core skills:

- `game-studio-sprite-assets`: characters, enemies, NPCs, props, projectiles, impacts, FX, sprite sheets, frame extraction, transparent PNGs, GIF previews, and Godot sprite import metadata.
- `game-studio-map-assets`: platformer stages, RPG maps, tower-defense maps, parallax layers, prop packs, collision/zones metadata, layered previews, and Godot scene handoff.
- `game-studio-asset-qa`: accepted asset quality checks, alpha/chroma-key validation, frame counts, edge cropping, metadata, and Godot import readiness.

Do not keep all asset production detail in the art bible. The art bible defines style and constraints; the specialized skills produce game-ready outputs.

## GPT Image 2 Rules

- Use Codex image generation for new raster assets.
- Save accepted assets under `assets/generated/<category>/`.
- Save prompt/provenance records under `assets/source-prompts/`.
- For transparency, prefer a flat chroma-key background plus local removal. Use true transparent CLI fallback only after user confirmation.
- For UI icons and sprites, specify target size, silhouette readability, padding, background/alpha needs, and "no text/no watermark" unless text is explicitly required.
- Runtime sprite and prop assets should use a solid chroma-key raw background and local post-processing to alpha. Default to `#FF00FF`, but choose a different key color when the subject uses magenta, pink, purple, or similar FX colors.
- Controllable hero multi-action assets must be generated per action first, QA'd, then assembled into delivery atlases only after each action passes.
- Playable maps must produce runtime data: separate objects, props, collision, zones, exits, camera bounds, or Godot-native nodes. Do not stop at one baked background unless the user asked for background-only art.
- UI assets must follow `design/ui/ui-ux-spec.md` and the art bible. A collection of generic rounded panels, web cards, default icons, or unrelated decorative images is not a coherent game UI kit.
- Carry the same locked identity anchors through environment, actor, FX, icon and UI prompts. Compare palette, lighting direction, edge treatment, detail density, camera/view, material response and runtime scale together; individually attractive assets that do not belong in the same game are rejected.
- Reject first-pass art that is merely detailed. Cheap visual signals include generic fantasy motifs, uncontrolled ornament, plastic bevels, inconsistent rendering density, AI pseudo-text, weak silhouettes, stretched frames, mismatched camera/light, tiny sprites in an oversized world and the same component pasted onto every surface.
- Asset generation is incomplete until accepted files are connected to actual scenes/resources and seen in current runtime evidence. A mockup may guide art direction but cannot prove integration.

## Web Search Triggers

Use web search when:
- The user says generated assets look bad, generic, off-style, or not fun.
- Asset needs are large and online references/open-source assets can reduce generation churn.
- You need official Godot import, texture, sprite sheet, tilemap, shader, or web export constraints.
- You need licensing-safe reference sources.

For resources, prefer official marketplaces, public domain/CC0 sources, creator pages with clear licenses, and official docs. Record source URLs in the asset prompt/provenance file when used.

## Output Files

Common outputs:
- `design/art/art-bible.md`
- `design/assets/asset-manifest.yaml`
- `design/assets/asset-coverage.json`
- `design/assets/godot-import-manifest.yaml`
- `design/assets/prompts/<asset-id>.md`
- `assets/source-prompts/<asset-id>.yaml`
- `assets/generated/<category>/<asset-id>-v001.png`
- `assets/generated/<category>/<asset-id>/sheet-transparent.png`
- `assets/generated/<category>/<asset-id>/frames/*.png`
- `assets/generated/<category>/<asset-id>/animation.gif`
- `assets/generated/<category>/<asset-id>/pipeline-meta.json`

Update `production/session-state/active.md` after each accepted asset batch.
Update `design/assets/asset-coverage.json` after acceptance, integration, and runtime verification; do not batch-mark unverified assets complete.

## Asset Gate

After accepting generated assets, run:

```powershell
../../tools/check-asset-gate.ps1 -Root .
```

For production-ready asset QA, run:

```powershell
../../tools/check-asset-qa.ps1 -Root .
```

The gate should pass before a demo/review when accepted generated assets exist. It checks:
- accepted files are under `assets/generated/`
- accepted files are referenced by `design/assets/asset-manifest.yaml`
- prompt/provenance files exist under `assets/source-prompts/`
- generated files are not orphaned outside the manifest
- accepted runtime assets have raw source, processed output, and `pipeline-meta.json`
- sprite assets have frames, GIF preview, alpha, frame count, and chroma-key cleanup evidence
- map assets have preview, props metadata, collision/zones metadata when gameplay requires them
- Godot projects have import intent recorded

When `production/player-ready-contract.md` exists, also run:

```bash
python3 ../../scripts/guards/player_ready_gate.py --root .
```

Any incomplete required coverage group, missing integrated path, or missing runtime evidence blocks `PLAYER_READY` even when the legacy asset gate passes.
