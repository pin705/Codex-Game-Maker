# Generated Asset Rules

- Accepted generated assets must live under `assets/generated/`.
- Prompt and provenance records must live under `assets/source-prompts/`.
- Every accepted runtime asset must record `generation_provider`. Use explicit
  values such as `gpt_image`, `web_sourced`, `user_supplied`, or
  `local_deterministic_placeholder`.
- Do not present `local_deterministic_placeholder` assets as GPT Image output.
  They are valid for code/scene smoke tests only and are not release-ready
  showcase assets.
- A release-ready GPT Image asset needs raw source output, source prompt,
  harness spec/report when applicable, processed output, metadata, and QA
  evidence. Missing any of those must be called out as a warning or blocker.
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
- Default action frame counts: idle 6-8, side-view playable hero walk/run 12, top-down survivor move loops 8 per direction, secondary walk 8, jump 6-8, attack 8-12, hurt 3-5, death 8-12, FX 8-16.
- Runtime action sheets must be reviewed as animation, not only as image grids. Idle must loop calmly, walk/run must alternate feet, and jump must provide phase poses rather than a blind loop.
- Playable characters must not freeze on a walk/run frame when input stops. Idle can be subtle, but it must have an accepted idle action, visible preview evidence, and a runtime state-machine transition back to idle.
- Derived movement sheets must not be made by stacking a second full-body copy or unmasked limb crops over the base character. If deriving from a reference image, use clean regenerated frames, local warp/deformation, or a repaint pass that removes the old limb pose first.
- Local animation repair must not leave both the old foot/hand/limb and the shifted replacement visible. Remove or repaint the original pixels first; one frame should contain one clean body silhouette.
- When a local repair touches feet, hands, limbs, tails, weapons, or props, add `local_repair` to the harness spec and point it at a repair manifest. The manifest must record single-silhouette cleanup evidence such as `old_foot_pixels_removed_or_covered_before_replacement=true`, `no_second_lower_foot_pair=true`, `no_hard_occlusion_blocks=true`, and `single_paw_pair_per_frame=true`.
- A geometry-only harness PASS is not enough for repaired locomotion. Run the harness gate again after adding `local_repair` so the report includes `harness.local_repair.pixel_erasure`, `harness.local_repair.paw_blob_scan` for foot/leg repairs, and `harness.local_repair.evidence`.
- Paw/leg local repairs must erase the original source pixels first, then draw one connected leg-and-paw setup per side in the original footprint. If the cleanup relies on flat robe-colored rectangles, large masks, or pasted oval feet under the old feet, reject it and regenerate or repaint again.
- Raw chroma-key repairs must erase removed source pixels back to the selected key color, not transparent black. Transparent black becomes false opaque residue after RGB export and can hide broken erasure.
- Top-down survivor projects must not reuse side-view platformer locomotion sheets. Preferred directional sets include idle_down, idle_side, idle_up, move_down, move_side, and move_up.
- Side-only survivor prototypes are allowed when explicitly recorded as `direction_model: side_only_last_horizontal`: use idle_side and move_side only, flip left/right, and preserve last horizontal facing during vertical movement.
- Top-down survivor movement should read as a restrained shuffle with visible hand and foot changes. Do not fake it by scaling, translating, whole-body wobbling, camera jitter, or globally warping the whole character; keep the head, torso, tail, equipment, runtime pivot, and foot baseline stable unless the motion phase explicitly requires a small repaint.
- Body shake alone is not an acceptable walk/run loop. The feet and/or hands must visibly alternate, even in side-only survivor prototypes.
- Top-down survivor walk/move sheets need lower-body motion-phase evidence in addition to geometry evidence. Too many adjacent near-neutral transitions mean the animation is not gameplay-ready even if every frame is centered and uncropped.
- Do not put semi-transparent shadow, glow, dust, or motion-trail pixels directly on a chroma-key raw locomotion sheet. They blend into near-key halo colors and become purple/green residue after processing. Generate them as separate FX or opaque runtime assets.
- Locomotion characters must be designed for animation: visible separated feet, short clothing, and no long robe, skirt, staff, cape, or prop that blocks foot contact poses in idle/move sheets.
- If a character concept hides the feet or makes clean foot isolation unreliable, regenerate a movement-friendly variant before importing it into a playable prototype.
- For side-only survivor heroes, prefer stable torso/feet with limited hand/foot alternation over full directional art that looks bad. North/south states should be omitted rather than shipped if they are weaker than the side-only model.
- Idle and movement actions in the same playable character bundle must share target height, pivot, foot baseline, and runtime scale. Cross-state scale popping is a blocker even when each sheet passes individually.
- A side-only top-down survivor runtime must explicitly test idle_side -> move_side -> idle_side. Without that smoke test, the showcase is not ready.
- Reject or regenerate sheets where tails, feet, weapons, platforms, or FX fragments from neighboring cells appear after slicing.
- Do not put long staffs, large weapons, dust clouds, magic trails, or other wide secondary elements into locomotion sheets. Generate those as attack/cast/FX assets.
- Accepted playable sprite sheets must have a harness spec and a passing harness report before Godot import. Edge-touch frames are blockers, not warnings.
- Rectified playable sheets must isolate the foreground with the selected key/alpha mask before pasting into the harness canvas. Rectangular gradient background blocks around a character are a failed rectification, even if the frame geometry looks aligned.
- Record target in-game size, pivot, foot baseline, animation FPS, loop/non-loop, and state-machine mapping before importing a playable character into Godot.
- Playable map assets must expose runtime objects, collision, zones, exits, or engine-native map data. A single baked image is not enough unless the user explicitly asked for background-only art.
- Platformer scenes must use a scene scale plan before generated assets are placed. Do not place raw generated sprites at source pixel scale.
- Platform visual overlap and player foot sink must scale with platform visual size. A fixed value can pass on large platforms and fail on smaller ones.
- Repeated runtime objects such as pickups must use groups, metadata, or stable instance ids; do not rely on duplicate node names.
- Playable showcases must include grounded spawn, reachable route, generated collectible assets, a finish condition, restart, and evidence of a full playthrough.
- Top-down showcase props that visually block walking must have generated/imported collision metadata and Godot `StaticBody2D` or equivalent blockers. Do not ship solid-looking trees, rocks, or walls as visual-only sprites.
- Generated UI art must be constrained by runtime control sizes, clipping, and default-style removal. Do not place raw card/icon art at source pixel size in an upgrade picker.
- Health, XP, stamina, and skill cooldown HUD bars in a generated-asset showcase should use image-based frames/fills or an explicit design-system skin. Default engine progress bars are acceptable only for greybox passes.
- Generated FX must be validated in-game at scene scale. Tiny reused hit pops are not enough for upgrades, pulse skills, projectile hits, and kill feedback.
- Godot projects should record accepted asset import intent in `design/assets/godot-import-manifest.yaml`.
