#!/usr/bin/env python3
"""Cross-platform Codex Game Maker command entrypoint."""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent


def run(script: Path, arguments: list[str]) -> int:
    completed = subprocess.run([sys.executable, str(script), *arguments], check=False)
    return completed.returncode


def locate_godot(root: Path) -> str:
    candidates = [
        shutil.which("godot"), shutil.which("godot4"),
        root / ".tools/godot/bin/godot",
        root / ".tools/godot/Godot.app/Contents/MacOS/Godot",
        root / ".tools/godot/macos/Godot.app/Contents/MacOS/Godot",
        SCRIPT_DIR.parent / ".tools/godot/bin/godot",
        SCRIPT_DIR.parent / ".tools/godot/macos/Godot.app/Contents/MacOS/Godot",
    ]
    for candidate in candidates:
        if candidate and Path(candidate).is_file():
            return str(Path(candidate).resolve())
    return ""


def doctor(root: Path) -> int:
    plugin_root = SCRIPT_DIR.parent
    godot = locate_godot(root)
    policy_path = plugin_root / "references/policies/godot-version-policy.json"
    checks = {
        "python": sys.executable,
        "project_godot": str(root / "project.godot") if (root / "project.godot").is_file() else "",
        "godot": godot,
        "player_ready_gate": str(SCRIPT_DIR / "guards/player_ready_gate.py"),
        "commercial_release_gate": str(SCRIPT_DIR / "guards/commercial_release_gate.py"),
        "quality_runner": str(SCRIPT_DIR / "quality_runner.py"),
        "version_policy": str(policy_path),
    }
    blockers = []
    warnings = []
    for key in ("player_ready_gate", "commercial_release_gate", "quality_runner", "version_policy"):
        if not Path(checks[key]).is_file():
            blockers.append(f"Missing {key}: {checks[key]}")
    if not checks["project_godot"]:
        blockers.append("Missing project.godot in target root")
    if godot and policy_path.is_file():
        version_result = subprocess.run([godot, "--version"], capture_output=True, text=True, timeout=15, check=False)
        version = version_result.stdout.strip().splitlines()[0] if version_result.stdout.strip() else version_result.stderr.strip()
        checks["godot_version"] = version
        match = re.match(r"^(\d+\.\d+)", version)
        minor = match.group(1) if match else ""
        policy = json.loads(policy_path.read_text(encoding="utf-8"))
        if minor in policy.get("eol_minor_lines", []):
            blockers.append(f"Godot {version} is EOL; migrate before commercial release")
        elif minor not in policy.get("supported_minor_lines", []):
            warnings.append(f"Godot {version} is not on a fully supported line in the verified policy")
    elif not godot:
        warnings.append("Godot executable not found")
    gate = "BLOCKED" if blockers else ("PASS_WITH_WARNINGS" if warnings else "PASS")
    report = {"gate": gate, "root": str(root), "checks": checks, "blockers": blockers, "warnings": warnings}
    print(json.dumps(report, indent=2))
    return 1 if blockers else 0


def main() -> int:
    parser = argparse.ArgumentParser(prog="cgm", description="Codex Game Maker cross-platform gates")
    sub = parser.add_subparsers(dest="command", required=True)

    doctor_parser = sub.add_parser("doctor")
    doctor_parser.add_argument("--root", default=".")

    install_parser = sub.add_parser("install-godot")
    install_parser.add_argument("--version", default="")
    install_parser.add_argument("--with-export-templates", action="store_true")
    install_parser.add_argument("--force", action="store_true")
    install_parser.add_argument("--dry-run", action="store_true")

    export_parser = sub.add_parser("export")
    export_parser.add_argument("--root", default=".")
    export_parser.add_argument("--preset", required=True)
    export_parser.add_argument("--output", required=True)
    export_parser.add_argument("--godot", default="")
    export_parser.add_argument("--debug", action="store_true")

    quality_parser = sub.add_parser("quality")
    quality_parser.add_argument("--root", default=".")
    quality_parser.add_argument("--profile", choices=("player_ready", "commercial_release", "all"), default="all")
    quality_parser.add_argument("--command", dest="command_ids", action="append", default=[])

    player_parser = sub.add_parser("player-ready")
    player_parser.add_argument("--root", default=".")
    player_parser.add_argument("--skip-quality", action="store_true")
    player_parser.add_argument("--strict", action="store_true")

    commercial_parser = sub.add_parser("commercial-release")
    commercial_parser.add_argument("--root", default=".")
    commercial_parser.add_argument("--skip-quality", action="store_true")
    commercial_parser.add_argument("--output", default="production/evidence/commercial-release-gate.json")

    args = parser.parse_args()
    root = Path(getattr(args, "root", ".")).resolve()
    if args.command == "doctor":
        return doctor(root)
    if args.command == "install-godot":
        values = []
        if args.version:
            values.extend(["--version", args.version])
        if args.with_export_templates:
            values.append("--with-export-templates")
        if args.force:
            values.append("--force")
        if args.dry_run:
            values.append("--dry-run")
        return run(SCRIPT_DIR / "install_godot.py", values)
    if args.command == "export":
        values = ["--root", str(root), "--preset", args.preset, "--output", args.output]
        if args.godot:
            values.extend(["--godot", args.godot])
        if args.debug:
            values.append("--debug")
        return run(SCRIPT_DIR / "export_godot.py", values)
    if args.command == "quality":
        values = ["--root", str(root), "--profile", args.profile]
        for command_id in args.command_ids:
            values.extend(["--command", command_id])
        return run(SCRIPT_DIR / "quality_runner.py", values)
    if args.command == "player-ready":
        if not args.skip_quality:
            rc = run(SCRIPT_DIR / "quality_runner.py", ["--root", str(root), "--profile", "player_ready"])
            if rc != 0:
                return rc
        values = ["--root", str(root)]
        if args.strict:
            values.append("--strict")
        return run(SCRIPT_DIR / "guards/player_ready_gate.py", values)
    if args.command == "commercial-release":
        if not args.skip_quality:
            rc = run(SCRIPT_DIR / "quality_runner.py", ["--root", str(root), "--profile", "commercial_release"])
            if rc != 0:
                return rc
        return run(
            SCRIPT_DIR / "guards/commercial_release_gate.py",
            ["--root", str(root), "--output", args.output],
        )
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
