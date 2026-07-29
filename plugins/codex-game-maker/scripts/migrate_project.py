#!/usr/bin/env python3
"""Conservative project-contract migration with backup and explicit review markers."""

from __future__ import annotations

import argparse
import json
import shutil
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def read_json(path: Path) -> dict[str, Any] | None:
    if not path.is_file():
        return None
    try:
        value = json.loads(path.read_text(encoding="utf-8-sig"))
        return value if isinstance(value, dict) else None
    except json.JSONDecodeError:
        return None


def write_json(path: Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def migrate(root: Path, dry_run: bool, backup: bool) -> dict[str, Any]:
    changes: list[dict[str, str]] = []
    blockers: list[str] = []
    backup_path = ""
    if backup and not dry_run:
        stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
        destination = root / ".cgm-backups" / stamp
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(root, destination, ignore=shutil.ignore_patterns(".git", ".godot", ".tools", "build", ".cgm-backups"))
        backup_path = str(destination)

    state_path = root / "design/game-state-matrix.json"
    state = read_json(state_path)
    if state is not None and isinstance(state.get("states"), dict):
        rows = []
        for state_id, value in state["states"].items():
            row = dict(value) if isinstance(value, dict) else {}
            row.setdefault("id", str(state_id))
            row.setdefault("required", True)
            row.setdefault("status", "needs_review")
            rows.append(row)
        state["states"] = rows
        state["schema_version"] = 2
        state.setdefault("journeys", [])
        state.setdefault("experience_requirements", [])
        state.setdefault("quality_requirements", [])
        state.setdefault("required_evidence_checks", [])
        blockers.append("Migrated legacy state dictionary; define and verify game-specific journeys before player-ready.")
        changes.append({"path": str(state_path.relative_to(root)), "change": "converted legacy states dictionary to schema-v2 rows"})
        if not dry_run:
            write_json(state_path, state)

    style_path = root / "design/art/style-lock.json"
    if not style_path.is_file():
        template = Path(__file__).resolve().parent.parent / "references/templates/style-lock.json"
        changes.append({"path": "design/art/style-lock.json", "change": "created planned style-lock template"})
        blockers.append("Style lock was created as planned; fill it and run cgm style-lock seal before production.")
        if not dry_run:
            style_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(template, style_path)

    session_path = root / "production/session-state/active.md"
    if not session_path.is_file():
        template = Path(__file__).resolve().parent.parent / "references/templates/session-state.md"
        changes.append({"path": "production/session-state/active.md", "change": "created continuity session-state template"})
        blockers.append("Session state was created; bind it to the sealed style digest and current production evidence.")
        if not dry_run:
            session_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(template, session_path)

    for relative in ("design/assets/asset-coverage.json", "design/audio/audio-manifest.json", "production/reviews/visual-quality-contract.json", "production/evidence/player-ready.json"):
        path = root / relative
        data = read_json(path)
        if data is None:
            continue
        if "style_lock" not in data:
            data["style_lock"] = {"path": "design/art/style-lock.json", "style_version": "", "sha256": ""}
            changes.append({"path": relative, "change": "added pending style-lock binding"})
            blockers.append(f"{relative} needs a sealed style-lock binding.")
            if not dry_run:
                write_json(path, data)

    report = {
        "schema_version": 1,
        "gate": "BLOCKED" if blockers else "PASS",
        "dry_run": dry_run,
        "backup": backup_path,
        "changes": changes,
        "blockers": blockers,
    }
    if not dry_run:
        write_json(root / "production/evidence/migration-report.json", report)
    return report


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".")
    parser.add_argument("--dry-run", action="store_true")
    backup_group = parser.add_mutually_exclusive_group()
    backup_group.add_argument("--backup", dest="backup", action="store_true")
    backup_group.add_argument("--no-backup", dest="backup", action="store_false")
    parser.set_defaults(backup=True)
    args = parser.parse_args()
    report = migrate(Path(args.root).resolve(), args.dry_run, args.backup)
    print(json.dumps(report, indent=2, ensure_ascii=False))
    return 0 if report["gate"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
