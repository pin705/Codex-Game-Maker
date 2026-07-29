import json
import struct
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
import zlib


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "plugins/codex-game-maker/scripts/style_lock.py"


class StyleLockToolTests(unittest.TestCase):
    def fixture(self, root: Path) -> Path:
        art = root / "design/art/art-bible.md"
        art.parent.mkdir(parents=True)
        art.write_text("# Art Bible\nStatus: Locked\nA specific visual identity.\n", encoding="utf-8")
        reference = root / "assets/references/look.png"
        reference.parent.mkdir(parents=True)
        scanline = b"\x00" + bytes((24, 48, 96)) * 320
        raw = scanline * 180
        def chunk(kind: bytes, payload: bytes) -> bytes:
            return struct.pack(">I", len(payload)) + kind + payload + struct.pack(">I", zlib.crc32(kind + payload) & 0xFFFFFFFF)
        reference.write_bytes(
            b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", struct.pack(">IIBBBBB", 320, 180, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw, 9))
            + chunk(b"IEND", b"")
        )
        lock = {
            "schema_version": 1,
            "style_id": "fixture-style",
            "style_version": "1.0.0",
            "status": "planned",
            "source_art_bible": "design/art/art-bible.md",
            "art_bible_sha256": "",
            "digest": "",
            "identity_rule": "A specific authored fixture visual identity",
            "anchors": {
                "materials": ["paper"], "shape_language": ["angled"], "camera_and_view": ["side"],
                "lighting": ["upper-left"], "palette_roles": ["amber focus"], "typography_roles": ["display"],
                "detail_density": ["quiet world"], "motion_and_fx": ["restrained"],
            },
            "forbidden_drift": ["plastic", "dashboard"],
            "approved_families": ["world", "ui"],
            "locked_references": [{"path": "assets/references/look.png", "sha256": "", "families": ["world", "ui"]}],
            "change_control": {"previous_digest": "", "change_reason": "", "approved_by": "", "approved_on": ""},
        }
        path = root / "design/art/style-lock.json"
        path.write_text(json.dumps(lock), encoding="utf-8")
        return path

    def test_seal_then_verify(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            self.fixture(root)
            seal = subprocess.run([sys.executable, str(SCRIPT), "seal", "--root", str(root), "--approved-by", "Art Owner", "--reason", "Initial lock"], capture_output=True, text=True)
            verify = subprocess.run([sys.executable, str(SCRIPT), "verify", "--root", str(root)], capture_output=True, text=True)
        self.assertEqual(seal.returncode, 0, seal.stdout + seal.stderr)
        self.assertEqual(verify.returncode, 0, verify.stdout + verify.stderr)

    def test_verify_blocks_stale_art_bible(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            self.fixture(root)
            subprocess.run([sys.executable, str(SCRIPT), "seal", "--root", str(root), "--approved-by", "Art Owner", "--reason", "Initial lock"], check=True, capture_output=True)
            (root / "design/art/art-bible.md").write_text("changed", encoding="utf-8")
            verify = subprocess.run([sys.executable, str(SCRIPT), "verify", "--root", str(root)], capture_output=True, text=True)
            report = json.loads(verify.stdout)
        self.assertEqual(verify.returncode, 1)
        self.assertIn("art_bible_sha256 is stale", report["errors"])

    def test_seal_rejects_invalid_style_version_without_writing(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            path = self.fixture(root)
            before = path.read_text(encoding="utf-8")
            seal = subprocess.run(
                [sys.executable, str(SCRIPT), "seal", "--root", str(root), "--version", "latest", "--approved-by", "Art Owner", "--reason", "Initial lock"],
                capture_output=True,
                text=True,
            )
            report = json.loads(seal.stdout)
            after = path.read_text(encoding="utf-8")
        self.assertEqual(seal.returncode, 1)
        self.assertIn("style_version must be x.y.z", report["errors"])
        self.assertEqual(before, after)

    def test_seal_rejects_reference_outside_project(self) -> None:
        with tempfile.TemporaryDirectory() as temp, tempfile.TemporaryDirectory() as outside:
            root = Path(temp)
            path = self.fixture(root)
            data = json.loads(path.read_text(encoding="utf-8"))
            external = Path(outside) / "look.png"
            external.write_bytes(b"external")
            data["locked_references"] = [{"path": str(external), "sha256": "", "families": ["world"]}]
            path.write_text(json.dumps(data), encoding="utf-8")
            seal = subprocess.run(
                [sys.executable, str(SCRIPT), "seal", "--root", str(root), "--approved-by", "Art Owner", "--reason", "Initial lock"],
                capture_output=True,
                text=True,
            )
            report = json.loads(seal.stdout)
        self.assertEqual(seal.returncode, 1)
        self.assertTrue(any("project-relative" in error for error in report["errors"]))


if __name__ == "__main__":
    unittest.main()
