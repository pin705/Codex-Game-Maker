#!/usr/bin/env python3
"""Cross-platform Godot export runner for an existing export preset."""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
PLUGIN_ROOT = SCRIPT_DIR.parent


def find_godot(root: Path, configured: str) -> str:
    candidates = []
    if configured:
        candidates.append(Path(configured).expanduser())
    if os.environ.get("GODOT"):
        candidates.append(Path(os.environ["GODOT"]).expanduser())
    for name in ("godot", "godot4"):
        found = shutil.which(name)
        if found:
            candidates.append(Path(found))
    for base in (root, PLUGIN_ROOT):
        candidates.extend([
            base / ".tools/godot/bin/godot",
            base / ".tools/godot/bin/godot.cmd",
            base / ".tools/godot/macos/Godot.app/Contents/MacOS/Godot",
        ])
    for candidate in candidates:
        if candidate.is_file():
            return str(candidate.resolve())
    raise RuntimeError("Godot executable not found; run cgm.py install-godot or pass --godot")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".")
    parser.add_argument("--preset", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--godot", default="")
    parser.add_argument("--debug", action="store_true")
    parser.add_argument("--log", default="production/evidence/platforms/export.log")
    args = parser.parse_args()
    root = Path(args.root).resolve()
    if not (root / "project.godot").is_file() or not (root / "export_presets.cfg").is_file():
        print(json.dumps({"gate": "BLOCKED", "error": "project.godot and export_presets.cfg are required"}, indent=2))
        return 1
    godot = find_godot(root, args.godot)
    output = Path(args.output)
    output = output.resolve() if output.is_absolute() else (root / output).resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    mode = "--export-debug" if args.debug else "--export-release"
    command = [godot, "--headless", "--path", str(root), mode, args.preset, str(output)]
    completed = subprocess.run(command, capture_output=True, text=True, check=False)
    log = Path(args.log)
    log = log.resolve() if log.is_absolute() else (root / log).resolve()
    log.parent.mkdir(parents=True, exist_ok=True)
    log.write_text(completed.stdout + "\n" + completed.stderr, encoding="utf-8")
    gate = "PASS" if completed.returncode == 0 and output.exists() else "BLOCKED"
    print(json.dumps({"gate": gate, "command": command, "returncode": completed.returncode, "output": str(output), "log": str(log)}, indent=2))
    return 0 if gate == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
