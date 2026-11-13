"""Encode only the actual Cycles PNG frames, with explicit loop repetition."""

import hashlib
import json
import subprocess
from pathlib import Path


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    output = Path(__file__).resolve().parent
    render = json.loads((output / "render_provenance.json").read_text())
    assert not render["probe_only"]
    assert len(render["frames"]) == 40
    for frame in render["frames"]:
        assert sha256(output / frame["file"]) == frame["sha256"]

    sequence = []
    for action, count, repeats in (("studio_walk", 25, 2), ("studio_sprint", 15, 3)):
        for repeat in range(repeats):
            for frame in range(count):
                sequence.append({
                    "encoded_frame": len(sequence),
                    "source_png": f"{action}/{frame:04d}.png",
                    "loop_repetition": repeat + 1,
                })
    assert len(sequence) == 95
    timeline = output / "studio-timeline.ffconcat"
    lines = ["ffconcat version 1.0"]
    for frame in sequence:
        lines.extend([f"file '{frame['source_png']}'", "duration 0.04"])
    lines.append(f"file '{sequence[-1]['source_png']}'")
    timeline.write_text("\n".join(lines) + "\n")
    video = output / "Lumo-Original-Studio-Walk-Sprint.mp4"
    command = [
        "ffmpeg", "-hide_banner", "-y", "-f", "concat", "-safe", "0",
        "-i", str(timeline), "-an", "-r", "25", "-fps_mode", "cfr",
        "-frames:v", "95", "-c:v", "libx264", "-preset", "medium",
        "-crf", "17", "-pix_fmt", "yuv420p", "-movflags", "+faststart",
        "-metadata", "title=Lumo Original: authored walk and sprint Actions",
        "-metadata", "comment=Offline Blender Cycles CPU studio render; 40 genuine rendered PNGs, explicit repeated loops; not gameplay or device FPS evidence.",
        str(video),
    ]
    with (output / "ffmpeg-encode.log").open("w") as log:
        subprocess.run(command, check=True, stdout=log, stderr=subprocess.STDOUT, timeout=90)
    probe = subprocess.run([
        "ffprobe", "-v", "error", "-count_frames", "-select_streams", "v:0",
        "-show_entries", "stream=codec_name,width,height,pix_fmt,avg_frame_rate,nb_read_frames,duration:format=duration,size",
        "-of", "json", str(video),
    ], check=True, capture_output=True, text=True, timeout=30)
    metadata = json.loads(probe.stdout)
    stream = metadata["streams"][0]
    assert stream["width"] == 512 and stream["height"] == 512
    assert stream["avg_frame_rate"] == "25/1"
    assert int(stream["nb_read_frames"]) == 95
    assert abs(float(metadata["format"]["duration"]) - 3.8) < 0.01
    decoded = subprocess.run([
        "ffmpeg", "-v", "error", "-i", str(video), "-f", "null", "-",
    ], check=True, capture_output=True, text=True, timeout=30)
    assert not decoded.stderr.strip()
    ffmpeg = subprocess.run(["ffmpeg", "-version"], check=True, capture_output=True, text=True).stdout.splitlines()[0]
    report = {
        "kind": "offline_original_lumo_studio_video_provenance",
        "file": video.name,
        "sha256": sha256(video),
        "bytes": video.stat().st_size,
        "ffmpeg_version": ffmpeg,
        "encoding_command": command,
        "metadata": metadata,
        "render_provenance_file": "render_provenance.json",
        "render_provenance_sha256": sha256(output / "render_provenance.json"),
        "input_sha256": render["input_sha256"],
        "actual_cycles_rendered_frames": 40,
        "encoded_frames": 95,
        "duration_seconds": 3.8,
        "media_fps": 25,
        "loop_segments": [
            {"action": "studio_walk", "start_seconds": 0, "end_seconds": 2, "loops": 2, "unique_rendered_frames": 25},
            {"action": "studio_sprint", "start_seconds": 2, "end_seconds": 3.8, "loops": 3, "unique_rendered_frames": 15},
        ],
        "transition": "hard cut between two independent authored action loops",
        "frame_interpolation_or_morphing": False,
        "image_generation_used": False,
        "full_video_decode_errors": [],
        "source_assets_unchanged": render["source_unchanged_after_render"],
        "gameplay_capture": False,
        "physical_android_measurement": False,
        "no_60_fps_claim": True,
        "frame_mapping": sequence,
        "encoder_script_sha256": sha256(Path(__file__)),
    }
    (output / "video_provenance.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({"file": str(video), "sha256": report["sha256"], "bytes": report["bytes"], "duration_seconds": 3.8, "encoded_frames": 95}))


if __name__ == "__main__":
    main()
