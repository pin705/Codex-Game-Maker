import json
import hashlib
import math
import struct
import subprocess
import sys
import tempfile
import unittest
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "plugins/codex-game-maker/scripts/audio_qa.py"


def write_wav(path: Path, amplitude: int = 6000, duration: float = 0.2, sample_width: int = 2) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    rate = 22050
    frames = bytearray()
    for index in range(int(rate * duration)):
        value = int(amplitude * math.sin(2 * math.pi * 440 * index / rate))
        if sample_width == 3:
            frames.extend(value.to_bytes(3, byteorder="little", signed=True))
        else:
            frames.extend(struct.pack("<h", value))
    with wave.open(str(path), "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(sample_width)
        handle.setframerate(rate)
        handle.writeframes(bytes(frames))


class AudioQaTests(unittest.TestCase):
    def manifest(self, root: Path, asset: str) -> None:
        path = root / "design/audio/audio-manifest.json"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps({
            "intentional_silence": False,
            "qa_policy": {"minimum_duration_seconds": 0.05, "minimum_sample_rate": 22050, "minimum_rms_dbfs": -36, "maximum_rms_dbfs": -6, "maximum_peak_dbfs": -0.1, "maximum_loop_seam_normalized": 0.2},
            "events": [{"id": "hit", "status": "verified", "asset": asset, "loop": False}],
        }), encoding="utf-8")

    def test_valid_wav_passes(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            write_wav(root / "assets/audio/hit.wav")
            self.manifest(root, "assets/audio/hit.wav")
            result = subprocess.run([sys.executable, str(SCRIPT), "--root", str(root)], capture_output=True, text=True)
            report = json.loads(result.stdout)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(len(report["manifest_sha256"]), 64)

    def test_clipped_wav_is_blocked(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            write_wav(root / "assets/audio/hit.wav", amplitude=32767)
            self.manifest(root, "assets/audio/hit.wav")
            result = subprocess.run([sys.executable, str(SCRIPT), "--root", str(root)], capture_output=True, text=True)
            report = json.loads(result.stdout)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(report["gate"], "BLOCKED")

    def test_valid_24_bit_wav_passes(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            write_wav(root / "assets/audio/hit.wav", amplitude=1_500_000, sample_width=3)
            self.manifest(root, "assets/audio/hit.wav")
            result = subprocess.run([sys.executable, str(SCRIPT), "--root", str(root)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_audio_asset_outside_project_is_blocked(self) -> None:
        with tempfile.TemporaryDirectory() as temp, tempfile.TemporaryDirectory() as outside:
            root = Path(temp)
            asset = Path(outside) / "hit.wav"
            write_wav(asset)
            self.manifest(root, str(asset))
            result = subprocess.run([sys.executable, str(SCRIPT), "--root", str(root)], capture_output=True, text=True)
            report = json.loads(result.stdout)
        self.assertEqual(result.returncode, 1)
        self.assertTrue(any(row["error"] == "asset missing" for row in report["blockers"]))

    def test_compressed_metrics_without_quality_binding_are_blocked(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            asset = root / "assets/audio/hit.ogg"
            asset.parent.mkdir(parents=True)
            asset.write_bytes(b"OggS" + b"fixture" * 64)
            self.manifest(root, "assets/audio/hit.ogg")
            manifest_path = root / "design/audio/audio-manifest.json"
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            manifest["events"][0]["qa_metrics"] = {
                "duration_seconds": 1,
                "sample_rate": 44100,
                "peak_dbfs": -1,
                "rms_dbfs": -12,
                "measured_by": "fixture",
                "asset_sha256": hashlib.sha256(asset.read_bytes()).hexdigest(),
                "command_id": "audio-probe",
                "command_sha256": "a" * 64,
                "stdout_sha256": "b" * 64,
            }
            manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
            result = subprocess.run([sys.executable, str(SCRIPT), "--root", str(root)], capture_output=True, text=True)
            report = json.loads(result.stdout)
        self.assertEqual(result.returncode, 1)
        self.assertTrue(any("quality command" in row["error"] for row in report["blockers"]))


if __name__ == "__main__":
    unittest.main()
