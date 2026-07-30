# System GDD: Enemy Director

Status: Implemented and native long-run verified; manual balance verification pending  
ID: SYS-04  
Source concept: `design/gdd/game-concept.md`

## Overview

The director continuously tightens spawn cadence, adds scripted pressure beats at 1:15 and 1:55, keeps active entities within a browser-friendly cap and spawns one Thiên Ma boss exactly at 2:30.

## Player Fantasy

Vân Mộng dần bị mực tà xâm chiếm: ban đầu người chơi có khoảng thở để học kiếm pháp, sau đó phải chủ động mở đường, và phút cuối trở thành trận quyết chiến với đại linh thú.

## Detailed Rules

### Spawn Contract

- Advance spawn accumulator only in `RUNNING`. A state pause/level-up does not catch up a burst on resume.
- Sample one of four arena edges at the configured margin + 12 px, with the other coordinate randomized inside the edge bounds.
- Scripted 1:15 ambush spawns nine Beasts around the player at alternating 360/415 px radii and clamps them to a 72 px arena inset.
- Ordinary and scripted spawns respect the configured maximum of 125 living enemies; if reached, skip without banking spawn debt.
- Use session-seeded RNG so phase mixes are reproducible for QA.

### Ordinary Linh Thú

- **U Linh** (`WISP`): small baseline pursuer.
- **Mặc Thú** (`BEAST`): faster, tougher pursuer introduced as progress rises.
- **Tà Ma** (`DEMON`): slow, heavy pursuer introduced late.
- **Tinh Anh** (`ELITE`): one scripted elite at 1:55.
- Enemies use simple normalized pursuit plus restrained lateral sway. No pathfinding, projectiles or obstacle navigation are required for ordinary enemies.
- Enemy-to-enemy collision may be disabled; apply a small deterministic separation force only if clumping makes silhouettes unreadable.

### Boss

- At the first `RUNNING` tick with elapsed time ≥ 150 s, spawn **Thiên Ma** once at arena top-center, regardless of the random spawn cadence.
- Boss uses pursuit plus a telegraphed 230 px radial slam; telegraph lasts 0.92 s and cast cadence resets to 4.6 s.
- Show the announcement `THIÊN MA GIÁNG THẾ` without freezing the clock.
- Boss defeat reports `is_boss = true` and triggers victory through session flow.
- Surviving to 240 s wins; defeating the boss is also a victory route per the game contract.

## Formulas And Tuning

### Enemy Profiles

| Profile | HP | Speed | Contact damage | XP | Footprint |
|---|---:|---:|---:|---:|---:|
| U Linh / Wisp | `38 × difficulty` | `86 × 1.08` | scaled base | 5 | 15 px radius |
| Mặc Thú / Beast | `38 × 1.8 × difficulty` | `86 × 1.32` | scaled base ×1.12 | 8 | 20 px radius |
| Tà Ma / Demon | `38 × 2.65 × difficulty` | `86 × 0.78` | scaled base ×1.55 | 12 | 25 px radius |
| Tinh Anh / Elite | `38 × 10 × difficulty` | `86 × 0.82` | scaled base ×1.85 | 42 | 34 px radius |
| Thiên Ma / Boss | `38 × 44 × difficulty` | `86 × 0.72` | scaled base ×2.2 | 180 data value; no orb on terminal victory | 52 px radius |

### Spawn Curve

- Interval is `lerp(1.05, 0.34, pow(elapsed / 240, 0.72))` seconds.
- One enemy spawns per tick. After 35% progress, a second has 34% chance; after 72%, a third has 26% chance.
- Kind roll: Wisp by default; after 20% progress Beast occupies the configured mid roll; after 62% progress Demon has a 22% top-priority roll.
- HP difficulty is `1 + minutes × 0.42`; contact damage base scales by `1 + minutes × 0.18` before profile multipliers.
- Scripted beats: 1:15 nine-Beast ambush, 1:55 one Elite, 2:30 one Boss.

## Edge Cases

- Cap reached: skip ordinary spawn and reset/clamp accumulator; never unleash deferred burst.
- Boss timestamp occurs while LEVEL_UP/PAUSED: spawn on first resumed `RUNNING` tick, exactly once.
- Scripted event and boss flags set once, so resume/restart cannot duplicate the same event.
- Player dies before boss timestamp: terminal state prevents boss spawn.
- Restart at/after 2:30: elapsed and all event/boss flags reset; no stale entities survive.
- Enemy killed twice by simultaneous hits: only one XP/death event.

## Dependencies

Upstream: session elapsed/state/seed, player position, arena bounds, tuning.  
Downstream: combat target registry, player contact damage, progression drops, boss victory, HUD boss bar.  
Signals/events: local enemy `died(enemy, position, xp_value, was_boss)`, `player_contact(damage)`, `boss_slam(origin, radius, damage)`; timed beats use `Events.banner_requested`.

## Visual And Audio Requirements

Assets needed: none; procedural ink bodies following art bible silhouettes.  
Feedback moments: spawn ink bloom at edge, red eye/threat cue, hurt flash, death splatter, boss shadow/announcement.  
UI/HUD needs: ordinary enemies need no bars; boss has name + HP bar.  
Audio cues: optional soft ink pop, enemy hit/death and one boss gong.

## Acceptance Criteria

- [ ] Spawns follow the continuous interval/multi-spawn formula within seeded tolerance and stop outside RUNNING.
- [ ] Random ordinary enemies appear on a valid configured arena edge; scripted ambush positions stay in bounds.
- [ ] The 125-living cap is respected and no paused spawn debt creates a burst.
- [ ] Wisp/Beast/Demon/Elite match their profile/scaling values and pursue without frame-rate dependence.
- [ ] Scripted beats fire once at 1:15, 1:55 and 2:30; boss slam radius/telegraph are readable.
- [ ] Boss defeat emits one boss result; timeout can still win with boss alive.
- [ ] Restart clears all enemies and resets boss/spawn state.

## Godot Notes

Likely scene/resource structure: director Node with accumulator/seeded RNG, reusable enemy scene with profile enum/Resource, boss presentation variant.  
Web export risks: node churn, overdraw and too many collision pairs; cap entities, disable enemy-enemy physics and prefer pooling only if profiling justifies it.  
Official docs to verify during implementation: `RandomNumberGenerator`, collision layers and profiling for Godot 4.4. Native smoke covers enemy creation/death; full pressure profiling remains pending.
