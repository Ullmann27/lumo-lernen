#!/usr/bin/env python3
"""Produce free German Lumo audio LOCALLY, never from a cloud TTS API.

Piper is a build-time producer, not an Android/Flutter runtime dependency.
Model/data: Thorsten Emotional, CC0; generator: Piper GPL-3.0-or-later.
Only licensed audio outputs and their provenance are bundled with the app.
No input profiles, credentials, recordings or user data are accepted.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import re
import subprocess
import wave
from pathlib import Path

import numpy as np
from piper import PiperVoice, SynthesisConfig

MODEL_SHA = "c1764e652266cd6dcebf1b95c61973df5970a5f5272e94b655ff1ddf9a99d1ff"
CONFIG_SHA = "92895b9e99f7cfc13f4a9879da615c3d6e0baa4d660e26d7b685abdd27a6d1d3"
MODEL_COMMIT = "2c11851a427461f4e6a14b5c389386ffb0b01bc7"
PROFILE = "lumo-free-emotional-de-v1"
ALLOWED_EMOTIONS = {"amused": 0, "neutral": 4}
FPS = 20


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def text_key(text: str) -> str:
    return " ".join(re.sub(r"[^a-z0-9äöüß]+", " ", text.lower()).split())


def decoded_envelope(path: Path) -> tuple[str, int, float]:
    pcm = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", str(path), "-f", "s16le",
         "-ac", "1", "-ar", "24000", "-"],
        check=True, capture_output=True,
    ).stdout
    audio = np.frombuffer(pcm, dtype="<i2").astype(np.float32) / 32768
    if len(audio) < 2400 or not np.all(np.isfinite(audio)):
        raise ValueError("Missing or invalid decoded audio")
    peak = float(np.max(np.abs(audio)))
    if peak >= 0.999 or float(np.sqrt(np.mean(audio * audio))) < 0.005:
        raise ValueError("Clipped or effectively silent output")
    bins = []
    for offset in range(0, len(audio), 24000 // FPS):
        window = audio[offset: offset + 24000 // FPS]
        bins.append(float(np.sqrt(np.mean(window * window))))
    highest = max(bins) or 1
    envelope = "".join(str(min(9, round(9 * value / highest))) for value in bins)
    return envelope, round(len(audio) / 24), peak


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", type=Path, required=True)
    parser.add_argument("--input-json", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--pitch-semitones", type=float, default=0)
    args = parser.parse_args()
    if not 0 <= args.pitch_semitones <= 2.5:
        raise ValueError("Only the audited gentle pitch range is allowed")
    config_path = Path(f"{args.model}.json")
    if sha256(args.model) != MODEL_SHA or sha256(config_path) != CONFIG_SHA:
        raise ValueError("Model/configuration is not the pinned audited source")
    entries = json.loads(args.input_json.read_text(encoding="utf-8"))
    if not isinstance(entries, list) or not entries:
        raise ValueError("Expected a non-empty checked public text inventory")
    config = json.loads(config_path.read_text(encoding="utf-8"))
    for emotion, speaker in ALLOWED_EMOTIONS.items():
        if config["speaker_id_map"].get(emotion) != speaker:
            raise ValueError("Emotion mapping changed")
    output = args.output_dir
    output.mkdir(parents=True, exist_ok=True)
    raw_dir = output / "producer-wav"
    raw_dir.mkdir(exist_ok=True)
    voice = PiperVoice.load(str(args.model), use_cuda=False)
    clips = {}
    proof = []
    for index, entry in enumerate(entries, start=1):
        text = entry["text"].strip()
        emotion = entry.get("emotion", "neutral")
        if not text or len(text) > 650 or emotion not in ALLOWED_EMOTIONS:
            raise ValueError("Only bounded public text and child-safe emotions are allowed")
        key = text_key(text)
        if key in clips:
            continue
        identity = hashlib.sha256(
            f"{PROFILE}|{emotion}|{args.pitch_semitones}|{key}".encode()
        ).hexdigest()[:16]
        clip_id = f"free_{identity}"
        raw = raw_dir / f"{clip_id}.wav"
        encoded = output / f"{clip_id}.m4a"
        length_scale = float(entry.get("length_scale", 1.0))
        if not 0.90 <= length_scale <= 1.12:
            raise ValueError("Unsafe narration speed")
        synthesis = SynthesisConfig(
            speaker_id=ALLOWED_EMOTIONS[emotion],
            length_scale=length_scale,
            noise_scale=0.55,
            noise_w_scale=0.70,
            normalize_audio=True,
            volume=0.90,
        )
        with wave.open(str(raw), "wb") as destination:
            voice.synthesize_wav(text, destination, syn_config=synthesis)
        filters = []
        if args.pitch_semitones:
            ratio = math.pow(2, args.pitch_semitones / 12)
            filters.append(f"rubberband=pitch={ratio:.8f}:formant=preserved")
        filters.append("loudnorm=I=-18:TP=-2:LRA=7")
        subprocess.run(
            ["ffmpeg", "-v", "error", "-y", "-i", str(raw),
             "-af", ",".join(filters), "-ar", "24000", "-ac", "1",
             "-c:a", "aac", "-b:a", "48k", "-movflags", "+faststart",
             str(encoded)], check=True,
        )
        envelope, duration_ms, peak = decoded_envelope(encoded)
        clips[key] = {
            "id": clip_id, "text": text, "ms": duration_ms, "env": envelope,
            "emotion": emotion, "speaker_id": ALLOWED_EMOTIONS[emotion],
            "asset_sha256": sha256(encoded),
        }
        proof.append({
            **clips[key], "key": key, "m4a_bytes": encoded.stat().st_size,
            "decoded_peak": peak, "length_scale": length_scale,
            "pitch_semitones": args.pitch_semitones,
        })
        print(f"{index}/{len(entries)} {clip_id}: {duration_ms} ms ({emotion})", flush=True)
    catalog = {
        "version": 1, "fps": FPS, "variant": PROFILE,
        "generation": "Local Piper / Thorsten Emotional; no paid API",
        "voice": "Lumo Offline: Deutsch, freundlich und emotional",
        "license": "CC0-1.0 source voice dataset; locally produced audio",
        "model_sha256": MODEL_SHA, "config_sha256": CONFIG_SHA,
        "model_commit": MODEL_COMMIT,
        "asset_directory": "audio/voice/lumo_free",
        "clips": clips, "aliases": {},
    }
    (output / "catalog.json").write_text(
        json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8",
    )
    manifest = {
        "profile": PROFILE, "model_sha256": MODEL_SHA,
        "model_commit": MODEL_COMMIT, "producer": "piper-tts 1.8.0",
        "producer_is_not_bundled_with_android": True,
        "child_data_used": False, "cloud_calls": 0, "api_credentials_used": False,
        "model_card_url": "https://huggingface.co/rhasspy/piper-voices/blob/main/de/de_DE/thorsten_emotional/medium/MODEL_CARD",
        "author_permission_url": "https://www.thorsten-voice.de/kostenloses-deutsches-text-to-speech-mit-thorsten-voice/",
        "source_model_url": f"https://huggingface.co/Thorsten-Voice/Piper/resolve/{MODEL_COMMIT}/de_DE-thorsten_emotional-medium.onnx",
        "clip_count": len(clips), "files": proof,
    }
    (output / "production-manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8",
    )


if __name__ == "__main__":
    main()
