# Playtest Evidence: STORY-0001 Native Smoke

Date: 2026-07-29  
Tester: Codex Game Maker  
Build or commit: local ignored showcase output  
Engine: Godot 4.4.stable.official.4c311cbee  
Main scene: `scenes/main.tscn`

## Setup

Command or editor path: portable official Godot at repository `.tools/godot/Godot.app/Contents/MacOS/Godot`  
Device/browser: macOS 26.5.1, Apple M1; native OpenGL 4.1 Metal Compatibility for movie captures; headless Dummy audio for smoke  
Input method: smoke harness invokes the same state/UI signals; full physical keyboard/browser input remains manual QA

## Scenario

Goal: prove the smallest complete loop and every terminal route without waiting four real minutes.  
Start state: fresh `START` scene with accepted key art loaded.  
Expected core loop: start → enemy death/orb → one threshold → three cards → select → resume → pause/resume → timeout/boss/death terminals.

## Results

Completed:

- Godot editor import/parse exited `0`; no GDScript parse/compile failures.
- Main scene booted headless for 300 frames and exited `0` without runtime errors.
- `tests/smoke_runtime.tscn` passed 23 assertions and exited `0` (auto sword and Chấn Khí damage included).
- `tests/smoke_long_run.tscn` fast-forwarded the four-minute clock and passed timed event/boss/cap/timeout checks (`enemies=121`, `boss_spawned=true`, under the 125 cap).
- Title/start, player enable, one enemy death, one orb and one XP threshold passed.
- Breakthrough froze the tree, showed exactly three `Button` cards and resumed from one selection.
- Pause/resume froze and restored the tree.
- Timeout victory passed without requiring a boss kill.
- Boss defeat produced immediate victory; lethal player damage produced defeat.
- Godot Movie Maker rendered native 1280x720 title, combat and breakthrough frames using the Compatibility renderer.

Failed:

- None in the automated native smoke scope.

Observed issues:

- Godot editor headless import logs internal progress-dialog warnings; scripts still load and command exits `0`.
- Headless Dummy renderer cannot capture a viewport texture; visual evidence was therefore rendered through Godot Movie Maker/OpenGL.
- Godot 4.6.2 Web export templates are installed; Web export and served Chromium smoke pass. Firefox/Safari, physical-device and manual four-minute checks remain pending.
- A full real-time four-minute manual playthrough and physical keyboard/browser focus pass remain outstanding.

## Commands

```text
Godot --headless --path . --editor --quit --verbose
  -> exit 0; scene/scripts/assets imported; no SCRIPT ERROR

Godot --headless --path . --quit-after 300 --verbose
  -> exit 0; main scene/key art loaded; no runtime error

Godot --headless --path . tests/smoke_runtime.tscn
  -> SMOKE RESULT: PASS; exit 0

Godot --headless --path . tests/smoke_long_run.tscn
  -> LONG RUN RESULT: PASS; enemies=121 boss_spawned=true; exit 0

Godot --path . --write-movie <evidence>.avi --fixed-fps 30 --quit-after 5|8
  -> native Compatibility render completed; ffmpeg extracted PNG evidence
```

## Media

Screenshots:

- `production/playtests/title-screen-runtime.png` — clean title state and key-art integration.
- `production/playtests/gameplay-runtime.png` — HUD, procedural player/enemies/orbs and Kiếm Trận VFX.
- `production/playtests/upgrade-runtime.png` — exactly three readable cards inside 1280x720.

Recording: short temporary AVI captures were used only to extract current PNG evidence.

## Verdict

Gate: **PASS_WITH_WARNINGS**  
Next verification: install Godot 4.4 export templates, export/serve `build/web/index.html`, then complete one full four-minute keyboard playthrough plus boss and death/restart routes in a browser.
