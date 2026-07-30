# Visual Acceptance QA — Vân Mộng Tu Tiên

Date: 2026-07-29  
Viewport reviewed: 1280×720 native captures  
Scope: title, normal combat, boss, breakthrough, pause, victory and defeat

## Result

**PASS for blocker/high visual issues.** The seven-state native set now meets
the V2 art-bible gate for an authored commercial-adjacent presentation. This
is not a claim that the complete game is release-ready: Web export/browser
input and a physical-input four-minute run remain unverified.

## Evidence

- `title-final.png`: atmospheric key art plus warm hanging-scroll surface;
  no generic dark dashboard slab.
- `gameplay-final.png`: authored arena, 76 px hero, three distinct ordinary
  enemy families, qi pickups, flying sword/hit beat and compact HUD islands.
- `boss-final.png`: dedicated 150 px boss silhouette, grounded contact shadow,
  framed health meter and no HUD overlap.
- `upgrade-final.png`: three paper talisman folios, sword/qi illustrated icons,
  readable Vietnamese copy and no card/icon clipping.
- `pause-final.png`, `victory-final.png`, `defeat-final.png`: the same paper,
  bronze, jade and cinnabar material family carries through all modal states.

## Checks

- Hero foot pivot, scale and center-playfield visibility: PASS.
- Wisp/Mặc Lang/Tà Tu/boss silhouette separation: PASS.
- Arena contrast and center readability: PASS.
- HUD obstruction and boss overlap: PASS.
- Sword, qi and hit-effect runtime scale: PASS.
- Upgrade card icon/text clipping: PASS.
- Visible magenta/green chroma fringe or primitive body fallback: none found.
- Generic rounded HTML/dashboard chrome: none found in the accepted set.

## Remaining Release Gates

- Export and verify the Web build in Chromium; Firefox second when available.
- Record a full four-minute physical-input run, boss-kill path and
  death/restart path.
- Tune density/XP/boss pressure only from playtest evidence; do not redesign
  the accepted visual language without a new art review.
