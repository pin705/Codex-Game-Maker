# Playable Showcase QA

Showcase: `{{showcase_name}}`
Engine/version: `{{engine_version}}`
Date: `{{date}}`
Reviewer: `{{reviewer}}`

## Build Evidence

- [ ] Godot project opens or runs headless.
- [ ] Godot lint gate passes or warnings are recorded.
- [ ] Asset harness checks pass for runtime sprites/platforms.
- [ ] Asset QA gate passes or warnings are recorded.
- [ ] Runtime assets record generation provider and provenance.
- [ ] Placeholder assets, if any, are explicitly marked non-release-ready.
- [ ] Web build exported.
- [ ] Web preview served and hard-refreshed.

Evidence:

```text
{{commands_and_outputs}}
```

## Scene Scale

- [ ] Viewport is 16:9 and gameplay canvas keeps the intended composition.
- [ ] Player target size matches the scene scale plan.
- [ ] Platforms use aspect-preserving visual scale.
- [ ] Collectibles and finish object use generated assets at target size.
- [ ] No raw generated sprite is placed at source pixel scale.

Notes:

```text
{{scene_scale_notes}}
```

## Grounding And Collision

- [ ] Player starts grounded on frame one.
- [ ] Player does not float above large platforms.
- [ ] Player does not visibly sink into small platforms.
- [ ] Platform visual overlap is scaled per platform.
- [ ] Player foot sink is derived from the current floor/platform scale.
- [ ] Collision/debug rectangles are invisible in runtime.
- [ ] Falling off route resets or recovers safely.

Notes:

```text
{{grounding_notes}}
```

## Character State Machine

- [ ] Idle plays with no movement input.
- [ ] Run/walk plays only while grounded and moving.
- [ ] Run/walk loop alternates feet and does not scale-pop.
- [ ] Switching between idle and movement keeps the same target height, pivot, and foot baseline.
- [ ] Top-down side-only characters pass `idle_side -> move_side -> idle_side`.
- [ ] Top-down movement uses visible hand/foot alternation, not whole-body wobble.
- [ ] Runtime visual node count is one; no duplicate sprite/animation overlay exists.
- [ ] Jump rise/apex/fall use phase frames, not a blind loop.
- [ ] Landing returns to idle/run cleanly.
- [ ] Restart resets state, animation, pickups, and win state.

Notes:

```text
{{state_machine_notes}}
```

## Collectibles And Goal

- [ ] Every collectible instance animates.
- [ ] Every collectible instance can be collected.
- [ ] Collection radius matches visual placement.
- [ ] Count/HUD updates correctly.
- [ ] Finish object is grounded or intentionally anchored.
- [ ] Finish triggers a clear state after required objective completion.

Notes:

```text
{{objective_notes}}
```

## Top-Down Props, UI, And FX

- [ ] Collision-bearing generated props block movement through the intended base/trunk area.
- [ ] Player/enemy collision masks include the generated prop blocker layer when intended.
- [ ] Generated upgrade-card UI is clipped inside the panel and does not use raw source pixel size.
- [ ] Default engine button chrome is removed or intentionally styled under generated UI art.
- [ ] Upgrade, hit, pulse, kill, and passive skill feedback are visually distinct at gameplay scale.

Notes:

```text
{{top_down_ui_fx_notes}}
```

## Route Quality

- [ ] Spawn, first jump, midpoint, final jump, and finish are all reachable.
- [ ] Gaps fit the jump arc.
- [ ] Vertical steps fit the jump arc.
- [ ] Route has at least one readable challenge.
- [ ] Camera framing keeps the next objective visible enough.
- [ ] The demo has an ending, not just a sandbox.

Notes:

```text
{{route_notes}}
```

## Result

Gate: `PASS | PASS_WITH_WARNINGS | BLOCKED`

Blockers:

- `{{blocker}}`

Warnings:

- `{{warning}}`
