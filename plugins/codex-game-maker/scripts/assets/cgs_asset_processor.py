#!/usr/bin/env python3
"""Codex Game Maker 2D asset processor.

This script is intentionally deterministic: it does not generate art. It only
cleans, splits, aligns, previews, and writes metadata for image-generated assets.
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import numpy as np
from PIL import Image, ImageSequence


DEFAULT_KEY_COLOR = (255, 0, 255)
NAMED_COLORS = {
    "magenta": (255, 0, 255),
    "green": (0, 255, 0),
    "blue": (0, 0, 255),
    "cyan": (0, 255, 255),
    "red": (255, 0, 0),
    "yellow": (255, 255, 0),
}

KEY_COLOR_CANDIDATES = [
    {"name": "magenta", "hex": "#FF00FF", "rgb": (255, 0, 255), "avoid": ("magenta", "pink", "purple", "violet", "fuchsia", "rose", "lavender", "magic", "arcane")},
    {"name": "green", "hex": "#00FF00", "rgb": (0, 255, 0), "avoid": ("green", "grass", "forest", "tree", "leaf", "leaves", "slime", "moss", "emerald", "nature", "toxic", "poison")},
    {"name": "cyan", "hex": "#00FFFF", "rgb": (0, 255, 255), "avoid": ("cyan", "aqua", "blue", "water", "ice", "frost", "crystal", "sky", "electric")},
    {"name": "blue", "hex": "#0000FF", "rgb": (0, 0, 255), "avoid": ("blue", "navy", "water", "ice", "frost", "sky", "night", "shadow")},
    {"name": "red", "hex": "#FF0000", "rgb": (255, 0, 0), "avoid": ("red", "orange", "fire", "flame", "lava", "blood", "heart", "scarlet", "crimson")},
    {"name": "yellow", "hex": "#FFFF00", "rgb": (255, 255, 0), "avoid": ("yellow", "gold", "golden", "sun", "lightning", "coin", "banana", "amber")},
]


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


def as_posix(path: Path) -> str:
    return path.as_posix()


def load_rgba(path: Path) -> Image.Image:
    if not path.exists():
        raise FileNotFoundError(f"Input image not found: {path}")
    return Image.open(path).convert("RGBA")


def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def parse_color(value: str) -> tuple[int, int, int]:
    clean = value.strip().lower()
    if clean == "auto":
        raise ValueError("auto must be resolved against an image before parsing")
    if clean in NAMED_COLORS:
        return NAMED_COLORS[clean]
    if clean.startswith("#"):
        clean = clean[1:]
    if len(clean) == 6:
        try:
            return tuple(int(clean[index:index + 2], 16) for index in (0, 2, 4))  # type: ignore[return-value]
        except ValueError as exc:
            raise ValueError(f"Invalid color value: {value}") from exc
    if "," in clean:
        parts = [part.strip() for part in clean.split(",")]
        if len(parts) == 3:
            try:
                rgb = tuple(int(part) for part in parts)
            except ValueError as exc:
                raise ValueError(f"Invalid color value: {value}") from exc
            if all(0 <= channel <= 255 for channel in rgb):
                return rgb  # type: ignore[return-value]
    raise ValueError(f"Invalid color value: {value}. Use #RRGGBB, R,G,B, or a named color.")


def color_hex(color: tuple[int, int, int]) -> str:
    return "#{:02X}{:02X}{:02X}".format(*color)


def detect_border_key_color(image: Image.Image, border: int | None = None) -> tuple[int, int, int]:
    rgba = np.array(image.convert("RGBA"), dtype=np.uint8)
    height, width = rgba.shape[:2]
    if width == 0 or height == 0:
        return DEFAULT_KEY_COLOR

    sample = border if border and border > 0 else max(2, min(width, height) // 64)
    sample = min(sample, max(1, width // 2), max(1, height // 2))
    strips = [
        rgba[:sample, :, :],
        rgba[-sample:, :, :],
        rgba[:, :sample, :],
        rgba[:, -sample:, :],
    ]
    pixels = np.concatenate([strip.reshape(-1, 4) for strip in strips], axis=0)
    opaque_pixels = pixels[pixels[:, 3] > 127]
    pixels = opaque_pixels if opaque_pixels.size > 0 else pixels

    rgb = pixels[:, :3].astype(np.int16)
    quantized = ((rgb + 8) // 16) * 16
    quantized = np.clip(quantized, 0, 255).astype(np.uint8)
    colors, counts = np.unique(quantized, axis=0, return_counts=True)
    dominant = colors[int(np.argmax(counts))]
    return (int(dominant[0]), int(dominant[1]), int(dominant[2]))


def resolve_key_color(image: Image.Image, requested: str) -> tuple[tuple[int, int, int], str]:
    clean = requested.strip().lower()
    if clean == "auto":
        return detect_border_key_color(image), "auto_border"
    return parse_color(requested), "explicit"


def keyword_hits(text: str, keywords: tuple[str, ...]) -> list[str]:
    clean = text.lower()
    return [keyword for keyword in keywords if keyword in clean]


def suggest_key_color(description: str) -> dict[str, Any]:
    text = description.lower()
    scored = []
    for index, candidate in enumerate(KEY_COLOR_CANDIDATES):
        hits = keyword_hits(text, candidate["avoid"])
        score = len(hits) * 10 + index
        scored.append({
            "name": candidate["name"],
            "hex": candidate["hex"],
            "score": score,
            "avoid_hits": hits,
        })

    scored.sort(key=lambda item: item["score"])
    best = scored[0]
    risky = [item for item in scored if item["avoid_hits"]]
    return {
        "key_color": best["hex"],
        "name": best["name"],
        "reason": "Chosen because the description does not appear to use this chroma-key color heavily.",
        "description": description,
        "candidates": scored,
        "risk_notes": [
            f"Avoid {item['hex']} ({item['name']}) because description mentions: {', '.join(item['avoid_hits'])}"
            for item in risky
        ],
    }


def chroma_key_color(
    image: Image.Image,
    key_color: tuple[int, int, int],
    key_color_source: str,
    tolerance: int = 24,
    softness: int = 16,
    despill: bool = True,
) -> tuple[Image.Image, dict[str, Any]]:
    arr = np.array(image.convert("RGBA"), dtype=np.float32)
    rgb = arr[:, :, :3]
    alpha = arr[:, :, 3]
    target = np.array(key_color, dtype=np.float32)
    dist = np.linalg.norm(rgb - target, axis=2)

    hard = dist <= tolerance
    soft = (dist > tolerance) & (dist < tolerance + max(1, softness))
    soft_alpha = ((dist - tolerance) / max(1, softness)) * 255.0

    alpha[hard] = 0
    alpha[soft] = np.minimum(alpha[soft], soft_alpha[soft])

    if despill:
        near = dist < (tolerance + softness + 18)
        rgb[:, :, 0][near] = np.minimum(rgb[:, :, 0][near], 245)
        rgb[:, :, 2][near] = np.minimum(rgb[:, :, 2][near], 245)

    arr[:, :, :3] = rgb
    arr[:, :, 3] = alpha
    out = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA")

    meta = {
        "background": color_hex(key_color),
        "key_color": color_hex(key_color),
        "key_color_source": key_color_source,
        "tolerance": tolerance,
        "softness": softness,
        "transparent_pixels": int(np.count_nonzero(np.array(out)[:, :, 3] == 0)),
        "semi_transparent_pixels": int(np.count_nonzero((np.array(out)[:, :, 3] > 0) & (np.array(out)[:, :, 3] < 255))),
    }
    return out, meta


def alpha_bbox(image: Image.Image, threshold: int = 4) -> BBox:
    alpha = np.array(image.convert("RGBA"))[:, :, 3]
    ys, xs = np.where(alpha > threshold)
    if len(xs) == 0 or len(ys) == 0:
        return BBox(0, 0, 0, 0)
    return BBox(int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1)


def edge_touch(image: Image.Image, threshold: int = 4, margin: int = 1) -> bool:
    alpha = np.array(image.convert("RGBA"))[:, :, 3]
    if alpha.size == 0:
        return False
    top = alpha[:margin, :]
    bottom = alpha[-margin:, :]
    left = alpha[:, :margin]
    right = alpha[:, -margin:]
    return any(np.any(edge > threshold) for edge in (top, bottom, left, right))


def count_opaque_color(
    image: Image.Image,
    color: tuple[int, int, int],
    tolerance: int = 12,
    alpha_threshold: int = 8,
) -> int:
    arr = np.array(image.convert("RGBA"), dtype=np.int16)
    rgb = arr[:, :, :3]
    alpha = arr[:, :, 3]
    target = np.array(color, dtype=np.int16)
    diff = np.abs(rgb - target).max(axis=2)
    return int(np.count_nonzero((diff <= tolerance) & (alpha > alpha_threshold)))


def split_grid(image: Image.Image, rows: int, cols: int) -> list[Image.Image]:
    if rows <= 0 or cols <= 0:
        raise ValueError("rows and cols must be positive")
    width, height = image.size
    cell_w = width // cols
    cell_h = height // rows
    if cell_w <= 0 or cell_h <= 0:
        raise ValueError(f"Grid {rows}x{cols} is too large for image {width}x{height}")

    cells: list[Image.Image] = []
    for row in range(rows):
        for col in range(cols):
            left = col * cell_w
            top = row * cell_h
            right = width if col == cols - 1 else (col + 1) * cell_w
            bottom = height if row == rows - 1 else (row + 1) * cell_h
            cells.append(image.crop((left, top, right, bottom)))
    return cells


def compute_scale(crops: list[tuple[Image.Image, BBox]], cell_size: tuple[int, int], fit_scale: float, shared: bool) -> list[float]:
    cell_w, cell_h = cell_size
    max_w = max((bbox.width for _, bbox in crops if not bbox.empty), default=1)
    max_h = max((bbox.height for _, bbox in crops if not bbox.empty), default=1)
    target_w = max(1, int(cell_w * fit_scale))
    target_h = max(1, int(cell_h * fit_scale))

    if shared:
        scale = min(1.0, target_w / max_w, target_h / max_h)
        return [scale for _ in crops]

    scales = []
    for _, bbox in crops:
        if bbox.empty:
            scales.append(1.0)
        else:
            scales.append(min(1.0, target_w / bbox.width, target_h / bbox.height))
    return scales


def paste_aligned(subject: Image.Image, canvas_size: tuple[int, int], anchor: str) -> Image.Image:
    canvas = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    cw, ch = canvas_size
    sw, sh = subject.size
    x = int((cw - sw) / 2)
    if anchor in ("bottom", "feet"):
        y = ch - sh
    else:
        y = int((ch - sh) / 2)
    canvas.alpha_composite(subject, (max(0, x), max(0, y)))
    return canvas


def normalize_frames(
    cells: list[Image.Image],
    anchor: str,
    fit_scale: float,
    shared_scale: bool,
) -> tuple[list[Image.Image], list[dict[str, Any]]]:
    if not cells:
        return [], []

    cell_w, cell_h = cells[0].size
    crops: list[tuple[Image.Image, BBox]] = []
    for cell in cells:
        bbox = alpha_bbox(cell)
        if bbox.empty:
            crops.append((Image.new("RGBA", (1, 1), (0, 0, 0, 0)), bbox))
        else:
            crops.append((cell.crop((bbox.left, bbox.top, bbox.right, bbox.bottom)), bbox))

    scales = compute_scale(crops, (cell_w, cell_h), fit_scale, shared_scale)
    frames: list[Image.Image] = []
    frame_meta: list[dict[str, Any]] = []
    for index, ((crop, bbox), scale) in enumerate(zip(crops, scales)):
        if bbox.empty:
            normalized = Image.new("RGBA", (cell_w, cell_h), (0, 0, 0, 0))
        else:
            new_size = (max(1, int(crop.width * scale)), max(1, int(crop.height * scale)))
            resized = crop.resize(new_size, Image.Resampling.LANCZOS) if new_size != crop.size else crop
            normalized = paste_aligned(resized, (cell_w, cell_h), anchor)

        frames.append(normalized)
        frame_meta.append({
            "index": index,
            "bbox": {"left": bbox.left, "top": bbox.top, "right": bbox.right, "bottom": bbox.bottom, "width": bbox.width, "height": bbox.height},
            "scale": scale,
            "edge_touch": edge_touch(cells[index]),
            "empty": bbox.empty,
        })

    return frames, frame_meta


def assemble_grid(frames: list[Image.Image], rows: int, cols: int) -> Image.Image:
    if not frames:
        raise ValueError("No frames to assemble")
    cell_w, cell_h = frames[0].size
    sheet = Image.new("RGBA", (cell_w * cols, cell_h * rows), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        row = index // cols
        col = index % cols
        sheet.alpha_composite(frame, (col * cell_w, row * cell_h))
    return sheet


def save_gif(frames: list[Image.Image], path: Path, duration_ms: int) -> None:
    if not frames:
        return
    ensure_dir(path.parent)
    gif_frames = [frame.convert("RGBA") for frame in frames]
    gif_frames[0].save(
        path,
        save_all=True,
        append_images=gif_frames[1:],
        duration=duration_ms,
        loop=0,
        disposal=2,
        transparency=0,
    )


def save_direction_strips(frames: list[Image.Image], rows: int, cols: int, out_dir: Path, names: list[str]) -> list[str]:
    if rows != len(names) or not frames:
        return []
    ensure_dir(out_dir)
    cell_w, cell_h = frames[0].size
    outputs: list[str] = []
    for row, name in enumerate(names):
        strip = Image.new("RGBA", (cell_w * cols, cell_h), (0, 0, 0, 0))
        row_frames = frames[row * cols:(row + 1) * cols]
        for col, frame in enumerate(row_frames):
            strip.alpha_composite(frame, (col * cell_w, 0))
        path = out_dir / f"{name}.png"
        strip.save(path)
        outputs.append(as_posix(path))
    return outputs


def process_sprite(args: argparse.Namespace) -> dict[str, Any]:
    input_path = Path(args.input)
    out_dir = Path(args.out_dir)
    ensure_dir(out_dir)
    frames_dir = out_dir / "frames"
    ensure_dir(frames_dir)

    raw = load_rgba(input_path)
    key_color, key_color_source = resolve_key_color(raw, args.key_color)
    clean, chroma_meta = chroma_key_color(raw, key_color, key_color_source, args.tolerance, args.softness, not args.no_despill)
    clean_path = out_dir / "raw-sheet-clean.png"
    clean.save(clean_path)

    cells = split_grid(clean, args.rows, args.cols)
    frames, frame_meta = normalize_frames(cells, args.anchor, args.fit_scale, not args.no_shared_scale)
    sheet = assemble_grid(frames, args.rows, args.cols)
    sheet_path = out_dir / "sheet-transparent.png"
    sheet.save(sheet_path)

    frame_paths = []
    for index, frame in enumerate(frames):
        frame_path = frames_dir / f"frame-{index:03d}.png"
        frame.save(frame_path)
        frame_paths.append(as_posix(frame_path))

    gif_path = out_dir / "animation.gif"
    save_gif(frames, gif_path, args.duration_ms)

    direction_outputs: list[str] = []
    if args.direction_strips or (args.rows == 4 and args.cols == 4):
        names = [name.strip() for name in args.direction_names.split(",") if name.strip()]
        if len(names) == args.rows:
            direction_outputs = save_direction_strips(frames, args.rows, args.cols, out_dir / "direction-strips", names)

    expected = args.expected_frames if args.expected_frames > 0 else args.rows * args.cols
    opaque_key = count_opaque_color(sheet, key_color)
    meta = {
        "schema": "codex-game-maker.asset-pipeline.v1",
        "asset_id": args.asset_id,
        "kind": "sprite",
        "input": as_posix(input_path),
        "output_dir": as_posix(out_dir),
        "raw_size": {"width": raw.width, "height": raw.height},
        "grid": {"rows": args.rows, "cols": args.cols, "expected_frames": expected, "actual_frames": len(frames)},
        "frame_size": {"width": frames[0].width if frames else 0, "height": frames[0].height if frames else 0},
        "anchor": args.anchor,
        "shared_scale": not args.no_shared_scale,
        "chroma_key": chroma_meta,
        "outputs": {
            "clean_sheet": as_posix(clean_path),
            "transparent_sheet": as_posix(sheet_path),
            "frames_dir": as_posix(frames_dir),
            "frames": frame_paths,
            "gif_preview": as_posix(gif_path),
            "direction_strips": direction_outputs,
        },
        "qa": {
            "has_alpha": bool(sheet.mode == "RGBA" and np.any(np.array(sheet)[:, :, 3] < 255)),
            "opaque_key_pixels": opaque_key,
            "opaque_magenta_pixels": count_opaque_color(sheet, DEFAULT_KEY_COLOR),
            "edge_touch_frames": [item["index"] for item in frame_meta if item["edge_touch"]],
            "empty_frames": [item["index"] for item in frame_meta if item["empty"]],
            "frame_count_ok": len(frames) == expected,
        },
        "frames": frame_meta,
    }

    meta_path = out_dir / "pipeline-meta.json"
    meta["outputs"]["pipeline_meta"] = as_posix(meta_path)
    meta_path.write_text(json.dumps(meta, indent=2), encoding="utf-8")
    return meta


def process_prop_pack(args: argparse.Namespace) -> dict[str, Any]:
    input_path = Path(args.input)
    out_dir = Path(args.out_dir)
    ensure_dir(out_dir)
    props_dir = out_dir / "props"
    ensure_dir(props_dir)

    raw = load_rgba(input_path)
    key_color, key_color_source = resolve_key_color(raw, args.key_color)
    clean, chroma_meta = chroma_key_color(raw, key_color, key_color_source, args.tolerance, args.softness, not args.no_despill)
    clean_path = out_dir / "prop-pack-clean.png"
    clean.save(clean_path)

    cells = split_grid(clean, args.rows, args.cols)
    props, prop_meta = normalize_frames(cells, "center", args.fit_scale, False)

    prop_paths = []
    for index, prop in enumerate(props):
        bbox = alpha_bbox(prop)
        cropped = prop if bbox.empty else prop.crop((bbox.left, bbox.top, bbox.right, bbox.bottom))
        prop_path = props_dir / f"{args.asset_id}-prop-{index:02d}.png"
        cropped.save(prop_path)
        prop_paths.append(as_posix(prop_path))

    transparent_pack = assemble_grid(props, args.rows, args.cols)
    pack_path = out_dir / "prop-pack-transparent.png"
    transparent_pack.save(pack_path)

    expected = args.expected_props if args.expected_props > 0 else args.rows * args.cols
    meta = {
        "schema": "codex-game-maker.asset-pipeline.v1",
        "asset_id": args.asset_id,
        "kind": "prop_pack",
        "input": as_posix(input_path),
        "output_dir": as_posix(out_dir),
        "raw_size": {"width": raw.width, "height": raw.height},
        "grid": {"rows": args.rows, "cols": args.cols, "expected_props": expected, "actual_props": len(props)},
        "chroma_key": chroma_meta,
        "outputs": {
            "clean_pack": as_posix(clean_path),
            "transparent_pack": as_posix(pack_path),
            "props_dir": as_posix(props_dir),
            "props": prop_paths,
        },
        "qa": {
            "has_alpha": bool(transparent_pack.mode == "RGBA" and np.any(np.array(transparent_pack)[:, :, 3] < 255)),
            "opaque_key_pixels": count_opaque_color(transparent_pack, key_color),
            "opaque_magenta_pixels": count_opaque_color(transparent_pack, DEFAULT_KEY_COLOR),
            "edge_touch_frames": [item["index"] for item in prop_meta if item["edge_touch"]],
            "empty_frames": [item["index"] for item in prop_meta if item["empty"]],
            "prop_count_ok": len(props) == expected,
        },
        "props": prop_meta,
    }

    manifest_path = out_dir / "props-manifest.json"
    meta_path = out_dir / "pipeline-meta.json"
    meta["outputs"]["props_manifest"] = as_posix(manifest_path)
    meta["outputs"]["pipeline_meta"] = as_posix(meta_path)
    manifest_path.write_text(json.dumps({"asset_id": args.asset_id, "props": prop_paths}, indent=2), encoding="utf-8")
    meta_path.write_text(json.dumps(meta, indent=2), encoding="utf-8")
    return meta


def load_placements(path: Path) -> list[dict[str, Any]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(data, list):
        return data
    if isinstance(data, dict):
        for key in ("props", "objects", "placements", "items"):
            if isinstance(data.get(key), list):
                return data[key]
    raise ValueError("Placements JSON must be a list or contain props/objects/placements/items list")


def compose_layered_preview(args: argparse.Namespace) -> dict[str, Any]:
    base_path = Path(args.base)
    placements_path = Path(args.placements)
    out_path = Path(args.out)
    ensure_dir(out_path.parent)

    base = load_rgba(base_path)
    canvas = base.copy()
    placements = load_placements(placements_path)

    resolved: list[dict[str, Any]] = []
    root = placements_path.parent
    for index, item in enumerate(sorted(placements, key=lambda value: int(value.get("layer", 0)))):
        file_value = item.get("file") or item.get("source") or item.get("path") or item.get("image")
        if not file_value:
            continue
        prop_path = Path(file_value)
        if not prop_path.is_absolute():
            prop_path = (root / prop_path).resolve()
        prop = load_rgba(prop_path)
        scale = float(item.get("scale", 1.0))
        if not math.isclose(scale, 1.0):
            prop = prop.resize((max(1, int(prop.width * scale)), max(1, int(prop.height * scale))), Image.Resampling.LANCZOS)
        x = int(item.get("x", 0))
        y = int(item.get("y", 0))
        anchor = str(item.get("anchor", "top_left"))
        if anchor == "center":
            x -= prop.width // 2
            y -= prop.height // 2
        elif anchor in ("bottom", "feet"):
            x -= prop.width // 2
            y -= prop.height
        canvas.alpha_composite(prop, (x, y))
        resolved.append({"index": index, "file": as_posix(prop_path), "x": x, "y": y, "anchor": anchor, "size": {"width": prop.width, "height": prop.height}})

    canvas.save(out_path)
    meta = {
        "schema": "codex-game-maker.asset-pipeline.v1",
        "kind": "layered_preview",
        "base": as_posix(base_path),
        "placements": as_posix(placements_path),
        "output": as_posix(out_path),
        "canvas_size": {"width": canvas.width, "height": canvas.height},
        "objects": resolved,
        "qa": {"object_count": len(resolved), "has_alpha": bool(canvas.mode == "RGBA" and np.any(np.array(canvas)[:, :, 3] < 255))},
    }
    meta_path = out_path.with_suffix(".pipeline-meta.json")
    meta["pipeline_meta"] = as_posix(meta_path)
    meta_path.write_text(json.dumps(meta, indent=2), encoding="utf-8")
    return meta


def inspect_image(args: argparse.Namespace) -> dict[str, Any]:
    path = Path(args.input)
    image = load_rgba(path)
    arr = np.array(image)
    alpha = arr[:, :, 3]
    bbox = alpha_bbox(image)
    key_color, key_color_source = resolve_key_color(image, args.key_color)
    frame_count = 0
    try:
        frame_count = sum(1 for _ in ImageSequence.Iterator(Image.open(path)))
    except Exception:
        frame_count = 1
    return {
        "path": as_posix(path),
        "mode": image.mode,
        "size": {"width": image.width, "height": image.height},
        "has_alpha": bool(np.any(alpha < 255)),
        "fully_transparent_pixels": int(np.count_nonzero(alpha == 0)),
        "key_color": color_hex(key_color),
        "key_color_source": key_color_source,
        "opaque_key_pixels": count_opaque_color(image, key_color),
        "opaque_magenta_pixels": count_opaque_color(image, DEFAULT_KEY_COLOR),
        "bbox": {"left": bbox.left, "top": bbox.top, "right": bbox.right, "bottom": bbox.bottom, "width": bbox.width, "height": bbox.height},
        "edge_touch": edge_touch(image),
        "frame_count": frame_count,
    }


def suggest_key_color_command(args: argparse.Namespace) -> dict[str, Any]:
    return suggest_key_color(args.description)


def write_result(result: dict[str, Any]) -> None:
    print(json.dumps(result, indent=2))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Codex Game Maker asset processor")
    sub = parser.add_subparsers(dest="command", required=True)

    sprite = sub.add_parser("sprite", help="process a sprite sheet")
    sprite.add_argument("--input", required=True)
    sprite.add_argument("--out-dir", required=True)
    sprite.add_argument("--asset-id", required=True)
    sprite.add_argument("--rows", type=int, required=True)
    sprite.add_argument("--cols", type=int, required=True)
    sprite.add_argument("--expected-frames", type=int, default=0)
    sprite.add_argument("--anchor", choices=["center", "bottom", "feet"], default="center")
    sprite.add_argument("--fit-scale", type=float, default=0.92)
    sprite.add_argument("--key-color", default="#FF00FF")
    sprite.add_argument("--tolerance", type=int, default=24)
    sprite.add_argument("--softness", type=int, default=16)
    sprite.add_argument("--duration-ms", type=int, default=140)
    sprite.add_argument("--no-despill", action="store_true")
    sprite.add_argument("--no-shared-scale", action="store_true")
    sprite.add_argument("--direction-strips", action="store_true")
    sprite.add_argument("--direction-names", default="down,left,right,up")
    sprite.set_defaults(func=process_sprite)

    pack = sub.add_parser("prop-pack", help="extract transparent props from a grid pack")
    pack.add_argument("--input", required=True)
    pack.add_argument("--out-dir", required=True)
    pack.add_argument("--asset-id", required=True)
    pack.add_argument("--rows", type=int, required=True)
    pack.add_argument("--cols", type=int, required=True)
    pack.add_argument("--expected-props", type=int, default=0)
    pack.add_argument("--fit-scale", type=float, default=0.94)
    pack.add_argument("--key-color", default="#FF00FF")
    pack.add_argument("--tolerance", type=int, default=24)
    pack.add_argument("--softness", type=int, default=16)
    pack.add_argument("--no-despill", action="store_true")
    pack.set_defaults(func=process_prop_pack)

    layered = sub.add_parser("layered-preview", help="compose a map preview from base plus placement JSON")
    layered.add_argument("--base", required=True)
    layered.add_argument("--placements", required=True)
    layered.add_argument("--out", required=True)
    layered.set_defaults(func=compose_layered_preview)

    inspect = sub.add_parser("inspect", help="inspect image alpha/key-color/frame metadata")
    inspect.add_argument("--input", required=True)
    inspect.add_argument("--key-color", default="#FF00FF")
    inspect.set_defaults(func=inspect_image)

    suggest = sub.add_parser("suggest-key", help="suggest a chroma-key color from an asset description")
    suggest.add_argument("--description", required=True)
    suggest.set_defaults(func=suggest_key_color_command)

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

