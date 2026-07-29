#!/usr/bin/env python3
"""Run real Godot import, runtime, and Web export smoke checks."""

from __future__ import annotations

import importlib.util
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CGM_PATH = ROOT / "plugins/codex-game-maker/scripts/cgm.py"
SPEC = importlib.util.spec_from_file_location("cgm", CGM_PATH)
assert SPEC and SPEC.loader
CGM = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CGM)


def run(command: list[str], cwd: Path) -> str:
    result = subprocess.run(command, cwd=str(cwd), capture_output=True, text=True, timeout=180, check=False)
    output = result.stdout + result.stderr
    if result.returncode != 0:
        raise RuntimeError(output)
    return output


def main() -> int:
    fixture = ROOT / "tests/fixtures/godot-smoke"
    godot = CGM.locate_godot(fixture)
    if not godot:
        raise RuntimeError("checksum-verified Godot wrapper was not found")
    version = run([godot, "--version"], fixture).strip().splitlines()[0]
    if not version.startswith("4.6.2"):
        raise RuntimeError(f"unexpected Godot version: {version}")
    run([godot, "--headless", "--editor", "--quit", "--path", str(fixture)], fixture)
    runtime = run([godot, "--headless", "--path", str(fixture), "--quit-after", "60"], fixture)
    if "CGM_GODOT_SMOKE_PASS" not in runtime:
        raise RuntimeError("runtime marker missing")
    output = fixture / "build/index.html"
    output.parent.mkdir(parents=True, exist_ok=True)
    run([godot, "--headless", "--path", str(fixture), "--export-release", "Web", str(output)], fixture)
    if not output.is_file() or output.stat().st_size < 100:
        raise RuntimeError("Web export artifact is missing or empty")
    print(f"PASS Godot {version}: import, runtime, and Web export")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
