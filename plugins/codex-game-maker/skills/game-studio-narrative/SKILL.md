---
name: game-studio-narrative
description: "Design, implement, and verify production-ready game narrative. Use for narrative pillars, world and character bibles, quest/dialogue structure, branching state, content ratings, localization IDs, VO/cinematic plans, narrative implementation, continuity, save compatibility, and runtime narrative QA."
---

# Game Studio Narrative

Connect narrative intent to gameplay state, implementation, localization, audio, and content compliance.

## Required Output

Create `design/narrative/narrative-bible.md` from `../../references/templates/narrative-bible.md` when narrative is in scope.

## Workflow

1. Define narrative promise, themes, tone, audience/content boundaries, world rules, characters, arcs, and delivery channels.
2. Map story beats to player actions and game states. Avoid cutscene-only solutions when play can carry meaning.
3. Assign stable IDs to dialogue, objectives, barks, subtitles, choices, and codex entries.
4. Define branching variables, conditions, consequences, fallback behavior, save/version migration, and test paths.
5. Record VO, portrait, cinematic, music, localization, content-rating, accessibility, and performance dependencies.
6. Implement one complete narrative slice, then test every reachable branch, skip/replay behavior, interruption, failure, and resume.
7. Run continuity, spoiler, truncation, subtitle, rating, and linguistic QA before content lock.

Unreachable states, broken conditions, missing fallback, hard-coded final text, continuity blockers, absent subtitle IDs, or unreviewed rating-sensitive content block narrative completion.
