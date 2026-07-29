#!/usr/bin/env python3
"""Dependency-free validation helpers for Codex Game Maker gates."""

from __future__ import annotations

import hashlib
import json
import os
import re
import struct
import subprocess
import wave
import zlib
from datetime import date, datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Optional


PASS_STATUSES = {"pass", "passed", "verified", "approved", "complete", "locked", "ready", "submission_ready"}
NA_STATUSES = {"not_applicable", "not-applicable", "n/a"}
IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".gif", ".webp"}
AUDIO_EXTENSIONS = {".wav", ".ogg", ".mp3", ".flac"}
VIDEO_EXTENSIONS = {".mp4", ".mov", ".webm"}
MEDIA_EXTENSIONS = IMAGE_EXTENSIONS | AUDIO_EXTENSIONS | VIDEO_EXTENSIONS


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def date_is_recent(value: Any, max_age_days: int = 180) -> bool:
    try:
        verified = date.fromisoformat(str(value))
    except ValueError:
        return False
    age = (datetime.now(timezone.utc).date() - verified).days
    return 0 <= age <= max_age_days


def issue(code: str, message: str, path: Any = "", **extra: Any) -> dict:
    value = {"code": code, "message": message, "path": str(path) if path is not None else ""}
    value.update(extra)
    return value


def load_json(path: Path, blockers: list[dict], code: str = "json") -> Optional[dict]:
    if not path.is_file():
        blockers.append(issue(f"{code}.missing", f"Missing {path}", path))
        return None
    try:
        value = json.loads(path.read_text(encoding="utf-8-sig"))
    except (OSError, json.JSONDecodeError) as exc:
        blockers.append(issue(f"{code}.invalid", str(exc), path))
        return None
    if not isinstance(value, dict):
        blockers.append(issue(f"{code}.object_required", "Expected a JSON object", path))
        return None
    return value


def resolve_project_path(root: Path, raw: str) -> Optional[Path]:
    value = str(raw or "").strip()
    if not value:
        return None
    if value.startswith("res://"):
        value = value[6:]
    path = Path(value)
    return path.resolve() if path.is_absolute() else (root / path).resolve()


def is_within(root: Path, path: Path) -> bool:
    try:
        path.resolve().relative_to(root.resolve())
        return True
    except ValueError:
        return False


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def sha256_path(path: Path) -> str:
    if path.is_file():
        return sha256_file(path)
    digest = hashlib.sha256()
    if path.is_dir():
        for item in sorted(p for p in path.rglob("*") if p.is_file()):
            digest.update(str(item.relative_to(path)).encode("utf-8"))
            digest.update(sha256_file(item).encode("ascii"))
    return digest.hexdigest()


def sha256_json(value: Any) -> str:
    payload = json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def style_lock_digest(value: dict[str, Any]) -> str:
    """Hash a style lock without its self-referential digest field."""
    normalized = {key: item for key, item in value.items() if key != "digest"}
    return sha256_json(normalized)


def project_fingerprint(root: Path) -> str:
    included = {".gd", ".tscn", ".tres", ".godot", ".json", ".cfg", ".gdshader"}
    ignored_parts = {".git", ".godot", "build", ".tools", "production"}
    code_roots = {"scenes", "scripts", "src", "tests", "addons", "resources"}
    contract_paths = {
        "design/game-state-matrix.json",
        "design/art/art-bible.md",
        "design/art/style-lock.json",
        "design/assets/asset-coverage.json",
        "design/audio/audio-manifest.json",
        "design/ui/ui-ux-spec.md",
        "production/reviews/visual-quality-contract.json",
    }
    candidates: list[Path] = []
    for path in root.rglob("*"):
        relative = path.relative_to(root)
        if not path.is_file():
            continue
        relative_text = relative.as_posix()
        explicit_contract = relative_text in contract_paths or relative_text.startswith("assets/source-prompts/")
        if not explicit_contract and any(part in ignored_parts for part in relative.parts):
            continue
        if explicit_contract or path.name in {"project.godot", "export_presets.cfg"} or (relative.parts and relative.parts[0] in code_roots and path.suffix.lower() in included):
            candidates.append(path)
    digest = hashlib.sha256()
    for path in sorted(candidates):
        digest.update(str(path.relative_to(root)).encode("utf-8"))
        digest.update(sha256_file(path).encode("ascii"))
    return digest.hexdigest()


def git_commit(root: Path) -> str:
    try:
        result = subprocess.run(
            ["git", "rev-parse", "HEAD"], cwd=str(root), capture_output=True, text=True, timeout=10, check=False
        )
    except (OSError, subprocess.TimeoutExpired):
        return ""
    return result.stdout.strip() if result.returncode == 0 else ""


def git_dirty(root: Path) -> Optional[bool]:
    try:
        result = subprocess.run(
            ["git", "status", "--porcelain"], cwd=str(root), capture_output=True, text=True, timeout=10, check=False
        )
    except (OSError, subprocess.TimeoutExpired):
        return None
    return bool(result.stdout.strip()) if result.returncode == 0 else None


def _jpeg_dimensions(data: bytes) -> Optional[tuple[int, int]]:
    if not data.startswith(b"\xff\xd8"):
        return None
    index = 2
    while index + 9 < len(data):
        if data[index] != 0xFF:
            index += 1
            continue
        marker = data[index + 1]
        index += 2
        if marker in {0xD8, 0xD9}:
            continue
        if index + 2 > len(data):
            break
        length = int.from_bytes(data[index:index + 2], "big")
        if length < 2 or index + length > len(data):
            break
        if marker in {0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF}:
            height = int.from_bytes(data[index + 3:index + 5], "big")
            width = int.from_bytes(data[index + 5:index + 7], "big")
            return width, height
        index += length
    return None


def sniff_media(path: Path) -> dict:
    data = path.read_bytes()
    info: dict[str, Any] = {"kind": "unknown", "format": "unknown", "size": len(data)}
    if data.startswith(b"\x89PNG\r\n\x1a\n") and len(data) >= 24:
        width = int.from_bytes(data[16:20], "big")
        height = int.from_bytes(data[20:24], "big")
        info.update(kind="image", format="png", width=width, height=height)
        offset = 8
        saw_ihdr = saw_idat = saw_iend = False
        png_valid = True
        while offset + 12 <= len(data):
            length = int.from_bytes(data[offset:offset + 4], "big")
            end = offset + 12 + length
            if end > len(data):
                png_valid = False
                break
            chunk = data[offset + 4:offset + 8]
            payload = data[offset + 8:offset + 8 + length]
            expected_crc = int.from_bytes(data[offset + 8 + length:end], "big")
            if zlib.crc32(chunk + payload) & 0xFFFFFFFF != expected_crc:
                png_valid = False
                break
            if chunk == b"IHDR":
                saw_ihdr = length == 13 and offset == 8
            elif chunk == b"IDAT":
                saw_idat = True
            elif chunk == b"IEND":
                saw_iend = length == 0
                break
            offset = end
        if not (png_valid and saw_ihdr and saw_idat and saw_iend):
            info["invalid"] = True
    elif data.startswith((b"GIF87a", b"GIF89a")) and len(data) >= 10:
        width, height = struct.unpack("<HH", data[6:10])
        info.update(kind="image", format="gif", width=width, height=height, invalid=not data.endswith(b";"))
    elif data.startswith(b"\xff\xd8"):
        dims = _jpeg_dimensions(data)
        info.update(kind="image", format="jpeg", invalid=not data.endswith(b"\xff\xd9"))
        if dims:
            info.update(width=dims[0], height=dims[1])
    elif data.startswith(b"RIFF") and data[8:12] == b"WEBP":
        declared = int.from_bytes(data[4:8], "little") + 8 if len(data) >= 8 else 0
        info.update(kind="image", format="webp", invalid=declared > len(data))
    elif data.startswith(b"RIFF") and data[8:12] == b"WAVE":
        info.update(kind="audio", format="wav")
        try:
            with wave.open(str(path), "rb") as handle:
                rate = handle.getframerate()
                frames = handle.getnframes()
                info.update(sample_rate=rate, channels=handle.getnchannels(), duration_seconds=(frames / rate if rate else 0))
        except wave.Error:
            info["invalid"] = True
    elif data.startswith(b"OggS"):
        info.update(kind="audio", format="ogg")
    elif data.startswith(b"fLaC"):
        info.update(kind="audio", format="flac")
    elif data.startswith(b"ID3") or (len(data) >= 2 and data[0] == 0xFF and data[1] & 0xE0 == 0xE0):
        info.update(kind="audio", format="mp3")
    elif len(data) >= 12 and data[4:8] == b"ftyp":
        info.update(kind="video", format="mp4")
    elif data.startswith(b"\x1aE\xdf\xa3"):
        info.update(kind="video", format="webm")
    return info


def validate_media(
    path: Path,
    expected_kind: Optional[str] = None,
    min_width: int = 1,
    min_height: int = 1,
    min_size: int = 64,
) -> tuple[list[str], dict]:
    errors: list[str] = []
    if not path.is_file():
        return ["media file is missing"], {}
    try:
        info = sniff_media(path)
    except OSError as exc:
        return [str(exc)], {}
    ext = path.suffix.lower()
    expected_from_ext = "image" if ext in IMAGE_EXTENSIONS else "audio" if ext in AUDIO_EXTENSIONS else "video" if ext in VIDEO_EXTENSIONS else None
    if info.get("kind") == "unknown":
        errors.append("unrecognized media signature")
    if expected_from_ext and info.get("kind") != expected_from_ext:
        errors.append(f"extension {ext} does not match detected {info.get('kind')}")
    if expected_kind and info.get("kind") != expected_kind:
        errors.append(f"expected {expected_kind}, detected {info.get('kind')}")
    if info.get("size", 0) < min_size:
        errors.append(f"media is too small ({info.get('size', 0)} bytes)")
    if info.get("kind") == "image":
        width, height = info.get("width"), info.get("height")
        if width is not None and width < min_width:
            errors.append(f"image width {width} is below {min_width}")
        if height is not None and height < min_height:
            errors.append(f"image height {height} is below {min_height}")
    if info.get("kind") == "audio" and info.get("format") == "wav":
        if info.get("invalid") or info.get("duration_seconds", 0) <= 0:
            errors.append("invalid or empty WAV")
    if info.get("invalid"):
        errors.append(f"invalid {info.get('format', 'media')} structure")
    return errors, info


def validate_artifact(path: Path, media_minimum: bool = False) -> tuple[list[str], dict]:
    if not path.exists():
        return ["artifact is missing"], {}
    if path.is_dir():
        if not any(item.is_file() for item in path.rglob("*")):
            return ["artifact directory is empty"], {}
        return [], {"kind": "directory", "sha256": sha256_path(path)}
    if path.stat().st_size <= 0:
        return ["artifact file is empty"], {}
    if path.suffix.lower() in MEDIA_EXTENSIONS:
        return validate_media(path, min_width=640 if media_minimum else 1, min_height=360 if media_minimum else 1)
    return [], {"kind": "file", "size": path.stat().st_size, "sha256": sha256_file(path)}


def require_artifacts(
    root: Path,
    raw_values: Any,
    blockers: list[dict],
    code: str,
    message: str,
    source: Any,
    media_only: bool = False,
    media_minimum: bool = False,
) -> list[Path]:
    valid: list[Path] = []
    if not isinstance(raw_values, list) or not raw_values:
        blockers.append(issue(code, message, source))
        return valid
    for raw in raw_values:
        raw_path = raw.get("path", "") if isinstance(raw, dict) else raw
        path = resolve_project_path(root, str(raw_path))
        if path is None:
            blockers.append(issue(f"{code}.empty", "Evidence path is empty", source))
            continue
        if not is_within(root, path):
            blockers.append(issue(f"{code}.outside_root", f"Evidence must remain inside the project: {raw_path}", path))
            continue
        if media_only and path.suffix.lower() not in MEDIA_EXTENSIONS:
            blockers.append(issue(f"{code}.media_required", f"Runtime evidence must be image/video media: {raw_path}", path))
            continue
        errors, _ = validate_artifact(path, media_minimum=media_minimum)
        if errors:
            for error in errors:
                blockers.append(issue(f"{code}.invalid", f"Invalid artifact {raw_path}: {error}", path))
            continue
        valid.append(path)
    return valid


def markdown_status(path: Path) -> str:
    if not path.is_file():
        return ""
    text = path.read_text(encoding="utf-8-sig")
    match = re.search(r"^Status:\s*(.+?)\s*$", text, re.MULTILINE | re.IGNORECASE)
    return match.group(1).strip().lower() if match else ""


def require_ready_markdown(path: Path, blockers: list[dict], code: str) -> Optional[str]:
    if not path.is_file():
        blockers.append(issue(f"{code}.missing", f"Missing {path}", path))
        return None
    text = path.read_text(encoding="utf-8-sig")
    status = markdown_status(path)
    if status not in PASS_STATUSES:
        blockers.append(issue(f"{code}.status", f"Status is not approved/verified: {status or 'missing'}", path))
    if re.search(r"\[(?:Game|Version|Goal|system|content|path|command|PASS\s*\|)", text, re.IGNORECASE):
        blockers.append(issue(f"{code}.placeholder", "Document still contains template placeholders", path))
    return text


def status_ok(value: Any) -> bool:
    return str(value or "").strip().lower() in PASS_STATUSES


def status_na(value: Any) -> bool:
    return str(value or "").strip().lower() in NA_STATUSES


def by_id(rows: Any) -> dict[str, dict]:
    if not isinstance(rows, list):
        return {}
    return {str(row.get("id")): row for row in rows if isinstance(row, dict) and row.get("id")}


def compare_metric(actual: Any, budget: Any, mode: str) -> bool:
    try:
        left = float(actual)
        right = float(budget)
    except (TypeError, ValueError):
        return False
    return left >= right if mode == "min" else left <= right


def command_results(report: Optional[dict]) -> dict[str, dict]:
    return by_id(report.get("results")) if isinstance(report, dict) else {}


def report_gate(root: Path, blockers: list[dict], warnings: list[dict], evidence: list[dict]) -> dict:
    gate = "BLOCKED" if blockers else ("PASS_WITH_WARNINGS" if warnings else "PASS")
    return {"root": str(root), "gate": gate, "blockers": blockers, "warnings": warnings, "evidence": evidence}
