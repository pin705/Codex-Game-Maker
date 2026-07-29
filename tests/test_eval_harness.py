import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("cgm_eval", ROOT / "evals/run_eval.py")
assert SPEC and SPEC.loader
EVAL = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(EVAL)


class EvalHarnessTests(unittest.TestCase):
    def test_corpus_is_valid(self) -> None:
        self.assertEqual(EVAL.validate_corpus(), [])

    def test_high_quality_independent_run_passes(self) -> None:
        rubric, cases, _, _ = EVAL.corpus()
        case_id = next(iter(cases))
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "run.json"
            path.write_text(json.dumps({
                "schema_version": 1,
                "status": "complete",
                "run_id": "fixture-run",
                "case_id": case_id,
                "variant": "plugin-current",
                "brief_sha256": "a" * 64,
                "plugin": {"version": "1.0.0", "commit": "fixture"},
                "agent": {"model": "fixture-model", "reasoning_effort": "high", "context_mode": "fresh-task"},
                "timing": {"started_at": "2026-07-29T00:00:00Z", "finished_at": "2026-07-29T00:10:00Z", "duration_seconds": 600},
                "routing": {"expected_skills": ["game-studio-start", "game-studio-build"], "activated_skills": ["game-studio-start", "game-studio-build"], "forbidden_skills": []},
                "scores": {row["id"]: 4.5 for row in rubric["dimensions"]},
                "review": {"reviewer": "Independent Fixture", "mode": "independent-agent", "independence": "Did not author output", "blind": True},
                "known_defects": [],
                "decision": "PASS",
                "artifacts": [{"path": "release/game.zip", "kind": "build", "sha256": "c" * 64}],
            }), encoding="utf-8")
            result = EVAL.score_run(path)
        self.assertEqual(result["gate"], "PASS", result)

    def test_known_severe_defect_cannot_pass(self) -> None:
        rubric, cases, _, _ = EVAL.corpus()
        case_id = next(iter(cases))
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "run.json"
            path.write_text(json.dumps({
                "schema_version": 1,
                "status": "complete",
                "run_id": "false-pass",
                "case_id": case_id,
                "variant": "plugin-current",
                "brief_sha256": "b" * 64,
                "plugin": {"version": "1.0.0", "commit": "fixture"},
                "agent": {"model": "fixture-model", "reasoning_effort": "high", "context_mode": "fresh-task"},
                "routing": {"expected_skills": ["game-studio-build"], "activated_skills": [], "forbidden_skills": []},
                "scores": {row["id"]: 5 for row in rubric["dimensions"]},
                "review": {"reviewer": "Independent Fixture", "mode": "human", "independence": "Did not author output", "blind": True},
                "known_defects": ["generic-dashboard-ui"],
                "decision": "PASS",
                "artifacts": [],
            }), encoding="utf-8")
            result = EVAL.score_run(path)
        self.assertEqual(result["gate"], "BLOCKED")
        self.assertTrue(result["false_pass"])

    def test_unnecessary_skill_activation_fails_routing_precision(self) -> None:
        rubric, cases, _, _ = EVAL.corpus()
        case_id = next(iter(cases))
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "run.json"
            path.write_text(json.dumps({
                "schema_version": 1,
                "status": "complete",
                "run_id": "routing-overactivation",
                "case_id": case_id,
                "variant": "plugin-current",
                "brief_sha256": "d" * 64,
                "plugin": {"version": "1.0.0", "commit": "abcdef0"},
                "agent": {"model": "fixture-model", "reasoning_effort": "high", "context_mode": "fresh-task"},
                "timing": {"started_at": "2026-07-29T00:00:00Z", "finished_at": "2026-07-29T00:10:00Z", "duration_seconds": 600},
                "routing": {"expected_skills": ["game-studio-build"], "activated_skills": ["game-studio-build", "game-studio-marketing"], "forbidden_skills": ["game-studio-marketing"]},
                "scores": {row["id"]: 5 for row in rubric["dimensions"]},
                "review": {"reviewer": "Independent Fixture", "mode": "independent-agent", "independence": "Did not author output", "blind": True},
                "known_defects": [],
                "decision": "PASS",
                "artifacts": [{"path": "release/game.zip", "kind": "build", "sha256": "e" * 64}],
            }), encoding="utf-8")
            result = EVAL.score_run(path)
        self.assertEqual(result["gate"], "BLOCKED")
        self.assertEqual(result["routing_precision"], 0.5)
        self.assertEqual(result["unexpected_skills"], ["game-studio-marketing"])

    def test_aggregate_without_real_runs_remains_blocked(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            result = EVAL.aggregate(Path(temp))
        self.assertEqual(result["gate"], "BLOCKED")
        self.assertFalse(result["coverage_ok"])
        self.assertFalse(result["baseline_coverage_ok"])


if __name__ == "__main__":
    unittest.main()
