# System GDD: Combat

Status: Implemented and native-smoke verified; Web/manual balance verification pending  
ID: SYS-02  
Source concept: `design/gdd/game-concept.md`

## Overview

Combat combines an automatic nearest-target qi sword with one manual radial skill, **Chấn Khí / Kiếm Trận**, creating a readable cadence between constant offense and deliberate escape/clear moments. The shipped project action for the skill is `qi_pulse`.

## Player Fantasy

Phi kiếm tự hộ chủ khi người chơi chuyên tâm vào thân pháp; đúng lúc bị vây, một lần kết ấn bằng `Space` mở kiếm trận quét sạch khoảng thở.

## Detailed Rules

### Auto Qi Sword

- While `RUNNING`, an attack accumulator advances with gameplay delta. At the interval, search the bounded living-enemy collection.
- Choose the nearest target; ties use a stable instance/order key so deterministic tests do not flap.
- If no valid target exists, consume/reset that interval without spawning a projectile; do not bank a burst.
- Spawn a visible sword from the player toward the target snapshot. Projectile travels straight, expires on hit/range/lifetime and damages one enemy by default.
- A projectile cannot hit the same enemy more than once. Destroy/return it to pool immediately after its pierce count is exhausted.

### Sword Ring / Kiếm Trận

- `qi_pulse` (`Space`) in `RUNNING` requests the skill. If cooldown is ready and player alive, resolve one radial hit centered on the player.
- Each living enemy whose hurt center is within current radius receives one damage packet; one cast cannot double-hit an enemy.
- Start cooldown on a successful cast only. Pressing during cooldown gives a quiet unavailable cue and does not reset it.
- Cooldowns advance only in `RUNNING`; pause, level-up and terminal screens freeze them.
- No knockback or crowd-control is required for MVP.

### Damage Contract

- Damage is a positive integer/float payload with source ID and attack ID.
- Enemy HP is clamped at 0; death runs exactly once even if multiple hits land in a tick.
- A dead enemy stops targeting/contact immediately, reports XP/boss flag and is removed after its short death feedback.
- Combat does not decide victory or create upgrade UI; it emits facts.

## Formulas And Tuning

| Value | Formula / Range | Source | Notes |
|---|---|---|---|
| auto damage | 22; tune 18–30 | `resources/tuning/game_balance.json` | multiplied by damage upgrades |
| auto interval | 0.72 s; lower via attack-speed ranks | `resources/tuning/game_balance.json` | current implementation divides by multiplier |
| target selection | nearest living enemy in scene set | `scripts/gameplay/main.gd` | no hard range in current MVP; keep caps bounded |
| projectile speed | 690 px/s | `resources/tuning/game_balance.json` | visual travel, not homing |
| projectile lifetime | 1.45 s | `resources/tuning/game_balance.json` | cleanup guard |
| base projectiles | 1; +1 per `extra_sword` rank | player state | fan spread ±10° |
| ring damage | 48 | `resources/tuning/game_balance.json` | multiplied by pulse/global modifiers |
| ring radius | 190 px; ×1.15 per `qi_pulse` rank | `resources/tuning/game_balance.json` | telegraph matches actual hit radius |
| ring cooldown | 5.5 s | `resources/tuning/game_balance.json` | displayed as fill + seconds |
| effective damage | `round(base × global_damage × skill_damage)` | combat state | minimum 1 on valid hit |

## Canonical Upgrade Effects

| ID | Vietnamese card | Effect per stack | Cap |
|---|---|---|---|
| `sword_damage` | Vạn Kiếm Quy Tông | Phi kiếm +32% sát thương | 6 |
| `attack_speed` | Kiếm Tâm Thông Minh | tốc độ xuất kiếm +18% | 5 |
| `extra_sword` | Phân Quang Kiếm Ảnh | +1 phi kiếm mỗi lần ngự kiếm | 3 |
| `piercing_sword` | Phá Vọng Kiếm Ý | phi kiếm xuyên thêm 1 mục tiêu | 3 |
| `cloud_step` | Lăng Vân Bộ | tốc độ di chuyển +12%, hút linh khí +8% | 4 |
| `jade_body` | Thanh Ngọc Đạo Thể | +25 HP tối đa và hồi 25 | 5 |
| `spirit_well` | Tụ Linh Quyết | hút +34%, XP +12% | 4 |
| `qi_pulse` | Thái Hư Chấn Khí | Chấn Khí rộng +15%, mạnh +28% | 4 |
| `life_stream` | Trường Sinh Khí | hồi sinh mệnh mỗi giây +0.65 | 4 |
| `phoenix_blade` | Phượng Hoàng Kiếm Hỏa | định kỳ phi kiếm gây sát thương gấp bội | 2 |

The current implementation also has a deterministic `emergency_heal` fallback if no catalog card remains; it must never make the offer array empty.

## Edge Cases

- Target dies before projectile arrives: projectile continues along its launch vector and expires normally; it does not teleport to a new target.
- Enemy exits range after launch: existing projectile remains valid.
- Several enemies at identical distance: stable tie-breaker prevents jittering target choice.
- Pressing Space/`qi_pulse` on title/choice/pause: context consumes or ignores it; no deferred cast when returning to play.
- Cooldown reaches zero during a state transition: it is ready only after returning to `RUNNING` and receiving a fresh press.
- Ring cast kills boss while player receives lethal contact: session result priority resolves the outcome once.
- Upgrade at cap: remove it from future card candidate pool.

## Dependencies

Upstream: player position/alive state, session state, enemy registry/group, progression modifiers, tuning.  
Downstream: enemy HP/death, XP drop, boss result, HUD cooldown, VFX/audio.  
Signals/events: `Events.pulse_state_changed(remaining, cooldown)` plus local enemy `died(...)`; projectile hits are resolved internally by main orchestration.

## Visual And Audio Requirements

Assets needed: none; procedural cyan-white sword polygons, `Line2D` trails and radial ring.  
Feedback moments: launch line, hit spark, enemy flash, small damage cue, exact ring boundary, larger boss hit flash.  
UI/HUD needs: Sword Ring icon/rune, radial/bar cooldown with numeric seconds and ready glow.  
Audio cues: optional light sword swish, impact tap and deeper ring cast; avoid continuous layers.

## Acceptance Criteria

- [ ] Auto sword fires at the configured interval while a living target exists and selects the nearest target.
- [ ] One base projectile applies exactly 22 damage once and cleans itself on hit/expiry.
- [ ] One ready Space/`qi_pulse` press applies 48 damage once to every enemy within the displayed 190 px radius.
- [ ] Space during cooldown does not change the 5.5 s cooldown or produce damage.
- [ ] All combat/cooldown progression freezes in PAUSED, LEVEL_UP and terminal states.
- [ ] Each listed upgrade changes its documented value immediately; caps/floors are respected.
- [ ] Enemy death is emitted exactly once under simultaneous hits.

## Godot Notes

Likely scene/resource structure: player child attack controller, lightweight projectile `Area2D`, enemy group/registry, one procedural VFX helper.  
Web export risks: unbounded nodes/particles and frame-dependent timers; cap/pool and use gameplay delta.  
Official docs to verify during implementation: Area2D overlap behavior and physics-query timing for Godot 4.4. Native Godot smoke passes; full-session and browser verification remain pending.
