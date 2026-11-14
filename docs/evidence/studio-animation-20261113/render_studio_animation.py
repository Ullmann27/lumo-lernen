"""Render the saved original-Lumo Actions; never write the native source assets.

This is an offline Blender studio film, not a gameplay or Android capture.
The source .blend contains Actions only. Its saved Actions are appended to the
unchanged original GLB rig, then evaluated by Blender at the recorded times.
"""

import argparse
import hashlib
import importlib.util
import json
import math
import sys
import time
from pathlib import Path

import bpy

sys.dont_write_bytecode = True


def sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument("--native-project", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--probe", action="store_true")
    return parser.parse_args(sys.argv[sys.argv.index("--") + 1:])


def main():
    args = arguments()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    native = args.native_project.resolve()
    source = native / "assets/characters/lumo_animated/Lumo-Animated-Mobile.glb"
    library = native / "docs/evidence/studio-character-20261113/Lumo-Studio-Actions.blend"
    authoring = native / "tools/lumo_animation/author_platform_clips.py"
    input_hashes = {str(path.relative_to(native)): sha256(path) for path in (source, library, authoring)}
    assert input_hashes[str(source.relative_to(native))] == "3559f700784bc1006905ee3aae01e8bcfbffb95b4f621f7430ce771ba0e3efd5"

    spec = importlib.util.spec_from_file_location("lumo_authoring_source", authoring)
    author = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(author)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(source), merge_vertices=False)
    rigs = [obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE"]
    assert len(rigs) == 1
    rig = rigs[0]
    assert len(rig.data.bones) == 65
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH" and any(mod.type == "ARMATURE" and mod.object == rig for mod in obj.modifiers)]
    assert len(meshes) == 1
    for obj in list(bpy.context.scene.objects):
        if obj.type == "MESH" and obj not in meshes:
            bpy.data.objects.remove(obj, do_unlink=True)
    for track in list(rig.animation_data.nla_tracks):
        rig.animation_data.nla_tracks.remove(track)
    rig.animation_data.action = next(action for action in bpy.data.actions if action.name.startswith("idle_"))
    bpy.context.scene.frame_set(0)
    bpy.context.view_layer.update()
    for bone in rig.pose.bones:
        bone.rotation_mode = "QUATERNION"

    with bpy.data.libraries.load(str(library), link=False) as (data_from, data_to):
        available = sorted(data_from.actions)
        assert all(name in available for name in ("studio_walk", "studio_sprint"))
        data_to.actions = ["studio_walk", "studio_sprint"]
    actions = {action.name: action for action in data_to.actions}
    assert tuple(actions["studio_walk"].frame_range) == (0.0, 60.0)
    assert tuple(actions["studio_sprint"].frame_range) == (0.0, 36.0)

    author.setup_render()
    scene = bpy.context.scene
    scene.render.resolution_x = 512
    scene.render.resolution_y = 512
    scene.render.resolution_percentage = 100
    scene.render.fps = 25
    scene.render.fps_base = 1
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGB"
    scene.render.image_settings.color_depth = "8"
    scene.render.film_transparent = False
    scene.render.threads_mode = "FIXED"
    scene.render.threads = 8
    scene.cycles.device = "CPU"
    scene.cycles.samples = 64
    scene.cycles.use_denoising = False
    scene.cycles.use_adaptive_sampling = False
    scene.cycles.max_bounces = 4
    scene.cycles.diffuse_bounces = 2
    scene.cycles.glossy_bounces = 2
    scene.cycles.transmission_bounces = 2
    scene.cycles.transparent_max_bounces = 4
    scene.cycles.seed = 19
    scene.cycles.use_animated_seed = False
    scene.render.use_persistent_data = True
    scene.camera.data.ortho_scale = 2.35

    report = {
        "kind": "offline_original_lumo_studio_animation",
        "native_candidate": "b5bc6e7cdb03b190cb46f886301cf7bf3cb02928",
        "input_sha256": input_hashes,
        "blender": bpy.app.version_string,
        "render_engine": scene.render.engine,
        "device": scene.cycles.device,
        "resolution": [512, 512],
        "samples": scene.cycles.samples,
        "denoising": False,
        "adaptive_sampling": False,
        "max_bounces": scene.cycles.max_bounces,
        "threads": scene.render.threads,
        "color_transform": scene.view_settings.view_transform,
        "media_fps": 25,
        "source_action_timebase_fps": 60,
        "available_actions": available,
        "clips": [
            {"action": "studio_walk", "source_frame_range": [0, 60], "duration_seconds": 1.0, "rendered_frames": 25},
            {"action": "studio_sprint", "source_frame_range": [0, 36], "duration_seconds": 0.6, "rendered_frames": 15},
        ],
        "geometry_modified": False,
        "face_modified": False,
        "source_assets_written": False,
        "root_motion": "in_place_authored_actions",
        "gameplay_capture": False,
        "device_performance_measurement": False,
        "frames": [],
    }
    began = time.perf_counter()
    for action_name, count in (("studio_walk", 25), ("studio_sprint", 15)):
        rig.animation_data.action = actions[action_name]
        clip_dir = output / action_name
        clip_dir.mkdir(exist_ok=True)
        for frame_index in range(count):
            if args.probe and report["frames"]:
                break
            source_frame = frame_index * 60.0 / 25.0
            scene.frame_set(math.floor(source_frame), subframe=source_frame % 1)
            bpy.context.view_layer.update()
            destination = clip_dir / f"{frame_index:04d}.png"
            scene.render.filepath = str(destination)
            tick = time.perf_counter()
            bpy.ops.render.render(write_still=True)
            frame_record = {
                "file": str(destination.relative_to(output)),
                "action": action_name,
                "source_frame": source_frame,
                "media_time_seconds": frame_index / 25.0,
                "render_seconds": time.perf_counter() - tick,
                "sha256": sha256(destination),
                "foot_heads_world": {side: list(rig.matrix_world @ rig.pose.bones["Foot." + side].head) for side in ("L", "R")},
            }
            report["frames"].append(frame_record)
            print("STUDIO_FRAME " + json.dumps(frame_record), flush=True)
    report["render_wall_seconds"] = time.perf_counter() - began
    report["source_unchanged_after_render"] = all(sha256(native / path) == expected for path, expected in input_hashes.items())
    assert report["source_unchanged_after_render"]
    report["probe_only"] = args.probe
    report["renderer_script_sha256"] = sha256(Path(__file__))
    report_path = output / ("probe_provenance.json" if args.probe else "render_provenance.json")
    report_path.write_text(json.dumps(report, indent=2) + "\n")
    print("STUDIO_RENDER_COMPLETE " + str(report_path), flush=True)


if __name__ == "__main__":
    main()
