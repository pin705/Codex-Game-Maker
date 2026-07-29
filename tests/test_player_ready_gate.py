import json
import math
import os
import struct
import subprocess
import sys
import tempfile
import unittest
import wave
import zlib
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
PLUGIN = REPO_ROOT / "plugins/codex-game-maker"
PLAYER_GATE = PLUGIN / "scripts/guards/player_ready_gate.py"
COMMERCIAL_GATE = PLUGIN / "scripts/guards/commercial_release_gate.py"
QUALITY_RUNNER = PLUGIN / "scripts/quality_runner.py"
VALIDATION_LIB = PLUGIN / "scripts/lib"
sys.path.insert(0, str(VALIDATION_LIB))

from cgm_validation import sha256_path  # noqa: E402


CLASSIC_STATES = (
    "launch-pad", "front-door", "guided-first-step", "active-run",
    "interrupt-layer", "tuning-desk", "success-recap", "recovery-recap",
)
ASSET_GROUPS = ("actors-and-actions", "world-and-affordances", "presentation-and-feedback")
AUDIO_EVENTS = ("navigate-choice", "perform-action", "world-bed", "session-outcome")
EVIDENCE_CHECKS = ("primary-journey", "presentation", "sound", "manual-playtest")
VISUAL_SURFACE_CHECKS = (
    "art_bible_coherence", "cross_asset_coherence", "composition_hierarchy",
    "text_legibility", "no_overlap_or_clipping", "asset_scale_grounding",
    "safe_zones", "input_focus_feedback", "no_placeholder_or_generic_ui",
    "no_distorted_textures",
)
VISUAL_CROSS_SURFACE_CHECKS = (
    "world_character_scale", "world_character_palette_lighting",
    "world_ui_material_language", "component_reuse_without_monotony",
    "typography_hierarchy", "motion_fx_language",
)
COMPLIANCE_ITEMS = (
    "asset-rights", "dependency-licenses", "ai-provenance", "privacy-data-inventory",
    "privacy-policy-decision", "content-rating", "third-party-notices", "platform-terms",
    "commerce-disclosures", "secrets-scan",
)
ACCESSIBILITY_FEATURES = (
    "text-readability", "contrast", "non-color-cues", "subtitles-captions", "audio-alternatives",
    "input-remapping", "ui-navigation-focus", "difficulty-timing-assists", "motion-camera-controls",
    "photosensitivity", "accessible-help-support", "player-review",
)


def write(root: Path, relative: str, content: str = "verified\n") -> Path:
    path = root / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    return path


def write_json(root: Path, relative: str, value: dict) -> Path:
    return write(root, relative, json.dumps(value, indent=2))


def _png_chunk(kind: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)


def write_png(root: Path, relative: str, color: tuple[int, int, int], width: int = 640, height: int = 360) -> Path:
    path = root / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    scanline = b"\x00" + bytes(color) * width
    raw = scanline * height
    data = b"\x89PNG\r\n\x1a\n"
    data += _png_chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
    data += _png_chunk(b"IDAT", zlib.compress(raw, 9))
    data += _png_chunk(b"IEND", b"")
    path.write_bytes(data)
    return path


def write_wav(root: Path, relative: str, frequency: int = 440) -> Path:
    path = root / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    rate = 22050
    frames = bytearray()
    for index in range(rate // 5):
        sample = int(6000 * math.sin(2 * math.pi * frequency * index / rate))
        frames.extend(struct.pack("<h", sample))
    with wave.open(str(path), "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(rate)
        handle.writeframes(bytes(frames))
    return path


def run_json(script: Path, root: Path, *args: str) -> tuple[subprocess.CompletedProcess, dict]:
    result = subprocess.run(
        [sys.executable, str(script), "--root", str(root), *args],
        check=False,
        capture_output=True,
        text=True,
    )
    return result, json.loads(result.stdout)


def run_quality(root: Path, profile: str) -> None:
    result = subprocess.run(
        [sys.executable, str(QUALITY_RUNNER), "--root", str(root), "--profile", profile],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise AssertionError(result.stdout + result.stderr)


def create_fake_godot(root: Path) -> str:
    if os.name == "nt":
        path = write(
            root,
            "tools/godot.cmd",
            "@echo off\r\nif \"%1\"==\"--version\" (echo 4.7.1.stable.official.fixture) else (echo Godot fixture command: PASS)\r\n",
        )
    else:
        path = write(
            root,
            "tools/godot",
            "#!/usr/bin/env python3\nimport sys\nprint('4.7.1.stable.official.fixture' if '--version' in sys.argv else 'Godot fixture command: PASS')\n",
        )
        path.chmod(0o755)
    return str(path.relative_to(root))


def quality_commands(
    include_commercial: bool = False,
    journey_commands: tuple[str, ...] = ("core_loop", "recovery_flow"),
    visual_artifacts: tuple[str, ...] = (),
) -> list[dict]:
    command_ids = ["godot_import", "godot_lint", "long_run", "visual_smoke", *journey_commands]
    if include_commercial:
        command_ids.extend(["build_web", "smoke_web", "performance_web"])
    return [
        {
            "id": command_id,
            "argv": (["{godot}", "--headless", "--editor", "--quit"] if command_id == "godot_import" else [sys.executable, "tests/quality_probe.py", command_id]),
            "cwd": ".",
            "timeout_seconds": 30,
            "required_for": ["player_ready", "commercial_release"] if command_id in {"godot_import", "godot_lint", "long_run", "visual_smoke", *journey_commands} else ["commercial_release"],
            "expected_artifacts": list(visual_artifacts) if command_id == "visual_smoke" else [],
        }
        for command_id in command_ids
    ]


def create_visual_contract(root: Path, state_captures: dict[str, str]) -> None:
    artifacts = tuple(sorted(set(state_captures.values())))
    write_json(root, "production/reviews/visual-quality-contract.json", {
        "schema_version": 1,
        "status": "verified",
        "reviewer": "Fixture Visual Reviewer",
        "reviewer_mode": "independent-agent",
        "reviewer_independence": "Fixture reviewer did not author the runtime surfaces",
        "build": "fixture",
        "review_method": "actual-runtime-capture-inspection",
        "required_viewports": [{"id": "fixture-640x360", "width": 640, "height": 360, "device": "fixture viewport"}],
        "art_direction": {
            "identity_rule": "Warm carved fixture presentation with clear silhouettes and restrained focus light",
            "materials": ["carved metal", "matte field"],
            "shape_language": ["strong silhouettes", "framed hierarchy"],
            "palette_roles": ["warm focus", "cool world", "high-contrast text"],
            "typography_roles": ["display", "body", "numeric feedback"],
            "forbidden_patterns": ["generic dashboard", "distorted textures", "overlapping text"],
        },
        "lookdev": {
            "source_mode": "authored",
            "status": "verified",
            "representative_asset_ids": ["fixture-lookdev"],
            "candidate_ids": [],
            "accepted_candidate_ids": [],
            "rejected_candidate_ids": [],
            "candidate_evidence": [],
            "locked_reference_paths": [artifacts[0]],
            "decision_rationale": "Authored fixture reference establishes the target material, scale, and hierarchy",
            "evidence": [artifacts[0]],
        },
        "surfaces": [
            {
                "id": state_id,
                "state_id": state_id,
                "status": "verified",
                "captures": [{"viewport_id": "fixture-640x360", "path": capture, "sha256": sha256_path(root / capture)}],
                "checks": {check: "PASS" for check in VISUAL_SURFACE_CHECKS},
                "not_applicable_rationales": {},
                "findings": [],
            }
            for state_id, capture in state_captures.items()
        ],
        "cross_surface_checks": {check: "PASS" for check in VISUAL_CROSS_SURFACE_CHECKS},
        "not_applicable_rationales": {},
        "open_findings": [],
        "verification_commands": [{
            "id": "visual-smoke",
            "required": True,
            "command_id": "visual_smoke",
            "expected_artifacts": list(artifacts),
        }],
    })


def create_player_ready_fixture(root: Path, include_commercial_commands: bool = False) -> dict[str, str]:
    write(root, "scenes/main.tscn", "[gd_scene format=3]\n")
    write(root, "project.godot", '[application]\nrun/main_scene="res://scenes/main.tscn"\n[application]\nconfig/features=PackedStringArray("4.7")\n')
    write(root, "design/gdd/game-concept.md", "# Game Concept: Fixture\nStatus: Verified\nCore loop, audience, pillars, scope, and player journey verified.\n")
    write(root, "design/art/art-bible.md", "# Art Bible: Fixture\nStatus: Verified\nAuthored silhouettes, palette, typography, UI materials, motion, and asset rules verified.\n")
    write(root, "docs/architecture/architecture.md", "# Architecture: Fixture\nStatus: Verified\nGodot scene, data, signals, saves, testing, and export boundaries verified.\n")
    write(root, "docs/architecture/control-manifest.md", "# Control Manifest: Fixture\nStatus: Verified\nKeyboard, controller, focus, remapping, pause, restart, and prompt bindings verified.\n")
    write(root, "tests/quality_probe.py", """#!/usr/bin/env python3
import pathlib
import sys

if not pathlib.Path("project.godot").is_file() or len(sys.argv) != 2:
    raise SystemExit(1)
print(f"{sys.argv[1]}: verified fixture project")
""")
    write(
        root,
        "production/player-ready-contract.md",
        """# Player-Ready Contract: Test Game
Status: Approved

## Required Player States
- [x] Complete journey

## Quality Gates
- [x] Runtime and manual evidence complete
""",
    )

    state_captures: dict[str, str] = {}
    colors = ((200, 20, 20), (20, 200, 20), (100, 180, 240), (20, 20, 200), (200, 200, 20), (200, 20, 200), (20, 200, 200), (120, 80, 220))
    for state, color in zip(CLASSIC_STATES, colors):
        relative = f"production/evidence/states/{state}.png"
        write_png(root, relative, color)
        state_captures[state] = relative
    transitions = {
        "launch-pad": [{"to": "front-door", "trigger": "startup-complete"}],
        "front-door": [{"to": "guided-first-step", "trigger": "begin-session"}, {"to": "tuning-desk", "trigger": "configure"}],
        "guided-first-step": [{"to": "active-run", "trigger": "guidance-complete"}],
        "active-run": [{"to": "interrupt-layer", "trigger": "interrupt-request"}, {"to": "success-recap", "trigger": "goal-met"}, {"to": "recovery-recap", "trigger": "run-ended"}],
        "interrupt-layer": [{"to": "active-run", "trigger": "resume"}, {"to": "tuning-desk", "trigger": "configure"}],
        "tuning-desk": [{"to": "front-door", "trigger": "configuration-saved"}],
        "success-recap": [{"to": "front-door", "trigger": "continue"}],
        "recovery-recap": [{"to": "active-run", "trigger": "try-again"}],
    }
    write_json(
        root,
        "design/game-state-matrix.json",
        {
            "schema_version": 2,
            "release_profile": "web-demo",
            "states": [
                {
                    "id": state,
                    "role": f"fixture-role-{state}",
                    "required": True,
                    "status": "verified",
                    "ui_surface": True,
                    "scene": "res://scenes/main.tscn",
                    "evidence": [state_captures[state]],
                    "transitions": transitions[state],
                }
                for state in CLASSIC_STATES
            ],
            "journeys": [{
                "id": "primary-session", "required": True, "goal": "Complete and recover a fixture run",
                "start_state": "launch-pad", "required_states": list(CLASSIC_STATES),
                "completion_states": ["success-recap", "recovery-recap"], "test_command_id": "core_loop",
                "recovery_paths": [{"from": "recovery-recap", "to": "active-run", "required": True, "test_command_id": "recovery_flow"}],
                "evidence": [state_captures["active-run"], state_captures["success-recap"]],
            }],
            "experience_requirements": [
                {"id": "first-session-guidance", "required": True, "rationale": "Fixture input needs guided discovery", "fulfilled_by": ["guided-first-step"], "evidence": [state_captures["guided-first-step"]]},
                {"id": "runtime-configuration", "required": True, "rationale": "Fixture exposes declared preferences", "fulfilled_by": ["tuning-desk"], "evidence": [state_captures["tuning-desk"]]},
                {"id": "session-recovery", "required": True, "rationale": "A failed fixture run can be retried", "fulfilled_by": ["recovery-recap", "active-run"], "evidence": [state_captures["recovery-recap"]]},
            ],
            "quality_requirements": [
                {"id": "engine-import", "kind": "engine_import", "required": True, "command_id": "godot_import"},
                {"id": "static-analysis", "kind": "static_analysis", "required": True, "command_id": "godot_lint"},
                {"id": "soak", "kind": "reliability", "required": True, "command_id": "long_run"},
            ],
            "required_evidence_checks": list(EVIDENCE_CHECKS),
        },
    )

    captures = {
        **state_captures,
        "title": state_captures["front-door"],
        "gameplay": state_captures["active-run"],
        "settings": state_captures["tuning-desk"],
        "victory": state_captures["success-recap"],
        "defeat": state_captures["recovery-recap"],
    }
    create_visual_contract(root, state_captures)

    asset_rows = {}
    for index, group in enumerate(ASSET_GROUPS, start=1):
        asset_id = f"{group}-fixture"
        asset_path = f"assets/generated/{group}/{asset_id}.png"
        provenance_path = f"assets/source-prompts/{asset_id}.md"
        write_png(root, asset_path, (30 * index, 40 + 20 * index, 220 - 20 * index))
        write(root, provenance_path, "Source: authored fixture; license and commercial rights verified.\n")
        surface_id = CLASSIC_STATES[index - 1]
        asset_rows[group] = {
            "id": asset_id,
            "status": "verified",
            "path": asset_path,
            "provenance": provenance_path,
            "runtime_refs": ["scenes/main.tscn"],
            "presentation": {
                "source_kind": "dedicated-component",
                "usages": [{
                    "id": f"{asset_id}-runtime",
                    "runtime_ref": "scenes/main.tscn",
                    "surface_ids": [surface_id],
                    "render_mode": "uniform",
                    "rendered_size": [160, 90],
                    "rationale": "Uniform fixture scaling preserves the authored aspect ratio in the declared state",
                    "evidence": [state_captures[surface_id]],
                }],
            },
        }
    write_json(
        root,
        "design/assets/asset-coverage.json",
        {
            "coverage_policy": {
                "minimum_distinct_assets": len(ASSET_GROUPS),
                "rationale": "One distinct integrated fixture artifact per declared visible-system group",
                "inventory_sources": ["design/gdd/game-concept.md", "design/ui/ui-ux-spec.md"],
            },
            "groups": [
                {
                    "id": group,
                    "required": True,
                    "status": "verified",
                    "coverage_basis": f"Fixture inventory for {group}",
                    "required_asset_ids": [asset_rows[group]["id"]],
                    "assets": [asset_rows[group]],
                    "evidence": [captures[state]],
                }
                for group, state in zip(ASSET_GROUPS, CLASSIC_STATES)
            ]
        },
    )

    write(
        root,
        "design/ui/ui-ux-spec.md",
        """# UI/UX Spec: Test Game
Status: Verified
Implementation mode: godot-theme
Minimal UI rationale: Not applicable; the fixture uses an authored Godot Theme.

Implementation resources:
- res://resources/ui/game-theme.tres

## Visual Language
Carved warm-metal frames, strong silhouettes, readable serif display type, and restrained amber focus light.

## Screen Inventory
| State ID | Player goal | Required components | Input modes | Evidence |
|---|---|---|---|---|
| launch-pad | Enter | Startup feedback | Keyboard and controller | launch-pad.png |
| front-door | Start | Identity and start action | Keyboard and controller | front-door.png |
| guided-first-step | Learn | Guidance and prompts | Keyboard and controller | guided-first-step.png |
| active-run | Act | HUD and contextual feedback | Keyboard and controller | active-run.png |
| interrupt-layer | Resume | Interruption actions | Keyboard and controller | interrupt-layer.png |
| tuning-desk | Configure | Preference controls | Keyboard and controller | tuning-desk.png |
| success-recap | Continue | Outcome summary | Keyboard and controller | success-recap.png |
| recovery-recap | Recover | Recovery action | Keyboard and controller | recovery-recap.png |

## HUD Hierarchy
Health and objective remain readable inside the title-safe area without covering the action.

## Component System
A shared Godot Theme owns panels, nine-slices, buttons, meters, focus rings, and typography tokens.

## Input And Focus
Input actions drive dynamic keyboard/controller prompts, explicit focus neighbors, and a visible non-color focus ring.

## Responsive Layout
The 1920x1080 reference scales through containers and anchors and is checked at 1280x720 and ultrawide.

## Accessibility
Text scale, remapping, non-color state cues, contrast, and reduced-motion behavior are verified.

## Motion And Feedback
Fast restrained transitions clarify state changes, with authored focus, pressed, invalid, and confirm feedback.

## Evidence
Runtime captures and full keyboard/controller navigation passed with no open high-severity findings.
""",
    )

    write(root, "resources/ui/game-theme.tres", '[gd_resource type="Theme" format=3]\n')

    audio_paths = []
    audio_events = []
    for index, event in enumerate(AUDIO_EVENTS):
        audio_path = f"assets/audio/{event}.wav"
        provenance_path = f"assets/audio/{event}.provenance.md"
        write_wav(root, audio_path, 220 + index * 37)
        write(root, provenance_path, "Source: authored fixture tone; license and commercial rights verified.\n")
        audio_paths.append(audio_path)
        audio_events.append({"id": event, "status": "verified", "asset": audio_path, "provenance": provenance_path, "trigger": f"signal:{event}"})
    write_json(
        root,
        "design/audio/audio-manifest.json",
        {
            "intentional_silence": False,
            "silence_rationale": "",
            "coverage_policy": {"minimum_distinct_assets": len(AUDIO_EVENTS), "rationale": "Distinct fixture audio for navigation, action, world bed, and outcome"},
            "required_buses": ["Master", "Feedback", "World"],
            "buses": ["Master", "Feedback", "World"],
            "coverage_requirements": [
                {"id": "interaction-feedback", "required": True, "rationale": "Player choices and actions need distinct confirmation", "event_ids": ["navigate-choice", "perform-action"]},
                {"id": "world-and-outcome", "required": True, "rationale": "The fixture needs a world bed and session outcome", "event_ids": ["world-bed", "session-outcome"]},
            ],
            "events": audio_events,
            "evidence": audio_paths + [captures["gameplay"]],
        },
    )

    write(root, "tests/test_core_loop.gd", "extends Node\n")
    write(
        root,
        "production/playtests/manual-core-loop.md",
        """# Manual Core Loop
Status: Verified
Tester: Fixture Tester
Build: fixture
## Results
Boot-to-replay journey completed with keyboard and controller.
## Media
Screenshot: {gameplay_path}
Media SHA-256: {gameplay_sha}
## Verdict
Gate: PASS
""".format(gameplay_path=captures["gameplay"], gameplay_sha=sha256_path(root / captures["gameplay"])),
    )
    write(root, "production/reviews/visual-quality.md", f"# Visual Review\nStatus: Verified\nBuild: fixture\nReviewer: Fixture Reviewer\nEvidence: {captures['gameplay']}\nEvidence SHA-256: {sha256_path(root / captures['gameplay'])}\nGate: PASS\n")
    write(root, "production/reviews/audio-listening.md", f"# Audio Review\nStatus: Verified\nBuild: fixture\nReviewer: Fixture Reviewer\nEvidence: assets/audio/world-bed.wav\nEvidence SHA-256: {sha256_path(root / 'assets/audio/world-bed.wav')}\nGate: PASS\n")
    write_json(
        root,
        "production/evidence/player-ready.json",
        {
            "checks": {check: "PASS" for check in EVIDENCE_CHECKS},
            "quality_report": "production/evidence/quality-run.json",
            "visual_contract": "production/reviews/visual-quality-contract.json",
            "visual_review": "production/reviews/visual-quality.md",
            "audio_review": "production/reviews/audio-listening.md",
            "artifacts": list(captures.values()) + audio_paths,
        },
    )
    write_json(
        root,
        "production/quality-command-manifest.json",
        {"version": 2, "godot_path": create_fake_godot(root), "commands": quality_commands(include_commercial_commands, visual_artifacts=tuple(sorted(set(state_captures.values()))))},
    )
    return captures


def convert_to_endless_sandbox_fixture(root: Path) -> dict[str, str]:
    state_ids = ("drop-in", "roaming-loop", "pack-overlay", "safe-exit")
    colors = ((32, 72, 108), (52, 132, 86), (126, 82, 152), (210, 150, 70))
    captures: dict[str, str] = {}
    for state_id, color in zip(state_ids, colors):
        relative = f"production/evidence/states/{state_id}.png"
        write_png(root, relative, color)
        captures[state_id] = relative
    transitions = {
        "drop-in": [{"to": "roaming-loop", "trigger": "world-ready"}],
        "roaming-loop": [{"to": "pack-overlay", "trigger": "open-pack"}, {"to": "safe-exit", "trigger": "save-and-leave"}],
        "pack-overlay": [{"to": "roaming-loop", "trigger": "close-pack"}],
        "safe-exit": [{"to": "drop-in", "trigger": "start-new-session"}],
    }
    evidence_checks = ["sandbox-session", "inventory-return", "intentional-session-exit", "manual-playtest"]
    write_json(root, "design/game-state-matrix.json", {
        "schema_version": 2,
        "release_profile": "endless-sandbox",
        "states": [
            {"id": state_id, "role": role, "required": True, "status": "verified", "ui_surface": True, "scene": "res://scenes/main.tscn", "evidence": [captures[state_id]], "transitions": transitions[state_id]}
            for state_id, role in zip(state_ids, ("session-entry", "open-ended-play", "diegetic-inventory", "save-and-exit"))
        ],
        "journeys": [{
            "id": "open-ended-session", "required": True, "goal": "Enter, roam, inspect inventory, save, and leave safely",
            "start_state": "drop-in", "required_states": list(state_ids), "completion_states": ["safe-exit"],
            "test_command_id": "sandbox_session",
            "recovery_paths": [{"from": "pack-overlay", "to": "roaming-loop", "required": True, "test_command_id": "inventory_return"}],
            "evidence": [captures["roaming-loop"], captures["safe-exit"]],
        }],
        "experience_requirements": [
            {"id": "nonterminal-session-exit", "required": True, "rationale": "The endless sandbox completes a session by saving and leaving, not by victory or defeat", "fulfilled_by": ["safe-exit"], "evidence": [captures["safe-exit"]]},
            {"id": "inventory-return", "required": True, "rationale": "The diegetic pack must return to uninterrupted roaming", "fulfilled_by": ["pack-overlay", "roaming-loop"], "evidence": [captures["pack-overlay"]]},
        ],
        "quality_requirements": [
            {"id": "engine-import", "kind": "engine_import", "required": True, "command_id": "godot_import"},
            {"id": "static-analysis", "kind": "static_analysis", "required": True, "command_id": "godot_lint"},
            {"id": "soak", "kind": "reliability", "required": True, "command_id": "long_run"},
        ],
        "required_evidence_checks": evidence_checks,
    })
    coverage_path = root / "design/assets/asset-coverage.json"
    coverage = json.loads(coverage_path.read_text(encoding="utf-8"))
    for group, state_id in zip(coverage["groups"], state_ids):
        for asset in group["assets"]:
            for usage in asset["presentation"]["usages"]:
                usage["surface_ids"] = [state_id]
                usage["evidence"] = [captures[state_id]]
        group["evidence"] = [captures[state_id]]
    write_json(root, "design/assets/asset-coverage.json", coverage)
    write(root, "scripts/ui/sandbox_overlay.gd", "extends Control\n# Custom-drawn diegetic pack overlay.\n")
    rows = "\n".join(
        f"| {state_id} | Verify {role} | Authored fixture surface | Keyboard and controller | {Path(captures[state_id]).name} |"
        for state_id, role in zip(state_ids, ("entry", "roaming", "pack", "save-exit"))
    )
    write(root, "design/ui/ui-ux-spec.md", f"""# UI/UX Spec: Endless Sandbox
Status: Verified
Implementation mode: custom-draw
Minimal UI rationale: The sandbox uses a diegetic custom-drawn pack instead of conventional menus.

Implementation resources:
- res://scripts/ui/sandbox_overlay.gd

## Visual Language
Diegetic field-journal marks and world-space prompts preserve the open landscape.

## Screen Inventory
| State ID | Player goal | Required components | Input modes | Evidence |
|---|---|---|---|---|
{rows}

## HUD Hierarchy
Only context-critical survival information appears during roaming.

## Component System
Custom draw tokens and a shared overlay script own all presentation.

## Input And Focus
Keyboard and controller bindings expose pack, close, save, and return behavior.

## Responsive Layout
Safe zones and world prompts were checked at target aspects.

## Accessibility
Text scaling, non-color prompts, reduced motion, and remapping are verified.

## Motion And Feedback
Transitions explain pack entry, return to roaming, and safe session exit.

## Evidence
All declared sandbox UI states have current runtime captures.
""")
    play_media = root / captures["roaming-loop"]
    write(root, "production/playtests/manual-core-loop.md", f"# Manual Sandbox Journey\nStatus: Verified\nTester: Fixture Tester\nBuild: fixture\n## Results\nOpen-ended session and safe exit completed.\n## Media\nScreenshot: {captures['roaming-loop']}\nMedia SHA-256: {sha256_path(play_media)}\n## Verdict\nGate: PASS\n")
    write(root, "production/reviews/visual-quality.md", f"# Visual Review\nStatus: Verified\nBuild: fixture\nReviewer: Fixture Reviewer\nEvidence: {captures['roaming-loop']}\nEvidence SHA-256: {sha256_path(play_media)}\nGate: PASS\n")
    write_json(root, "production/evidence/player-ready.json", {
        "checks": {check: "PASS" for check in evidence_checks},
        "quality_report": "production/evidence/quality-run.json",
        "visual_contract": "production/reviews/visual-quality-contract.json",
        "visual_review": "production/reviews/visual-quality.md",
        "audio_review": "production/reviews/audio-listening.md",
        "artifacts": list(captures.values()),
    })
    create_visual_contract(root, captures)
    write_json(root, "production/quality-command-manifest.json", {
        "version": 2,
        "godot_path": create_fake_godot(root),
        "commands": quality_commands(False, ("sandbox_session", "inventory_return"), tuple(sorted(set(captures.values())))),
    })
    return captures


def create_commercial_fixture(root: Path) -> None:
    captures = create_player_ready_fixture(root, include_commercial_commands=True)
    build_artifact = write(root, "build/web/game.pck", "release build artifact\n")
    build_hash = sha256_path(build_artifact)
    common_evidence = "production/evidence/commercial/check.md"
    write(root, common_evidence, "Verified by fixture owner on target build.\n")

    write_json(
        root,
        "production/commercial-release-contract.json",
        {
            "status": "approved",
            "release_id": "fixture-1.0.0",
            "release_type": "premium-launch",
            "version": "1.0.0",
            "build_commit": "fixture-commit",
            "engine": {"name": "Godot", "version": "4.7.1"},
            "target_platforms": ["web"],
            "stores": ["direct"],
            "release_locales": ["en"],
            "audience": {"minimum_age": 13, "children_targeted": False},
            "business_model": {"type": "premium", "price": 9.99, "iap": False, "ads": False, "dlc": False},
            "narrative_in_scope": False,
            "online_features": {"enabled": False, "services": [], "accounts": False, "chat": False, "ugc": False},
            "data_practices": {"collects_data": False, "third_party_sdks": []},
            "live_service": False,
            "external_approvals": [
                {"id": "release-owner", "owner": "Fixture Release Owner", "status": "approved", "decided_on": "2026-07-29", "evidence": [common_evidence]},
                {"id": "legal-owner", "owner": "Fixture Legal Owner", "status": "approved", "decided_on": "2026-07-29", "evidence": [common_evidence]},
                {"id": "commerce-owner", "owner": "Fixture Commerce Owner", "status": "approved", "decided_on": "2026-07-29", "evidence": [common_evidence]},
            ],
        },
    )
    write(root, "business/product-brief.md", "# Product Business Brief: Fixture\nStatus: Approved\nEvidence-backed premium scope approved.\n")
    write(root, "business/monetization-design.md", "# Monetization Design: Fixture\nStatus: Approved\nOne-time premium purchase; no IAP or ads.\n")
    write_json(
        root,
        "production/build-matrix.json",
        {
            "status": "verified",
            "targets": [{
                "id": "web", "platform": "web", "store": "direct", "status": "verified",
                "artifact": "build/web/game.pck", "sha256": build_hash,
                "build_command_id": "build_web", "smoke_command_id": "smoke_web",
                "official_requirements_source": "https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html",
                "requirements_verified_on": "2026-07-29", "devices": ["Safari macOS", "Chrome Windows"],
                "evidence": [common_evidence],
                "signing": {"required": False, "status": "not_applicable", "evidence": []},
                "store_review": {"required": False, "status": "not_applicable", "evidence": []},
            }],
        },
    )
    performance_evidence = "production/evidence/performance/web.json"
    write_json(root, performance_evidence, {"build_sha256": build_hash, "device": "Safari macOS fixture", "duration_seconds": 600, "verified": True})
    quality_manifest_path = root / "production/quality-command-manifest.json"
    quality_manifest = json.loads(quality_manifest_path.read_text(encoding="utf-8"))
    for command in quality_manifest["commands"]:
        if command["id"] == "build_web":
            command["expected_artifacts"] = ["build/web/game.pck"]
        if command["id"] == "performance_web":
            command["expected_artifacts"] = [performance_evidence]
    write_json(root, "production/quality-command-manifest.json", quality_manifest)

    write_json(
        root,
        "production/performance-budget.json",
        {
            "status": "verified",
            "targets": [{
                "id": "web", "status": "verified",
                "budgets": {"min_fps": 60, "max_frame_time_ms": 20, "max_memory_mb": 512, "max_startup_seconds": 5, "max_scene_load_seconds": 3, "max_memory_growth_mb": 32, "max_crashes": 0},
                "results": {"min_fps": 60, "max_frame_time_ms": 16.7, "max_memory_mb": 200, "max_startup_seconds": 2, "max_scene_load_seconds": 1, "max_memory_growth_mb": 2, "max_crashes": 0},
                "device": "Safari macOS fixture", "duration_seconds": 600, "build_sha256": build_hash,
                "measurement_command_id": "performance_web", "evidence": [performance_evidence],
            }],
        },
    )
    write_json(
        root,
        "production/compliance-manifest.json",
        {
            "status": "verified",
            "items": [
                {"id": item, "required": True, "status": "verified", "owner": "Fixture Owner", "source": "official/project audit", "rationale": "", "evidence": [common_evidence]}
                for item in COMPLIANCE_ITEMS
            ],
        },
    )
    write(root, "localization/en.csv", "id,text\nstart,Start\n")
    write_json(
        root,
        "design/localization/localization-manifest.json",
        {
            "status": "verified", "source_locale": "en", "release_locales": ["en"],
            "pseudo_localization": {"status": "verified", "evidence": [captures["settings"]]},
            "locales": [{"id": "en", "status": "verified", "catalog": "localization/en.csv", "font_coverage": "Latin complete", "linguistic_approval": "source", "evidence": [captures["settings"]]}],
        },
    )
    write_json(
        root,
        "design/accessibility/accessibility-conformance.json",
        {
            "status": "verified",
            "features": [{"id": item, "status": "verified", "rationale": "", "evidence": [common_evidence]} for item in ACCESSIBILITY_FEATURES],
        },
    )
    marketing_assets = []
    icon = write_png(root, "marketing/icon.png", (40, 80, 120), width=256, height=256)
    marketing_assets.append({"id": "icon", "type": "icon", "status": "verified", "path": str(icon.relative_to(root)), "evidence": [common_evidence]})
    for index, state in enumerate(("title", "gameplay", "victory"), start=1):
        marketing_assets.append({"id": f"screenshot-{index}", "type": "screenshot", "status": "verified", "path": captures[state], "evidence": [common_evidence]})
    write_json(
        root,
        "marketing/store-manifest.json",
        {
            "status": "verified", "positioning_approved": True,
            "targets": [{
                "id": "web", "platform": "web", "store": "direct", "status": "verified",
                "official_requirements_source": "https://example.com/official-requirements", "requirements_verified_on": "2026-07-29",
                "assets": marketing_assets, "claims": [],
            }],
        },
    )
    write(root, "production/liveops-plan.md", "# LiveOps And Support Plan: Fixture\nStatus: Approved\nRollback, support, and patch ownership verified.\n")
    write(root, "production/telemetry-crash-plan.md", "# Telemetry And Crash Plan: Fixture\nStatus: Approved\nTelemetry intentionally disabled and verified; manual crash support is owned.\n")


class PlayerReadyGateTests(unittest.TestCase):
    def test_empty_project_is_blocked(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            result, report = run_json(PLAYER_GATE, Path(temp_dir))
        self.assertEqual(result.returncode, 1)
        self.assertEqual(report["gate"], "BLOCKED")

    def test_complete_player_ready_fixture_passes(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            create_player_ready_fixture(root)
            run_quality(root, "player_ready")
            result, report = run_json(PLAYER_GATE, root)
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual(report["gate"], "PASS")

    def test_fake_png_is_blocked(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            captures = create_player_ready_fixture(root)
            run_quality(root, "player_ready")
            write(root, captures["title"], "not a png")
            result, report = run_json(PLAYER_GATE, root)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(report["gate"], "BLOCKED")
        self.assertTrue(any("media" in row["message"].lower() or "signature" in row["message"].lower() for row in report["blockers"]))

    def test_truncated_png_structure_is_blocked(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            captures = create_player_ready_fixture(root)
            run_quality(root, "player_ready")
            capture = root / captures["title"]
            capture.write_bytes(capture.read_bytes()[:-12])
            result, report = run_json(PLAYER_GATE, root)
        self.assertEqual(result.returncode, 1)
        self.assertTrue(any(row["code"].startswith("state.evidence") for row in report["blockers"]))

    def test_outside_project_evidence_is_blocked(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            parent = Path(temp_dir)
            root = parent / "game"
            root.mkdir()
            create_player_ready_fixture(root)
            write_png(parent, "outside.png", (1, 2, 3))
            matrix_path = root / "design/game-state-matrix.json"
            matrix = json.loads(matrix_path.read_text(encoding="utf-8"))
            next(row for row in matrix["states"] if row["id"] == "front-door")["evidence"] = ["../outside.png"]
            write_json(root, "design/game-state-matrix.json", matrix)
            run_quality(root, "player_ready")
            result, report = run_json(PLAYER_GATE, root)
        self.assertEqual(result.returncode, 1)
        self.assertTrue(any(row["code"].endswith("outside_root") for row in report["blockers"]))

    def test_endless_sandbox_without_conventional_state_names_passes(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            create_player_ready_fixture(root)
            convert_to_endless_sandbox_fixture(root)
            run_quality(root, "player_ready")
            result, report = run_json(PLAYER_GATE, root)
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual(report["gate"], "PASS")

    def test_start_and_completion_states_do_not_need_redundant_journey_entries(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            create_player_ready_fixture(root)
            matrix_path = root / "design/game-state-matrix.json"
            matrix = json.loads(matrix_path.read_text(encoding="utf-8"))
            journey = matrix["journeys"][0]
            journey["required_states"] = [
                state_id for state_id in journey["required_states"]
                if state_id not in {journey["start_state"], *journey["completion_states"]}
            ]
            write_json(root, "design/game-state-matrix.json", matrix)
            run_quality(root, "player_ready")
            result, report = run_json(PLAYER_GATE, root)
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual(report["gate"], "PASS")

    def test_required_state_needs_its_own_distinct_evidence(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            create_player_ready_fixture(root)
            matrix_path = root / "design/game-state-matrix.json"
            matrix = json.loads(matrix_path.read_text(encoding="utf-8"))
            launch = next(row for row in matrix["states"] if row["id"] == "launch-pad")
            front_door = next(row for row in matrix["states"] if row["id"] == "front-door")
            launch_evidence = launch["evidence"][0]
            launch["evidence"].append(front_door["evidence"][0])
            front_door["evidence"] = [launch_evidence]
            write_json(root, "design/game-state-matrix.json", matrix)
            run_quality(root, "player_ready")
            result, report = run_json(PLAYER_GATE, root)
        self.assertEqual(result.returncode, 1)
        self.assertTrue(any(row["code"] == "state.evidence_not_distinct" and row.get("state_id") == "front-door" for row in report["blockers"]))

    def test_recovery_source_must_be_reachable_from_its_journey(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            create_player_ready_fixture(root)
            orphan_capture = "production/evidence/states/orphan-recovery.png"
            write_png(root, orphan_capture, (17, 33, 61))
            matrix_path = root / "design/game-state-matrix.json"
            matrix = json.loads(matrix_path.read_text(encoding="utf-8"))
            matrix["states"].append({
                "id": "orphan-recovery",
                "role": "unreachable recovery fixture",
                "required": False,
                "status": "verified",
                "ui_surface": False,
                "scene": "res://scenes/main.tscn",
                "evidence": [orphan_capture],
                "transitions": [{"to": "active-run", "trigger": "recover"}],
            })
            matrix["journeys"][0]["recovery_paths"].append({
                "from": "orphan-recovery",
                "to": "active-run",
                "required": True,
                "test_command_id": "recovery_flow",
            })
            write_json(root, "design/game-state-matrix.json", matrix)
            run_quality(root, "player_ready")
            result, report = run_json(PLAYER_GATE, root)
        self.assertEqual(result.returncode, 1)
        self.assertTrue(any(row["code"] == "journey.recovery_unreachable" for row in report["blockers"]))

    def test_asset_floor_cannot_understate_declared_inventory(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            create_player_ready_fixture(root)
            coverage_path = root / "design/assets/asset-coverage.json"
            coverage = json.loads(coverage_path.read_text(encoding="utf-8"))
            coverage["coverage_policy"]["minimum_distinct_assets"] = 1
            write_json(root, "design/assets/asset-coverage.json", coverage)
            run_quality(root, "player_ready")
            result, report = run_json(PLAYER_GATE, root)
        self.assertEqual(result.returncode, 1)
        self.assertTrue(any(row["code"] == "assets.policy_below_inventory" for row in report["blockers"]))

    def test_asset_presentation_blocks_aspect_ratio_distortion(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            create_player_ready_fixture(root)
            coverage_path = root / "design/assets/asset-coverage.json"
            coverage = json.loads(coverage_path.read_text(encoding="utf-8"))
            coverage["groups"][0]["assets"][0]["presentation"]["usages"][0]["rendered_size"] = [160, 160]
            write_json(root, "design/assets/asset-coverage.json", coverage)
            run_quality(root, "player_ready")
            result, report = run_json(PLAYER_GATE, root)
        self.assertEqual(result.returncode, 1)
        self.assertTrue(any(row["code"] == "asset.presentation_distorted" for row in report["blockers"]))

    def test_unreachable_declared_state_is_blocked(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            create_player_ready_fixture(root)
            matrix_path = root / "design/game-state-matrix.json"
            matrix = json.loads(matrix_path.read_text(encoding="utf-8"))
            active = next(row for row in matrix["states"] if row["id"] == "active-run")
            active["transitions"] = [row for row in active["transitions"] if row["to"] != "success-recap"]
            write_json(root, "design/game-state-matrix.json", matrix)
            run_quality(root, "player_ready")
            result, report = run_json(PLAYER_GATE, root)
        self.assertEqual(result.returncode, 1)
        self.assertTrue(any(row["code"] == "journey.unreachable" for row in report["blockers"]))

    def test_legacy_fixed_state_dictionary_is_blocked(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            captures = create_player_ready_fixture(root)
            write_json(root, "design/game-state-matrix.json", {
                "release_profile": "legacy",
                "states": {
                    "title": {"status": "verified", "scene": "res://scenes/main.tscn", "evidence": [captures["title"]]},
                    "gameplay": {"status": "verified", "scene": "res://scenes/main.tscn", "evidence": [captures["gameplay"]]},
                    "victory": {"status": "verified", "scene": "res://scenes/main.tscn", "evidence": [captures["victory"]]},
                },
            })
            run_quality(root, "player_ready")
            result, report = run_json(PLAYER_GATE, root)
        self.assertEqual(result.returncode, 1)
        self.assertTrue(any(row["code"] == "states.schema" for row in report["blockers"]))

    def test_generated_lookdev_requires_candidate_comparison(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            create_player_ready_fixture(root)
            contract_path = root / "production/reviews/visual-quality-contract.json"
            contract = json.loads(contract_path.read_text(encoding="utf-8"))
            contract["lookdev"].update({
                "source_mode": "generated",
                "candidate_ids": ["cheap-first-pass"],
                "accepted_candidate_ids": ["cheap-first-pass"],
                "rejected_candidate_ids": [],
            })
            write_json(root, "production/reviews/visual-quality-contract.json", contract)
            run_quality(root, "player_ready")
            result, report = run_json(PLAYER_GATE, root)
        self.assertEqual(result.returncode, 1)
        self.assertTrue(any(row["code"] == "visual_contract.lookdev_candidates" for row in report["blockers"]))

    def test_visual_contract_blocks_unresolved_high_finding(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            create_player_ready_fixture(root)
            contract_path = root / "production/reviews/visual-quality-contract.json"
            contract = json.loads(contract_path.read_text(encoding="utf-8"))
            contract["surfaces"][0]["findings"] = [{
                "severity": "high",
                "status": "open",
                "finding": "Frame is stretched and text overlaps ornament",
            }]
            write_json(root, "production/reviews/visual-quality-contract.json", contract)
            run_quality(root, "player_ready")
            result, report = run_json(PLAYER_GATE, root)
        self.assertEqual(result.returncode, 1)
        self.assertTrue(any(row["code"] == "visual_contract.finding_open" for row in report["blockers"]))

    def test_visual_contract_rejects_production_self_review(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            create_player_ready_fixture(root)
            contract_path = root / "production/reviews/visual-quality-contract.json"
            contract = json.loads(contract_path.read_text(encoding="utf-8"))
            contract["reviewer_mode"] = "self-review"
            contract["reviewer_independence"] = "The production agent reviewed its own work"
            write_json(root, "production/reviews/visual-quality-contract.json", contract)
            run_quality(root, "player_ready")
            result, report = run_json(PLAYER_GATE, root)
        self.assertEqual(result.returncode, 1)
        self.assertTrue(any(row["code"] == "visual_contract.reviewer_not_independent" for row in report["blockers"]))

    def test_visual_capture_must_be_bound_to_quality_command(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            create_player_ready_fixture(root)
            manifest_path = root / "production/quality-command-manifest.json"
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            visual = next(row for row in manifest["commands"] if row["id"] == "visual_smoke")
            visual["expected_artifacts"] = visual["expected_artifacts"][1:]
            write_json(root, "production/quality-command-manifest.json", manifest)
            run_quality(root, "player_ready")
            result, report = run_json(PLAYER_GATE, root)
        self.assertEqual(result.returncode, 1)
        self.assertTrue(any(row["code"] == "quality.required_artifact_unbound" for row in report["blockers"]))

    def test_quality_runner_rejects_noop_command(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            create_player_ready_fixture(root)
            manifest_path = root / "production/quality-command-manifest.json"
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            for command in manifest["commands"]:
                if command["id"] == "godot_lint":
                    command["argv"] = ["echo", "PASS"]
            write_json(root, "production/quality-command-manifest.json", manifest)
            result = subprocess.run(
                [sys.executable, str(QUALITY_RUNNER), "--root", str(root), "--profile", "player_ready"],
                check=False,
                capture_output=True,
                text=True,
            )
            report = json.loads(result.stdout)
        self.assertEqual(result.returncode, 1)
        rejected = [row for row in report["results"] if row["id"] == "godot_lint"]
        self.assertEqual(rejected[0]["status"], "BLOCKED")

    def test_quality_runner_rejects_interpreter_eval_noop(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            create_player_ready_fixture(root)
            manifest_path = root / "production/quality-command-manifest.json"
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            for command in manifest["commands"]:
                if command["id"] == "godot_lint":
                    command["argv"] = [sys.executable, "-c", "print('PASS')"]
            write_json(root, "production/quality-command-manifest.json", manifest)
            result = subprocess.run(
                [sys.executable, str(QUALITY_RUNNER), "--root", str(root), "--profile", "player_ready"],
                check=False,
                capture_output=True,
                text=True,
            )
            report = json.loads(result.stdout)
        self.assertEqual(result.returncode, 1)
        rejected = [row for row in report["results"] if row["id"] == "godot_lint"]
        self.assertEqual(rejected[0]["status"], "BLOCKED")

    def test_commercial_engine_probe_mismatch_is_blocked(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            create_commercial_fixture(root)
            run_quality(root, "commercial_release")
            contract_path = root / "production/commercial-release-contract.json"
            contract = json.loads(contract_path.read_text(encoding="utf-8"))
            contract["engine"]["version"] = "4.6.1"
            write_json(root, "production/commercial-release-contract.json", contract)
            result, report = run_json(COMMERCIAL_GATE, root)
        self.assertEqual(result.returncode, 1)
        self.assertTrue(any(row["code"] == "godot.build_version_mismatch" for row in report["blockers"]))

    def test_complete_commercial_fixture_passes(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            create_commercial_fixture(root)
            run_quality(root, "commercial_release")
            result, report = run_json(COMMERCIAL_GATE, root)
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual(report["gate"], "PASS")

    def test_commercial_fixture_without_compliance_is_blocked(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            create_commercial_fixture(root)
            (root / "production/compliance-manifest.json").unlink()
            run_quality(root, "commercial_release")
            result, report = run_json(COMMERCIAL_GATE, root)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(report["gate"], "BLOCKED")
        self.assertTrue(any(row["code"].startswith("compliance") for row in report["blockers"]))

    def test_commercial_fixture_without_required_owner_approval_is_blocked(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            create_commercial_fixture(root)
            contract_path = root / "production/commercial-release-contract.json"
            contract = json.loads(contract_path.read_text(encoding="utf-8"))
            contract["external_approvals"] = [row for row in contract["external_approvals"] if row["id"] != "release-owner"]
            write_json(root, "production/commercial-release-contract.json", contract)
            run_quality(root, "commercial_release")
            result, report = run_json(COMMERCIAL_GATE, root)
        self.assertEqual(result.returncode, 1)
        self.assertTrue(any(row["code"] == "approval.required_missing" for row in report["blockers"]))

    def test_commercial_build_command_must_bind_current_artifact(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            create_commercial_fixture(root)
            manifest_path = root / "production/quality-command-manifest.json"
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            for command in manifest["commands"]:
                if command["id"] == "build_web":
                    command["expected_artifacts"] = []
            write_json(root, "production/quality-command-manifest.json", manifest)
            run_quality(root, "commercial_release")
            result, report = run_json(COMMERCIAL_GATE, root)
        self.assertEqual(result.returncode, 1)
        self.assertTrue(any(row["code"] == "build.command_artifact_unbound" for row in report["blockers"]))


if __name__ == "__main__":
    unittest.main()
