#!/usr/bin/env python3
"""Repository-level validation for the canonical Codex Game Maker plugin."""

from __future__ import annotations

import ast
import json
import re
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "plugins" / "codex-game-maker"
EVALS = ROOT / "evals"
RELATIVE_RESOURCE = re.compile(
    r"(?P<path>(?:\.\./)+(?:references|scripts|tools)/[^\s`\"')>,]+)"
)
ID_PATTERN = re.compile(r"[a-z0-9][a-z0-9-]*")
SEMVER_PATTERN = re.compile(r"(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)")

REQUIRED_REPOSITORY_FILES = (
    ".github/CODEOWNERS",
    ".github/ISSUE_TEMPLATE/bug.yml",
    ".github/ISSUE_TEMPLATE/config.yml",
    ".github/pull_request_template.md",
    ".github/workflows/nightly-runtime.yml",
    ".github/workflows/plugin-validate.yml",
    ".github/workflows/release.yml",
    "SECURITY.md",
    "SUPPORT.md",
    "docs/RELEASE_POLICY.md",
    "evals/EVALUATION.md",
    "evals/benchmark-cases.json",
    "evals/negative-corpus.json",
    "evals/routing-corpus.json",
    "evals/rubric.json",
    "evals/run_eval.py",
    "evals/templates/eval-run.json",
    "requirements-dev.txt",
    "scripts/build_release.py",
    "tests/run_godot_smoke.py",
    "tests/verify_godot_policy_source.py",
    "tests/fixtures/godot-smoke/export_presets.cfg",
    "tests/fixtures/godot-smoke/main.tscn",
    "tests/fixtures/godot-smoke/project.godot",
    "tests/fixtures/godot-smoke/smoke.gd",
    "tests/fixtures/godot-smoke/smoke.gd.uid",
    "tests/test_asset_workflows_style.py",
    "tests/test_audio_qa.py",
    "tests/test_cgm_cli.py",
    "tests/test_eval_harness.py",
    "tests/test_install_godot.py",
    "tests/test_migration.py",
    "tests/test_plugin_contract_validator.py",
    "tests/test_style_lock.py",
    "tests/validate_release.py",
)

REQUIRED_PLUGIN_FILES = (
    "references/templates/session-state.md",
    "references/templates/style-lock.json",
    "scripts/audio_qa.py",
    "scripts/migrate_project.py",
    "scripts/style_lock.py",
)

STYLE_ANCHORS = (
    "materials",
    "shape_language",
    "camera_and_view",
    "lighting",
    "palette_roles",
    "typography_roles",
    "detail_density",
    "motion_and_fx",
)

STYLE_BOUND_JSON_TEMPLATES = (
    "asset-coverage.json",
    "audio-manifest.json",
    "player-ready-evidence.json",
    "visual-quality-contract.json",
)


def fail(message: str) -> None:
    raise SystemExit(message)


def load_json_object(path: Path) -> dict:
    try:
        value = json.loads(path.read_text(encoding="utf-8-sig"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"Invalid JSON file {path.relative_to(ROOT)}: {exc}")
    if not isinstance(value, dict):
        fail(f"Expected a JSON object: {path.relative_to(ROOT)}")
    return value


def non_empty_string(value: object) -> bool:
    return isinstance(value, str) and bool(value.strip())


def validate_required_files() -> None:
    for relative in REQUIRED_REPOSITORY_FILES:
        path = ROOT / relative
        if not path.is_file() or path.stat().st_size == 0:
            fail(f"Missing or empty required repository file: {relative}")
    for relative in REQUIRED_PLUGIN_FILES:
        path = PACKAGE / relative
        if not path.is_file() or path.stat().st_size == 0:
            fail(f"Missing or empty required plugin file: plugins/codex-game-maker/{relative}")


def load_json_and_yaml() -> None:
    candidates: set[Path] = set()
    candidates.add(PACKAGE / ".codex-plugin" / "plugin.json")
    candidates.update((PACKAGE / "references" / "templates").glob("*.json"))
    candidates.update((PACKAGE / "references" / "policies").glob("*.json"))
    candidates.update((PACKAGE / "references" / "commands").glob("*.yaml"))
    candidates.update((PACKAGE / "references" / "workflows").glob("*.yaml"))
    candidates.update((PACKAGE / "skills").glob("*/agents/openai.yaml"))
    candidates.update(EVALS.glob("*.json"))
    candidates.update((EVALS / "templates").glob("*.json"))
    candidates.update((ROOT / ".github" / "ISSUE_TEMPLATE").glob("*.yml"))
    candidates.update((ROOT / ".github" / "workflows").glob("*.yml"))

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
    ignore_lines = {
        line.strip().rstrip("/")
        for line in (ROOT / ".gitignore").read_text(encoding="utf-8-sig").splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    }
    continuity_paths = {"design/art", "production/session-state"}
    if ignore_lines & continuity_paths:
        fail("Style lock and session-state continuity paths must remain version-control eligible")


def validate_counts() -> None:
    expected = {
        "skills": (len([p for p in (PACKAGE / "skills").iterdir() if p.is_dir()]), 23),
        "templates": (len([p for p in (PACKAGE / "references" / "templates").iterdir() if p.is_file()]), 60),
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


def unique_rows(data: dict, label: str, minimum: int) -> list[dict]:
    rows = data.get("cases")
    if not isinstance(rows, list) or len(rows) < minimum or not all(isinstance(row, dict) for row in rows):
        fail(f"{label} must contain at least {minimum} object cases")
    ids = [row.get("id") for row in rows]
    if (
        len(ids) != len(set(ids))
        or not all(non_empty_string(item) and ID_PATTERN.fullmatch(str(item)) for item in ids)
    ):
        fail(f"{label} case IDs must be unique, non-empty lower-case hyphen IDs")
    return rows


def string_list(value: object, label: str, allow_empty: bool = False) -> list[str]:
    if not isinstance(value, list) or (not value and not allow_empty):
        fail(f"{label} must be a{' possibly empty' if allow_empty else ' non-empty'} string array")
    if not all(non_empty_string(item) for item in value) or len(value) != len(set(value)):
        fail(f"{label} must contain unique non-empty strings")
    return [str(item) for item in value]


def validate_eval_corpus() -> None:
    benchmark = load_json_object(EVALS / "benchmark-cases.json")
    routing = load_json_object(EVALS / "routing-corpus.json")
    negatives = load_json_object(EVALS / "negative-corpus.json")
    rubric = load_json_object(EVALS / "rubric.json")
    run_template = load_json_object(EVALS / "templates" / "eval-run.json")
    for label, data in (
        ("benchmark corpus", benchmark),
        ("routing corpus", routing),
        ("negative corpus", negatives),
        ("rubric", rubric),
        ("eval-run template", run_template),
    ):
        if data.get("schema_version") != 1:
            fail(f"{label} must use schema_version 1")

    benchmark_rows = unique_rows(benchmark, "Benchmark corpus", 6)
    for row in benchmark_rows:
        case_id = row["id"]
        for field in ("genre", "mode", "prompt"):
            if not non_empty_string(row.get(field)):
                fail(f"Benchmark case {case_id} needs {field}")
        string_list(row.get("must_cover"), f"Benchmark case {case_id} must_cover")

    skill_names = {
        path.parent.name for path in (PACKAGE / "skills").glob("*/SKILL.md")
    }
    routing_rows = unique_rows(routing, "Routing corpus", 24)
    covered_skills: set[str] = set()
    has_negative = False
    has_multi_skill = False
    for row in routing_rows:
        case_id = row["id"]
        if not non_empty_string(row.get("prompt")):
            fail(f"Routing case {case_id} needs prompt")
        expected = set(string_list(row.get("expected_skills"), f"Routing case {case_id} expected_skills", allow_empty=True))
        forbidden = set(string_list(row.get("forbidden_skills"), f"Routing case {case_id} forbidden_skills", allow_empty=True))
        if expected & forbidden:
            fail(f"Routing case {case_id} cannot both expect and forbid the same skill")
        unknown = (expected | forbidden) - skill_names
        if unknown:
            fail(f"Routing case {case_id} references unknown skills: {sorted(unknown)}")
        covered_skills.update(expected)
        has_negative = has_negative or (not expected and bool(forbidden))
        has_multi_skill = has_multi_skill or len(expected) > 1
    if covered_skills != skill_names:
        fail(f"Routing corpus does not cover every skill; missing: {sorted(skill_names - covered_skills)}")
    if not has_negative or not has_multi_skill:
        fail("Routing corpus needs both hard-negative and multi-skill overlap cases")

    negative_rows = unique_rows(negatives, "Negative corpus", 10)
    for row in negative_rows:
        if row.get("severity") not in {"blocker", "high"} or not non_empty_string(row.get("defect")):
            fail(f"Negative case {row['id']} needs blocker/high severity and a defect")

    scale = rubric.get("score_scale")
    if not isinstance(scale, dict):
        fail("Eval rubric needs score_scale")
    try:
        scale_minimum = float(scale.get("minimum"))
        scale_maximum = float(scale.get("maximum"))
    except (TypeError, ValueError):
        fail("Eval rubric score scale must be numeric")
    if scale_minimum < 0 or scale_maximum <= scale_minimum:
        fail("Eval rubric score scale must be ordered and non-negative")
    dimensions = rubric.get("dimensions")
    if not isinstance(dimensions, list) or not dimensions or not all(isinstance(row, dict) for row in dimensions):
        fail("Eval rubric needs object dimensions")
    dimension_ids = [row.get("id") for row in dimensions]
    if len(dimension_ids) != len(set(dimension_ids)) or not all(
        non_empty_string(item) and ID_PATTERN.fullmatch(str(item)) for item in dimension_ids
    ):
        fail("Eval rubric dimension IDs must be unique lower-case hyphen IDs")
    try:
        weights = [float(row.get("weight")) for row in dimensions]
    except (TypeError, ValueError):
        fail("Eval rubric dimension weights must be numeric")
    if any(weight <= 0 for weight in weights) or abs(sum(weights) - 100.0) > 1e-9:
        fail("Eval rubric dimension weights must be positive and total 100")
    if not all(non_empty_string(row.get("description")) for row in dimensions):
        fail("Every eval rubric dimension needs a description")
    thresholds = rubric.get("release_thresholds")
    if not isinstance(thresholds, dict):
        fail("Eval rubric needs release_thresholds")
    threshold_fields = {
        "minimum_total_score",
        "minimum_dimension_percent",
        "minimum_runs_per_case",
        "minimum_blind_baseline_win_rate",
        "minimum_routing_precision",
        "minimum_routing_recall",
        "maximum_blocker_high_false_passes",
    }
    if not threshold_fields.issubset(thresholds):
        fail(f"Eval rubric is missing release thresholds: {sorted(threshold_fields - set(thresholds))}")
    try:
        if not 0 <= float(thresholds["minimum_total_score"]) <= 100:
            raise ValueError
        if not 0 <= float(thresholds["minimum_dimension_percent"]) <= 100:
            raise ValueError
        if int(thresholds["minimum_runs_per_case"]) < 3:
            raise ValueError
        for field in ("minimum_blind_baseline_win_rate", "minimum_routing_precision", "minimum_routing_recall"):
            if not 0 <= float(thresholds[field]) <= 1:
                raise ValueError
        if int(thresholds["maximum_blocker_high_false_passes"]) != 0:
            raise ValueError
    except (TypeError, ValueError):
        fail("Eval release thresholds contain invalid or unsafe values")

    required_run_fields = {
        "status", "run_id", "case_id", "variant", "brief_sha256", "plugin",
        "agent", "timing", "routing", "scores", "review", "known_defects",
        "decision", "artifacts", "blind_comparison", "notes",
    }
    if not required_run_fields.issubset(run_template):
        fail(f"eval-run template is missing fields: {sorted(required_run_fields - set(run_template))}")
    if run_template.get("status") != "planned" or run_template.get("decision") != "BLOCKED":
        fail("eval-run template must default to planned and BLOCKED")
    for field, required in (
        ("plugin", {"version", "commit"}),
        ("agent", {"model", "reasoning_effort", "context_mode"}),
        ("timing", {"started_at", "finished_at", "duration_seconds"}),
        ("routing", {"expected_skills", "activated_skills", "forbidden_skills"}),
        ("review", {"reviewer", "mode", "independence", "blind"}),
    ):
        value = run_template.get(field)
        if not isinstance(value, dict) or not required.issubset(value):
            fail(f"eval-run template {field} is missing fields: {sorted(required - set(value or {}))}")
    if run_template["review"].get("mode") not in {"human", "independent-agent"} or run_template["review"].get("blind") is not True:
        fail("eval-run template must default to a blind human or independent-agent review")
    for field in ("known_defects", "artifacts"):
        if not isinstance(run_template.get(field), list):
            fail(f"eval-run template {field} must be an array")
    artifact_rows = run_template.get("artifacts", [])
    if not artifact_rows or not all(
        isinstance(row, dict) and {"path", "kind", "sha256"}.issubset(row)
        for row in artifact_rows
    ):
        fail("eval-run template needs path/kind/sha256 artifact rows")
    comparison = run_template.get("blind_comparison")
    if not isinstance(comparison, dict) or not {"baseline_run_id", "winner", "rationale"}.issubset(comparison):
        fail("eval-run template needs complete blind_comparison metadata")
    if not isinstance(run_template.get("scores"), dict):
        fail("eval-run template scores must be an object")

    evaluation_doc = (EVALS / "EVALUATION.md").read_text(encoding="utf-8-sig")
    for command in ("run_eval.py validate", "run_eval.py score", "run_eval.py aggregate"):
        if command not in evaluation_doc:
            fail(f"Evaluation guide is missing command: {command}")


def validate_style_and_session_contracts() -> None:
    templates = PACKAGE / "references" / "templates"
    style = load_json_object(templates / "style-lock.json")
    if style.get("schema_version") != 1 or style.get("status") != "planned":
        fail("Style-lock template must use schema_version 1 and planned status")
    if not non_empty_string(style.get("style_id")) or not SEMVER_PATTERN.fullmatch(str(style.get("style_version", ""))):
        fail("Style-lock template needs a style ID and semantic style_version")
    if style.get("source_art_bible") != "design/art/art-bible.md":
        fail("Style-lock template must bind design/art/art-bible.md")
    for field in ("art_bible_sha256", "digest", "identity_rule", "forbidden_drift", "approved_families", "locked_references", "change_control"):
        if field not in style:
            fail(f"Style-lock template is missing {field}")
    anchors = style.get("anchors")
    if not isinstance(anchors, dict):
        fail("Style-lock template needs anchors")
    for field in STYLE_ANCHORS:
        if field not in anchors or not isinstance(anchors[field], list):
            fail(f"Style-lock template needs array anchors.{field}")
    locked_references = style.get("locked_references")
    if not isinstance(locked_references, list) or not locked_references or not all(isinstance(row, dict) for row in locked_references):
        fail("Style-lock template needs a locked-reference row")
    if not {"path", "sha256", "families"}.issubset(locked_references[0]):
        fail("Style-lock reference rows need path, sha256, and families")
    change_control = style.get("change_control")
    if not isinstance(change_control, dict) or not {"previous_digest", "change_reason", "approved_by", "approved_on"}.issubset(change_control):
        fail("Style-lock template needs complete change_control metadata")

    for filename in STYLE_BOUND_JSON_TEMPLATES:
        data = load_json_object(templates / filename)
        binding = data.get("style_lock")
        if not isinstance(binding, dict) or binding.get("path") != "design/art/style-lock.json":
            fail(f"{filename} must bind design/art/style-lock.json")
        if not {"style_version", "sha256"}.issubset(binding):
            fail(f"{filename} style_lock needs style_version and sha256")

    asset_manifest = yaml.safe_load((templates / "asset-manifest.yaml").read_text(encoding="utf-8-sig"))
    asset_binding = asset_manifest.get("style_lock") if isinstance(asset_manifest, dict) else None
    if not isinstance(asset_binding, dict) or asset_binding.get("path") != "design/art/style-lock.json" or not {"style_version", "sha256"}.issubset(asset_binding):
        fail("asset-manifest.yaml must bind the current style lock")
    prompt_spec = yaml.safe_load((templates / "asset-prompt-spec.yaml").read_text(encoding="utf-8-sig"))
    prompt_binding = prompt_spec.get("style_lock") if isinstance(prompt_spec, dict) else None
    prompt_fields = {"path", "style_version", "style_lock_sha256", "art_bible_sha256", "locked_reference_paths", "forbidden_drift"}
    if not isinstance(prompt_binding, dict) or prompt_binding.get("path") != "design/art/style-lock.json" or not prompt_fields.issubset(prompt_binding):
        fail("asset-prompt-spec.yaml must carry complete style-lock provenance")

    markdown_requirements = {
        "art-bible.md": ("Canonical style lock: `design/art/style-lock.json`", "Style version and digest:"),
        "ui-ux-spec.md": ("Style lock: `design/art/style-lock.json`", "Style version:", "Style SHA-256:"),
        "session-state.md": (
            "Style lock: `design/art/style-lock.json`", "Style version:", "Style SHA-256:",
            "Art bible SHA-256:", "Last verified build:", "Last quality report:",
            "Open blocker/high findings:", "Next executable action:", "Resume notes:",
        ),
    }
    for filename, markers in markdown_requirements.items():
        text = (templates / filename).read_text(encoding="utf-8-sig")
        for marker in markers:
            if marker not in text:
                fail(f"{filename} is missing continuity field: {marker}")


def validate_audio_migration_release_support() -> None:
    templates = PACKAGE / "references" / "templates"
    audio = load_json_object(templates / "audio-manifest.json")
    policy = audio.get("qa_policy")
    policy_fields = {
        "minimum_duration_seconds", "minimum_sample_rate", "minimum_rms_dbfs",
        "maximum_rms_dbfs", "maximum_peak_dbfs", "maximum_loop_seam_normalized",
    }
    if not isinstance(policy, dict) or not policy_fields.issubset(policy):
        fail(f"Audio manifest is missing QA policy fields: {sorted(policy_fields - set(policy or {}))}")
    if audio.get("qa_report") != "production/evidence/audio-qa.json":
        fail("Audio manifest must bind production/evidence/audio-qa.json")

    python_entrypoints = {
        PACKAGE / "scripts/audio_qa.py": ("def wav_metrics", "def evaluate", "qa_policy", "audio-qa.json"),
        PACKAGE / "scripts/migrate_project.py": ("def migrate", ".cgm-backups", "dry_run", "style-lock.json"),
        PACKAGE / "scripts/style_lock.py": ("def lock_digest", "seal", "verify", "art_bible_sha256"),
        EVALS / "run_eval.py": ("def validate_corpus", "def score_run", "def aggregate"),
        ROOT / "scripts/build_release.py": ("zipfile", "SHA256SUMS.txt", "sbom"),
        ROOT / "tests/validate_release.py": ("evals/run_eval.py", "agents/openai.yaml", "SECURITY.md"),
    }
    for path, markers in python_entrypoints.items():
        text = path.read_text(encoding="utf-8-sig")
        try:
            ast.parse(text, filename=str(path))
        except SyntaxError as exc:
            fail(f"Invalid Python entrypoint {path.relative_to(ROOT)}: {exc}")
        for marker in markers:
            if marker not in text:
                fail(f"{path.relative_to(ROOT)} is missing required behavior marker: {marker}")

    support_requirements = {
        "SECURITY.md": ("# Security Policy", "## Reporting", "## Trust Boundaries"),
        "SUPPORT.md": ("# Support", "Codex Game Maker version", "sanitized"),
        "docs/RELEASE_POLICY.md": ("# Release Policy", "semantic versioning", "Release CI", "migration"),
    }
    for relative, markers in support_requirements.items():
        text = (ROOT / relative).read_text(encoding="utf-8-sig")
        for marker in markers:
            if marker not in text:
                fail(f"{relative} is missing required release/support section: {marker}")


def validate_godot_policy() -> None:
    path = PACKAGE / "references" / "policies" / "godot-version-policy.json"
    policy = load_json_object(path)
    version = str(policy.get("recommended_version", ""))
    if not SEMVER_PATTERN.fullmatch(version):
        fail("Godot policy recommended_version must be x.y.z")
    minor = ".".join(version.split(".")[:2])
    supported = string_list(policy.get("supported_minor_lines"), "Godot supported_minor_lines")
    partial = string_list(policy.get("security_platform_support_only"), "Godot security_platform_support_only", allow_empty=True)
    prerelease = string_list(policy.get("prerelease_minor_lines"), "Godot prerelease_minor_lines", allow_empty=True)
    eol = string_list(policy.get("eol_minor_lines"), "Godot eol_minor_lines", allow_empty=True)
    groups = [set(supported), set(partial), set(prerelease), set(eol)]
    if minor not in supported:
        fail("Recommended Godot version must belong to a fully supported line")
    for index, left in enumerate(groups):
        for right in groups[index + 1 :]:
            if left & right:
                fail(f"Godot policy support groups overlap: {sorted(left & right)}")
    release_id = f"{version}-stable"
    releases = policy.get("verified_archives")
    release = releases.get(release_id) if isinstance(releases, dict) else None
    if not isinstance(release, dict) or release.get("checksum_algorithm") != "sha512":
        fail(f"Godot policy needs a SHA-512 release record for {release_id}")
    expected_source = (
        "https://github.com/godotengine/godot-builds/releases/download/"
        f"{release_id}/SHA512-SUMS.txt"
    )
    if release.get("checksum_source") != expected_source:
        fail("Godot checksum source must point to the matching official release")
    expected_files = {
        f"Godot_v{release_id}_export_templates.tpz",
        f"Godot_v{release_id}_linux.arm64.zip",
        f"Godot_v{release_id}_linux.x86_64.zip",
        f"Godot_v{release_id}_macos.universal.zip",
        f"Godot_v{release_id}_win64.exe.zip",
        f"Godot_v{release_id}_windows_arm64.exe.zip",
    }
    files = release.get("files")
    if not isinstance(files, dict) or set(files) != expected_files:
        fail(f"Godot policy must pin exactly the supported editor/template archives: {sorted(expected_files)}")
    if not all(isinstance(value, str) and re.fullmatch(r"[0-9a-f]{128}", value) for value in files.values()):
        fail("Every pinned Godot archive needs a lower-case 128-character SHA-512")


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
    validate_required_files()
    load_json_and_yaml()
    validate_skill_resources()
    validate_counts()
    validate_eval_corpus()
    validate_style_and_session_contracts()
    validate_audio_migration_release_support()
    validate_godot_policy()
    validate_dynamic_contracts()
    validate_todo_markers()
    validate_single_source()
    print("Repository validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
