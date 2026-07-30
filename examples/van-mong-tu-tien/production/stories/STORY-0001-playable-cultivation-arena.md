# Story: Playable Cultivation Arena

Status: Implemented; native automated verification complete; Web/manual verification pending  
ID: STORY-0001  
Source:

- Concept: `design/gdd/game-concept.md`
- Systems: `design/gdd/systems-index.md` and `design/gdd/system-*.md`
- Art: `design/art/art-bible.md`
- Architecture: `docs/architecture/architecture.md`
- ADR: `docs/architecture/adr-0001-engine-web.md`
- Controls: `docs/architecture/control-manifest.md`

## Player Value

Người chơi có thể hoàn thành một ván `Vân Mộng Tu Tiên` bốn phút trọn vẹn trên bàn phím: né linh thú, dùng phi kiếm và Chấn Khí, chọn đạo duyên, đi qua năm mốc cảnh giới rồi thắng, thua hoặc chơi lại ngay.

## Goal

Create the smallest complete Godot 4.4 playable slice at logical 1600x900 (1280x720 window override) with procedural ink-wash combat, one automatic sword attack, one active `qi_pulse`, XP/three-card breakthroughs, Phàm Nhân → Luyện Khí → Trúc Cơ → Kim Đan → Nguyên Anh, escalating enemies, a 2:30 boss, two victory routes, death, pause and clean restart.

## Non-Goals

- Save/meta progression, equipment, quests, dialogue, extra maps/characters.
- Touch/gamepad/remapping UI, localization framework or online services.
- More than the current Wisp/Beast/Demon/Elite profiles and one boss.
- More than one active skill or the current upgrade catalog.
- Sprite-sheet production, complex shaders, procedural music or required audio.
- Making key art a prerequisite for gameplay; procedural title fallback remains mandatory.
- Release packaging/deployment beyond a local Web smoke export.

## Files To Touch

Expected:

- `project.godot`
- `export_presets.cfg` when Web templates are available
- `scenes/main.tscn`
- `scripts/core/*.gd`
- `scripts/gameplay/*.gd`
- `scripts/ui/*.gd`
- `resources/tuning/game_balance.json`
- accepted title asset reference only through the manifest
- `production/playtests/STORY-0001-evidence.md`

Avoid:

- repository tooling outside `examples/van-mong-tu-tien/`
- changing GDD/ADR rules to match accidental implementation drift without design review
- unaccepted files or temp-generation paths
- unrelated dependencies/plugins

## Acceptance Criteria

### Boot And Presentation

- [x] Godot 4.4 opens/imports the project with Compatibility renderer and `scenes/main.tscn` at logical 1600x900 / 16:9 window presentation.
- [x] Start overlay shows `Vân Mộng Tu Tiên`, controls and starts via `confirm`/Enter or button; missing key art uses procedural fallback.
- [x] Native 1280x720 capture follows the art bible: ink base, jade player/reward language, vermilion threat, gold breakthrough.

### Core Play

- [ ] WASD and arrows provide equal-speed 8-direction movement within the 54 px logical arena margin (manual/browser check pending).
- [ ] Auto sword finds a living nearest target, damages once and cleans up; projectile/pierce upgrades work (full-session check pending).
- [x] Space (`qi_pulse`) casts a visible radial Chấn Khí; HUD exposes its 5.5 s cooldown in the native capture.
- [x] Player HP/contact immunity/death behave once and do not allow negative HP or repeated terminal events in the smoke harness.

### Progression

- [x] One ordinary enemy death drops one XP orb; boss death immediately ends in victory without an orb.
- [x] A threshold freezes gameplay and offers exactly three distinct valid Vietnamese cards.
- [x] Card signal selection applies one choice once and resumes play; full physical click pass remains pending.
- [ ] Realm display/bonuses at levels 1/3/6/10/14 need a full-session manual check.

### Session

- [ ] Spawn cadence and timed beats need a real-time four-minute run.
- [ ] `Thiên Ma` appears once at 150 s under peak pressure (manual timing pending).
- [x] Boss defeat wins early; timeout victory without a boss and HP 0 defeat both pass the native harness.
- [x] P pause/resume freezes and restores the simulation in the harness.
- [ ] R restart from every UI state needs physical input verification.
- [x] Boss victory, timeout victory and defeat each produce one terminal state in the harness.

### Web / Quality

- [ ] One uninterrupted native four-minute playthrough and death/restart path are recorded.
- [ ] Web export served over HTTP runs without console-fatal error.
- [ ] Browser verifies canvas focus and every advertised key/card input.
- [ ] Peak boss pressure stays responsive/readable within documented entity/particle caps.

## Verification Plan

Commands run successfully:

- portable Godot 4.4 `--headless --path . --editor --quit --verbose` → exit 0; no script parse errors.
- portable Godot 4.4 `--headless --path . tests/smoke_runtime.tscn` → 21/21 assertions, exit 0.
- portable Godot Movie Maker → native 1280x720 title/combat/upgrade captures.

Tooling still missing:

- `pwsh`/`powershell` are absent, so repository story/asset/review gates were not invoked.
- Godot 4.4 Web export templates are not installed, so Web export/browser checks remain pending.

Commands to run after Godot 4.4 + export templates are installed:

- `godot --headless --path . --editor --quit` — import/parse project (completed with portable binary).
- `godot --headless --path . --quit-after 5` — boot main scene smoke test if supported by installed binary.
- `godot --headless --path . --export-release Web build/web/index.html` — produce served Web output after preset creation.
- From repository root, run the available Godot lint/story-gate PowerShell tools with this project path once `pwsh` exists.

Manual:

- Start from the overlay; verify WASD/arrows, Space, P, R and Enter.
- Trigger at least two level-ups; choose cards by mouse and verify one click only.
- Pause during enemies/projectiles/orbs and confirm clock/cooldowns/damage freeze.
- Reach 2:30, inspect boss/telegraph/UI/performance, then verify boss-kill victory.
- Restart and verify timeout victory at exactly 4:00 with boss alive.
- Restart, die, and restart again from defeat.
- Repeat the control/state smoke test in a served Chromium build; Firefox second if available.

Evidence to save:

- `production/playtests/STORY-0001-evidence.md`
- 1280x720 presentation screenshots: start, combat, level-up, boss, pause, victory, defeat
- Web export log and browser console summary

## Risks

Design: tuning may reach Nguyên Anh too late or auto-attack may feel passive; adjust only authoritative config after full runs.  
Technical: current environment lacks Godot/PowerShell; code, input map and export cannot be validated here yet.  
Art: procedural ink layers may reduce contrast; accepted key art is optional for runtime.  
Production: extra enemy types, realm tiers or boss phases are explicit scope cuts.  
QA: modal/pause/result races and restart state leakage are higher risk than raw content count.

## Implementation Notes

Follow the dependency order in `systems-index.md`. Deliver a complete greybox loop before polishing particles/audio. Do not change the fixed 4:00 duration, 2:30 boss timestamp, logical 1600x900 viewport or five-realm scope without a brief/GDD decision.

## Evidence

Result: Native implementation verified; Web/manual verification pending.

Commands run:

- Godot 4.4 portable editor/scene parse → exit 0.
- `tests/smoke_runtime.tscn` → 21/21 PASS, exit 0.
- Movie Maker captures → title, gameplay and upgrade screenshots at 1280x720.
- Web export/templates → not run to completion; templates absent.

Manual playtest:

- Native deterministic smoke: PASS.
- Full four-minute physical/browser playtest: pending.

Media:

- `production/playtests/STORY-0001-evidence.md`
- `production/playtests/title-screen-runtime.png`
- `production/playtests/gameplay-runtime.png`
- `production/playtests/upgrade-runtime.png`

## Review

Gate: PASS_WITH_WARNINGS  
Reviewer notes: Native implementation and deterministic smoke are verified. Run the repository story gate when PowerShell is available, then complete the Web/manual checklist before calling the story fully done.
