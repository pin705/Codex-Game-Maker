# Art Bible V4: Vân Mộng Tu Tiên

Status: V4 master UI board approved by user; full desktop/mobile implementation and runtime revalidation in progress
Release evidence boundary: V4 replaces the rejected V3 UI composition and chrome strategy. Existing captures are baseline evidence only until the complete desktop and dedicated 844×390 matrix is refreshed.
Source concept: `design/gdd/game-concept.md`  
Asset brief: `design/assets/visual-overhaul-batch-01.md`  
Scale contract: `design/assets/scene-scale-plan.yaml`  
Target: commercial-adjacent authored 2D presentation at native resolution; full release readiness still requires Web/manual QA

## V4 Commercial UI Reset — User Directed

The user rejected the current V3 presentation as visually fragmented, cheap and
overloaded: buttons and text are weak, the hub reads like a dashboard, large
backgrounds are repeatedly cropped, and generated chrome fights the world art.
V4 therefore supersedes V3 for every UI surface while preserving the underlying
game systems and accepted world/actor assets.

Primary user reference:
`design/art/lookdev/v4/user-commercial-ui-reference.png`. It is a composition,
hierarchy and material-density reference supplied by the user. It is not a
runtime bitmap, a source for copied trade dress, or permission to reproduce
another game's layout/iconography.

Approved implementation target:
`design/art/lookdev/v4/master-board-candidate-01.png`. The user approved this
single overview board on 2026-07-30 and requested the implementation follow it
across every desktop and mobile surface. The board locks composition hierarchy,
material restraint, component silhouettes, combat density and cross-screen
coherence. Generated labels and exact atlas pixels are not runtime assets;
Godot-native controls and live Vietnamese text must reproduce the system.

V4 non-negotiable rules:

- One material system across the whole game: matte blue-black ink, warm muted
  paper, thin aged bronze structure, restrained jade focus and cinnabar danger.
- Layout and type establish hierarchy before ornament. No label may be shrunk to
  rescue an overcrowded panel; content is reduced or recomposed instead.
- Major panels, buttons, tabs, HUD islands and modals use scalable Godot-native
  clipped silhouettes. Generated atlases may supply icons or isolated artwork,
  but not stretched/cropped control chrome.
- Meta screens share one subdued sect-world backing. Stage art appears only as
  a contained preview or as the actual combat world, never as a different
  full-screen wallpaper behind every menu.
- Phone landscape uses complete aspect-preserved art with ink extension fields;
  important subjects and frames cannot be cover-cropped to fill 844×390.
- Desktop body copy targets 17–19 logical px, action labels 17–20 px and major
  headings 30–46 px. Phone body copy remains at least 15–16 physical px where
  displayed; optional prose is removed before text is reduced.
- The hub has three unequal priorities only: identity/loadout, current
  expedition, and a compact command rail. It may not become a grid of seven
  equal buttons or a wall of framed cards.
- Combat HUD uses compact edge islands and a reduced five-skill rail. The arena
  center, player movement lane and boss telegraphs remain visually dominant.
- Icons and portraits are color-normalized toward ink/paper before integration;
  saturation is reserved for state. Blue neon, violet corruption, jade safety
  and gold reward cannot all compete at full intensity in one frame.
- Repetition is controlled: one surface silhouette may appear at most twice in
  the same screen unless it represents a deliberate list/grid family.

V3 raster chrome (`UIKIT-006`, `UIKIT-007`, `UIKIT-008`, scroll and talisman
panel crops) remains in the repository for provenance and rollback but is no
longer the default component layer. V4 production UI is native/custom-drawn;
icons, portraits and environment art remain reusable after palette and scale QA.

## Why V2 Exists

The current title illustration establishes a useful mood, but the playable scene does not carry that quality into the game. The baseline screenshots show a dark background with small procedural circles and polygons for nearly every gameplay object, while the HUD and breakthrough screen use broad flat rounded panels with almost no authored ornament, texture, hierarchy or iconography.

Audited evidence:

- `production/playtests/title-screen-runtime.png`: strong atmospheric key art, but the large flat title panel looks detached from the painting.
- `production/playtests/gameplay-runtime.png`: player, enemies, qi, projectiles and hits are procedural primitives; most silhouettes read as symbols instead of illustrated beings.
- `production/playtests/upgrade-runtime.png`: three equal dark rectangles dominate the screen; tiny placeholder marks replace meaningful upgrade art.
- Runtime implementation confirms the gap: entity files rely on `_draw()` primitives and `scripts/ui/hud.gd` relies on `StyleBoxFlat` and default `ProgressBar` styling.

V2 therefore supersedes the former “procedural runtime plus one splash” art strategy. Procedural drawing may remain only as a documented fallback, collision/telegraph aid or temporary debug layer. It is not the intended shipped presentation.

## V3 Arsenal Direction — User Approved

The player approved `design/art/lookdev/v3/arsenal-reference-approved.png` as the target for the next production pass. The reference is used for hierarchy, material response, density and authored silhouette—not as a bitmap pasted behind live controls and not as permission to copy another game's trade dress.

V3 adds the following non-negotiable rules to the living-ink identity:

- Combat HUD is a constellation of three edge-anchored islands plus a raised five-skill rail. The middle arena remains open; no broad lower bar may consume the character's movement lane.
- Inventory uses a legible equipment column, a dense slot grid and a visually separate comparison folio. These three regions have different silhouettes and depth, not three equal dashboard cards.
- Every item and active skill has its own game asset. Rarity frames are presentation chrome only and can never substitute for an item icon.
- Item icons use centered, recognizable relic silhouettes with painterly metal, jade, silk, stone or talisman material. They remain readable at 56–96 logical pixels and contain no baked text, border, rarity color field or watermark.
- Active-skill icons use one bold brush silhouette, one restrained element accent and a dark circular ground. Cooldown, rank, binding, locked and casting states remain live UI layers.
- Companion management pairs one large illustrated subject with a compact assist state, bond rule and contained evolution strip. Evolution markers must never hang below the mobile safe area.
- Desktop supports editorial density; 844×390 phone uses fewer words, larger protected labels and icon-first choices. It is a dedicated composition rather than a scaled desktop screenshot.
- Aged bronze is thin structural hardware. Blue-black lacquer is matte and absorbent. Paper shows fibre and wash. Jade/gold/violet/cinnabar communicate state without glossy plastic bevels or uncontrolled bloom.

Rejected direction: `design/art/lookdev/v3/scroll-heavy-candidate-rejected.png` is too scroll-dominant and leaves insufficient visual distinction between equipment, inventory, skills and companion states. The decision record is `design/art/lookdev/v3/decision.md`.

## V3 Authored UI Identity Batch — Runtime Revalidation Recorded

This additive batch keeps style version `3.0.0` and digest
`0d1b060efbb561c8625b13cd07912a49808ec704ce1d0db8ebf616d231d109da`.
It does **not** reseal `design/art/style-lock.json`: the full shared-component
migration, refreshed desktop/phone captures and independent review must be
accepted first. Consequently this edited art bible is not new style-lock or
player-ready evidence; the lock's art-bible hash is intentionally left for the
final accepted migration seal.

`UIKIT-007-ritual-surface-atlas` extends the approved arsenal material language
through one committed 1536×1024 atlas:

- Raw source: `assets/raw/ui/UIKIT-007-ritual-surface-atlas-v001.png`, SHA-256 `302172f890f74428fce745a103839cf52ce867e61b6497b2eecba2a8acd82c2a`.
- Alpha source and runtime delivery: `assets/generated/ui/UIKIT-007-ritual-surface-atlas/source/atlas-transparent.png` and `runtime/atlas-transparent.png`, both SHA-256 `02f7a634a8857745c0cb2b3aa1195ff06596a05c0dc0bcdeea5922dfb729828c`.
- Provenance and processing: `assets/source-prompts/UIKIT-007-ritual-surface-atlas.yaml` plus `assets/generated/ui/UIKIT-007-ritual-surface-atlas/pipeline-meta.json`; chroma cleanup records 770,024 transparent and 22,487 partially transparent pixels.
- Source-wired regions: desktop title scroll and wide header, guarded modal and result plates, raised five-skill rail, attack medallion, joystick medallion and the live boss identity/health bar. `status_plaque` alone remains reserved and unbound.
- Only `wide_header`, `modal_guard` and `result_plate` are dedicated nine-slice surfaces, using margins 76/38/76/38, 66/52/66/52 and 86/52/86/52 respectively. The scroll, boss bar and skill rail preserve their source aspect. Current native 1600×900/844×390 captures show the square touch targets and boss bar without blocking distortion or overlap; physical-device review remains open.
- The atlas contains no text, number, cooldown, rarity, key binding, logo or pseudo-calligraphy. Those remain live Godot nodes.

The batch also bundles two OFL typography families from the official Google
Fonts repository so Vietnamese presentation never depends on an OS or remote
font:

| Family | Project files and SHA-256 | Runtime role | License/provenance |
|---|---|---|---|
| Be Vietnam Pro | `assets/fonts/BeVietnamPro-Regular.ttf` — `cd1ef6e9d7db28ad5cdb88a65ccbe693870e60d340b791f349d248342b4fe4c3`; `BeVietnamPro-SemiBold.ttf` — `bd8e27eb02720b9d91e59e4f10a90878643219f25ce6a8d9a4f06a8a88d3bb71` | Regular for body/HUD/default labels; SemiBold for buttons, tabs, eyebrows and compact emphasis | [Google Fonts Be Vietnam Pro](https://github.com/google/fonts/tree/main/ofl/bevietnampro); local `OFL-BeVietnamPro.txt`, SHA-256 `6b7f8f73609a25ea78c891e34cf37b06f8a676b7ea986e941e43b009110f2a85` |
| Literata variable roman | `assets/fonts/Literata-Variable.ttf` (upstream `Literata[opsz,wght].ttf`) — `b41138c9373112f32abb589cc22e8674b06ed4048b0c513be922bdd26f274440` | Large ritual titles and high-tier headings only | [Google Fonts Literata](https://github.com/google/fonts/tree/main/ofl/literata); local `OFL-Literata.txt`, SHA-256 `8742963604cd89dc81437811a850018fc03b2bfad686d7422c8235967c87614e` |

These hashes match the recorded official raw downloads and Godot FontFile import
artifacts. A clean Godot 4.6.2 parse, current Vietnamese native captures at
1600×900 and 844×390, and served Chromium rendering now pass. Cross-browser,
physical low-DPI and independent visual review remain open.

`UIKIT-008-control-silhouettes` removes the remaining one-shape control problem:
primary, secondary, back, stepper, destructive and confirm roles use distinct
original silhouettes with live Vietnamese captions. `PORTRAIT-001` supplies six
bestiary/companion dossier illustrations, `PORTRAIT-002` supplies player HUD and
Thiên Giác identity portraits, and `ACHIEVEICON-001` supplies six semantic
achievement seals. All four families are integrated candidates with current
native evidence; none is independently accepted or release-ready yet.

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
- Body and HUD copy use Be Vietnam Pro Regular; actions and compact emphasis use Be Vietnam Pro SemiBold; Literata is reserved for large ritual headings. All fonts are bundled project-local resources with Vietnamese copy rendered at runtime.
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
| `UIKIT-007-ritual-surface-atlas` | Title/header/modal/result/HUD/touch material chrome | 1536x1024 atlas; nine isolated regions; fixed-shape plus three dedicated nine-slices |
| `UIKIT-008-control-silhouettes` | Primary/secondary/back/stepper/destructive/confirm controls | 1536x1024 atlas; six isolated regions; four dedicated nine-slices plus two uniform medallions |
| `PORTRAIT-001-bestiary-companion-atlas` | Codex threats and Thanh Vân Hồ dossier identity | 3x2, six 512 px cells |
| `PORTRAIT-002-hero-boss` | Player HUD and Thiên Giác boss identity | 2x1, two 887 px cells |
| `ACHIEVEICON-001-six-seals` | Six distinct achievement identities | 3x2, six 512 px cells |
| `FONT-001-be-vietnam-pro` | Vietnamese body, HUD and action typography | Regular + SemiBold project-local TTF files |
| `FONT-002-literata` | Ritual display typography | Variable roman `opsz,wght` TTF |
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
- [x] UIKIT-007/008, PORTRAIT-001/002, ACHIEVEICON-001 and bundled fonts pass current Godot import/parse plus 1600×900 and 844×390 capture checks.
- [ ] The refreshed full-surface V3 batch receives independent visual review before any player-ready, release-ready or commercial-ready claim.
