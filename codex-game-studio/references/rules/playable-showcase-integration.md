# Playable Showcase Integration Rules

These rules capture recurring failures found while building generated-asset
platformer showcases. Apply them whenever generated art becomes a playable
Godot scene, web preview, or public demo.

For Vampire Survivors / Survivor.io style controllable characters, also apply
`references/rules/topdown-survivor-character-assets.md`.

## Problems To Prevent

- Raw generated art was visually attractive but did not fit gameplay scale.
- Deterministic placeholder art was treated as if it completed the GPT Image
  asset workflow.
- Character frames had inconsistent pivots, scale, and grounded foot lines.
- Run/walk sheets looked like motion but did not alternate feet as a real loop.
- Top-down survivor movement reused platformer side-run poses or moved the
  entire sprite, causing jitter instead of a grounded shuffle.
- Animation repair left both the original limb and shifted limb visible,
  causing a two-character or ghost-overlay look during movement.
- Chroma-key raw sheets used semi-transparent shadow/glow pixels, producing
  near-key purple or green residue after alpha cleanup.
- Jump sheets were looped like idle/run even though jump is a phased state.
- Neighboring-frame tails or limbs appeared inside a frame after sheet slicing.
- Platform props were cropped or stretched to fit a level.
- Collision rectangles leaked into runtime visuals.
- Player, platforms, and collectibles were too large for a 16:9 scene.
- Generated UI card art was placed at raw source scale or mixed with default
  engine button chrome, causing oversized unreadable upgrade screens.
- Generated FX existed as assets but were too small or too generic to read in
  gameplay.
- Generated tall props looked solid but had no `StaticBody2D`/collision layer,
  so the player walked through them.
- The player spawned above the platform or fell forever due to missing grounding.
- Pickups were placed visually but only the first instance could be collected.
- Placeholder primitives replaced generated collectible assets.
- The level had no route quality, recovery, or finish condition.
- Fixed visual offsets made small platforms look wrong even when large platforms
  looked correct.

## Required System

Every playable generated-asset showcase must have four contracts:

1. `scene-scale-plan.yaml`
   Defines the 16:9 viewport, world size, target in-game pixel sizes, player
   hitbox, platform visual scale, platform collision top, camera limits, route
   constraints, collectibles, and finish condition.

2. Asset harnesses
   Every player action, collision-bearing platform, large prop, pickup, and
   finish object needs a harness or import contract. Do not rely on free-form
   prompt layout for runtime assets.

3. Runtime import metadata
   Record generation provider, raw source paths, processed output paths,
   pivots, frame sizes, target display size, animation FPS, loop/non-loop
   status, collision role, and Godot node target.

4. Playable QA evidence
   Record a smoke test that covers spawn, idle, movement, jump, pickup
   collection for every instance, finish trigger, restart, and web preview.

## Grounding Contract

For platformers, keep a strict split between collision and visuals:

- Store each platform as `top_y`, `collision_width`, `collision_height`,
  `visual_width`, and optional `visual_top_overlap`.
- Place the collision surface at `top_y`.
- Place platform art from its own visual contract. Do not infer collision from
  the sprite center.
- Platform visual overlap must scale with the platform art scale. A fixed
  overlap can work for one platform size and fail on another.
- Player visual foot sink must be derived from the current floor/platform scale,
  not one global constant.
- Character sprites must use a bottom/feet pivot for grounded states.
- Jump/airborne frames may use different visual framing, but the runtime state
  machine must keep the hitbox and collision foot position stable.

## Animation Contract

- `idle` loops at low FPS and must be the default no-input state.
- `walk`/`run` must alternate left and right foot contacts.
- Top-down survivor `move_*` loops should keep the head, torso, tail,
  equipment, pivot, and foot baseline stable. Animate restrained hand/foot
  alternation; do not create movement by scaling, translating, or globally
  warping the whole character.
- Locomotion character designs need visible separated feet. Long robes, skirts,
  staffs, capes, oversized tails, or props that cover foot contact poses should
  move to idle/cast/attack art or be replaced by a movement-friendly variant.
- If a character's feet cannot be isolated cleanly after one repair pass,
  regenerate the movement variant instead of stacking more local fixes.
- Whole-body shake, sprite wobble, camera jitter, or pivot jitter is not a
  valid walk/run loop. Feet and/or hands must visibly alternate.
- If an animation is repaired by moving local body parts, the old pixels must
  be cleared or repainted before the moved part is pasted. A runtime frame must
  show one clean character silhouette, not old and new limbs at once.
- Keep semi-transparent shadows, glows, dust, and motion trails out of
  chroma-key raw locomotion sheets. Use separate FX/imported opaque elements.
- Cross-state playable hero actions must share target height, foot baseline,
  pivot, and runtime scale. If switching from movement to idle makes the
  character grow, shrink, float, or sink, the action bundle is blocked.
- `jump` is not a simple loop. Runtime should select or hold phase frames:
  anticipation/takeoff, rise, apex, fall, and land.
- First and last loop frames must connect without a pop.
- Frame extraction must prove no neighboring-frame fragments remain.
- Do not ship a playable showcase with obvious tail, foot, weapon, or FX
  fragments from adjacent cells.
- If a playable project uses local deterministic placeholders, label them as
  placeholders in the README, manifest, and QA evidence. They can validate
  runtime structure but not the final GPT Image asset flow.

## Level Contract

Showcases are still games. A small demo route must include:

- A grounded spawn on the first platform.
- At least four reachable platforms or equivalent route beats.
- Gaps and vertical steps that match the player jump arc.
- Collectibles placed inside collection radius on reachable route positions.
- Every collectible instance animated and collectible, not only the first one.
- A visible finish object that triggers a clear state.
- Restart input and recovery for failed jumps.

For top-down / survivor showcases:

- Tall visual props such as trees, rocks, pillars, crates, and walls must be
  imported as separated visuals plus collision blockers, usually `StaticBody2D`
  on a dedicated props layer.
- Player and enemy collision masks must include the props layer when those
  props are meant to block movement.
- Collision should usually cover the walk-blocking base/trunk, not the full
  canopy or decorative transparent bounds.
- Projectile collision with props must be an intentional design choice, not an
  accidental result of sharing the enemy layer.

## UI And FX Contract

- Generated UI frames must be constrained to runtime control sizes. Do not use
  raw source pixel size as the button/card size.
- HUD health, XP, stamina, and cooldown bars should use generated image frames
  or a deliberately styled skin. Do not ship default grey engine bars in a
  generated-asset showcase.
- Remove default engine button chrome when generated UI art is the intended
  card frame. Generated art should not sit on top of an unrelated default box.
- Clip card contents and cap icon sizes so generated icons cannot overflow the
  panel.
- Smoke tests should assert card count, card size, and clipping for generated
  upgrade-choice UI.
- Gameplay FX must be visible at scene scale. Upgrades, pulse attacks, hits,
  and kills should have distinct readable feedback, not just a tiny reused pop.

## Review Checklist

Before calling a showcase ready:

- Run `tools/check-asset-harness.ps1` for raw runtime sheets.
- Run `tools/check-asset-qa.ps1 -Root .`.
- Run `tools/check-godot-lint.ps1 -Root .`.
- Run `tools/preview-godot-web.ps1 -Project .` or export and serve the Web
  build manually.
- Take or record evidence at start, on a small platform, after collecting the
  last pickup, and at the finish.
- For top-down showcases, also record evidence that the player cannot walk
  through at least one generated blocker prop and that upgrade-choice UI stays
  within the viewport.
- Hard refresh the browser when verifying a new Godot Web `.pck`.
