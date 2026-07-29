#!/usr/bin/env python3
"""Build a deterministic plugin archive, checksum, and file SBOM."""

from __future__ import annotations

import hashlib
import json
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PLUGIN = ROOT / "plugins/codex-game-maker"
DIST = ROOT / "dist"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def release_files() -> list[Path]:
    excluded_parts = {"__pycache__", ".tools", ".godot", "build", "tmp"}
    return sorted(
        path
        for path in PLUGIN.rglob("*")
        if path.is_file()
        and not excluded_parts.intersection(path.parts)
        and path.name != ".DS_Store"
        and path.suffix not in {".pyc", ".tmp"}
    )


def main() -> int:
    manifest = json.loads((PLUGIN / ".codex-plugin/plugin.json").read_text(encoding="utf-8"))
    version = manifest["version"]
    DIST.mkdir(exist_ok=True)
    for stale in (*DIST.glob("codex-game-maker-*.zip"), *DIST.glob("codex-game-maker-*.sbom.json"), DIST / "SHA256SUMS.txt"):
        stale.unlink(missing_ok=True)
    archive = DIST / f"codex-game-maker-{version}.zip"
    files = release_files()
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as bundle:
        for path in files:
            relative = Path("codex-game-maker") / path.relative_to(PLUGIN)
            info = zipfile.ZipInfo(str(relative).replace("\\", "/"), date_time=(2026, 1, 1, 0, 0, 0))
            info.external_attr = (0o755 if path.suffix in {".py", ".ps1"} else 0o644) << 16
            bundle.writestr(info, path.read_bytes(), compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)
    checksum = sha256(archive)
    (DIST / "SHA256SUMS.txt").write_text(f"{checksum}  {archive.name}\n", encoding="utf-8")
    sbom = {
        "schema": "codex-game-maker-file-sbom-v1",
        "name": "codex-game-maker",
        "version": version,
        "files": [{"path": str(path.relative_to(PLUGIN)).replace("\\", "/"), "sha256": sha256(path), "size": path.stat().st_size} for path in files],
        "python_dependencies": (PLUGIN / "requirements-asset-tools.txt").read_text(encoding="utf-8").splitlines(),
    }
    (DIST / f"codex-game-maker-{version}.sbom.json").write_text(json.dumps(sbom, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"gate": "PASS", "version": version, "archive": str(archive), "sha256": checksum, "files": len(files)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
