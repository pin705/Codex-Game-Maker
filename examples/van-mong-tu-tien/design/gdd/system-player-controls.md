# System GDD: Player & Controls

Status: Implemented for keyboard, controller and multitouch; browser and physical-device verification pending  
ID: SYS-01  
Source concept: `design/gdd/game-concept.md`

## Overview

This system converts explicit keyboard actions into responsive 8-direction movement, owns player HP/contact immunity and keeps the avatar inside the fixed logical 1600x900 arena (shown in a 1280x720 window). It exposes state; it does not own attacks, XP or UI.

## Player Fantasy

Người chơi là kiếm tu thân pháp linh hoạt: hướng chạy đổi ngay, đường chéo không nhanh hơn đường thẳng và một sai lầm vẫn cho khoảng ngắn để thoát vòng vây thay vì nhận sát thương liên tục mỗi frame.

## Detailed Rules

- `move_left`, `move_right`, `move_up`, `move_down` read continuously only in `RUNNING`.
- Defaults are both WASD and arrow keys. Use `Input.get_vector(...)` or equivalent clamped vector so diagonal magnitude is at most 1.
- Set `CharacterBody2D.motion_mode` to `MOTION_MODE_FLOATING`, assign `velocity = direction * move_speed`, then use `move_and_slide()` in physics updates.
- When direction is zero, velocity becomes zero on that physics tick; no acceleration/inertia in MVP.
- Clamp the player center inside a 54 px margin of the logical arena. Enemy bodies do not physically pin the player; contact uses distance/hit events.
- Player begins each fresh run at arena center, full 120 HP, alive, no cooldown carry-over.
- A valid enemy contact hit subtracts that enemy's damage, emits health feedback and starts 0.55 s immunity. Further contacts during immunity do no damage.
- At HP ≤ 0, clamp HP to 0, emit `player_died` exactly once and disable further movement/damage.
- `pause_game`, `restart_game`, `confirm` and breakthrough selection are interpreted by session/UI context, not by the player movement script.
- Controls shown to the player: `WASD / Phím mũi tên: Di chuyển`, `Space: Kiếm Trận`, `P: Tạm dừng`, `R: Chơi lại`.

## Formulas And Tuning

| Value | Formula / Range | Source | Notes |
|---|---|---|---|
| logical viewport | 1600x900; window override 1280x720 | project settings | fixed design resolution; stretch preserves 16:9 |
| spawn position | `(800, 450)` | session config | reset every run |
| move speed | 305 px/s; tune 280–320 | balance Resource | independent of frame rate |
| max HP | 120 | balance Resource | upgrades may add maximum and current HP |
| arena margin | 54 px | balance Resource | player center clamp |
| contact immunity | 0.55 s; tune 0.45–0.70 | balance Resource | visible flash/halo required |
| incoming damage | `max(0, enemy.contact_damage)` | enemy profile | only once per immunity window |

## Input Context Matrix

| Context | Movement | Enter / confirm | Space / qi_pulse | P | R / restart_game | Mouse |
|---|---|---|---|---|---|---|
| START | ignored | start | ignored | ignored | fresh run | start button |
| RUNNING | move | ignored | Chấn Khí request | pause | restart | ignored |
| LEVEL_UP | ignored | ignored | ignored | ignored | restart | choose a card |
| PAUSED | ignored | ignored | ignored | resume | restart | resume/restart buttons |
| VICTORY / DEFEAT | ignored | ignored | ignored | ignored | restart | restart button |

## Edge Cases

- Opposite directions pressed together: their axis cancels to zero; the other axis remains valid.
- Focus is lost: movement must stop when input is no longer reported; no stuck velocity after returning.
- Key echo: pause/restart/start use just-pressed/context transitions, never OS repeat cadence.
- Player is resized or viewport stretches: clamp uses logical arena coordinates, not raw browser CSS size.
- Several enemies overlap: only the first accepted hit in an immunity window applies; order must not multiply damage.
- Damage and victory occur on the same physics tick: session flow owns the result priority.

## Dependencies

Upstream: Godot Input Map, session state, tuning Resource.  
Downstream: combat origin, enemy target position, HUD health, defeat transition.  
Signals/events: `Events.player_health_changed(current, maximum)` and local `CultivatorPlayer.died()`.

## Visual And Audio Requirements

Assets needed: none; procedural ink silhouette/aura.  
Feedback moments: movement direction cue, cyan aura, vermilion hurt flash, brief immunity blink that never hides position, ink dissolve on death.  
UI/HUD needs: HP bar + numeric current/max; concise controls panel.  
Audio cues: optional short hurt and death cues; game remains readable muted.

## Acceptance Criteria

- [ ] WASD and all four arrow keys move in the advertised directions in native and Web builds.
- [ ] Diagonal and cardinal movement cover equal distance over the same duration within tolerance.
- [ ] Releasing all movement keys stops the player within one physics tick.
- [ ] Player never crosses the 54 px logical arena margin.
- [ ] Overlapping contacts cannot damage more than once per 0.55 s immunity window.
- [ ] HP reaches 0 once, emits one death, and cannot become negative.
- [ ] Movement and damage freeze in PAUSED/LEVEL_UP/terminal states.

## Godot Notes

Likely scene/resource structure: `CharacterBody2D` root, collision shape, procedural visual child, hurt `Area2D`; typed `player.gd`.  
Web export risks: canvas focus and keyboard capture; test browser focus loss/re-entry.  
Official docs verified: https://docs.godotengine.org/en/4.4/classes/class_characterbody2d.html and https://docs.godotengine.org/en/4.4/classes/class_inputeventkey.html

The official class docs identify `MOTION_MODE_FLOATING` as suitable for top-down games and warn against depending on user-configurable key-repeat timing. Runtime verification remains pending.
