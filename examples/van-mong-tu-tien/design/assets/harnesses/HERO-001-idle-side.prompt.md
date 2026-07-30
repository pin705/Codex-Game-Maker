# Harness Prompt Contract: HERO-001-idle-side

Generate one raw gameplay sprite sheet, not a presentation board.

- Exact canvas: `1536x1024` pixels.
- Exact grid: `2 rows x 3 columns`, read left-to-right then top-to-bottom.
- Exact cell size: `512x512` pixels.
- Flat background in every cell: solid `#FF00FF`, no gradient, texture, shadow or transparency.
- Per-cell safe zone: x `56..456`, y `56..456`; keep every visible pixel inside it.
- Feet/bottom baseline: y `440` in every cell.
- Canonical view: right-facing three-quarter top-down survivor character, not a platformer profile.
- Pivot: feet; same identity, costume, visible height, lighting and camera in all six frames.

Subject: an original young sword cultivator of Vân Mộng wearing a short split warm-ivory travel coat over a blue-black inner layer, separated visible dark boots, tied dark hair, a small jade waist talisman and one restrained cinnabar knot. Painterly ink-on-silk material, crisp readable silhouette, dry-brush edge texture and restrained jade highlights. No held weapon.

Motion phases:

1. Neutral anchored pose.
2. Quiet breath in with tiny sleeve lift.
3. Blink/hold; feet still fixed.
4. Breath out.
5. Talisman and sleeve settle.
6. Loop bridge back to frame 1.

Study pale/dark ink texture rather than copying composition from [Gong Xian's public-domain *Landscapes*](https://www.metmuseum.org/art/collection/search/65620). The character design and every pose must be original.

Constraints: no text, calligraphy, label, frame number, grid line, border, UI, logo or watermark; no plastic 3D render, anime-gacha gloss, neon cyberpunk or photorealism; no long robe, staff, sword, cape, aura, glow, dust or cast shadow; no whole-body translation, scaling or wobble; no duplicated limbs; nothing crosses a cell boundary.

Acceptance intent: a clean six-frame idle loop at 6 FPS, normalized to 512x512 frames and displayed at 76 logical pixels tall.
