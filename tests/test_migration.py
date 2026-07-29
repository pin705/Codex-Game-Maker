import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "plugins/codex-game-maker/scripts/migrate_project.py"


class MigrationTests(unittest.TestCase):
    def test_dry_run_does_not_write_and_reports_legacy_graph(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            path = root / "design/game-state-matrix.json"
            path.parent.mkdir(parents=True)
            path.write_text(json.dumps({"schema_version": 1, "states": {"old": {"status": "verified"}}}), encoding="utf-8")
            result = subprocess.run([sys.executable, str(SCRIPT), "--root", str(root), "--dry-run"], capture_output=True, text=True)
            report = json.loads(result.stdout)
            self.assertEqual(result.returncode, 1)
            self.assertTrue(report["dry_run"])
            self.assertFalse((root / "design/art/style-lock.json").exists())
            self.assertTrue(any("legacy state" in item for item in report["blockers"]))

    def test_migration_creates_backup_and_report(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            path = root / "design/game-state-matrix.json"
            path.parent.mkdir(parents=True)
            path.write_text(json.dumps({"schema_version": 1, "states": {"old": {"status": "verified"}}}), encoding="utf-8")
            result = subprocess.run([sys.executable, str(SCRIPT), "--root", str(root)], capture_output=True, text=True)
            report = json.loads(result.stdout)
            migrated = json.loads(path.read_text(encoding="utf-8"))
            self.assertEqual(result.returncode, 1)
            self.assertTrue(report["backup"])
            self.assertTrue((root / "production/evidence/migration-report.json").exists())
            self.assertTrue((root / "production/session-state/active.md").exists())
            self.assertEqual(migrated["schema_version"], 2)
            self.assertIsInstance(migrated["states"], list)


if __name__ == "__main__":
    unittest.main()
