"""Regression tests for the sealed style contract in asset workflows."""

from __future__ import annotations

import json
import os
import struct
import subprocess
import sys
import tempfile
import unittest
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / "plugins/codex-game-maker/scripts/assets/cgs_asset_workflows.py"
STYLE_LOCK = ROOT / "plugins/codex-game-maker/scripts/style_lock.py"


def write_png(path: Path, color: tuple[int, int, int], width: int = 320, height: int = 180) -> None:
    """Write a small valid RGB PNG without adding a test-only image dependency."""
    path.parent.mkdir(parents=True, exist_ok=True)
    scanline = b"\x00" + bytes(color) * width
    raw = scanline * height

    def chunk(kind: bytes, payload: bytes) -> bytes:
        return (
            struct.pack(">I", len(payload))
            + kind
            + payload
            + struct.pack(">I", zlib.crc32(kind + payload) & 0xFFFFFFFF)
        )

    data = b"\x89PNG\r\n\x1a\n"
    data += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
    data += chunk(b"IDAT", zlib.compress(raw, 9))
    data += chunk(b"IEND", b"")
    path.write_bytes(data)


def run_json(command: list[str]) -> tuple[subprocess.CompletedProcess[str], dict]:
    completed = subprocess.run(
        command,
        cwd=ROOT,
        capture_output=True,
        text=True,
        env=os.environ.copy(),
    )
    payload = (completed.stdout or completed.stderr).strip()
    try:
        report = json.loads(payload)
    except json.JSONDecodeError as exc:  # pragma: no cover - useful failure context
        raise AssertionError(f"Expected JSON output, got:\n{payload}") from exc
    return completed, report


class AssetWorkflowStyleTests(unittest.TestCase):
    def seal_style_lock(self, root: Path) -> dict:
        (root / "design/art").mkdir(parents=True, exist_ok=True)
        (root / "design/art/art-bible.md").write_text(
            "# Art Bible\nStatus: Locked\nA blue-amber carved fox identity.\n",
            encoding="utf-8",
        )
        write_png(root / "assets/references/look.png", (24, 48, 96))
        lock = {
            "schema_version": 1,
            "style_id": "fixture-style",
            "style_version": "1.0.0",
            "status": "planned",
            "source_art_bible": "design/art/art-bible.md",
            "art_bible_sha256": "",
            "digest": "",
            "identity_rule": "Blue-amber carved fox silhouettes with restrained focus light",
            "anchors": {
                "materials": ["carved wood", "matte cloth"],
                "shape_language": ["angular ears", "clean silhouettes"],
                "camera_and_view": ["side orthographic"],
                "lighting": ["warm upper-left key"],
                "palette_roles": ["blue world", "amber focus"],
                "typography_roles": ["display serif"],
                "detail_density": ["medium focal, quiet background"],
                "motion_and_fx": ["restrained arcs"],
            },
            "forbidden_drift": ["plastic bevels", "generic dashboard"],
            "approved_families": ["world", "actors", "ui"],
            "locked_references": [{
                "path": "assets/references/look.png",
                "sha256": "",
                "families": ["world", "actors", "ui"],
            }],
            "change_control": {
                "previous_digest": "",
                "change_reason": "Initial lock",
                "approved_by": "Art Owner",
                "approved_on": "",
            },
        }
        path = root / "design/art/style-lock.json"
        path.write_text(json.dumps(lock), encoding="utf-8")
        completed, report = run_json([
            sys.executable,
            str(STYLE_LOCK),
            "seal",
            "--root",
            str(root),
            "--approved-by",
            "Art Owner",
            "--reason",
            "Initial lock",
        ])
        self.assertEqual(completed.returncode, 0, report)
        return json.loads(path.read_text(encoding="utf-8"))

    def run_bundle(self, root: Path, *extra: str) -> tuple[subprocess.CompletedProcess[str], dict]:
        return run_json([
            sys.executable,
            str(WORKFLOW),
            "action-bundle",
            "--root",
            str(root),
            "--asset-id",
            "hero",
            "--description",
            "blue fox hero",
            "--actions",
            "idle",
            "--cell-width",
            "64",
            "--cell-height",
            "64",
            "--jump-cell-height",
            "64",
            "--safe-margin",
            "8",
            *extra,
        ])

    def test_lookdev_can_plan_without_a_lock_but_does_not_generate_runtime_art(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / "design/art").mkdir(parents=True)
            (root / "design/art/art-bible.md").write_text("# Draft\n", encoding="utf-8")
            completed, report = self.run_bundle(root, "--lookdev")
            self.assertEqual(completed.returncode, 0, report)
            self.assertEqual(report["planned"], ["hero-idle"])
            prompt = (root / "assets/source-prompts/hero-idle.yaml").read_text(encoding="utf-8")
            self.assertIn("style_version: lookdev", prompt)
            self.assertIn("style_lock_sha256: unlocked-lookdev", prompt)
            self.assertFalse(any(path.is_file() for path in (root / "assets/raw").rglob("*")))
            self.assertFalse(any(path.is_file() for path in (root / "assets/generated").rglob("*")))

    def test_production_requires_a_sealed_lock(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            completed, report = self.run_bundle(root)
            self.assertEqual(completed.returncode, 1)
            self.assertIn("Missing design/art/style-lock.json", report["error"])
            self.assertFalse((root / "assets/source-prompts").exists())

    def test_valid_sealed_lock_reaches_planning_and_binds_prompt(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            lock = self.seal_style_lock(root)
            completed, report = self.run_bundle(root, "--reference-file", "assets/references/look.png")
            self.assertEqual(completed.returncode, 0, report)
            self.assertEqual(report["planned"], ["hero-idle"])
            prompt = (root / "assets/source-prompts/hero-idle.yaml").read_text(encoding="utf-8")
            self.assertIn(f"style_version: {lock['style_version']}", prompt)
            self.assertIn(f"style_lock_sha256: {lock['digest']}", prompt)
            self.assertIn("assets/references/look.png", prompt)
            bundle = (root / "design/assets/action-bundles/hero.yaml").read_text(encoding="utf-8")
            self.assertIn(f"style_lock_sha256: \"{lock['digest']}\"", bundle)
            manifest = (root / "design/assets/asset-manifest.yaml").read_text(encoding="utf-8")
            self.assertIn(f"sha256: \"{lock['digest']}\"", manifest)
            self.assertFalse(any(path.is_file() for path in (root / "assets/raw").rglob("*")))
            self.assertFalse(any(path.is_file() for path in (root / "assets/generated").rglob("*")))

    def test_stale_lock_and_unapproved_reference_are_blocked(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            self.seal_style_lock(root)
            (root / "design/art/art-bible.md").write_text("changed", encoding="utf-8")
            completed, report = self.run_bundle(root)
            self.assertEqual(completed.returncode, 1)
            self.assertIn("art_bible_sha256 is missing or stale", report["error"])

        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            self.seal_style_lock(root)
            write_png(root / "assets/references/unapproved.png", (90, 30, 10))
            completed, report = self.run_bundle(root, "--reference-file", "assets/references/unapproved.png")
            self.assertEqual(completed.returncode, 1)
            self.assertIn("must be sealed for the asset's visual family", report["error"])

    def test_production_reference_must_match_asset_family(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            self.seal_style_lock(root)
            path = root / "design/art/style-lock.json"
            lock = json.loads(path.read_text(encoding="utf-8"))
            lock["locked_references"][0]["families"] = ["ui"]
            path.write_text(json.dumps(lock), encoding="utf-8")
            completed, report = run_json([
                sys.executable, str(STYLE_LOCK), "seal", "--root", str(root),
                "--version", "1.0.1", "--approved-by", "Art Owner", "--reason", "UI-only reference",
            ])
            self.assertEqual(completed.returncode, 0, report)
            completed, report = self.run_bundle(root)
        self.assertEqual(completed.returncode, 1)
        self.assertIn("no reference for asset family/category", report["error"])

    def test_locked_reference_must_be_a_real_image(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            self.seal_style_lock(root)
            reference = root / "assets/references/look.png"
            reference.write_bytes(b"not an image")
            path = root / "design/art/style-lock.json"
            lock = json.loads(path.read_text(encoding="utf-8"))
            path.write_text(json.dumps(lock), encoding="utf-8")
            completed, report = run_json([
                sys.executable, str(STYLE_LOCK), "seal", "--root", str(root),
                "--version", "1.0.1", "--approved-by", "Art Owner", "--reason", "Invalid reference fixture",
            ])
        self.assertEqual(completed.returncode, 1)
        self.assertTrue(any("not a valid 320x180+ image" in error for error in report["errors"]))


if __name__ == "__main__":
    unittest.main()
