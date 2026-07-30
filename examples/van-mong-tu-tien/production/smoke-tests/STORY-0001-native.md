# Smoke Test: STORY-0001 Native Godot 4.4

Date: 2026-07-29  
Tester: Codex Game Maker  
Engine: Godot 4.4.stable.official.4c311cbee  
Build: local showcase  
Gate: PASS

## Setup

Command: official portable Godot + `tests/smoke_runtime.tscn`  
Device/browser: macOS Apple M1, headless native engine  
Main scene: `scenes/main.tscn`

## Must Still Work

- [x] Project imports/parses and main scene starts.
- [x] Player can enter the run and a defeated enemy creates one XP orb.
- [x] One XP threshold opens exactly three cards and one choice resumes play.
- [x] Pause/resume freezes and restores the simulation.
- [x] Timeout victory, boss victory and defeat each reach the intended terminal state.
- [x] Fast-forwarded 240-second clock triggers both timed events, one boss and the enemy cap without losing timeout victory.
- [x] No obvious crash or blocking runtime error occurs in the smoke route.

## Result

Passed:

- 23/23 state smoke assertions plus long-run director/clock smoke (`enemies=121`, boss once, under the 125 cap).
- Godot process exit code `0`.
- Three native 1280x720 visual captures rendered successfully.

Failed:

- None in native smoke scope.

Notes: Web export/browser focus and a full four-minute manual run are tracked as separate verification work.
