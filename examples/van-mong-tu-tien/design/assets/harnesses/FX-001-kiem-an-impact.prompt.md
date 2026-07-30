# Asset Harness Prompt Contract: FX-001-kiem-an-impact

Use this contract when generating the raw image sheet.

- Exact canvas: 1536x768 pixels.
- Exact grid: 2 rows x 4 columns.
- Exact cell size: 384x384 pixels.
- Background: one flat solid chroma-key color #FF00FF across every cell.
- Safe zone per cell: x 40..344, y 40..344.
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
- Motion phases: 1: pose 1; 2: pose 2; 3: pose 3; 4: pose 4; 5: pose 5; 6: pose 6; 7: pose 7; 8: pose 8.
