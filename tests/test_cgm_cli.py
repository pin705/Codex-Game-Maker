import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CGM = ROOT / "plugins/codex-game-maker/scripts/cgm.py"


class CgmCliTests(unittest.TestCase):
    def test_doctor_reports_plugin_and_project(self) -> None:
        fixture = ROOT / "tests/fixtures/godot-smoke"
        result = subprocess.run(
            [sys.executable, str(CGM), "doctor", "--root", str(fixture), "--require-project"],
            capture_output=True,
            text=True,
        )
        report = json.loads(result.stdout)
        self.assertEqual(result.returncode, 0, report)
        self.assertEqual(report["checks"]["plugin_version"], "1.0.0")
        self.assertTrue(report["checks"]["project_godot"])

    def test_doctor_can_require_a_project(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            result = subprocess.run(
                [sys.executable, str(CGM), "doctor", "--root", temp, "--require-project"],
                capture_output=True,
                text=True,
            )
            report = json.loads(result.stdout)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(report["gate"], "BLOCKED")
        self.assertTrue(any("project.godot" in blocker for blocker in report["blockers"]))

    def test_install_dry_run_uses_verified_stable_policy(self) -> None:
        result = subprocess.run(
            [sys.executable, str(CGM), "install-godot", "--dry-run"],
            capture_output=True,
            text=True,
        )
        report = json.loads(result.stdout)
        self.assertEqual(result.returncode, 0, report)
        self.assertEqual(report["version"], "4.6.2")
        self.assertEqual(len(report["expected_sha512"]), 128)


if __name__ == "__main__":
    unittest.main()
