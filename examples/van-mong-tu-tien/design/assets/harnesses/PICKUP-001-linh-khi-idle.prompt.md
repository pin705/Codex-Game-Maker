# Asset Harness Prompt Contract: PICKUP-001-linh-khi-idle

Use this contract when generating the raw image sheet.

- Exact canvas: 768x512 pixels.
- Exact grid: 2 rows x 3 columns.
- Exact cell size: 256x256 pixels.
- Background: one flat solid chroma-key color #FF00FF across every cell.
- Safe zone per cell: x 36..220, y 36..220.
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
- Character foot/bottom baseline: keep grounded frames near y=220 inside each cell.
- Motion phases: 1: neutral; 2: breath in; 3: hold; 4: breath out; 5: settle; 6: loop bridge.
