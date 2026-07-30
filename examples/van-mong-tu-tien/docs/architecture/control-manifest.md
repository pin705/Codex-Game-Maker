# Control Manifest

Status: Verified  
Release evidence boundary: keyboard, controller and touch are implemented; served-browser and physical-device verification remain pending  
Generated from: `docs/architecture/adr-0001-engine-web.md`  
Target: Godot 4.4, desktop + mobile landscape + future Web export; 1600×900 desktop authoring canvas and dedicated 844×390 phone canvas

## Input Actions

All shipped gameplay controls use project-specific actions. Bind the static `project.godot` Input Map and any bootstrap fallback to this same list; do not let the two sources drift.

| Action | Default bindings | Context | Behavior |
|---|---|---|---|
| `move_left` | physical `A`, `Left` | RUNNING | continuous left movement |
| `move_right` | physical `D`, `Right` | RUNNING | continuous right movement |
| `move_up` | physical `W`, `Up` | RUNNING | continuous upward movement |
| `move_down` | physical `S`, `Down` | RUNNING | continuous downward movement |
| `qi_pulse` | `Space` | RUNNING | cast Chấn Khí/Kiếm Trận if ready |
| `pause_game` | physical `P` | RUNNING / PAUSED | toggle pause once per fresh press |
| `restart_game` | physical `R` | all run/modal/result states | reload a fresh run |
| `confirm` | `Enter`, keypad Enter | START | start the run; must not also cast `qi_pulse` |

The three level-up cards are visible mouse-clickable/focusable/touchable `Button`s. The current project also binds UI-only `upgrade_1`, `upgrade_2`, and `upgrade_3` to `1`, `2`, and `3`; these are optional card shortcuts, not part of the eight-action gameplay contract. Controller focus and multitouch are implemented; served-browser and physical-device verification remain release gates.

| Optional UI action | Binding | Context | Scope |
|---|---|---|---|
| `upgrade_1` | `1` | LEVEL_UP | select left card |
| `upgrade_2` | `2` | LEVEL_UP | select center card |
| `upgrade_3` | `3` | LEVEL_UP | select right card |

Touch mapping is deliberately parallel to the Input Map: the left joystick mirrors the four movement actions, the lower-right sigil mirrors `qi_pulse`, and the upper-right pause target mirrors `pause_game`. All three retain a 64 px physical target floor after `canvas_items + expand`. The paused overlay owns explicit `TIẾP TỤC` (`Events.resume_requested`) and `NHẬP THẾ LẠI` actions, so resuming never requires a keyboard.

For WASD use physical keycodes so movement follows key position across keyboard layouts. For arrows, Space, Enter and P/R use the appropriate named key codes. Each generated `InputEventKey` mapping should set one primary key representation, consistent with the Godot 4.4 class guidance.

## Context Routing

| State | Gameplay input owner | UI input owner | Simulation advances? |
|---|---|---|---|
| START | none | start overlay / `confirm` | no |
| RUNNING | player/combat/session | HUD display only | yes |
| LEVEL_UP | none | upgrade-card overlay | no |
| PAUSED | resume/restart requests only | pause overlay buttons or P/R | no |
| VICTORY / DEFEAT | restart only | result overlay | no |

Context transitions consume the triggering event. In particular:

- Enter/`confirm` that starts a run cannot also cast `qi_pulse`.
- A card click cannot pass through to gameplay behind the overlay.
- Returning from a modal clears UI focus/pressed state before movement/combat resumes.
- P/R/confirm use just-pressed semantics and ignore `InputEventKey.echo`.

## Required Patterns

- Read movement with `Input.get_vector("move_left", "move_right", "move_up", "move_down")` or equivalent normalized/clamped logic.
- Gate all gameplay input and simulation through the authoritative session state.
- Use `CharacterBody2D` floating motion mode and physics-delta movement for player/enemy bodies.
- Use signals/events for UI-to-gameplay requests; UI displays health, XP, cooldown and state but does not own them.
- Keep balance values in `resources/tuning/` with one authoritative source (`game_balance.json` in the current slice).
- Keep restart lifecycle explicit: reload/reinitialize the gameplay scene so mutable state cannot leak.
- Cache procedural ink geometry or regenerate only on state change; do not allocate large arrays every frame without profiling.
- Provide a procedural title fallback when the key-art path is unavailable.
- Keep Vietnamese glyph coverage and readable text in the centered desktop canvas or the dedicated device-space phone canvas; never downscale the desktop menu wholesale on a phone.

## Forbidden Patterns

- No reliance on Godot default `ui_left`, `ui_right`, `ui_up`, `ui_down`, `ui_accept` or `ui_cancel` for shipped gameplay controls.
- No HUD/control text advertising a key that is absent from the Input Map.
- No direct keycode checks scattered across gameplay scripts; context code calls actions.
- No frame-dependent cooldown, spawn, invulnerability, movement or session timers.
- No process/damage/clock leakage while LEVEL_UP, PAUSED or terminal.
- No hardcoded balance duplication in several node scripts.
- No UI node directly changing HP, XP, enemy lists, boss flags or result state.
- No non-idempotent death/result callback and no double XP from repeated overlap/hit events.
- No asset reference into Codex generated-image temp folders or to unaccepted manifest paths.
- No runtime dependency on remote fonts, textures, audio or network access.
- No C#, GDExtension, required threads or Forward+/Mobile renderer on the Web MVP.

## Asset Rules

- Accepted generated assets live under `assets/generated/`; raw outputs under `assets/raw/`; prompt/provenance under `assets/source-prompts/`.
- `design/assets/asset-manifest.yaml` is the authoritative acceptance/release record.
- `generation_provider: gpt_image` describes provider provenance only; acceptance is tracked separately. `KEYART-001` is currently accepted with a warning; gameplay must still run without it.
- Key art must keep a processed 1280x720 crop, 320x180 preview, no text/watermark and a clean title-safe zone.
- Accepted raster actors, enemies, environments, UI and sigils carry the final presentation; procedural drawing remains a documented feedback/fallback layer. Gameplay must still fail safely if optional title key art is unavailable.

## Pause / Process Rules

- `RUNNING`: session delta, physics, attacks, cooldowns, spawns, pickups and damage enabled.
- `LEVEL_UP`: only choice UI, session input router and cosmetic overlay animations process.
- `PAUSED`: only pause/result UI, P/R routing and the touch/controller resume/retry buttons process.
- `VICTORY`/`DEFEAT`: no mutable gameplay simulation; only result UI/restart.
- If using `SceneTree.paused`, deliberately set UI/session `process_mode`; if using a logical state gate, apply it consistently to every timer/physics owner. Do not mix strategies casually.

## Testing And Evidence

- Logic: deterministic checks for XP overflow, upgrade caps, event/boss-once spawn, result priority and clean restart.
- Movement: compare cardinal/diagonal travel distance and verify the 54 px logical arena margin.
- Input: native + served Web checklist for WASD, arrows, Space, P, R, Enter, mouse cards and optional 1/2/3 card shortcuts.
- Browser focus: click outside/inside canvas, return to play, confirm no stuck key/ghost action.
- Visual: renderer captures cover desktop 1600×900, phone 844×390, portrait guard and 2100×900 ultrawide, including combat, boss, breakthrough, pause, victory and defeat.
- Performance: inspect peak frame time/entity counts near 2:30.
- Web export: record browser/version, served URL/method, console errors and result in playtest evidence.

Current native evidence: `tests/smoke_runtime.tscn`, `tests/smoke_frontend_flow.tscn`, `tests/smoke_mobile_support.tscn`, `tests/smoke_responsive_layout.tscn`, plus the hash-bound captures under `production/playtests/`. Godot 4.6.2 Web export and served Chromium smoke cover canvas focus, Enter/pointer/Escape transitions and 844×390 rendering in `production/evidence/platforms/`; Firefox/Safari controls, audio unlock, physical iOS/Android testing and sustained touch remain unverified.

## Official References

- Input events: https://docs.godotengine.org/en/4.4/classes/class_inputeventkey.html
- Top-down character body: https://docs.godotengine.org/en/4.4/classes/class_characterbody2d.html
- Web export/focus/platform constraints: https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_web.html
