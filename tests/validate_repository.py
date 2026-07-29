#!/usr/bin/env python3
"""Repository-level validation for both Codex Game Maker plugin layouts."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "plugins" / "codex-game-maker"
STUDIO = ROOT / "codex-game-studio"
RELATIVE_RESOURCE = re.compile(
    r"(?P<path>(?:\.\./)+(?:references|scripts|tools)/[^\s`\"')>,]+)"
)


def fail(message: str) -> None:
    raise SystemExit(message)


def load_json_and_yaml() -> None:
    roots = (PACKAGE, STUDIO)
    candidates: set[Path] = set()
    for root in roots:
        candidates.add(root / ".codex-plugin" / "plugin.json")
        candidates.update((root / "references" / "templates").glob("*.json"))
        candidates.update((root / "references" / "policies").glob("*.json"))
        candidates.update((root / "references" / "commands").glob("*.yaml"))
        candidates.update((root / "references" / "workflows").glob("*.yaml"))
        candidates.update((root / "skills").glob("*/agents/openai.yaml"))

    for path in sorted(candidates):
        if not path.is_file():
            fail(f"Missing structured file: {path.relative_to(ROOT)}")
        try:
            with path.open("r", encoding="utf-8-sig") as handle:
                if path.suffix == ".json":
                    json.load(handle)
                else:
                    yaml.safe_load(handle)
        except (json.JSONDecodeError, yaml.YAMLError) as exc:
            fail(f"Invalid {path.suffix} file {path.relative_to(ROOT)}: {exc}")


def validate_skill_resources() -> None:
    for root in (PACKAGE, STUDIO):
        for skill_file in sorted((root / "skills").glob("*/SKILL.md")):
            text = skill_file.read_text(encoding="utf-8-sig")
            for match in RELATIVE_RESOURCE.finditer(text):
                token = match.group("path").rstrip(".;:")
                if any(marker in token for marker in ("<", ">", "*")):
                    continue
                resolved = (skill_file.parent / token).resolve()
                if not resolved.exists():
                    fail(
                        "Broken skill resource reference: "
                        f"{skill_file.relative_to(ROOT)} -> {token}"
                    )


def directory_files(root: Path) -> dict[str, bytes]:
    return {
        str(path.relative_to(root)): path.read_bytes()
        for path in sorted(root.rglob("*"))
        if path.is_file() and "__pycache__" not in path.parts
    }


def validate_mirror() -> None:
    for subdir in ("references", "scripts"):
        package_files = directory_files(PACKAGE / subdir)
        studio_files = directory_files(STUDIO / subdir)
        if package_files != studio_files:
            fail(f"Package/studio {subdir} trees are not synchronized")

    package_skills = directory_files(PACKAGE / "skills")
    studio_skills = directory_files(STUDIO / "skills")
    normalized_studio = {
        name: data.replace(b"../../../tools/", b"../../tools/")
        for name, data in studio_skills.items()
    }
    if package_skills != normalized_studio:
        fail("Package/studio skill trees are not semantically synchronized")

    if directory_files(PACKAGE / "tools") != directory_files(ROOT / "tools"):
        fail("Root tools/ is not synchronized with the plugin package")

    package_manifest = json.loads(
        (PACKAGE / ".codex-plugin" / "plugin.json").read_text(encoding="utf-8")
    )
    studio_manifest = json.loads(
        (STUDIO / ".codex-plugin" / "plugin.json").read_text(encoding="utf-8")
    )
    for key in (
        "name",
        "version",
        "description",
        "author",
        "homepage",
        "repository",
        "license",
        "keywords",
        "skills",
    ):
        if package_manifest.get(key) != studio_manifest.get(key):
            fail(f"Plugin manifests disagree on {key}")
    for key in (
        "displayName",
        "shortDescription",
        "longDescription",
        "developerName",
        "category",
        "capabilities",
        "websiteURL",
        "defaultPrompt",
        "brandColor",
    ):
        if package_manifest["interface"].get(key) != studio_manifest["interface"].get(key):
            fail(f"Plugin interface manifests disagree on {key}")


def validate_counts() -> None:
    expected = {
        "skills": (len([p for p in (PACKAGE / "skills").iterdir() if p.is_dir()]), 23),
        "templates": (len(list((PACKAGE / "references" / "templates").glob("*"))), 57),
        "guards": (len([p for p in (PACKAGE / "scripts" / "guards").iterdir() if p.is_file()]), 9),
    }
    commands = yaml.safe_load(
        (PACKAGE / "references" / "commands" / "catalog.yaml").read_text(
            encoding="utf-8"
        )
    )
    expected["aliases"] = (len(commands.get("commands", [])), 20)
    for label, (actual, wanted) in expected.items():
        if actual != wanted:
            fail(f"Expected {wanted} {label}, found {actual}")


def validate_todo_markers() -> None:
    for root in (PACKAGE, STUDIO):
        for path in root.rglob("*"):
            if not path.is_file() or "__pycache__" in path.parts:
                continue
            try:
                text = path.read_text(encoding="utf-8-sig")
            except UnicodeDecodeError:
                continue
            if "[TODO:" in text:
                fail(f"Unresolved scaffold marker in {path.relative_to(ROOT)}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--skip-mirror",
        action="store_true",
        help="Run structured/resource checks before the studio mirror is refreshed.",
    )
    args = parser.parse_args()

    load_json_and_yaml()
    validate_skill_resources()
    validate_counts()
    validate_todo_markers()
    if not args.skip_mirror:
        validate_mirror()
    print("Repository validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
