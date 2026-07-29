#!/usr/bin/env python3
"""Cross-platform Godot and export-template installer using only Python stdlib."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import platform
import shutil
import stat
import sys
import tempfile
import urllib.request
import zipfile
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
PLUGIN_ROOT = SCRIPT_DIR.parent
POLICY_PATH = PLUGIN_ROOT / "references/policies/godot-version-policy.json"


def host_profile(version: str, status: str) -> dict:
    machine = platform.machine().lower()
    if sys.platform == "darwin":
        key, filename, executable = "macos", f"Godot_v{version}-{status}_macos.universal.zip", "Godot.app/Contents/MacOS/Godot"
    elif os.name == "nt":
        suffix = "windows_arm64.exe" if machine in {"arm64", "aarch64"} else "win64.exe"
        key, filename = "windows", f"Godot_v{version}-{status}_{suffix}.zip"
        executable = f"Godot_v{version}-{status}_{suffix}"
    elif sys.platform.startswith("linux"):
        arch = "arm64" if machine in {"arm64", "aarch64"} else "x86_64"
        key, filename = "linux", f"Godot_v{version}-{status}_linux.{arch}.zip"
        executable = f"Godot_v{version}-{status}_linux.{arch}"
    else:
        raise RuntimeError(f"Unsupported platform: {sys.platform}")
    tag = f"{version}-{status}"
    return {
        "platform": key,
        "architecture": machine,
        "filename": filename,
        "executable_relative": executable,
        "url": f"https://github.com/godotengine/godot-builds/releases/download/{tag}/{filename}",
    }


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def download(url: str, destination: Path) -> None:
    request = urllib.request.Request(url, headers={"User-Agent": "Codex-Game-Maker"})
    with urllib.request.urlopen(request) as response, destination.open("wb") as output:
        shutil.copyfileobj(response, output)


def template_root() -> Path:
    if sys.platform == "darwin":
        return Path.home() / "Library/Application Support/Godot/export_templates"
    if os.name == "nt":
        return Path(os.environ.get("APPDATA", str(Path.home() / "AppData/Roaming"))) / "Godot/export_templates"
    return Path.home() / ".local/share/godot/export_templates"


def install_templates(version: str, status: str, download_dir: Path, force: bool) -> dict:
    template_version = f"{version}.{status}"
    target = template_root() / template_version
    if (target / "web_release.zip").is_file() and not force:
        return {"status": "existing", "path": str(target)}
    filename = f"Godot_v{version}-{status}_export_templates.tpz"
    url = f"https://github.com/godotengine/godot-builds/releases/download/{version}-{status}/{filename}"
    archive = download_dir / filename
    download(url, archive)
    with tempfile.TemporaryDirectory(prefix="cgm-templates-") as temp:
        with zipfile.ZipFile(archive) as bundle:
            bundle.extractall(temp)
        source = Path(temp) / "templates"
        if not source.is_dir():
            raise RuntimeError("Export-template archive has no templates directory")
        target.mkdir(parents=True, exist_ok=True)
        for item in source.iterdir():
            destination = target / item.name
            if item.is_dir():
                shutil.copytree(item, destination, dirs_exist_ok=True)
            else:
                shutil.copy2(item, destination)
    return {"status": "installed", "path": str(target), "url": url, "sha256": sha256_file(archive)}


def write_wrapper(executable: Path, bin_dir: Path) -> Path:
    bin_dir.mkdir(parents=True, exist_ok=True)
    if os.name == "nt":
        wrapper = bin_dir / "godot.cmd"
        wrapper.write_text(f'@echo off\r\n"{executable}" %*\r\n', encoding="utf-8")
    else:
        wrapper = bin_dir / "godot"
        wrapper.write_text(f'#!/bin/sh\nexec "{executable}" "$@"\n', encoding="utf-8")
        wrapper.chmod(wrapper.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
    return wrapper


def main() -> int:
    policy = json.loads(POLICY_PATH.read_text(encoding="utf-8"))
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", default=policy["recommended_version"])
    parser.add_argument("--status", default="stable")
    parser.add_argument("--install-dir", default=str(PLUGIN_ROOT / ".tools/godot"))
    parser.add_argument("--with-export-templates", action="store_true")
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--sha256", default="", help="Optional expected SHA-256 for the editor archive")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    profile = host_profile(args.version, args.status)
    base = Path(args.install_dir).expanduser().resolve()
    install_root = base / profile["platform"]
    executable = install_root / profile["executable_relative"]
    plan = {**profile, "version": args.version, "status": args.status, "install_root": str(install_root), "executable": str(executable)}
    if args.dry_run:
        print(json.dumps(plan, indent=2))
        return 0

    download_dir = base / "downloads"
    download_dir.mkdir(parents=True, exist_ok=True)
    archive = download_dir / profile["filename"]
    if args.force and install_root.exists():
        shutil.rmtree(install_root)
    if not executable.is_file():
        install_root.mkdir(parents=True, exist_ok=True)
        download(profile["url"], archive)
        actual_hash = sha256_file(archive)
        if args.sha256 and actual_hash.lower() != args.sha256.lower():
            raise RuntimeError(f"SHA-256 mismatch: expected {args.sha256}, got {actual_hash}")
        with zipfile.ZipFile(archive) as bundle:
            bundle.extractall(install_root)
    if not executable.is_file():
        candidates = [path for path in install_root.rglob("*") if path.is_file() and (path.name == "Godot" or path.name.startswith("Godot_v"))]
        if not candidates:
            raise RuntimeError(f"Godot executable not found under {install_root}")
        executable = candidates[0]
    if os.name != "nt":
        executable.chmod(executable.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
    wrapper = write_wrapper(executable, base / "bin")
    result = {**plan, "gate": "PASS", "executable": str(executable), "wrapper": str(wrapper)}
    if archive.is_file():
        result["archive_sha256"] = sha256_file(archive)
    if args.with_export_templates:
        result["export_templates"] = install_templates(args.version, args.status, download_dir, args.force)
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(json.dumps({"gate": "BLOCKED", "error": str(exc)}, indent=2), file=sys.stderr)
        raise SystemExit(1)
