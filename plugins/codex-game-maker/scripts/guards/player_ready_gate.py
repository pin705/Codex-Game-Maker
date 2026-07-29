#!/usr/bin/env python3
"""Cross-platform structural and evidence gate for player-ready Godot games."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Optional


COMPLETE = {"integrated", "verified", "pass"}
CONTRACT_COMPLETE = {"approved", "locked", "complete", "player_ready", "player-ready"}
REQUIRED_STATES = {"boot", "title", "gameplay", "pause", "settings", "victory", "defeat"}
REQUIRED_GROUPS = {"player", "environment", "gameplay-feedback", "ui", "release-branding"}
REQUIRED_AUDIO = {"ui-confirm", "ui-back", "player-action", "damage-or-failure", "reward", "victory", "defeat"}
REQUIRED_EVIDENCE = {"core_loop", "long_run", "visual_quality", "controls", "ui_states", "audio", "manual_playtest"}
UI_SECTIONS = {
    "Visual Language", "Screen Inventory", "HUD Hierarchy", "Component System",
    "Input And Focus", "Responsive Layout", "Accessibility", "Motion And Feedback", "Evidence",
}
UI_TEMPLATE_MARKERS = {
    "Materials, shape language, palette, typography, iconography, depth and ornament:",
    "Critical persistent information:",
    "Contextual information:",
    "Center-playfield protection:",
    "Theme/style resources:",
    "Panels and frames:",
    "Buttons and focus states:",
    "Meters, cards, tooltips and prompts:",
    "Keyboard/mouse:",
    "Controller:",
    "Touch if applicable:",
    "Dynamic prompt strategy:",
    "Reference resolution:",
    "Safe zones:",
    "UI scale behavior:",
    "Target resolutions/aspects:",
    "Text sizing and contrast:",
    "Non-color encoding:",
    "Reduced motion:",
    "Remapping and prompt updates:",
    "Transition language:",
    "Hover/focus/pressed/disabled states:",
    "UI audio cues:",
    "Runtime captures:",
    "Navigation test:",
    "Known findings:",
}


def load_json(path: Path, blockers: list[dict]) -> Optional[dict]:
    if not path.is_file():
        blockers.append({"code": "file.missing", "message": f"Missing {path}", "path": str(path)})
        return None
    try:
        value = json.loads(path.read_text(encoding="utf-8-sig"))
    except (OSError, json.JSONDecodeError) as exc:
        blockers.append({"code": "json.invalid", "message": str(exc), "path": str(path)})
        return None
    if not isinstance(value, dict):
        blockers.append({"code": "json.object_required", "message": "Expected a JSON object", "path": str(path)})
        return None
    return value


def resolve_project_path(root: Path, raw: str) -> Optional[Path]:
    if not raw:
        return None
    if raw.startswith("res://"):
        return root / raw[6:]
    return root / raw


def require_file(root: Path, relative: str, blockers: list[dict]) -> None:
    path = root / relative
    if not path.is_file():
        blockers.append({"code": "required.missing", "message": f"Missing required file: {relative}", "path": str(path)})


def require_artifacts(root: Path, raw_values: object, code: str, message: str, source: str, blockers: list[dict]) -> None:
    if not isinstance(raw_values, list) or not raw_values:
        blockers.append({"code": code, "message": message, "path": source})
        return
    for raw in raw_values:
        artifact = resolve_project_path(root, str(raw))
        if artifact is None or not artifact.exists():
            blockers.append({"code": f"{code}.not_found", "message": f"Missing evidence artifact: {raw}", "path": str(artifact)})


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".")
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()
    root = Path(args.root).resolve()
    blockers: list[dict] = []
    warnings: list[dict] = []
    evidence: list[dict] = []

    for relative in (
        "project.godot", "production/player-ready-contract.md", "design/gdd/game-concept.md",
        "design/art/art-bible.md", "docs/architecture/architecture.md",
        "docs/architecture/control-manifest.md", "design/ui/ui-ux-spec.md",
    ):
        require_file(root, relative, blockers)

    contract_path = root / "production/player-ready-contract.md"
    if contract_path.is_file():
        contract_text = contract_path.read_text(encoding="utf-8-sig")
        status_match = re.search(r"^Status:\s*(.+?)\s*$", contract_text, re.MULTILINE | re.IGNORECASE)
        contract_status = status_match.group(1).strip().lower() if status_match else ""
        if contract_status not in CONTRACT_COMPLETE:
            blockers.append({"code": "contract.not_approved", "message": "Player-ready contract status must be Approved, Locked, Complete, or Player-Ready", "path": str(contract_path)})
        if "[Game Title]" in contract_text or re.search(r"\[[^\]]*(?:system|content|out-of-scope)[^\]]*\]", contract_text, re.IGNORECASE):
            blockers.append({"code": "contract.placeholder", "message": "Player-ready contract still contains template placeholders", "path": str(contract_path)})
        if re.search(r"^- \[ \]", contract_text, re.MULTILINE):
            blockers.append({"code": "contract.unchecked", "message": "Player-ready contract has unchecked required items", "path": str(contract_path)})

    project = root / "project.godot"
    if project.is_file():
        text = project.read_text(encoding="utf-8-sig")
        match = re.search(r'^\s*run/main_scene\s*=\s*"([^"]+)"', text, re.MULTILINE)
        if not match:
            blockers.append({"code": "godot.main_scene.missing", "message": "run/main_scene is not configured", "path": str(project)})
        else:
            scene = resolve_project_path(root, match.group(1))
            if scene is None or not scene.is_file():
                blockers.append({"code": "godot.main_scene.not_found", "message": f"Main scene is missing: {match.group(1)}", "path": str(scene)})
            else:
                evidence.append({"code": "godot.main_scene", "path": str(scene)})

    states = load_json(root / "design/game-state-matrix.json", blockers)
    if states is not None:
        rows = states.get("states")
        if not isinstance(rows, dict):
            blockers.append({"code": "states.invalid", "message": "states must be an object", "path": "design/game-state-matrix.json"})
        else:
            for state in sorted(REQUIRED_STATES):
                row = rows.get(state)
                if not isinstance(row, dict):
                    blockers.append({"code": "state.missing", "message": f"Missing required state: {state}", "path": "design/game-state-matrix.json"})
                    continue
                if str(row.get("status", "")).lower() not in COMPLETE:
                    blockers.append({"code": "state.incomplete", "message": f"State {state} is not integrated/verified", "path": "design/game-state-matrix.json"})
                scene = resolve_project_path(root, str(row.get("scene", "")))
                if scene is None or not scene.is_file():
                    blockers.append({"code": "state.scene_missing", "message": f"State {state} has no valid scene/path", "path": str(scene)})
                captures = row.get("evidence")
                require_artifacts(root, captures, "state.evidence_missing", f"State {state} has no runtime evidence", "design/game-state-matrix.json", blockers)

    coverage = load_json(root / "design/assets/asset-coverage.json", blockers)
    if coverage is not None:
        groups = coverage.get("groups")
        if not isinstance(groups, list):
            blockers.append({"code": "assets.groups_invalid", "message": "groups must be an array", "path": "design/assets/asset-coverage.json"})
        else:
            by_id = {g.get("id"): g for g in groups if isinstance(g, dict)}
            for group_id in sorted(REQUIRED_GROUPS):
                group = by_id.get(group_id)
                if not isinstance(group, dict):
                    blockers.append({"code": "assets.group_missing", "message": f"Missing asset group: {group_id}", "path": "design/assets/asset-coverage.json"})
                    continue
                if group.get("required", True) and str(group.get("status", "")).lower() not in COMPLETE:
                    blockers.append({"code": "assets.group_incomplete", "message": f"Asset group {group_id} is not integrated/verified", "path": "design/assets/asset-coverage.json"})
                assets = group.get("assets")
                if group.get("required", True) and (not isinstance(assets, list) or not assets):
                    blockers.append({"code": "assets.empty", "message": f"Required asset group {group_id} is empty", "path": "design/assets/asset-coverage.json"})
                if group.get("required", True):
                    require_artifacts(root, group.get("evidence"), "assets.evidence_missing", f"Asset group {group_id} has no runtime evidence", "design/assets/asset-coverage.json", blockers)
                for asset in assets if isinstance(assets, list) else []:
                    if not isinstance(asset, dict) or str(asset.get("status", "")).lower() not in COMPLETE:
                        blockers.append({"code": "asset.incomplete", "message": f"Asset in {group_id} is not integrated/verified", "path": "design/assets/asset-coverage.json"})
                        continue
                    artifact = resolve_project_path(root, str(asset.get("path", "")))
                    if artifact is None or not artifact.exists():
                        blockers.append({"code": "asset.not_found", "message": f"Integrated asset path is missing: {asset.get('path', '')}", "path": str(artifact)})

    ui_path = root / "design/ui/ui-ux-spec.md"
    if ui_path.is_file():
        ui_text = ui_path.read_text(encoding="utf-8-sig")
        if "[Game Title]" in ui_text or re.search(r"^Status:\s*Draft\s*$", ui_text, re.MULTILINE | re.IGNORECASE):
            blockers.append({"code": "ui.template_incomplete", "message": "UI spec is still marked Draft or contains the template title", "path": str(ui_path)})
        for section in sorted(UI_SECTIONS):
            if not re.search(rf"^##\s+{re.escape(section)}\s*$", ui_text, re.MULTILINE):
                blockers.append({"code": "ui.section_missing", "message": f"UI spec missing section: {section}", "path": str(ui_path)})
        remaining_markers = sorted(marker for marker in UI_TEMPLATE_MARKERS if re.search(rf"^{re.escape(marker)}\s*$", ui_text, re.MULTILINE))
        if remaining_markers:
            blockers.append({"code": "ui.placeholder", "message": f"UI spec has {len(remaining_markers)} unfilled template fields", "path": str(ui_path)})
        for line in ui_text.splitlines():
            if not line.startswith("|") or re.match(r"^\|[- :|]+\|$", line) or "State |" in line:
                continue
            cells = [cell.strip() for cell in line.strip("|").split("|")]
            if len(cells) >= 5 and any(not cell for cell in cells[:5]):
                blockers.append({"code": "ui.screen_row_incomplete", "message": f"UI screen inventory row has empty required cells: {line}", "path": str(ui_path)})

    audio = load_json(root / "design/audio/audio-manifest.json", blockers)
    if audio is not None:
        if audio.get("intentional_silence"):
            if not str(audio.get("silence_rationale", "")).strip():
                blockers.append({"code": "audio.silence_unjustified", "message": "Intentional silence needs a rationale", "path": "design/audio/audio-manifest.json"})
        else:
            buses = audio.get("buses")
            if not isinstance(buses, list) or not {"Master", "Music", "SFX", "UI"}.issubset(set(buses)):
                blockers.append({"code": "audio.buses_missing", "message": "Required audio buses are missing", "path": "design/audio/audio-manifest.json"})
            events = audio.get("events")
            by_id = {e.get("id"): e for e in events if isinstance(e, dict)} if isinstance(events, list) else {}
            for event_id in sorted(REQUIRED_AUDIO):
                event = by_id.get(event_id)
                if not isinstance(event, dict) or str(event.get("status", "")).lower() not in COMPLETE:
                    blockers.append({"code": "audio.event_incomplete", "message": f"Audio event {event_id} is not integrated/verified", "path": "design/audio/audio-manifest.json"})
                    continue
                artifact = resolve_project_path(root, str(event.get("asset", "")))
                if artifact is None or not artifact.is_file():
                    blockers.append({"code": "audio.asset_missing", "message": f"Audio event {event_id} has no valid asset", "path": str(artifact)})
                if not str(event.get("trigger", "")).strip():
                    blockers.append({"code": "audio.trigger_missing", "message": f"Audio event {event_id} has no trigger", "path": "design/audio/audio-manifest.json"})
        require_artifacts(root, audio.get("evidence"), "audio.evidence_missing", "Audio manifest has no listening/runtime evidence", "design/audio/audio-manifest.json", blockers)

    test_files = list((root / "tests").glob("**/*.gd")) if (root / "tests").is_dir() else []
    if not test_files:
        blockers.append({"code": "tests.missing", "message": "No Godot tests found under tests/", "path": str(root / "tests")})
    else:
        evidence.append({"code": "tests.present", "count": len(test_files)})

    playtest_files = [path for path in (root / "production/playtests").glob("*.md") if path.is_file() and path.stat().st_size > 0] if (root / "production/playtests").is_dir() else []
    if not playtest_files:
        blockers.append({"code": "playtest.missing", "message": "No non-empty manual playtest note found under production/playtests/", "path": str(root / "production/playtests")})
    else:
        evidence.append({"code": "playtests.present", "count": len(playtest_files)})

    report = load_json(root / "production/evidence/player-ready.json", blockers)
    if report is not None:
        checks = report.get("checks")
        if not isinstance(checks, dict):
            blockers.append({"code": "evidence.checks_invalid", "message": "checks must be an object", "path": "production/evidence/player-ready.json"})
        else:
            for check in sorted(REQUIRED_EVIDENCE):
                if str(checks.get(check, "")).upper() != "PASS":
                    blockers.append({"code": "evidence.not_passed", "message": f"Evidence check {check} is not PASS", "path": "production/evidence/player-ready.json"})
        artifacts = report.get("artifacts")
        require_artifacts(root, artifacts, "evidence.artifacts_missing", "No player-ready artifacts recorded", "production/evidence/player-ready.json", blockers)

    if args.strict and warnings:
        blockers.append({"code": "strict.warnings", "message": "Strict mode treats warnings as blockers", "path": str(root)})
    gate = "BLOCKED" if blockers else ("PASS_WITH_WARNINGS" if warnings else "PASS")
    print(json.dumps({"root": str(root), "gate": gate, "blockers": blockers, "warnings": warnings, "evidence": evidence}, indent=2))
    return 1 if blockers else 0


if __name__ == "__main__":
    raise SystemExit(main())
