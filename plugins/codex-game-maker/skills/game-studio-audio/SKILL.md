---
name: game-studio-audio
description: "Plan, source or create, integrate, mix, and verify complete game audio for Godot projects. Use for music, ambience, UI sounds, combat and interaction SFX, audio buses, ducking, variation, spatial audio, volume settings, licensing/provenance, and audio QA; especially when a game is silent or relies on temporary sounds."
---

# Game Studio Audio

Treat audio as gameplay feedback and world identity, not a final decorative add-on.

## Required Context

Read the concept, art bible, systems GDDs, game-state matrix, UI spec, control manifest, and `design/audio/audio-manifest.json`. Create the manifest from `../../references/templates/audio-manifest.json` if absent.

## Audio Pass

1. Inventory player actions, impacts, pickups, UI actions, transitions, danger, victory, defeat, ambience, and music states.
2. Define an audio identity consistent with the fantasy and visual material language.
3. Source, generate, record, or synthesize assets with provenance and commercial-use notes.
4. Create Godot buses for Master, Music, SFX, UI, Ambience, and Voice when applicable.
5. Integrate events at authoritative gameplay/UI state transitions, not through polling or duplicated calls.
6. Add variation for frequent sounds through small pitch/volume/sample pools while preserving readability.
7. Implement persisted volume controls and mute behavior.
8. Test overlap, pause behavior, restart cleanup, scene transitions, and the busiest gameplay state.
9. Record integrated asset paths, triggers, and evidence in the manifest. Required player-ready IDs include confirm/back/focus/invalid UI, player action, failure, reward, victory, defeat, main music, and gameplay ambience.
10. Use at least four distinct integrated audio files across UI, gameplay, music/ambience, and outcomes; do not point every event at one placeholder tone.
11. Complete `production/reviews/audio-listening.md` from `../../references/templates/audio-listening-review.md` on target output devices, recording reviewer, build/commit, current audio evidence, and its SHA-256.

## Minimum Player-Ready Coverage

- title/menu identity or documented intentional silence
- confirm, back, focus/selection, and invalid UI feedback
- primary player action and movement feedback where appropriate
- hit/damage/failure and reward/pickup feedback
- danger/escalation feedback
- victory and defeat transitions
- ambience or intentional environmental silence
- volume settings and bus routing

Temporary beeps, invalid media signatures, missing files, unlicensed sources, and events marked `planned`, `mock`, or `placeholder` block player-ready. A deliberately silent design is allowed only when `intentional_silence` is true with a concrete rationale and playtest evidence.

## Quality Rules

- Keep the mix intelligible before making it loud.
- Protect critical cues from masking by ambience or music.
- Avoid restarting looping music on ordinary state changes.
- Stop or hand off long-lived audio cleanly on restart and scene transitions.
- Do not claim audio complete without listening evidence on the target output path.
