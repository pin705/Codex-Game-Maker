# Harness Prompt Contract: UIKIT-001-kim-ngoc-components

Generate one raw source-component sheet for a Godot UI skin. This is not a screenshot or finished menu.

- Exact canvas: `2048x1536` pixels.
- Exact grid: `3 rows x 4 columns`, read left-to-right then top-to-bottom.
- Exact cell size: `512x512` pixels.
- Flat background in all cells: solid `#FF00FF`; no transparency, gradient or texture outside each component.
- Per-cell safe zone: x `56..456`, y `56..456`.
- Each cell contains exactly one centered isolated component; nothing crosses cell boundaries.
- Shared material family: warm fibrous xuan paper, blue-black lacquer/ink, aged bronze corner hardware, sparse gold, jade and cinnabar accents. Painterly 2D, crisp alpha-ready edges, restrained wear.

Exact slot order:

1. Wide low combat plaque frame, empty center, clipped/folded corners, 9-slice-safe.
2. Larger square-ish modal frame, empty center, restrained bronze brackets, 9-slice-safe.
3. Wide low meter underlay with dark lacquer channel, no fill and no text.
4. Matching wide low meter overlay/frame with transparent/key-color center channel.
5. Tall upgrade card frame like a talisman folio, empty paper center, 9-slice-safe.
6. Matching selected-card gold rim plus small separate-looking seal accent contained as one overlay component.
7. Square realm seal medallion with a blank center—no character or pseudo-character.
8. Circular/diamond skill medallion with blank center.
9. Flying sword upgrade icon.
10. Sword-ring/expanding-blade-circle upgrade icon.
11. Qi pearl upgrade icon.
12. Vitality knot/leaf-vein upgrade icon.

Nine-slice frames keep corners and brackets inside the outer 22 percent of their own cropped bounds; middle edge runs remain visually tileable. Icons use one dominant silhouette, at most two functional accent colors and generous internal padding.

Study material contrast from the public-domain [Dong Qichang *Landscapes and poems*](https://www.metmuseum.org/art/collection/search/41480): ink, gold-flecked paper and satin. Do not copy or invent calligraphy. All components must be original.

Constraints: absolutely no words, letters, numerals, Chinese/Vietnamese characters, pseudo-calligraphy, labels, frame numbers, visible grid, screenshot content, buttons with text, cursor, logo or watermark; no rounded HTML dashboard cards, glassmorphism, glossy mobile-game bevel, plastic 3D, neon cyberpunk or generic CSS gradient; no component shadow crossing the safe zone.

Acceptance intent: extract all 12 cells into separate alpha textures; slots 1, 2 and 5 must survive Godot `NinePatchRect`; slots 3–4 support `TextureProgressBar`; icons remain recognizable at 48–64 logical pixels.
