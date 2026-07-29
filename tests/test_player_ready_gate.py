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


STATES = ("boot", "title", "onboarding", "gameplay", "pause", "settings", "victory", "defeat")
ASSET_GROUPS = ("player", "environment", "gameplay-feedback", "ui", "release-branding")
AUDIO_EVENTS = ("ui-confirm", "ui-back", "ui-focus", "ui-invalid", "player-action", "damage-or-failure", "reward", "victory", "defeat", "music-main", "ambience-gameplay")
EVIDENCE_CHECKS = ("core_loop", "long_run", "visual_quality", "controls", "ui_states", "audio", "manual_playtest")
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


def quality_commands(include_commercial: bool = False) -> list[dict]:
    command_ids = ["godot_import", "godot_lint", "core_loop", "long_run"]
    if include_commercial:
        command_ids.extend(["build_web", "smoke_web", "performance_web"])
    return [
        {
            "id": command_id,
            "argv": (["{godot}", "--headless", "--editor", "--quit"] if command_id == "godot_import" else [sys.executable, "-c", f"print('{command_id}: PASS')"]),
            "cwd": ".",
            "timeout_seconds": 30,
            "required_for": ["player_ready", "commercial_release"] if command_id in {"godot_import", "godot_lint", "core_loop", "long_run"} else ["commercial_release"],
            "expected_artifacts": [],
        }
        for command_id in command_ids
    ]


def create_player_ready_fixture(root: Path, include_commercial_commands: bool = False) -> dict[str, str]:
    write(root, "scenes/main.tscn", "[gd_scene format=3]\n")
    write(root, "project.godot", '[application]\nrun/main_scene="res://scenes/main.tscn"\n[application]\nconfig/features=PackedStringArray("4.7")\n')
    write(root, "design/gdd/game-concept.md", "# Game Concept: Fixture\nStatus: Verified\nCore loop, audience, pillars, scope, and player journey verified.\n")
    write(root, "design/art/art-bible.md", "# Art Bible: Fixture\nStatus: Verified\nAuthored silhouettes, palette, typography, UI materials, motion, and asset rules verified.\n")
    write(root, "docs/architecture/architecture.md", "# Architecture: Fixture\nStatus: Verified\nGodot scene, data, signals, saves, testing, and export boundaries verified.\n")
    write(root, "docs/architecture/control-manifest.md", "# Control Manifest: Fixture\nStatus: Verified\nKeyboard, controller, focus, remapping, pause, restart, and prompt bindings verified.\n")
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

    captures: dict[str, str] = {}
    colors = ((200, 20, 20), (20, 200, 20), (100, 180, 240), (20, 20, 200), (200, 200, 20), (200, 20, 200), (20, 200, 200), (120, 80, 220))
    for state, color in zip(STATES, colors):
        relative = f"production/evidence/states/{state}.png"
        write_png(root, relative, color)
        captures[state] = relative
    write_json(
        root,
        "design/game-state-matrix.json",
        {
            "release_profile": "web-demo",
            "states": {
                state: {"status": "verified", "scene": "res://scenes/main.tscn", "evidence": [captures[state]]}
                for state in STATES
            },
        },
    )

    asset_rows = {}
    for index, group in enumerate(ASSET_GROUPS, start=1):
        asset_id = f"{group}-fixture"
        asset_path = f"assets/generated/{group}/{asset_id}.png"
        provenance_path = f"assets/source-prompts/{asset_id}.md"
        write_png(root, asset_path, (30 * index, 40 + 20 * index, 220 - 20 * index))
        write(root, provenance_path, "Source: authored fixture; license and commercial rights verified.\n")
        asset_rows[group] = {"id": asset_id, "status": "verified", "path": asset_path, "provenance": provenance_path, "runtime_refs": ["scenes/main.tscn"]}
    write_json(
        root,
        "design/assets/asset-coverage.json",
        {
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
                for group, state in zip(ASSET_GROUPS, STATES)
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
| Title | Start | Logo and start action | Keyboard and controller | title.png |
| Gameplay | Act | HUD and prompts | Keyboard and controller | gameplay.png |
| Pause | Resume | Pause actions | Keyboard and controller | pause.png |
| Settings | Configure | Sliders and remapping | Keyboard and controller | settings.png |
| Victory | Replay | Results and replay | Keyboard and controller | victory.png |
| Defeat | Retry | Result and retry | Keyboard and controller | defeat.png |

## HUD Hierarchy
Health and objective remain readable inside the title-safe area without covering the action.

## Component System
A shared Godot Theme owns panels, nine-slices, buttons, meters, focus rings, and typography tokens.
Theme resource: res://resources/ui/game-theme.tres

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
        write_wav(root, audio_path, 220 + index * 37)
        audio_paths.append(audio_path)
        audio_events.append({"id": event, "status": "verified", "asset": audio_path, "trigger": f"signal:{event}"})
    write_json(
        root,
        "design/audio/audio-manifest.json",
        {
            "intentional_silence": False,
            "silence_rationale": "",
            "buses": ["Master", "Music", "SFX", "UI", "Ambience"],
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
Screenshot: production/evidence/states/gameplay.png
Media SHA-256: {gameplay_sha}
## Verdict
Gate: PASS
""".format(gameplay_sha=sha256_path(root / captures["gameplay"])),
    )
    write(root, "production/reviews/visual-quality.md", f"# Visual Review\nStatus: Verified\nBuild: fixture\nReviewer: Fixture Reviewer\nEvidence: production/evidence/states/gameplay.png\nEvidence SHA-256: {sha256_path(root / captures['gameplay'])}\nGate: PASS\n")
    write(root, "production/reviews/audio-listening.md", f"# Audio Review\nStatus: Verified\nBuild: fixture\nReviewer: Fixture Reviewer\nEvidence: assets/audio/music-main.wav\nEvidence SHA-256: {sha256_path(root / 'assets/audio/music-main.wav')}\nGate: PASS\n")
    write_json(
        root,
        "production/evidence/player-ready.json",
        {
            "checks": {check: "PASS" for check in EVIDENCE_CHECKS},
            "quality_report": "production/evidence/quality-run.json",
            "visual_review": "production/reviews/visual-quality.md",
            "audio_review": "production/reviews/audio-listening.md",
            "artifacts": list(captures.values()) + audio_paths,
        },
    )
    write_json(
        root,
        "production/quality-command-manifest.json",
        {"version": 2, "godot_path": create_fake_godot(root), "commands": quality_commands(include_commercial_commands)},
    )
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
            matrix["states"]["title"]["evidence"] = ["../outside.png"]
            write_json(root, "design/game-state-matrix.json", matrix)
            run_quality(root, "player_ready")
            result, report = run_json(PLAYER_GATE, root)
        self.assertEqual(result.returncode, 1)
        self.assertTrue(any(row["code"].endswith("outside_root") for row in report["blockers"]))

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
