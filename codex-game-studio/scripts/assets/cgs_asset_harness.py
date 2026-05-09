#!/usr/bin/env python3
"""Codex Game Maker asset harness generator and validator.

The harness is a deterministic geometry contract for image-generated game
assets. It creates a reference guide plus a machine-readable spec, then checks
raw sheets against exact canvas, cell, safe-zone, crop, and motion constraints.
"""

from __future__ import annotations

import argparse
import json
import math
import re
import sys
from collections import deque
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import numpy as np
from PIL import Image, ImageDraw

try:
    import cgs_asset_processor as processor
except ImportError:  # pragma: no cover
    processor = None  # type: ignore[assignment]


DEFAULT_KEY_COLOR = (255, 0, 255)
SCHEMA = "codex-game-maker.asset-harness.v1"


@dataclass
class BBox:
    left: int
    top: int
    right: int
    bottom: int

    @property
    def width(self) -> int:
        return max(0, self.right - self.left)

    @property
    def height(self) -> int:
        return max(0, self.bottom - self.top)

    @property
    def empty(self) -> bool:
        return self.width == 0 or self.height == 0


def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def as_posix(path: Path) -> str:
    return path.as_posix()


def safe_id(value: str) -> str:
    clean = re.sub(r"[^A-Za-z0-9_.-]+", "-", value.strip())
    clean = re.sub(r"-+", "-", clean).strip("-")
    return clean or "asset"


def parse_color(value: str) -> tuple[int, int, int]:
    if processor is not None:
        return processor.parse_color(value)
    clean = value.strip()
    if clean.startswith("#"):
        clean = clean[1:]
    if len(clean) != 6:
        raise ValueError(f"Invalid color value: {value}")
    return tuple(int(clean[index:index + 2], 16) for index in (0, 2, 4))  # type: ignore[return-value]


def color_hex(color: tuple[int, int, int]) -> str:
    return "#{:02X}{:02X}{:02X}".format(*color)


def add_item(items: list[dict[str, Any]], code: str, message: str, path: str = "", **extra: Any) -> None:
    item: dict[str, Any] = {"code": code, "message": message}
    if path:
        item["path"] = path
    item.update(extra)
    items.append(item)


def bbox_from_mask(mask: np.ndarray) -> BBox:
    ys, xs = np.where(mask)
    if len(xs) == 0 or len(ys) == 0:
        return BBox(0, 0, 0, 0)
    return BBox(int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1)


def load_rgba(path: Path) -> Image.Image:
    if not path.exists():
        raise FileNotFoundError(f"Input image not found: {path}")
    return Image.open(path).convert("RGBA")


def mask_from_image(image: Image.Image, key_color: tuple[int, int, int], tolerance: int, alpha_threshold: int) -> np.ndarray:
    arr = np.array(image.convert("RGBA"), dtype=np.int16)
    alpha = arr[:, :, 3]
    if np.any(alpha < 250):
        return alpha > alpha_threshold

    rgb = arr[:, :, :3]
    target = np.array(key_color, dtype=np.int16)
    delta = np.abs(rgb - target).max(axis=2)
    return delta > tolerance


def edge_counts(mask: np.ndarray, margin: int) -> dict[str, int]:
    margin = max(1, min(margin, mask.shape[0], mask.shape[1]))
    return {
        "top": int(np.count_nonzero(mask[:margin, :])),
        "bottom": int(np.count_nonzero(mask[-margin:, :])),
        "left": int(np.count_nonzero(mask[:, :margin])),
        "right": int(np.count_nonzero(mask[:, -margin:])),
    }


def connected_components(mask: np.ndarray, min_area: int) -> list[dict[str, Any]]:
    height, width = mask.shape
    seen = np.zeros(mask.shape, dtype=bool)
    components: list[dict[str, Any]] = []
    starts = np.argwhere(mask)

    for sy, sx in starts:
        y = int(sy)
        x = int(sx)
        if seen[y, x]:
            continue

        queue: deque[tuple[int, int]] = deque([(y, x)])
        seen[y, x] = True
        area = 0
        min_x = max_x = x
        min_y = max_y = y

        while queue:
            cy, cx = queue.popleft()
            area += 1
            if cx < min_x:
                min_x = cx
            if cx > max_x:
                max_x = cx
            if cy < min_y:
                min_y = cy
            if cy > max_y:
                max_y = cy

            for ny, nx in ((cy - 1, cx), (cy + 1, cx), (cy, cx - 1), (cy, cx + 1)):
                if ny < 0 or ny >= height or nx < 0 or nx >= width:
                    continue
                if seen[ny, nx] or not mask[ny, nx]:
                    continue
                seen[ny, nx] = True
                queue.append((ny, nx))

        if area >= min_area:
            components.append({
                "area": area,
                "bbox": {"left": min_x, "top": min_y, "right": max_x + 1, "bottom": max_y + 1},
            })

    components.sort(key=lambda item: int(item["area"]), reverse=True)
    return components


def median(values: list[float]) -> float:
    if not values:
        return 0.0
    return float(np.median(np.array(values, dtype=np.float32)))


def max_relative_drift(values: list[float]) -> float:
    base = median([value for value in values if value > 0])
    if base <= 0:
        return 0.0
    return max(abs(value - base) / base for value in values)


def lower_body_transition_diffs(
    image: Image.Image,
    spec: dict[str, Any],
    key_color: tuple[int, int, int],
    tolerance: int,
    alpha_threshold: int,
) -> list[float]:
    grid = spec["grid"]
    rows = int(grid["rows"])
    cols = int(grid["cols"])
    cell_w = int(grid["cell_width"])
    cell_h = int(grid["cell_height"])
    cells: list[tuple[np.ndarray, np.ndarray]] = []

    for index in range(rows * cols):
        row = index // cols
        col = index % cols
        cell = image.crop((col * cell_w, row * cell_h, (col + 1) * cell_w, (row + 1) * cell_h)).convert("RGBA")
        lower_top = int(cell_h * 0.56)
        lower = cell.crop((0, lower_top, cell_w, cell_h))
        lower_arr = np.array(lower, dtype=np.int16)
        lower_mask = mask_from_image(lower, key_color, tolerance, alpha_threshold)
        cells.append((lower_arr, lower_mask))

    diffs: list[float] = []
    for index, (current_arr, current_mask) in enumerate(cells):
        next_arr, next_mask = cells[(index + 1) % len(cells)]
        union = current_mask | next_mask
        if not np.any(union):
            diffs.append(0.0)
            continue
        rgb_delta = np.abs(current_arr[:, :, :3] - next_arr[:, :, :3])
        diffs.append(float(np.mean(rgb_delta[union]) / 255.0))
    return diffs


def phase_plan(action: str, frames: int, view_profile: str = "neutral") -> list[str]:
    action = action.lower()
    view_profile = view_profile.lower()
    if action in ("run", "walk"):
        if view_profile == "top_down_survivor":
            labels = [
                "neutral contact",
                "small left-foot shuffle",
                "center settle",
                "small right-foot shuffle",
                "neutral return",
                "small left-foot shuffle return",
                "center settle return",
                "loop bridge",
            ]
            return labels[:frames]
        labels = [
            "left-foot contact",
            "down recoil",
            "passing pose",
            "up pose",
            "right-foot contact",
            "down recoil",
            "passing pose",
            "up pose",
            "left-foot contact return",
            "recovery",
            "passing pose",
            "loop bridge",
        ]
        return labels[:frames]
    if action == "jump":
        labels = [
            "anticipation crouch",
            "takeoff stretch",
            "rise",
            "apex",
            "early fall",
            "fall",
            "landing contact",
            "landing recovery",
        ]
        return labels[:frames]
    if action == "idle":
        labels = ["neutral", "breath in", "hold", "breath out", "settle", "loop bridge", "secondary motion", "return"]
        return labels[:frames]
    return [f"pose {index + 1}" for index in range(frames)]


def prompt_contract(spec: dict[str, Any]) -> str:
    grid = spec["grid"]
    canvas = spec["canvas"]
    action = spec.get("action", "")
    view_profile = str(spec.get("view_profile", "neutral")).lower()
    frames = int(grid["rows"]) * int(grid["cols"])
    phases = phase_plan(action, frames, view_profile)
    phase_text = "; ".join(f"{index + 1}: {label}" for index, label in enumerate(phases))
    safe = spec["safe_zone"]
    foot = spec.get("foot_line_y", 0)

    lines = [
        f"# Asset Harness Prompt Contract: {spec['asset_id']}",
        "",
        "Use this contract when generating the raw image sheet.",
        "",
        f"- Exact canvas: {canvas['width']}x{canvas['height']} pixels.",
        f"- Exact grid: {grid['rows']} rows x {grid['cols']} columns.",
        f"- Exact cell size: {grid['cell_width']}x{grid['cell_height']} pixels.",
        f"- Background: one flat solid chroma-key color {spec['key_color']} across every cell.",
        f"- Safe zone per cell: x {safe['left']}..{safe['right']}, y {safe['top']}..{safe['bottom']}.",
        "- The subject must stay completely inside the safe zone in every frame.",
        "- Leave empty chroma-key padding around ears, tails, feet, weapons, trails, dust, and effects.",
        "- Do not draw grid lines, borders, labels, frame numbers, watermarks, UI, or debug overlays.",
        "- Keep the same character identity, costume, scale, camera angle, and lighting across all frames.",
        "- Do not let any body part or prop cross into a neighboring cell.",
        "- Do not fake animation by stacking a second full-body character, ghost limbs, or unmasked duplicated limb crops over the base pose.",
        "- If a local repair shifts a foot, hand, limb, tail, or prop, remove or repaint the original pixels first so only one clean visible body remains.",
        "- Do not use semi-transparent shadows, glows, dust, or motion trails in a chroma-key raw sheet; generate those as separate FX sheets or opaque runtime assets.",
        "- Preserve a stable runtime pivot and visible bounding box so the asset can be scaled consistently in a 16:9 scene.",
        "- If the subject has a long tail, weapon, staff, cape, trail, or backpack, it still must fit fully inside the safe zone in every frame.",
        "- If the prop or tail cannot fit comfortably, generate a larger-cell harness or move that element to a separate attack/cast/FX sheet.",
    ]
    if view_profile == "top_down_survivor":
        lines.extend([
            "- View profile: top-down survivor / arena action.",
            "- Do not use a side-view platformer run silhouette for this asset.",
            "- Movement is a restrained top-down shuffle: visible alternating feet and hands, no long stride, no airborne running pose.",
            "- Body shake, whole-sprite wobble, or camera/pivot jitter is not locomotion and must not be used as the primary animation.",
            "- Do not fake movement by translating, scaling, or globally warping the whole character; keep head, torso, tail, equipment, pivot, and foot baseline stable.",
            "- Choose locomotion-friendly silhouettes: short jacket, separated visible feet, and no long robe, skirt, staff, cape, or prop blocking the feet in move/idle sheets.",
            "- If the current character concept hides the feet, regenerate a locomotion-friendly variant before making the runtime walk cycle.",
            "- Build idle as its own loop. A stopped character must never freeze on a walk/run contact pose.",
            "- Direction matters for polished directional characters. Plan separate down, side, and up sheets, or use one canonical four-direction sheet.",
            "- If the project chooses a side-only survivor model, record direction_model=side_only_last_horizontal and generate only approved idle_side/move_side sheets instead of weak north/south variants.",
            "- Up/down movement should not look like the character is sliding sideways across the arena unless the side-only model is explicitly chosen for that prototype.",
            "- Keep attack/cast props and weapon swings separate from locomotion unless the game design explicitly needs an always-held prop.",
        ])
    if foot > 0:
        lines.append(f"- Character foot/bottom baseline: keep grounded frames near y={foot} inside each cell.")
    if action:
        lines.append(f"- Motion phases: {phase_text}.")
    if action in ("run", "walk"):
        if view_profile == "top_down_survivor":
            lines.extend([
                "- This must be a restrained locomotion loop, not a platformer sprint.",
                "- Use 8 frames for each top-down direction unless a higher-fidelity pass is explicitly requested.",
                "- Feet and hands must alternate visibly under the body. Keep head, torso, and equipment from growing, shrinking, wobbling, or lunging forward.",
                "- The first and last poses must connect cleanly without a pop.",
                "- Contact feet should stay near the same baseline; avoid sliding, sinking, or floating feet between frames.",
            ])
        else:
            lines.extend([
                "- This must be a real loop: left-foot and right-foot contacts must alternate.",
                "- The first and last poses must connect cleanly without a pop.",
                "- Contact feet should land on the same baseline; avoid sliding, sinking, or floating feet between frames.",
                "- For controllable heroes, prefer 12 frames in a 3x4 grid for run/walk unless the user explicitly asks for a lower-fidelity pass.",
                "- Do not include held staffs, large weapons, dust clouds, or magic trails in the locomotion loop; generate those as separate actions or FX.",
            ])
    if action == "jump":
        lines.extend([
            "- This is a phased airborne action, not a looping animation.",
            "- Include readable takeoff/rise/apex/fall/landing poses with stable identity and no adjacent-frame fragments.",
        ])
    if spec["kind"] == "platform":
        lines.extend([
            "- Platform art must not be cropped by the canvas edge unless it is explicitly marked tileable.",
            "- Include transparent/key-color padding around decorative grass, flowers, stones, roots, and underside details.",
            "- If the platform is meant to repeat horizontally, generate left, middle, and right pieces separately.",
            "- Keep a clear flat collision top surface; decorative grass may overlap above it but must be accounted for in runtime visual_top_overlap.",
            "- Generate the platform for a planned runtime size instead of relying on arbitrary stretching in the engine.",
        ])
    return "\n".join(lines) + "\n"


def make_harness_image(spec: dict[str, Any], path: Path) -> None:
    canvas = spec["canvas"]
    grid = spec["grid"]
    key_color = parse_color(spec["key_color"])
    width = int(canvas["width"])
    height = int(canvas["height"])
    cell_w = int(grid["cell_width"])
    cell_h = int(grid["cell_height"])
    rows = int(grid["rows"])
    cols = int(grid["cols"])
    safe = spec["safe_zone"]

    image = Image.new("RGBA", (width, height), (*key_color, 255))
    overlay = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    for row in range(rows):
        for col in range(cols):
            left = col * cell_w
            top = row * cell_h
            right = left + cell_w
            bottom = top + cell_h
            draw.rectangle((left, top, right - 1, bottom - 1), outline=(30, 30, 30, 210), width=3)
            draw.rectangle(
                (
                    left + int(safe["left"]),
                    top + int(safe["top"]),
                    left + int(safe["right"]) - 1,
                    top + int(safe["bottom"]) - 1,
                ),
                outline=(255, 255, 255, 230),
                width=2,
            )
            draw.rectangle(
                (
                    left + int(safe["left"]),
                    top + int(safe["top"]),
                    left + int(safe["right"]) - 1,
                    top + int(safe["bottom"]) - 1,
                ),
                fill=(255, 255, 255, 20),
            )
            foot = int(spec.get("foot_line_y", 0) or 0)
            if foot > 0:
                y = top + foot
                draw.line((left + int(safe["left"]), y, left + int(safe["right"]), y), fill=(0, 30, 255, 230), width=2)
            draw.text((left + 8, top + 8), f"{row + 1},{col + 1}", fill=(255, 255, 255, 240))

    image.alpha_composite(overlay)
    ensure_dir(path.parent)
    image.convert("RGB").save(path)


def build_spec(args: argparse.Namespace) -> dict[str, Any]:
    asset_id = safe_id(args.asset_id)
    rows = int(args.rows)
    cols = int(args.cols)
    cell_w = int(args.cell_width)
    cell_h = int(args.cell_height)
    safe_margin = int(args.safe_margin)
    canvas_w = rows and cols * cell_w
    canvas_h = rows * cell_h
    key_color = color_hex(parse_color(args.key_color))
    action = safe_id(args.action).lower() if args.action else ""

    foot_line_actions = {"idle", "walk", "run", "hurt", "death"}
    foot_line = int(args.foot_line)
    if foot_line <= 0 and args.kind == "sprite" and action in foot_line_actions:
        foot_line = max(1, cell_h - safe_margin)

    edge_guard = int(args.edge_guard) if int(args.edge_guard) > 0 else max(4, min(16, safe_margin // 3))
    min_component_area = int(args.min_component_area) if int(args.min_component_area) > 0 else max(32, int(cell_w * cell_h * 0.001))
    max_scale_drift = float(args.max_scale_drift)
    if action in {"jump", "fall", "attack"}:
        max_scale_drift = max(max_scale_drift, 0.50)

    safe_zone = {
        "left": safe_margin,
        "top": safe_margin,
        "right": cell_w - safe_margin,
        "bottom": cell_h - safe_margin,
    }

    spec = {
        "schema": SCHEMA,
        "asset_id": asset_id,
        "kind": args.kind,
        "action": action,
        "view_profile": args.view_profile,
        "target_engine": "Godot 4.4",
        "canvas": {"width": canvas_w, "height": canvas_h},
        "grid": {"rows": rows, "cols": cols, "cell_width": cell_w, "cell_height": cell_h},
        "safe_margin": safe_margin,
        "safe_zone": safe_zone,
        "edge_guard_px": edge_guard,
        "key_color": key_color,
        "foot_line_y": foot_line,
        "acceptance": {
            "alpha_threshold": int(args.alpha_threshold),
            "key_tolerance": int(args.key_tolerance),
            "min_component_area": min_component_area,
            "max_scale_drift_ratio": max_scale_drift,
            "max_foot_drift_px": int(args.max_foot_drift),
            "min_lower_body_transition_diff": 0.13,
            "max_weak_motion_transitions": 2,
            "allow_empty_cells": bool(args.allow_empty_cells),
            "allow_horizontal_edge_touch": bool(args.allow_horizontal_edge_touch),
            "allow_vertical_edge_touch": bool(args.allow_vertical_edge_touch),
            "block_safe_zone_violations": True,
            "block_neighbor_fragments": True,
        },
        "runtime_contract": {
            "pivot": args.pivot,
            "frame_order": "left-to-right, top-to-bottom",
            "loop": bool(args.loop),
            "view_profile": args.view_profile,
            "motion_phases": phase_plan(action, rows * cols, args.view_profile),
        },
        "outputs": {},
    }
    return spec


def create_command(args: argparse.Namespace) -> dict[str, Any]:
    out_dir = Path(args.out_dir).resolve()
    ensure_dir(out_dir)
    spec = build_spec(args)
    asset_id = spec["asset_id"]
    guide_path = out_dir / f"{asset_id}.harness.png"
    spec_path = out_dir / f"{asset_id}.harness.json"
    prompt_path = out_dir / f"{asset_id}.prompt.md"

    spec["outputs"] = {
        "harness_guide": as_posix(guide_path),
        "harness_spec": as_posix(spec_path),
        "prompt_contract": as_posix(prompt_path),
    }

    make_harness_image(spec, guide_path)
    prompt_path.write_text(prompt_contract(spec), encoding="utf-8")
    spec_path.write_text(json.dumps(spec, indent=2), encoding="utf-8")

    return {
        "status": "ok",
        "asset_id": asset_id,
        "kind": spec["kind"],
        "harness_guide": as_posix(guide_path),
        "harness_spec": as_posix(spec_path),
        "prompt_contract": as_posix(prompt_path),
    }


def validate_cells(image: Image.Image, spec: dict[str, Any], input_path: Path) -> dict[str, Any]:
    grid = spec["grid"]
    rows = int(grid["rows"])
    cols = int(grid["cols"])
    cell_w = int(grid["cell_width"])
    cell_h = int(grid["cell_height"])
    expected_w = int(spec["canvas"]["width"])
    expected_h = int(spec["canvas"]["height"])
    acceptance = spec.get("acceptance", {})
    key_color = parse_color(str(spec.get("key_color", "#FF00FF")))
    key_tolerance = int(acceptance.get("key_tolerance", 24))
    alpha_threshold = int(acceptance.get("alpha_threshold", 8))
    edge_guard = int(spec.get("edge_guard_px", 8))
    safe = spec["safe_zone"]
    allow_empty = bool(acceptance.get("allow_empty_cells", False))
    allow_x_edge = bool(acceptance.get("allow_horizontal_edge_touch", False))
    allow_y_edge = bool(acceptance.get("allow_vertical_edge_touch", False))
    min_component_area = int(acceptance.get("min_component_area", max(32, int(cell_w * cell_h * 0.001))))

    blockers: list[dict[str, Any]] = []
    warnings: list[dict[str, Any]] = []
    evidence: list[dict[str, Any]] = []
    frames: list[dict[str, Any]] = []

    if image.width != expected_w or image.height != expected_h:
        add_item(
            blockers,
            "harness.canvas_size.mismatch",
            f"Image is {image.width}x{image.height}, expected {expected_w}x{expected_h}.",
            as_posix(input_path),
        )

    if image.width % cols != 0 or image.height % rows != 0:
        add_item(blockers, "harness.grid.not_divisible", "Image dimensions are not divisible by the harness grid.", as_posix(input_path))
        return {"blockers": blockers, "warnings": warnings, "evidence": evidence, "frames": frames}

    actual_cell_w = image.width // cols
    actual_cell_h = image.height // rows
    if actual_cell_w != cell_w or actual_cell_h != cell_h:
        add_item(
            blockers,
            "harness.cell_size.mismatch",
            f"Actual cell size is {actual_cell_w}x{actual_cell_h}, expected {cell_w}x{cell_h}.",
            as_posix(input_path),
        )

    sheet_mask = mask_from_image(image, key_color, key_tolerance, alpha_threshold)
    widths: list[float] = []
    heights: list[float] = []
    bottoms: list[float] = []
    centers: list[float] = []

    for index in range(rows * cols):
        row = index // cols
        col = index % cols
        left = col * actual_cell_w
        top = row * actual_cell_h
        mask = sheet_mask[top:top + actual_cell_h, left:left + actual_cell_w]
        bbox = bbox_from_mask(mask)
        counts = edge_counts(mask, edge_guard)
        components = connected_components(mask, min_component_area)
        frame_meta: dict[str, Any] = {
            "index": index,
            "row": row,
            "col": col,
            "bbox": {"left": bbox.left, "top": bbox.top, "right": bbox.right, "bottom": bbox.bottom, "width": bbox.width, "height": bbox.height},
            "edge_counts": counts,
            "components": components[:4],
        }
        frames.append(frame_meta)

        if bbox.empty:
            code = "harness.frame.empty"
            message = f"Cell {index} is empty."
            if allow_empty:
                add_item(warnings, code, message)
            else:
                add_item(blockers, code, message)
            continue

        widths.append(float(bbox.width))
        heights.append(float(bbox.height))
        bottoms.append(float(bbox.bottom))
        centers.append(float((bbox.left + bbox.right) / 2))

        safe_violations: list[str] = []
        if bbox.left < int(safe["left"]):
            safe_violations.append("left")
        if bbox.top < int(safe["top"]):
            safe_violations.append("top")
        if bbox.right > int(safe["right"]):
            safe_violations.append("right")
        if bbox.bottom > int(safe["bottom"]):
            safe_violations.append("bottom")
        if safe_violations:
            add_item(
                blockers,
                "harness.safe_zone.violation",
                f"Cell {index} exits the safe zone on: {', '.join(safe_violations)}.",
                sides=safe_violations,
                frame=index,
            )

        edge_sides = [side for side, count in counts.items() if count > 0]
        disallowed_edges = [
            side for side in edge_sides
            if not ((side in ("left", "right") and allow_x_edge) or (side in ("top", "bottom") and allow_y_edge))
        ]
        if disallowed_edges:
            add_item(
                blockers,
                "harness.cell_edge.touch",
                f"Cell {index} has opaque pixels inside the {edge_guard}px edge guard: {', '.join(disallowed_edges)}.",
                sides=disallowed_edges,
                frame=index,
            )

        if len(components) > 1:
            extras = components[1:]
            near_boundary = []
            for component in extras:
                cb = component["bbox"]
                if cb["left"] <= edge_guard or cb["top"] <= edge_guard or cb["right"] >= actual_cell_w - edge_guard or cb["bottom"] >= actual_cell_h - edge_guard:
                    near_boundary.append(component)
            if near_boundary:
                add_item(
                    blockers,
                    "harness.neighbor_fragment",
                    f"Cell {index} has detached component(s) near a cell boundary, usually caused by slicing into the next frame.",
                    frame=index,
                    components=near_boundary[:3],
                )
            else:
                add_item(
                    warnings,
                    "harness.detached_components",
                    f"Cell {index} has {len(components)} separated opaque components. Review if these are intentional.",
                    frame=index,
                )

    scale_limit = float(acceptance.get("max_scale_drift_ratio", 0.16))
    width_drift = max_relative_drift(widths)
    height_drift = max_relative_drift(heights)
    if width_drift > scale_limit or height_drift > scale_limit:
        add_item(
            blockers,
            "harness.scale_drift",
            f"Frame bounding boxes drift too much: width {width_drift:.2%}, height {height_drift:.2%}, limit {scale_limit:.2%}.",
            width_drift=width_drift,
            height_drift=height_drift,
        )

    foot_line = int(spec.get("foot_line_y", 0) or 0)
    if foot_line > 0 and bottoms:
        max_foot_drift = int(acceptance.get("max_foot_drift_px", 18))
        foot_drift = max(abs(bottom - foot_line) for bottom in bottoms)
        if foot_drift > max_foot_drift:
            add_item(
                blockers,
                "harness.foot_line_drift",
                f"Frame bottoms drift {foot_drift:.1f}px from foot line y={foot_line}, limit {max_foot_drift}px.",
                foot_drift=foot_drift,
            )

    action = str(spec.get("action", "")).lower()
    view_profile = str(spec.get("view_profile", "neutral")).lower()
    if action in ("run", "walk") and view_profile != "top_down_survivor" and len(centers) >= 6:
        center_drift = max_relative_drift(centers)
        if center_drift < 0.012 and width_drift < 0.012 and height_drift < 0.012:
            add_item(
                warnings,
                "harness.low_motion_variation",
                "Run/walk frames have very similar silhouettes. Review the GIF for missing foot alternation.",
            )
    if action in ("run", "walk", "move") and view_profile == "top_down_survivor" and rows * cols >= 6:
        min_transition_diff = float(acceptance.get("min_lower_body_transition_diff", 0.13))
        max_weak_transitions = int(acceptance.get("max_weak_motion_transitions", 2))
        transition_diffs = lower_body_transition_diffs(image, spec, key_color, key_tolerance, alpha_threshold)
        weak = [index for index, value in enumerate(transition_diffs) if value < min_transition_diff]
        if len(weak) > max_weak_transitions:
            add_item(
                blockers,
                "harness.motion_phase.weak_lower_body",
                (
                    "Top-down walk/move loop has too many weak lower-body transitions. "
                    "This usually means the sheet is visually aligned but the feet/hands are not actually alternating."
                ),
                weak_transitions=weak,
                transition_diffs=[round(value, 4) for value in transition_diffs],
                min_transition_diff=min_transition_diff,
                max_weak_transitions=max_weak_transitions,
            )
        else:
            add_item(
                evidence,
                "harness.motion_phase.lower_body_ok",
                "Top-down lower-body transition variation is strong enough for a readable movement loop.",
                transition_diffs=[round(value, 4) for value in transition_diffs],
            )

    if not blockers:
        add_item(evidence, "harness.geometry.ok", "Canvas, grid, safe zones, edge guards, and drift checks passed.", as_posix(input_path))

    return {"blockers": blockers, "warnings": warnings, "evidence": evidence, "frames": frames}


def resolve_spec_relative(path_value: str, spec_path: Path) -> Path:
    candidate = Path(path_value)
    if candidate.is_absolute():
        return candidate
    return (spec_path.parent / candidate).resolve()


def resolve_manifest_relative(path_value: str, manifest_path: Path) -> Path:
    candidate = Path(path_value)
    if candidate.is_absolute():
        return candidate
    for parent in [manifest_path.parent, *manifest_path.parents]:
        resolved = (parent / candidate).resolve()
        if resolved.exists():
            return resolved
    return (manifest_path.parent / candidate).resolve()


def mask_from_regions(size: tuple[int, int], regions: list[dict[str, Any]]) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    for region in regions:
        if "ellipse" in region:
            draw.ellipse(tuple(int(v) for v in region["ellipse"]), fill=255)
        if "rect" in region:
            draw.rectangle(tuple(int(v) for v in region["rect"]), fill=255)
        if "polygon" in region:
            points = [(int(point[0]), int(point[1])) for point in region["polygon"]]
            draw.polygon(points, fill=255)
    return mask


def check_paw_blob_scan(
    image: Image.Image,
    spec: dict[str, Any],
    meta: dict[str, Any],
    manifest_path: Path,
    blockers: list[dict[str, Any]],
    evidence: list[dict[str, Any]],
) -> None:
    scan = meta.get("paw_blob_scan", {})
    if not isinstance(scan, dict) or not scan.get("enabled", False):
        return

    region = scan.get("region", [])
    colors = scan.get("colors", [])
    if not isinstance(region, list) or len(region) != 4:
        return
    if not isinstance(colors, list) or not colors:
        return

    grid = spec["grid"]
    cell_w = int(grid["cell_width"])
    cell_h = int(grid["cell_height"])
    rows = int(grid["rows"])
    cols = int(grid["cols"])
    x0, y0, x1, y1 = [int(v) for v in region]
    x0 = max(0, min(cell_w, x0))
    x1 = max(0, min(cell_w, x1))
    y0 = max(0, min(cell_h, y0))
    y1 = max(0, min(cell_h, y1))
    if x1 <= x0 or y1 <= y0:
        return

    max_components = int(scan.get("max_components", 2))
    min_area = int(scan.get("min_area", 80))
    max_area_drift = float(scan.get("max_area_drift_ratio", 0.60))
    worst_components = 0
    worst_frame = 0
    areas: list[float] = []
    sheet = image.convert("RGBA")
    scan_blocked = False

    for index in range(rows * cols):
        row = index // cols
        col = index % cols
        left = col * cell_w
        top = row * cell_h
        cell = sheet.crop((left + x0, top + y0, left + x1, top + y1))
        arr = np.array(cell.convert("RGBA"), dtype=np.int16)
        alpha_mask = arr[:, :, 3] > 8
        color_mask = np.zeros(alpha_mask.shape, dtype=bool)
        for color_spec in colors:
            if not isinstance(color_spec, dict):
                continue
            rgb = color_spec.get("rgb", [])
            if not isinstance(rgb, list) or len(rgb) != 3:
                continue
            tolerance = int(color_spec.get("tolerance", 42))
            target = np.array([int(rgb[0]), int(rgb[1]), int(rgb[2])], dtype=np.int16)
            delta = np.abs(arr[:, :, :3] - target).max(axis=2)
            color_mask |= delta <= tolerance
        paw_mask = alpha_mask & color_mask
        components = connected_components(paw_mask, min_area)
        count = len(components)
        if count > worst_components:
            worst_components = count
            worst_frame = index
        areas.append(float(sum(int(component["area"]) for component in components)))
        if count > max_components:
            scan_blocked = True
            add_item(
                blockers,
                "harness.local_repair.paw_blob_count",
                f"Frame {index} has {count} visible paw/leg color blobs in the lower-body scan region; limit {max_components}.",
                as_posix(manifest_path),
                frame=index,
                components=components[:6],
            )

    area_drift = max_relative_drift(areas)
    if area_drift > max_area_drift:
        scan_blocked = True
        add_item(
            blockers,
            "harness.local_repair.paw_blob_area_drift",
            f"Paw/leg visible area drifts {area_drift:.1%}; limit {max_area_drift:.1%}. This often indicates duplicated or disappearing feet.",
            as_posix(manifest_path),
            area_drift=area_drift,
        )
    if not scan_blocked and worst_components > 0:
        add_item(
            evidence,
            "harness.local_repair.paw_blob_scan",
            f"Lower-body paw scan passed; worst frame {worst_frame} had {worst_components} paw/leg blobs.",
            as_posix(manifest_path),
        )


def check_reference_erasure(
    image: Image.Image,
    spec: dict[str, Any],
    meta: dict[str, Any],
    manifest_path: Path,
    blockers: list[dict[str, Any]],
    evidence: list[dict[str, Any]],
) -> None:
    source_value = str(meta.get("reference_source", "") or meta.get("source", "")).strip()
    regions = meta.get("old_foot_erasure_regions", [])
    if not source_value or not isinstance(regions, list) or not regions:
        return

    source_path = resolve_manifest_relative(source_value, manifest_path)
    if not source_path.exists():
        add_item(
            blockers,
            "harness.local_repair.reference_not_found",
            f"Local repair reference source does not exist: {source_path}",
            as_posix(source_path),
        )
        return

    grid = spec["grid"]
    cell_w = int(grid["cell_width"])
    cell_h = int(grid["cell_height"])
    rows = int(grid["rows"])
    cols = int(grid["cols"])
    reference_resize = meta.get("reference_resize", [cell_w, cell_h])
    reference_paste = meta.get("reference_paste", [0, 0])
    if not isinstance(reference_resize, list) or len(reference_resize) != 2:
        return
    if not isinstance(reference_paste, list) or len(reference_paste) != 2:
        return

    reference_cell = Image.new("RGBA", (cell_w, cell_h), (0, 0, 0, 0))
    reference_image = load_rgba(source_path).resize((int(reference_resize[0]), int(reference_resize[1])), Image.Resampling.LANCZOS)
    reference_cell.alpha_composite(reference_image, (int(reference_paste[0]), int(reference_paste[1])))
    region_mask = np.array(mask_from_regions((cell_w, cell_h), regions), dtype=np.uint8) > 0
    reference_arr = np.array(reference_cell.convert("RGBA"), dtype=np.int16)
    reference_opaque = reference_arr[:, :, 3] > 8
    check_mask = region_mask & reference_opaque
    reference_count = int(np.count_nonzero(check_mask))
    if reference_count == 0:
        return

    sheet = image.convert("RGBA")
    max_match_ratio = float(meta.get("max_old_reference_match_ratio", 0.08))
    worst_ratio = 0.0
    worst_frame = 0
    for index in range(rows * cols):
        row = index // cols
        col = index % cols
        left = col * cell_w
        top = row * cell_h
        cell = sheet.crop((left, top, left + cell_w, top + cell_h))
        cell_arr = np.array(cell.convert("RGBA"), dtype=np.int16)
        color_delta = np.abs(cell_arr[:, :, :3] - reference_arr[:, :, :3]).max(axis=2)
        alpha_delta = np.abs(cell_arr[:, :, 3] - reference_arr[:, :, 3])
        unchanged = check_mask & (color_delta <= 8) & (alpha_delta <= 8)
        ratio = float(np.count_nonzero(unchanged)) / float(reference_count)
        if ratio > worst_ratio:
            worst_ratio = ratio
            worst_frame = index

    if worst_ratio > max_match_ratio:
        add_item(
            blockers,
            "harness.local_repair.old_pixels_remaining",
            f"Local repair still matches {worst_ratio:.1%} of old reference pixels in the erased limb region; limit {max_match_ratio:.1%}.",
            as_posix(manifest_path),
            frame=worst_frame,
            match_ratio=worst_ratio,
        )
    else:
        add_item(
            evidence,
            "harness.local_repair.pixel_erasure",
            f"Old reference pixels in repaired limb regions are below threshold; worst frame {worst_frame} matched {worst_ratio:.1%}.",
            as_posix(manifest_path),
        )


def validate_local_repair_manifest(
    spec: dict[str, Any],
    spec_path: Path,
    image: Image.Image,
    blockers: list[dict[str, Any]],
    warnings: list[dict[str, Any]],
    evidence: list[dict[str, Any]],
) -> None:
    """Validate semantic evidence for local limb/foot repair passes.

    The geometry harness can prove that a sheet has correct canvas, safe zone,
    foot line, and slicing behavior. It cannot infer that a repaint removed
    the old limb before drawing a replacement. This optional contract requires
    explicit repair metadata for derived animation sheets.
    """

    repair = spec.get("local_repair")
    if not isinstance(repair, dict) or not repair:
        return

    manifest_value = str(repair.get("manifest", "")).strip()
    if not manifest_value:
        add_item(blockers, "harness.local_repair.manifest_missing", "local_repair.manifest is required when local_repair is enabled.")
        return

    manifest_path = resolve_spec_relative(manifest_value, spec_path)
    if not manifest_path.exists():
        add_item(
            blockers,
            "harness.local_repair.manifest_not_found",
            f"Local repair manifest does not exist: {manifest_path}",
            as_posix(manifest_path),
        )
        return

    try:
        meta = json.loads(manifest_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        add_item(
            blockers,
            "harness.local_repair.manifest_invalid_json",
            f"Local repair manifest is not valid JSON: {exc}",
            as_posix(manifest_path),
        )
        return

    contract = meta.get("local_repair_contract", {})
    if not isinstance(contract, dict):
        add_item(
            blockers,
            "harness.local_repair.contract_missing",
            "Local repair manifest must include a local_repair_contract object.",
            as_posix(manifest_path),
        )
        return

    for key in repair.get("required_true", []):
        if contract.get(str(key)) is not True:
            add_item(
                blockers,
                "harness.local_repair.required_true_failed",
                f"Local repair contract must set {key}=true.",
                as_posix(manifest_path),
                field=str(key),
            )

    for key in repair.get("required_false", []):
        if contract.get(str(key)) is not False:
            add_item(
                blockers,
                "harness.local_repair.required_false_failed",
                f"Local repair contract must set {key}=false.",
                as_posix(manifest_path),
                field=str(key),
            )

    check_reference_erasure(image, spec, meta, manifest_path, blockers, evidence)
    check_paw_blob_scan(image, spec, meta, manifest_path, blockers, evidence)

    if not blockers:
        add_item(
            evidence,
            "harness.local_repair.evidence",
            "Local repair manifest records single-silhouette limb cleanup evidence.",
            as_posix(manifest_path),
        )


def validate_command(args: argparse.Namespace) -> dict[str, Any]:
    spec_path = Path(args.spec).resolve()
    input_path = Path(args.input).resolve()
    spec = json.loads(spec_path.read_text(encoding="utf-8"))
    if spec.get("schema") != SCHEMA:
        raise ValueError(f"Unsupported harness schema: {spec.get('schema')}")
    if args.key_color:
        spec["key_color"] = color_hex(parse_color(args.key_color))

    image = load_rgba(input_path)
    analysis = validate_cells(image, spec, input_path)
    blockers = analysis["blockers"]
    warnings = analysis["warnings"]
    evidence = analysis["evidence"]
    validate_local_repair_manifest(spec, spec_path, image, blockers, warnings, evidence)
    gate = "BLOCKED" if blockers else "PASS_WITH_WARNINGS" if warnings else "PASS"
    result = {
        "schema": SCHEMA,
        "asset_id": spec["asset_id"],
        "kind": spec["kind"],
        "action": spec.get("action", ""),
        "input": as_posix(input_path),
        "harness_spec": as_posix(spec_path),
        "gate": gate,
        "blockers": blockers,
        "warnings": warnings,
        "evidence": evidence,
        "frames": analysis["frames"],
    }

    report_path = Path(args.report).resolve() if args.report else input_path.with_suffix(".harness-report.json")
    ensure_dir(report_path.parent)
    report_path.write_text(json.dumps(result, indent=2), encoding="utf-8")
    result["report"] = as_posix(report_path)
    return result


def crop_with_padding(image: Image.Image, bbox: BBox, padding: int) -> Image.Image:
    left = max(0, bbox.left - padding)
    top = max(0, bbox.top - padding)
    right = min(image.width, bbox.right + padding)
    bottom = min(image.height, bbox.bottom + padding)
    return image.crop((left, top, right, bottom))


def crop_foreground_with_padding(
    image: Image.Image,
    bbox: BBox,
    padding: int,
    key_color: tuple[int, int, int],
    tolerance: int,
    alpha_threshold: int,
) -> Image.Image:
    crop = crop_with_padding(image, bbox, padding).convert("RGBA")
    mask = mask_from_image(crop, key_color, tolerance, alpha_threshold)
    arr = np.array(crop, dtype=np.uint8)
    arr[:, :, 3] = np.where(mask, arr[:, :, 3], 0).astype(np.uint8)
    return Image.fromarray(arr, "RGBA")


def component_bbox(item: dict[str, Any]) -> BBox:
    bbox = item["bbox"]
    return BBox(int(bbox["left"]), int(bbox["top"]), int(bbox["right"]), int(bbox["bottom"]))


def sort_components_for_grid(components: list[dict[str, Any]], rows: int, cols: int) -> list[dict[str, Any]]:
    selected = components[:rows * cols]
    selected.sort(key=lambda item: ((item["bbox"]["top"] + item["bbox"]["bottom"]) / 2, (item["bbox"]["left"] + item["bbox"]["right"]) / 2))
    ordered: list[dict[str, Any]] = []
    for row in range(rows):
        start = row * cols
        row_items = selected[start:start + cols]
        row_items.sort(key=lambda item: (item["bbox"]["left"] + item["bbox"]["right"]) / 2)
        ordered.extend(row_items)
    return ordered


def paste_crop_into_cell(
    out: Image.Image,
    crop: Image.Image,
    cell_left: int,
    cell_top: int,
    cell_w: int,
    cell_h: int,
    safe: dict[str, Any],
    anchor: str,
    fit_scale: float,
) -> dict[str, Any]:
    target_left = int(safe["left"])
    target_top = int(safe["top"])
    target_right = int(safe["right"])
    target_bottom = int(safe["bottom"])
    target_w = max(1, target_right - target_left)
    target_h = max(1, target_bottom - target_top)
    scale = min(target_w / max(1, crop.width), target_h / max(1, crop.height)) * max(0.05, fit_scale)
    new_w = max(1, min(cell_w, int(round(crop.width * scale))))
    new_h = max(1, min(cell_h, int(round(crop.height * scale))))
    resized = crop.resize((new_w, new_h), Image.Resampling.LANCZOS)

    x = cell_left + target_left + (target_w - new_w) // 2
    if anchor in ("bottom", "feet"):
        y = cell_top + target_bottom - new_h
    else:
        y = cell_top + target_top + (target_h - new_h) // 2

    x = max(cell_left, min(cell_left + cell_w - new_w, x))
    y = max(cell_top, min(cell_top + cell_h - new_h, y))
    out.alpha_composite(resized, (x, y))
    return {
        "paste": {"left": x - cell_left, "top": y - cell_top, "right": x - cell_left + new_w, "bottom": y - cell_top + new_h},
        "scale": scale,
        "output_size": {"width": new_w, "height": new_h},
    }


def cell_bbox_from_source_grid(
    image: Image.Image,
    source_rows: int,
    source_cols: int,
    index: int,
    key_color: tuple[int, int, int],
    tolerance: int,
    alpha_threshold: int,
) -> tuple[Image.Image | None, dict[str, Any]]:
    source_cell_w = image.width // source_cols
    source_cell_h = image.height // source_rows
    row = index // source_cols
    col = index % source_cols
    left = col * source_cell_w
    top = row * source_cell_h
    cell = image.crop((left, top, left + source_cell_w, top + source_cell_h))
    mask = mask_from_image(cell, key_color, tolerance, alpha_threshold)
    bbox = bbox_from_mask(mask)
    meta = {
        "source_cell": {"row": row, "col": col, "left": left, "top": top, "width": source_cell_w, "height": source_cell_h},
        "source_bbox": {"left": bbox.left, "top": bbox.top, "right": bbox.right, "bottom": bbox.bottom, "width": bbox.width, "height": bbox.height},
    }
    if bbox.empty:
        return None, meta
    return crop_foreground_with_padding(cell, bbox, 2, key_color, tolerance, alpha_threshold), meta


def rectify_command(args: argparse.Namespace) -> dict[str, Any]:
    spec_path = Path(args.spec).resolve()
    input_path = Path(args.input).resolve()
    out_path = Path(args.output).resolve()
    meta_path = Path(args.meta).resolve() if args.meta else out_path.with_suffix(".rectify-meta.json")
    spec = json.loads(spec_path.read_text(encoding="utf-8"))
    if spec.get("schema") != SCHEMA:
        raise ValueError(f"Unsupported harness schema: {spec.get('schema')}")
    if args.key_color:
        spec["key_color"] = color_hex(parse_color(args.key_color))

    grid = spec["grid"]
    rows = int(grid["rows"])
    cols = int(grid["cols"])
    cell_w = int(grid["cell_width"])
    cell_h = int(grid["cell_height"])
    frame_count = rows * cols
    canvas_w = int(spec["canvas"]["width"])
    canvas_h = int(spec["canvas"]["height"])
    acceptance = spec.get("acceptance", {})
    key_color = parse_color(str(spec.get("key_color", "#FF00FF")))
    tolerance = int(args.tolerance if args.tolerance >= 0 else acceptance.get("key_tolerance", 24))
    alpha_threshold = int(acceptance.get("alpha_threshold", 8))
    min_component_area = int(acceptance.get("min_component_area", max(32, int(cell_w * cell_h * 0.001))))
    safe = spec["safe_zone"]
    anchor = args.anchor or str(spec.get("runtime_contract", {}).get("pivot", "center"))
    if int(spec.get("foot_line_y", 0) or 0) > 0 and not args.anchor:
        anchor = "bottom"

    image = load_rgba(input_path)
    method = args.method
    if method == "auto":
        if image.width == canvas_w and image.height == canvas_h:
            method = "grid"
        elif frame_count == 1:
            method = "largest"
        else:
            sheet_mask = mask_from_image(image, key_color, tolerance, alpha_threshold)
            components = connected_components(sheet_mask, min_component_area)
            method = "components" if len(components) >= frame_count else "grid"

    out = Image.new("RGBA", (canvas_w, canvas_h), (*key_color, 255))
    frames: list[dict[str, Any]] = []

    if method == "components":
        sheet_mask = mask_from_image(image, key_color, tolerance, alpha_threshold)
        components = connected_components(sheet_mask, min_component_area)
        if len(components) < frame_count:
            raise ValueError(f"Only found {len(components)} component(s), expected at least {frame_count}.")
        ordered = sort_components_for_grid(components, rows, cols)
        for index, component in enumerate(ordered[:frame_count]):
            row = index // cols
            col = index % cols
            bbox = component_bbox(component)
            crop = crop_foreground_with_padding(image, bbox, int(args.padding), key_color, tolerance, alpha_threshold)
            paste_meta = paste_crop_into_cell(out, crop, col * cell_w, row * cell_h, cell_w, cell_h, safe, anchor, float(args.fit_scale))
            frames.append({
                "index": index,
                "method": "components",
                "source_bbox": {"left": bbox.left, "top": bbox.top, "right": bbox.right, "bottom": bbox.bottom, "width": bbox.width, "height": bbox.height},
                "area": int(component["area"]),
                **paste_meta,
            })
    elif method == "largest":
        sheet_mask = mask_from_image(image, key_color, tolerance, alpha_threshold)
        components = connected_components(sheet_mask, min_component_area)
        if not components:
            raise ValueError("No foreground component found.")
        component = components[0]
        bbox = component_bbox(component)
        crop = crop_foreground_with_padding(image, bbox, int(args.padding), key_color, tolerance, alpha_threshold)
        paste_meta = paste_crop_into_cell(out, crop, 0, 0, cell_w, cell_h, safe, anchor, float(args.fit_scale))
        frames.append({
            "index": 0,
            "method": "largest",
            "source_bbox": {"left": bbox.left, "top": bbox.top, "right": bbox.right, "bottom": bbox.bottom, "width": bbox.width, "height": bbox.height},
            "area": int(component["area"]),
            **paste_meta,
        })
    elif method == "grid":
        if image.width % cols == 0 and image.height % rows == 0:
            source_rows = rows
            source_cols = cols
        elif args.source_rows > 0 and args.source_cols > 0 and image.width % args.source_cols == 0 and image.height % args.source_rows == 0:
            source_rows = int(args.source_rows)
            source_cols = int(args.source_cols)
        else:
            source_rows = rows
            source_cols = cols
        for index in range(frame_count):
            row = index // cols
            col = index % cols
            crop, source_meta = cell_bbox_from_source_grid(image, source_rows, source_cols, index, key_color, tolerance, alpha_threshold)
            if crop is None:
                frames.append({"index": index, "method": "grid", "empty": True, **source_meta})
                continue
            paste_meta = paste_crop_into_cell(out, crop, col * cell_w, row * cell_h, cell_w, cell_h, safe, anchor, float(args.fit_scale))
            frames.append({"index": index, "method": "grid", **source_meta, **paste_meta})
    else:
        raise ValueError(f"Unsupported rectify method: {method}")

    ensure_dir(out_path.parent)
    out.save(out_path)
    result = {
        "schema": SCHEMA,
        "asset_id": spec["asset_id"],
        "kind": spec["kind"],
        "action": spec.get("action", ""),
        "method": method,
        "input": as_posix(input_path),
        "output": as_posix(out_path),
        "harness_spec": as_posix(spec_path),
        "key_color": color_hex(key_color),
        "tolerance": tolerance,
        "fit_scale": float(args.fit_scale),
        "frames": frames,
    }
    ensure_dir(meta_path.parent)
    meta_path.write_text(json.dumps(result, indent=2), encoding="utf-8")
    result["meta"] = as_posix(meta_path)
    return result


def write_result(result: dict[str, Any]) -> None:
    print(json.dumps(result, indent=2))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Codex Game Maker asset harness")
    sub = parser.add_subparsers(dest="command", required=True)

    create = sub.add_parser("create", help="create an asset harness guide, spec, and prompt contract")
    create.add_argument("--out-dir", required=True)
    create.add_argument("--asset-id", required=True)
    create.add_argument("--kind", choices=["sprite", "platform", "prop", "fx", "map-object"], default="sprite")
    create.add_argument("--action", default="")
    create.add_argument("--view-profile", choices=["neutral", "side_platformer", "top_down_survivor"], default="neutral")
    create.add_argument("--rows", type=int, default=3)
    create.add_argument("--cols", type=int, default=4)
    create.add_argument("--cell-width", type=int, default=384)
    create.add_argument("--cell-height", type=int, default=384)
    create.add_argument("--safe-margin", type=int, default=48)
    create.add_argument("--key-color", default="#FF00FF")
    create.add_argument("--foot-line", type=int, default=0)
    create.add_argument("--pivot", default="bottom")
    create.add_argument("--edge-guard", type=int, default=0)
    create.add_argument("--alpha-threshold", type=int, default=8)
    create.add_argument("--key-tolerance", type=int, default=24)
    create.add_argument("--min-component-area", type=int, default=0)
    create.add_argument("--max-scale-drift", type=float, default=0.16)
    create.add_argument("--max-foot-drift", type=int, default=18)
    create.add_argument("--allow-empty-cells", action="store_true")
    create.add_argument("--allow-horizontal-edge-touch", action="store_true")
    create.add_argument("--allow-vertical-edge-touch", action="store_true")
    create.add_argument("--loop", action="store_true")
    create.set_defaults(func=create_command)

    validate = sub.add_parser("validate", help="validate a raw sheet against a harness spec")
    validate.add_argument("--spec", required=True)
    validate.add_argument("--input", required=True)
    validate.add_argument("--report", default="")
    validate.add_argument("--key-color", default="")
    validate.set_defaults(func=validate_command)

    rectify = sub.add_parser("rectify", help="fit a raw generated image back into a harness canvas")
    rectify.add_argument("--spec", required=True)
    rectify.add_argument("--input", required=True)
    rectify.add_argument("--output", required=True)
    rectify.add_argument("--meta", default="")
    rectify.add_argument("--method", choices=["auto", "grid", "components", "largest"], default="auto")
    rectify.add_argument("--source-rows", type=int, default=0)
    rectify.add_argument("--source-cols", type=int, default=0)
    rectify.add_argument("--key-color", default="")
    rectify.add_argument("--tolerance", type=int, default=-1)
    rectify.add_argument("--fit-scale", type=float, default=1.0)
    rectify.add_argument("--padding", type=int, default=2)
    rectify.add_argument("--anchor", choices=["", "center", "bottom", "feet"], default="")
    rectify.set_defaults(func=rectify_command)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        result = args.func(args)
        write_result(result)
        if args.command == "validate" and result.get("gate") == "BLOCKED":
            return 1
        return 0
    except Exception as exc:
        print(json.dumps({"error": str(exc)}, indent=2), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
