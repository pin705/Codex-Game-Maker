# STORY-0002 — Five-skill run foundation

Status: Ready  
Player value: A run visibly grows from a basic kiếm tu kit into a five-skill cultivation build, with every level-up offer respecting unlock, equip and max-rank rules.

## Goal

Extract run skill definitions from `main.gd`, cap run level at 20, introduce a five-slot runtime loadout and expose each slot's identity/rank/cooldown in the HUD without breaking the existing combat journey.

## Acceptance criteria

- [ ] Skill definitions are loaded from project data, not a hard-coded UI or match tree.
- [ ] A run owns at most five equipped active skills and never offers a max-rank skill.
- [ ] Level cannot exceed 20; XP at cap does not open another breakthrough.
- [ ] Every breakthrough produces three distinct valid choices or a documented fallback/skip path.
- [ ] Existing Phi Kiếm and Chấn Khí behavior is preserved through the new system.
- [ ] HUD shows five authored slots with empty/locked, ready, cooldown and rank states.
- [ ] Keyboard/controller focus and mobile layout remain functional.
- [ ] Headless tests cover loadout capacity, rank cap, offer validity and level cap.
- [ ] Runtime capture shows the skill strip during the busiest combat state.

## Files in scope

- `resources/data/skill-definitions.json`
- `scripts/gameplay/run_skill_system.gd`
- `scripts/gameplay/main.gd`
- `scripts/core/events.gd`
- `scripts/ui/hud.gd`
- `tests/smoke_run_skill_system.gd`
- `tests/smoke_run_skill_system.tscn`
- contracts/evidence that bind this story

## Verification

- Godot import/lint.
- Focused `smoke_run_skill_system` command.
- Existing primary session, recovery, responsive and visual smoke commands.
- Native desktop/phone combat captures and served-Web smoke.

