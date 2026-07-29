import importlib.util
import json
import tempfile
import unittest
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "plugins/codex-game-maker/scripts/install_godot.py"
SPEC = importlib.util.spec_from_file_location("cgm_install_godot", SCRIPT)
assert SPEC and SPEC.loader
INSTALLER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(INSTALLER)


class InstallGodotTests(unittest.TestCase):
    def test_safe_extract_rejects_parent_traversal(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            archive = root / "unsafe.zip"
            with zipfile.ZipFile(archive, "w") as bundle:
                bundle.writestr("../escaped.txt", "unsafe")
            with zipfile.ZipFile(archive) as bundle:
                with self.assertRaises(RuntimeError):
                    INSTALLER.safe_extract(bundle, root / "out")
            self.assertFalse((root / "escaped.txt").exists())

    def test_existing_install_requires_matching_executable_hash(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            executable = Path(temp) / "Godot"
            executable.write_bytes(b"verified executable")
            profile = {"platform": "linux", "filename": "godot.zip"}
            manifest = {
                "version": "4.6.2",
                "status": "stable",
                "platform": "linux",
                "filename": "godot.zip",
                "expected_sha512": "a" * 128,
                "executable": str(executable),
                "executable_sha256": INSTALLER.sha256_file(executable),
            }
            self.assertEqual(
                INSTALLER.existing_install_error(
                    manifest,
                    version="4.6.2",
                    status="stable",
                    profile=profile,
                    expected_sha512="a" * 128,
                    executable=executable,
                ),
                "",
            )
            executable.write_bytes(b"tampered executable")
            self.assertIn(
                "hash",
                INSTALLER.existing_install_error(
                    manifest,
                    version="4.6.2",
                    status="stable",
                    profile=profile,
                    expected_sha512="a" * 128,
                    executable=executable,
                ),
            )

    def test_existing_templates_require_trusted_marker(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            target = root / "4.6.2.stable"
            target.mkdir(parents=True)
            web = target / "web_release.zip"
            web.write_bytes(b"web template")
            original = INSTALLER.template_root
            INSTALLER.template_root = lambda: root
            policy = {
                "verified_archives": {
                    "4.6.2-stable": {
                        "files": {
                            "Godot_v4.6.2-stable_export_templates.tpz": "b" * 128,
                        }
                    }
                }
            }
            try:
                with self.assertRaises(RuntimeError):
                    INSTALLER.install_templates("4.6.2", "stable", root, False, policy)
                marker = {
                    "schema_version": 1,
                    "version": "4.6.2",
                    "status": "stable",
                    "archive_filename": "Godot_v4.6.2-stable_export_templates.tpz",
                    "archive_sha512": "b" * 128,
                    "web_release_sha256": INSTALLER.sha256_file(web),
                }
                (target / ".codex-game-maker-install.json").write_text(
                    json.dumps(marker), encoding="utf-8"
                )
                result = INSTALLER.install_templates("4.6.2", "stable", root, False, policy)
            finally:
                INSTALLER.template_root = original
            self.assertEqual(result["status"], "existing")


if __name__ == "__main__":
    unittest.main()
