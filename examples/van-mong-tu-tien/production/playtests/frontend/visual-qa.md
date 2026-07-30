# Front-end visual QA — 2026-07-29

Scope: native Godot 4.4 Compatibility captures at 1600x900, plus combat gallery at 1280x720.

## Evidence reviewed

- `title.png`
- `hub.png`
- `stages.png`
- `loadout.png`
- `techniques.png`
- `codex.png`
- `achievements.png`
- `settings.png`
- `reset.png`
- `results.png`
- `../overhaul/gameplay-final.png`
- `../overhaul/upgrade-final.png`
- `../overhaul/pause-final.png`
- `../overhaul/victory-final.png`
- `../overhaul/defeat-final.png`

## Acceptance checks

- PASS — every primary screen has authored environment/key art rather than a flat web-style backdrop.
- PASS — panels, cards, tabs and buttons are raster-backed; no stock Godot focus rectangle or default application chrome is visible.
- PASS — blank-center UIKIT-003 buttons keep Vietnamese captions clear at runtime sizes.
- PASS — critical copy is 14 px or larger in the new front end; text does not bleed into neighboring cards.
- PASS — all interactive targets measured by the flow harness are at least 48x48.
- PASS — keyboard/controller focus remains visible through texture/label treatment.
- PASS — critical status uses text/numeric labels in addition to color.
- PASS — controls and critical copy remain inside the 90% title-safe region; decorative art may extend to the viewport edge.
- PASS — hub and combat keep the central playfield/courtyard readable.
- PASS — locked stages/bestiary entries remain visually identifiable without pretending to be unlocked.
- PASS — reset profile is protected by a second authored confirmation surface.

## Findings by severity

- Blocker: none found.
- High: none found.
- Medium: none found in native captures.
- Low: the deliberately ornate header/frame silhouettes occupy more space than a minimalist UI; retain this only while 16:9 remains the supported presentation aspect.

## Release caveat

This is native screenshot acceptance, not a commercial-release declaration. Browser rendering/input/audio still requires Godot 4.4 Web export templates, and game feel still needs a human four-minute playthrough.
