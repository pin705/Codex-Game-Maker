# Top-Down Survivor Character Asset Rules

Use these rules for Vampire Survivors / Survivor.io style controllable
characters. These rules exist because side-view platformer habits repeatedly
produce bad top-down characters: oversized sprites, body wobble instead of
walking, missing idle states, duplicated limb repairs, and state machines that
stay stuck in movement.

## Lessons Captured

- A good raw image is not a runtime-ready sprite. The asset must survive
  slicing, alpha cleanup, scale normalization, Godot import, and state changes.
- Platformer run cycles do not transfer to top-down survivor games. The camera
  is different, the stride is smaller, and the character often only needs
  side-facing movement with runtime flip.
- Whole-body shaking is not walking. Movement must show readable hand and/or
  foot alternation while keeping the head, torso, tail, equipment, pivot, and
  foot baseline stable.
- If a generated character hides the feet, wears a long robe, carries a wide
  staff, or has a tail crossing cell boundaries, regenerate a movement-friendly
  design before local repair.
- Local foot repair is risky. Never paste new feet under old feet. Remove or
  repaint the old pixels first, then prove the final frame has one silhouette.
- Idle is its own action. A stopped character must not freeze on frame 0 of a
  walk/run sheet.
- Cross-state scale popping is a blocker. Idle and move must share target
  height, frame canvas, pivot, foot baseline, runtime scale, and facing model.
- Runtime behavior matters. Asset QA must be paired with a Godot smoke test
  that proves idle -> move -> idle.

## Recommended Direction Model

For first playable top-down survivor prototypes, prefer:

```yaml
direction_model: side_only_last_horizontal
states:
  - idle_side
  - move_side
runtime:
  left: flip_h idle_side/move_side
  right: normal idle_side/move_side
  vertical_movement: preserve last horizontal facing
```

Do not force weak `move_up` or `move_down` art into the game. Add those only
when generated quality is clearly good enough.

## Required Asset Contract

Each playable character action must record:

- exact canvas, grid, cell size, and safe margin
- selected chroma key
- expected frame count and FPS
- pivot and foot baseline
- target in-game height
- generation provider and source prompt
- raw source, processed output, frames, GIF preview, and pipeline metadata
- harness spec and harness report
- runtime state name and transition rules

## Harness Expectations

For `top_down_survivor` movement:

- geometry PASS is not enough
- require lower-body motion-phase evidence
- block too many adjacent near-neutral transitions
- block edge-touching tails, feet, staff, cape, or FX
- block semi-transparent shadow/glow/trail pixels in chroma-key locomotion
- block local repairs without pixel erasure evidence

For `idle`:

- 6-8 frames is enough
- motion must be restrained: breathing, blink, ear/tail accent, or subtle hand
  settle
- feet stay anchored
- no body translation, wobble, or scale animation
- accepted idle must share move-side canvas and runtime scale

## Runtime Smoke Test

Every Godot top-down survivor character must have a smoke test equivalent to:

1. Instantiate the player.
2. Assert exactly one direct visual sprite/animated sprite node.
3. Assert `idle_side` and `move_side` exist.
4. Assert frame counts match the asset contract.
5. Assert idle and move frames share the same canvas size.
6. Assert initial animation is `idle_side`.
7. Simulate movement input and assert animation becomes `move_side`.
8. Clear movement input and assert animation returns to `idle_side`.
9. Assert visual scale is unchanged across both states.

## Regenerate Instead Of Repairing When

- feet are hidden by clothing or pose
- the staff, weapon, tail, or cape crosses cells
- the loop only shakes the body
- north/south views are weaker than side-only movement
- local repair leaves duplicate feet, hands, shadows, or hard mask blocks
- the idle pose and move pose require different runtime scale

## Done Means

- raw asset passes harness
- processed frames and GIF preview exist
- asset manifest records runtime mapping
- Godot state machine switches idle -> move -> idle
- smoke test passes
- web export uses the updated assets
