# Release Assets Checklist

This document tracks what is needed before Codex Game Maker looks polished on GitHub.

## Brand Decisions

| Item | Decision | Notes |
|---|---|---|
| Public name | Codex Game Maker | Keep internal folder paths stable for now. |
| Default README language | English | Chinese version lives in `README.zh-CN.md`. |
| Target audience | Everyone | Beginner-first, with explicit professional features. |
| License | MIT | Add `LICENSE` before first public release. |
| Primary engine | Godot 4.6.2 | Existing web/Unity/Unreal projects are respected. |

## Visual Assets

| Asset | Recommended Content | Size |
|---|---|---:|
| `assets/brand/logo.png` | Original jade spirit-fox and ink-brush sword emblem for the game studio tool | 1024x1024 |
| `assets/brand/banner.png` | Ink-and-jade cultivation realm with production-grid motifs and negative space for README copy | 1600x500 |
| `assets/brand/social-preview.png` | Original spirit-fox/sword key art with dark copy-safe space for GitHub metadata | 1280x640 |
| `assets/brand/demo.gif` | End-to-end sprite asset pipeline to Godot Web preview | 12-20 seconds |
| `assets/brand/workflow-diagram.png` | Prompt -> GPT Image -> processor -> QA -> Godot -> browser preview | 1200x700 |

Current status:

- `logo.png`: generated original emblem; no copied brand marks, mascot or in-image text.
- `banner.png`: generated ink-and-jade studio visual; no stale Godot 4.4/v0.1-alpha labels.
- `social-preview.png`: generated copy-safe social visual; repository title and description remain live Markdown/metadata rather than unreliable in-image text.
- `demo.gif`: optional showcase enhancement.
- `workflow-diagram.png`: optional showcase enhancement.

## Demo GIF Flow

Recommended sequence:

1. Prompt: "Use Codex Game Maker to build a cultivation-survivor player-ready slice with a locked original ink-and-jade style."
2. Show generated action bundle files: `idle`, `run`, `cast`, `hurt`, `death`.
3. Show GPT Image raw sheets under `assets/raw/`.
4. Run asset processor and show transparent frames + GIF previews.
5. Run `plugins/codex-game-maker/tools/import-sprite-to-godot.ps1`.
6. Show `SpriteFrames` and `AnimatedSprite2D` scene in Godot.
7. Run browser preview.

Keep terminal footage short. The point is proof, not logs.

## Credibility Pattern

Claude Code Game Studios presents credibility through concrete counts and visible structure: agents, skills, hooks, rules, templates, slash commands, project structure, platform support, and philosophy. Codex Game Maker should use the same proof style, but with leaner numbers and asset-first positioning.

Recommended badges:

- MIT License
- Godot 4.6.2
- GPT Image Ready
- Windows / macOS / Linux
- v1.0.0 stable

Recommended counts:

- 23 core skills
- 32 tool scripts
- 7 top-level cross-platform Python CLI scripts
- 9 guard scripts
- 60 templates
- 2 asset processor/workflow scripts
- 20 natural-language command aliases

## Optional Showcase Enhancements

- Add a real asset-driven showcase from a released example project.
- Record one short demo GIF.
- Render a static workflow diagram from the current commercial lifecycle.

Repository validation remains mandatory on Windows, macOS, and Linux release targets; generated game output under `tmp/`, `.tools/`, `.godot/`, and `build/` must stay uncommitted.
