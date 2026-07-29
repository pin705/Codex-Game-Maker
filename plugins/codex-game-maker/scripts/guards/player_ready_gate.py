#!/usr/bin/env python3
"""Cross-platform, media-aware and command-backed player-ready gate for Godot games."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Optional


SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR.parent / "lib"))

from cgm_validation import (  # noqa: E402
    AUDIO_EXTENSIONS,
    MEDIA_EXTENSIONS,
    PASS_STATUSES,
    by_id,
    command_results,
    git_commit,
    git_dirty,
    is_within,
    issue,
    load_json,
    project_fingerprint,
    report_gate,
    require_artifacts,
    require_ready_markdown,
    resolve_project_path,
    sha256_json,
    sha256_file,
    sha256_path,
    sniff_media,
    status_ok,
    validate_artifact,
    validate_media,
)


REQUIRED_STATES = {"boot", "title", "onboarding", "gameplay", "pause", "settings", "victory", "defeat"}
REQUIRED_GROUPS = {"player", "environment", "gameplay-feedback", "ui", "release-branding"}
REQUIRED_AUDIO = {"ui-confirm", "ui-back", "ui-focus", "ui-invalid", "player-action", "damage-or-failure", "reward", "victory", "defeat", "music-main", "ambience-gameplay"}
REQUIRED_EVIDENCE = {"core_loop", "long_run", "visual_quality", "controls", "ui_states", "audio", "manual_playtest"}
REQUIRED_COMMANDS = {"godot_import", "godot_lint", "core_loop", "long_run"}
MEDIA_PATH_PATTERN = re.compile(r"((?:production|assets|marketing|build)/[A-Za-z0-9_./-]+\.(?:png|jpe?g|gif|webp|wav|ogg|mp3|flac|mp4|mov|webm))", re.IGNORECASE)
UI_SECTIONS = {
    "Visual Language", "Screen Inventory", "HUD Hierarchy", "Component System",
    "Input And Focus", "Responsive Layout", "Accessibility", "Motion And Feedback", "Evidence",
}
UI_TEMPLATE_MARKERS = {
    "Materials, shape language, palette, typography, iconography, depth and ornament:",
    "Critical persistent information:", "Contextual information:", "Center-playfield protection:",
    "Theme/style resources:", "Panels and frames:", "Buttons and focus states:",
    "Meters, cards, tooltips and prompts:", "Keyboard/mouse:", "Controller:",
    "Touch if applicable:", "Dynamic prompt strategy:", "Reference resolution:", "Safe zones:",
    "UI scale behavior:", "Target resolutions/aspects:", "Text sizing and contrast:",
    "Non-color encoding:", "Reduced motion:", "Remapping and prompt updates:",
    "Transition language:", "Hover/focus/pressed/disabled states:", "UI audio cues:",
    "Runtime captures:", "Navigation test:", "Known findings:",
}


def require_file(root: Path, relative: str, blockers: list[dict]) -> None:
    path = root / relative
    if not path.is_file():
        blockers.append(issue("required.missing", f"Missing required file: {relative}", path))


def require_pass_review(root: Path, pattern: str, code: str, expected_kind: str, blockers: list[dict]) -> None:
    review_dir = root / "production/reviews"
    candidates = list(review_dir.glob(pattern)) if review_dir.is_dir() else []
    for path in candidates:
        text = path.read_text(encoding="utf-8-sig")
        status = re.search(r"^Status:\s*(.+?)\s*$", text, re.MULTILINE | re.IGNORECASE)
        gate_pass = re.search(r"^Gate:\s*PASS\s*$", text, re.MULTILINE | re.IGNORECASE)
        reviewer = re.search(r"^Reviewer:\s*(\S.+?)\s*$", text, re.MULTILINE | re.IGNORECASE)
        build = re.search(r"^Build(?: or commit)?:\s*(\S.+?)\s*$", text, re.MULTILINE | re.IGNORECASE)
        media_paths = [resolve_project_path(root, raw) for raw in MEDIA_PATH_PATTERN.findall(text)]
        media_paths = [item for item in media_paths if item is not None and is_within(root, item)]
        hash_match = re.search(r"^Evidence SHA-256:\s*([0-9a-f]{64})\s*$", text, re.MULTILINE | re.IGNORECASE)
        valid_media = []
        for media_path in media_paths:
            errors, _ = validate_media(media_path, expected_kind=expected_kind)
            if not errors:
                valid_media.append(media_path)
        hash_ok = bool(hash_match and valid_media and any(sha256_file(item) == hash_match.group(1).lower() for item in valid_media))
        if status and status.group(1).strip().lower() in PASS_STATUSES and gate_pass and reviewer and build and valid_media and hash_ok and "[path]" not in text:
            return
    blockers.append(issue(code, f"No passing {pattern} review found", review_dir))


def validate_quality(root: Path, blockers: list[dict], warnings: list[dict], evidence: list[dict]) -> Optional[dict]:
    manifest_path = root / "production/quality-command-manifest.json"
    report_path = root / "production/evidence/quality-run.json"
    manifest = load_json(manifest_path, blockers, "quality.manifest")
    report = load_json(report_path, blockers, "quality.report")
    if manifest is None or report is None:
        return report
    if report.get("manifest_sha256") != sha256_file(manifest_path):
        blockers.append(issue("quality.manifest_changed", "Quality report does not match the current command manifest", report_path))
    current_fingerprint = project_fingerprint(root)
    if report.get("project_fingerprint") != current_fingerprint:
        blockers.append(issue("quality.project_changed", "Project code/scenes/tests changed after the quality run", report_path))
    current_commit = git_commit(root)
    if current_commit and report.get("git_commit") and report.get("git_commit") != current_commit:
        blockers.append(issue("quality.commit_changed", "Quality report was produced for a different commit", report_path))
    if report.get("git_dirty"):
        warnings.append(issue("quality.dirty_run", "Quality commands were run from a dirty worktree", report_path))

    godot = report.get("godot") if isinstance(report.get("godot"), dict) else {}
    detected_version = str(godot.get("version", ""))
    policy_path = SCRIPT_DIR.parent.parent / "references/policies/godot-version-policy.json"
    policy = load_json(policy_path, blockers, "godot_policy")
    supported = policy.get("supported_minor_lines", []) if policy else []
    version_match = re.match(r"^(\d+\.\d+)", detected_version)
    if godot.get("status") != "PASS" or not version_match or version_match.group(1) not in supported:
        blockers.append(issue("quality.godot_version_invalid", f"Quality evidence must probe a supported Godot binary; detected: {detected_version or 'none'}", report_path))

    manifest_commands = by_id(manifest.get("commands"))
    if len(manifest_commands) != len(manifest.get("commands", [])):
        blockers.append(issue("quality.command_duplicate", "Quality command IDs must be unique", manifest_path))
    results = command_results(report)
    for command_id in sorted(REQUIRED_COMMANDS):
        command = manifest_commands.get(command_id)
        result = results.get(command_id)
        if not command or not isinstance(command.get("argv"), list) or not command.get("argv"):
            blockers.append(issue("quality.command_missing", f"Required executable command is not configured: {command_id}", manifest_path))
            continue
        if not result or result.get("status") != "PASS" or result.get("returncode") != 0:
            blockers.append(issue("quality.command_failed", f"Required command did not pass: {command_id}", report_path))
            continue
        if result.get("command_sha256") != sha256_json(command):
            blockers.append(issue("quality.command_changed", f"Command evidence is not bound to the current command row: {command_id}", report_path))
        argv = result.get("argv")
        if not isinstance(argv, list) or not argv or not all(isinstance(item, str) and item for item in argv):
            blockers.append(issue("quality.argv_missing", f"Command {command_id} has no recorded argv", report_path))
        try:
            output_bytes = int(result.get("output_bytes", 0) or 0)
        except (TypeError, ValueError):
            output_bytes = 0
        artifacts = result.get("artifacts") if isinstance(result.get("artifacts"), list) else []
        if output_bytes <= 0 and not artifacts:
            blockers.append(issue("quality.evidence_empty", f"Command {command_id} produced no log or artifact evidence", report_path))
        if command_id == "godot_import":
            raw_argv = command.get("argv") if isinstance(command.get("argv"), list) else []
            if not any("{godot}" in item or "godot" in Path(item).name.lower() for item in raw_argv):
                blockers.append(issue("quality.godot_command_missing", "godot_import must invoke the configured Godot executable", manifest_path))
        for stream in ("stdout", "stderr"):
            log_path = resolve_project_path(root, str(result.get(stream, "")))
            expected_hash = str(result.get(f"{stream}_sha256", ""))
            if log_path is None or not log_path.is_file() or not expected_hash or sha256_file(log_path) != expected_hash:
                blockers.append(issue("quality.log_invalid", f"Command {command_id} has missing or changed {stream} evidence", log_path))
        for artifact in result.get("artifacts", []) if isinstance(result.get("artifacts"), list) else []:
            path = resolve_project_path(root, str(artifact.get("path", ""))) if isinstance(artifact, dict) else None
            if path is None or not path.exists() or not artifact.get("sha256") or sha256_path(path) != artifact.get("sha256"):
                blockers.append(issue("quality.artifact_invalid", f"Command {command_id} has invalid artifact evidence", path))
        evidence.append({"code": "quality.command", "id": command_id, "duration_seconds": result.get("duration_seconds")})
    return report


def evaluate(root: Path, strict: bool = False) -> dict:
    root = root.resolve()
    blockers: list[dict] = []
    warnings: list[dict] = []
    evidence: list[dict] = []

    require_file(root, "project.godot", blockers)

    for relative, code in (
        ("production/player-ready-contract.md", "contract"),
        ("design/gdd/game-concept.md", "concept"),
        ("design/art/art-bible.md", "art_bible"),
        ("docs/architecture/architecture.md", "architecture"),
        ("docs/architecture/control-manifest.md", "controls"),
    ):
        require_ready_markdown(root / relative, blockers, code)

    contract_path = root / "production/player-ready-contract.md"
    contract_text = contract_path.read_text(encoding="utf-8-sig") if contract_path.is_file() else None
    if contract_text and re.search(r"^- \[ \]", contract_text, re.MULTILINE):
        blockers.append(issue("contract.unchecked", "Player-ready contract has unchecked required items", contract_path))

    project = root / "project.godot"
    if project.is_file():
        project_text = project.read_text(encoding="utf-8-sig")
        match = re.search(r'^\s*run/main_scene\s*=\s*"([^"]+)"', project_text, re.MULTILINE)
        if not match:
            blockers.append(issue("godot.main_scene.missing", "run/main_scene is not configured", project))
        else:
            scene = resolve_project_path(root, match.group(1))
            if scene is None or not is_within(root, scene) or not scene.is_file():
                blockers.append(issue("godot.main_scene.not_found", f"Main scene is missing: {match.group(1)}", scene))
            else:
                evidence.append({"code": "godot.main_scene", "path": str(scene)})

    runtime_media: list[Path] = []
    states = load_json(root / "design/game-state-matrix.json", blockers, "states")
    if states is not None:
        rows = states.get("states")
        if not isinstance(rows, dict):
            blockers.append(issue("states.invalid", "states must be an object", "design/game-state-matrix.json"))
        else:
            for state in sorted(REQUIRED_STATES):
                row = rows.get(state)
                if not isinstance(row, dict):
                    blockers.append(issue("state.missing", f"Missing required state: {state}", "design/game-state-matrix.json"))
                    continue
                if not status_ok(row.get("status")):
                    blockers.append(issue("state.incomplete", f"State {state} is not verified", "design/game-state-matrix.json"))
                scene = resolve_project_path(root, str(row.get("scene", "")))
                if scene is None or not is_within(root, scene) or not scene.is_file():
                    blockers.append(issue("state.scene_missing", f"State {state} has no valid scene/path", scene))
                runtime_media.extend(require_artifacts(
                    root, row.get("evidence"), blockers, "state.evidence", f"State {state} has no runtime evidence",
                    "design/game-state-matrix.json", media_only=True, media_minimum=True,
                ))
    unique_runtime = {sha256_file(path) for path in runtime_media if path.is_file()}
    for path in runtime_media:
        if sniff_media(path).get("kind") not in {"image", "video"}:
            blockers.append(issue("state.evidence_not_visual", "State evidence must be an image or video", path))
    if len(unique_runtime) < 5:
        blockers.append(issue("state.evidence_not_distinct", "Required states need at least five distinct runtime captures", "design/game-state-matrix.json", distinct=len(unique_runtime)))

    coverage = load_json(root / "design/assets/asset-coverage.json", blockers, "assets")
    integrated_asset_hashes: set[str] = set()
    if coverage is not None:
        groups = by_id(coverage.get("groups"))
        for group_id in sorted(REQUIRED_GROUPS):
            group = groups.get(group_id)
            if not group:
                blockers.append(issue("assets.group_missing", f"Missing asset group: {group_id}", "design/assets/asset-coverage.json"))
                continue
            if group.get("required", True) and not status_ok(group.get("status")):
                blockers.append(issue("assets.group_incomplete", f"Asset group {group_id} is not verified", "design/assets/asset-coverage.json"))
            assets = group.get("assets")
            required_ids = {str(item) for item in group.get("required_asset_ids", []) if str(item)} if isinstance(group.get("required_asset_ids"), list) else set()
            if group.get("required", True) and (not required_ids or not str(group.get("coverage_basis", "")).strip()):
                blockers.append(issue("assets.coverage_contract_missing", f"Asset group {group_id} needs coverage_basis and required_asset_ids", "design/assets/asset-coverage.json"))
            actual_ids = {str(item.get("id")) for item in assets if isinstance(item, dict) and item.get("id")} if isinstance(assets, list) else set()
            for missing_id in sorted(required_ids - actual_ids):
                blockers.append(issue("assets.required_asset_missing", f"Asset group {group_id} is missing required asset {missing_id}", "design/assets/asset-coverage.json"))
            if group.get("required", True) and (not isinstance(assets, list) or not assets):
                blockers.append(issue("assets.empty", f"Required asset group {group_id} is empty", "design/assets/asset-coverage.json"))
            if group.get("required", True):
                require_artifacts(root, group.get("evidence"), blockers, "assets.evidence", f"Asset group {group_id} has no runtime evidence", "design/assets/asset-coverage.json", media_only=True, media_minimum=True)
            for asset in assets if isinstance(assets, list) else []:
                if not isinstance(asset, dict) or not status_ok(asset.get("status")):
                    blockers.append(issue("asset.incomplete", f"Asset in {group_id} is not verified", "design/assets/asset-coverage.json"))
                    continue
                path = resolve_project_path(root, str(asset.get("path", "")))
                if path is None or not is_within(root, path):
                    blockers.append(issue("asset.path_missing", f"Asset in {group_id} has no path", "design/assets/asset-coverage.json"))
                    continue
                errors, _ = validate_artifact(path)
                for error in errors:
                    blockers.append(issue("asset.invalid", f"Invalid integrated asset: {error}", path))
                if not errors and path.is_file():
                    integrated_asset_hashes.add(sha256_file(path))
                provenance = resolve_project_path(root, str(asset.get("provenance", "")))
                if provenance is None or not is_within(root, provenance) or not provenance.is_file() or provenance.stat().st_size == 0:
                    blockers.append(issue("asset.provenance_missing", f"Asset in {group_id} has no valid provenance/license record", provenance))
                elif not re.search(r"\b(source|author|generated|license|rights)\b", provenance.read_text(encoding="utf-8-sig"), re.IGNORECASE):
                    blockers.append(issue("asset.provenance_incomplete", f"Asset in {group_id} provenance does not record source/license/rights", provenance))
                runtime_refs = asset.get("runtime_refs")
                if not isinstance(runtime_refs, list) or not runtime_refs:
                    blockers.append(issue("asset.runtime_refs_missing", f"Asset in {group_id} has no runtime integration references", "design/assets/asset-coverage.json"))
                else:
                    for raw_ref in runtime_refs:
                        runtime_ref = resolve_project_path(root, str(raw_ref))
                        if runtime_ref is None or not is_within(root, runtime_ref) or not runtime_ref.exists():
                            blockers.append(issue("asset.runtime_ref_invalid", f"Missing runtime reference: {raw_ref}", runtime_ref))
    if coverage is not None and len(integrated_asset_hashes) < 4:
        blockers.append(issue("assets.not_distinct", "Player-ready asset coverage needs at least four distinct integrated production assets", "design/assets/asset-coverage.json", distinct=len(integrated_asset_hashes)))

    ui_path = root / "design/ui/ui-ux-spec.md"
    if ui_path.is_file():
        ui_text = ui_path.read_text(encoding="utf-8-sig")
        ui_status = re.search(r"^Status:\s*(.+?)\s*$", ui_text, re.MULTILINE | re.IGNORECASE)
        if not ui_status or ui_status.group(1).strip().lower() not in PASS_STATUSES or "[Game Title]" in ui_text:
            blockers.append(issue("ui.template_incomplete", "UI spec is not verified or still contains the template title", ui_path))
        for section in sorted(UI_SECTIONS):
            if not re.search(rf"^##\s+{re.escape(section)}\s*$", ui_text, re.MULTILINE):
                blockers.append(issue("ui.section_missing", f"UI spec missing section: {section}", ui_path))
        remaining = [marker for marker in UI_TEMPLATE_MARKERS if re.search(rf"^{re.escape(marker)}\s*$", ui_text, re.MULTILINE)]
        if remaining:
            blockers.append(issue("ui.placeholder", f"UI spec has {len(remaining)} unfilled template fields", ui_path))
        for line in ui_text.splitlines():
            if not line.startswith("|") or re.match(r"^\|[- :|]+\|$", line) or "State |" in line:
                continue
            cells = [cell.strip() for cell in line.strip("|").split("|")]
            if len(cells) >= 5 and any(not cell for cell in cells[:5]):
                blockers.append(issue("ui.screen_row_incomplete", f"UI inventory row is incomplete: {line}", ui_path))
        theme_match = re.search(r"^Theme resource:\s*(\S+)\s*$", ui_text, re.MULTILINE | re.IGNORECASE)
        theme_path = resolve_project_path(root, theme_match.group(1)) if theme_match else None
        if theme_path is None or not is_within(root, theme_path) or not theme_path.is_file() or "Theme" not in theme_path.read_text(encoding="utf-8-sig"):
            blockers.append(issue("ui.theme_missing", "UI spec must reference an implemented Godot Theme resource", theme_path or ui_path))

    audio = load_json(root / "design/audio/audio-manifest.json", blockers, "audio")
    audio_hashes: set[str] = set()
    if audio is not None:
        if audio.get("intentional_silence"):
            if not str(audio.get("silence_rationale", "")).strip():
                blockers.append(issue("audio.silence_unjustified", "Intentional silence needs a rationale", "design/audio/audio-manifest.json"))
        else:
            buses = audio.get("buses")
            if not isinstance(buses, list) or not {"Master", "Music", "SFX", "UI"}.issubset(set(buses)):
                blockers.append(issue("audio.buses_missing", "Required audio buses are missing", "design/audio/audio-manifest.json"))
            events = by_id(audio.get("events"))
            for event_id in sorted(REQUIRED_AUDIO):
                event = events.get(event_id)
                if not event or not status_ok(event.get("status")):
                    blockers.append(issue("audio.event_incomplete", f"Audio event {event_id} is not verified", "design/audio/audio-manifest.json"))
                    continue
                path = resolve_project_path(root, str(event.get("asset", "")))
                if path is None or not is_within(root, path):
                    blockers.append(issue("audio.asset_missing", f"Audio event {event_id} has no asset", path))
                else:
                    errors, _ = validate_media(path, expected_kind="audio", min_size=128)
                    for error in errors:
                        blockers.append(issue("audio.asset_invalid", f"Audio event {event_id}: {error}", path))
                    if not errors:
                        audio_hashes.add(sha256_file(path))
                if not str(event.get("trigger", "")).strip():
                    blockers.append(issue("audio.trigger_missing", f"Audio event {event_id} has no trigger", "design/audio/audio-manifest.json"))
        require_artifacts(root, audio.get("evidence"), blockers, "audio.evidence", "Audio manifest has no listening/runtime evidence", "design/audio/audio-manifest.json")
        if not audio.get("intentional_silence") and len(audio_hashes) < 4:
            blockers.append(issue("audio.not_distinct", "Player-ready audio needs at least four distinct integrated sounds across music, ambience, UI, gameplay, and outcomes", "design/audio/audio-manifest.json", distinct=len(audio_hashes)))

    test_files = list((root / "tests").glob("**/*.gd")) if (root / "tests").is_dir() else []
    if not test_files:
        blockers.append(issue("tests.missing", "No Godot tests found under tests/", root / "tests"))
    else:
        evidence.append({"code": "tests.present", "count": len(test_files)})

    playtest_files = list((root / "production/playtests").glob("*.md")) if (root / "production/playtests").is_dir() else []
    passing_playtests = []
    for path in playtest_files:
        text = path.read_text(encoding="utf-8-sig")
        status = re.search(r"^Status:\s*(.+?)\s*$", text, re.MULTILINE | re.IGNORECASE)
        tester = re.search(r"^Tester:\s*(\S.+?)\s*$", text, re.MULTILINE | re.IGNORECASE)
        build = re.search(r"^Build(?: or commit)?:\s*(\S.+?)\s*$", text, re.MULTILINE | re.IGNORECASE)
        media = [resolve_project_path(root, raw) for raw in MEDIA_PATH_PATTERN.findall(text)]
        media = [item for item in media if item is not None and is_within(root, item) and item.is_file()]
        hash_match = re.search(r"^Media SHA-256:\s*([0-9a-f]{64})\s*$", text, re.MULTILINE | re.IGNORECASE)
        hash_ok = bool(hash_match and any(sha256_file(item) == hash_match.group(1).lower() for item in media))
        if status and status.group(1).strip().lower() in PASS_STATUSES and tester and build and media and hash_ok and re.search(r"^Gate:\s*PASS\s*$", text, re.MULTILINE | re.IGNORECASE) and "[path]" not in text and "[what " not in text:
            passing_playtests.append(path)
    if not passing_playtests:
        blockers.append(issue("playtest.missing", "No complete manual playtest with Gate: PASS found", root / "production/playtests"))
    else:
        evidence.append({"code": "playtests.pass", "count": len(passing_playtests)})

    require_pass_review(root, "*visual*.md", "visual.review_missing", "image", blockers)
    require_pass_review(root, "*audio*.md", "audio.review_missing", "audio", blockers)
    validate_quality(root, blockers, warnings, evidence)

    report = load_json(root / "production/evidence/player-ready.json", blockers, "evidence")
    if report is not None:
        checks = report.get("checks")
        if not isinstance(checks, dict):
            blockers.append(issue("evidence.checks_invalid", "checks must be an object", "production/evidence/player-ready.json"))
        else:
            for check in sorted(REQUIRED_EVIDENCE):
                if str(checks.get(check, "")).upper() != "PASS":
                    blockers.append(issue("evidence.not_passed", f"Evidence check {check} is not PASS", "production/evidence/player-ready.json"))
        require_artifacts(root, report.get("artifacts"), blockers, "evidence.artifacts", "No player-ready artifacts recorded", "production/evidence/player-ready.json")
        expected_links = {
            "quality_report": "production/evidence/quality-run.json",
            "visual_review": "production/reviews/visual-quality.md",
            "audio_review": "production/reviews/audio-listening.md",
        }
        for field, expected in expected_links.items():
            if report.get(field) != expected or not (root / expected).is_file():
                blockers.append(issue("evidence.link_invalid", f"Player-ready evidence field {field} must reference {expected}", "production/evidence/player-ready.json"))

    dirty = git_dirty(root)
    if dirty:
        warnings.append(issue("git.dirty", "Worktree is dirty; commercial release will block", root))
    if strict and warnings:
        blockers.append(issue("strict.warnings", "Strict mode treats warnings as blockers", root))
    return report_gate(root, blockers, warnings, evidence)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".")
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()
    report = evaluate(Path(args.root), strict=args.strict)
    print(json.dumps(report, indent=2))
    return 1 if report["gate"] == "BLOCKED" else 0


if __name__ == "__main__":
    raise SystemExit(main())
