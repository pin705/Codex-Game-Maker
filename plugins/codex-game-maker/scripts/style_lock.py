#!/usr/bin/env python3
"""Seal and verify project-local visual style continuity."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from datetime import date
from pathlib import Path
from typing import Any


LIB_DIR = Path(__file__).resolve().parent / "lib"
if str(LIB_DIR) not in sys.path:
    sys.path.insert(0, str(LIB_DIR))

from cgm_validation import validate_media  # noqa: E402


SEMVER = re.compile(r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$")
STYLE_ID = re.compile(r"^[a-z0-9][a-z0-9-]{1,63}$")


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def lock_digest(value: dict[str, Any]) -> str:
    normalized = {key: item for key, item in value.items() if key != "digest"}
    payload = json.dumps(normalized, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def project_file(root: Path, value: object) -> Path | None:
    relative = Path(str(value))
    if not str(value).strip() or relative.is_absolute():
        return None
    candidate = (root / relative).resolve()
    try:
        candidate.relative_to(root.resolve())
    except ValueError:
        return None
    return candidate


def validate(root: Path, data: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if data.get("schema_version") != 1:
        errors.append("schema_version must be 1")
    if data.get("status") != "locked":
        errors.append("status must be locked")
    art_raw = str(data.get("source_art_bible", ""))
    art = project_file(root, art_raw)
    if art_raw != "design/art/art-bible.md" or art is None:
        errors.append("source art bible must be design/art/art-bible.md")
    elif not art.is_file():
        errors.append("source art bible is missing")
    elif data.get("art_bible_sha256") != file_sha256(art):
        errors.append("art_bible_sha256 is stale")
    for field in ("style_id", "style_version", "identity_rule"):
        if not str(data.get(field, "")).strip():
            errors.append(f"missing {field}")
    if str(data.get("style_id", "")) and not STYLE_ID.fullmatch(str(data["style_id"])):
        errors.append("style_id must be a lower-case hyphen ID")
    if str(data.get("style_version", "")) and not SEMVER.fullmatch(str(data["style_version"])):
        errors.append("style_version must be x.y.z")
    if str(data.get("identity_rule", "")).strip() and len(str(data["identity_rule"]).strip()) < 24:
        errors.append("identity_rule must be a concrete game-specific rule")
    anchors = data.get("anchors") if isinstance(data.get("anchors"), dict) else {}
    for field in ("materials", "shape_language", "camera_and_view", "lighting", "palette_roles", "typography_roles", "detail_density", "motion_and_fx"):
        if (
            not isinstance(anchors.get(field), list)
            or not anchors[field]
            or not all(str(item).strip() for item in anchors[field])
        ):
            errors.append(f"missing anchors.{field}")
    forbidden = data.get("forbidden_drift")
    families = data.get("approved_families")
    if not isinstance(forbidden, list) or len(forbidden) < 2 or not all(str(item).strip() for item in forbidden):
        errors.append("at least two concrete forbidden_drift rules are required")
    if not isinstance(families, list) or not families or not all(str(item).strip() for item in families):
        errors.append("approved_families are required")
        approved_families: set[str] = set()
    else:
        approved_families = {str(item) for item in families}
    for index, row in enumerate(data.get("locked_references", [])):
        if not isinstance(row, dict):
            errors.append(f"locked_references[{index}] is invalid")
            continue
        path = project_file(root, row.get("path", ""))
        if path is None:
            errors.append(f"locked reference must be a project-relative path: {row.get('path', '')}")
        elif not path.is_file():
            errors.append(f"locked reference is missing: {row.get('path', '')}")
        elif row.get("sha256") != file_sha256(path):
            errors.append(f"locked reference hash is stale: {row.get('path', '')}")
        else:
            media_errors, _ = validate_media(path, expected_kind="image", min_width=320, min_height=180)
            if media_errors:
                errors.append(f"locked reference is not a valid 320x180+ image: {row.get('path', '')}")
        reference_families = {
            str(item) for item in row.get("families", []) if str(item).strip()
        } if isinstance(row.get("families"), list) else set()
        if not reference_families or not reference_families.issubset(approved_families):
            errors.append(f"locked reference has no families: {row.get('path', '')}")
    if not data.get("locked_references"):
        errors.append("at least one locked reference is required")
    change = data.get("change_control") if isinstance(data.get("change_control"), dict) else {}
    for field in ("change_reason", "approved_by", "approved_on"):
        if not str(change.get(field, "")).strip():
            errors.append(f"missing change_control.{field}")
    if str(change.get("approved_on", "")) and not re.fullmatch(r"\d{4}-\d{2}-\d{2}", str(change["approved_on"])):
        errors.append("change_control.approved_on must use YYYY-MM-DD")
    if data.get("digest") != lock_digest(data):
        errors.append("style lock digest is stale")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=("seal", "verify"))
    parser.add_argument("--root", default=".")
    parser.add_argument("--version", default="")
    parser.add_argument("--reason", default="")
    parser.add_argument("--approved-by", default="")
    args = parser.parse_args()
    root = Path(args.root).resolve()
    path = root / "design/art/style-lock.json"
    if not path.is_file():
        print(json.dumps({"gate": "BLOCKED", "errors": [f"Missing {path}"]}, indent=2))
        return 1
    try:
        data = json.loads(path.read_text(encoding="utf-8-sig"))
    except json.JSONDecodeError as exc:
        print(json.dumps({"gate": "BLOCKED", "errors": [f"Invalid style lock JSON: {exc}"]}, indent=2))
        return 1
    if not isinstance(data, dict):
        print(json.dumps({"gate": "BLOCKED", "errors": ["Style lock root must be an object"]}, indent=2))
        return 1
    if args.action == "seal":
        if not args.approved_by or not args.reason:
            print(json.dumps({"gate": "BLOCKED", "errors": ["seal requires --approved-by and --reason"]}, indent=2))
            return 1
        previous = str(data.get("digest", ""))
        if args.version:
            data["style_version"] = args.version
        art = project_file(root, data.get("source_art_bible", ""))
        if art is not None and art.is_file():
            data["art_bible_sha256"] = file_sha256(art)
        for row in data.get("locked_references", []):
            if isinstance(row, dict):
                reference = project_file(root, row.get("path", ""))
                if reference is not None and reference.is_file():
                    row["sha256"] = file_sha256(reference)
        data["status"] = "locked"
        data["change_control"] = {
            "previous_digest": previous,
            "change_reason": args.reason,
            "approved_by": args.approved_by,
            "approved_on": date.today().isoformat(),
        }
        data["digest"] = lock_digest(data)
    errors = validate(root, data)
    if args.action == "seal" and not errors:
        path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({
        "gate": "BLOCKED" if errors else "PASS",
        "path": str(path),
        "style_id": data.get("style_id", ""),
        "style_version": data.get("style_version", ""),
        "sha256": data.get("digest", ""),
        "errors": errors,
    }, indent=2))
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
