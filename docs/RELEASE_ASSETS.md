# Release Assets Checklist

This document tracks what is needed before Codex Game Maker looks polished on GitHub.

## Brand Decisions

| Item | Decision | Notes |
|---|---|---|
| Public name | Codex Game Maker | Keep internal folder paths stable for now. |
| Default README language | English | Chinese version lives in `README.zh-CN.md`. |
| Target audience | Everyone | Beginner-first, with explicit professional features. |
| License | MIT | Add `LICENSE` before first public release. |
| Primary engine | Godot 4.4 | Existing web/Unity/Unreal projects are respected. |

## Visual Assets

| Asset | Recommended Content | Size |
|---|---|---:|
| `assets/brand/logo.png` | Cute cat game-maker mascot at a compact workbench | 1024x1024 |
| `assets/brand/banner.png` | Cat mascot, Codex-style workbench, sprite sheet, Godot editor, browser preview | 1600x500 |
| `assets/brand/social-preview.png` | Project name, one-line value prop, mascot, Godot + GPT Image visual cues | 1280x640 |
| `assets/brand/demo.gif` | End-to-end sprite asset pipeline to Godot Web preview | 12-20 seconds |
| `assets/brand/workflow-diagram.png` | Prompt -> GPT Image -> processor -> QA -> Godot -> browser preview | 1200x700 |

Current status:

- `logo.png`: generated and saved.
- `banner.png`: generated from the logo for README use.
- `social-preview.png`: generated from the logo for GitHub social preview.
- `demo.gif`: still needed.
- `workflow-diagram.png`: still needed.

## Demo GIF Flow

Recommended sequence:

1. Prompt: "Use Codex Game Maker to create a cute cat platformer hero."
2. Show generated action bundle files: `idle`, `run`, `jump`, `attack`, `hurt`.
3. Show GPT Image raw sheets under `assets/raw/`.
4. Run asset processor and show transparent frames + GIF previews.
5. Run `tools/import-sprite-to-godot.ps1`.
6. Show `SpriteFrames` and `AnimatedSprite2D` scene in Godot.
7. Run browser preview.

Keep terminal footage short. The point is proof, not logs.

## Credibility Pattern

Claude Code Game Studios presents credibility through concrete counts and visible structure: agents, skills, hooks, rules, templates, slash commands, project structure, platform support, and philosophy. Codex Game Maker should use the same proof style, but with leaner numbers and asset-first positioning.

Recommended badges:

- MIT License
- Godot 4.4
- GPT Image Ready
- Windows / macOS / Linux
- v0.1-alpha

Recommended counts:

- 8 core skills
- 29 tool scripts
- 7 guard scripts
- 30 templates
- 2 asset processor/workflow scripts
- optional professional command aliases

## Before Public Release

- Replace placeholder GitHub URLs in README.
- Add final logo, banner, and social preview.
- Add one real asset-driven showcase, not only a skeleton.
- Record one short demo GIF.
- Run Windows validation.
- Run macOS smoke test.
- Run Linux smoke test.
- Check that `tmp/`, `.tools/`, `.godot/`, and `build/` are not committed.

