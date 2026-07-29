#!/usr/bin/env python3
"""Verify every pinned Godot archive hash against the official checksum asset."""

from __future__ import annotations

import json
import re
import urllib.request
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
POLICY = ROOT / "plugins/codex-game-maker/references/policies/godot-version-policy.json"
CHECKSUM_LINE = re.compile(r"^([0-9a-fA-F]{128})\s+\*?(.+?)\s*$")


def main() -> int:
    policy = json.loads(POLICY.read_text(encoding="utf-8"))
    release_id = f"{policy['recommended_version']}-stable"
    release = policy["verified_archives"][release_id]
    url = release["checksum_source"]
    request = urllib.request.Request(url, headers={"User-Agent": "Codex-Game-Maker-Policy-Check"})
    with urllib.request.urlopen(request, timeout=60) as response:
        text = response.read().decode("utf-8")
    official: dict[str, str] = {}
    for line in text.splitlines():
        match = CHECKSUM_LINE.fullmatch(line)
        if match:
            official[match.group(2)] = match.group(1).lower()
    mismatches = [
        {
            "file": filename,
            "expected": expected,
            "official": official.get(filename, "missing"),
        }
        for filename, expected in sorted(release["files"].items())
        if official.get(filename) != expected
    ]
    report = {
        "gate": "BLOCKED" if mismatches else "PASS",
        "release": release_id,
        "checksum_source": url,
        "verified_files": len(release["files"]) - len(mismatches),
        "mismatches": mismatches,
    }
    print(json.dumps(report, indent=2))
    return 1 if mismatches else 0


if __name__ == "__main__":
    raise SystemExit(main())
