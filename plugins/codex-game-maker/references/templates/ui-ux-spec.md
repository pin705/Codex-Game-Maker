# UI/UX Spec: [Game Title]

Status: Draft
Implementation mode: [godot-theme | diegetic | custom-draw | hybrid | intentionally-minimal]
Minimal UI rationale:
Visual quality contract: `production/reviews/visual-quality-contract.json`
Style lock: `design/art/style-lock.json`
Style version:
Style SHA-256:
Visual/layout smoke command ID:

Implementation resources:
- res://[project-local-theme-scene-script-or-resource]

## Visual Language

Materials, shape language, palette, typography, iconography, depth and ornament:

## Screen Inventory

| State ID | Player goal | Required components | Input modes | Evidence |
|---|---|---|---|---|
| [state-id-from-game-state-matrix] | [game-specific goal] | [components] | [inputs] | [runtime path] |

## HUD Hierarchy

Critical persistent information:
Contextual information:
Center-playfield protection:

## Component System

Theme/style resources:
Panels and frames:
Buttons and focus states:
Meters, cards, tooltips and prompts:

| Asset/component ID | Source kind | Render mode | Native/frame size | Runtime/tested size range | Protected text rect | Evidence |
|---|---|---|---|---|---|---|
| [component-id] | [dedicated-component] | [uniform / nine-slice / tile / cover / custom] | [size] | [min / max] | [rect] | [runtime capture] |

## Input And Focus

Keyboard/mouse:
Controller:
Touch if applicable:
Dynamic prompt strategy:

## Responsive Layout

Reference resolution:
Safe zones:
UI scale behavior:
Target resolutions/aspects:

## Accessibility

Text sizing and contrast:
Non-color encoding:
Reduced motion:
Remapping and prompt updates:

## Motion And Feedback

Transition language:
Hover/focus/pressed/disabled states:
UI audio cues:

## Evidence

Runtime captures:
Navigation test:
Known findings:
