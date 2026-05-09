# Playable Asset Integration Playbook

This playbook turns lessons from the cat platformer showcase into repeatable
Codex Game Maker workflow rules. It also captures the follow-up top-down
survivor lessons from the vampire-grove-cgm showcase.

## What Went Wrong

- Good-looking generated art was placed before a scene scale contract existed.
- Character, platform, crystal, and flag sizes were tuned by eye instead of by
  a shared 16:9 runtime plan.
- Run and jump frames were accepted too early. The run did not read like a
  stable foot-alternating loop, and jump frames needed phase selection.
- Some generated sheets had slicing risks such as neighboring-frame fragments.
- Platform art was stretched or cropped before collision and visual anchors
  were defined.
- Collision/debug rectangles became visible in the playable scene.
- The player spawned/fell incorrectly until collision top and visual foot pivot
  were separated.
- Pickup instances were not all collectible until they used group/metadata
  instead of duplicate node names.
- The demo lacked route polish and finish verification until a small full
  playthrough was treated as required evidence.
- A fixed platform visual overlap worked on large platforms but made small
  platforms look like the player was sinking.
- Top-down survivor movement reused platformer instincts at first: the character
  looked like it was running side-on instead of doing a restrained arena-game
  shuffle.
- Several animation fixes accidentally created duplicate limb/body overlays.
- Idle was treated as optional, so the runtime could stay visually stuck on a
  movement pose after the player stopped.
- Generated UI and HUD art needed runtime size constraints; raw source scale
  was too large for in-game controls.

## New Default Workflow

1. Create or update `design/scene-scale-plan.yaml`.
2. Create harnesses for every runtime sprite, platform, pickup, and finish prop.
3. Generate raw sheets from harness prompt contracts.
4. Run harness and asset QA before engine import.
5. Import only accepted assets into Godot.
6. Build a small state machine before tuning animation visuals.
7. Place collision from metadata, not from sprite centers.
8. Verify large and small platform grounding separately.
9. Verify every repeated pickup instance.
10. Export and hard-refresh the Web preview before judging the result.
11. Fill `production/smoke-tests/playable-showcase-qa.md`.

For top-down survivor characters, also create a character contract from
`codex-game-studio/references/templates/topdown-survivor-character-contract.yaml`
before generating idle/move sheets.

## Required Files

- `codex-game-studio/references/rules/playable-showcase-integration.md`
- `codex-game-studio/references/templates/scene-scale-plan.yaml`
- `codex-game-studio/references/templates/asset-harness-spec.yaml`
- `codex-game-studio/references/templates/topdown-survivor-character-contract.yaml`
- `codex-game-studio/references/templates/playable-showcase-qa.md`
- `codex-game-studio/references/rules/topdown-survivor-character-assets.md`

## Practical Rules

- Do not place raw generated images at source pixel scale.
- Do not use fixed visual offsets when platform sizes vary.
- Do not infer platform collision from the rendered platform sprite.
- Do not loop jump sheets blindly.
- Do not accept walk/run loops without alternating foot contacts.
- Do not use whole-body wobble as top-down movement.
- Do not ship a controllable character without an idle -> move -> idle smoke
  test.
- Do not repair feet by pasting a second pair under the old pair.
- Do not trust duplicate node names for repeated gameplay objects.
- Do not call a showcase done without a finish condition and full route check.
