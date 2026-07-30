# Harness Prompt Contract: ENEMY-001-mac-lang-move-side

Generate one original ordinary-enemy gameplay sprite sheet.

- Exact canvas: `1536x768` pixels.
- Exact grid: `2 rows x 4 columns`, read left-to-right then top-to-bottom.
- Exact cell size: `384x384` pixels.
- Flat background: solid `#FF00FF` in every cell, with no gradient, transparency, shadow or texture.
- Per-cell safe zone: x `48..336`, y `48..336`.
- Paw/bottom baseline: y `326`.
- View: right-facing three-quarter top-down arena creature.
- Pivot: feet; same size, anatomy, lighting and angle in all eight frames.

Subject: **Mặc Lang**, an original low forward-leaning ink-wolf spirit. It has a wedge-shaped muzzle, four readable paws, ragged dry-brush mane, one compact broken-brush tail, blue-black wet-ink body, pale paper-like cracks and exactly two small cinnabar eyes. The silhouette must read as a predatory quadruped at 64 logical pixels tall without any circular aura.

Motion phases: front-paw contact; weight forward; rear-paw pass; compressed step; opposite front-paw contact; weight return; rear-paw return; loop bridge. Show true paw alternation and grounded weight transfer.

Study wet/dry ink behavior and negative space from the public-domain [Shitao *Landscapes of the Four Seasons*](https://www.metmuseum.org/art/collection/search/49180), but do not copy a composition or any source mark.

Constraints: no text, calligraphy, labels, visible grid, border, logo or watermark; no glossy 3D animal, cute round mascot, generic purple blob or photoreal wolf; no aura, glow, dust, shadow or trail in the body sheet; no extra heads, extra paws, duplicate tail, anatomy drift, body scaling or whole-sprite shake; no tail or paw crosses a cell edge.

Acceptance intent: an eight-frame chase loop at 8 FPS, runtime-flipped toward the player, target height 64 logical pixels.
