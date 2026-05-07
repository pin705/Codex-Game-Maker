# Game Concept: Platform Jumper

Status: Draft  
Engine target: Godot 4 + Web export

## Elevator Pitch

A compact 2D platform jumping game where the player crosses a floating training course, collects crystals, avoids spikes, and reaches a beacon.

## Core Fantasy

The player feels nimble, precise, and in control while chaining jumps across readable platforms.

## Unique Hook

Classic single-screen platforming plus forgiving controls: coyote time, jump buffering, and one extra air jump keep the game approachable without removing timing skill.

## Player Experience

Primary MDA aesthetic: Challenge  
Secondary aesthetics: Sensation, Discovery  
Target player: Casual platformer players who want a short skill test.

## Core Loop

30 seconds: Move, jump, collect a crystal, recover from a missed landing.  
5-15 minutes: Replay the course to collect everything and reduce mistakes.  
Session: Learn the level layout and complete it consistently.  
Long term: Add more levels, hazards, movement upgrades, and timing medals.

## Pillars

1. Responsive movement - Every input should feel immediate and readable.  
   Design test: If a player misses a jump, can they understand why?
2. Fair hazards - Threats are visible before they are dangerous.  
   Design test: Avoid surprise damage from offscreen or hidden objects.
3. Fast recovery - Failure restarts the player quickly at the beginning.  
   Design test: Death should interrupt flow for less than one second.
4. Clear objective - Collectibles and the exit are visually distinct.  
   Design test: The player can identify the goal without tutorial text.

## Anti-Pillars

- Not a precision masocore platformer, because the MVP should be approachable.
- Not a combat game, because movement is the core test.
- Not an open-world exploration game, because the MVP validates one tight level.

## Visual Identity Anchor

One-line visual rule: Clean neon arcade shapes on a dark readable background.  
Shape language: Rounded player, hard-edged platforms, sharp triangular hazards, diamond rewards.  
Color philosophy: Cyan for terrain, yellow for the player, pink for danger, green for completion.  
Motion/feedback feel: Snappy jumps, quick respawns, simple sparkle-like collectibles.

## MVP Hypothesis

The MVP proves: A small handcrafted level is fun when movement has forgiving timing and visible goals.

Required:
- Player movement with coyote time, jump buffer, and air jump.
- Static platforms, hazards, collectibles, and an exit beacon.
- HUD showing crystals, deaths, and completion state.

Not in MVP:
- Multiple levels.
- Enemies.
- Save/load.
- Generated raster production assets.

## Risks

Design: Jump tuning may be too floaty or too strict.  
Technical: Manual scene generation must stay simple enough for Godot Web export.  
Art/assets: Placeholder shapes need enough contrast to be playable.  
Production: Scope can expand quickly if level editor tools are added too early.  
QA/playtest: Needs real playtesting in Godot to tune distances.

## Next Step

Open the Godot project, run the main scene, and tune `resources/tuning/player_movement.tres`.

