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
- repo-local `codex-game-studio/references/policies/collaboration-policy.md` or installed-skill `references/policies/collaboration-policy.md`
- repo-local `codex-game-studio/references/templates/art-bible.md` or installed-skill `references/templates/art-bible.md`
- repo-local `codex-game-studio/references/templates/asset-prompt-spec.yaml` or installed-skill `references/templates/asset-prompt-spec.yaml`
- repo-local `codex-game-studio/references/policies/web-search-policy.md` or installed-skill `references/policies/web-search-policy.md`
- repo-local `codex-game-studio/scripts/guards/asset_gate.ps1` or installed-skill `scripts/guards/asset_gate.ps1`

If no art bible exists, create or draft `design/art/art-bible.md` before generating production assets.

## Asset Lifecycle

Use this lifecycle for project-bound assets:

1. Art bible
2. Asset brief
3. Prompt spec
4. Draft generation
5. Human pick
6. Post-process or slicing
7. Manifest update
8. In-game or mockup verification
9. Asset gate

Never leave a project-used generated asset only in Codex's default generated image directory. Move or copy accepted outputs into `assets/generated/`.

Before generating many assets, pause with a short asset brief and ask for confirmation. If the user wants speed, generate only a small first batch, usually 1-3 assets, before scaling up.

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
- `design/assets/godot-import-manifest.yaml`
- `design/assets/prompts/<asset-id>.md`
- `assets/source-prompts/<asset-id>.yaml`
- `assets/generated/<category>/<asset-id>-v001.png`
- `assets/generated/<category>/<asset-id>/sheet-transparent.png`
- `assets/generated/<category>/<asset-id>/frames/*.png`
- `assets/generated/<category>/<asset-id>/animation.gif`
- `assets/generated/<category>/<asset-id>/pipeline-meta.json`

Update `production/session-state/active.md` after each accepted asset batch.

## Asset Gate

After accepting generated assets, run:

```powershell
tools/check-asset-gate.ps1 -Root .
```

For production-ready asset QA, run:

```powershell
tools/check-asset-qa.ps1 -Root .
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
