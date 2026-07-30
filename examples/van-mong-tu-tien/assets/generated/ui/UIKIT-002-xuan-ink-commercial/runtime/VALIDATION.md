# UIKIT-002 runtime extraction QA

Source: `../alpha-source.png` (`1254x1254`, RGBA8)

Source SHA-256: `6a8035115572adbf7a27d9ca0dc1a952fddc552183740ff2d6360d9ea553acc7`

Method: each known main connected-component bound was cropped exactly, reset to a local page origin, then given a fresh 10 px fully transparent border. This intentionally excludes every disconnected pixel outside the named component instead of carrying neighboring atlas fragments into the runtime file. No image generation or visual repainting was used.

| Runtime asset | Atlas crop | Output | Non-transparent trim | Alpha coverage |
|---|---:|---:|---:|---:|
| `ui_scroll_panel.png` | `376x427+49+88` | `396x447` | `376x427+10+10` | 75.33% |
| `ui_lacquer_panel.png` | `446x287+470+163` | `466x307` | `446x287+10+10` | 74.23% |
| `ui_talisman_card.png` | `246x438+967+85` | `266x458` | `246x438+10+10` | 84.15% |
| `ui_button_gold.png` | `388x183+44+624` | `408x203` | `388x183+10+10` | 70.60% |
| `ui_button_jade.png` | `387x175+474+627` | `407x195` | `387x175+10+10` | 66.80% |
| `ui_tab_ink.png` | `318x123+904+652` | `338x143` | `318x123+10+10` | 75.35% |
| `ui_icon_sword.png` | `279x283+73+880` | `299x303` | `279x283+10+10` | 67.66% |
| `ui_icon_qi.png` | `277x287+487+879` | `297x307` | `277x287+10+10` | 66.43% |
| `ui_icon_vitality.png` | `277x284+890+881` | `297x304` | `277x284+10+10` | 68.03% |

## Validation results

- PASS: all nine runtime assets decode as PNG with an RGBA alpha channel.
- PASS: the full top, right, bottom, and left 10 px borders have maximum alpha `0` on every asset.
- PASS: alpha trim geometry matches the requested component bound exactly at offset `+10+10` for every asset.
- PASS: thresholded alpha analysis finds exactly one connected foreground component per asset.
- PASS: no opaque magenta/chroma pixels remain (`R > 0.80`, `B > 0.80`, `G < 0.35`, `A > 0.01` produced zero pixels).
- PASS: fully transparent pixels contain no hidden RGB color data.
- PASS: visual inspection on the labeled checkerboard contact sheet found no neighboring-panel fragments, clipping, visible matte fringe, or broken silhouette.

Contact sheet: `ui_contact_sheet.png` (`1548x1479`, labeled 3x3 checkerboard preview; QA-only, not intended to ship in a runtime bundle).

