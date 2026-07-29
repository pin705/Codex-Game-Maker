# Player Journey Contract v2

Use `design/game-state-matrix.json` as a game-specific directed graph. The gate validates the declared graph; it never supplies a universal list of screen or state IDs.

## Contract Shape

- `schema_version`: must be `2`.
- `states`: unique state objects with `id`, game-specific `role`, `required`, `status`, `ui_surface`, `scene`, `evidence`, and `transitions`.
- `journeys`: unique player journeys with `start_state`, `required_states`, `completion_states`, `test_command_id`, optional required `recovery_paths`, and runtime `evidence`.
- `experience_requirements`: game-specific product requirements mapped through `fulfilled_by` state IDs and evidence.
- `quality_requirements`: required command mappings. Include one each for `engine_import`, `static_analysis`, and `reliability`; add project-specific kinds freely.
- `required_evidence_checks`: the exact check IDs that must be `PASS` in `production/evidence/player-ready.json`.

## Derivation Rule

Build the graph from the GDD, system boundaries, audience, target device, session model, persistence model, and player promise. Consider—but do not automatically require—entry/front door, guidance, configuration, interruption, save/exit, hub/meta, narrative, commerce, matchmaking, failure, success, recovery, replay, credits, and live-event paths.

For every material conventional surface, either:

1. represent it as a state or experience requirement, or
2. record why this game deliberately does not need it in the player-ready contract or relevant system GDD.

Do not create fake title/pause/victory states merely to satisfy a checklist. Do not omit custom states merely because they are not in a template.

## Transition And Journey Rules

- Every transition references an existing state and records the real player/system trigger.
- Every required state belongs to at least one required journey as its start, a required state, or a completion state; do not duplicate IDs between those fields merely to satisfy the gate.
- Every required journey can reach all of its required and completion states from its start.
- Every required recovery source is reachable from that journey's start, its target is reachable from the source, the target can return to a declared completion state, and the path has its own executable `test_command_id`.
- A completion state means the journey promise was fulfilled, failed, safely exited, handed off, or intentionally looped. It need not be named victory or defeat.
- Endless and sandbox games may complete a session through save-and-exit, return-to-hub, handoff, or another declared session boundary.

## Evidence Rules

Every required state needs current project-local image/video evidence. Evidence can be:

```json
"evidence": ["production/evidence/states/world.png"]
```

or a marked segment in shared video:

```json
"evidence": [
  {"path": "production/evidence/session.webm", "marker": "00:42 roaming-loop"}
]
```

One still image cannot prove multiple required states. Each required state needs at least one image or marked video segment unique to that state. A shared video can cover multiple states only when each state declares a distinct marker. Journey evidence proves the end-to-end path in addition to per-state evidence.

## Coverage Contracts

The state graph drives adjacent contracts:

- UI: every `ui_surface` appears by exact ID in the UI screen inventory.
- Assets: groups and `minimum_distinct_assets` are derived from visible systems and cited inventory sources; the distinct-asset floor cannot be lower than the declared required asset-ID inventory.
- Visual quality: `production/reviews/visual-quality-contract.json` covers every required state at every declared target viewport, locks look-dev references, verifies asset/UI coherence and binds current captures to a visual-smoke command.
- Audio: buses, coverage rows, events, and distinct-asset floor are derived from actual state/action/mix needs.
- Quality: each journey and required recovery path contributes a command ID to the shell-free quality run.
- Player-ready evidence: required check IDs come from this game, not a global list.

Changing the GDD, state graph, content boundary, or target platform requires re-auditing these dependent contracts before the gate can be trusted.
