# Audio Listening Review: Vân Mộng Tu Tiên / Local Candidate

Status: BLOCKED
Build or commit: local ignored showcase output; final project fingerprint pending quality run
Reviewer: Pending human listener
Output devices: Not yet tested; required minimum is built-in speakers plus headphones on desktop and one physical mobile device

## Scenarios Reviewed

Automated coverage exists for the following scenarios, but none has received the required human listening pass:

- Title and hub calm score transition, including repeated navigation.
- Combat score start after the first user gesture and uninterrupted 32-second loop behavior.
- UI press, sword fire, qi pickup, player hurt, Chấn Khí, breakthrough, boss arrival and ordinary enemy defeat procedural cues.
- Victory and defeat result-bed transition with opposite melodic result phrases.
- Music/SFX volume controls, pause/resume, retry, return-to-hub and scene cleanup.
- Busiest mix: boss telegraph plus auto swords, Chấn Khí, enemy defeats, pickups and combat score.

## Findings

| Severity | Scenario | Finding | Evidence | Resolution |
|---|---|---|---|---|
| Blocker | All scenarios | No human listening session has checked the current build on any target output. | `tests/smoke_audio.gd` proves PCM/loop/bus structure only. | Perform and record a human listening pass. |
| High | Web first gesture | Audio unlock, resume and cleanup have not been tested in a served browser. | No Web build exists because export templates are absent. | Export/serve, then verify blocked-autoplay and first-gesture recovery. |
| High | Physical mobile | Speaker loudness, masking and thermals under a full run are unverified. | No physical-device recording or notes. | Test at least one iOS and one Android device. |
| Pending | Score identity | Title and hub WAV files are byte-identical by design; a listener must confirm that reuse feels intentional rather than monotonous. | `assets/generated/audio/music_title.wav`, `assets/generated/audio/music_hub.wav` | Confirm or revise after listening, not from waveform existence alone. |

## Evidence

Capture/recording: `assets/generated/audio/music_combat.wav`

Evidence SHA-256: 35c726113c5562943199babedcbefde0fbc3d9cc1fce985806ab425688d967fb

Bus/settings test: `tests/smoke_audio.tscn` verifies non-silent PCM, 32-second loop metadata and the Music/SFX buses; it does not assess perceived quality.

Target-output review: BLOCKED — no human target-output session recorded.

## Verdict

Gate: BLOCKED

Reason: Automated correctness cannot establish mix quality, loudness, masking, loop-seam perception or device behavior.
