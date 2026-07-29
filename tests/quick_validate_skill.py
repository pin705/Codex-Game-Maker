#!/usr/bin/env python3
"""CI-portable equivalent of Codex skill-creator quick validation."""

from __future__ import annotations

import re
import sys
from pathlib import Path

import yaml


ALLOWED_PROPERTIES = {"name", "description", "license", "allowed-tools", "metadata"}


def validate(skill_path: Path) -> str | None:
    skill_md = skill_path / "SKILL.md"
    if not skill_md.is_file():
        return "SKILL.md not found"
    content = skill_md.read_text(encoding="utf-8-sig")
    match = re.match(r"^---\n(.*?)\n---", content, re.DOTALL)
    if not match:
        return "Invalid or missing YAML frontmatter"
    try:
        frontmatter = yaml.safe_load(match.group(1))
    except yaml.YAMLError as exc:
        return f"Invalid YAML frontmatter: {exc}"
    if not isinstance(frontmatter, dict):
        return "Frontmatter must be a YAML object"
    unexpected = set(frontmatter) - ALLOWED_PROPERTIES
    if unexpected:
        return f"Unexpected frontmatter keys: {', '.join(sorted(unexpected))}"
    name = frontmatter.get("name")
    if not isinstance(name, str) or not name:
        return "Missing non-empty name"
    if (
        len(name) > 64
        or not re.fullmatch(r"[a-z0-9-]+", name)
        or name.startswith("-")
        or name.endswith("-")
        or "--" in name
    ):
        return f"Invalid hyphen-case skill name: {name}"
    description = frontmatter.get("description")
    if not isinstance(description, str) or not description:
        return "Missing non-empty description"
    if len(description) > 1024 or "<" in description or ">" in description:
        return "Description exceeds the skill contract"
    return None


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: quick_validate_skill.py <skill-directory>")
        return 2
    path = Path(sys.argv[1])
    error = validate(path)
    if error:
        print(f"{path}: {error}")
        return 1
    print(f"{path}: valid")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
