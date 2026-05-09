---
name: game-studio-design
description: Design a game from idea to usable GDD artifacts. Use for brainstorming, concept docs, core loops, pillars, systems maps, system GDDs, and design reviews. Uses a lean six-role review lens instead of a large agent roster, and follows Godot-first assumptions for blank projects.
---

# Game Studio Design

Use this for concept and systems design.

## Inputs To Check

Read if present:
- `design/gdd/game-concept.md`
- `design/gdd/systems-index.md`
- `design/art/art-bible.md`
- `production/session-state/active.md`
- repo-local `codex-game-studio/references/agents/core-agent-roster.md` or installed-skill `references/agents/core-agent-roster.md`
- repo-local `codex-game-studio/references/policies/collaboration-policy.md` or installed-skill `references/policies/collaboration-policy.md`
- repo-local `codex-game-studio/references/policies/engine-selection.md` or installed-skill `references/policies/engine-selection.md`
- repo-local `codex-game-studio/references/policies/web-search-policy.md` or installed-skill `references/policies/web-search-policy.md`
- repo-local `codex-game-studio/references/templates/kickoff-brief.md` or installed-skill `references/templates/kickoff-brief.md`

Before engine recommendations, detect existing project files. Blank projects default to Godot 4.4 + Web export.

## Lean Kickoff Requirement

If the user's input is only a genre, one-line idea, new project request, or broad multi-system request, do not create documents or code immediately. First produce:
- one-sentence understanding
- detected engine/stage when available
- default assumptions
- a short draft plan
- at most 3 high-impact questions
- "go with defaults" fast path

Proceed after the user answers or explicitly accepts defaults.

## Workflow

1. Clarify the user's current state: no idea, vague idea, clear concept, or existing work.
2. Produce or update `design/gdd/game-concept.md` using repo-local `codex-game-studio/references/templates/game-concept.md` or installed-skill `references/templates/game-concept.md`.
3. Define 3-5 game pillars and 3 anti-pillars.
4. Define the core loop at 30 seconds, 5-15 minutes, session, and long-term levels.
5. Produce `design/gdd/systems-index.md` with MVP systems and dependencies.
6. For each MVP system, create a system GDD using repo-local `codex-game-studio/references/templates/system-gdd.md` or installed-skill `references/templates/system-gdd.md`.
7. Run the six-role review lens:
   - Creative: is the fantasy and hook coherent?
   - Game Design: are rules, loops, and MVP boundaries testable?
   - Art: does the concept imply a clear visual identity?
   - Technical: is Godot/Web export plausible for the MVP?
   - Production: is the scope realistic?
   - QA: can the core fun hypothesis be tested?

## Write Policy

For new docs, create directories as needed and write incrementally. Keep `production/session-state/active.md` updated with:
- current artifact
- completed sections
- open questions
- next recommended step

Do not jump from concept design straight into playable code unless the user explicitly asks for the fast MVP path after seeing the design assumptions.

## Web Search Use

Use web search for:
- genre/market references when the user asks for examples or says ideas feel weak
- Godot version/API uncertainty
- official Godot docs for renderer/export/input/platform constraints
- public references for art direction if the user dislikes generated direction

Do not invent engine API details when official docs are available.

