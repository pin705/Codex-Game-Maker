import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
GATE = REPO_ROOT / "plugins/codex-game-maker/scripts/guards/player_ready_gate.py"
STATES = ("boot", "title", "gameplay", "pause", "settings", "victory", "defeat")
ASSET_GROUPS = ("player", "environment", "gameplay-feedback", "ui", "release-branding")
AUDIO_EVENTS = ("ui-confirm", "ui-back", "player-action", "damage-or-failure", "reward", "victory", "defeat")
EVIDENCE_CHECKS = ("core_loop", "long_run", "visual_quality", "controls", "ui_states", "audio", "manual_playtest")


def write(root: Path, relative: str, content: str = "verified\n") -> Path:
    path = root / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    return path


def write_json(root: Path, relative: str, value: dict) -> Path:
    return write(root, relative, json.dumps(value, indent=2))


def run_gate(root: Path) -> tuple[subprocess.CompletedProcess, dict]:
    result = subprocess.run(
        [sys.executable, str(GATE), "--root", str(root)],
        check=False,
        capture_output=True,
        text=True,
    )
    return result, json.loads(result.stdout)


def create_complete_fixture(root: Path) -> None:
    write(root, "scenes/main.tscn", "[gd_scene format=3]\n")
    write(root, "project.godot", '[application]\nrun/main_scene="res://scenes/main.tscn"\n')
    write(root, "design/gdd/game-concept.md")
    write(root, "design/art/art-bible.md")
    write(root, "docs/architecture/architecture.md")
    write(root, "docs/architecture/control-manifest.md")
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

    capture = "production/evidence/runtime.png"
    write(root, capture, "image evidence")
    write_json(
        root,
        "design/game-state-matrix.json",
        {
            "release_profile": "web-demo",
            "states": {
                state: {"status": "verified", "scene": "res://scenes/main.tscn", "evidence": [capture]}
                for state in STATES
            },
        },
    )

    asset_path = "assets/generated/fixture.png"
    write(root, asset_path, "asset")
    write_json(
        root,
        "design/assets/asset-coverage.json",
        {
            "groups": [
                {
                    "id": group,
                    "required": True,
                    "status": "verified",
                    "assets": [{"id": f"{group}-fixture", "status": "verified", "path": asset_path}],
                    "evidence": [capture],
                }
                for group in ASSET_GROUPS
            ]
        },
    )

    write(
        root,
        "design/ui/ui-ux-spec.md",
        """# UI/UX Spec: Test Game
Status: Verified

## Visual Language
Carved warm-metal frames, strong silhouettes, readable serif display type, and restrained amber focus light.

## Screen Inventory
| State | Player goal | Required components | Input modes | Evidence |
|---|---|---|---|---|
| Title | Start | Logo and start action | Keyboard and controller | runtime.png |
| Gameplay | Act | HUD and prompts | Keyboard and controller | runtime.png |
| Pause | Resume | Pause actions | Keyboard and controller | runtime.png |
| Settings | Configure | Sliders and remapping | Keyboard and controller | runtime.png |
| Victory | Replay | Results and replay | Keyboard and controller | runtime.png |
| Defeat | Retry | Result and retry | Keyboard and controller | runtime.png |

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
Runtime capture and full keyboard/controller navigation pass are recorded with no open high-severity findings.
""",
    )

    audio_path = "assets/audio/fixture.wav"
    write(root, audio_path, "audio")
    write_json(
        root,
        "design/audio/audio-manifest.json",
        {
            "intentional_silence": False,
            "silence_rationale": "",
            "buses": ["Master", "Music", "SFX", "UI", "Ambience"],
            "events": [
                {"id": event, "status": "verified", "asset": audio_path, "trigger": f"signal:{event}"}
                for event in AUDIO_EVENTS
            ],
            "evidence": [capture],
        },
    )

    write(root, "tests/test_core_loop.gd", "extends Node\n")
    write(root, "production/playtests/manual-core-loop.md", "Manual boot-to-replay journey: PASS\n")
    write_json(
        root,
        "production/evidence/player-ready.json",
        {"checks": {check: "PASS" for check in EVIDENCE_CHECKS}, "artifacts": [capture]},
    )


class PlayerReadyGateTests(unittest.TestCase):
    def test_empty_project_is_blocked(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            result, report = run_gate(Path(temp_dir))

        self.assertEqual(result.returncode, 1)
        self.assertEqual(report["gate"], "BLOCKED")
        self.assertTrue(report["blockers"])

    def test_complete_fixture_passes(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            create_complete_fixture(root)
            result, report = run_gate(root)

        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual(report["gate"], "PASS")
        self.assertEqual(report["blockers"], [])


if __name__ == "__main__":
    unittest.main()
