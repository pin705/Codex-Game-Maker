#!/usr/bin/env python3
"""Higher-level Codex Game Maker asset workflows.

This file coordinates deterministic asset steps around the lower-level
cgs_asset_processor.py. It does not generate images. It writes specs, repairs
processed image outputs, and creates Godot-ready resources/scenes.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any

try:
    import cgs_asset_processor as processor
except ImportError:  # pragma: no cover - only used when launched oddly.
    processor = None  # type: ignore[assignment]

try:
    from PIL import Image
except ImportError:  # pragma: no cover - surfaced as a production preflight error.
    Image = None  # type: ignore[assignment]


ACTION_DEFAULTS: dict[str, dict[str, Any]] = {
    "idle": {"rows": 2, "cols": 3, "frames": 6, "fps": 6, "anchor": "feet", "loop": True},
    "walk": {"rows": 3, "cols": 4, "frames": 12, "fps": 12, "anchor": "feet", "loop": True},
    "run": {"rows": 3, "cols": 4, "frames": 12, "fps": 12, "anchor": "feet", "loop": True},
    "jump": {"rows": 2, "cols": 4, "frames": 8, "fps": 10, "anchor": "center", "loop": False},
    "attack": {"rows": 3, "cols": 4, "frames": 12, "fps": 12, "anchor": "feet", "loop": False},
    "hurt": {"rows": 2, "cols": 3, "frames": 6, "fps": 8, "anchor": "feet", "loop": False},
    "death": {"rows": 3, "cols": 4, "frames": 12, "fps": 10, "anchor": "feet", "loop": False},
    "fx": {"rows": 2, "cols": 4, "frames": 8, "fps": 12, "anchor": "center", "loop": False},
}

TOP_DOWN_ACTION_DEFAULTS: dict[str, dict[str, Any]] = {
    "idle": {"rows": 2, "cols": 3, "frames": 6, "fps": 6, "anchor": "feet", "loop": True},
    "walk": {"rows": 2, "cols": 4, "frames": 8, "fps": 8, "anchor": "feet", "loop": True},
    "run": {"rows": 2, "cols": 4, "frames": 8, "fps": 8, "anchor": "feet", "loop": True},
    "move": {"rows": 2, "cols": 4, "frames": 8, "fps": 8, "anchor": "feet", "loop": True},
    "cast": {"rows": 2, "cols": 4, "frames": 8, "fps": 10, "anchor": "feet", "loop": False},
}


@dataclass
class ActionSpec:
    name: str
    rows: int
    cols: int
    expected_frames: int
    fps: float
    anchor: str
    loop: bool

    @property
    def duration_ms(self) -> int:
        return max(1, int(round(1000 / max(1.0, self.fps))))


def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def write_text(path: Path, content: str) -> None:
    ensure_dir(path.parent)
    path.write_text(content, encoding="utf-8")


def canonical_json_sha256(value: dict[str, Any]) -> str:
    normalized = {key: item for key, item in value.items() if key != "digest"}
    payload = json.dumps(normalized, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_style_lock(root: Path, allow_unlocked_lookdev: bool = False) -> dict[str, Any]:
    path = root / "design/art/style-lock.json"
    if not path.is_file():
        if allow_unlocked_lookdev:
            return {"style_version": "lookdev", "digest": "unlocked-lookdev", "art_bible_sha256": "", "locked_references": []}
        raise RuntimeError("Missing design/art/style-lock.json. Lock look-dev before production generation, or use --lookdev for candidate work.")
    data = json.loads(path.read_text(encoding="utf-8-sig"))
    if not isinstance(data, dict):
        raise RuntimeError("design/art/style-lock.json must contain an object")
    expected = canonical_json_sha256(data)
    if data.get("digest") != expected:
        raise RuntimeError("design/art/style-lock.json has a missing or stale digest")
    if data.get("schema_version") != 1:
        raise RuntimeError("style lock schema_version must be 1")
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]{1,63}", str(data.get("style_id", ""))):
        raise RuntimeError("style lock style_id must be a concrete lower-case hyphen ID")
    if not re.fullmatch(r"\d+\.\d+\.\d+", str(data.get("style_version", ""))):
        raise RuntimeError("style lock style_version must be x.y.z")
    if len(str(data.get("identity_rule", "")).strip()) < 24:
        raise RuntimeError("style lock identity_rule must be a concrete game-specific rule")
    art_path = (root / str(data.get("source_art_bible", ""))).resolve()
    try:
        art_path.relative_to(root.resolve())
    except ValueError as exc:
        raise RuntimeError("style lock art bible must remain inside the project") from exc
    if not art_path.is_file() or data.get("art_bible_sha256") != file_sha256(art_path):
        raise RuntimeError("style lock art_bible_sha256 is missing or stale")
    if data.get("status") != "locked":
        raise RuntimeError("style lock status must be locked")
    anchors = data.get("anchors") if isinstance(data.get("anchors"), dict) else {}
    for field in ("materials", "shape_language", "camera_and_view", "lighting", "palette_roles", "typography_roles", "detail_density", "motion_and_fx"):
        if not isinstance(anchors.get(field), list) or not anchors[field] or not all(str(item).strip() for item in anchors[field]):
            raise RuntimeError(f"style lock needs non-empty anchors.{field}")
    forbidden = data.get("forbidden_drift")
    if not isinstance(forbidden, list) or len(forbidden) < 2 or not all(str(item).strip() for item in forbidden):
        raise RuntimeError("style lock needs at least two concrete forbidden_drift rules")
    change_control = data.get("change_control") if isinstance(data.get("change_control"), dict) else {}
    for field in ("change_reason", "approved_by", "approved_on"):
        if not str(change_control.get(field, "")).strip():
            raise RuntimeError(f"style lock needs change_control.{field}")
    approved_families = {str(item) for item in data.get("approved_families", []) if str(item)}
    references = data.get("locked_references")
    if not approved_families or not isinstance(references, list) or not references:
        raise RuntimeError("style lock needs approved families and at least one locked reference")
    for row in references:
        if not isinstance(row, dict):
            raise RuntimeError("style lock contains an invalid locked reference")
        reference = (root / str(row.get("path", ""))).resolve()
        try:
            reference.relative_to(root.resolve())
        except ValueError as exc:
            raise RuntimeError("locked style references must remain inside the project") from exc
        families = {str(item) for item in row.get("families", []) if str(item)}
        if (
            not reference.is_file()
            or row.get("sha256") != file_sha256(reference)
            or not families
            or not families.issubset(approved_families)
        ):
            raise RuntimeError(f"locked style reference is missing, stale, or misclassified: {row.get('path', '')}")
        if Image is None:
            raise RuntimeError("Pillow is required to validate locked style reference images")
        try:
            with Image.open(reference) as image:
                width, height = image.size
                image.verify()
        except Exception as exc:
            raise RuntimeError(f"locked style reference is not a valid image: {row.get('path', '')}") from exc
        if width < 320 or height < 180:
            raise RuntimeError(f"locked style reference must be at least 320x180: {row.get('path', '')}")
    return data


def family_candidates(category: str) -> set[str]:
    normalized = safe_id(category).lower()
    aliases = {
        "actors": {"actor", "actors", "character", "characters", "creature", "creatures", "enemy", "enemies", "boss", "bosses", "npc", "npcs", "player"},
        "world": {"world", "environment", "environments", "map", "maps", "level", "levels", "prop", "props", "tile", "tiles", "background", "backgrounds"},
        "feedback": {"feedback", "fx", "vfx", "effect", "effects", "projectile", "projectiles", "impact", "impacts"},
        "ui": {"ui", "hud", "menu", "menus", "icon", "icons"},
    }
    candidates = {normalized}
    for canonical, values in aliases.items():
        if normalized in values:
            candidates.update(values)
            candidates.add(canonical)
    return candidates


def select_locked_reference(root: Path, style_lock: dict[str, Any], category: str, requested: str = "") -> str:
    candidates = family_candidates(category)
    requested_path = (root / requested).resolve() if requested else None
    for row in style_lock.get("locked_references", []):
        if not isinstance(row, dict) or not row.get("path"):
            continue
        path = (root / str(row["path"])).resolve()
        families = {str(item).lower() for item in row.get("families", []) if str(item)}
        if requested_path is not None and path != requested_path:
            continue
        if families & candidates:
            return str(row["path"])
    if requested:
        raise RuntimeError(
            "Production --reference-file must be sealed for the asset's visual family; "
            "use --lookdev for candidates or reseal a new style version first"
        )
    raise RuntimeError(
        f"The sealed style lock has no reference for asset family/category '{category}'; "
        "add and reseal an appropriate reference before production generation"
    )


def as_posix(path: Path) -> str:
    return path.as_posix()


def safe_id(value: str) -> str:
    clean = re.sub(r"[^A-Za-z0-9_.-]+", "-", value.strip())
    clean = re.sub(r"-+", "-", clean).strip("-")
    return clean or "asset"


def pascal_name(value: str) -> str:
    parts = re.split(r"[^A-Za-z0-9]+", value)
    name = "".join(part[:1].upper() + part[1:] for part in parts if part)
    return name or "Asset"


def clean_yaml_value(value: str) -> str:
    clean = value.strip()
    if clean == "":
        return ""
    if clean.startswith('"') and clean.endswith('"') and len(clean) >= 2:
        return clean[1:-1]
    if clean.startswith("'") and clean.endswith("'") and len(clean) >= 2:
        return clean[1:-1]
    return clean


def yaml_quote(value: Any) -> str:
    if value is None:
        return '""'
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return str(value)
    text = str(value).replace("\\", "/")
    escaped = text.replace('"', '\\"')
    return f'"{escaped}"'


def parse_asset_manifest(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        return []

    entries: list[dict[str, str]] = []
    current: dict[str, str] | None = None
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.rstrip()
        stripped = line.strip()
        if stripped.startswith("- asset_id:"):
            if current:
                entries.append(current)
            current = {"asset_id": clean_yaml_value(stripped.split(":", 1)[1])}
            continue
        if current and line.startswith("    ") and ":" in stripped:
            key, value = stripped.split(":", 1)
            current[key.strip()] = clean_yaml_value(value)
    if current:
        entries.append(current)
    return entries


def manifest_path(root: Path) -> Path:
    return root / "design" / "assets" / "asset-manifest.yaml"


def import_manifest_path(root: Path) -> Path:
    return root / "design" / "assets" / "godot-import-manifest.yaml"


def append_asset_manifest(root: Path, entries: list[dict[str, Any]], style_lock: dict[str, Any]) -> Path:
    path = manifest_path(root)
    ensure_dir(path.parent)
    existing = parse_asset_manifest(path)

    by_id: dict[str, dict[str, Any]] = {}
    order: list[str] = []
    for entry in existing:
        asset_id = str(entry.get("asset_id", "")).strip()
        if not asset_id:
            continue
        by_id[asset_id] = dict(entry)
        order.append(asset_id)

    for entry in entries:
        asset_id = str(entry.get("asset_id", "")).strip()
        if not asset_id:
            continue
        if asset_id not in by_id:
            order.append(asset_id)
            by_id[asset_id] = {"asset_id": asset_id}
        by_id[asset_id].update(entry)

    lines = [
        "style_lock:",
        "  path: design/art/style-lock.json",
        f"  style_version: {yaml_quote(str(style_lock.get('style_version', '')))}",
        f"  sha256: {yaml_quote(str(style_lock.get('digest', '')))}",
        "assets:",
    ]
    for asset_id in order:
        entry = by_id[asset_id]
        lines.append("")
        lines.append(f"  - asset_id: {asset_id}")
        for key, value in entry.items():
            if key == "asset_id":
                continue
            lines.append(f"    {key}: {yaml_quote(value)}")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return path


def append_import_manifest(root: Path, entries: list[dict[str, Any]]) -> Path:
    path = import_manifest_path(root)
    ensure_dir(path.parent)
    if not path.exists():
        path.write_text('godot_version: "4.6.2"\nimports:\n', encoding="utf-8")

    existing_ids: set[str] = set()
    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if stripped.startswith("- asset_id:"):
            existing_ids.add(clean_yaml_value(stripped.split(":", 1)[1]))

    blocks: list[str] = []
    for entry in entries:
        asset_id = str(entry.get("asset_id", "")).strip()
        if not asset_id or asset_id in existing_ids:
            continue
        lines = [f"  - asset_id: {asset_id}"]
        for key, value in entry.items():
            if key == "asset_id":
                continue
            lines.append(f"    {key}: {yaml_quote(value)}")
        blocks.append("\n".join(lines))
    if blocks:
        with path.open("a", encoding="utf-8") as handle:
            handle.write("\n" + "\n".join(blocks) + "\n")
    return path


def root_relative(root: Path, path: Path) -> str:
    try:
        return path.resolve().relative_to(root.resolve()).as_posix()
    except ValueError:
        return path.resolve().as_posix()


def res_path(root: Path, path: Path) -> str:
    return "res://" + root_relative(root, path).replace("\\", "/")


def resolve_project_path(root: Path, value: str | None) -> Path | None:
    if not value:
        return None
    clean = clean_yaml_value(value)
    if not clean:
        return None
    if clean.startswith("res://"):
        return root / clean[len("res://"):]
    path = Path(clean)
    if path.is_absolute():
        return path
    return root / path


def suggest_key(description: str) -> str:
    if processor is None:
        return "#FF00FF"
    return str(processor.suggest_key_color(description).get("key_color", "#FF00FF"))


def action_defaults_for(name: str, view: str) -> dict[str, Any]:
    base_name = name
    for suffix in ("_down", "_side", "_up", "-down", "-side", "-up"):
        if base_name.endswith(suffix):
            base_name = base_name[: -len(suffix)]
            break
    if view in ("topdown", "top_down", "top_down_survivor", "survivor"):
        return TOP_DOWN_ACTION_DEFAULTS.get(base_name, {"rows": 2, "cols": 4, "frames": 8, "fps": 8, "anchor": "feet", "loop": True})
    return ACTION_DEFAULTS.get(base_name, {"rows": 2, "cols": 4, "frames": 8, "fps": 8, "anchor": "center", "loop": True})


def parse_actions(actions: str, view: str = "side") -> list[ActionSpec]:
    specs: list[ActionSpec] = []
    for item in [part.strip() for part in actions.split(",") if part.strip()]:
        parts = [part.strip() for part in item.split(":")]
        name = safe_id(parts[0]).lower()
        defaults = action_defaults_for(name, view)
        rows = int(parts[1]) if len(parts) > 1 and parts[1] else int(defaults["rows"])
        cols = int(parts[2]) if len(parts) > 2 and parts[2] else int(defaults["cols"])
        frames = int(parts[3]) if len(parts) > 3 and parts[3] else int(defaults["frames"])
        fps = float(parts[4]) if len(parts) > 4 and parts[4] else float(defaults["fps"])
        anchor = parts[5] if len(parts) > 5 and parts[5] else str(defaults["anchor"])
        loop = str(defaults.get("loop", True)).lower() == "true"
        specs.append(ActionSpec(name, rows, cols, frames, fps, anchor, loop))
    return specs


def processor_script_path() -> Path:
    return Path(__file__).with_name("cgs_asset_processor.py")


def harness_script_path() -> Path:
    return Path(__file__).with_name("cgs_asset_harness.py")


def run_processor(args: list[str]) -> dict[str, Any]:
    cmd = [sys.executable, as_posix(processor_script_path()), *args]
    completed = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    if completed.returncode != 0:
        detail = completed.stderr.strip() or completed.stdout.strip()
        raise RuntimeError(f"asset processor failed: {detail}")
    return json.loads(completed.stdout)


def run_harness(args: list[str], allow_blocked: bool = False) -> dict[str, Any]:
    cmd = [sys.executable, as_posix(harness_script_path()), *args]
    completed = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    if completed.returncode != 0 and not allow_blocked:
        detail = completed.stderr.strip() or completed.stdout.strip()
        raise RuntimeError(f"asset harness failed: {detail}")
    output = completed.stdout.strip()
    if not output:
        detail = completed.stderr.strip() or "asset harness produced no output"
        raise RuntimeError(detail)
    return json.loads(output)


def source_prompt_text(
    *,
    asset_id: str,
    description: str,
    action: ActionSpec,
    key_color: str,
    view: str,
    view_profile: str,
    direction_model: str,
    category: str,
    harness_spec: str,
    harness_prompt: str,
    canvas_size: str,
    cell_size: str,
    safe_margin: int,
    style_lock: dict[str, Any],
    reference_file: str = "",
) -> str:
    locked_references = [str(row.get("path")) for row in style_lock.get("locked_references", []) if isinstance(row, dict) and row.get("path")]
    anchors = style_lock.get("anchors") if isinstance(style_lock.get("anchors"), dict) else {}
    identity_anchors = [str(style_lock.get("identity_rule", "")), *[str(item) for item in anchors.get("shape_language", [])]]
    material_anchors = [str(item) for item in anchors.get("materials", [])]
    palette_anchors = [str(item) for item in anchors.get("palette_roles", [])] + [str(item) for item in anchors.get("lighting", [])]
    forbidden = [str(item) for item in style_lock.get("forbidden_drift", [])]
    return "\n".join([
        f"asset_id: {asset_id}",
        f"category: {category}",
        "asset_kind: sprite",
        "generation_provider: gpt_image",
        f"action: {action.name}",
        f"view: {view}",
        f"view_profile: {view_profile}",
        f"direction_model: {direction_model}",
        f"rows: {action.rows}",
        f"cols: {action.cols}",
        f"expected_frames: {action.expected_frames}",
        f"fps: {action.fps:g}",
        f"anchor: {action.anchor}",
        f"key_color: {key_color}",
        f"harness_spec: {harness_spec}",
        f"harness_prompt: {harness_prompt}",
        f"exact_canvas: {canvas_size}",
        f"exact_cell_size: {cell_size}",
        f"safe_margin: {safe_margin}",
        f"reference_file: {reference_file}",
        "style_lock:",
        "  path: design/art/style-lock.json",
        f"  style_version: {style_lock.get('style_version', '')}",
        f"  style_lock_sha256: {style_lock.get('digest', '')}",
        f"  art_bible_sha256: {style_lock.get('art_bible_sha256', '')}",
        f"  locked_reference_paths: {json.dumps(locked_references, ensure_ascii=False)}",
        f"  identity_anchors: {json.dumps([item for item in identity_anchors if item], ensure_ascii=False)}",
        f"  material_anchors: {json.dumps(material_anchors, ensure_ascii=False)}",
        f"  palette_and_lighting_anchors: {json.dumps(palette_anchors, ensure_ascii=False)}",
        f"  forbidden_drift: {json.dumps(forbidden, ensure_ascii=False)}",
        "generation_prompt: >",
        f"  {description}. Create a {action.rows}x{action.cols} sprite-sheet grid for the {action.name} action.",
        f"  The final image must be exactly {canvas_size}; every cell must be exactly {cell_size}.",
        f"  Use a flat solid chroma-key background of {key_color}. Keep every pose inside the harness safe zone with at least {safe_margin}px padding.",
        "  Keep identity, scale, pose readability, foot baseline, and pivot consistent across all frames.",
        "  No text, no labels, no watermark, no borders, no grid lines, and no pixels crossing into neighboring cells.",
        "  Do not create motion by stacking another full-body character or unmasked duplicate limbs over the base frame.",
        "  If a foot, hand, limb, tail, or prop is moved in a local repair, remove or repaint the original pixels first so only one clean visible body remains.",
        "  Do not put semi-transparent shadows, glows, dust, or motion trails into a chroma-key raw sheet; generate those as separate FX assets.",
        "  The asset will be placed into a 16:9 playable scene, so preserve a stable runtime pivot and predictable bounding box.",
        "  For side-view platformers, walk/run must alternate left-foot and right-foot contact poses and make the first and last frames loop cleanly.",
        "  For top-down survivor games, do not use side-view platformer running. Use small shuffles with visible hand and foot changes plus a separate idle loop.",
        "  Body shake, whole-sprite wobble, or camera/pivot jitter is not locomotion; feet and hands must carry the movement read.",
        "  Do not create top-down movement by translating, scaling, or globally warping the whole character; keep head, torso, tail, equipment, pivot, and foot baseline stable.",
        "  Prefer locomotion-friendly silhouettes with short clothing and separated visible feet; avoid long robes, staffs, capes, or props that hide the feet in idle/move sheets.",
        "  If the character concept hides or crops the feet, regenerate a movement-friendly variant instead of repeatedly repairing bad foot masks.",
        "  If direction_model is full_directional, create separate down/side/up states or a canonical four-direction sheet.",
        "  If direction_model is side_only_last_horizontal, generate only side-facing states and rely on runtime flip plus last horizontal facing.",
        "  For jump, create phase poses for takeoff, rise, apex, fall, and land; do not design it as a blind loop.",
        "",
    ])


def action_bundle_command(args: argparse.Namespace) -> dict[str, Any]:
    root = Path(args.root).resolve()
    style_lock = load_style_lock(root, allow_unlocked_lookdev=bool(args.lookdev))
    bundle_id = safe_id(args.asset_id)
    category = safe_id(args.category)
    selected_reference = args.reference_file
    if not args.lookdev:
        selected_reference = select_locked_reference(root, style_lock, category, args.reference_file)
    view_profile = "top_down_survivor" if args.view in ("topdown", "top_down", "top_down_survivor", "survivor") else "side_platformer"
    if args.direction_model == "auto":
        direction_model = "full_directional" if view_profile == "top_down_survivor" else "none"
    else:
        direction_model = args.direction_model
    actions = parse_actions(args.actions, args.view)
    bundle_dir = root / "design" / "assets" / "action-bundles"
    harness_dir = root / "design" / "assets" / "harnesses"
    prompt_dir = root / "assets" / "source-prompts"
    raw_dir = root / "assets" / "raw"
    generated_dir = root / "assets" / "generated" / category
    review_dir = root / "production" / "reviews"

    ensure_dir(bundle_dir)
    ensure_dir(harness_dir)
    ensure_dir(prompt_dir)
    ensure_dir(raw_dir)
    ensure_dir(generated_dir)
    ensure_dir(review_dir)

    bundle_lines = [
        f"bundle_id: {bundle_id}",
        f"description: {yaml_quote(args.description)}",
        f"category: {category}",
        f"view: {args.view}",
        f"view_profile: {view_profile}",
        f"direction_model: {direction_model}",
        "godot_version: \"4.6.2\"",
        f"style_version: {yaml_quote(str(style_lock.get('style_version', '')))}",
        f"style_lock_sha256: {yaml_quote(str(style_lock.get('digest', '')))}",
        "actions:",
    ]

    manifest_entries: list[dict[str, Any]] = []
    processed: list[dict[str, Any]] = []
    blocked: list[dict[str, Any]] = []
    planned: list[str] = []

    for action in actions:
        action_asset_id = f"{bundle_id}-{action.name}"
        key_color = args.key_color if args.key_color not in ("suggest", "auto-suggest") else suggest_key(f"{args.description} {action.name}")
        cell_w = int(args.cell_width)
        cell_h = int(args.jump_cell_height) if action.name == "jump" else int(args.cell_height)
        safe_margin = int(args.safe_margin)
        harness_args = [
            "create",
            "--out-dir", as_posix(harness_dir),
            "--asset-id", action_asset_id,
            "--kind", "sprite",
            "--action", action.name,
            "--view-profile", view_profile,
            "--rows", str(action.rows),
            "--cols", str(action.cols),
            "--cell-width", str(cell_w),
            "--cell-height", str(cell_h),
            "--safe-margin", str(safe_margin),
            "--key-color", key_color,
            "--pivot", action.anchor,
            "--max-foot-drift", str(args.max_foot_drift),
            "--max-scale-drift", str(args.max_scale_drift),
        ]
        if action.loop:
            harness_args.append("--loop")
        harness_meta = run_harness(harness_args)
        harness_spec_path = Path(str(harness_meta["harness_spec"]))
        harness_prompt_path = Path(str(harness_meta["prompt_contract"]))
        prompt_path = prompt_dir / f"{action_asset_id}.yaml"
        write_text(prompt_path, source_prompt_text(
            asset_id=action_asset_id,
            description=args.description,
            action=action,
            key_color=key_color,
            view=args.view,
            view_profile=view_profile,
            direction_model=direction_model,
            category=category,
            harness_spec=root_relative(root, harness_spec_path),
            harness_prompt=root_relative(root, harness_prompt_path),
            canvas_size=f"{action.cols * cell_w}x{action.rows * cell_h}",
            cell_size=f"{cell_w}x{cell_h}",
            safe_margin=safe_margin,
            style_lock=style_lock,
            reference_file=selected_reference,
        ))

        bundle_lines.extend([
            f"  - action: {action.name}",
            f"    asset_id: {action_asset_id}",
            f"    rows: {action.rows}",
            f"    cols: {action.cols}",
            f"    expected_frames: {action.expected_frames}",
            f"    fps: {action.fps:g}",
            f"    anchor: {action.anchor}",
            f"    loop: {'true' if action.loop else 'false'}",
            f"    direction_model: {direction_model}",
            f"    key_color: {yaml_quote(key_color)}",
            f"    harness_spec: {root_relative(root, harness_spec_path)}",
            f"    harness_prompt: {root_relative(root, harness_prompt_path)}",
            f"    canvas: {action.cols * cell_w}x{action.rows * cell_h}",
            f"    cell_size: {cell_w}x{cell_h}",
            f"    source_prompt: {root_relative(root, prompt_path)}",
            f"    raw_target: assets/raw/{action_asset_id}-sheet.png",
        ])

        raw_path = raw_dir / f"{action_asset_id}-sheet.png"
        out_dir = generated_dir / action_asset_id
        entry: dict[str, Any] = {
            "name": f"{bundle_id} {action.name}",
            "category": category,
            "asset_kind": "sprite",
            "status": "needed",
            "generation_provider": "gpt_image",
            "release_ready": False,
            "raw_file": root_relative(root, raw_path),
            "selected_file": "",
            "processed_file": "",
            "frames_dir": "",
            "gif_preview": "",
            "pipeline_meta": "",
            "harness_spec": root_relative(root, harness_spec_path),
            "harness_report": "",
            "source_prompt": root_relative(root, prompt_path),
            "style_version": style_lock.get("style_version", ""),
            "style_lock_sha256": style_lock.get("digest", ""),
            "expected_frames": action.expected_frames,
            "frame_size": f"{cell_w}x{cell_h}",
            "anchor": action.anchor,
            "key_color": key_color,
            "direction_model": direction_model,
            "godot_import": "",
            "collision_role": "none",
            "notes": "Generated by action bundle planning.",
        }

        if args.process_existing_raw and raw_path.exists():
            ensure_dir(out_dir)
            harness_report_path = out_dir / "harness-report.json"
            harness_result = run_harness([
                "validate",
                "--spec", as_posix(harness_spec_path),
                "--input", as_posix(raw_path),
                "--report", as_posix(harness_report_path),
            ], allow_blocked=True)
            entry["harness_report"] = root_relative(root, harness_report_path)
            if harness_result.get("gate") == "BLOCKED":
                entry.update({
                    "status": "blocked",
                    "notes": "Harness blocked the raw sheet. Regenerate before processing.",
                })
                blocked.append({"asset_id": action_asset_id, "harness_report": entry["harness_report"]})
                manifest_entries.append({"asset_id": action_asset_id, **entry})
                continue

            meta = run_processor([
                "sprite",
                "--input", as_posix(raw_path),
                "--out-dir", as_posix(out_dir),
                "--asset-id", action_asset_id,
                "--rows", str(action.rows),
                "--cols", str(action.cols),
                "--expected-frames", str(action.expected_frames),
                "--anchor", action.anchor,
                "--fit-scale", str(args.fit_scale),
                "--key-color", key_color,
                "--tolerance", str(args.tolerance),
                "--softness", str(args.softness),
                "--duration-ms", str(action.duration_ms),
            ])
            outputs = meta.get("outputs", {})
            pipeline_meta_path = Path(outputs.get("pipeline_meta", ""))
            if pipeline_meta_path.is_file():
                pipeline_data = json.loads(pipeline_meta_path.read_text(encoding="utf-8-sig"))
                pipeline_data["style_version"] = style_lock.get("style_version", "")
                pipeline_data["style_lock_sha256"] = style_lock.get("digest", "")
                pipeline_data["art_bible_sha256"] = style_lock.get("art_bible_sha256", "")
                write_text(pipeline_meta_path, json.dumps(pipeline_data, indent=2, ensure_ascii=False) + "\n")
            frame_size = meta.get("frame_size", {})
            entry.update({
                "status": "accepted",
                "selected_file": root_relative(root, Path(outputs.get("transparent_sheet", ""))),
                "processed_file": root_relative(root, Path(outputs.get("transparent_sheet", ""))),
                "frames_dir": root_relative(root, Path(outputs.get("frames_dir", ""))),
                "gif_preview": root_relative(root, Path(outputs.get("gif_preview", ""))),
                "pipeline_meta": root_relative(root, Path(outputs.get("pipeline_meta", ""))),
                "frame_size": f"{frame_size.get('width', 0)}x{frame_size.get('height', 0)}",
                "notes": f"Processed from existing raw sheet after harness gate {harness_result.get('gate')}.",
            })
            processed.append({"asset_id": action_asset_id, "pipeline_meta": entry["pipeline_meta"]})
        else:
            planned.append(action_asset_id)

        manifest_entries.append({"asset_id": action_asset_id, **entry})

    bundle_path = bundle_dir / f"{bundle_id}.yaml"
    write_text(bundle_path, "\n".join(bundle_lines) + "\n")
    manifest_file = append_asset_manifest(root, manifest_entries, style_lock)

    report_path = review_dir / f"action-bundle-{bundle_id}.md"
    report_lines = [
        f"# Action Bundle: {bundle_id}",
        "",
        f"- description: {args.description}",
        f"- actions: {', '.join(action.name for action in actions)}",
        f"- planned raw sheets: {len(planned)}",
        f"- processed sheets: {len(processed)}",
        f"- harness-blocked sheets: {len(blocked)}",
        "",
        "## Next Steps",
        "",
        "- Generate raw sheets listed in the bundle spec using each harness prompt contract.",
        "- Re-run with `-ProcessExistingRaw` after raw sheets are saved. Harness-blocked sheets must be regenerated.",
        "- Run asset QA before Godot import.",
        "",
    ]
    write_text(report_path, "\n".join(report_lines))

    return {
        "status": "ok",
        "bundle_id": bundle_id,
        "bundle_spec": root_relative(root, bundle_path),
        "manifest": root_relative(root, manifest_file),
        "report": root_relative(root, report_path),
        "planned": planned,
        "processed": processed,
        "blocked": blocked,
    }


def load_json_if_exists(path: Path | None) -> Any:
    if not path or not path.exists():
        return None
    return json.loads(path.read_text(encoding="utf-8-sig"))


def repair_assets_command(args: argparse.Namespace) -> dict[str, Any]:
    root = Path(args.root).resolve()
    entries = parse_asset_manifest(manifest_path(root))
    if args.asset_id:
        entries = [entry for entry in entries if entry.get("asset_id") == args.asset_id]

    proposals: list[dict[str, Any]] = []
    applied: list[dict[str, Any]] = []
    for entry in entries:
        status = entry.get("status", "")
        if status not in ("accepted", "reviewed", "ready"):
            continue
        meta_path = resolve_project_path(root, entry.get("pipeline_meta"))
        meta = load_json_if_exists(meta_path)
        if not isinstance(meta, dict):
            continue

        qa = meta.get("qa", {})
        kind = str(meta.get("kind", entry.get("asset_kind", "")))
        residue = int(qa.get("opaque_key_pixels", qa.get("opaque_magenta_pixels", 0)) or 0)
        edge_touch = list(qa.get("edge_touch_frames", []) or [])
        frame_ok = qa.get("frame_count_ok", qa.get("prop_count_ok", True))
        if residue == 0 and not edge_touch and frame_ok:
            continue

        chroma = meta.get("chroma_key", {})
        tolerance = int(chroma.get("tolerance", 24))
        softness = int(chroma.get("softness", 16))
        key_color = str(chroma.get("key_color", chroma.get("background", entry.get("key_color", "#FF00FF"))))
        new_tolerance = min(120, tolerance + (20 if residue > 0 else 0))
        new_softness = min(48, softness + (8 if residue > 0 else 0))
        fit_scale = 0.78 if kind == "sprite" and edge_touch else 0.9 if edge_touch else 0.92
        raw_file = resolve_project_path(root, entry.get("raw_file") or str(meta.get("input", "")))
        if not raw_file or not raw_file.exists():
            proposals.append({
                "asset_id": entry.get("asset_id"),
                "action": "needs_regeneration",
                "reason": "raw source missing, cannot repair deterministically",
            })
            continue

        proposal = {
            "asset_id": entry.get("asset_id"),
            "kind": kind,
            "reason": {"opaque_key_pixels": residue, "edge_touch_frames": edge_touch, "frame_count_ok": frame_ok},
            "repair": {"tolerance": new_tolerance, "softness": new_softness, "fit_scale": fit_scale, "key_color": key_color},
        }
        proposals.append(proposal)

        if not args.apply:
            continue

        output_dir = meta_path.parent if meta_path else resolve_project_path(root, entry.get("processed_file"))
        if not output_dir:
            continue
        grid = meta.get("grid", {})
        current_tolerance = new_tolerance
        current_softness = new_softness
        current_fit_scale = fit_scale
        attempt_records: list[dict[str, Any]] = []
        repaired: dict[str, Any] | None = None

        for attempt in range(1, max(1, int(args.max_attempts)) + 1):
            if kind == "sprite":
                repaired = run_processor([
                    "sprite",
                    "--input", as_posix(raw_file),
                    "--out-dir", as_posix(output_dir),
                    "--asset-id", str(entry.get("asset_id", meta.get("asset_id", "sprite"))),
                    "--rows", str(grid.get("rows", 1)),
                    "--cols", str(grid.get("cols", 1)),
                    "--expected-frames", str(grid.get("expected_frames", grid.get("actual_frames", 0))),
                    "--anchor", str(meta.get("anchor", entry.get("anchor", "center"))),
                    "--fit-scale", str(current_fit_scale),
                    "--key-color", key_color,
                    "--tolerance", str(current_tolerance),
                    "--softness", str(current_softness),
                ])
            elif kind == "prop_pack":
                repaired = run_processor([
                    "prop-pack",
                    "--input", as_posix(raw_file),
                    "--out-dir", as_posix(output_dir),
                    "--asset-id", str(entry.get("asset_id", meta.get("asset_id", "props"))),
                    "--rows", str(grid.get("rows", 1)),
                    "--cols", str(grid.get("cols", 1)),
                    "--expected-props", str(grid.get("expected_props", grid.get("actual_props", 0))),
                    "--fit-scale", str(current_fit_scale),
                    "--key-color", key_color,
                    "--tolerance", str(current_tolerance),
                    "--softness", str(current_softness),
                ])
            else:
                break

            repaired_qa = repaired.get("qa", {})
            repaired_residue = int(repaired_qa.get("opaque_key_pixels", repaired_qa.get("opaque_magenta_pixels", 0)) or 0)
            repaired_edges = list(repaired_qa.get("edge_touch_frames", []) or [])
            repaired_count_ok = repaired_qa.get("frame_count_ok", repaired_qa.get("prop_count_ok", True))
            attempt_records.append({
                "attempt": attempt,
                "tolerance": current_tolerance,
                "softness": current_softness,
                "fit_scale": current_fit_scale,
                "opaque_key_pixels": repaired_residue,
                "edge_touch_frames": repaired_edges,
                "count_ok": repaired_count_ok,
            })

            if repaired_residue == 0 and not repaired_edges and repaired_count_ok:
                break

            if repaired_residue > 0:
                current_tolerance = min(120, current_tolerance + 20)
                current_softness = min(48, current_softness + 8)
            if repaired_edges:
                current_fit_scale = max(0.65, current_fit_scale - 0.06)

        if repaired:
            applied.append({
                "asset_id": entry.get("asset_id"),
                "pipeline_meta": root_relative(root, Path(repaired["outputs"]["pipeline_meta"])),
                "attempts": attempt_records,
            })

    report_path = root / "production" / "reviews" / f"asset-repair-{time.strftime('%Y%m%d-%H%M%S')}.md"
    report = [
        "# Asset Repair Report",
        "",
        f"- mode: {'apply' if args.apply else 'dry-run'}",
        f"- proposals: {len(proposals)}",
        f"- applied: {len(applied)}",
        "",
        "```json",
        json.dumps({"proposals": proposals, "applied": applied}, indent=2),
        "```",
        "",
    ]
    write_text(report_path, "\n".join(report))
    return {"status": "ok", "report": root_relative(root, report_path), "proposals": proposals, "applied": applied}


def selected_sprite_entries(root: Path, bundle_id: str, asset_ids: str) -> list[dict[str, str]]:
    entries = parse_asset_manifest(manifest_path(root))
    if asset_ids:
        wanted = {safe_id(item.strip()) for item in asset_ids.split(",") if item.strip()}
        return [entry for entry in entries if safe_id(entry.get("asset_id", "")) in wanted]
    prefix_dash = f"{bundle_id}-"
    prefix_underscore = f"{bundle_id}_"
    return [
        entry for entry in entries
        if entry.get("asset_kind", "") == "sprite"
        and entry.get("status", "") in ("accepted", "reviewed", "ready")
        and (entry.get("asset_id", "") == bundle_id or entry.get("asset_id", "").startswith(prefix_dash) or entry.get("asset_id", "").startswith(prefix_underscore))
    ]


def action_name_from_asset(asset_id: str, bundle_id: str) -> str:
    for prefix in (f"{bundle_id}-", f"{bundle_id}_"):
        if asset_id.startswith(prefix):
            return safe_id(asset_id[len(prefix):]).lower()
    return safe_id(asset_id).lower()


def godot_bool(value: bool) -> str:
    return "true" if value else "false"


def godot_sprite_command(args: argparse.Namespace) -> dict[str, Any]:
    root = Path(args.project).resolve()
    bundle_id = safe_id(args.bundle_id)
    entries = selected_sprite_entries(root, bundle_id, args.asset_ids)
    if not entries:
        raise ValueError(f"No accepted sprite entries found for bundle '{bundle_id}'.")

    resource_dir = root / "resources" / "animations"
    scene_dir = root / "scenes" / "characters"
    ensure_dir(resource_dir)
    ensure_dir(scene_dir)

    ext_lines: list[str] = []
    animations: list[str] = []
    import_entries: list[dict[str, Any]] = []
    ext_index = 1

    for entry in sorted(entries, key=lambda item: item.get("asset_id", "")):
        asset_id = entry.get("asset_id", "")
        action = action_name_from_asset(asset_id, bundle_id)
        frames_dir = resolve_project_path(root, entry.get("frames_dir"))
        if not frames_dir or not frames_dir.exists():
            continue
        frame_paths = sorted(frames_dir.glob("*.png"))
        if not frame_paths:
            continue

        frame_refs: list[str] = []
        for frame in frame_paths:
            ref_id = f"{ext_index}_{action}_{frame.stem.replace('-', '_')}"
            ext_lines.append(f'[ext_resource type="Texture2D" path="{res_path(root, frame)}" id="{ref_id}"]')
            frame_refs.append(ref_id)
            ext_index += 1

        speed = float(entry.get("fps", 0) or 0)
        if speed <= 0:
            try:
                expected = int(entry.get("expected_frames", 0) or 0)
                speed = 12.0 if expected >= 12 else 8.0 if expected >= 8 else 6.0
            except ValueError:
                speed = 8.0
        loop = action in ("idle", "walk", "run")
        frame_blocks = ", ".join([f'{{"duration": 1.0, "texture": ExtResource("{ref_id}")}}' for ref_id in frame_refs])
        animations.append(
            "{"
            f'"frames": [{frame_blocks}], '
            f'"loop": {godot_bool(loop)}, '
            f'"name": &"{action}", '
            f'"speed": {speed:.1f}'
            "}"
        )
        import_entries.append({
            "asset_id": asset_id,
            "source_file": entry.get("processed_file", ""),
            "res_path": res_path(root, resolve_project_path(root, entry.get("processed_file")) or frames_dir),
            "target_node": "AnimatedSprite2D",
            "import_preset": "2d_sprite_frames",
            "frame_size": entry.get("frame_size", ""),
            "pivot": entry.get("anchor", "center"),
            "anchor": entry.get("anchor", "center"),
            "collision_role": entry.get("collision_role", "none"),
            "spriteframes": f"res://resources/animations/{bundle_id}_spriteframes.tres",
        })

    if not animations:
        raise ValueError(f"No frame PNG files found for bundle '{bundle_id}'.")

    spriteframes_path = resource_dir / f"{bundle_id}_spriteframes.tres"
    spriteframes_text = "\n".join([
        f"[gd_resource type=\"SpriteFrames\" load_steps={len(ext_lines) + 1} format=3]",
        "",
        *ext_lines,
        "",
        "[resource]",
        "animations = [" + ", ".join(animations) + "]",
        "",
    ])
    write_text(spriteframes_path, spriteframes_text)

    default_animation = "idle" if any("name\": &\"idle" in animation for animation in animations) else action_name_from_asset(entries[0].get("asset_id", ""), bundle_id)
    scene_name = args.scene_name or pascal_name(bundle_id)
    scene_path = scene_dir / f"{bundle_id}.tscn"
    scene_text = "\n".join([
        "[gd_scene load_steps=2 format=3]",
        "",
        f'[ext_resource type="SpriteFrames" path="{res_path(root, spriteframes_path)}" id="1_spriteframes"]',
        "",
        f'[node name="{scene_name}" type="AnimatedSprite2D"]',
        'sprite_frames = ExtResource("1_spriteframes")',
        f'animation = &"{default_animation}"',
        "playing = true",
        "",
    ])
    write_text(scene_path, scene_text)
    append_import_manifest(root, import_entries + [{
        "asset_id": bundle_id,
        "source_file": root_relative(root, spriteframes_path),
        "res_path": res_path(root, scene_path),
        "target_node": "AnimatedSprite2D",
        "import_preset": "sprite_bundle_scene",
        "notes": "Generated SpriteFrames and AnimatedSprite2D scene.",
    }])

    return {
        "status": "ok",
        "bundle_id": bundle_id,
        "spriteframes": root_relative(root, spriteframes_path),
        "scene": root_relative(root, scene_path),
        "actions": [action_name_from_asset(entry.get("asset_id", ""), bundle_id) for entry in entries],
    }


def parse_json_list(root: Path, value: str | None, keys: tuple[str, ...]) -> list[dict[str, Any]]:
    path = resolve_project_path(root, value)
    data = load_json_if_exists(path)
    if isinstance(data, list):
        return [item for item in data if isinstance(item, dict)]
    if isinstance(data, dict):
        for key in keys:
            if isinstance(data.get(key), list):
                return [item for item in data[key] if isinstance(item, dict)]
    return []


def rect_values(item: dict[str, Any]) -> tuple[float, float, float, float]:
    rect = item.get("rect")
    if isinstance(rect, list) and len(rect) >= 4:
        return float(rect[0]), float(rect[1]), float(rect[2]), float(rect[3])
    if isinstance(rect, dict):
        return float(rect.get("x", 0)), float(rect.get("y", 0)), float(rect.get("w", rect.get("width", 32))), float(rect.get("h", rect.get("height", 32)))
    return (
        float(item.get("x", 0)),
        float(item.get("y", 0)),
        float(item.get("w", item.get("width", 32))),
        float(item.get("h", item.get("height", 32))),
    )


def map_entries(root: Path, asset_id: str) -> list[dict[str, str]]:
    entries = parse_asset_manifest(manifest_path(root))
    allowed = ("map", "level", "stage", "tilemap", "parallax")
    selected = []
    for entry in entries:
        if asset_id and entry.get("asset_id") != asset_id:
            continue
        kind = entry.get("asset_kind", "").lower()
        category = entry.get("category", "").lower()
        if any(token in kind or token in category for token in allowed):
            selected.append(entry)
    return selected


def node_name(value: str, fallback: str) -> str:
    return pascal_name(str(value or fallback))


def godot_map_command(args: argparse.Namespace) -> dict[str, Any]:
    root = Path(args.project).resolve()
    entries = map_entries(root, args.asset_id)
    if not entries:
        raise ValueError("No map-like asset entries found.")

    scene_dir = root / "scenes" / "levels"
    ensure_dir(scene_dir)
    outputs: list[dict[str, str]] = []

    for entry in entries:
        asset_id = safe_id(entry.get("asset_id", "level"))
        ext_lines: list[str] = []
        sub_lines: list[str] = []
        node_lines: list[str] = [
            "[node name=\"Level\" type=\"Node2D\"]",
            "",
        ]
        load_steps = 1

        preview = resolve_project_path(root, entry.get("preview_file") or entry.get("processed_file") or entry.get("selected_file"))
        if preview and preview.exists():
            load_steps += 1
            ext_lines.append(f'[ext_resource type="Texture2D" path="{res_path(root, preview)}" id="1_preview"]')
            node_lines.extend([
                "[node name=\"VisualPreview\" type=\"Sprite2D\" parent=\".\"]",
                'texture = ExtResource("1_preview")',
                "centered = false",
                "",
            ])

        props = parse_json_list(root, entry.get("props_metadata"), ("props", "objects", "placements", "items"))
        ext_index = 2
        for index, prop in enumerate(props):
            file_value = prop.get("file") or prop.get("source") or prop.get("path") or prop.get("image")
            prop_path = resolve_project_path(root, str(file_value)) if file_value else None
            if not prop_path or not prop_path.exists():
                continue
            ref_id = f"{ext_index}_prop_{index}"
            ext_index += 1
            load_steps += 1
            ext_lines.append(f'[ext_resource type="Texture2D" path="{res_path(root, prop_path)}" id="{ref_id}"]')
            x = float(prop.get("x", 0))
            y = float(prop.get("y", 0))
            node_lines.extend([
                f'[node name="{node_name(prop.get("name", ""), f"Prop{index}")}" type="Sprite2D" parent="."]',
                f'position = Vector2({x:g}, {y:g})',
                f'texture = ExtResource("{ref_id}")',
                "",
            ])

        collision = parse_json_list(root, entry.get("collision_metadata"), ("collision", "collisions", "solids", "blockers"))
        for index, item in enumerate(collision):
            x, y, w, h = rect_values(item)
            sub_name = f"{index + 1}_collision_shape"
            load_steps += 1
            sub_lines.extend([
                f'[sub_resource type="RectangleShape2D" id="{sub_name}"]',
                f"size = Vector2({w:g}, {h:g})",
                "",
            ])
            body_name = node_name(item.get("name", ""), f"Collision{index}")
            node_lines.extend([
                f'[node name="{body_name}" type="StaticBody2D" parent="."]',
                f'position = Vector2({x + w / 2:g}, {y + h / 2:g})',
                "",
                f'[node name="CollisionShape2D" type="CollisionShape2D" parent="{body_name}"]',
                f'shape = SubResource("{sub_name}")',
                "",
            ])

        zones = parse_json_list(root, entry.get("zones_metadata"), ("zones", "areas", "triggers", "exits"))
        for index, item in enumerate(zones):
            x, y, w, h = rect_values(item)
            sub_name = f"{index + 1}_zone_shape"
            load_steps += 1
            sub_lines.extend([
                f'[sub_resource type="RectangleShape2D" id="{sub_name}"]',
                f"size = Vector2({w:g}, {h:g})",
                "",
            ])
            zone_name = node_name(item.get("name", ""), f"Zone{index}")
            node_lines.extend([
                f'[node name="{zone_name}" type="Area2D" parent="."]',
                f'position = Vector2({x + w / 2:g}, {y + h / 2:g})',
                "",
                f'[node name="CollisionShape2D" type="CollisionShape2D" parent="{zone_name}"]',
                f'shape = SubResource("{sub_name}")',
                "",
            ])

        if entry.get("tiles_metadata", ""):
            node_lines.extend([
                "[node name=\"EditableTileMap\" type=\"TileMapLayer\" parent=\".\"]",
                "",
            ])

        scene_path = scene_dir / f"{asset_id}.tscn"
        scene_text = "\n".join([
            f"[gd_scene load_steps={load_steps} format=3]",
            "",
            *ext_lines,
            "",
            *sub_lines,
            *node_lines,
        ])
        write_text(scene_path, scene_text)
        append_import_manifest(root, [{
            "asset_id": asset_id,
            "source_file": entry.get("preview_file") or entry.get("processed_file") or entry.get("selected_file", ""),
            "res_path": res_path(root, scene_path),
            "target_node": "Node2D",
            "import_preset": "editable_map_scene",
            "notes": "Generated level scene with Sprite2D, StaticBody2D, Area2D, and optional TileMapLayer placeholders.",
        }])
        outputs.append({"asset_id": asset_id, "scene": root_relative(root, scene_path)})

    return {"status": "ok", "levels": outputs}


def reference_variant_command(args: argparse.Namespace) -> dict[str, Any]:
    root = Path(args.root).resolve()
    style_lock = load_style_lock(root, allow_unlocked_lookdev=bool(args.lookdev))
    reference_path = (root / args.reference_file).resolve()
    try:
        reference_path.relative_to(root)
    except ValueError as exc:
        raise RuntimeError("reference file must remain inside the project") from exc
    if not reference_path.is_file():
        raise RuntimeError(f"reference file does not exist: {args.reference_file}")
    if not args.lookdev:
        locked_references = {
            (root / str(row.get("path", ""))).resolve()
            for row in style_lock.get("locked_references", [])
            if isinstance(row, dict) and row.get("path")
        }
        if reference_path not in locked_references:
            raise RuntimeError(
                "Production reference variants must use a reference from the sealed style lock; "
                "use --lookdev for candidates or reseal a new style version first"
            )
    asset_id = safe_id(args.asset_id)
    actions = parse_actions(args.actions)
    variant_dir = root / "design" / "assets" / "reference-variants"
    ensure_dir(variant_dir)
    key_color = args.key_color if args.key_color != "suggest" else suggest_key(args.description)

    lines = [
        f"asset_id: {asset_id}",
        f"reference_file: {args.reference_file}",
        f"description: {yaml_quote(args.description)}",
        f"key_color: {yaml_quote(key_color)}",
        "style_lock:",
        "  path: design/art/style-lock.json",
        f"  style_version: {yaml_quote(str(style_lock.get('style_version', '')))}",
        f"  style_lock_sha256: {yaml_quote(str(style_lock.get('digest', '')))}",
        f"  art_bible_sha256: {yaml_quote(str(style_lock.get('art_bible_sha256', '')))}",
        "identity_lock:",
        "  preserve: silhouette, face shape, costume motifs, color palette, readable proportions",
        "  allowed_variation: pose, limb placement, expression, squash/stretch, motion smear",
        "  forbidden_variation: outfit redesign, species change, palette drift, extra limbs, text labels",
        "actions:",
    ]
    for action in actions:
        lines.extend([
            f"  - action: {action.name}",
            f"    rows: {action.rows}",
            f"    cols: {action.cols}",
            f"    expected_frames: {action.expected_frames}",
            f"    fps: {action.fps:g}",
            f"    anchor: {action.anchor}",
        ])
    lines.extend([
        "prompt_notes:",
        "  - Use the reference image as identity guidance, not as a background.",
        "  - Generate one action per raw sheet.",
        "  - Keep every frame isolated on the selected flat chroma-key background.",
        "",
    ])
    path = variant_dir / f"{asset_id}.yaml"
    write_text(path, "\n".join(lines))
    return {"status": "ok", "variant_spec": root_relative(root, path), "key_color": key_color}


def showcase_command(args: argparse.Namespace) -> dict[str, Any]:
    root = Path(args.root).resolve()
    name = safe_id(args.name)
    project = root / "examples" / name
    write_text(project / "project.godot", "\n".join([
        "; Engine configuration file.",
        "; Generated by Codex Game Maker asset workflow.",
        "config_version=5",
        "",
        "[application]",
        f'config/name="{args.title}"',
        'run/main_scene="res://scenes/main/Main.tscn"',
        'config/features=PackedStringArray("4.6", "Forward Plus")',
        "",
        "[display]",
        "window/size/viewport_width=960",
        "window/size/viewport_height=540",
        "",
    ]))
    write_text(project / "export_presets.cfg", "\n".join([
        "[preset.0]",
        "",
        'name="Web"',
        'platform="Web"',
        "runnable=true",
        "dedicated_server=false",
        'custom_features=""',
        'export_filter="all_resources"',
        'include_filter=""',
        'exclude_filter=""',
        'export_path="build/web/index.html"',
        'encryption_include_filters=""',
        'encryption_exclude_filters=""',
        "encrypt_pck=false",
        "encrypt_directory=false",
        "",
        "[preset.0.options]",
        "",
        'custom_template/debug=""',
        'custom_template/release=""',
        "variant/extensions_support=false",
        "vram_texture_compression/for_desktop=true",
        "vram_texture_compression/for_mobile=false",
        "html/export_icon=true",
        'html/custom_html_shell=""',
        'html/head_include=""',
        "html/canvas_resize_policy=2",
        "html/focus_canvas_on_start=true",
        "html/experimental_virtual_keyboard=false",
        "progressive_web_app/enabled=false",
        'progressive_web_app/offline_page=""',
        "progressive_web_app/display=1",
        "progressive_web_app/orientation=0",
        'progressive_web_app/icon_144x144=""',
        'progressive_web_app/icon_180x180=""',
        'progressive_web_app/icon_512x512=""',
        "progressive_web_app/background_color=Color(0, 0, 0, 1)",
        "",
    ]))
    write_text(project / "design" / "scene-scale-plan.yaml", "\n".join([
        'schema: "codex-game-maker.scene-scale-plan.v1"',
        "viewport:",
        '  aspect_ratio: "16:9"',
        "  design_width: 1280",
        "  design_height: 720",
        '  stretch_mode: "canvas_items"',
        '  stretch_aspect: "keep"',
        "world:",
        "  width: 1600",
        "  camera_height: 720",
        '  camera_rule: "follow player with lead, clamp to world bounds"',
        "grounding_contract:",
        "  platform_collision:",
        '    representation: "top_y + collision_width + collision_height"',
        '    visual_overlap_rule: "scale from platform visual scale"',
        "  player:",
        '    grounded_pivot: "feet"',
        '    visual_foot_sink_rule: "derive from current floor/platform visual scale"',
        "runtime_asset_scale:",
        "  player:",
        "    target_height_px: 96",
        '    pivot: "feet"',
        "  platform:",
        "    target_height_px: 72",
        '    pivot: "top_center"',
        "  collectible:",
        "    target_height_px: 48",
        '    pivot: "center"',
        "  finish:",
        "    target_height_px: 120",
        '    pivot: "bottom"',
        "",
    ]))
    write_text(project / "production" / "smoke-tests" / "playable-showcase-qa.md", "\n".join([
        "# Playable Showcase QA",
        "",
        "- [ ] Player starts grounded on frame one.",
        "- [ ] Player does not float above large platforms.",
        "- [ ] Player does not sink into small platforms.",
        "- [ ] Idle is the default no-input state.",
        "- [ ] Run/walk alternates feet and loops cleanly.",
        "- [ ] Jump uses phase frames instead of a blind loop.",
        "- [ ] Every collectible instance animates and can be collected.",
        "- [ ] Finish object triggers a clear state.",
        "- [ ] No collision/debug rectangles render in runtime.",
        "- [ ] Web preview was hard-refreshed after export.",
        "",
        "Evidence:",
        "",
        "```text",
        "Not run yet.",
        "```",
        "",
    ]))
    write_text(project / "README.md", "\n".join([
        f"# {args.title}",
        "",
        "A Godot 4.6.2 showcase skeleton for validating Codex Game Maker generated assets.",
        "",
        "Expected flow:",
        "",
        "1. Create an action bundle.",
        "2. Generate raw image sheets with the recorded prompts.",
        "3. Process sheets into transparent frames and GIF previews.",
        "4. Import accepted sprite bundles into Godot.",
        "5. Use `design/scene-scale-plan.yaml` before placing assets in-engine.",
        "6. Run the main scene and verify the generated character or map in-engine.",
        "7. Fill `production/smoke-tests/playable-showcase-qa.md` before calling the showcase ready.",
        "",
    ]))
    write_text(project / "design" / "gdd" / "game-concept.md", "\n".join([
        "# Asset Pipeline Showcase Concept",
        "",
        "Goal: prove that generated 2D assets can move from image output to Godot runtime scenes with clear QA evidence.",
        "",
    ]))
    write_text(project / "design" / "art" / "art-bible.md", "\n".join([
        "# Art Bible",
        "",
        "- style: readable 2D game-ready assets",
        "- background handling: smart chroma key with transparent processed outputs",
        "- runtime target: Godot 4.6.2",
        "",
    ]))
    write_text(project / "scripts" / "main.gd", "\n".join([
        "extends Node2D",
        "",
        "@onready var status_label: Label = $CanvasLayer/StatusLabel",
        "",
        "func _ready() -> void:",
        "    status_label.text = \"Import a generated sprite scene, then instance it under ShowcaseRoot.\"",
        "",
    ]))
    write_text(project / "scenes" / "main" / "Main.tscn", "\n".join([
        "[gd_scene load_steps=2 format=3]",
        "",
        '[ext_resource type="Script" path="res://scripts/main.gd" id="1_main"]',
        "",
        "[node name=\"Main\" type=\"Node2D\"]",
        "script = ExtResource(\"1_main\")",
        "",
        "[node name=\"ShowcaseRoot\" type=\"Node2D\" parent=\".\"]",
        "position = Vector2(480, 340)",
        "",
        "[node name=\"CanvasLayer\" type=\"CanvasLayer\" parent=\".\"]",
        "",
        "[node name=\"StatusLabel\" type=\"Label\" parent=\"CanvasLayer\"]",
        "offset_left = 24.0",
        "offset_top = 24.0",
        "offset_right = 936.0",
        "offset_bottom = 68.0",
        "",
    ]))
    return {"status": "ok", "project": root_relative(root, project)}


def write_result(result: dict[str, Any]) -> None:
    print(json.dumps(result, indent=2))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Codex Game Maker asset workflow tools")
    sub = parser.add_subparsers(dest="command", required=True)

    action = sub.add_parser("action-bundle", help="plan and optionally process a multi-action sprite bundle")
    action.add_argument("--root", default=".")
    action.add_argument("--asset-id", required=True)
    action.add_argument("--description", required=True)
    action.add_argument("--category", default="characters")
    action.add_argument("--view", default="side")
    action.add_argument("--direction-model", default="auto", choices=["auto", "none", "full_directional", "side_only_last_horizontal"])
    action.add_argument("--actions", default="idle,run,jump,attack,hurt")
    action.add_argument("--key-color", default="suggest")
    action.add_argument("--reference-file", default="")
    action.add_argument("--lookdev", action="store_true", help="Allow an unlocked style only while generating comparison candidates; output cannot pass player-ready")
    action.add_argument("--cell-width", type=int, default=384)
    action.add_argument("--cell-height", type=int, default=384)
    action.add_argument("--jump-cell-height", type=int, default=512)
    action.add_argument("--safe-margin", type=int, default=56)
    action.add_argument("--max-foot-drift", type=int, default=18)
    action.add_argument("--max-scale-drift", type=float, default=0.16)
    action.add_argument("--fit-scale", type=float, default=0.92)
    action.add_argument("--tolerance", type=int, default=70)
    action.add_argument("--softness", type=int, default=32)
    action.add_argument("--process-existing-raw", action="store_true")
    action.set_defaults(func=action_bundle_command)

    repair = sub.add_parser("repair-assets", help="propose or apply deterministic asset processing repairs")
    repair.add_argument("--root", default=".")
    repair.add_argument("--asset-id", default="")
    repair.add_argument("--apply", action="store_true")
    repair.add_argument("--max-attempts", type=int, default=4)
    repair.set_defaults(func=repair_assets_command)

    sprite = sub.add_parser("godot-sprite", help="generate SpriteFrames and AnimatedSprite2D scene from accepted sprites")
    sprite.add_argument("--project", default=".")
    sprite.add_argument("--bundle-id", required=True)
    sprite.add_argument("--asset-ids", default="")
    sprite.add_argument("--scene-name", default="")
    sprite.set_defaults(func=godot_sprite_command)

    level = sub.add_parser("godot-map", help="generate editable Godot level scenes from map metadata")
    level.add_argument("--project", default=".")
    level.add_argument("--asset-id", default="")
    level.set_defaults(func=godot_map_command)

    variant = sub.add_parser("reference-variant", help="write reference-guided variant generation spec")
    variant.add_argument("--root", default=".")
    variant.add_argument("--asset-id", required=True)
    variant.add_argument("--reference-file", required=True)
    variant.add_argument("--description", required=True)
    variant.add_argument("--actions", default="idle,run,jump")
    variant.add_argument("--key-color", default="suggest")
    variant.add_argument("--lookdev", action="store_true", help="Allow an unlocked reference only for candidate comparison; output cannot pass player-ready")
    variant.set_defaults(func=reference_variant_command)

    showcase = sub.add_parser("showcase", help="create a Godot 4.6.2 asset pipeline showcase skeleton")
    showcase.add_argument("--root", default=".")
    showcase.add_argument("--name", default="asset-pipeline-showcase")
    showcase.add_argument("--title", default="Asset Pipeline Showcase")
    showcase.set_defaults(func=showcase_command)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        write_result(args.func(args))
        return 0
    except Exception as exc:
        print(json.dumps({"error": str(exc)}, indent=2), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
