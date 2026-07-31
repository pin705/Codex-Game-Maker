# System GDD: Expanded Economy & Meta Progression

Status: Persistent skill-fragment slice implemented; item/Huyền Thiết/beast-essence layers remain planned
ID: SYS-09

Economy layers are separate:

1. In-run: XP, skill ranks, temporary passives and one reroll token. Reset at run end.
2. Run rewards: pending item drops, Huyền Thiết fragments, manual fragments and beast essence. Confirmed at results.
3. Persistent: Linh Ngọc, equipment inventory, technique unlocks/ranks, spirit-beast growth and loadouts.

Every currency records at least one source and sink. Linh Ngọc buys technique ranks/refunds; Huyền Thiết reforges or salvages equipment; manual fragments unlock doctrine nodes; beast essence evolves the equipped companion. No currency is introduced before its meaningful sink is implemented.

Implemented slice: save v3 stores per-technique skill fragments, seeded run results award fragments, permanent technique upgrades consume an increasing fragment cost, and technique/results UI exposes owned/cost/drop values. Linh Ngọc remains the general run reward; the unimplemented item and beast currencies are not emitted.
