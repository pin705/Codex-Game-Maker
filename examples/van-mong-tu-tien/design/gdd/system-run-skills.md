# System GDD: Run Skills & Evolution

Status: Core cap/unlock/evolution filtering implemented; five fully independent active casts remain an expansion gate
ID: SYS-06

## Player promise

A four-minute run grows from a two-technique foundation into a deliberate five-skill formation. Each skill has its own targeting, cadence, shape and rank milestones; max-rank skills leave the offer pool.

## Rules

- Run level is clamped to 1–20. XP at level 20 may still fill the meter for score but cannot queue another breakthrough.
- At most five active skills are equipped. A new-skill choice occupies the first empty slot; an upgrade choice increments one equipped skill up to rank 5.
- Each offer contains three distinct valid rows selected from unlock, upgrade and passive pools. Max-rank skills and locked prerequisites are excluded before selection.
- One reroll token per run is the initial economy baseline; skip converts the offer into a small heal only when no reroll remains. Both are disabled until their UI/runtime path is implemented.
- Slot inputs are `skill_1` through `skill_5`; the existing `qi_pulse` action mirrors its assigned slot for backward compatibility.
- Active skill cooldowns and cast stages advance only in RUNNING. Breakthrough, pause and result states freeze them.
- The current implementation begins with two learned techniques, gates new catalog entries by level, excludes a sixth learned technique and removes max-rank rows before rolling three distinct offers.
- Sword ranks 3/5 widen the projectile formation and add a distinct seal/VFX layer; remaining production skills still require their full table-specific rank 3/5 behavior implementations.
- Every current runtime catalog skill now routes through distinct cast, travel
  and impact VFX phases. This completes presentation feedback for sword,
  phoenix, qi, movement, vitality, gathering and companion assists; it does not
  replace the remaining gameplay gate for five independently targeted active
  casts and their rank-3/rank-5 mechanics.

## Initial production skills

| ID | Role / target | Rank 1 | Rank 2 | Rank 3 behavior | Rank 4 synergy | Rank 5 evolution |
|---|---|---|---|---|---|---|
| `phi_kiem` | nearest-target projectile | one flying sword | faster recovery | fork after first hit | gains doctrine/equipment tag bonus | Kiếm Vực volley and tier-3 trail/impact |
| `kiem_tran` | manual radial control | current Chấn Khí | shorter recovery | leaves a short ward field | jade/spirit-beast bond extends control | double-ring collapse with tier-3 audio/VFX |
| `linh_phu` | periodic orbit/strike | one orbiting talisman | second orbit | talismans detonate on expiry | fire/qi tags increase detonation | rotating four-seal formation |
| `bang_lien` | ground zone / slow | one frost-lotus field | larger zone | enemies shatter on death | water/jade tags extend slow | expanding lotus chain with tier-3 decal |
| `thien_loi` | chain priority damage | three-target chain | shorter interval | jumps to elite/boss first | lightning/crit tags add overload | heavenly pillar plus secondary arcs |

## Presentation and readability

- Five HUD slots show icon, rank, cooldown radial/seconds, input binding and unavailable state.
- Enemy danger boundaries remain above decorative trails and below the player only when the danger is already resolved.
- Rank 3/5 transitions trigger a short ritual notice and update the skill silhouette immediately.

## Acceptance

- Offers never contain duplicates, a maxed skill or a sixth active skill.
- Level 20 queues no breakthrough.
- Rank 3 and 5 behavior changes are asserted and captured for every production skill.
- Pause/restart clears cast stages, projectiles, zones and cooldowns deterministically.
