#!/usr/bin/env python3
"""Cross-platform, media-aware and command-backed player-ready gate for Godot games."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any, Optional


SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR.parent / "lib"))

from cgm_validation import (  # noqa: E402
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


REQUIRED_QUALITY_KINDS = {"engine_import", "static_analysis", "reliability"}
UI_MODES = {"godot-theme", "diegetic", "custom-draw", "hybrid", "intentionally-minimal"}
VISUAL_SURFACE_CHECKS = {
    "art_bible_coherence", "cross_asset_coherence", "composition_hierarchy",
    "text_legibility", "no_overlap_or_clipping", "asset_scale_grounding",
    "safe_zones", "input_focus_feedback", "no_placeholder_or_generic_ui",
    "no_distorted_textures",
}
VISUAL_CROSS_SURFACE_CHECKS = {
    "world_character_scale", "world_character_palette_lighting",
    "world_ui_material_language", "component_reuse_without_monotony",
    "typography_hierarchy", "motion_fx_language",
}
VISUAL_SOURCE_MODES = {"generated", "authored", "sourced", "user-provided", "procedural", "mixed"}
ASSET_SOURCE_KINDS = {"dedicated-component", "sprite-sheet", "tileable", "full-frame", "procedural", "sourced"}
ASSET_RENDER_MODES = {"uniform", "native", "sprite-frame", "nine-slice", "tile", "cover", "procedural"}
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
    "Visual/layout smoke command ID:",
    "| [component-id] | [dedicated-component] | [uniform / nine-slice / tile / cover / custom] | [size] | [min / max] | [rect] | [runtime capture] |",
}


def require_file(root: Path, relative: str, blockers: list[dict]) -> None:
    path = root / relative
    if not path.is_file():
        blockers.append(issue("required.missing", f"Missing required file: {relative}", path))


def require_pass_review(
    root: Path,
    pattern: str,
    code: str,
    expected_kinds: set[str],
    blockers: list[dict],
) -> None:
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
            errors, info = validate_media(media_path)
            if not errors and info.get("kind") in expected_kinds:
                valid_media.append(media_path)
        hash_ok = bool(hash_match and valid_media and any(sha256_file(item) == hash_match.group(1).lower() for item in valid_media))
        if status and status.group(1).strip().lower() in PASS_STATUSES and gate_pass and reviewer and build and valid_media and hash_ok and "[path]" not in text:
            return
    blockers.append(issue(code, f"No passing {pattern} review found", review_dir))


def reachable(adjacency: dict[str, set[str]], start: str) -> set[str]:
    visited: set[str] = set()
    pending = [start]
    while pending:
        current = pending.pop()
        if current in visited:
            continue
        visited.add(current)
        pending.extend(adjacency.get(current, set()) - visited)
    return visited


def state_evidence_keys(root: Path, rows: Any, valid_paths: list[Path]) -> set[str]:
    valid = {path.resolve() for path in valid_paths}
    keys: set[str] = set()
    for raw in rows if isinstance(rows, list) else []:
        raw_path = raw.get("path", "") if isinstance(raw, dict) else raw
        marker = str(raw.get("marker", "")).strip() if isinstance(raw, dict) else ""
        path = resolve_project_path(root, str(raw_path))
        if path is None or path.resolve() not in valid or not path.is_file():
            continue
        media = sniff_media(path)
        digest = sha256_file(path)
        if media.get("kind") == "video" and marker:
            keys.add(f"{digest}#{marker}")
        else:
            keys.add(digest)
    return keys


def validate_state_contract(
    root: Path,
    blockers: list[dict],
    evidence: list[dict],
) -> tuple[Optional[dict], set[str], set[str], set[str], set[str]]:
    path = root / "design/game-state-matrix.json"
    data = load_json(path, blockers, "states")
    required_commands: set[str] = set()
    godot_commands: set[str] = set()
    evidence_checks: set[str] = set()
    ui_states: set[str] = set()
    if data is None:
        return None, required_commands, godot_commands, evidence_checks, ui_states
    if data.get("schema_version") != 2:
        blockers.append(issue("states.schema", "game-state-matrix.json must use schema_version 2 with dynamic states, transitions, journeys, and requirements", path))
        return data, required_commands, godot_commands, evidence_checks, ui_states

    raw_states = data.get("states")
    if not isinstance(raw_states, list) or not raw_states:
        blockers.append(issue("states.invalid", "states must be a non-empty array", path))
        return data, required_commands, godot_commands, evidence_checks, ui_states
    states = by_id(raw_states)
    if len(states) != len(raw_states):
        blockers.append(issue("states.duplicate", "Every state needs a unique non-empty id", path))
    adjacency: dict[str, set[str]] = {state_id: set() for state_id in states}
    required_states: set[str] = set()
    required_state_keys: dict[str, set[str]] = {}

    for state_id, row in states.items():
        if row.get("required", True):
            required_states.add(state_id)
        if not status_ok(row.get("status")):
            blockers.append(issue("state.incomplete", f"State {state_id} is not verified", path))
        if not str(row.get("role", "")).strip():
            blockers.append(issue("state.role_missing", f"State {state_id} needs a game-specific role", path))
        scene = resolve_project_path(root, str(row.get("scene", "")))
        if scene is None or not is_within(root, scene) or not scene.is_file():
            blockers.append(issue("state.scene_missing", f"State {state_id} has no valid project-local scene/path", scene))
        valid_media = require_artifacts(
            root,
            row.get("evidence"),
            blockers,
            "state.evidence",
            f"State {state_id} has no runtime evidence",
            path,
            media_only=True,
            media_minimum=True,
        )
        if row.get("required", True):
            required_state_keys[state_id] = state_evidence_keys(root, row.get("evidence"), valid_media)
        if row.get("ui_surface"):
            ui_states.add(state_id)
        transitions = row.get("transitions")
        if not isinstance(transitions, list):
            blockers.append(issue("state.transitions_invalid", f"State {state_id} transitions must be an array", path))
            continue
        for transition in transitions:
            if not isinstance(transition, dict):
                blockers.append(issue("state.transition_invalid", f"State {state_id} has an invalid transition", path))
                continue
            target = str(transition.get("to", "")).strip()
            trigger = str(transition.get("trigger", "")).strip()
            if target not in states:
                blockers.append(issue("state.transition_target", f"State {state_id} points to missing state {target or '<empty>'}", path))
                continue
            if not trigger:
                blockers.append(issue("state.transition_trigger", f"Transition {state_id} -> {target} has no trigger/condition", path))
            adjacency[state_id].add(target)

    journeys_raw = data.get("journeys")
    journeys = by_id(journeys_raw)
    if not isinstance(journeys_raw, list) or not journeys or len(journeys) != len(journeys_raw):
        blockers.append(issue("journey.invalid", "journeys must be a non-empty array with unique IDs", path))
    covered_states: set[str] = set()
    for journey_id, journey in journeys.items():
        if not journey.get("required", True):
            continue
        start = str(journey.get("start_state", "")).strip()
        journey_states = {str(item) for item in journey.get("required_states", []) if str(item)} if isinstance(journey.get("required_states"), list) else set()
        completion_states = {str(item) for item in journey.get("completion_states", []) if str(item)} if isinstance(journey.get("completion_states"), list) else set()
        goal = str(journey.get("goal", "")).strip()
        if start not in states or not journey_states or not completion_states or not goal:
            blockers.append(issue("journey.contract_incomplete", f"Journey {journey_id} needs a concrete goal, valid start, required_states, and completion_states", path))
            continue
        unknown = (journey_states | completion_states) - set(states)
        for state_id in sorted(unknown):
            blockers.append(issue("journey.state_missing", f"Journey {journey_id} references missing state {state_id}", path))
        if unknown:
            continue
        visited = reachable(adjacency, start)
        for state_id in sorted((journey_states | completion_states) - visited):
            blockers.append(issue("journey.unreachable", f"Journey {journey_id} cannot reach required state {state_id} from {start}", path))
        if not completion_states.intersection(visited):
            blockers.append(issue("journey.no_completion", f"Journey {journey_id} has no reachable completion state", path))
        covered_states.update(journey_states | completion_states | {start})
        command_id = str(journey.get("test_command_id", "")).strip()
        if not command_id:
            blockers.append(issue("journey.test_missing", f"Journey {journey_id} needs an executable test_command_id", path))
        else:
            required_commands.add(command_id)
        require_artifacts(root, journey.get("evidence"), blockers, "journey.evidence", f"Journey {journey_id} has no end-to-end runtime evidence", path, media_only=True, media_minimum=True)
        recoveries = journey.get("recovery_paths", [])
        if not isinstance(recoveries, list):
            blockers.append(issue("journey.recovery_invalid", f"Journey {journey_id} recovery_paths must be an array", path))
            recoveries = []
        for recovery in recoveries:
            if not isinstance(recovery, dict) or not recovery.get("required", True):
                continue
            source = str(recovery.get("from", "")).strip()
            target = str(recovery.get("to", "")).strip()
            recovery_reachable = reachable(adjacency, source) if source in states else set()
            if source not in states or target not in states or source not in visited or target not in recovery_reachable:
                blockers.append(issue("journey.recovery_unreachable", f"Journey {journey_id} recovery path {source} -> {target} is not reachable", path))
            elif not completion_states.intersection(reachable(adjacency, target)):
                blockers.append(issue("journey.recovery_no_completion", f"Journey {journey_id} recovery target {target} cannot return to a declared completion state", path))
            recovery_command = str(recovery.get("test_command_id", "")).strip()
            if not recovery_command:
                blockers.append(issue("journey.recovery_test_missing", f"Journey {journey_id} recovery {source} -> {target} needs test_command_id", path))
            else:
                required_commands.add(recovery_command)

    for state_id in sorted(required_states - covered_states):
        blockers.append(issue("state.uncovered", f"Required state {state_id} is not covered by a required journey", path))
    evidence_owners: dict[str, set[str]] = {}
    for state_id, keys in required_state_keys.items():
        for key in keys:
            evidence_owners.setdefault(key, set()).add(state_id)
    for state_id in sorted(required_states):
        keys = required_state_keys.get(state_id, set())
        if not any(evidence_owners.get(key) == {state_id} for key in keys):
            blockers.append(issue("state.evidence_not_distinct", f"Required state {state_id} needs at least one image or marked video segment not reused by another required state", path, state_id=state_id))

    requirements_raw = data.get("experience_requirements")
    requirements = by_id(requirements_raw)
    if not isinstance(requirements_raw, list) or not requirements or len(requirements) != len(requirements_raw):
        blockers.append(issue("experience.invalid", "experience_requirements must be a non-empty array with unique game-specific IDs", path))
    for requirement_id, requirement in requirements.items():
        if not requirement.get("required", True):
            continue
        fulfilled = {str(item) for item in requirement.get("fulfilled_by", []) if str(item)} if isinstance(requirement.get("fulfilled_by"), list) else set()
        if not str(requirement.get("rationale", "")).strip() or not fulfilled:
            blockers.append(issue("experience.contract_incomplete", f"Requirement {requirement_id} needs rationale and fulfilled_by states", path))
        for state_id in sorted(fulfilled - set(states)):
            blockers.append(issue("experience.state_missing", f"Requirement {requirement_id} references missing state {state_id}", path))
        require_artifacts(root, requirement.get("evidence"), blockers, "experience.evidence", f"Requirement {requirement_id} has no evidence", path)

    quality_raw = data.get("quality_requirements")
    quality = by_id(quality_raw)
    kinds: set[str] = set()
    if not isinstance(quality_raw, list) or not quality or len(quality) != len(quality_raw):
        blockers.append(issue("quality.contract_invalid", "quality_requirements must be a non-empty array with unique IDs", path))
    for row in quality.values():
        if not row.get("required", True):
            continue
        kind = str(row.get("kind", "")).strip()
        command_id = str(row.get("command_id", "")).strip()
        kinds.add(kind)
        if not command_id:
            blockers.append(issue("quality.contract_command_missing", f"Quality requirement {row.get('id')} needs command_id", path))
        else:
            required_commands.add(command_id)
            if kind == "engine_import":
                godot_commands.add(command_id)
    for kind in sorted(REQUIRED_QUALITY_KINDS - kinds):
        blockers.append(issue("quality.contract_kind_missing", f"Missing universal quality requirement kind: {kind}", path))

    checks = data.get("required_evidence_checks")
    if not isinstance(checks, list) or not checks or not all(isinstance(item, str) and item.strip() for item in checks):
        blockers.append(issue("evidence.contract_invalid", "required_evidence_checks must declare this game's completion evidence", path))
    elif len(set(checks)) != len(checks):
        blockers.append(issue("evidence.contract_duplicate", "required_evidence_checks must use unique check IDs", path))
    else:
        evidence_checks = {item.strip() for item in checks}
    evidence.append({"code": "journey.graph", "states": len(states), "required_states": len(required_states), "journeys": len(journeys)})
    return data, required_commands, godot_commands, evidence_checks, ui_states


def validate_visual_contract(
    root: Path,
    state_contract: Optional[dict],
    blockers: list[dict],
    evidence: list[dict],
) -> tuple[set[str], dict[str, set[str]]]:
    path = root / "production/reviews/visual-quality-contract.json"
    data = load_json(path, blockers, "visual_contract")
    required_commands: set[str] = set()
    command_artifacts: dict[str, set[str]] = {}
    if data is None:
        return required_commands, command_artifacts
    if data.get("schema_version") != 1 or not status_ok(data.get("status")):
        blockers.append(issue("visual_contract.status", "Visual quality contract must use schema_version 1 and verified status", path))
    for field in ("reviewer", "reviewer_independence", "build", "review_method"):
        if not str(data.get(field, "")).strip():
            blockers.append(issue("visual_contract.metadata", f"Visual quality contract needs {field}", path))
    if str(data.get("reviewer_mode", "")).strip().lower() not in {"human", "independent-agent"}:
        blockers.append(issue("visual_contract.reviewer_not_independent", "Final visual PASS requires human or independent-agent review, not production self-review", path))

    raw_viewports = data.get("required_viewports")
    viewports = by_id(raw_viewports)
    if not isinstance(raw_viewports, list) or not viewports or len(viewports) != len(raw_viewports):
        blockers.append(issue("visual_contract.viewports", "required_viewports must be a non-empty array with unique IDs", path))
    valid_viewports: dict[str, tuple[int, int]] = {}
    for viewport_id, viewport in viewports.items():
        try:
            width = int(viewport.get("width", 0))
            height = int(viewport.get("height", 0))
        except (TypeError, ValueError):
            width, height = 0, 0
        if width < 320 or height < 180 or not str(viewport.get("device", "")).strip():
            blockers.append(issue("visual_contract.viewport_invalid", f"Viewport {viewport_id} needs target dimensions and device", path))
        else:
            valid_viewports[viewport_id] = (width, height)

    direction = data.get("art_direction") if isinstance(data.get("art_direction"), dict) else {}
    if not str(direction.get("identity_rule", "")).strip():
        blockers.append(issue("visual_contract.identity_missing", "art_direction needs a concrete identity_rule", path))
    for field in ("materials", "shape_language", "palette_roles", "typography_roles", "forbidden_patterns"):
        values = direction.get(field)
        if not isinstance(values, list) or not values or not all(str(item).strip() for item in values):
            blockers.append(issue("visual_contract.direction_incomplete", f"art_direction needs non-empty {field}", path))

    lookdev = data.get("lookdev") if isinstance(data.get("lookdev"), dict) else {}
    source_mode = str(lookdev.get("source_mode", "")).strip().lower()
    candidates = {str(item) for item in lookdev.get("candidate_ids", []) if str(item)} if isinstance(lookdev.get("candidate_ids"), list) else set()
    accepted = {str(item) for item in lookdev.get("accepted_candidate_ids", []) if str(item)} if isinstance(lookdev.get("accepted_candidate_ids"), list) else set()
    rejected = {str(item) for item in lookdev.get("rejected_candidate_ids", []) if str(item)} if isinstance(lookdev.get("rejected_candidate_ids"), list) else set()
    candidate_rows = by_id(lookdev.get("candidate_evidence"))
    accepted_candidate_paths: set[Path] = set()
    representative = {str(item) for item in lookdev.get("representative_asset_ids", []) if str(item)} if isinstance(lookdev.get("representative_asset_ids"), list) else set()
    if source_mode not in VISUAL_SOURCE_MODES or not status_ok(lookdev.get("status")) or not representative or not str(lookdev.get("decision_rationale", "")).strip():
        blockers.append(issue("visual_contract.lookdev_incomplete", "Look-dev needs a valid source mode, verified status, representative assets, and decision rationale", path))
    if source_mode in {"generated", "mixed"} and (len(candidates) < 2 or not accepted or not rejected or not accepted.issubset(candidates) or not rejected.issubset(candidates)):
        blockers.append(issue("visual_contract.lookdev_candidates", "Generated look-dev must compare at least two candidates and record accepted and rejected candidate IDs", path))
    if source_mode in {"generated", "mixed"}:
        if set(candidate_rows) != candidates:
            blockers.append(issue("visual_contract.lookdev_candidate_evidence", "Every generated look-dev candidate ID needs one evidence row", path))
        for candidate_id, candidate in candidate_rows.items():
            outcome = str(candidate.get("outcome", "")).strip().lower()
            candidate_path = resolve_project_path(root, str(candidate.get("path", "")))
            candidate_hash = str(candidate.get("sha256", "")).strip().lower()
            errors, _ = validate_media(candidate_path, expected_kind="image", min_width=320, min_height=180) if candidate_path and is_within(root, candidate_path) else (["candidate is missing or outside project"], {})
            if errors or outcome not in {"accepted", "rejected"} or not candidate_hash or sha256_file(candidate_path) != candidate_hash:
                blockers.append(issue("visual_contract.lookdev_candidate_evidence", f"Look-dev candidate {candidate_id} needs valid image, hash, and accepted/rejected outcome", candidate_path))
            elif outcome == "accepted":
                accepted_candidate_paths.add(candidate_path)
            if (outcome == "accepted") != (candidate_id in accepted) or (outcome == "rejected") != (candidate_id in rejected):
                blockers.append(issue("visual_contract.lookdev_candidate_outcome", f"Look-dev candidate {candidate_id} outcome disagrees with accepted/rejected IDs", path))
    locked_paths = require_artifacts(root, lookdev.get("locked_reference_paths"), blockers, "visual_contract.lookdev_reference", "Look-dev has no locked project-local visual reference", path, media_only=True)
    require_artifacts(root, lookdev.get("evidence"), blockers, "visual_contract.lookdev_evidence", "Look-dev has no comparison/runtime evidence", path, media_only=True, media_minimum=True)
    if not locked_paths:
        blockers.append(issue("visual_contract.lookdev_unlocked", "Look-dev must lock at least one accepted reference image", path))
    elif source_mode in {"generated", "mixed"} and not accepted_candidate_paths.issubset({item.resolve() for item in locked_paths}):
        blockers.append(issue("visual_contract.lookdev_reference_mismatch", "Accepted generated look-dev candidates must be included in locked_reference_paths", path))

    state_rows = state_contract.get("states", []) if isinstance(state_contract, dict) else []
    required_states = {
        str(row.get("id")) for row in state_rows
        if isinstance(row, dict) and row.get("id") and row.get("required", True)
    }
    declared_states = {
        str(row.get("id")) for row in state_rows
        if isinstance(row, dict) and row.get("id")
    }
    state_evidence: dict[str, set[Path]] = {}
    for row in state_rows if isinstance(state_rows, list) else []:
        if not isinstance(row, dict) or not row.get("id"):
            continue
        paths: set[Path] = set()
        for raw in row.get("evidence", []) if isinstance(row.get("evidence"), list) else []:
            raw_path = raw.get("path", "") if isinstance(raw, dict) else raw
            resolved = resolve_project_path(root, str(raw_path))
            if resolved is not None:
                paths.add(resolved)
        state_evidence[str(row.get("id"))] = paths

    raw_surfaces = data.get("surfaces")
    surfaces = by_id(raw_surfaces)
    if not isinstance(raw_surfaces, list) or len(surfaces) != len(raw_surfaces):
        blockers.append(issue("visual_contract.surfaces_invalid", "surfaces must be an array with unique IDs", path))
    covered_states: set[str] = set()
    all_capture_paths: set[str] = set()
    for surface_id, surface in surfaces.items():
        state_id = str(surface.get("state_id", "")).strip()
        if surface_id != state_id or state_id not in declared_states:
            blockers.append(issue("visual_contract.surface_state", f"Visual surface {surface_id} must use the exact declared state ID", path))
            continue
        if state_id in required_states:
            covered_states.add(state_id)
        if not status_ok(surface.get("status")):
            blockers.append(issue("visual_contract.surface_incomplete", f"Visual surface {state_id} is not verified", path))
        raw_captures = surface.get("captures")
        capture_viewports: set[str] = set()
        if not isinstance(raw_captures, list) or not raw_captures:
            blockers.append(issue("visual_contract.capture_missing", f"Visual surface {state_id} has no captures", path))
            raw_captures = []
        for capture in raw_captures:
            if not isinstance(capture, dict):
                blockers.append(issue("visual_contract.capture_invalid", f"Visual surface {state_id} has an invalid capture row", path))
                continue
            viewport_id = str(capture.get("viewport_id", "")).strip()
            capture_viewports.add(viewport_id)
            raw_capture_path = str(capture.get("path", "")).strip()
            capture_path = resolve_project_path(root, raw_capture_path)
            expected_hash = str(capture.get("sha256", "")).strip().lower()
            errors, info = validate_media(capture_path, expected_kind="image", min_width=320, min_height=180) if capture_path and is_within(root, capture_path) else (["capture is missing or outside project"], {})
            if errors:
                for error in errors:
                    blockers.append(issue("visual_contract.capture_invalid", f"Visual surface {state_id}: {error}", capture_path))
                continue
            expected_size = valid_viewports.get(viewport_id)
            if expected_size and (info.get("width"), info.get("height")) != expected_size:
                blockers.append(issue("visual_contract.capture_size", f"Visual surface {state_id} capture does not match viewport {viewport_id}", capture_path, expected=expected_size, actual=(info.get("width"), info.get("height"))))
            if not expected_hash or sha256_file(capture_path) != expected_hash:
                blockers.append(issue("visual_contract.capture_hash", f"Visual surface {state_id} capture hash is missing or stale", capture_path))
            if capture_path not in state_evidence.get(state_id, set()):
                blockers.append(issue("visual_contract.capture_unbound", f"Visual surface {state_id} capture is not bound to that state's evidence", capture_path))
            all_capture_paths.add(raw_capture_path)
        for viewport_id in sorted(set(valid_viewports) - capture_viewports):
            blockers.append(issue("visual_contract.viewport_uncovered", f"Visual surface {state_id} has no capture for viewport {viewport_id}", path))

        checks = surface.get("checks") if isinstance(surface.get("checks"), dict) else {}
        rationales = surface.get("not_applicable_rationales") if isinstance(surface.get("not_applicable_rationales"), dict) else {}
        for check_id in sorted(VISUAL_SURFACE_CHECKS):
            status = str(checks.get(check_id, "")).strip().upper()
            if status not in {"PASS", "NOT_APPLICABLE"}:
                blockers.append(issue("visual_contract.check_failed", f"Visual surface {state_id} check {check_id} is not PASS or NOT_APPLICABLE", path))
            elif status == "NOT_APPLICABLE" and not str(rationales.get(check_id, "")).strip():
                blockers.append(issue("visual_contract.na_unjustified", f"Visual surface {state_id} check {check_id} needs an N/A rationale", path))
        for finding in surface.get("findings", []) if isinstance(surface.get("findings"), list) else []:
            if isinstance(finding, dict) and str(finding.get("severity", "")).strip().lower() in {"blocker", "high"} and str(finding.get("status", "")).strip().lower() != "resolved":
                blockers.append(issue("visual_contract.finding_open", f"Visual surface {state_id} has an unresolved {finding.get('severity')} finding", path))

    for state_id in sorted(required_states - covered_states):
        blockers.append(issue("visual_contract.state_uncovered", f"Visual contract does not review required state {state_id}", path))

    cross_checks = data.get("cross_surface_checks") if isinstance(data.get("cross_surface_checks"), dict) else {}
    cross_rationales = data.get("not_applicable_rationales") if isinstance(data.get("not_applicable_rationales"), dict) else {}
    for check_id in sorted(VISUAL_CROSS_SURFACE_CHECKS):
        status = str(cross_checks.get(check_id, "")).strip().upper()
        if status not in {"PASS", "NOT_APPLICABLE"}:
            blockers.append(issue("visual_contract.cross_check_failed", f"Cross-surface check {check_id} is not PASS or NOT_APPLICABLE", path))
        elif status == "NOT_APPLICABLE" and not str(cross_rationales.get(check_id, "")).strip():
            blockers.append(issue("visual_contract.na_unjustified", f"Cross-surface check {check_id} needs an N/A rationale", path))
    for finding in data.get("open_findings", []) if isinstance(data.get("open_findings"), list) else []:
        if isinstance(finding, dict) and str(finding.get("severity", "")).strip().lower() in {"blocker", "high"} and str(finding.get("status", "")).strip().lower() != "resolved":
            blockers.append(issue("visual_contract.finding_open", f"Visual contract has an unresolved {finding.get('severity')} finding", path))

    raw_commands = data.get("verification_commands")
    commands = by_id(raw_commands)
    if not isinstance(raw_commands, list) or not commands or len(commands) != len(raw_commands):
        blockers.append(issue("visual_contract.commands_invalid", "verification_commands must be a non-empty array with unique IDs", path))
    bound_artifacts: set[str] = set()
    for command in commands.values():
        if not command.get("required", True):
            continue
        command_id = str(command.get("command_id", "")).strip()
        expected_artifacts = {str(item) for item in command.get("expected_artifacts", []) if str(item)} if isinstance(command.get("expected_artifacts"), list) else set()
        if not command_id or not expected_artifacts:
            blockers.append(issue("visual_contract.command_incomplete", f"Visual verification command {command.get('id')} needs command_id and expected_artifacts", path))
            continue
        required_commands.add(command_id)
        command_artifacts.setdefault(command_id, set()).update(expected_artifacts)
        bound_artifacts.update(expected_artifacts)
    for raw_capture_path in sorted(all_capture_paths - bound_artifacts):
        blockers.append(issue("visual_contract.capture_command_unbound", f"Runtime capture is not bound to a visual verification command: {raw_capture_path}", path))
    evidence.append({"code": "visual.contract", "states": len(covered_states), "viewports": len(valid_viewports), "captures": len(all_capture_paths)})
    return required_commands, command_artifacts


def positive_pair(value: Any) -> Optional[tuple[float, float]]:
    if not isinstance(value, list) or len(value) != 2:
        return None
    try:
        pair = (float(value[0]), float(value[1]))
    except (TypeError, ValueError):
        return None
    return pair if pair[0] > 0 and pair[1] > 0 else None


def validate_asset_presentation(
    root: Path,
    asset_id: str,
    asset: dict,
    artifact_info: dict,
    declared_state_ids: set[str],
    blockers: list[dict],
    source: Any,
) -> None:
    presentation = asset.get("presentation") if isinstance(asset.get("presentation"), dict) else {}
    source_kind = str(presentation.get("source_kind", "")).strip().lower()
    raw_usages = presentation.get("usages")
    usages = by_id(raw_usages)
    if source_kind not in ASSET_SOURCE_KINDS or not isinstance(raw_usages, list) or not usages or len(usages) != len(raw_usages):
        blockers.append(issue("asset.presentation_invalid", f"Asset {asset_id} needs a valid source_kind and unique presentation usages", source))
        return
    runtime_refs = {
        resolve_project_path(root, str(item))
        for item in asset.get("runtime_refs", []) if str(item)
    } if isinstance(asset.get("runtime_refs"), list) else set()
    source_width = artifact_info.get("width") if artifact_info.get("kind") == "image" else None
    source_height = artifact_info.get("height") if artifact_info.get("kind") == "image" else None

    for usage_id, usage in usages.items():
        render_mode = str(usage.get("render_mode", "")).strip().lower()
        runtime_ref = resolve_project_path(root, str(usage.get("runtime_ref", "")))
        surface_ids = {str(item) for item in usage.get("surface_ids", []) if str(item)} if isinstance(usage.get("surface_ids"), list) else set()
        rendered_size = positive_pair(usage.get("rendered_size"))
        if render_mode not in ASSET_RENDER_MODES or runtime_ref is None or runtime_ref not in runtime_refs or not runtime_ref.exists():
            blockers.append(issue("asset.presentation_usage_invalid", f"Asset {asset_id} usage {usage_id} needs a valid render_mode and runtime_ref already declared by the asset", source))
        if not surface_ids or not surface_ids.issubset(declared_state_ids):
            blockers.append(issue("asset.presentation_surface_invalid", f"Asset {asset_id} usage {usage_id} must map to declared game state IDs", source))
        if render_mode != "procedural" and rendered_size is None:
            blockers.append(issue("asset.presentation_size_missing", f"Asset {asset_id} usage {usage_id} needs rendered_size", source))
        if not str(usage.get("rationale", "")).strip():
            blockers.append(issue("asset.presentation_rationale_missing", f"Asset {asset_id} usage {usage_id} needs a composition/scaling rationale", source))
        require_artifacts(root, usage.get("evidence"), blockers, "asset.presentation_evidence", f"Asset {asset_id} usage {usage_id} has no runtime composite evidence", source, media_only=True, media_minimum=True)
        if render_mode == "procedural" and source_kind != "procedural":
            blockers.append(issue("asset.presentation_procedural_source", f"Asset {asset_id} usage {usage_id} is procedural but its source_kind is not", source))

        if not source_width or not source_height or rendered_size is None:
            continue
        comparison_size = positive_pair(usage.get("source_frame_size")) if render_mode == "sprite-frame" else (float(source_width), float(source_height))
        if render_mode in {"uniform", "native", "sprite-frame"}:
            if comparison_size is None:
                blockers.append(issue("asset.presentation_frame_size_missing", f"Asset {asset_id} usage {usage_id} needs source_frame_size", source))
            else:
                source_ratio = comparison_size[0] / comparison_size[1]
                rendered_ratio = rendered_size[0] / rendered_size[1]
                if abs(source_ratio - rendered_ratio) / source_ratio > 0.05:
                    blockers.append(issue("asset.presentation_distorted", f"Asset {asset_id} usage {usage_id} changes aspect ratio without an approved stretch mode", source, source_ratio=source_ratio, rendered_ratio=rendered_ratio))
        elif render_mode == "nine-slice":
            margins = usage.get("nine_slice_margins")
            try:
                margins = [int(item) for item in margins] if isinstance(margins, list) and len(margins) == 4 else []
            except (TypeError, ValueError):
                margins = []
            minimum = positive_pair(usage.get("minimum_tested_size"))
            maximum = positive_pair(usage.get("maximum_tested_size"))
            if source_kind != "dedicated-component" or len(margins) != 4 or any(item <= 0 for item in margins):
                blockers.append(issue("asset.presentation_nine_slice_invalid", f"Asset {asset_id} usage {usage_id} must use a dedicated component with four positive nine-slice margins", source))
            elif margins[0] + margins[2] >= source_width or margins[1] + margins[3] >= source_height:
                blockers.append(issue("asset.presentation_nine_slice_margins", f"Asset {asset_id} usage {usage_id} nine-slice margins consume the source texture", source))
            if minimum is None or maximum is None or minimum[0] > rendered_size[0] or minimum[1] > rendered_size[1] or maximum[0] < rendered_size[0] or maximum[1] < rendered_size[1]:
                blockers.append(issue("asset.presentation_nine_slice_range", f"Asset {asset_id} usage {usage_id} needs a tested size range covering its runtime size", source))
        elif render_mode == "tile":
            if source_kind not in {"dedicated-component", "tileable"}:
                blockers.append(issue("asset.presentation_tile_source", f"Asset {asset_id} usage {usage_id} is tiled but was not authored as tileable", source))
            require_artifacts(root, usage.get("seam_test_evidence"), blockers, "asset.presentation_seam_evidence", f"Asset {asset_id} usage {usage_id} has no seam-test evidence", source, media_only=True, media_minimum=True)
        elif render_mode == "cover":
            safe_area = usage.get("crop_safe_area")
            try:
                safe_area = [float(item) for item in safe_area] if isinstance(safe_area, list) and len(safe_area) == 4 else []
            except (TypeError, ValueError):
                safe_area = []
            if len(safe_area) != 4 or safe_area[0] < 0 or safe_area[1] < 0 or safe_area[2] <= 0 or safe_area[3] <= 0 or safe_area[0] + safe_area[2] > source_width or safe_area[1] + safe_area[3] > source_height:
                blockers.append(issue("asset.presentation_crop_safe_area", f"Asset {asset_id} usage {usage_id} needs a crop_safe_area for cover mode", source))


def validate_quality(
    root: Path,
    required_commands: set[str],
    godot_commands: set[str],
    required_artifacts_by_command: dict[str, set[str]],
    blockers: list[dict],
    warnings: list[dict],
    evidence: list[dict],
) -> Optional[dict]:
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
    for command_id in sorted(required_commands):
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
        if command_id in godot_commands:
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
        recorded_artifacts = {
            resolve_project_path(root, str(artifact.get("path", "")))
            for artifact in result.get("artifacts", []) if isinstance(artifact, dict)
        }
        for raw_expected in sorted(required_artifacts_by_command.get(command_id, set())):
            expected_path = resolve_project_path(root, raw_expected)
            if expected_path not in recorded_artifacts:
                blockers.append(issue("quality.required_artifact_unbound", f"Command {command_id} is not bound to required artifact {raw_expected}", expected_path))
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

    states, required_commands, godot_commands, evidence_checks, ui_state_ids = validate_state_contract(root, blockers, evidence)
    visual_commands, visual_command_artifacts = validate_visual_contract(root, states, blockers, evidence)
    required_commands.update(visual_commands)

    coverage = load_json(root / "design/assets/asset-coverage.json", blockers, "assets")
    integrated_asset_hashes: set[str] = set()
    state_rows = states.get("states", []) if isinstance(states, dict) else []
    declared_state_ids = {str(row.get("id")) for row in state_rows if isinstance(row, dict) and row.get("id")}
    if coverage is not None:
        raw_groups = coverage.get("groups")
        groups = by_id(raw_groups)
        if not isinstance(raw_groups, list) or not groups or len(groups) != len(raw_groups):
            blockers.append(issue("assets.groups_invalid", "Asset groups must be a non-empty array with unique game-specific IDs", "design/assets/asset-coverage.json"))
        required_groups = {group_id for group_id, group in groups.items() if group.get("required", True)}
        if not required_groups:
            blockers.append(issue("assets.required_groups_missing", "Asset coverage must declare at least one required game-specific group", "design/assets/asset-coverage.json"))
        policy = coverage.get("coverage_policy") if isinstance(coverage.get("coverage_policy"), dict) else {}
        try:
            minimum_distinct = int(policy.get("minimum_distinct_assets", 0))
        except (TypeError, ValueError):
            minimum_distinct = 0
        inventory_sources = policy.get("inventory_sources") if isinstance(policy.get("inventory_sources"), list) else []
        if minimum_distinct < 1 or not str(policy.get("rationale", "")).strip() or not inventory_sources:
            blockers.append(issue("assets.policy_invalid", "coverage_policy needs a justified minimum_distinct_assets and inventory_sources derived from this game's design", "design/assets/asset-coverage.json"))
        for raw_source in inventory_sources:
            source = resolve_project_path(root, str(raw_source))
            if source is None or not is_within(root, source) or not source.is_file():
                blockers.append(issue("assets.inventory_source_missing", f"Asset inventory source is missing: {raw_source}", source))
        seen_asset_ids: set[str] = set()
        for group_id, group in sorted(groups.items()):
            if group.get("required", True) and not status_ok(group.get("status")):
                blockers.append(issue("assets.group_incomplete", f"Asset group {group_id} is not verified", "design/assets/asset-coverage.json"))
            assets = group.get("assets")
            required_ids = {str(item) for item in group.get("required_asset_ids", []) if str(item)} if isinstance(group.get("required_asset_ids"), list) else set()
            if group.get("required", True) and (not required_ids or not str(group.get("coverage_basis", "")).strip()):
                blockers.append(issue("assets.coverage_contract_missing", f"Asset group {group_id} needs coverage_basis and required_asset_ids", "design/assets/asset-coverage.json"))
            actual_ids = {str(item.get("id")) for item in assets if isinstance(item, dict) and item.get("id")} if isinstance(assets, list) else set()
            for duplicate in sorted(seen_asset_ids.intersection(actual_ids)):
                blockers.append(issue("assets.id_duplicate", f"Asset id {duplicate} is reused across groups", "design/assets/asset-coverage.json"))
            seen_asset_ids.update(actual_ids)
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
                errors, artifact_info = validate_artifact(path)
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
                validate_asset_presentation(root, str(asset.get("id", "<missing>")), asset, artifact_info, declared_state_ids, blockers, "design/assets/asset-coverage.json")
        required_asset_floor = sum(
            len({str(item) for item in group.get("required_asset_ids", []) if str(item)})
            for group in groups.values()
            if group.get("required", True) and isinstance(group.get("required_asset_ids"), list)
        )
        if minimum_distinct < required_asset_floor:
            blockers.append(issue("assets.policy_below_inventory", "minimum_distinct_assets cannot be lower than the declared required asset inventory", "design/assets/asset-coverage.json", minimum=minimum_distinct, required_assets=required_asset_floor))
        if len(integrated_asset_hashes) < minimum_distinct:
            blockers.append(issue("assets.not_distinct", "Integrated production assets do not meet this game's declared coverage policy", "design/assets/asset-coverage.json", expected=minimum_distinct, distinct=len(integrated_asset_hashes)))

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
        inventory_ids: set[str] = set()
        inventory_match = re.search(r"^## Screen Inventory\s*$([\s\S]*?)(?=^##\s|\Z)", ui_text, re.MULTILINE)
        for line in inventory_match.group(1).splitlines() if inventory_match else []:
            if not line.startswith("|") or re.match(r"^\|[- :|]+\|$", line) or "State ID" in line:
                continue
            cells = [cell.strip() for cell in line.strip("|").split("|")]
            if len(cells) >= 5 and any(not cell for cell in cells[:5]):
                blockers.append(issue("ui.screen_row_incomplete", f"UI inventory row is incomplete: {line}", ui_path))
            elif len(cells) >= 5:
                inventory_ids.add(cells[0])
        for state_id in sorted(ui_state_ids - inventory_ids):
            blockers.append(issue("ui.state_missing", f"UI inventory does not cover declared UI state {state_id}", ui_path))
        mode_match = re.search(r"^Implementation mode:\s*(\S+)\s*$", ui_text, re.MULTILINE | re.IGNORECASE)
        mode = mode_match.group(1).strip().lower() if mode_match else ""
        if mode not in UI_MODES:
            blockers.append(issue("ui.mode_invalid", f"UI implementation mode must be one of {sorted(UI_MODES)}", ui_path))
        resource_refs = sorted(set(re.findall(r"res://[A-Za-z0-9_./-]+", ui_text)))
        resources: list[Path] = []
        for raw_resource in resource_refs:
            resource = resolve_project_path(root, raw_resource)
            if resource is not None and is_within(root, resource) and resource.is_file() and resource.stat().st_size > 0:
                resources.append(resource)
        if not resources:
            blockers.append(issue("ui.resources_missing", "UI spec must reference at least one implemented project-local presentation resource", ui_path))
        if mode in {"godot-theme", "hybrid"} and not any("Theme" in resource.read_text(encoding="utf-8-sig", errors="ignore") for resource in resources):
            blockers.append(issue("ui.theme_missing", "godot-theme/hybrid mode needs an implemented Godot Theme resource", ui_path))
        if mode == "intentionally-minimal" and not re.search(r"^Minimal UI rationale:\s*\S.+$", ui_text, re.MULTILINE | re.IGNORECASE):
            blockers.append(issue("ui.minimal_unjustified", "Intentionally minimal UI needs a concrete rationale", ui_path))

    audio = load_json(root / "design/audio/audio-manifest.json", blockers, "audio")
    audio_hashes: set[str] = set()
    if audio is not None:
        if audio.get("intentional_silence"):
            if not str(audio.get("silence_rationale", "")).strip():
                blockers.append(issue("audio.silence_unjustified", "Intentional silence needs a rationale", "design/audio/audio-manifest.json"))
        else:
            buses = {str(item) for item in audio.get("buses", []) if str(item)} if isinstance(audio.get("buses"), list) else set()
            required_buses = {str(item) for item in audio.get("required_buses", []) if str(item)} if isinstance(audio.get("required_buses"), list) else set()
            if not required_buses or not required_buses.issubset(buses):
                blockers.append(issue("audio.buses_missing", "Audio manifest buses do not cover this game's declared required_buses", "design/audio/audio-manifest.json"))
            raw_coverage = audio.get("coverage_requirements")
            coverage_rows = by_id(raw_coverage)
            if not isinstance(raw_coverage, list) or not coverage_rows or len(coverage_rows) != len(raw_coverage):
                blockers.append(issue("audio.coverage_invalid", "coverage_requirements must be a non-empty array with unique game-specific IDs", "design/audio/audio-manifest.json"))
            required_events: set[str] = set()
            for coverage_id, coverage_row in coverage_rows.items():
                if not coverage_row.get("required", True):
                    continue
                event_ids = {str(item) for item in coverage_row.get("event_ids", []) if str(item)} if isinstance(coverage_row.get("event_ids"), list) else set()
                if not str(coverage_row.get("rationale", "")).strip() or not event_ids:
                    blockers.append(issue("audio.coverage_contract_incomplete", f"Audio coverage {coverage_id} needs rationale and event_ids", "design/audio/audio-manifest.json"))
                required_events.update(event_ids)
            raw_events = audio.get("events")
            events = by_id(raw_events)
            if not isinstance(raw_events, list) or len(events) != len(raw_events):
                blockers.append(issue("audio.events_invalid", "Audio events must be an array with unique IDs", "design/audio/audio-manifest.json"))
            for event_id in sorted(required_events):
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
                provenance = resolve_project_path(root, str(event.get("provenance", "")))
                if provenance is None or not is_within(root, provenance) or not provenance.is_file() or provenance.stat().st_size == 0:
                    blockers.append(issue("audio.provenance_missing", f"Audio event {event_id} has no project-local provenance/license record", provenance))
                if not str(event.get("trigger", "")).strip():
                    blockers.append(issue("audio.trigger_missing", f"Audio event {event_id} has no trigger", "design/audio/audio-manifest.json"))
        require_artifacts(root, audio.get("evidence"), blockers, "audio.evidence", "Audio manifest has no listening/runtime evidence", "design/audio/audio-manifest.json")
        if not audio.get("intentional_silence"):
            policy = audio.get("coverage_policy") if isinstance(audio.get("coverage_policy"), dict) else {}
            try:
                minimum_distinct_audio = int(policy.get("minimum_distinct_assets", 0))
            except (TypeError, ValueError):
                minimum_distinct_audio = 0
            if minimum_distinct_audio < 1 or not str(policy.get("rationale", "")).strip():
                blockers.append(issue("audio.policy_invalid", "Audio coverage_policy needs a game-specific rationale and positive minimum_distinct_assets", "design/audio/audio-manifest.json"))
            elif len(audio_hashes) < minimum_distinct_audio:
                blockers.append(issue("audio.not_distinct", "Integrated audio does not meet this game's declared coverage policy", "design/audio/audio-manifest.json", expected=minimum_distinct_audio, distinct=len(audio_hashes)))

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

    require_pass_review(root, "*visual*.md", "visual.review_missing", {"image", "video"}, blockers)
    audio_review_kinds = {"audio", "video"} if audio and audio.get("intentional_silence") else {"audio"}
    require_pass_review(root, "*audio*.md", "audio.review_missing", audio_review_kinds, blockers)
    validate_quality(root, required_commands, godot_commands, visual_command_artifacts, blockers, warnings, evidence)

    report = load_json(root / "production/evidence/player-ready.json", blockers, "evidence")
    if report is not None:
        checks = report.get("checks")
        if not isinstance(checks, dict):
            blockers.append(issue("evidence.checks_invalid", "checks must be an object", "production/evidence/player-ready.json"))
        else:
            for check in sorted(evidence_checks):
                if str(checks.get(check, "")).upper() != "PASS":
                    blockers.append(issue("evidence.not_passed", f"Evidence check {check} is not PASS", "production/evidence/player-ready.json"))
        require_artifacts(root, report.get("artifacts"), blockers, "evidence.artifacts", "No player-ready artifacts recorded", "production/evidence/player-ready.json")
        expected_links = {
            "quality_report": "production/evidence/quality-run.json",
            "visual_contract": "production/reviews/visual-quality-contract.json",
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
