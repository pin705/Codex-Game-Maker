# Player-Ready Contract: Vân Mộng Tu Tiên

Status: Verified
Gate result: BLOCKED pending the unchecked human, physical-device, served-Web and final independent-review evidence below.
Target gate: PLAYER_READY
Release profile: desktop-and-mobile-landscape-candidate
Target devices: desktop Web browsers at 1600×900 logical presentation; landscape iOS/Android candidate with notch-safe touch controls; portrait is guarded rather than playable
Target session length: one four-minute combat run plus the persistent sect/meta loop

## Player Promise

Core fantasy: Enter Vân Mộng as a vulnerable kiếm tu, shape a doctrine through visible cultivation choices, survive an escalating four-minute tribulation, and return to the sect with persistent progress.

Complete player journey: Title → Hub → Stage Select → Loadout → Combat → Breakthrough/Pause → Victory or Defeat → Hub/Retry, alongside technique ascension, codex, achievements, settings, and protected profile reset.

Quality bar: A coherent ink, silk, lacquer, bronze, jade and cinnabar presentation with authored world, actor, UI and VFX assets; readable Vietnamese UI; responsive keyboard/controller/touch interaction; distinct audio states; deterministic recovery; and current runtime evidence. This is a player-ready candidate bar, not a store/commercial-release claim.

## Scope Boundary

Required systems:

- Persistent JSON profile, migration/recovery, currency, stage records, unlocks, techniques, bestiary, achievements and settings.
- Title, hub, stage selection, loadout, technique ascension, codex, achievements, settings, guarded profile reset and result surfaces.
- Four-minute arena survival with movement, auto sword, active Chấn Khí, enemy director, boss, XP pickups, three-card breakthroughs, pause, victory, defeat and retry/return recovery.
- Three stage identities, three disciplines, three permanent technique tracks and visible rank-aware cultivation VFX.
- Keyboard/mouse, controller navigation and landscape multi-touch with safe-area handling and portrait input blocking.
- Music/SFX buses, four state score files, procedural event cues and player-facing volume controls.

Required content:

- Vân Mộng Cốc, Huyết Vân Đài and Thiên Môn Tàn Cảnh.
- Player, Wisp, Mặc Lang, Tà Tu/Elite, Thiên Giác boss, qi orb, flying sword, impact/burst and cultivation-sigil visual families.
- Fifteen required states and three required journeys declared in `design/game-state-matrix.json`.

Explicitly excluded:

- Accounts, cloud save, leaderboards, multiplayer, matchmaking, live events and backend services; the bounded candidate is local and single-player.
- Store submission, signing, monetization, legal/compliance completion, marketing deliverables and broad localization; these belong to commercial-release work after PLAYER_READY.
- Player-facing key remapping and platform-specific prompt glyph switching; centralized InputMap bindings remain required and this omission blocks a broad accessibility/commercial claim, not the bounded candidate test.
- Portrait gameplay; portrait intentionally blocks combat and instructs the player to rotate.
- Credits are not yet required for this internal candidate because no public distribution is authorized; a credits/licenses surface becomes mandatory before public commercial release.

## Required Player Journeys

The game-specific graph, transitions, recovery paths and exact command IDs are defined in `design/game-state-matrix.json`.

- [x] Every currently required player-visible state and modal is represented in a required journey.
- [x] Graph reachability and declared completion states are structurally valid.
- [x] Each journey and recovery path declares a real project-local Godot test command ID.
- [x] A fresh hash-bound quality run proves every journey command after the latest presentation changes on Godot 4.6.2.
- [ ] The defeat → retry recovery path has a dedicated end-to-end assertion rather than only separate defeat and fresh-start assertions.
- [x] Guidance, configuration, interruption, hub/meta, failure, success and recovery needs are explicitly represented.
- [x] Commerce, online, portrait gameplay and public-release credits are explicitly excluded with rationale for this candidate.

## Quality Gates

- [x] Required authored art families are integrated and mapped to runtime captures in `design/assets/asset-coverage.json`.
- [ ] Final independent visual review passes every required surface; the current production-authored captures are review input only.
- [ ] Physical iOS/Android device QA verifies DPI, notch/home-indicator safe areas, thumb reach, thermals and sustained touch behavior.
- [ ] Served Web export verifies canvas focus, every advertised input, audio unlock and browser rendering in supported browsers.
- [ ] A human completes and records one uninterrupted four-minute core-loop playtest plus boss-kill and death/retry routes.
- [ ] A human listening pass verifies music/SFX balance, loop seams, loudness, pause/restart cleanup and output-device behavior.
- [x] Godot 4.6.2, within the supported 4.6/4.7 policy, produces the current import, static-analysis, journey, reliability and visual evidence.
- [ ] No blocker/high visual, usability, audio, platform or playtest finding remains.

## Current Evidence Boundary

The current shell-free quality run binds all 13 declared commands, the final command manifest, Godot 4.6.2 and project fingerprint `740e418cd08d2d68a753c5dc91e0fd05bc9c8f96d6f5c1b9c9c94cf1eddecd3f`. The 844×390 phone captures remain layout diagnostics, not physical-device proof. Independent visual review is still required until its final hash-bound verdict is recorded. Automated PCM checks do not substitute for human listening.

## Completion Rule

Do not report PLAYER_READY or commercial-ready while any required check in `production/evidence/player-ready.json` is BLOCKED, while the quality report is absent/stale, or while a required state, recovery path, device target, audio scenario or review lacks current evidence.
