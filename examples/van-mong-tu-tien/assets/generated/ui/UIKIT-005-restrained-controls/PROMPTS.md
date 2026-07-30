# UIKIT-005 Restrained Controls

Canonical provenance: `assets/source-prompts/UIKIT-005-restrained-controls.yaml`  
Execution: Codex built-in ImageGen, no input/reference images.  
Background: flat `#FF00FF` chroma key; runtime text remains Godot-authored.

## Command candidate A — selected

```text
Use case: stylized-concept
Asset type: production game UI command-button component for a Vietnamese xianxia cultivation game
Primary request: one single wide blank command plaque, designed as a scalable 5:1 horizontal control with a perfectly quiet empty center for runtime-rendered text
Subject: matte blue-black lacquered wood, a very thin aged-bronze structural rim, clipped asymmetric corners, one tiny restrained jade knot on only one side, sparse dry-brush wear and chipped hand-made edges
Style/medium: premium hand-painted 2D game UI asset, restrained ink-and-silk material language, refined commercial production quality
Composition/framing: exactly one isolated horizontal plaque centered on canvas, straight front view, generous padding on all sides, no perspective, no cast shadow
Lighting/mood: soft diffuse paper light, low specularity, elegant and sober
Color palette: blue-black ink, oxidized dark bronze, a tiny jade accent, warm paper highlight only on edge wear
Scene/backdrop: perfectly flat solid #FF00FF chroma-key background for local background removal
Constraints: blank center; no text; no letters; no numbers; no pseudo-calligraphy; no watermark; no logo; no flowers; no ornate clasps; no cloud curls; no glossy bevel; no plastic 3D; no pill shape; no gold slab; no gradient or texture in the background; no floor; no reflection; background must be uniform #FF00FF and absent from the plaque; crisp separated silhouette; at least 12% empty padding around the plaque
```

Selected in the source look-development comparison and then verified at runtime
scale: the quiet matte field, thin bronze rim and single jade knot carry captions
without returning to the glossy gold/plastic signal of the superseded family.

## Command candidate B — rejected

```text
Use case: stylized-concept
Asset type: second look-development candidate for a production game UI command-button component in a Vietnamese xianxia cultivation game
Primary request: one single wide blank command tablet, designed as a scalable 5:1 horizontal control with a quiet empty center for runtime-rendered text
Subject: layered blackened silk and charcoal ink-wash paper held by only four minimal aged-bronze corner brackets, one small asymmetrical cinnabar maker seal near the far left edge, subtle stitched edge and dry-brush fibers
Style/medium: premium hand-painted 2D game UI asset, understated museum-like xuan-paper and ink material, commercial-quality but sober
Composition/framing: exactly one isolated horizontal plaque centered on canvas, straight front view, generous padding on all sides, no perspective, no cast shadow
Lighting/mood: diffuse natural paper light, completely matte, quiet ritual seriousness
Color palette: charcoal ink, faded black silk, tarnished brown bronze, tiny cinnabar accent, no bright gold
Scene/backdrop: perfectly flat solid #FF00FF chroma-key background for local background removal
Constraints: blank center; no text; no letters; no numbers; no pseudo-calligraphy; no watermark; no logo; no flowers; no cloud curls; no ornate clasps; no glossy bevel; no plastic 3D; no pill shape; no bright gold; no gray UI rectangle; no gradient or texture in background; no floor; no reflection; background uniform #FF00FF and absent from tablet; crisp separated silhouette; at least 12% empty padding around tablet
```

Rejected because the cinnabar seal contains visible pseudo-calligraphy. The
source is retained for decision provenance only and has no runtime derivative.

## Matching lacquer panel — selected

```text
Use case: stylized-concept
Asset type: production game UI scalable nine-slice panel for a Vietnamese xianxia cultivation game
Primary request: one single large blank near-square ritual panel with a broad quiet center for runtime-rendered text and nested content
Subject: matte blue-black inked silk stretched over a thin dark wood backing, a very narrow aged-bronze structural rim, clipped asymmetric corners, only one tiny restrained jade inlay at the upper-right corner, sparse dry-brush wear
Style/medium: premium hand-painted 2D game UI asset matching a sober ink-and-silk command plaque, commercial production quality, understated museum display material
Composition/framing: exactly one isolated near-square panel centered on canvas, straight front view, generous padding on all sides, no perspective, no cast shadow
Lighting/mood: soft diffuse paper light, low specularity, elegant and quiet
Color palette: blue-black ink, oxidized brown bronze, tiny dark jade accent, no bright gold
Scene/backdrop: perfectly flat solid #FF00FF chroma-key background for local background removal
Constraints: blank center covering at least 72% of panel width and height; no text; no letters; no numbers; no pseudo-calligraphy; no watermark; no logo; no flowers; no cloud curls; no ornate clasps; no glossy bevel; no plastic 3D; no gold slab; no thick decorative furniture; no gradient or texture in background; no floor; no reflection; background uniform #FF00FF and absent from panel; crisp separated silhouette; at least 10% empty padding around panel; corners and rim must be suitable for nine-slice scaling
```

Selected as the large-surface counterpart to candidate A. See
`pipeline-meta.json` for call IDs, timestamps, processing lineage, hashes and
measured alpha QA.
