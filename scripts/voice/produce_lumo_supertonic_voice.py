#!/usr/bin/env python3
"""Generate checked public German Lumo audio entirely on the local CPU.

Uses the official Supertonic Python inference implementation (MIT code) and
the pinned int8 conversion of Supertonic 3 (Open RAIL-M model). The misleading
MIT-only LICENSE in the conversion archive is NOT treated as the model license.
No profiles, microphone input, credentials or synthesis APIs are used.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import struct
import subprocess
import time
import wave
from pathlib import Path

import numpy as np
import onnxruntime as ort
from supertonic.core import Style, Supertonic, UnicodeProcessor

FPS = 20


def sha256(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def text_key(text: str) -> str:
    import re
    return " ".join(re.sub(r"[^a-z0-9äöüß]+", " ", text.lower()).split())


def read_styles(path: Path) -> tuple[np.ndarray, np.ndarray]:
    raw = path.read_bytes()
    if len(raw) < 48:
        raise ValueError("Truncated style header")
    shape = struct.unpack_from("<6q", raw)
    if shape != (10, 50, 256, 10, 8, 16):
        raise ValueError(f"Unverified style shapes: {shape}")
    ttl_count = int(np.prod(shape[:3]))
    dp_count = int(np.prod(shape[3:]))
    if len(raw) != 48 + 4 * (ttl_count + dp_count):
        raise ValueError("Truncated or oversized style payload")
    values = np.frombuffer(raw, dtype="<f4", offset=48)
    ttl = values[:ttl_count].reshape(shape[:3]).copy()
    dp = values[ttl_count:].reshape(shape[3:]).copy()
    if not np.all(np.isfinite(values)):
        raise ValueError("Non-finite style data")
    return ttl, dp


def match_official_style(style_path: Path, ttl: np.ndarray,
                         dp: np.ndarray) -> int:
    """Prove preset identity against an official style JSON, never guess order."""
    reference = json.loads(style_path.read_text(encoding="utf-8"))
    ref_ttl = np.array(reference["style_ttl"]["data"], dtype=np.float32)
    ref_dp = np.array(reference["style_dp"]["data"], dtype=np.float32)
    matches = [
        index for index in range(ttl.shape[0])
        if np.array_equal(ttl[index:index + 1], ref_ttl)
        and np.array_equal(dp[index:index + 1], ref_dp)
    ]
    if len(matches) != 1:
        raise ValueError(f"Cannot verify unique official preset: {matches}")
    return matches[0]


def envelope(encoded: Path) -> tuple[str, int, float, float]:
    pcm = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", str(encoded), "-f", "s16le",
         "-ac", "1", "-ar", "24000", "-"],
        check=True, capture_output=True,
    ).stdout
    samples = np.frombuffer(pcm, dtype="<i2").astype(np.float32) / 32768
    if len(samples) < 2400 or not np.all(np.isfinite(samples)):
        raise ValueError("Missing or invalid decoded speech")
    peak = float(np.max(np.abs(samples)))
    rms = float(np.sqrt(np.mean(samples * samples)))
    if peak >= .999 or rms < .005:
        raise ValueError("Clipped or effectively silent audio")
    bins = [
        float(np.sqrt(np.mean(samples[offset:offset + 1200] ** 2)))
        for offset in range(0, len(samples), 1200)
    ]
    maximum = max(bins) or 1
    env = "".join(str(min(9, round(9 * value / maximum))) for value in bins)
    return env, round(len(samples) / 24), peak, rms


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model-dir", type=Path, required=True)
    parser.add_argument("--config", type=Path, required=True)
    parser.add_argument("--official-style", type=Path, required=True)
    parser.add_argument("--input-json", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--speed", type=float, default=.98)
    parser.add_argument("--steps", type=int)
    args = parser.parse_args()
    if not .90 <= args.speed <= 1.05:
        raise ValueError("Unreviewed child narration speed")
    config = json.loads(args.config.read_text(encoding="utf-8"))
    steps = config["steps"] if args.steps is None else args.steps
    if not 4 <= steps <= 24:
        raise ValueError("Unreviewed diffusion step count")
    for name, expected in config["file_sha256"].items():
        if sha256(args.model_dir / name) != expected:
            raise ValueError(f"Unverified model component: {name}")
    cfg = json.loads((args.model_dir / "tts.json").read_text(encoding="utf-8"))
    if cfg["ae"]["sample_rate"] != config["sample_rate"]:
        raise ValueError("Sample rate differs from the actual model configuration")
    ttl, dp = read_styles(args.model_dir / "voice.bin")
    speaker = match_official_style(args.official_style, ttl, dp)
    preset = args.official_style.stem
    style = Style(ttl[speaker:speaker + 1], dp[speaker:speaker + 1])
    processor = UnicodeProcessor.__new__(UnicodeProcessor)
    processor.indexer = np.fromfile(
        args.model_dir / "unicode_indexer.bin", dtype="<i4",
    ).tolist()
    processor.supported_chars = processor._make_supported_characters()
    options = ort.SessionOptions()
    options.intra_op_num_threads = 2
    options.inter_op_num_threads = 1
    options.execution_mode = ort.ExecutionMode.ORT_SEQUENTIAL
    sessions = [
        ort.InferenceSession(
            str(args.model_dir / f"{name}.int8.onnx"),
            sess_options=options, providers=["CPUExecutionProvider"],
        )
        for name in ("duration_predictor", "text_encoder",
                     "vector_estimator", "vocoder")
    ]
    engine = Supertonic(cfg, processor, *sessions)
    entries = json.loads(args.input_json.read_text(encoding="utf-8"))
    if not isinstance(entries, list) or not entries:
        raise ValueError("Checked public text inventory missing")
    output = args.output_dir
    output.mkdir(parents=True, exist_ok=True)
    wav_dir = output / "producer-wav"
    wav_dir.mkdir(exist_ok=True)
    clips, rows = {}, []
    for index, entry in enumerate(entries, start=1):
        text = entry["text"].strip()
        spoken_text = entry.get("spoken_text", text).strip()
        producer_input = entry.get("phonetic_input", spoken_text).strip()
        if (not text or not spoken_text or not producer_input
                or len(producer_input) > 600):
            raise ValueError("Unbounded or empty public text")
        key = text_key(text)
        if key in clips:
            continue
        identity = hashlib.sha256(
            f'{config["profile"]}|{preset}|{args.speed}|{key}'.encode()
        ).hexdigest()[:16]
        clip_id = f"free_{identity}"
        raw = wav_dir / f"{clip_id}.wav"
        encoded = output / f"{clip_id}.m4a"
        np.random.seed(int(identity[:8], 16))
        started = time.monotonic()
        wav, duration = engine(
            [producer_input], style, total_step=steps,
            speed=args.speed, lang="de",
        )
        prediction = float(duration[0])
        if not np.isfinite(prediction) or not .10 <= prediction <= 45:
            raise ValueError("Invalid predicted duration")
        count = min(wav.shape[-1], int(prediction * engine.sample_rate))
        audio = wav.reshape(-1)[:count]
        if not np.all(np.isfinite(audio)) or len(audio) < 4410:
            raise ValueError("Invalid generated waveform")
        peak = float(np.max(np.abs(audio)))
        if peak < .005:
            raise ValueError("Silent waveform")
        if peak > .85:
            audio = audio * (.85 / peak)
        with wave.open(str(raw), "wb") as destination:
            destination.setnchannels(1)
            destination.setsampwidth(2)
            destination.setframerate(engine.sample_rate)
            destination.writeframes(
                (np.clip(audio, -.98, .98) * 32767).astype("<i2").tobytes(),
            )
        subprocess.run(
            ["ffmpeg", "-v", "error", "-y", "-i", str(raw),
             "-af", "loudnorm=I=-18:TP=-2:LRA=7",
             "-ar", "24000", "-ac", "1", "-c:a", "aac", "-b:a", "48k",
             "-movflags", "+faststart", str(encoded)], check=True,
        )
        env, duration_ms, decoded_peak, rms = envelope(encoded)
        clips[key] = {
            "id": clip_id, "text": text, "spoken_text": spoken_text,
            "producer_input": producer_input,
            "ms": duration_ms, "env": env, "preset": preset,
            "style": entry.get("style", "warm"),
            "asset_sha256": sha256(encoded),
            "synthesis_steps": steps,
            "synthesis_speed": args.speed,
        }
        rows.append({
            **clips[key], "key": key, "m4a_bytes": encoded.stat().st_size,
            "decoded_peak": decoded_peak, "decoded_rms": rms,
            "synthesis_seconds": round(time.monotonic() - started, 4),
            "speed": args.speed,
        })
        print(f"{index}/{len(entries)} {preset} {clip_id}: {duration_ms} ms",
              flush=True)
    model_inputs = {
        session._model_path.rsplit("/", 1)[-1]: {
            "inputs": {i.name: [i.type, i.shape] for i in session.get_inputs()},
            "outputs": {i.name: [i.type, i.shape] for i in session.get_outputs()},
        }
        for session in sessions
    }
    catalog = {
        "version": 1, "fps": FPS, "variant": config["profile"],
        "generation": "Local Supertonic 3 / ONNX CPU; zero synthesis API calls",
        "voice": f"Lumo Frei / {preset}",
        "license": "Open RAIL-M model; locally generated audio",
        "machine_generated": True, "preset": preset, "speaker_id": speaker,
        "asset_directory": "audio/voice/lumo_free",
        "clips": clips, "aliases": {},
    }
    (output / "catalog.json").write_text(
        json.dumps(catalog, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    (output / "production-manifest.json").write_text(
        json.dumps({
            "profile": config["profile"], "preset": preset,
            "speaker_id_verified_against_official_style": speaker,
            "official_style_sha256": sha256(args.official_style),
            "model_files": config["file_sha256"],
            "model_license_url": config["model_license_url"],
            "sample_rate_actual": engine.sample_rate,
            "onnxruntime": ort.__version__, "model_contract": model_inputs,
            "steps": steps, "speed": args.speed,
            "child_data_used": False, "cloud_calls": 0,
            "api_credentials_used": False,
            "physical_android_listening": "NOT TESTED",
            "clip_count": len(clips), "files": rows,
        }, ensure_ascii=False, indent=2) + "\n", encoding="utf-8",
    )


if __name__ == "__main__":
    main()
