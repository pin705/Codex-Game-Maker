#!/usr/bin/env python3
"""Validate immutable plugin release metadata and lifecycle documentation."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PLUGIN = ROOT / "plugins/codex-game-maker"


def fail(message: str, errors: list[str]) -> None:
    errors.append(message)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--tag", default="")
    args = parser.parse_args()
    errors: list[str] = []
    manifest = json.loads((PLUGIN / ".codex-plugin/plugin.json").read_text(encoding="utf-8"))
    version = str(manifest.get("version", ""))
    if not re.fullmatch(r"\d+\.\d+\.\d+", version):
        fail(f"Stable release version must be x.y.z, got {version}", errors)
    if args.tag and args.tag != f"v{version}":
        fail(f"Tag {args.tag} does not match manifest v{version}", errors)
    for relative in ("README.md", "README.zh-CN.md", "CHANGELOG.md", "UPGRADING.md", "CONTRIBUTING.md", "docs/RELEASE_ASSETS.md"):
        text = (ROOT / relative).read_text(encoding="utf-8-sig")
        if version not in text:
            fail(f"{relative} does not name release {version}", errors)
    readme = (ROOT / "README.md").read_text(encoding="utf-8-sig")
    update_block = re.search(r"marketplace upgrade codex-game-maker[\s\S]{0,400}", readme)
    if not update_block or "plugin add codex-game-maker@codex-game-maker" not in update_block.group(0) or "plugin list" not in update_block.group(0):
        fail("README update flow must upgrade, reinstall, and verify the plugin", errors)
    for required in ("SECURITY.md", "SUPPORT.md", "docs/RELEASE_POLICY.md", "requirements-dev.txt", "evals/rubric.json"):
        if not (ROOT / required).is_file():
            fail(f"Missing release file: {required}", errors)
    skills = sorted((PLUGIN / "skills").glob("*/SKILL.md"))
    for skill in skills:
        if not (skill.parent / "agents/openai.yaml").is_file():
            fail(f"Missing agents/openai.yaml: {skill.parent.name}", errors)
    eval_result = subprocess.run([sys.executable, str(ROOT / "evals/run_eval.py"), "validate"], capture_output=True, text=True)
    if eval_result.returncode != 0:
        fail("Evaluation corpus validation failed: " + eval_result.stdout, errors)
    result = {"gate": "BLOCKED" if errors else "PASS", "version": version, "skills": len(skills), "errors": errors}
    print(json.dumps(result, indent=2))
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
