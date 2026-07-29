#!/usr/bin/env python3
"""Run project-owned quality commands without a shell and record tamper-evident inputs."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR / "lib"))

from cgm_validation import (  # noqa: E402
    git_commit,
    git_dirty,
    is_within,
    project_fingerprint,
    resolve_project_path,
    sha256_file,
    sha256_path,
    sha256_json,
    utc_now,
)


def expand_arg(value: str, root: Path, godot: str) -> str:
    return value.replace("{root}", str(root)).replace("{godot}", godot)


def artifact_records(root: Path, raw_values: Any) -> tuple[list[dict], list[str]]:
    records: list[dict] = []
    errors: list[str] = []
    for raw in raw_values if isinstance(raw_values, list) else []:
        path = resolve_project_path(root, str(raw))
        if path is None or not path.exists() or not (path.resolve().is_relative_to(root.resolve())):
            errors.append(f"Missing expected artifact: {raw}")
            continue
        records.append({"path": str(raw), "sha256": sha256_path(path), "size": path.stat().st_size if path.is_file() else None})
    return records, errors


def run_quality(root: Path, manifest_path: Path, report_path: Path, profile: str, command_ids: list[str]) -> dict:
    manifest = json.loads(manifest_path.read_text(encoding="utf-8-sig"))
    if not isinstance(manifest, dict) or not isinstance(manifest.get("commands"), list):
        raise ValueError("quality-command-manifest.json must contain a commands array")
    configured_ids = [str(row.get("id", "")) for row in manifest["commands"] if isinstance(row, dict)]
    if len(configured_ids) != len(set(configured_ids)):
        raise ValueError("quality command IDs must be unique")

    configured_godot = str(manifest.get("godot_path", "")).strip()
    godot_path = configured_godot
    if godot_path:
        resolved = resolve_project_path(root, godot_path)
        godot_path = str(resolved) if resolved else godot_path
    else:
        godot_path = os.environ.get("GODOT", "godot")

    log_dir = report_path.parent / "commands"
    log_dir.mkdir(parents=True, exist_ok=True)
    results: list[dict] = []
    selected = []
    for row in manifest["commands"]:
        if not isinstance(row, dict):
            continue
        required_for = row.get("required_for", [])
        if command_ids and str(row.get("id")) not in command_ids:
            continue
        if not command_ids and profile != "all" and profile not in required_for:
            continue
        selected.append(row)

    started_at = utc_now()
    for row in selected:
        command_id = str(row.get("id", "")).strip()
        argv_raw = row.get("argv")
        result: dict[str, Any] = {"id": command_id, "status": "BLOCKED", "returncode": None, "duration_seconds": 0}
        if (
            not re.fullmatch(r"[a-z0-9][a-z0-9_-]{0,63}", command_id)
            or not isinstance(argv_raw, list)
            or not argv_raw
            or not all(isinstance(item, str) and item for item in argv_raw)
        ):
            result["error"] = "Command id and non-empty argv string array are required"
            results.append(result)
            continue

        executable = Path(argv_raw[0]).name.lower()
        shell_code_flags = {"-c", "-command", "/c", "/k"}
        no_op_executables = {"true", "false", "echo", "printf", "ver", "cmd.exe"}
        if executable in no_op_executables or (executable in {"sh", "bash", "zsh", "fish", "cmd", "powershell", "pwsh"} and shell_code_flags.intersection({item.lower() for item in argv_raw[1:]})):
            result["error"] = "Shell snippets and no-op commands are not valid quality evidence"
            results.append(result)
            continue

        cwd = resolve_project_path(root, str(row.get("cwd", ".")))
        if cwd is None or not cwd.is_dir() or not is_within(root, cwd):
            result["error"] = "Command cwd must be an existing directory inside the project root"
            results.append(result)
            continue

        argv = [expand_arg(value, root, godot_path) for value in argv_raw]
        timeout_seconds = int(row.get("timeout_seconds", 300))
        if timeout_seconds < 1 or timeout_seconds > 21600:
            result["error"] = "timeout_seconds must be between 1 and 21600"
            results.append(result)
            continue
        stdout_path = log_dir / f"{command_id}.stdout.log"
        stderr_path = log_dir / f"{command_id}.stderr.log"
        start = time.monotonic()
        try:
            completed = subprocess.run(
                argv,
                cwd=str(cwd),
                capture_output=True,
                text=True,
                timeout=max(1, timeout_seconds),
                check=False,
                env=os.environ.copy(),
            )
            stdout_path.write_text(completed.stdout, encoding="utf-8")
            stderr_path.write_text(completed.stderr, encoding="utf-8")
            artifacts, artifact_errors = artifact_records(root, row.get("expected_artifacts", []))
            output_bytes = len(completed.stdout.encode("utf-8")) + len(completed.stderr.encode("utf-8"))
            result.update(
                returncode=completed.returncode,
                status="PASS" if completed.returncode == 0 and not artifact_errors and (output_bytes > 0 or artifacts) else "BLOCKED",
                stdout=str(stdout_path.relative_to(root)),
                stderr=str(stderr_path.relative_to(root)),
                stdout_sha256=sha256_file(stdout_path),
                stderr_sha256=sha256_file(stderr_path),
                artifacts=artifacts,
                argv=argv,
                command_sha256=sha256_json(row),
                output_bytes=output_bytes,
            )
            if artifact_errors:
                result["artifact_errors"] = artifact_errors
            if output_bytes == 0 and not artifacts:
                result["error"] = "Passing commands must leave non-empty log or artifact evidence"
        except subprocess.TimeoutExpired as exc:
            stdout_path.write_text(exc.stdout or "", encoding="utf-8")
            stderr_path.write_text(exc.stderr or "", encoding="utf-8")
            result["error"] = f"Timed out after {timeout_seconds}s"
        except OSError as exc:
            result["error"] = str(exc)
        result["duration_seconds"] = round(time.monotonic() - start, 3)
        results.append(result)

    godot_probe: dict[str, Any] = {"path": godot_path, "status": "BLOCKED", "version": ""}
    try:
        probe = subprocess.run(
            [godot_path, "--version"],
            cwd=str(root),
            capture_output=True,
            text=True,
            timeout=15,
            check=False,
        )
        version_output = (probe.stdout or probe.stderr).strip()
        godot_probe.update(
            status="PASS" if probe.returncode == 0 and version_output else "BLOCKED",
            returncode=probe.returncode,
            version=version_output.splitlines()[0] if version_output else "",
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        godot_probe["error"] = str(exc)

    report = {
        "schema_version": 2,
        "profile": profile,
        "started_at": started_at,
        "finished_at": utc_now(),
        "manifest": str(manifest_path.relative_to(root)),
        "manifest_sha256": sha256_file(manifest_path),
        "project_fingerprint": project_fingerprint(root),
        "git_commit": git_commit(root),
        "git_dirty": git_dirty(root),
        "godot": godot_probe,
        "results": results,
    }
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    return report


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".")
    parser.add_argument("--manifest", default="production/quality-command-manifest.json")
    parser.add_argument("--report", default="production/evidence/quality-run.json")
    parser.add_argument("--profile", choices=("player_ready", "commercial_release", "all"), default="all")
    parser.add_argument("--command", action="append", default=[])
    args = parser.parse_args()
    root = Path(args.root).resolve()
    manifest_path = resolve_project_path(root, args.manifest)
    report_path = resolve_project_path(root, args.report)
    if (
        manifest_path is None
        or not manifest_path.is_file()
        or not manifest_path.resolve().is_relative_to(root.resolve())
        or report_path is None
        or not report_path.resolve().is_relative_to(root.resolve())
    ):
        print(json.dumps({"gate": "BLOCKED", "error": "Quality manifest is missing or report path is invalid"}, indent=2))
        return 1
    try:
        report = run_quality(root, manifest_path, report_path, args.profile, args.command)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(json.dumps({"gate": "BLOCKED", "error": str(exc)}, indent=2))
        return 1
    blocked = [row for row in report["results"] if row.get("status") != "PASS"]
    gate = "BLOCKED" if blocked or not report["results"] else "PASS"
    print(json.dumps({"gate": gate, "report": str(report_path), "results": report["results"]}, indent=2))
    return 1 if gate == "BLOCKED" else 0


if __name__ == "__main__":
    raise SystemExit(main())
