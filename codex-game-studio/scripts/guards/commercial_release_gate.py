#!/usr/bin/env python3
"""Cross-platform commercial release gate for Codex Game Maker projects."""

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
    compare_metric,
    date_is_recent,
    git_commit,
    git_dirty,
    is_within,
    issue,
    load_json,
    report_gate,
    require_artifacts,
    require_ready_markdown,
    resolve_project_path,
    sha256_path,
    sha256_file,
    sha256_json,
    status_na,
    status_ok,
    validate_artifact,
    validate_media,
)
from player_ready_gate import evaluate as evaluate_player_ready  # noqa: E402


REQUIRED_COMPLIANCE = {
    "asset-rights", "dependency-licenses", "ai-provenance", "privacy-data-inventory",
    "privacy-policy-decision", "content-rating", "third-party-notices", "platform-terms",
    "commerce-disclosures", "secrets-scan",
}
COMPLIANCE_NA_ALLOWED = {"ai-provenance", "commerce-disclosures"}
REQUIRED_ACCESSIBILITY = {
    "text-readability", "contrast", "non-color-cues", "subtitles-captions", "audio-alternatives",
    "input-remapping", "ui-navigation-focus", "difficulty-timing-assists", "motion-camera-controls",
    "photosensitivity", "accessible-help-support", "player-review",
}


def required_status(data: Optional[dict], path: Path, blockers: list[dict], code: str) -> bool:
    if data is None:
        return False
    if not status_ok(data.get("status")):
        blockers.append(issue(f"{code}.status", f"{path.name} is not verified/approved", path))
        return False
    return True


def validate_build_matrix(
    root: Path,
    contract: dict,
    quality_report: Optional[dict],
    blockers: list[dict],
    evidence: list[dict],
) -> dict[str, dict]:
    path = root / "production/build-matrix.json"
    data = load_json(path, blockers, "build_matrix")
    if not required_status(data, path, blockers, "build_matrix"):
        return {}
    targets = by_id(data.get("targets"))
    declared = {str(item) for item in contract.get("target_platforms", []) if str(item)}
    quality = command_results(quality_report)
    verified: dict[str, dict] = {}
    for target_id in sorted(declared):
        row = targets.get(target_id)
        if not row:
            blockers.append(issue("build.target_missing", f"Build matrix is missing target {target_id}", path))
            continue
        if not status_ok(row.get("status")):
            blockers.append(issue("build.target_incomplete", f"Build target {target_id} is not verified", path))
        artifact = resolve_project_path(root, str(row.get("artifact", "")))
        errors, _ = validate_artifact(artifact) if artifact and is_within(root, artifact) else (["artifact path is empty or outside project"], {})
        for error in errors:
            blockers.append(issue("build.artifact_invalid", f"{target_id}: {error}", artifact))
        actual_hash = sha256_path(artifact) if artifact and artifact.exists() else ""
        if not row.get("sha256") or row.get("sha256") != actual_hash:
            blockers.append(issue("build.hash_mismatch", f"Build artifact hash is missing or stale for {target_id}", artifact))
        for field in ("build_command_id", "smoke_command_id"):
            command_id = str(row.get(field, ""))
            result = quality.get(command_id)
            if not command_id or not result or result.get("status") != "PASS" or result.get("returncode") != 0:
                blockers.append(issue("build.command_failed", f"{target_id} has no passing {field}", path))
            elif field == "build_command_id":
                result_artifacts = result.get("artifacts") if isinstance(result.get("artifacts"), list) else []
                artifact_bound = any(
                    isinstance(item, dict)
                    and resolve_project_path(root, str(item.get("path", ""))) == artifact
                    and item.get("sha256") == actual_hash
                    for item in result_artifacts
                )
                if not artifact_bound:
                    blockers.append(issue("build.command_artifact_unbound", f"Build command evidence is not bound to the current artifact for {target_id}", path))
        if not str(row.get("official_requirements_source", "")).startswith("https://") or not date_is_recent(row.get("requirements_verified_on")):
            blockers.append(issue("build.requirements_unverified", f"Current official requirements are not recorded for {target_id}", path))
        devices = row.get("devices")
        if not isinstance(devices, list) or not devices:
            blockers.append(issue("build.device_matrix_missing", f"No target-device evidence is declared for {target_id}", path))
        require_artifacts(root, row.get("evidence"), blockers, "build.evidence", f"No build/smoke evidence for {target_id}", path)
        platform = str(row.get("platform", target_id)).lower()
        signing = row.get("signing") if isinstance(row.get("signing"), dict) else {}
        signing_required = platform in {"macos", "ios", "android"} or bool(signing.get("required"))
        if signing_required:
            if not status_ok(signing.get("status")):
                blockers.append(issue("build.signing_missing", f"Signing is not verified for {target_id}", path))
            require_artifacts(root, signing.get("evidence"), blockers, "build.signing_evidence", f"No signing evidence for {target_id}", path)
        store_review = row.get("store_review") if isinstance(row.get("store_review"), dict) else {}
        store_required = str(row.get("store", "direct")) not in {"", "direct", "none"} or bool(store_review.get("required"))
        if store_required:
            if not status_ok(store_review.get("status")):
                blockers.append(issue("build.store_review_missing", f"Store review package is not submission-ready for {target_id}", path))
            require_artifacts(root, store_review.get("evidence"), blockers, "build.store_evidence", f"No store review evidence for {target_id}", path)
        verified[target_id] = {"row": row, "artifact": artifact, "sha256": actual_hash}
        evidence.append({"code": "build.target", "id": target_id, "sha256": actual_hash})
    extras = set(targets) - declared
    if extras:
        evidence.append({"code": "build.extra_targets", "ids": sorted(extras)})
    return verified


def validate_performance(root: Path, declared: set[str], builds: dict[str, dict], quality_report: Optional[dict], blockers: list[dict], evidence: list[dict]) -> None:
    path = root / "production/performance-budget.json"
    data = load_json(path, blockers, "performance")
    if not required_status(data, path, blockers, "performance"):
        return
    targets = by_id(data.get("targets"))
    quality = command_results(quality_report)
    metric_modes = {
        "min_fps": "min", "max_frame_time_ms": "max", "max_memory_mb": "max",
        "max_startup_seconds": "max", "max_scene_load_seconds": "max",
        "max_memory_growth_mb": "max", "max_crashes": "max",
    }
    for target_id in sorted(declared):
        row = targets.get(target_id)
        if not row or not status_ok(row.get("status")):
            blockers.append(issue("performance.target_missing", f"No verified performance result for {target_id}", path))
            continue
        budgets = row.get("budgets") if isinstance(row.get("budgets"), dict) else {}
        results = row.get("results") if isinstance(row.get("results"), dict) else {}
        for metric, mode in metric_modes.items():
            if metric not in budgets or not compare_metric(results.get(metric), budgets.get(metric), mode):
                blockers.append(issue("performance.budget_failed", f"{target_id} failed or omitted metric {metric}", path, actual=results.get(metric), budget=budgets.get(metric)))
        if not str(row.get("device", "")).strip() or not row.get("duration_seconds"):
            blockers.append(issue("performance.context_missing", f"Device/duration is missing for {target_id}", path))
        build_hash = builds.get(target_id, {}).get("sha256", "")
        if not build_hash or row.get("build_sha256") != build_hash:
            blockers.append(issue("performance.build_mismatch", f"Performance evidence is not for the current {target_id} build", path))
        command_id = str(row.get("measurement_command_id", ""))
        command_result = quality.get(command_id)
        if not command_id or not command_result or command_result.get("status") != "PASS" or command_result.get("returncode") != 0:
            blockers.append(issue("performance.command_missing", f"No passing measurement command for {target_id}", path))
        else:
            command_paths = {
                resolve_project_path(root, str(item.get("path", "")))
                for item in command_result.get("artifacts", [])
                if isinstance(item, dict)
            }
            evidence_paths = {
                resolve_project_path(root, str(item))
                for item in row.get("evidence", [])
            } if isinstance(row.get("evidence"), list) else set()
            if not {item for item in command_paths.intersection(evidence_paths) if item is not None and is_within(root, item)}:
                blockers.append(issue("performance.command_evidence_unbound", f"Performance command is not bound to target evidence for {target_id}", path))
        require_artifacts(root, row.get("evidence"), blockers, "performance.evidence", f"No profiler/device evidence for {target_id}", path)
        evidence.append({"code": "performance.target", "id": target_id})


def validate_compliance(root: Path, blockers: list[dict], evidence: list[dict]) -> None:
    path = root / "production/compliance-manifest.json"
    data = load_json(path, blockers, "compliance")
    if not required_status(data, path, blockers, "compliance"):
        return
    items = by_id(data.get("items"))
    for item_id in sorted(REQUIRED_COMPLIANCE):
        row = items.get(item_id)
        if not row:
            blockers.append(issue("compliance.item_missing", f"Missing compliance item {item_id}", path))
            continue
        if status_na(row.get("status")):
            if item_id not in COMPLIANCE_NA_ALLOWED or not str(row.get("rationale", "")).strip():
                blockers.append(issue("compliance.na_invalid", f"{item_id} cannot be N/A without an allowed rationale", path))
            continue
        if not status_ok(row.get("status")):
            blockers.append(issue("compliance.item_incomplete", f"Compliance item {item_id} is not approved", path))
            continue
        if not str(row.get("owner", "")).strip() or not str(row.get("source", "")).strip():
            blockers.append(issue("compliance.ownership_missing", f"Compliance item {item_id} lacks owner/source", path))
        require_artifacts(root, row.get("evidence"), blockers, "compliance.evidence", f"No evidence for compliance item {item_id}", path)
        evidence.append({"code": "compliance.item", "id": item_id})


def validate_localization(root: Path, contract: dict, blockers: list[dict], evidence: list[dict]) -> None:
    path = root / "design/localization/localization-manifest.json"
    data = load_json(path, blockers, "localization")
    if not required_status(data, path, blockers, "localization"):
        return
    declared = {str(item) for item in contract.get("release_locales", []) if str(item)}
    manifest_locales = {str(item) for item in data.get("release_locales", []) if str(item)} if isinstance(data.get("release_locales"), list) else set()
    if not declared or manifest_locales != declared:
        blockers.append(issue("localization.locale_mismatch", "Localization manifest locales do not match the release contract", path))
    pseudo = data.get("pseudo_localization") if isinstance(data.get("pseudo_localization"), dict) else {}
    if not status_ok(pseudo.get("status")):
        blockers.append(issue("localization.pseudo_missing", "Pseudo-localization has not passed", path))
    require_artifacts(root, pseudo.get("evidence"), blockers, "localization.pseudo_evidence", "Pseudo-localization has no evidence", path)
    locales = by_id(data.get("locales"))
    source_locale = str(data.get("source_locale", ""))
    for locale in sorted(declared):
        row = locales.get(locale)
        if not row or not status_ok(row.get("status")):
            blockers.append(issue("localization.locale_incomplete", f"Locale {locale} is not verified", path))
            continue
        catalog = resolve_project_path(root, str(row.get("catalog", "")))
        if catalog is None or not is_within(root, catalog) or not catalog.is_file() or catalog.stat().st_size == 0:
            blockers.append(issue("localization.catalog_missing", f"Locale {locale} has no valid catalog", catalog))
        if not str(row.get("font_coverage", "")).strip():
            blockers.append(issue("localization.font_missing", f"Locale {locale} has no font/glyph coverage result", path))
        if locale != source_locale and not str(row.get("linguistic_approval", "")).strip():
            blockers.append(issue("localization.approval_missing", f"Locale {locale} lacks linguistic approval", path))
        require_artifacts(root, row.get("evidence"), blockers, "localization.evidence", f"Locale {locale} has no runtime evidence", path, media_only=True, media_minimum=True)
        evidence.append({"code": "localization.locale", "id": locale})


def validate_accessibility(root: Path, blockers: list[dict], evidence: list[dict]) -> None:
    path = root / "design/accessibility/accessibility-conformance.json"
    data = load_json(path, blockers, "accessibility")
    if not required_status(data, path, blockers, "accessibility"):
        return
    rows = by_id(data.get("features"))
    for feature_id in sorted(REQUIRED_ACCESSIBILITY):
        row = rows.get(feature_id)
        if not row:
            blockers.append(issue("accessibility.feature_missing", f"Missing accessibility feature {feature_id}", path))
            continue
        if status_na(row.get("status")):
            if feature_id == "player-review" or not str(row.get("rationale", "")).strip():
                blockers.append(issue("accessibility.na_invalid", f"Feature {feature_id} cannot be N/A without a valid rationale", path))
            continue
        if not status_ok(row.get("status")):
            blockers.append(issue("accessibility.feature_incomplete", f"Accessibility feature {feature_id} is not verified", path))
            continue
        require_artifacts(root, row.get("evidence"), blockers, "accessibility.evidence", f"No evidence for accessibility feature {feature_id}", path)
        evidence.append({"code": "accessibility.feature", "id": feature_id})


def validate_marketing(root: Path, declared: set[str], blockers: list[dict], evidence: list[dict]) -> None:
    path = root / "marketing/store-manifest.json"
    data = load_json(path, blockers, "marketing")
    if not required_status(data, path, blockers, "marketing"):
        return
    if data.get("positioning_approved") is not True:
        blockers.append(issue("marketing.positioning_unapproved", "Marketing positioning is not approved", path))
    rows = [row for row in data.get("targets", []) if isinstance(row, dict)] if isinstance(data.get("targets"), list) else []
    for target_id in sorted(declared):
        matches = [row for row in rows if str(row.get("platform")) == target_id or str(row.get("id")) == target_id]
        if not matches:
            blockers.append(issue("marketing.target_missing", f"No store package for target {target_id}", path))
            continue
        for row in matches:
            if not status_ok(row.get("status")):
                blockers.append(issue("marketing.target_incomplete", f"Marketing target {row.get('id')} is not verified", path))
            if not str(row.get("official_requirements_source", "")).startswith("https://") or not date_is_recent(row.get("requirements_verified_on")):
                blockers.append(issue("marketing.requirements_unverified", f"Store requirements are not current for {row.get('id')}", path))
            assets = [asset for asset in row.get("assets", []) if isinstance(asset, dict)] if isinstance(row.get("assets"), list) else []
            icons = [asset for asset in assets if asset.get("type") == "icon"]
            screenshots = [asset for asset in assets if asset.get("type") == "screenshot"]
            if not icons or len(screenshots) < 3:
                blockers.append(issue("marketing.assets_incomplete", f"{row.get('id')} needs an icon and at least three screenshots", path))
            for asset in assets:
                if not status_ok(asset.get("status")):
                    blockers.append(issue("marketing.asset_incomplete", f"Marketing asset {asset.get('id')} is not verified", path))
                    continue
                asset_path = resolve_project_path(root, str(asset.get("path", "")))
                kind = "video" if asset.get("type") in {"trailer", "app-preview"} else "image"
                min_width, min_height = (640, 360) if asset.get("type") == "screenshot" else (64, 64)
                if asset_path is None or not is_within(root, asset_path):
                    blockers.append(issue("marketing.asset_missing", f"Marketing asset {asset.get('id')} has no path", path))
                else:
                    errors, _ = validate_media(asset_path, expected_kind=kind, min_width=min_width, min_height=min_height)
                    for error in errors:
                        blockers.append(issue("marketing.asset_invalid", f"{asset.get('id')}: {error}", asset_path))
                require_artifacts(root, asset.get("evidence"), blockers, "marketing.asset_evidence", f"No approval evidence for {asset.get('id')}", path)
            for claim in row.get("claims", []) if isinstance(row.get("claims"), list) else []:
                if not isinstance(claim, dict) or not status_ok(claim.get("status")):
                    blockers.append(issue("marketing.claim_unverified", f"Unverified marketing claim for {row.get('id')}", path))
                    continue
                require_artifacts(root, claim.get("evidence"), blockers, "marketing.claim_evidence", "Marketing claim has no runtime evidence", path)
            evidence.append({"code": "marketing.target", "id": row.get("id")})


def validate_external_approvals(root: Path, contract: dict, blockers: list[dict], evidence: list[dict]) -> None:
    approvals = contract.get("external_approvals")
    if not isinstance(approvals, list):
        blockers.append(issue("approval.list_missing", "external_approvals must be an array", "production/commercial-release-contract.json"))
        return
    rows = by_id(approvals)
    required = {"release-owner", "legal-owner"}
    model = contract.get("business_model") if isinstance(contract.get("business_model"), dict) else {}
    if str(model.get("type", "")) not in {"free", "free-no-monetization"} or any(model.get(key) for key in ("iap", "ads", "dlc")):
        required.add("commerce-owner")
    stores = {str(item).lower() for item in contract.get("stores", []) if str(item)} if isinstance(contract.get("stores"), list) else set()
    if stores - {"", "direct", "none"}:
        required.add("store-account-owner")
    platforms = {str(item).lower() for item in contract.get("target_platforms", []) if str(item)} if isinstance(contract.get("target_platforms"), list) else set()
    if platforms.intersection({"macos", "ios", "android"}):
        required.add("signing-owner")
    if platforms.intersection({"playstation", "xbox", "nintendo-switch", "switch"}):
        required.add("platform-certification-owner")
    data_practices = contract.get("data_practices") if isinstance(contract.get("data_practices"), dict) else {}
    if data_practices.get("collects_data") or data_practices.get("third_party_sdks"):
        required.add("privacy-owner")
    audience = contract.get("audience") if isinstance(contract.get("audience"), dict) else {}
    if audience.get("children_targeted"):
        required.add("child-safety-owner")
    for approval_id in sorted(required - set(rows)):
        blockers.append(issue("approval.required_missing", f"Required external approval is missing: {approval_id}", "production/commercial-release-contract.json"))
    for row in approvals:
        if not isinstance(row, dict) or not row.get("id") or not status_ok(row.get("status")) or not str(row.get("owner", "")).strip() or not date_is_recent(row.get("decided_on"), max_age_days=365):
            blockers.append(issue("approval.incomplete", "External approval is missing id or approved status", "production/commercial-release-contract.json"))
            continue
        require_artifacts(root, row.get("evidence"), blockers, "approval.evidence", f"External approval {row.get('id')} has no evidence", "production/commercial-release-contract.json")
        evidence.append({"code": "approval.external", "id": row.get("id")})


def evaluate(root: Path, strict: bool = True) -> dict:
    root = root.resolve()
    blockers: list[dict] = []
    warnings: list[dict] = []
    evidence: list[dict] = []

    player = evaluate_player_ready(root, strict=True)
    if player["gate"] != "PASS":
        blockers.append(issue("player_ready.blocked", f"Player-ready gate is {player['gate']}", root, blocker_count=len(player["blockers"])))
    else:
        evidence.append({"code": "player_ready.pass"})

    contract_path = root / "production/commercial-release-contract.json"
    contract = load_json(contract_path, blockers, "commercial_contract")
    if contract is None:
        return report_gate(root, blockers, warnings, evidence)
    required_status(contract, contract_path, blockers, "commercial_contract")
    for field in ("release_id", "version", "build_commit"):
        if not str(contract.get(field, "")).strip():
            blockers.append(issue("commercial_contract.field_missing", f"Missing commercial contract field: {field}", contract_path))
    declared = {str(item) for item in contract.get("target_platforms", []) if str(item)} if isinstance(contract.get("target_platforms"), list) else set()
    if not declared:
        blockers.append(issue("commercial_contract.targets_missing", "No target platforms declared", contract_path))

    policy_path = SCRIPT_DIR.parent.parent / "references/policies/godot-version-policy.json"
    policy = load_json(policy_path, blockers, "godot_policy")
    engine = contract.get("engine") if isinstance(contract.get("engine"), dict) else {}
    engine_version = str(engine.get("version", ""))
    version_match = re.match(r"^(\d+\.\d+)", engine_version)
    minor = version_match.group(1) if version_match else ""
    if policy:
        if not date_is_recent(policy.get("verified_on")):
            blockers.append(issue("godot.policy_stale", "Godot version policy is older than 180 days and must be reverified", policy_path))
        if minor in policy.get("eol_minor_lines", []):
            blockers.append(issue("godot.eol", f"Godot {engine_version} is EOL for commercial release", contract_path))
        elif minor not in policy.get("supported_minor_lines", []):
            blockers.append(issue("godot.unsupported", f"Godot {engine_version} is not on a fully supported line in the verified policy", contract_path))
        evidence.append({"code": "godot.version_policy", "version": engine_version, "verified_on": policy.get("verified_on")})

    current_commit = git_commit(root)
    if current_commit and contract.get("build_commit") != current_commit:
        blockers.append(issue("release.commit_mismatch", "Commercial contract build_commit does not match HEAD", contract_path))
    dirty = git_dirty(root)
    if dirty:
        blockers.append(issue("release.dirty_worktree", "Commercial release requires a clean worktree", root))

    quality_report = load_json(root / "production/evidence/quality-run.json", blockers, "quality.report")
    quality_manifest = load_json(root / "production/quality-command-manifest.json", blockers, "quality.manifest")
    if quality_report and quality_manifest:
        probed_version = str((quality_report.get("godot") or {}).get("version", "")) if isinstance(quality_report.get("godot"), dict) else ""
        if not probed_version.startswith(engine_version):
            blockers.append(issue("godot.build_version_mismatch", "Commercial contract engine version does not match the probed build tool", "production/evidence/quality-run.json", contract=engine_version, detected=probed_version))
        results = command_results(quality_report)
        for row in quality_manifest.get("commands", []) if isinstance(quality_manifest.get("commands"), list) else []:
            if isinstance(row, dict) and "commercial_release" in row.get("required_for", []):
                result = results.get(str(row.get("id")))
                if not result or result.get("status") != "PASS" or result.get("returncode") != 0:
                    blockers.append(issue("quality.commercial_command_failed", f"Commercial command did not pass: {row.get('id')}", "production/evidence/quality-run.json"))
                    continue
                if result.get("command_sha256") != sha256_json(row):
                    blockers.append(issue("quality.commercial_command_changed", f"Commercial command evidence is stale: {row.get('id')}", "production/evidence/quality-run.json"))
                for stream in ("stdout", "stderr"):
                    log_path = resolve_project_path(root, str(result.get(stream, "")))
                    expected_hash = str(result.get(f"{stream}_sha256", ""))
                    if log_path is None or not is_within(root, log_path) or not log_path.is_file() or not expected_hash or sha256_file(log_path) != expected_hash:
                        blockers.append(issue("quality.commercial_log_invalid", f"Commercial command {row.get('id')} has missing or changed {stream}", log_path))

    require_ready_markdown(root / "business/product-brief.md", blockers, "business")
    model = contract.get("business_model") if isinstance(contract.get("business_model"), dict) else {}
    if str(model.get("type", "")) not in {"free-no-monetization", "free"} or any(model.get(key) for key in ("iap", "ads", "dlc")):
        require_ready_markdown(root / "business/monetization-design.md", blockers, "monetization")

    builds = validate_build_matrix(root, contract, quality_report, blockers, evidence)
    validate_performance(root, declared, builds, quality_report, blockers, evidence)
    validate_compliance(root, blockers, evidence)
    validate_localization(root, contract, blockers, evidence)
    validate_accessibility(root, blockers, evidence)
    validate_marketing(root, declared, blockers, evidence)
    require_ready_markdown(root / "production/liveops-plan.md", blockers, "liveops")
    require_ready_markdown(root / "production/telemetry-crash-plan.md", blockers, "telemetry")

    if contract.get("narrative_in_scope"):
        require_ready_markdown(root / "design/narrative/narrative-bible.md", blockers, "narrative")
    online = contract.get("online_features") if isinstance(contract.get("online_features"), dict) else {}
    if online.get("enabled"):
        require_ready_markdown(root / "docs/online/online-services-plan.md", blockers, "online")
        require_ready_markdown(root / "docs/security/threat-model.md", blockers, "security")
    validate_external_approvals(root, contract, blockers, evidence)

    if strict and warnings:
        blockers.append(issue("strict.warnings", "Commercial release treats warnings as blockers", root))
    return report_gate(root, blockers, warnings, evidence)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".")
    parser.add_argument("--no-strict", action="store_true")
    parser.add_argument("--output", default="")
    args = parser.parse_args()
    report = evaluate(Path(args.root), strict=not args.no_strict)
    output = json.dumps(report, indent=2)
    print(output)
    if args.output:
        path = resolve_project_path(Path(args.root).resolve(), args.output)
        if path:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(output + "\n", encoding="utf-8")
    return 1 if report["gate"] == "BLOCKED" else 0


if __name__ == "__main__":
    raise SystemExit(main())
