# ADR-0001: Use Godot 4 With Web Export Target

Status: Accepted  
Date: 2026-05-05

## Context

The workspace had no existing engine files. Codex Game Maker is Godot-first for blank game projects and recommends Godot 4 with a Web export path.

## Decision

Build the platform jumper as a Godot 4 project using 2D physics and the compatibility renderer.

## Consequences

- The MVP can run in the Godot editor and later be exported to the browser.
- Movement uses `CharacterBody2D` and `move_and_slide()`.
- Production assets can be added later without changing the core prototype.



