# System GDD: Cultivation Progression

Status: Implemented and native-smoke verified; manual feel verification pending  
ID: SYS-03  
Source concept: `design/gdd/game-concept.md`

## Overview

Enemies release collectible linh khí. Filling the XP bar increments cultivation level, freezes combat and presents exactly three distinct đạo duyên. Realm names turn repeated levels into the four-minute arc Phàm Nhân → Luyện Khí → Trúc Cơ → Kim Đan → Nguyên Anh.

## Player Fantasy

Mỗi viên linh khí kéo về là một bước tu luyện; mỗi lần đột phá là một quyết định thật, và đổi cảnh giới phải khiến người chơi cảm thấy mình vừa vượt một tầng trời.

## Detailed Rules

### XP Orbs

- Current collectible profile values are Wisp 5 XP, Beast 8 XP, Demon 12 XP and Elite 42 XP. Boss retains a data value but its death ends the run immediately and does not create an orb.
- Orbs remain at the death position, bob visibly, and begin magnet movement when the living player is within 180 px (or after the long-idle fallback).
- Within 42 px, collect once, add XP and remove the orb. Multiple callbacks cannot double-award.
- Orbs and magnet motion freeze outside `PLAYING` and are cleared on restart/end cleanup.

### Levels And Realms

- Start at level 1, 0 XP, **Phàm Nhân**.
- XP required for the next level is `floor(18 × 1.28^(current_level - 1))`.
- XP can overflow. After accepting one upgrade, if overflow already meets the next threshold, queue another breakthrough; never show nested or two simultaneous overlays.
- Realm mapping: level 1 `Phàm Nhân`, level 3 `Luyện Khí`, level 6 `Trúc Cơ`, level 10 `Kim Đan`, level 14 `Nguyên Anh`; the highest reached threshold remains active.
- A realm transition plays a stronger gold seal/ink-ring cue and grants the current implementation's realm bonus: damage ×1.10, move speed ×1.035, +12 maximum HP with healing.

### Three-Card Breakthrough

- On a level-up threshold, session enters `BREAKTHROUGH`; timers, damage, motion, spawns, orbs and cooldowns freeze.
- Build a candidate pool from upgrades below cap. Offer exactly three distinct IDs. With ten baseline upgrades, this remains possible in the expected run.
- Card shows Vietnamese name and one-line concrete effect. No rarity, reroll or skip in MVP.
- Choice uses the three visible mouse-clickable/focusable cards; accept only the first valid request. Apply one stack, update displays and resume play. The current project additionally supports explicit UI-only `upgrade_1/2/3` shortcuts (`1/2/3`); they are not required for the core gameplay contract.
- Use a session seed for shuffle/random selection so a test run can reproduce offers; do not use frame time as repeated randomness.

## Formulas And Tuning

| Value | Formula / Range | Source | Notes |
|---|---|---|---|
| XP to next | `floor(18 × 1.28^(level - 1))` | `game_balance.json` | compute after each level increment |
| collectible enemy drops | 5 / 8 / 12 / 42 XP | enemy profiles | Wisp / Beast / Demon / Elite; boss victory has no orb |
| magnet radius | 180 px | `game_balance.json` | upgradeable |
| pickup radius | 42 px | `game_balance.json` | collect once |
| magnet acceleration/speed | 720 / 780 px/s | orb script | long-idle fallback after 12 s |
| Phàm Nhân | level 1 | realm table | starting milestone |
| Luyện Khí | level 3 | realm table | first realm breakthrough |
| Trúc Cơ | level 6 | realm table | second realm breakthrough |
| Kim Đan | level 10 | realm table | third realm breakthrough |
| Nguyên Anh | level 14 | realm table | final MVP milestone |
| card count | exactly 3 distinct valid IDs | progression config | no duplicates in one offer |

## Upgrade Pool

| ID | Card | Player-facing text | Owner |
|---|---|---|---|
| `sword_damage` | Vạn Kiếm Quy Tông | `Phi kiếm gây thêm 32% sát thương.` | combat |
| `attack_speed` | Kiếm Tâm Thông Minh | `Tốc độ xuất kiếm tăng 18%.` | combat |
| `extra_sword` | Phân Quang Kiếm Ảnh | `Mỗi lần ngự kiếm phóng thêm một phi kiếm.` | combat |
| `piercing_sword` | Phá Vọng Kiếm Ý | `Phi kiếm xuyên thêm một mục tiêu.` | combat |
| `cloud_step` | Lăng Vân Bộ | `Tốc độ di chuyển tăng 12%; hút linh khí tăng nhẹ.` | player |
| `jade_body` | Thanh Ngọc Đạo Thể | `Tăng 25 sinh mệnh tối đa và hồi ngay 25.` | player |
| `spirit_well` | Tụ Linh Quyết | `Phạm vi hút tăng 34% và nhận thêm 12% linh khí.` | progression |
| `qi_pulse` | Thái Hư Chấn Khí | `Chấn khí rộng hơn 15% và mạnh hơn 28%.` | combat |
| `life_stream` | Trường Sinh Khí | `Hồi sinh mệnh mỗi giây tăng thêm 0,65.` | player |
| `phoenix_blade` | Phượng Hoàng Kiếm Hỏa | `Định kỳ luyện hóa phi kiếm thành kiếm hỏa.` | combat |

Candidate rolls draw three distinct below-cap entries from the ten-card catalog. If a synthetic stress run exhausts the pool, an emergency heal may prevent a deadlock, but normal four-minute play must still show three cards at every breakthrough.

## Edge Cases

- One orb crosses two thresholds: show one choice, apply it, then show the next queued choice before resuming gameplay.
- Player dies on the same tick an orb is collected: session priority decides; no breakthrough may reopen after a terminal result.
- Double click / key echo: first valid selection locks the overlay; subsequent events are ignored.
- Card at cap selected from stale UI: validate again, ignore invalid selection and keep overlay open with an error cue.
- Restart during choice: discard candidate list, seed, overflow XP and upgrade stacks.
- Nguyên Anh reached: later levels remain Nguyên Anh; do not invent another realm in MVP.

## Dependencies

Upstream: enemy death/drop data, player position/alive, session process state, seeded RNG, tuning.  
Downstream: combat/player modifiers, HUD XP/level/realm, session BREAKTHROUGH state, VFX.  
Signals/events: `Events.experience_changed(current, required, level)`, `Events.upgrade_options_presented(options)`, `Events.upgrade_selected(id)`, `Events.realm_changed(name, subtitle)`.

## Visual And Audio Requirements

Assets needed: none; procedural gold orb/seal and runtime card frames.  
Feedback moments: orb magnet trail, XP bar pulse, screen-safe breakthrough ink bloom, stronger realm seal at levels 4/7.  
UI/HUD needs: XP bar, `Cấp tu vi N`, current realm, modal title `Đạo Tâm Khai Ngộ`, three clickable cards.  
Audio cues: optional orb chime, card accept brush stroke and realm gong; respect Web first-gesture/audio restrictions.

## Acceptance Criteria

- [ ] Non-boss enemy deaths award their documented profile XP once through one collectible orb; boss death goes directly to victory.
- [ ] XP thresholds follow the documented formula and overflow is preserved.
- [ ] Every level-up presents exactly three distinct valid cards and freezes gameplay.
- [ ] Mouse selection accepts exactly one of the three cards in the Web build; no click passes through to gameplay.
- [ ] One selection applies the correct immediate effect and resumes or queues the next breakthrough.
- [ ] Realm display changes at levels 1/3/6/10/14 to the five canonical milestones and applies each realm bonus once.
- [ ] Restart returns to level 1, 0 XP, Phàm Nhân and no upgrade stacks.

## Godot Notes

Likely scene/resource structure: orb `Area2D`, progression Node/resource table, `CanvasLayer` breakthrough Control with three Buttons.  
Web export risks: mouse/canvas focus, UI key echo and accidental gameplay Space event; context gate inputs.  
Official docs to verify during implementation: Control focus/Buttons and pause `process_mode` in Godot 4.4. Native smoke covers card count/freeze/resume; browser focus remains pending.
