# Visual Overhaul Asset Brief — Batch 01

Status: Native visual acceptance passed; Web/manual release gates pending  
Date: 2026-07-29  
Art direction: `design/art/art-bible.md`  
Scale contract: `design/assets/scene-scale-plan.yaml`

## Outcome

Replace the visible “background plus procedural primitives plus flat HTML-like panels” presentation with one coherent authored art family while keeping all current combat, progression, controls and Vietnamese UI behavior intact.

This batch is deliberately the smallest set that can prove the new quality bar in one gameplay screenshot: animated hero, one ordinary enemy, the boss, qi pickup, auto sword, hit impact and a reusable UI material kit. Other enemy variants, arena props and larger breakthrough effects expand only after this batch survives in-engine review.

## Audit Summary

| Severity | Current issue | Required correction |
|---|---|---|
| Blocker | Player, enemies, boss, orb, projectile and impact are `_draw()` circles, polygons, arcs and lines | Replace the visible body/effect layer with authored raster sprites; keep procedural layers only for fallback or tunable telegraphs. |
| Blocker | Breakthrough cards are empty rounded rectangles with tiny placeholder symbols | Use a material card frame, selected-state seal/rim and readable illustrated icons. |
| High | Full-width HUD bar resembles a web dashboard and gives every datum equal visual weight | Split it into three low-chrome authored islands and use texture-backed meters. |
| High | Ordinary enemy variants share a compact icon-like visual mass | Establish one strong production enemy silhouette now; extend the family only after scale/readability approval. |
| High | Small generic glow/ring feedback is reused for several different events | Give pickup, projectile and impact separate shape and timing identities. |
| Medium | Title key art is substantially richer than the game beneath it | Keep the art, but replace the flat title-card treatment in the integration pass so both surfaces share material language. |

## Reference Use

- [Gong Xian, *Landscapes* — The Met](https://www.metmuseum.org/art/collection/search/65620), Public Domain: study pale wash/dense dot contrast for internal ink texture.
- [Shitao, *Landscapes of the Four Seasons* — The Met](https://www.metmuseum.org/art/collection/search/49180), Public Domain: study wet-ink pooling and asymmetrical edges for beasts and FX.
- [Dong Qichang, *Landscapes and poems* — The Met](https://www.metmuseum.org/art/collection/search/41480), Public Domain: study ink, gold-flecked paper and satin material contrast for UI; do not copy calligraphy.

The references provide material vocabulary only. New assets must be original, must not trace compositions and must not include the source works' inscriptions.

## Controlled Generation Order

Do not generate all eight assets blindly.

1. First pick: `HERO-001-idle-side`, `ENEMY-001-mac-lang-move-side`, `UIKIT-001-kim-ngoc-components`.
2. Inspect raw output against harness, process to alpha, render GIFs where animated and mock them at target runtime size.
3. Accept, revise or regenerate each item independently. Record concrete prompt deltas rather than broad “make it better” requests.
4. Generate `HERO-001-move-side` using the accepted idle identity as the visual reference. Reject cross-action scale or costume drift.
5. Generate boss, pickup, projectile and impact only after the first-pick material language is approved.
6. Integrate and capture normal combat, breakthrough and boss frames before authoring the next enemy/prop batch.

## Asset Matrix

| Asset ID | Asset kind | Sheet | Runtime target | Pivot | State/node |
|---|---|---:|---:|---|---|
| `HERO-001-idle-side` | player sprite | 2x3, `1536x1024` | 76 px tall | feet | `idle_side`, `AnimatedSprite2D` |
| `HERO-001-move-side` | player sprite | 2x4, `2048x1024` | 76 px tall | feet | `move_side`, `AnimatedSprite2D` |
| `ENEMY-001-mac-lang-move-side` | enemy sprite | 2x4, `1536x768` | 64 px tall | feet | chase loop, `AnimatedSprite2D` |
| `BOSS-001-thien-giac-move-side` | boss sprite | 2x4, `2048x1024` | 156 px tall | feet | chase loop, `AnimatedSprite2D` |
| `PICKUP-001-linh-khi-idle` | pickup sprite | 2x3, `768x512` | 26 px core/38 px readable extent | center | idle loop, `AnimatedSprite2D` |
| `PROJECTILE-001-ngoc-phi-kiem-flight` | projectile sprite | 2x3, `1152x512` | 58x20 px | center | flight loop, rotated by runtime |
| `FX-001-kiem-an-impact` | impact FX | 2x4, `1536x768` | 72 px peak | center | one-shot, `AnimatedSprite2D` |
| `UIKIT-001-kim-ngoc-components` | UI component pack | 3x4, `2048x1536` | slot-dependent | center | extracted textures/atlas regions |

All dimensions are logical design pixels unless explicitly identified as raw-source pixels.

## Standard Paths

For each `<asset-id>`:

- Harness JSON: `design/assets/harnesses/<asset-id>.harness.json`
- Harness guide, generated immediately before art generation: `design/assets/harnesses/<asset-id>.harness.png`
- Prompt contract: `design/assets/harnesses/<asset-id>.prompt.md`
- Prompt/provenance: `assets/source-prompts/<asset-id>.yaml`
- Raw source: `assets/raw/<category>/<asset-id>-v001.png`
- Processed bundle: `assets/generated/<category>/<asset-id>/`
- Transparent sheet: `assets/generated/<category>/<asset-id>/sheet-transparent.png`
- Frames: `assets/generated/<category>/<asset-id>/frames/`
- Animation preview: `assets/generated/<category>/<asset-id>/animation.gif`
- Pipeline metadata: `assets/generated/<category>/<asset-id>/pipeline-meta.json`
- Harness report: `assets/generated/<category>/<asset-id>/harness-report.json`

The committed harness JSON and prompt contract are the generation source of truth. The `.harness.png` files are intentionally not rendered in this documentation-only pass; the generation operator must render them from the committed specs and verify there is no contract drift before requesting images.

## Hero Bundle Contract

Bundle: `design/assets/action-bundles/HERO-001.yaml`

- Direction model: `side_only_last_horizontal`.
- Right-facing art is canonical; runtime `flip_h=true` faces left.
- Vertical movement preserves the most recent horizontal facing.
- Idle and move use the same 512x512 normalized frame canvas, target height, foot line and runtime scale.
- The first required runtime evidence is `idle_side -> move_side -> idle_side` with one visual sprite node and no size pop.

## UI Kit Slot Contract

`UIKIT-001-kim-ngoc-components` uses left-to-right, top-to-bottom slot order:

| Slot | Component | Intended runtime use |
|---:|---|---|
| 0 | combat plaque frame | nine-slice realm/timer plaque |
| 1 | modal frame | nine-slice pause/end/notice panel |
| 2 | meter underlay | `TextureProgressBar.texture_under` |
| 3 | meter overlay | `TextureProgressBar.texture_over` |
| 4 | upgrade card frame | nine-slice normal card |
| 5 | selected card rim/seal | overlay for keyboard/mouse focus |
| 6 | realm seal medallion | upper-left realm identity |
| 7 | skill medallion | cooldown/ready indicator |
| 8 | flying sword icon | projectile/pierce upgrades |
| 9 | sword-ring icon | pulse radius/power upgrades |
| 10 | qi pearl icon | pickup/XP/magnet upgrades |
| 11 | vitality knot icon | health/regen upgrades |

The generated sheet contains no text. Card copy, numbers, realm names and controls remain Vietnamese runtime labels. Source components must be extracted before integration; do not display the raw 3x4 sheet in the game.

## First-Pick Review Questions

- Does the hero look like a specific original cultivator at 76 px, rather than a painted blob or generic anime avatar?
- Does Mặc Lang read as a moving beast at 64 px without relying on a circular aura?
- Do the UI components feel like one physical family when placed beside the title key art?
- Are paper, ink, bronze, jade and cinnabar still distinguishable at `1280x720`?
- Does any output introduce glossy 3D material, neon bloom, fake characters, watermark, text or default dashboard geometry?

## Batch Acceptance Gate

Batch 01 has passed the generated-asset and native screenshot gates below. The
planned raster UI atlas was superseded for this batch by custom Godot material
frames plus accepted raster icons; it remains deferred and is not presented as
generated art.

- Raw images pass their exact harness or are regenerated/rectified for geometry only.
- Animated sheets produce clean transparent frames and reviewed GIFs.
- Hero identity, target height, pivot and foot line match between both actions.
- Authored UI frames render without warped/clipped corners and icons read at 48–64 px.
- Godot import intent is recorded and runtime uses authored textures without unrelated default chrome.
- Native screenshots at `1280x720` cover normal combat, boss and breakthrough selection.
- Visual QA contains no blocker/high issue for plastic/default UI, placeholder primitives, crop, scale, alpha or readability.

The integrated seven-state screenshot review passed without blocker/high issues.
Commercial-adjacent native presentation is accepted; complete release readiness
still requires Web/browser and full physical-input playtest evidence.
