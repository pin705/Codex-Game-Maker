# Architecture: [Game Title]

Status: Draft
Engine: Godot 4.7.1 unless existing project detection says otherwise

## Engine Detection

Detected engine:
Evidence:
Recommendation:

## Architecture Goals

- [Goal]
- [Goal]
- [Goal]

## Godot Project Structure

```text
project.godot
scenes/
  main/
  gameplay/
  ui/
scripts/
  core/
  gameplay/
  ui/
resources/
  data/
  tuning/
assets/
  generated/
```

## System Boundaries

| System | Godot Representation | Owns | Emits | Depends On |
|---|---|---|---|---|
| [system] | [scene/resource/autoload] | [state] | [signals] | [deps] |

## Data And Tuning

Gameplay values live in:

```text
resources/data/
resources/tuning/
assets/data/
```

Do not hardcode gameplay values in node scripts.

## Asset Pipeline

Generated assets:
Prompt provenance:
Import settings:
Web export considerations:


## Save/Load

Format:
Location:
Versioning:
Web export risks:

## Input

Keyboard/mouse:
Gamepad:
Remapping:
Touch/mobile if relevant:

## Performance Budget

Target platform:
FPS:
Memory:
Asset limits:

## Technical Risks

| Risk | Severity | Verification Plan | Source |
|---|---|---|---|
| [risk] | [Low/Med/High] | [test/research] | [doc/source] |

## Required ADRs

- [ ] ADR-0001: [decision]
- [ ] ADR-0002: [decision]
- [ ] ADR-0003: [decision]

