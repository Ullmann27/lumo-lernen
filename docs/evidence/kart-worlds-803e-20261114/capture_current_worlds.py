#!/usr/bin/env python3
"""Inspect existing production Kart worlds without changing product sources."""
from pathlib import Path
import hashlib, importlib.util, json, os, secrets, shutil, subprocess, tempfile, time

BASE = Path("/workspace/scratch/5987865ae883")
PROJECT = BASE / "lumo-godot"
OUT = BASE / "qa/kart-theme-source-803e-20261114"
DISPLAY = 197
TRACKS = ["zauberwald", "bergwelt", "holo_city", "crystal_canyon", "jungle_temple",
          "candy_cloud", "volcano_night", "winter_sprint", "galaxy_ringway",
          "desert_drift", "learning_lab"]
baseline = json.loads((OUT / "source-binding-production-before.json").read_text())
assert baseline["checked"] == baseline["expected"] == 1175 and not baseline["differences"]
for row in baseline["files"]:
    assert hashlib.sha256((PROJECT / row["path"]).read_bytes()).hexdigest() == row["sha256"]
spec = importlib.util.spec_from_file_location("verified_renderer", PROJECT / "tools/run_local_renderer.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
executables = {key: shutil.which(key) for key in ("Xorg", "xauth", "godot")}
assert all(executables.values())
assert not Path(f"/tmp/.X{DISPLAY}-lock").exists()
server_dir = OUT / "renderer-session"
server_dir.mkdir(exist_ok=False)
config, auth = server_dir / "xorg.conf", server_dir / "auth"
config.write_text(module.CONFIG)
auth.touch(mode=0o600)
server = None
results = []
started = time.monotonic()
try:
    subprocess.run([executables["xauth"], "-f", str(auth), "add", f"localhost:{DISPLAY}",
                    "MIT-MAGIC-COOKIE-1", secrets.token_hex(16)], check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    with (server_dir / "server-stdout.log").open("w") as server_log:
        server = subprocess.Popen([executables["Xorg"], f":{DISPLAY}", "-config", str(config),
                  "-logfile", str(server_dir / "Xorg.log"), "-nolisten", "unix",
                  "-nolisten", "local", "-listen", "tcp", "-noreset", "-auth", str(auth)],
                  stdout=server_log, stderr=subprocess.STDOUT)
        time.sleep(1.5)
        assert server.poll() is None, "Isolated display startup failed"
        for track in TRACKS:
            isolated = Path(tempfile.mkdtemp(prefix="lumo-theme-capture."))
            for name in ("userdata", "config", "cache"):
                (isolated / name).mkdir()
            (isolated / "capture.ready").write_text("lumo-track-theme-capture-v1\n" + str(isolated) + "\n")
            env = os.environ.copy()
            env.update(DISPLAY=f"localhost:{DISPLAY}", XAUTHORITY=str(auth),
                       LIBGL_ALWAYS_SOFTWARE="1", LUMO_TRACK_THEME_CAPTURE_ROOT=str(isolated),
                       XDG_DATA_HOME=str(isolated / "userdata"),
                       XDG_CONFIG_HOME=str(isolated / "config"), XDG_CACHE_HOME=str(isolated / "cache"))
            capture = OUT / "captures" / track
            log = OUT / (track + ".log")
            command = [executables["godot"], "--path", str(PROJECT), "--display-driver", "x11",
                       "--audio-driver", "Dummy", "--rendering-method", "gl_compatibility",
                       "--script", "res://scripts/tests/kart_track_theme_capture.gd", "--",
                       "--track=" + track, "--detail=full", "--out=" + str(capture), "--site=0"]
            tick = time.monotonic()
            with log.open("w") as stream:
                try:
                    completed = subprocess.run(command, env=env, stdout=stream, stderr=subprocess.STDOUT, timeout=180)
                    code = completed.returncode
                except subprocess.TimeoutExpired:
                    code = 124
            row = {"track": track, "exit_code": code, "seconds": time.monotonic()-tick,
                   "command": command, "capture_root": str(isolated), "log": log.name,
                   "frames": [], "capture_kind": "stationary production scene; no driving or device performance"}
            metadata = capture / "capture.json"
            if metadata.exists():
                data = json.loads(metadata.read_text())
                row["capture_status"] = data.get("status")
                row["original_harness_git_provenance"] = data.get("source")
                row["source_binding"] = "1175 published runtime/asset/scene/capture files exactly match Native803; older local Git HEAD and dirty stamp are preserved verbatim"
                for image in sorted(capture.glob("*.png")):
                    row["frames"].append({"path": str(image.relative_to(OUT)), "bytes": image.stat().st_size,
                                          "sha256": hashlib.sha256(image.read_bytes()).hexdigest()})
            results.append(row)
            (OUT / "runs-in-progress.json").write_text(json.dumps(results, indent=2)+"\n")
            print(json.dumps({"track": track, "exit_code": code, "capture_status": row.get("capture_status"),
                              "pngs": len(row["frames"]), "seconds": row["seconds"]}), flush=True)
            if code != 0:
                break
finally:
    if server is not None and server.poll() is None:
        server.terminate()
        try:
            server.wait(timeout=3)
        except subprocess.TimeoutExpired:
            server.kill()
            server.wait()
    auth.unlink(missing_ok=True)
    differences = []
    for row in baseline["files"]:
        path = PROJECT / row["path"]
        if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != row["sha256"]:
            differences.append(row["path"])
    report = {"source": baseline["source"], "published_tree": baseline["published_tree"],
              "runtime_files_checked": len(baseline["files"]), "source_changes": differences,
              "elapsed_seconds": time.monotonic()-started, "results": results,
              "all_11_captured": len(results)==11 and all(x["exit_code"]==0 and len(x["frames"])==3 for x in results),
              "physical_android": False, "fps_claim": False,
              "visual_review": "pending individual image inspection"}
    (OUT / "capture-runs.json").write_text(json.dumps(report, indent=2)+"\n")
    print(json.dumps({"done": True, "all_11_captured": report["all_11_captured"],
                      "source_changes": differences, "tracks": len(results)}), flush=True)
