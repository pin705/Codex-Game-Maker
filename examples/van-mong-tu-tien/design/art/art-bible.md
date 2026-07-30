# Art Bible V2: Vân Mộng Tu Tiên

Status: Verified  
Release evidence boundary: visual batch is integrated across desktop and dedicated 844×390 phone layouts; physical/Web/manual release gates remain pending  
Source concept: `design/gdd/game-concept.md`  
Asset brief: `design/assets/visual-overhaul-batch-01.md`  
Scale contract: `design/assets/scene-scale-plan.yaml`  
Target: commercial-adjacent authored 2D presentation at native resolution; full release readiness still requires Web/manual QA

## Why V2 Exists

The current title illustration establishes a useful mood, but the playable scene does not carry that quality into the game. The baseline screenshots show a dark background with small procedural circles and polygons for nearly every gameplay object, while the HUD and breakthrough screen use broad flat rounded panels with almost no authored ornament, texture, hierarchy or iconography.

Audited evidence:

- `production/playtests/title-screen-runtime.png`: strong atmospheric key art, but the large flat title panel looks detached from the painting.
- `production/playtests/gameplay-runtime.png`: player, enemies, qi, projectiles and hits are procedural primitives; most silhouettes read as symbols instead of illustrated beings.
- `production/playtests/upgrade-runtime.png`: three equal dark rectangles dominate the screen; tiny placeholder marks replace meaningful upgrade art.
- Runtime implementation confirms the gap: entity files rely on `_draw()` primitives and `scripts/ui/hud.gd` relies on `StyleBoxFlat` and default `ProgressBar` styling.

V2 therefore supersedes the former “procedural runtime plus one splash” art strategy. Procedural drawing may remain only as a documented fallback, collision/telegraph aid or temporary debug layer. It is not the intended shipped presentation.

## Visual Identity

One-line rule: **mực sống trên lụa cũ, đồng ám giữ khung, ngọc quang chỉ bùng lên khi kiếm ý vận hành.**

Target feeling: an illustrated cultivation tale with physical material, restrained luxury and dangerous negative space—not neon fantasy, glossy mobile UI or browser-dashboard chrome.

The visual stack must be recognizable in one glance:

1. Warm xuan-paper and silk grain form the quiet world.
2. Blue-black wet and dry ink forms characters, beasts, rocks and motion.
3. Aged bronze and sparse gold define important frames, seals and breakthroughs.
4. Jade-cyan indicates the player and controllable power.
5. Cinnabar/vermilion indicates hostile intent, damage and boss pressure.

## Public-Domain Study References

These are material and brush-behavior studies only. Do not trace a composition, reuse inscriptions, reproduce a figure or prompt for an artist imitation. Every game asset must remain an original design.

| Reference | What may be studied | Rights/provenance |
|---|---|---|
| [Gong Xian, *Landscapes*, 1680s — The Met](https://www.metmuseum.org/art/collection/search/65620) | Pale wash against dense dark dot clusters; density that still preserves translucency | The official object page marks the image **Public Domain** and links The Met Open Access terms for unrestricted commercial and noncommercial use. |
| [Shitao, *Landscapes of the Four Seasons* — The Met](https://www.metmuseum.org/art/collection/search/49180) | Free wet-ink edges, irregular pooling and asymmetrical negative space | The official object page marks the image **Public Domain** under The Met Open Access program. |
| [Dong Qichang, *Landscapes and poems*, early 17th century — The Met](https://www.metmuseum.org/art/collection/search/41480) | Ink, restrained mineral color, gold-flecked paper and satin as a material reference for UI | The official object page marks the image **Public Domain** under The Met Open Access program. Do not reuse its calligraphy. |

## Shape Language

### Player

- A compact three-quarter top-down silhouette facing sideways: narrow shoulders, short split travel coat, visible separated feet and a small jade talisman at the waist.
- The robe ends above the ankles so the eight-frame movement loop can show real alternating foot contact.
- One restrained ribbon or sleeve accent is allowed; no long staff, huge sword, cape or floor-length robe in locomotion sheets.
- The face is calm and readable through a light skin/paper value against blue-black hair; avoid chibi circles, plastic anime rendering and generic armored-warrior mass.
- The flying sword remains a separate gameplay asset. The hero locomotion sheet contains no weapon trail or aura cloud.

### Ordinary Enemy — Mặc Lang

- A low, forward-leaning ink-wolf spirit: wedge muzzle, ragged brush mane, four readable feet and a single broken-brush tail.
- Pale paper cracks and two cinnabar eyes create identity without turning the body into a red blob.
- Its mass must be clearly different from the upright player at 60–68 logical pixels high.

### Boss — Thiên Giác Mặc Lân

- Broad shoulder mass, crown-like forked horns, ink-cloud mane and one pale mask plane; the silhouette must read before internal texture.
- Gold is structural only at the horn rings/seal scars; cinnabar is reserved for eyes, core and attack state.
- The body sheet contains no 230 px slam ring. Telegraph and impact remain separate runtime FX so the boss sprite stays clean.

### Pickups, Projectile And Impact

- Linh khí is a faceted seed/pearl wrapped by two dry-brush comma marks, not a generic glowing circle.
- Phi kiếm has a hand-painted metal blade, dark hilt, jade inlay and a compact horizontal silhouette; the trail is a separate effect.
- Impact is a one-shot broken sword-seal: hard white/cyan center, dry-brush shards, then dissolving ink flecks. It must not look like a generic plus-sign spark.

### UI

- Frames use asymmetrical lacquered-paper plates held by aged bronze corner clamps and one jade/cinnabar accent, with deliberate chipped edges.
- Upgrade cards resemble a compact talisman folio: tall paper body, seal notch, icon medallion and a narrow bottom text field.
- Avoid equal-weight dashboard boxes. Hierarchy comes from silhouette, material and spacing, not from adding more rounded rectangles.
- Corners are clipped, folded or bracketed rather than uniformly rounded. No glassmorphism, glossy bevel, pill buttons or generic CSS gradients.

## Color And Value System

| Role | Core palette | Use |
|---|---|---|
| Warm support | `#E7DDC4`, `#C9B995`, `#8F7D5C` | paper, silk, inactive card interior, secondary type field |
| Deep ink | `#0B171B`, `#17292D`, `#314248` | silhouettes, text plates, deep wash and outlines |
| Jade safety | `#55C9A6`, `#A9F1D5`, `#DFFFF2` | hero focus, sword, qi, ready-state accents |
| Cinnabar threat | `#B43D35`, `#E06B52`, `#6F2527` | enemy eyes/core, damage, telegraphs |
| Aged bronze | `#8A6730`, `#C69A48`, `#F0D184` | frame hardware, selected card, realm milestone |
| Violet corruption | `#675078`, `#9A78A9` | secondary hostile ink only; never player power |

Value rule: the player keeps a light torso/head plane against a dark outline; ordinary enemies keep a dark body with two light/cinnabar cues; rewards keep a bright compact center. A grayscale thumbnail at `640x360` must still separate all three.

Saturation rule: no full-screen teal/orange grade. Functional color should occupy less than roughly 15% of a normal combat frame; the world remains predominantly paper and ink.

## Rendering And Material Rules

- Medium: painterly 2D raster sprites with crisp alpha silhouettes, internal dry-brush texture and restrained wet-ink pooling.
- Camera: three-quarter top-down arena. Characters are not platformer side profiles and not orthographic chess pieces.
- Lighting is baked and consistent: soft upper-left paper light, minimal rim, no plastic specular shine.
- Texture detail must survive the runtime sizes in `scene-scale-plan.yaml`; do not rely on hairline decoration visible only in the source sheet.
- Chroma-key raw sheets use a single flat key color with no gradient, no shadow and no semi-transparent glow. Shadow, aura, trails and bloom are separate runtime layers.
- Source frames use shared scale and fixed canvas. Runtime scaling is derived from transparent bounds, never from raw sheet dimensions.
- Linear filtering is the default for painted sprites. Mipmaps remain off for small 2D gameplay sprites unless a device test shows shimmer.

## Motion Language

- Hero idle: restrained breath, blink and sleeve/talisman settle; feet and pivot remain fixed.
- Hero move: eight-frame shuffle with visible left/right foot and hand alternation; no whole-body shake, scale animation or long platformer stride.
- Enemy move: predatory weight transfer and paw alternation; the torso may compress slightly but cannot slide inside its cell.
- Boss move: slow heavy step, shoulder/mane follow-through and a clean loop; horns do not change shape or cross cell edges.
- Qi orb: six-frame turn/breathe cycle; no baked blur.
- Projectile: six-frame material shimmer while the runtime rotates and translates the whole sprite.
- Impact: eight-frame one-shot with a strong 2–3 frame hit peak and complete decay by frame 8.

## UI Composition

### Normal Combat

- Persistent chrome is split into three authored islands, not one full-width bar: realm seal at upper-left, slim health/qi stack near upper-center-left, and timer/skill medallion at upper-right.
- The center-top and the area around the player remain open. Temporary wave notices use a narrow silk banner and disappear quickly.
- Health and qi use `TextureProgressBar` under/progress/over textures, not default `ProgressBar` skinning. The official Godot 4.4 class supports three texture layers: [TextureProgressBar documentation](https://docs.godotengine.org/en/4.4/classes/class_textureprogressbar.html).

### Breakthrough

- One quiet paper veil darkens/desaturates combat, then three talisman cards occupy the lower-middle band.
- A card contains, in order: icon medallion, short title, one benefit sentence and level mark. The selected state is a separate gold seal/rim, not merely a border-color swap.
- Every card stays within `330x390` logical pixels; icon art is capped at `96x96`; text remains runtime-rendered Vietnamese.
- Final Batch 01 uses custom Godot-drawn paper/bronze frames plus accepted raster sword/qi/hit icons; the planned raster nine-slice atlas is explicitly deferred rather than displayed as placeholder art. `NinePatchRect` remains the supported path for a later atlas: [NinePatchRect documentation](https://docs.godotengine.org/en/4.4/classes/class_ninepatchrect.html).

### Title, Pause And End States

- Keep `KEYART-001` as atmospheric title art, but replace the large dashboard-like title rectangle with a narrower hanging scroll/bronze bracket composition.
- Pause, victory and defeat reuse the same material family; victory leans gold/jade, defeat leans paper ash/cinnabar.
- All readable text is authored by Godot UI. Generated textures contain no letters, numerals, seals with legible characters or pseudo-calligraphy.

## Runtime Sprite Contract

- Animated characters and FX target `AnimatedSprite2D` plus a `SpriteFrames` resource. Godot 4.4 references: [AnimatedSprite2D](https://docs.godotengine.org/en/4.4/classes/class_animatedsprite2d.html) and [SpriteFrames](https://docs.godotengine.org/en/4.4/classes/class_spriteframes.html).
- Hero direction model is `side_only_last_horizontal`: use only `idle_side` and `move_side`, flip for left/right, and preserve the last horizontal facing during vertical movement.
- Stopping always returns `move_side -> idle_side`; a frozen movement contact pose is a blocker.
- Player/enemy/boss collisions remain gameplay-owned shapes. No collision rectangle or radius is painted into the asset.
- The boss telegraph, player aura and skill radii remain separate effects so gameplay readability can be tuned without regenerating body art.

## Batch 01 Asset Families

| Asset ID | Runtime identity | Generation shape |
|---|---|---|
| `HERO-001-idle-side` | Kiếm tu idle | 2x3, 6 frames, 512 px cells |
| `HERO-001-move-side` | Kiếm tu move | 2x4, 8 frames, 512 px cells |
| `ENEMY-001-wisp-idle` | Mặc Linh | 2x3, 6 frames, 512 px cells |
| `ENEMY-001-mac-lang-move-side` | Mặc Lang | 2x4, 8 frames, 384 px cells |
| `ENEMY-002-ta-tu-idle` | Tà Tu / elite identity | 2x3, 6 frames, 512 px cells |
| `BOSS-001-thien-giac-move-side` | Thiên Giác Mặc Lân | 2x2, 4 frames, 768x512 px cells |
| `PICKUP-001-linh-khi-idle` | Linh khí | 2x3, 6 frames, 256 px cells |
| `PROJECTILE-001-ngoc-phi-kiem-flight` | Auto-attack sword | 2x3, 6 frames, 384x256 px cells |
| `FX-001-kiem-an-impact` | Sword hit | 2x4, 8 frames, 384 px cells |
| `ARENA-001-cloud-ring` | Arena plate | 1600x900 single frame |
| `UI-RUNTIME-001` | HUD/cards/modals | custom Godot Controls + accepted raster icons |
| `UIKIT-001-kim-ngoc-components` | Optional future raster atlas | deferred, not displayed |

## Generation, Provenance And QA

- Every gameplay image begins with its committed harness JSON and prompt contract under `design/assets/harnesses/`.
- Every generation request uses the matching provenance spec under `assets/source-prompts/`.
- Generate each hero action separately; accept both actions independently before assembling a Godot atlas or `SpriteFrames` resource.
- Raw files live under `assets/raw/`; accepted processed files, frames, GIFs and pipeline metadata live under `assets/generated/`.
- Never point the game at a temporary Codex image directory.
- A good contact sheet is insufficient: inspect transparent frames, GIF cadence, runtime scale, pivot stability, chroma residue and edge fragments.
- UI source components must be extracted and tested at their actual control sizes. A decorative source atlas that still sits over default engine chrome is not accepted.
- Generated reference-driven assets record the museum object URLs above, but must remain original and contain no copied inscriptions or composition.

## Hard Rejection Criteria

- Plastic 3D render, glossy mobile-game bevel, neon cyberpunk or generic anime gacha finish.
- Default rounded dashboard panels, equal-weight information boxes or unmodified engine progress bars.
- Primitive-only player/enemy/pickup/impact presentation in a claimed final screenshot.
- Baked text, pseudo-Chinese characters, watermark, logo or visible grid lines.
- Hidden feet, duplicated limbs, warped identity, body-scale popping or locomotion made from whole-sprite wobble.
- Chroma-key residue, semi-transparent key-colored halos, edge-touching horns/tails/trails or neighboring-frame fragments.
- UI atlas elements that cannot be nine-sliced cleanly or icons that fail at 48–64 logical pixels.
- Calling the overhaul “commercial-ready” before in-game screenshots and the asset/runtime gates pass.

## Acceptance Checklist

- [x] Batch 01 first pick was reviewed at source scale and runtime scale before expansion.
- [x] Hero `idle_side -> move_side -> idle_side` passes Godot smoke without scale/pivot drift.
- [x] Mặc Lang and the boss have unmistakably different silhouettes at thumbnail scale.
- [x] Qi orb, projectile and impact each read as a different object/effect without labels.
- [x] Normal combat contains no default full-width dashboard bar and preserves open playfield space.
- [x] Breakthrough cards use authored material frames and real icons; all three fit at `1280x720`.
- [x] Title, normal combat, boss, breakthrough, pause, victory and defeat received severity-based visual review.
- [x] Asset harness, asset QA and Godot runtime checks pass for every accepted asset.
