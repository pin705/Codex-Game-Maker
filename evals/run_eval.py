#!/usr/bin/env python3
"""Validate and score Codex Game Maker evaluation artifacts."""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parent


def load(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def corpus() -> tuple[dict, dict[str, dict], dict, dict]:
    rubric = load(ROOT / "rubric.json")
    cases = {row["id"]: row for row in load(ROOT / "benchmark-cases.json")["cases"]}
    routing = load(ROOT / "routing-corpus.json")
    negatives = load(ROOT / "negative-corpus.json")
    return rubric, cases, routing, negatives


def validate_corpus() -> list[str]:
    errors: list[str] = []
    rubric, cases, routing, negatives = corpus()
    dimensions = rubric.get("dimensions", [])
    ids = [row.get("id") for row in dimensions if isinstance(row, dict)]
    if len(ids) != len(set(ids)) or not ids:
        errors.append("rubric dimension IDs must be unique and non-empty")
    if sum(int(row.get("weight", 0)) for row in dimensions if isinstance(row, dict)) != 100:
        errors.append("rubric weights must total 100")
    if len(cases) < 6:
        errors.append("benchmark corpus must contain at least six cases")
    for case_id, row in cases.items():
        if not str(row.get("prompt", "")).strip() or not row.get("must_cover"):
            errors.append(f"benchmark case {case_id} needs prompt and must_cover")
    skills = {path.parent.name for path in (ROOT.parent / "plugins/codex-game-maker/skills").glob("*/SKILL.md")}
    route_rows = routing.get("cases", [])
    route_ids = [row.get("id") for row in route_rows if isinstance(row, dict)]
    if len(route_rows) < 24 or len(route_ids) != len(set(route_ids)):
        errors.append("routing corpus needs at least 24 uniquely identified cases")
    for row in route_rows:
        if not isinstance(row, dict) or not str(row.get("prompt", "")).strip():
            errors.append("every routing row needs a prompt")
            continue
        unknown = (set(row.get("expected_skills", [])) | set(row.get("forbidden_skills", []))) - skills
        if unknown:
            errors.append(f"routing case {row.get('id')} references unknown skills: {sorted(unknown)}")
    negative_rows = negatives.get("cases", [])
    if len(negative_rows) < 10:
        errors.append("negative corpus must contain at least ten cases")
    for row in negative_rows:
        if row.get("severity") not in {"blocker", "high"} or not str(row.get("defect", "")).strip():
            errors.append(f"negative case {row.get('id')} needs blocker/high severity and a defect")
    return errors


def score_run(path: Path) -> dict:
    rubric, cases, _, negatives = corpus()
    known_skills = {
        skill.parent.name
        for skill in (ROOT.parent / "plugins/codex-game-maker/skills").glob("*/SKILL.md")
    }
    run = load(path)
    errors: list[str] = []
    if run.get("schema_version") != 1 or run.get("status") != "complete":
        errors.append("run must use schema_version 1 and status complete")
    if run.get("case_id") not in cases:
        errors.append("run case_id is not in benchmark-cases.json")
    for field in ("run_id", "brief_sha256"):
        if not str(run.get(field, "")).strip():
            errors.append(f"run needs {field}")
    if not re.fullmatch(r"[0-9a-f]{64}", str(run.get("brief_sha256", ""))):
        errors.append("brief_sha256 must be a lower-case SHA-256")
    plugin = run.get("plugin", {})
    if not str(plugin.get("version", "")).strip() or not str(plugin.get("commit", "")).strip():
        errors.append("run needs plugin version and commit")
    agent = run.get("agent", {})
    if not str(agent.get("model", "")).strip() or not str(agent.get("reasoning_effort", "")).strip():
        errors.append("run needs model and reasoning_effort")
    review = run.get("review", {})
    if review.get("mode") not in {"human", "independent-agent"} or not review.get("blind"):
        errors.append("final evaluation requires a blind human or independent-agent review")
    if not str(review.get("reviewer", "")).strip() or not str(review.get("independence", "")).strip():
        errors.append("reviewer identity and independence are required")
    dimensions = rubric["dimensions"]
    scores = run.get("scores", {})
    weighted = 0.0
    dimension_percents: dict[str, float] = {}
    scale_max = float(rubric["score_scale"]["maximum"])
    for dimension in dimensions:
        dimension_id = dimension["id"]
        try:
            value = float(scores[dimension_id])
        except (KeyError, TypeError, ValueError):
            errors.append(f"missing numeric score for {dimension_id}")
            continue
        if value < 0 or value > scale_max:
            errors.append(f"score for {dimension_id} is outside the rubric scale")
            continue
        percent = value / scale_max * 100
        dimension_percents[dimension_id] = round(percent, 2)
        weighted += percent * float(dimension["weight"]) / 100
    known = {row["id"]: row for row in negatives["cases"]}
    severe = [item for item in run.get("known_defects", []) if item in known]
    false_pass = bool(severe and str(run.get("decision", "")).upper() == "PASS")
    thresholds = rubric["release_thresholds"]
    routing = run.get("routing") if isinstance(run.get("routing"), dict) else {}
    expected_rows = routing.get("expected_skills")
    actual_rows = routing.get("activated_skills")
    if (
        not isinstance(expected_rows, list)
        or not expected_rows
        or not all(isinstance(item, str) and item for item in expected_rows)
        or len(expected_rows) != len(set(expected_rows))
    ):
        errors.append("benchmark run routing.expected_skills must be a unique non-empty string array")
        expected: set[str] = set()
    else:
        expected = set(expected_rows)
    if (
        not isinstance(actual_rows, list)
        or not all(isinstance(item, str) and item for item in actual_rows)
        or len(actual_rows) != len(set(actual_rows))
    ):
        errors.append("routing.activated_skills must be a unique string array")
        actual: set[str] = set()
    else:
        actual = set(actual_rows)
    unknown_skills = (expected | actual) - known_skills
    if unknown_skills:
        errors.append(f"routing references unknown skills: {sorted(unknown_skills)}")
    forbidden_rows = routing.get("forbidden_skills", [])
    forbidden = set(forbidden_rows) if isinstance(forbidden_rows, list) else set()
    if not isinstance(forbidden_rows, list) or not all(isinstance(item, str) and item for item in forbidden_rows):
        errors.append("routing.forbidden_skills must be a string array")
    forbidden_activated = sorted(actual & forbidden)
    if forbidden_activated:
        errors.append(f"routing activated forbidden skills: {forbidden_activated}")
    true_positives = len(expected & actual)
    routing_precision = true_positives / len(actual) if actual else 0.0
    routing_recall = true_positives / len(expected) if expected else 0.0
    routing_ok = (
        routing_precision >= float(thresholds["minimum_routing_precision"])
        and routing_recall >= float(thresholds["minimum_routing_recall"])
    )
    artifacts = run.get("artifacts")
    if not isinstance(artifacts, list) or not artifacts:
        errors.append("complete benchmark run needs hashed artifacts")
    else:
        for index, artifact in enumerate(artifacts):
            if not isinstance(artifact, dict):
                errors.append(f"artifacts[{index}] must be an object")
                continue
            if not str(artifact.get("path", "")).strip() or not str(artifact.get("kind", "")).strip():
                errors.append(f"artifacts[{index}] needs path and kind")
            if not re.fullmatch(r"[0-9a-f]{64}", str(artifact.get("sha256", ""))):
                errors.append(f"artifacts[{index}].sha256 must be a lower-case SHA-256")
    passed = (
        not errors
        and not false_pass
        and routing_ok
        and weighted >= float(thresholds["minimum_total_score"])
        and all(value >= float(thresholds["minimum_dimension_percent"]) for value in dimension_percents.values())
        and str(run.get("decision", "")).upper() == "PASS"
    )
    return {
        "run": str(path),
        "gate": "PASS" if passed else "BLOCKED",
        "score": round(weighted, 2),
        "dimension_percents": dimension_percents,
        "routing_ok": routing_ok,
        "routing_precision": round(routing_precision, 3),
        "routing_recall": round(routing_recall, 3),
        "unexpected_skills": sorted(actual - expected),
        "missing_skills": sorted(expected - actual),
        "false_pass": false_pass,
        "errors": errors,
    }


def aggregate(directory: Path) -> dict:
    rubric, cases, _, _ = corpus()
    results = [score_run(path) for path in sorted(directory.glob("*.json"))]
    complete = [row for row in results if not row["errors"]]
    raw_runs = [load(Path(row["run"])) for row in complete]
    current = [(row, raw) for row, raw in zip(complete, raw_runs) if raw.get("variant") == "plugin-current"]
    counts = Counter(raw.get("case_id") for _, raw in current)
    minimum = int(rubric["release_thresholds"]["minimum_runs_per_case"])
    coverage_ok = all(counts.get(case_id, 0) >= minimum for case_id in cases)
    false_passes = sum(1 for row, _ in current if row["false_pass"])
    passed_runs = sum(1 for row, _ in current if row["gate"] == "PASS")
    scores = sorted(row["score"] for row, _ in current)
    median = scores[len(scores) // 2] if scores else 0
    baseline_rows = [raw for _, raw in zip(complete, raw_runs) if raw.get("variant") in {"no-plugin", "previous-release"}]
    baseline_counts = Counter(raw.get("case_id") for raw in baseline_rows)
    baseline_coverage_ok = all(baseline_counts.get(case_id, 0) >= 1 for case_id in cases)
    blind_comparisons = [raw.get("blind_comparison", {}).get("winner") for _, raw in current if raw.get("blind_comparison")]
    blind_comparison_coverage_ok = bool(current) and len(blind_comparisons) == len(current)
    win_rate = (sum(1 for value in blind_comparisons if value == "plugin-current") / len(blind_comparisons)) if blind_comparisons else 0
    mean_precision = sum(row["routing_precision"] for row, _ in current) / len(current) if current else 0
    mean_recall = sum(row["routing_recall"] for row, _ in current) / len(current) if current else 0
    thresholds = rubric["release_thresholds"]
    gate = "PASS" if (
        coverage_ok
        and current
        and passed_runs == len(current)
        and false_passes <= int(thresholds["maximum_blocker_high_false_passes"])
        and baseline_coverage_ok
        and blind_comparison_coverage_ok
        and win_rate >= float(thresholds["minimum_blind_baseline_win_rate"])
        and mean_precision >= float(thresholds["minimum_routing_precision"])
        and mean_recall >= float(thresholds["minimum_routing_recall"])
    ) else "BLOCKED"
    return {
        "gate": gate,
        "current_runs": len(current),
        "case_counts": dict(sorted(counts.items())),
        "coverage_ok": coverage_ok,
        "passed_runs": passed_runs,
        "false_passes": false_passes,
        "median_score": median,
        "baseline_runs": len(baseline_rows),
        "baseline_case_counts": dict(sorted(baseline_counts.items())),
        "baseline_coverage_ok": baseline_coverage_ok,
        "blind_comparison_coverage_ok": blind_comparison_coverage_ok,
        "blind_baseline_win_rate": round(win_rate, 3),
        "routing_precision": round(mean_precision, 3),
        "routing_recall": round(mean_recall, 3),
        "results": results,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("validate")
    score = sub.add_parser("score")
    score.add_argument("run")
    release = sub.add_parser("aggregate")
    release.add_argument("directory")
    args = parser.parse_args()
    if args.command == "validate":
        errors = validate_corpus()
        result = {"gate": "BLOCKED" if errors else "PASS", "errors": errors}
    elif args.command == "score":
        result = score_run(Path(args.run).resolve())
    else:
        result = aggregate(Path(args.directory).resolve())
    print(json.dumps(result, indent=2))
    return 0 if result["gate"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
