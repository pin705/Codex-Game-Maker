# ADR-0001: Godot 4.4 GDScript + Compatibility Web Runtime

Status: Accepted and native-runtime verified; Web export verification pending  
Date: 2026-07-29  
Engine: Godot 4.4

## Context

`Vân Mộng Tu Tiên` needs a compact 2D top-down arena that starts quickly in desktop browsers, maintains a deterministic four-minute session, draws an ink-wash look procedurally and supports explicit keyboard controls. The repository is Godot-first, the current project is Godot 4.4 with GL Compatibility, and the canonical implementation uses a logical 1600x900 canvas with a 1280x720 window override.

The local environment did not expose `godot`, `godot4`, `pwsh`, or `powershell` on PATH during this decision. This ADR can select the target, but cannot claim that parsing, running, export templates or browser output were verified.

## Decision

Use:

- Godot 4.4 with typed GDScript where practical;
- 2D scenes/nodes and `CharacterBody2D` in floating motion mode for top-down controlled bodies;
- Compatibility renderer for WebGL 2.0;
- the default/preferred single-threaded Web export path;
- logical 1600x900 design viewport with a 1280x720 window override and 16:9-preserving stretch;
- explicit project-specific Input Map actions: `move_left`, `move_right`, `move_up`, `move_down`, `qi_pulse`, `pause_game`, `restart_game`, `confirm`;
- short imported WAV cues through `AudioStreamPlayer`/`AudioStreamWAV` only as optional presentation;
- procedural runtime ink-wash geometry, with accepted key art isolated to title presentation.

Do not add C#, GDExtension, native plugins, runtime network services, required multithreading, remote font/texture loading or a non-Godot web fallback for this MVP.

## Options Considered

| Option | Pros | Cons | Fit |
|---|---|---|---|
| Godot 4.4 + GDScript + Compatibility, single-thread Web | Repository default; strong 2D scene/input tools; one source for desktop/Web; Web path documented; procedural draw APIs | Requires editor/export templates; Web/browser constraints must be tested | Chosen |
| Godot 4.4 threaded Web export | Potentially more performance and stream-audio capability | Requires cross-origin isolation/headers or PWA workaround; unnecessary for bounded 2D MVP | Rejected for MVP |
| Phaser/TypeScript | Direct browser toolchain and DOM integration | Conflicts with accepted Godot brief and existing project | Rejected |
| Canvas/WebGL custom runtime | Maximum control, minimal engine payload possible | Rebuilds scene/input/collision/export infrastructure; high production risk | Rejected |
| Godot C# | Familiar typed language for some teams | Godot 4 C# projects cannot currently export to Web per official docs | Rejected |

## Rationale

The game is a bounded 2D simulation with simple pursuit, overlaps, timers and UI overlays. Godot's scene tree and GDScript are sufficient without third-party packages. `CharacterBody2D` provides a script-driven character body and explicitly documents `MOTION_MODE_FLOATING` for top-down motion. Compatibility is required for Godot 4 Web; Forward+/Mobile do not target WebGL 2.0. Single-thread Web is the documented preferred default and removes cross-origin-isolation setup from the first playable milestone.

The rendering strategy also reduces asset risk: `_draw()`, polygons, lines, gradients and modest particles deliver the combat language, while `KEYART-001` remains title presentation. Imported short WAV cues are simple to package, but audio never carries gameplay-critical information because browsers can gate playback until a user gesture.

## Godot Implementation Notes

Scenes:

- `scenes/main.tscn` is the composition root for arena/session/UI;
- `CharacterBody2D` player and simple enemy entities;
- lightweight projectile nodes and explicit distance contracts for hits/pickups;
- `CanvasLayer` HUD, level-up/pause and terminal overlays.

Resources:

- `resources/tuning/game_balance.json` is the current authoritative balance source;
- stable upgrade/enemy IDs, separate from node names and filenames;
- generated asset paths resolved from accepted manifest entries only.

Autoloads:

- one small `Events` signal hub is acceptable for this MVP;
- no global Node should own arbitrary UI state and gameplay state together.

Signals/events:

- gameplay emits health, XP, cooldown, death, boss and session facts;
- UI receives facts and emits selection/pause/restart requests;
- session owns transitions and idempotent result resolution.

Data files:

- tuning remains outside node scripts where possible;
- MVP has no persistence/save format.

## Web Export Notes

- Godot 4 Web targets WebGL 2.0 through the Compatibility renderer.
- Single-thread export is preferred/default in current 4.4 docs and avoids mandatory SharedArrayBuffer/cross-origin-isolation headers.
- Export to `index.html` and serve the whole output directory over HTTP(S); do not test by double-clicking files.
- Web audio may be blocked until a user gesture. Default Web sample playback has limitations; use simple imported cues and no required audio effect chain/procedural audio.
- Test canvas focus, focus loss, WASD/arrows, Space, P, R, Enter and mouse card selection in a served browser build.
- Keep generated splash compressed and local; no runtime network request.
- The `.pck`, `.wasm`, `.js` and related export filenames must remain consistent with the generated HTML/export.

## Consequences

Positive:

- one Godot codebase covers editor and Web target;
- architecture stays small and matches a four-minute MVP;
- no dependency install or host-specific header requirement for the default build;
- game remains playable if audio or optional art is absent.

Negative:

- WebGL 2.0/Compatibility limits renderer features;
- browser focus, autoplay and export serving add manual QA;
- single-thread mode means performance must come from caps/simple simulation rather than background work;
- Godot editor + 4.4 export templates are required before validation.

Follow-up:

1. Install or provide a Godot 4.4 executable and Web export templates.
2. Parse/open project, run one native smoke test, configure Web preset.
3. Export/serve locally and verify controls, modal focus, audio gesture and four-minute completion.
4. Reconsider threading only if a measured bottleneck survives entity caps/optimization.

## Verification

- [x] `project.godot` opens in Godot 4.4 without script parse/import errors.
- [x] Native smoke completes boss-victory, timeout-victory and death routes; physical restart remains manual follow-up.
- [ ] Web export produces served `index.html` with no console-fatal error.
- [ ] Chromium and Firefox verify canvas focus plus every advertised binding.
- [ ] 60 FPS target is assessed near 2:30/boss pressure.
- [ ] Audio-muted and blocked-autoplay paths remain fully understandable.

Not run at ADR time: Godot CLI/editor validation, export and browser tests. Required tooling was absent from PATH.

## Sources

Official Godot Engine 4.4 documentation, checked 2026-07-29:

- Web export: https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_web.html
- `CharacterBody2D`: https://docs.godotengine.org/en/4.4/classes/class_characterbody2d.html
- `InputEventKey`: https://docs.godotengine.org/en/4.4/classes/class_inputeventkey.html
- `AudioStreamWAV`: https://docs.godotengine.org/en/4.4/classes/class_audiostreamwav.html
