import hashlib
import json
from pathlib import Path
import subprocess
import sys
root = Path(sys.argv[1])
avi = root / 'facial-runtime.avi'
movie = root / 'facial-runtime.mp4'
assert avi.is_file() and avi.stat().st_size > 1024, 'Missing actual MovieMaker AVI'
assert not movie.exists() and not (root / 'movie.json').exists(), 'Refusing stale movie evidence'
def run(name, args):
    with (root / name).open('wb') as log:
        result = subprocess.run(args, stdout=log, stderr=subprocess.STDOUT, timeout=90)
    assert result.returncode == 0, (name, result.returncode)
    return result.returncode
encode = run('movie-encode.log', ['ffmpeg', '-nostdin', '-y', '-i', str(avi),
    '-c:v', 'libx264', '-crf', '18', '-pix_fmt', 'yuv420p', '-c:a', 'aac',
    '-b:a', '128k', '-movflags', '+faststart', str(movie)])
decode = run('movie-decode.log', ['ffmpeg', '-nostdin', '-v', 'error', '-xerror',
    '-i', str(movie), '-f', 'null', '-'])
probe = subprocess.run(['ffprobe', '-v', 'error', '-count_frames', '-show_streams',
    '-show_format', '-of', 'json', str(movie)], stdout=subprocess.PIPE,
    stderr=subprocess.PIPE, timeout=90)
(root / 'movie-ffprobe.json').write_bytes(probe.stdout)
(root / 'movie-ffprobe-stderr.log').write_bytes(probe.stderr)
assert probe.returncode == 0, ('ffprobe', probe.returncode)
json.loads(probe.stdout)
def identity(path):
    data = path.read_bytes()
    return {'file': path.name, 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()}
(root / 'movie.json').write_text(json.dumps({
    'schema': 1, 'kind': 'actual_godot_movie', 'recording_fps': 24,
    'scope': 'Actual MovieMaker frames and original local audio; not Android/device FPS or phoneme lip sync',
    'source_avi': identity(avi), 'encoded_movie': identity(movie),
    'ffprobe': identity(root / 'movie-ffprobe.json'),
    'encode_exit_code': encode, 'decode_exit_code': decode,
    'probe_exit_code': probe.returncode}, indent=2) + '\n')