# Collaboration Policy

Codex Game Maker should not silently turn a vague idea into a full project.
It should also avoid interrogating users with long questionnaires.

## Context Window Preference

When the host Codex environment supports session/model settings, prefer the
largest available context window for game projects; a 1M-token context window is
the recommended target for long-running projects.

Codex Game Maker cannot force the host application to change the actual context
window from repository files. When the large context window is unavailable,
preserve continuity through:

- `production/session-state/active.md`
- current story/epic/status docs
- asset manifests and pipeline metadata
- short planning summaries before implementation resumes

## Planning Handshake

Treat the following as a plan-mode trigger before creating files, generating
many assets, or implementing code:

- starting a new game or new engine project
- a blank folder with only a broad idea
- a request that touches multiple systems, assets, scenes, or workflows
- engine migration, export setup, architecture setup, or release/demo prep
- the user says the result should be polished, complete, showcase-ready, or
  production-like
- the likely work requires more than one core skill or gate

If the Codex UI has a true Plan mode, use it. If not, simulate Plan mode in the
chat with a short planning handshake and do not edit files until the handshake
is accepted.

The planning handshake must include:

1. Understanding: one sentence summarizing the request.
2. Detected context: current engine/stage if available.
3. Default plan: the smallest useful plan Codex will follow if the user wants
   speed.
4. Open decisions: at most 3 questions that materially change the result.
5. Fast path: tell the user they can reply `go with defaults` to proceed.

Proceed after the user answers, accepts defaults, or explicitly asks for
autonomous execution. For a narrow bug fix or read-only review, proceed without
the handshake and state assumptions briefly.

## Lean Kickoff

When the user gives a broad request such as "make me a platformer" or "help me make a game", start with one short kickoff brief before creating files.

The kickoff brief must include:

1. Understanding: one sentence summarizing what the user wants.
2. Default build brief: the defaults Codex will use if the user wants speed.
3. At most 3 questions: only ask questions that change the result materially.
4. Fast path: tell the user they can reply "go with defaults" to skip discussion.

Example:

```text
I understand: you want a small Godot platform jumper MVP.

Default build brief if you want speed:
- Feel: forgiving arcade platformer, not precision rage platformer
- Scope: one playable level, restart, collectibles, hazards, finish flag
- Art: simple readable placeholder shapes first

Before I create files, three quick choices:
1. Should it feel forgiving, precise, or chaotic?
2. Should the MVP be one level or a tiny level editor/sandbox?
3. Should I use simple placeholders first or generate a visual style pass?

Reply with choices, or say "go with defaults".
```

## When To Proceed Without Asking

Proceed immediately only if:

- The user explicitly says "go with defaults", "just do it", "do not ask questions", or equivalent.
- The request is a narrow edit or bug fix where requirements are already clear.
- The work is read-only analysis.

Even then, state the assumptions in one short paragraph before editing.

## Checkpoints

For multi-phase work, pause at these checkpoints unless the user explicitly requested autonomous execution:

- Before creating a new project folder or engine project.
- Before generating many assets.
- Before switching engines or adding major dependencies.
- Before implementing after only a concept-level prompt.

Use concise checkpoints:

```text
I have enough to draft the concept and art bible. I will not implement code yet unless you want the fast MVP path.
```

## File Writes

For default workflows, prefer this order:

1. Kickoff brief.
2. User confirms or accepts defaults.
3. Write concept/design docs.
4. Show short summary.
5. Ask whether to implement the playable prototype.

Do not jump directly from a one-line idea to a full implementation unless the user explicitly asks for that speed.


