# Generated Asset Rules

- Accepted generated assets must live under `assets/generated/`.
- Prompt and provenance records must live under `assets/source-prompts/`.
- Do not reference images directly from Codex default generated-image folders.
- Use versioned filenames: `<asset-id>-v001.png`, `<asset-id>-v002.png`.
- Keep discarded drafts out of production references.
- UI icons and sprites must be checked at their target display size.
- No text in generated images unless the exact text is required and verified.
- Record web sources and licenses for any sourced or reference-driven asset.
- Runtime sprite assets must keep raw source, processed transparent output, frame outputs, GIF preview, and `pipeline-meta.json`.
- Prefer solid chroma-key raw backgrounds for transparent sprite/prop assets, then convert to alpha locally.
- Select the chroma key before generation from the asset description. Prefer `tools/suggest-key-color.ps1 -Description "<asset description>"` when available.
- Green-heavy assets usually use `#FF00FF`; magenta/pink/purple-heavy assets usually use `#00FF00`. If both conflict, choose another absent flat key and record the reason.
- Use processor `-KeyColor auto` only as a post-generation fallback when the selected key is unknown. Record the chosen key in the prompt spec and pipeline metadata.
- Do not generate controllable hero mixed-action atlases as one raw image. Generate per-action sheets first, QA them, then assemble delivery atlases deterministically.
- Character, enemy, NPC, summon, and animated body sheets should use multi-row grids by default. Avoid raw `1xN` strips except for projectiles or simple FX.
- Default action frame counts: idle 6-8, walk 8, run 8-12, jump 6-8, attack 8-12, hurt 3-5, death 8-12, FX 8-16.
- Playable map assets must expose runtime objects, collision, zones, exits, or engine-native map data. A single baked image is not enough unless the user explicitly asked for background-only art.
- Godot projects should record accepted asset import intent in `design/assets/godot-import-manifest.yaml`.
