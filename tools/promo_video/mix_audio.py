#!/usr/bin/env python3
"""Mischt Musik (music.py) und – falls config.json "stimme": true – Lumos App-Stimme.

Aufruf: mix_audio.py <dauer> <ziel.m4a>
Während Lumo spricht, wird die Musik abgesenkt. Ziel-Lautheit −16 LUFS.
"""
import json
import subprocess
import sys
from pathlib import Path

here = Path(__file__).parent
repo = here.parent.parent
cfg = json.loads((here / 'config.json').read_text())
audio = json.loads((here / 'audio.json').read_text())
duration, out = float(sys.argv[1]), sys.argv[2]
music = here / 'build' / 'musik.wav'
subprocess.run([sys.executable, str(here / 'music.py'), str(music), str(duration), json.dumps(audio['musik'])], check=True)

clips = audio['stimme'] if cfg.get('stimme') else []
cmd = ['ffmpeg', '-v', 'error', '-y', '-i', str(music)]
filters, mix = [], ['[m]']
duck = []
for i, clip in enumerate(clips):
    path = repo / clip['datei']
    cmd += ['-i', str(path)]
    length = float(subprocess.check_output(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', str(path)]))
    start = clip['bei']
    duck.append(f"between(t,{start - 0.3},{start + length + 0.2})")
    filters.append(f"[{i + 1}:a]aresample=44100,pan=stereo|c0=c0|c1=c0,loudnorm=I=-15:TP=-2:LRA=7,adelay={int(start * 1000)}:all=1[v{i}]")
    mix.append(f'[v{i}]')
gain = f"volume='if({'+'.join(duck)},0.32,1)':eval=frame" if duck else 'anull'
filters.insert(0, f"[0:a]{gain}[m]")
filters.append(f"{''.join(mix)}amix=inputs={len(mix)}:normalize=0:duration=first,loudnorm=I=-16:TP=-1.5:LRA=11,aresample=48000[out]")
cmd += ['-filter_complex', ';'.join(filters), '-map', '[out]', '-c:a', 'aac', '-b:a', '192k', out]
subprocess.run(cmd, check=True)
print('Ton geschrieben:', out, '· Stimme:', 'an' if clips else 'aus')
