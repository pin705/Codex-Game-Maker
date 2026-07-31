# System GDD: Spirit Beast Companion

Status: Core runtime assist implemented; bond/evolution economy remains planned
ID: SYS-08

One spirit beast may be equipped. The first production companion, `Thanh Vân Hồ`, has a directed assist that marks the highest-threat target, a passive bond that rewards movement between casts, a visible cooldown/energy ring and three evolution milestones. It follows a soft offset from the player, teleports only after an off-screen recovery threshold, ignores collision and never occupies enemy telegraph priority.

The companion must support summon, dismiss, defeat/recovery, pause, result and scene-reload cleanup. Targeting rejects dead/off-screen/irrelevant targets. Its damage and utility scale through skill/equipment tags rather than a flat always-on damage multiplier.

Current runtime: Thanh Vân Hồ follows a soft offset, ignores collision, prioritizes boss/elite threats, casts a six-second jade assist, reports cooldown to the fifth HUD slot and cleans up on terminal state. Bond spend, defeat/recovery and the three milestone evolution economy remain open.
