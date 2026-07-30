# Game Review Report: Vân Mộng Tu Tiên Native MVP

Status: Complete  
Gate: PASS_WITH_WARNINGS  
Date: 2026-07-29  
Reviewer: Codex Game Maker

## Evidence

Read: concept, five system GDDs, art bible, manifest/provenance, architecture/ADR/control manifest, implementation story, tuning, scenes and scripts.  
Ran: Godot 4.4 import/parse, 300-frame boot, 23-assertion state/combat smoke, fast-forwarded 240-second director/clock smoke, native Movie Maker visual captures, JSON/dimension/path checks.  
Could not verify: Web export/browser input (templates absent), real-time four-minute manual tuning/performance playthrough.

## Gate Summary

Blockers:

- None for opening and running the native Godot MVP.

Warnings:

- Web build/served-browser focus is not verified.
- Full-session balance and peak boss pressure are not manually playtested.
- PowerShell story/asset/review gates cannot run without `pwsh`; equivalent evidence is recorded manually.

Ready for: native hands-on playtest and Web export after templates are installed.

## Six-Role Review

### Creative

Finding: cultivation fantasy, five realms and ink/jade/vermilion language remain coherent from title through combat.  
Risk: procedural arena is intentionally darker than the warm-paper key art.  
Recommendation: retain the functional palette; only brighten after a full playtest proves readability needs it.

### Game Design

Finding: the four-minute loop has automatic offense, one active escape tool, XP choices, timed escalation and two victory routes.  
Risk: XP/spawn/boss tuning is only smoke-tested, not felt over four real minutes.  
Recommendation: run three complete sessions before expanding content.

### Art

Finding: title, gameplay and three-card screenshots are readable at 1280x720; accepted key art is integrated with fallback.  
Risk: high enemy counts may reduce silhouette separation.  
Recommendation: use entity cap/spawn tuning before adding visual noise.

### Technical

Finding: Godot 4.4 parses and boots; all core state routes pass the harness; renderer/input/export decisions match official docs.  
Risk: browser focus and Web export templates remain external unknowns.  
Recommendation: install templates and run the existing `Web` preset in Chromium/Firefox.

### Production

Finding: scope stayed within one arena, one active skill, current enemy/upgrade catalog and one boss.  
Risk: adding meta progression now would obscure the untested core balance.  
Recommendation: complete manual/browser evidence before new features.

### QA

Finding: deterministic smoke covers start, enemy/orb, breakthrough, pause, timeout, boss, defeat and a fast-forwarded 240-second cap/event run (121 active enemies, below the 125 cap).  
Risk: physical controls, restart from every modal and four-minute performance need hands-on evidence.  
Recommendation: use `production/playtests/STORY-0001-evidence.md` as the next checklist.

## Smoke Checklist

- [x] Project opens/imports structurally with Godot 4.4.
- [x] Main scene exists, boots and loads the accepted key art.
- [x] Core input path is documented and explicit in InputMap/bootstrap.
- [x] Automated core state loop passes 21 assertions.
- [x] Restart/failure path is documented; defeat state is automated.
- [x] Native 1280x720 title/combat/upgrade visuals are captured.
- [ ] Full four-minute physical playthrough recorded.
- [ ] Web export served and browser controls verified.

## Action Plan

1. Install Godot 4.4 export templates and export using `export_presets.cfg`.
2. Run one full four-minute keyboard playthrough and record boss/death/restart routes.
3. Serve the Web output and verify focus plus every advertised key/card input.

## Source Links

- https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_web.html
- https://docs.godotengine.org/en/4.4/classes/class_characterbody2d.html
- https://docs.godotengine.org/en/4.4/classes/class_inputeventkey.html
- https://docs.godotengine.org/en/4.4/classes/class_audiostreamwav.html
