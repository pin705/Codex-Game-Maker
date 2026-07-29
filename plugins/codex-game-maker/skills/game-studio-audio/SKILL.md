---
name: game-studio-audio
description: "Plan, source or create, integrate, mix, and verify complete game audio for Godot projects. Use for music, ambience, UI sounds, combat and interaction SFX, audio buses, ducking, variation, spatial audio, volume settings, licensing/provenance, and audio QA; especially when a game is silent or relies on temporary sounds."
---

# Game Studio Audio

Treat audio as gameplay feedback and world identity, not a final decorative add-on.

## Required Context

Read the concept, art bible, systems GDDs, game-state matrix, UI spec, control manifest, and `design/audio/audio-manifest.json`. Create the manifest from `../../references/templates/audio-manifest.json` if absent.

## Audio Pass

1. Derive audio coverage requirements from this game's state graph, actions, feedback needs, frequency, narrative, accessibility plan, and intended silence. Do not copy a universal event-ID list.
2. Define an audio identity consistent with the fantasy and visual material language.
3. Source, generate, record, or synthesize assets with provenance and commercial-use notes.
4. Declare `required_buses` and create only the buses this game's mix and settings architecture need.
5. Integrate events at authoritative gameplay/UI state transitions, not through polling or duplicated calls.
6. Add variation for frequent sounds through small pitch/volume/sample pools while preserving readability.
7. Implement persisted volume controls and mute behavior.
8. Test overlap, interruption/resume behavior, transition cleanup, persistence, and the busiest declared mix state.
9. Record game-specific coverage IDs, event IDs, integrated assets, provenance, triggers, and evidence in the manifest.
10. Set `coverage_policy.minimum_distinct_assets` from the actual event inventory and variation strategy; one placeholder tone cannot satisfy a larger declared floor.
11. Complete `production/reviews/audio-listening.md` from `../../references/templates/audio-listening-review.md` on target output devices, recording reviewer, build/commit, current audio evidence, and its SHA-256. For intentional silence, use a current session video or captured audio track that proves the silent runtime behavior; do not add a fake sound asset merely to satisfy the review.

## Player-Ready Coverage

Every required coverage row needs a rationale and one or more verified events. Derive needs such as navigation feedback, action confirmation, world ambience, music state, speech, warnings, outcomes, accessibility alternatives, and intentional silence from the actual game. The gate verifies the declared contract; the skill must make the contract exhaustive before production.

Temporary beeps, invalid media signatures, missing files, unlicensed sources, and events marked `planned`, `mock`, or `placeholder` block player-ready. A deliberately silent design is allowed only when `intentional_silence` is true with a concrete rationale and playtest evidence.

## Quality Rules

- Keep the mix intelligible before making it loud.
- Protect critical cues from masking by ambience or music.
- Avoid restarting looping music on ordinary state changes.
- Stop or hand off long-lived audio cleanly on restart and scene transitions.
- Do not claim audio complete without listening evidence on the target output path.
