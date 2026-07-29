# Player-Ready Contract: [Game Title]

Status: Draft
Target gate: PLAYER_READY
Release profile: [web-demo | desktop-premium | mobile | custom]
Target devices:
Target session length:

## Player Promise

Core fantasy:
Complete player journey:
Quality bar:

## Scope Boundary

Required systems:
- [system]

Required content:
- [content]

Explicitly excluded:
- [out-of-scope]

## Required Player Journeys

Define the game-specific journeys in `design/game-state-matrix.json`. Do not copy a universal menu/state list. Each required journey must declare its own start, required states, completion states, transitions, recovery paths, executable test command, and runtime evidence.

- [ ] Every player-visible state and modal required by this game's GDD is represented in a required journey.
- [ ] Every required state is reachable from its journey start.
- [ ] Every journey reaches its declared completion condition.
- [ ] Every required recovery/retry/continue/return path is reachable and command-tested.
- [ ] Game-specific guidance, configuration, interruption, save/exit, failure, success, hub, narrative, or live-session needs are explicitly required or explicitly excluded with rationale.

## Quality Gates

- [ ] Required art coverage is integrated and runtime-verified.
- [ ] Look-dev is locked; asset presentation usages and structured visual quality checks pass for every required state and target viewport.
- [ ] UI is art-directed, responsive, readable, and navigable without a mouse.
- [ ] Audio coverage is integrated or intentional silence is justified.
- [ ] Core-loop and long-run automated tests pass.
- [ ] Manual player journey is recorded.
- [ ] No blocker/high visual or usability finding remains.

## Completion Rule

Do not report the game complete while any required state, system, asset group, UI surface, audio event, or evidence item is planned, mock, placeholder, draft, missing, or blocked.
