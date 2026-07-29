#!/usr/bin/env python3
"""Dependency-free audio QA for player-ready manifests."""

from __future__ import annotations

import argparse
import array
import hashlib
import json
import math
import sys
import wave
from pathlib import Path
from typing import Any


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def sha256_json(value: Any) -> str:
    payload = json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def by_id(rows: Any) -> dict[str, dict[str, Any]]:
    if not isinstance(rows, list):
        return {}
    return {
        str(row.get("id")): row
        for row in rows
        if isinstance(row, dict) and str(row.get("id", ""))
    }


def project_path(root: Path, value: object) -> Path | None:
    relative = Path(str(value))
    if not str(value).strip() or relative.is_absolute():
        return None
    candidate = (root / relative).resolve()
    try:
        candidate.relative_to(root.resolve())
    except ValueError:
        return None
    return candidate


def wav_metrics(path: Path) -> dict[str, Any]:
    with wave.open(str(path), "rb") as handle:
        channels = handle.getnchannels()
        width = handle.getsampwidth()
        rate = handle.getframerate()
        frames = handle.getnframes()
        raw = handle.readframes(frames)
    typecodes = {1: "B", 2: "h", 4: "i"}
    if width not in {1, 2, 3, 4}:
        raise ValueError(f"unsupported WAV sample width: {width}")
    if width == 3:
        centered = [
            int.from_bytes(raw[index : index + 3], byteorder="little", signed=True)
            for index in range(0, len(raw), 3)
        ]
        full_scale = float((1 << 23) - 1)
    else:
        samples = array.array(typecodes[width])
        samples.frombytes(raw)
        if sys.byteorder != "little" and width > 1:
            samples.byteswap()
        centered = [int(value) for value in samples]
        full_scale = float((1 << (width * 8 - 1)) - 1)
    if width == 1:
        centered = [int(value) - 128 for value in samples]
        full_scale = 127.0
    if not centered or rate <= 0:
        raise ValueError("empty WAV")
    peak = max(abs(value) for value in centered) / full_scale
    rms = math.sqrt(sum(value * value for value in centered) / len(centered)) / full_scale
    window = min(len(centered) // 4, max(channels, int(rate * channels * 0.02)))
    if window:
        seam = math.sqrt(sum((centered[index] - centered[-window + index]) ** 2 for index in range(window)) / window) / full_scale
    else:
        seam = 1.0
    return {
        "format": "wav",
        "duration_seconds": round(frames / rate, 6),
        "sample_rate": rate,
        "channels": channels,
        "sample_width_bytes": width,
        "peak_dbfs": round(20 * math.log10(max(peak, 1e-12)), 3),
        "rms_dbfs": round(20 * math.log10(max(rms, 1e-12)), 3),
        "loop_seam_normalized": round(seam, 6),
    }


def evaluate(root: Path, manifest_path: Path) -> dict:
    manifest = json.loads(manifest_path.read_text(encoding="utf-8-sig"))
    quality_manifest_path = root / "production/quality-command-manifest.json"
    quality_report_path = root / "production/evidence/quality-run.json"
    try:
        quality_manifest = json.loads(quality_manifest_path.read_text(encoding="utf-8-sig"))
        quality_report = json.loads(quality_report_path.read_text(encoding="utf-8-sig"))
    except (OSError, json.JSONDecodeError):
        quality_manifest = {}
        quality_report = {}
    quality_commands = by_id(quality_manifest.get("commands")) if isinstance(quality_manifest, dict) else {}
    quality_results = by_id(quality_report.get("results")) if isinstance(quality_report, dict) else {}
    policy = manifest.get("qa_policy") if isinstance(manifest.get("qa_policy"), dict) else {}
    minimum_duration = float(policy.get("minimum_duration_seconds", 0.05))
    minimum_rate = int(policy.get("minimum_sample_rate", 22050))
    min_rms = float(policy.get("minimum_rms_dbfs", -36))
    max_rms = float(policy.get("maximum_rms_dbfs", -6))
    max_peak = float(policy.get("maximum_peak_dbfs", -0.1))
    max_seam = float(policy.get("maximum_loop_seam_normalized", 0.2))
    results: list[dict[str, Any]] = []
    blockers: list[dict[str, str]] = []
    for event in manifest.get("events", []):
        if not isinstance(event, dict) or str(event.get("status", "")).lower() not in {"verified", "approved", "complete", "ready"}:
            continue
        event_id = str(event.get("id", ""))
        asset = project_path(root, event.get("asset", ""))
        result: dict[str, Any] = {"id": event_id, "asset": str(event.get("asset", "")), "status": "PASS"}
        if asset is None or not asset.is_file():
            result["status"] = "BLOCKED"
            result["errors"] = ["asset missing"]
            blockers.append({"id": event_id, "error": "asset missing"})
            results.append(result)
            continue
        result["sha256"] = sha256_file(asset)
        errors: list[str] = []
        try:
            if asset.suffix.lower() == ".wav":
                metrics = wav_metrics(asset)
            else:
                metrics = event.get("qa_metrics") if isinstance(event.get("qa_metrics"), dict) else {}
                required = {
                    "duration_seconds", "sample_rate", "peak_dbfs", "rms_dbfs", "measured_by",
                    "asset_sha256", "command_id", "command_sha256", "stdout_sha256",
                }
                if not required.issubset(metrics) or metrics.get("asset_sha256") != result["sha256"]:
                    errors.append("compressed audio needs command-backed qa_metrics bound to the current asset SHA-256")
                else:
                    command_id = str(metrics.get("command_id", ""))
                    command = quality_commands.get(command_id)
                    command_result = quality_results.get(command_id)
                    stdout = project_path(root, command_result.get("stdout", "")) if command_result else None
                    if (
                        not command
                        or not command_result
                        or command_result.get("status") != "PASS"
                        or command_result.get("returncode") != 0
                        or command_result.get("command_sha256") != sha256_json(command)
                        or command_result.get("command_sha256") != metrics.get("command_sha256")
                        or not stdout
                        or not stdout.is_file()
                        or sha256_file(stdout) != metrics.get("stdout_sha256")
                    ):
                        errors.append("compressed audio qa_metrics are not bound to a current passing quality command and stdout hash")
        except (OSError, ValueError, wave.Error) as exc:
            metrics = {}
            errors.append(str(exc))
        result["metrics"] = metrics
        if metrics:
            if float(metrics.get("duration_seconds", 0)) < minimum_duration:
                errors.append("duration below policy")
            if int(metrics.get("sample_rate", 0)) < minimum_rate:
                errors.append("sample rate below policy")
            rms = float(metrics.get("rms_dbfs", -999))
            peak = float(metrics.get("peak_dbfs", 999))
            if rms < min_rms or rms > max_rms:
                errors.append("RMS dBFS outside policy")
            if peak > max_peak:
                errors.append("peak dBFS exceeds policy")
            if event.get("loop") and float(metrics.get("loop_seam_normalized", 999)) > max_seam:
                errors.append("loop seam exceeds policy")
        if errors:
            result["status"] = "BLOCKED"
            result["errors"] = errors
            blockers.extend({"id": event_id, "error": error} for error in errors)
        results.append(result)
    if not results and not manifest.get("intentional_silence"):
        blockers.append({"id": "manifest", "error": "no verified audio events to measure"})
    return {
        "schema_version": 1,
        "gate": "BLOCKED" if blockers else "PASS",
        "manifest": str(manifest_path.relative_to(root)),
        "manifest_sha256": sha256_file(manifest_path),
        "results": results,
        "blockers": blockers,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".")
    parser.add_argument("--manifest", default="design/audio/audio-manifest.json")
    parser.add_argument("--output", default="production/evidence/audio-qa.json")
    args = parser.parse_args()
    root = Path(args.root).resolve()
    manifest = project_path(root, args.manifest)
    output = project_path(root, args.output)
    if manifest is None or output is None:
        print(json.dumps({"gate": "BLOCKED", "error": "manifest and output must be project-relative paths"}, indent=2))
        return 1
    if not manifest.is_file():
        print(json.dumps({"gate": "BLOCKED", "error": f"audio manifest is missing: {args.manifest}"}, indent=2))
        return 1
    report = evaluate(root, manifest)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    return 0 if report["gate"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
