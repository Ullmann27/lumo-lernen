#!/usr/bin/env python3
"""Decode and transcribe real local speech assets without external audio APIs.

This is a machine intelligibility check, NOT human emotional/child acceptance.
Only checked neutral public test texts and locally generated files are accepted.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import time
from pathlib import Path

import numpy as np
from faster_whisper import WhisperModel

NUMBERS = {
    "0": "null", "1": "eins", "2": "zwei", "3": "drei", "4": "vier",
    "5": "fünf", "6": "sechs", "7": "sieben", "8": "acht",
    "9": "neun", "10": "zehn", "11": "elf", "12": "zwölf",
    "13": "dreizehn", "14": "vierzehn", "15": "fünfzehn",
    "16": "sechzehn", "17": "siebzehn", "18": "achtzehn",
    "19": "neunzehn", "20": "zwanzig",
}

VERIFIED_ASR_MODELS = {
    "d01c3014881c9c6f3133c182f3d2887eb6ca1c789a7538c5c007196857a0a6a9": (
        "Whisper Base", "https://huggingface.co/Systran/faster-whisper-base",
    ),
    "3e305921506d8872816023e4c273e75d2419fb89b24da97b4fe7bce14170d671": (
        "Whisper Small", "https://huggingface.co/Systran/faster-whisper-small",
    ),
}


def model_provenance(directory: Path) -> dict:
    """Identify the actual local decoder bytes, not a hardcoded model label."""
    files = {}
    for name in ("model.bin", "config.json", "tokenizer.json", "vocabulary.txt"):
        path = directory / name
        if not path.is_file():
            raise ValueError(f"Missing local ASR model component: {name}")
        with path.open("rb") as stream:
            files[name] = hashlib.file_digest(stream, "sha256").hexdigest()
    label, source = VERIFIED_ASR_MODELS.get(
        files["model.bin"], (directory.name, None),
    )
    return {"name": label, "source": source, "file_sha256": files}


def tokens(text: str) -> list[str]:
    words = re.findall(r"[a-zäöüß0-9]+", text.lower())
    # Brand-name spelling is not a math/content failure of a tiny ASR model.
    return [NUMBERS.get(word, "lumo" if word in ("lomo", "lumos") else word)
            for word in words]


def word_distance(expected: list[str], actual: list[str]) -> int:
    previous = list(range(len(actual) + 1))
    for i, left in enumerate(expected, 1):
        current = [i]
        for j, right in enumerate(actual, 1):
            current.append(min(current[-1] + 1, previous[j] + 1,
                               previous[j - 1] + (left != right)))
        previous = current
    return previous[-1]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--audio-dir", type=Path, required=True)
    parser.add_argument("--whisper-model", type=Path, required=True)
    parser.add_argument("--cpu-threads", type=int, choices=(1, 2), default=2)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    catalog = json.loads((args.audio_dir / "catalog.json").read_text())
    actual_model = model_provenance(args.whisper_model)
    asr = WhisperModel(
        str(args.whisper_model), device="cpu", compute_type="int8",
        cpu_threads=args.cpu_threads, num_workers=1, local_files_only=True,
    )
    rows = []
    for clip in catalog["clips"].values():
        extension = catalog.get("audio_extension", "m4a")
        if extension not in ("wav", "m4a"):
            raise ValueError("Unverified audio extension")
        path = args.audio_dir / f'{clip["id"]}.{extension}'
        started = time.monotonic()
        # Pass actual decoded PCM, not a filename. faster-whisper 1.2.1's
        # filename path uses a removed PyAV 19 metadata_errors keyword.
        decoded = subprocess.run(
            ["ffmpeg", "-v", "error", "-i", str(path), "-f", "f32le",
             "-ac", "1", "-ar", "16000", "-"],
            check=True, capture_output=True,
        ).stdout
        samples = np.frombuffer(decoded, dtype="<f4").copy()
        if len(samples) < 1600 or not np.all(np.isfinite(samples)):
            raise ValueError("Cannot verify empty or invalid decoded audio")
        rms = float(np.sqrt(np.mean(samples.astype(np.float64) ** 2)))
        peak = float(np.max(np.abs(samples)))
        if rms < .001 or peak < .005:
            raise ValueError("Cannot verify silent model output")
        media = json.loads(subprocess.run(
            ["ffprobe", "-v", "error", "-select_streams", "a:0",
             "-show_entries", "stream=sample_rate,channels,codec_name",
             "-of", "json", str(path)],
            check=True, capture_output=True, text=True,
        ).stdout)["streams"]
        if len(media) != 1 or int(media[0]["channels"]) != 1:
            raise ValueError("Expected one mono audio stream")
        segments, info = asr.transcribe(
            samples, language="de", beam_size=5, temperature=0,
            vad_filter=False, condition_on_previous_text=False,
        )
        heard = " ".join(segment.text.strip() for segment in segments)
        expected = clip.get("spoken_text", clip["text"])
        before, after = tokens(expected), tokens(heard)
        distance = word_distance(before, after)
        row = {
            "id": clip["id"], "expected": expected,
            "machine_transcription": heard, "language": info.language,
            "duration_seconds": info.duration,
            "source_sample_rate": int(media[0]["sample_rate"]),
            "source_channels": int(media[0]["channels"]),
            "source_codec": media[0]["codec_name"],
            "decoded_rms": round(rms, 6), "decoded_peak": round(peak, 6),
            "decoded_samples_at_or_above_0_99": int(
                np.count_nonzero(np.abs(samples) >= .99)),
            "word_errors": distance, "expected_words": len(before),
            "word_error_rate": round(distance / max(1, len(before)), 4),
            "asset_sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
            "transcription_seconds": round(time.monotonic() - started, 4),
            "human_listening_acceptance": "NOT TESTED",
        }
        rows.append(row)
        print(f'{clip["id"]}: {heard} (WER {row["word_error_rate"]})',
              flush=True)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(
        json.dumps({
            "method": f'local faster-whisper / {actual_model["name"]} / CTranslate2 int8',
            "cloud_audio_transfers": 0, "api_calls": 0,
            "limitations": "Machine transcript, not proof of child-friendly emotion, native playback or human listening.",
            "model_source": actual_model["source"],
            "model_provenance": actual_model,
            "profile": catalog["variant"], "voice": catalog["voice"],
            "rows": rows,
        }, ensure_ascii=False, indent=2) + "\n", encoding="utf-8",
    )


if __name__ == "__main__":
    main()
