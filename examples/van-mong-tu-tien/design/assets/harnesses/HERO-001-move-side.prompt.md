# Asset Harness Prompt Contract: HERO-001-move-side

Use this contract when generating the raw image sheet.

- Exact canvas: 1536x1024 pixels.
- Exact grid: 2 rows x 4 columns.
- Exact cell size: 384x512 pixels.
- Background: one flat solid chroma-key color #FF00FF across every cell.
- Safe zone per cell: x 54..330, y 54..458.
- The subject must stay completely inside the safe zone in every frame.
- Leave empty chroma-key padding around ears, tails, feet, weapons, trails, dust, and effects.
- Do not draw grid lines, borders, labels, frame numbers, watermarks, UI, or debug overlays.
- Keep the same character identity, costume, scale, camera angle, and lighting across all frames.
- Do not let any body part or prop cross into a neighboring cell.
- Do not fake animation by stacking a second full-body character, ghost limbs, or unmasked duplicated limb crops over the base pose.
- If a local repair shifts a foot, hand, limb, tail, or prop, remove or repaint the original pixels first so only one clean visible body remains.
- Do not use semi-transparent shadows, glows, dust, or motion trails in a chroma-key raw sheet; generate those as separate FX sheets or opaque runtime assets.
- Preserve a stable runtime pivot and visible bounding box so the asset can be scaled consistently in a 16:9 scene.
- If the subject has a long tail, weapon, staff, cape, trail, or backpack, it still must fit fully inside the safe zone in every frame.
- If the prop or tail cannot fit comfortably, generate a larger-cell harness or move that element to a separate attack/cast/FX sheet.
- View profile: top-down survivor / arena action.
- Do not use a side-view platformer run silhouette for this asset.
- Movement is a restrained top-down shuffle: visible alternating feet and hands, no long stride, no airborne running pose.
- Body shake, whole-sprite wobble, or camera/pivot jitter is not locomotion and must not be used as the primary animation.
- Do not fake movement by translating, scaling, or globally warping the whole character; keep head, torso, tail, equipment, pivot, and foot baseline stable.
- Choose locomotion-friendly silhouettes: short jacket, separated visible feet, and no long robe, skirt, staff, cape, or prop blocking the feet in move/idle sheets.
- If the current character concept hides the feet, regenerate a locomotion-friendly variant before making the runtime walk cycle.
- Build idle as its own loop. A stopped character must never freeze on a walk/run contact pose.
- Direction matters for polished directional characters. Plan separate down, side, and up sheets, or use one canonical four-direction sheet.
- If the project chooses a side-only survivor model, record direction_model=side_only_last_horizontal and generate only approved idle_side/move_side sheets instead of weak north/south variants.
- Up/down movement should not look like the character is sliding sideways across the arena unless the side-only model is explicitly chosen for that prototype.
- Keep attack/cast props and weapon swings separate from locomotion unless the game design explicitly needs an always-held prop.
- Character foot/bottom baseline: keep grounded frames near y=440 inside each cell.
- Motion phases: 1: pose 1; 2: pose 2; 3: pose 3; 4: pose 4; 5: pose 5; 6: pose 6; 7: pose 7; 8: pose 8.
