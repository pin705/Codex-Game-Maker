#!/usr/bin/env python3
"""CI-portable validation of the Codex plugin ingestion fields used here."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path, PurePosixPath
from urllib.parse import urlparse

import yaml


SEMVER = re.compile(
    r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)"
    r"(?:-[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?"
    r"(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$"
)
INTERFACE_STRINGS = (
    "displayName",
    "shortDescription",
    "longDescription",
    "developerName",
    "category",
)


def non_empty(value: object) -> bool:
    return isinstance(value, str) and bool(value.strip())


def validate_asset(root: Path, value: object, field: str, errors: list[str]) -> None:
    if not non_empty(value):
        errors.append(f"{field} must be a non-empty path")
        return
    candidate = PurePosixPath(str(value).replace("\\", "/"))
    if candidate.is_absolute() or any(part in {"", ".", ".."} for part in candidate.parts):
        errors.append(f"{field} must remain inside the plugin")
        return
    if not (root / candidate.as_posix()).is_file():
        errors.append(f"{field} points to a missing file")


def validate(root: Path) -> list[str]:
    errors: list[str] = []
    manifest_path = root / ".codex-plugin" / "plugin.json"
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return [f"invalid plugin manifest: {exc}"]
    for field in ("name", "version", "description"):
        if not non_empty(manifest.get(field)):
            errors.append(f"{field} must be non-empty")
    if non_empty(manifest.get("version")) and not SEMVER.fullmatch(manifest["version"]):
        errors.append("version must be strict semver")
    author = manifest.get("author")
    if not isinstance(author, dict) or not non_empty(author.get("name")):
        errors.append("author.name must be non-empty")
    elif author.get("url") is not None:
        parsed = urlparse(author["url"])
        if parsed.scheme != "https" or not parsed.netloc:
            errors.append("author.url must be absolute HTTPS")
    if str(manifest.get("skills", "")).rstrip("/") not in {"skills", "./skills"}:
        errors.append("skills must resolve to skills/")
    interface = manifest.get("interface")
    if not isinstance(interface, dict):
        return errors + ["interface must be an object"]
    for field in INTERFACE_STRINGS:
        if not non_empty(interface.get(field)):
            errors.append(f"interface.{field} must be non-empty")
    if "defaultPrompt" not in interface and "default_prompt" not in interface:
        errors.append("interface.defaultPrompt is required")
    capabilities = interface.get("capabilities")
    if not isinstance(capabilities, list) or not all(non_empty(item) for item in capabilities):
        errors.append("interface.capabilities must be an array of strings")
    color = interface.get("brandColor")
    if color is not None and (
        not isinstance(color, str) or not re.fullmatch(r"#[0-9A-Fa-f]{6}", color)
    ):
        errors.append("interface.brandColor must use #RRGGBB")
    for field in ("composerIcon", "logo", "logoDark"):
        if field in interface:
            validate_asset(root, interface[field], f"interface.{field}", errors)
    screenshots = interface.get("screenshots", [])
    if not isinstance(screenshots, list):
        errors.append("interface.screenshots must be an array")
    else:
        for index, path in enumerate(screenshots):
            validate_asset(root, path, f"interface.screenshots[{index}]", errors)

    skills_root = root / "skills"
    if not skills_root.is_dir():
        return errors + ["skills/ directory is required"]
    display_names: set[str] = set()
    for skill in sorted(skills_root.glob("*")):
        if not skill.is_dir():
            continue
        if not (skill / "SKILL.md").is_file():
            errors.append(f"{skill.name}: SKILL.md is required")
        agent_path = skill / "agents" / "openai.yaml"
        if not agent_path.is_file():
            errors.append(f"{skill.name}: agents/openai.yaml is required")
            continue
        try:
            agent = yaml.safe_load(agent_path.read_text(encoding="utf-8-sig"))
        except yaml.YAMLError as exc:
            errors.append(f"{skill.name}: invalid agents/openai.yaml: {exc}")
            continue
        skill_interface = agent.get("interface") if isinstance(agent, dict) else None
        if not isinstance(skill_interface, dict):
            errors.append(f"{skill.name}: agent interface must be an object")
            continue
        for field in ("display_name", "short_description", "default_prompt"):
            if not non_empty(skill_interface.get(field)):
                errors.append(f"{skill.name}: interface.{field} must be non-empty")
        short_description = skill_interface.get("short_description")
        if non_empty(short_description) and not 25 <= len(str(short_description).strip()) <= 64:
            errors.append(f"{skill.name}: interface.short_description must be 25-64 characters")
        default_prompt = skill_interface.get("default_prompt")
        if non_empty(default_prompt) and f"${skill.name}" not in str(default_prompt):
            errors.append(f"{skill.name}: interface.default_prompt must mention ${skill.name}")
        display_name = skill_interface.get("display_name")
        if non_empty(display_name):
            normalized_display_name = str(display_name).strip().casefold()
            if normalized_display_name in display_names:
                errors.append(f"{skill.name}: interface.display_name must be unique")
            display_names.add(normalized_display_name)
    return errors


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: validate_plugin_contract.py <plugin-directory>")
        return 2
    root = Path(sys.argv[1]).resolve()
    errors = validate(root)
    if errors:
        print("Plugin validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print(f"Plugin validation passed: {root}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
