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
from typing import Any


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


def sha512_file(path: Path) -> str:
    digest = hashlib.sha512()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def default_install_dir() -> Path:
    override = os.environ.get("CODEX_GAME_MAKER_CACHE")
    if override:
        return Path(override).expanduser() / "godot"
    if sys.platform == "darwin":
        return Path.home() / "Library/Caches/CodexGameMaker/godot"
    if os.name == "nt":
        return Path(os.environ.get("LOCALAPPDATA", str(Path.home() / "AppData/Local"))) / "CodexGameMaker/godot"
    return Path(os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache"))) / "codex-game-maker/godot"


def verified_checksum(policy: dict, version: str, status: str, filename: str, override: str = "") -> str:
    if override:
        if not all(char in "0123456789abcdefABCDEF" for char in override) or len(override) != 128:
            raise RuntimeError("--sha512 must be exactly 128 hexadecimal characters")
        return override.lower()
    release = policy.get("verified_archives", {}).get(f"{version}-{status}", {})
    checksum = str(release.get("files", {}).get(filename, "")).lower()
    if len(checksum) != 128:
        raise RuntimeError(f"No trusted SHA-512 is pinned for {filename}; pass an independently verified --sha512")
    return checksum


def verify_archive(path: Path, expected: str) -> str:
    actual = sha512_file(path)
    if actual != expected:
        path.unlink(missing_ok=True)
        raise RuntimeError(f"SHA-512 mismatch for {path.name}: expected {expected}, got {actual}")
    return actual


def safe_extract(bundle: zipfile.ZipFile, destination: Path) -> None:
    root = destination.resolve()
    for member in bundle.infolist():
        target = (destination / member.filename).resolve()
        try:
            target.relative_to(root)
        except ValueError as exc:
            raise RuntimeError(f"Unsafe archive member: {member.filename}") from exc
    bundle.extractall(destination)


def read_json(path: Path) -> dict[str, Any] | None:
    if not path.is_file():
        return None
    try:
        value = json.loads(path.read_text(encoding="utf-8-sig"))
    except (OSError, json.JSONDecodeError):
        return None
    return value if isinstance(value, dict) else None


def existing_install_error(
    manifest: dict[str, Any] | None,
    *,
    version: str,
    status: str,
    profile: dict[str, str],
    expected_sha512: str,
    executable: Path,
) -> str:
    if manifest is None:
        return "trusted install manifest is missing"
    expected = {
        "version": version,
        "status": status,
        "platform": profile["platform"],
        "filename": profile["filename"],
        "expected_sha512": expected_sha512,
        "executable": str(executable),
    }
    for field, value in expected.items():
        if manifest.get(field) != value:
            return f"install manifest {field} does not match the requested release"
    recorded_executable_hash = str(manifest.get("executable_sha256", ""))
    if len(recorded_executable_hash) != 64 or sha256_file(executable) != recorded_executable_hash:
        return "installed executable hash does not match the trusted install manifest"
    return ""


def download(url: str, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    request = urllib.request.Request(url, headers={"User-Agent": "Codex-Game-Maker"})
    temporary: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            prefix=f".{destination.name}.", suffix=".part", dir=destination.parent, delete=False
        ) as output:
            temporary = Path(output.name)
            with urllib.request.urlopen(request) as response:
                shutil.copyfileobj(response, output)
        os.replace(temporary, destination)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def template_root() -> Path:
    if sys.platform == "darwin":
        return Path.home() / "Library/Application Support/Godot/export_templates"
    if os.name == "nt":
        return Path(os.environ.get("APPDATA", str(Path.home() / "AppData/Roaming"))) / "Godot/export_templates"
    return Path.home() / ".local/share/godot/export_templates"


def install_templates(
    version: str,
    status: str,
    download_dir: Path,
    force: bool,
    policy: dict,
    sha512_override: str = "",
    keep_downloads: bool = False,
) -> dict:
    template_version = f"{version}.{status}"
    target = template_root() / template_version
    filename = f"Godot_v{version}-{status}_export_templates.tpz"
    url = f"https://github.com/godotengine/godot-builds/releases/download/{version}-{status}/{filename}"
    checksum = verified_checksum(policy, version, status, filename, sha512_override)
    marker_path = target / ".codex-game-maker-install.json"
    web_template = target / "web_release.zip"
    if web_template.is_file() and not force:
        marker = read_json(marker_path)
        valid_marker = (
            marker is not None
            and marker.get("version") == version
            and marker.get("status") == status
            and marker.get("archive_filename") == filename
            and marker.get("archive_sha512") == checksum
            and marker.get("web_release_sha256") == sha256_file(web_template)
        )
        if not valid_marker:
            raise RuntimeError(
                f"Existing export templates at {target} have no valid trusted marker; rerun with --force"
            )
        return {
            "status": "existing",
            "path": str(target),
            "archive_sha512": checksum,
            "install_manifest": str(marker_path),
        }
    if target.exists() and not force:
        raise RuntimeError(
            f"Existing export-template directory at {target} is incomplete or untrusted; rerun with --force"
        )
    archive = download_dir / filename
    download(url, archive)
    actual_checksum = verify_archive(archive, checksum)
    actual_sha256 = sha256_file(archive)
    target.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="cgm-templates-", dir=target.parent) as temp:
        with zipfile.ZipFile(archive) as bundle:
            unpacked = Path(temp) / "unpacked"
            unpacked.mkdir()
            safe_extract(bundle, unpacked)
        source = unpacked / "templates"
        if not source.is_dir():
            raise RuntimeError("Export-template archive has no templates directory")
        if not keep_downloads:
            archive.unlink(missing_ok=True)
        if target.exists():
            shutil.rmtree(target)
        shutil.move(str(source), str(target))
    if not web_template.is_file():
        raise RuntimeError("Installed export templates have no web_release.zip")
    marker = {
        "schema_version": 1,
        "version": version,
        "status": status,
        "archive_filename": filename,
        "archive_sha512": actual_checksum,
        "web_release_sha256": sha256_file(web_template),
    }
    marker_path.write_text(json.dumps(marker, indent=2) + "\n", encoding="utf-8")
    result = {
        "status": "installed",
        "path": str(target),
        "url": url,
        "sha256": actual_sha256,
        "sha512": actual_checksum,
        "install_manifest": str(marker_path),
    }
    result["archive_cached"] = keep_downloads
    return result


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
    parser.add_argument("--install-dir", default=str(default_install_dir()))
    parser.add_argument("--with-export-templates", action="store_true")
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--sha512", default="", help="Trusted SHA-512 override for a release not pinned in policy")
    parser.add_argument("--keep-downloads", action="store_true", help="Keep verified editor/template archives after installation")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    profile = host_profile(args.version, args.status)
    base = Path(args.install_dir).expanduser().resolve()
    install_root = base / profile["platform"]
    executable = install_root / profile["executable_relative"]
    expected_checksum = verified_checksum(policy, args.version, args.status, profile["filename"], args.sha512)
    plan = {**profile, "version": args.version, "status": args.status, "install_root": str(install_root), "executable": str(executable), "expected_sha512": expected_checksum}
    if args.dry_run:
        print(json.dumps(plan, indent=2))
        return 0

    download_dir = base / "downloads"
    download_dir.mkdir(parents=True, exist_ok=True)
    archive = download_dir / profile["filename"]
    manifest = base / "install-manifest.json"
    if executable.is_file() and not args.force:
        problem = existing_install_error(
            read_json(manifest),
            version=args.version,
            status=args.status,
            profile=profile,
            expected_sha512=expected_checksum,
            executable=executable,
        )
        if problem:
            raise RuntimeError(f"Existing Godot install is not trusted: {problem}; rerun with --force")
    if args.force or not executable.is_file():
        download(profile["url"], archive)
        verify_archive(archive, expected_checksum)
        with tempfile.TemporaryDirectory(prefix="cgm-godot-", dir=base) as temp:
            staging = Path(temp) / "install"
            staging.mkdir()
            with zipfile.ZipFile(archive) as bundle:
                safe_extract(bundle, staging)
            staged_executable = staging / profile["executable_relative"]
            if not staged_executable.is_file():
                candidates = [
                    path
                    for path in staging.rglob("*")
                    if path.is_file() and (path.name == "Godot" or path.name.startswith("Godot_v"))
                ]
                if not candidates:
                    raise RuntimeError(f"Godot executable not found in verified archive {archive.name}")
                staged_executable = candidates[0]
            relative_executable = staged_executable.relative_to(staging)
            if install_root.exists():
                shutil.rmtree(install_root)
            shutil.move(str(staging), str(install_root))
            executable = install_root / relative_executable
    if not executable.is_file():
        candidates = [path for path in install_root.rglob("*") if path.is_file() and (path.name == "Godot" or path.name.startswith("Godot_v"))]
        if not candidates:
            raise RuntimeError(f"Godot executable not found under {install_root}")
        executable = candidates[0]
    if os.name != "nt":
        executable.chmod(executable.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
    wrapper = write_wrapper(executable, base / "bin")
    result = {
        **plan,
        "gate": "PASS",
        "executable": str(executable),
        "executable_sha256": sha256_file(executable),
        "wrapper": str(wrapper),
        "install_manifest": str(manifest),
    }
    if archive.is_file():
        result["archive_sha256"] = sha256_file(archive)
        result["archive_sha512"] = sha512_file(archive)
        if not args.keep_downloads:
            archive.unlink()
            result["archive_cached"] = False
        else:
            result["archive_cached"] = True
    if args.with_export_templates:
        result["export_templates"] = install_templates(
            args.version,
            args.status,
            download_dir,
            args.force,
            policy,
            keep_downloads=args.keep_downloads,
        )
    manifest.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(json.dumps({"gate": "BLOCKED", "error": str(exc)}, indent=2), file=sys.stderr)
        raise SystemExit(1)
