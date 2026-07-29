#!/usr/bin/env python3
"""Repository-level validation for the canonical Codex Game Maker plugin."""

from __future__ import annotations

import json
import re
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "plugins" / "codex-game-maker"
RELATIVE_RESOURCE = re.compile(
    r"(?P<path>(?:\.\./)+(?:references|scripts|tools)/[^\s`\"')>,]+)"
)


def fail(message: str) -> None:
    raise SystemExit(message)


def load_json_and_yaml() -> None:
    candidates: set[Path] = set()
    candidates.add(PACKAGE / ".codex-plugin" / "plugin.json")
    candidates.update((PACKAGE / "references" / "templates").glob("*.json"))
    candidates.update((PACKAGE / "references" / "policies").glob("*.json"))
    candidates.update((PACKAGE / "references" / "commands").glob("*.yaml"))
    candidates.update((PACKAGE / "references" / "workflows").glob("*.yaml"))
    candidates.update((PACKAGE / "skills").glob("*/agents/openai.yaml"))

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
    for skill_file in sorted((PACKAGE / "skills").glob("*/SKILL.md")):
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


def validate_single_source() -> None:
    for legacy in (ROOT / "codex-game-studio", ROOT / "tools", ROOT / "requirements-asset-tools.txt"):
        if legacy.exists():
            fail(f"Duplicate legacy layout must not exist: {legacy.relative_to(ROOT)}")


def validate_counts() -> None:
    expected = {
        "skills": (len([p for p in (PACKAGE / "skills").iterdir() if p.is_dir()]), 23),
        "templates": (len(list((PACKAGE / "references" / "templates").glob("*"))), 58),
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


def validate_dynamic_contracts() -> None:
    templates = PACKAGE / "references" / "templates"
    state_contract = json.loads((templates / "game-state-matrix.json").read_text(encoding="utf-8"))
    if state_contract.get("schema_version") != 2:
        fail("Game-state template must use dynamic schema_version 2")
    for field in (
        "states",
        "journeys",
        "experience_requirements",
        "quality_requirements",
        "required_evidence_checks",
    ):
        if not isinstance(state_contract.get(field), list) or not state_contract[field]:
            fail(f"Game-state template needs non-empty dynamic field: {field}")
    quality_kinds = {
        str(row.get("kind"))
        for row in state_contract["quality_requirements"]
        if isinstance(row, dict) and row.get("required", True)
    }
    if not {"engine_import", "static_analysis", "reliability"}.issubset(quality_kinds):
        fail("Game-state template lost universal quality command kinds")

    assets = json.loads((templates / "asset-coverage.json").read_text(encoding="utf-8"))
    if not isinstance(assets.get("coverage_policy"), dict) or not isinstance(assets.get("groups"), list):
        fail("Asset coverage must remain game-contract driven")
    asset_schema = assets.get("asset_schema") if isinstance(assets.get("asset_schema"), dict) else {}
    if not isinstance(asset_schema.get("presentation"), dict):
        fail("Asset coverage lost runtime presentation usages")
    audio = json.loads((templates / "audio-manifest.json").read_text(encoding="utf-8"))
    for field in ("coverage_policy", "required_buses", "coverage_requirements", "events"):
        if field not in audio:
            fail(f"Audio manifest lost dynamic field: {field}")
    visual = json.loads((templates / "visual-quality-contract.json").read_text(encoding="utf-8"))
    for field in ("required_viewports", "art_direction", "lookdev", "surfaces", "cross_surface_checks", "verification_commands"):
        if field not in visual:
            fail(f"Visual quality contract lost field: {field}")

    gate_text = (PACKAGE / "scripts" / "guards" / "player_ready_gate.py").read_text(encoding="utf-8")
    for forbidden in ("REQUIRED_STATES", "REQUIRED_GROUPS", "REQUIRED_AUDIO", "REQUIRED_EVIDENCE"):
        if forbidden in gate_text:
            fail(f"Player-ready gate regressed to fixed contract constant: {forbidden}")

    for required_guardrail in ("visual-quality-contract.json", "asset.presentation_distorted", "visual_contract.finding_open"):
        if required_guardrail not in gate_text:
            fail(f"Player-ready gate lost visual guardrail: {required_guardrail}")

    contract_ref = "../../references/contracts/player-journey-schema.md"
    for skill_name in (
        "game-studio-start",
        "game-studio-design",
        "game-studio-build",
        "game-studio-implementation",
        "game-studio-review",
    ):
        skill_text = (PACKAGE / "skills" / skill_name / "SKILL.md").read_text(encoding="utf-8")
        if contract_ref not in skill_text:
            fail(f"{skill_name} no longer routes through the dynamic player-journey contract")


def validate_todo_markers() -> None:
    for path in PACKAGE.rglob("*"):
        if not path.is_file() or "__pycache__" in path.parts:
            continue
        try:
            text = path.read_text(encoding="utf-8-sig")
        except UnicodeDecodeError:
            continue
        if "[TODO:" in text:
            fail(f"Unresolved scaffold marker in {path.relative_to(ROOT)}")


def main() -> int:
    load_json_and_yaml()
    validate_skill_resources()
    validate_counts()
    validate_dynamic_contracts()
    validate_todo_markers()
    validate_single_source()
    print("Repository validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
