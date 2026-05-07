# Core Agent Roster

Codex Game Maker uses six useful role lenses by default. Do not create a large roster unless a project proves it needs more specialization.

## Creative

Use for game identity, fantasy, pillars, emotional tone, hook, and anti-pillars.
Output: risks to vision, pillar conflicts, stronger alternatives.

## Game Design

Use for core loops, systems, rules, formulas, tuning knobs, progression, and MVP boundaries.
Output: missing rules, untestable mechanics, scope risks, candidate acceptance criteria.

## Art

Use for visual identity, art bible, asset specs, prompt quality, readability, UI/icon/sprite consistency.
Output: art bible alignment, asset list gaps, generation prompt improvements.

## Technical

Use for engine detection, Godot-first architecture, implementation risks, export constraints, file structure, tests.
Output: engine recommendation, version/API risks, architecture constraints, official docs to verify.

## Production

Use for milestones, sprint scope, sequencing, dependencies, and "what next" decisions.
Output: smallest useful next step, scope cuts, milestone risks.

## QA

Use for test plans, playtest evidence, acceptance criteria, regression risks, release readiness.
Output: what must be verified, automated vs manual evidence, blockers.

## Asset QA Lenses

Use these as focused review lenses when runtime generated assets are accepted into a Godot project. They are not separate default runtime agents.

- Sprite QA: checks frame count, alpha transparency, chroma-key cleanup, frame alignment, edge clipping, GIF previews, and metadata.
- Map/Level Asset QA: checks map preview, separate props, collision metadata, zone metadata, and whether playable maps avoid becoming a single static background.
- Godot Import QA: checks import manifests, `res://` references, Sprite2D/AnimatedSprite2D/TileMapLayer/StaticBody2D/Area2D target usage, pivots, anchors, and collision roles.

## Use Policy

Default: apply these as review lenses in the main Codex response.

Spawn real sub-agents only when:
- the user explicitly asks for multiple agents, delegation, or parallel work
- a team workflow is invoked
- write scopes can be separated cleanly

Every spawned worker must have a concrete ownership boundary.


