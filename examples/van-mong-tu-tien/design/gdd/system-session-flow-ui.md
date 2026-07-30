# System GDD: Session Flow & UI

Status: Implemented across the declared state graph; Web/manual verification pending  
ID: SYS-05  
Source concept: `design/gdd/game-concept.md`

## Overview

This system owns the authoritative session state, 4-minute clock, pause/modal gates, result priority, clean restart and all player-facing Vietnamese HUD/overlay surfaces.

## Player Fantasy

Một lần nhập Vân Mộng là một hành trình trọn vẹn: biết mình đang ở cảnh giới nào, còn bao lâu tới thiên kiếp, khi nào Kiếm Trận sẵn sàng và vì sao mình thắng hoặc thua.

## Detailed Rules

### States

- `START`: optional splash or procedural fallback, title, concise controls and `Nhấn ENTER hoặc bấm nút`.
- `RUNNING`: only state that advances elapsed time, attacks, cooldowns, spawns, motion, damage and pickups.
- `LEVEL_UP`: freezes gameplay, shows three cards, keeps overlay/UI processing active.
- `PAUSED`: freezes gameplay, shows `Tạm Dừng`; `P` resumes.
- `VICTORY`: freezes gameplay, shows `Phi Thăng` plus reason and elapsed time.
- `DEFEAT`: freezes gameplay, shows `Đạo Tiêu Thân Tử` plus elapsed time.

### Transition Rules

- `START` + fresh `confirm` (Enter/button) → reset data and `RUNNING`; do not also cast Chấn Khí.
- `RUNNING` + valid level threshold → `LEVEL_UP`; one valid choice → `RUNNING` or next queued breakthrough.
- `RUNNING` + P → `PAUSED`; `PAUSED` + fresh P → `RUNNING`.
- `restart_game` in any non-text-entry context → immediate clean reload into `RUNNING` after one-frame cleanup if needed.
- Result checks are idempotent and resolved once per physics tick in priority: boss defeated → victory; player HP ≤ 0 → defeat; elapsed ≥ 240 s → victory.
- Reaching 240 s while paused/choosing cannot happen because elapsed does not advance.

### Clock And HUD

- Elapsed starts at 0.0 and advances by gameplay delta only in `RUNNING`, clamped at 240.0.
- Display remaining time as `MM:SS`, using ceiling so the HUD does not show `00:00` early.
- Persistent RUNNING HUD: HP, XP/level, realm, time, Chấn Khí cooldown, compact control hint. Boss bar appears only while boss alive.
- Modal overlays capture input and visually dim the arena, but gameplay state remains owned by session/progression.
- All player-facing copy is Vietnamese and must use font fallback with Vietnamese glyph coverage.

### Restart Contract

A restart clears enemies, projectiles, orbs, particles, modal choices and result flags; resets player/XP/realm/upgrades/cooldowns/spawn RNG/clock/event/boss flags; then recreates or reinitializes the run. Re-instantiating the gameplay scene is preferred over manually remembering every mutable field.

## Formulas And Tuning

| Value | Formula / Range | Source | Notes |
|---|---|---|---|
| session duration | 240.0 s | `resources/tuning/game_balance.json` | timeout victory |
| boss timestamp | 150.0 s | `resources/tuning/game_balance.json` | director owns spawn |
| displayed time | `ceil(240 - elapsed)` → `MM:SS` | HUD | clamp 00:00–04:00 |
| pause dim | 55–70% ink overlay | UI theme | preserve arena context |
| result priority | boss win > death > timeout win | session contract | evaluate once per physics tick |

## Player-Facing Copy

| Surface | Required text |
|---|---|
| Title | `Vân Mộng Tu Tiên` |
| Start | `Nhấn ENTER hoặc bấm nút` |
| Controls | `WASD / ←↑↓→ Di chuyển · Space Chấn Khí · P Tạm dừng · R Chơi lại` |
| Level modal | `Đạo Tâm Khai Ngộ` and `Chọn một công pháp` |
| Pause | `Tạm Dừng` and `Nhấn P để tiếp tục` |
| Victory | `Phi Thăng Thành Công` |
| Boss victory reason | `Thiên Ma đã bị trấn áp.` |
| Timeout reason | `Bạn đã vượt qua bốn phút ma kiếp.` |
| Defeat | `Đạo Tiêu Thân Tử` |
| Restart | `Nhấn R để tu luyện lại` |
| Boss | `Thiên Ma` / `THIÊN MA GIÁNG THẾ` |

## Edge Cases

- P held down: one just-pressed event changes state once; key echo cannot toggle repeatedly.
- R during a card click/result transition: restart wins after current input callback, and stale callbacks cannot alter the new run.
- Boss death, player death and timeout in one tick: documented priority produces exactly one result.
- Missing key art: title uses procedural paper/mountain background; start remains fully usable.
- Browser loses focus: movement stops; optionally auto-pause only after browser verification, not as a silent MVP assumption.
- UI focus consumes arrows/Space: in LEVEL_UP this is allowed; when returning to RUNNING clear focus/pressed state so no ghost movement/cast.
- Audio cannot autoplay: first user gesture may unlock cues, but no state depends on audio.

## Dependencies

Upstream: player health/death, progression/choice, director/boss, combat cooldown, Input Map.  
Downstream: process gates for every gameplay system, CanvasLayer visibility, restart lifecycle.  
Signals/events: `Events.start_requested`, `restart_requested`, `game_started`, `game_paused(is_paused)`, `run_stats_changed(elapsed, duration, kills)`, `game_finished(victory, title, details)`.

## Visual And Audio Requirements

Assets needed: optional accepted `KEYART-001`; procedural fallback mandatory.  
Feedback moments: title fade, timer emphasis after 2:30, modal ink bloom, boss banner, distinct gold victory/red defeat seals.  
UI/HUD needs: all surfaces above; layout safe in a 1600x900 logical canvas shown at 1280x720 with no overlap at three-card modal.  
Audio cues: optional UI brush taps/boss/result cues via short WAV; muted experience remains complete.

## Acceptance Criteria

- [ ] START starts one fresh run with `confirm`/Enter/button without accidentally casting Chấn Khí.
- [ ] Only RUNNING advances the clock and all gameplay processes.
- [ ] P pauses/resumes once per press; `restart_game` restarts cleanly from every state.
- [ ] LEVEL_UP freezes combat and accepts only one of three cards before resume.
- [ ] Boss defeat, player death and timeout produce exactly one result under documented priority.
- [ ] Timeout victory occurs at 4:00 and boss defeat can win earlier after 2:30.
- [ ] All HUD/modal text is readable Vietnamese at 1600x900 logical / 1280x720 window; no overlap or clipped card content.
- [ ] Missing/unaccepted key art does not prevent start, restart or full playthrough.

## Godot Notes

Likely scene/resource structure: composition-root session Node, CanvasLayer HUD/title/modal/result Controls, gameplay subtree recreated on restart. Set paused UI/process modes deliberately rather than scattering checks.  
Web export risks: canvas focus, mouse/keyboard modal routing, audio gesture, browser resize.  
Official docs verified for Web constraints and keyboard events: https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_web.html and https://docs.godotengine.org/en/4.4/classes/class_inputeventkey.html. Export/runtime verification remains pending.
