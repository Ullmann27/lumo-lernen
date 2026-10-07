"""Objektive Prüfung der Stimmproben: Verständlichkeit (Whisper-WER), Tonhöhe, Tempo."""
import json
import re
import sys
import wave

import numpy as np
from faster_whisper import WhisperModel

sys.path.insert(0, '/home/user/tools')


NUM = {str(i): w for i, w in enumerate('null eins zwei drei vier fünf sechs sieben acht neun zehn elf zwölf dreizehn vierzehn fünfzehn sechzehn siebzehn achtzehn neunzehn zwanzig'.split())}


def words(s):
    s = s.lower().replace('ß', 'ss').replace("'", '').replace('-', '')
    s = re.sub(r'(\w)(mal)\b', r'\1 \2', s)  # „viermal“ = „vier mal“
    return [NUM.get(w, w) for w in re.findall(r'[a-zäöü0-9]+', s)]


def wer(ref, hyp):
    r, h = words(ref), words(hyp)
    d = np.zeros((len(r) + 1, len(h) + 1), dtype=int)
    d[:, 0] = range(len(r) + 1)
    d[0, :] = range(len(h) + 1)
    for i in range(1, len(r) + 1):
        for j in range(1, len(h) + 1):
            d[i, j] = min(d[i-1, j] + 1, d[i, j-1] + 1, d[i-1, j-1] + (r[i-1] != h[j-1]))
    return d[len(r), len(h)] / len(r)


def f0_stats(path):
    with wave.open(path) as w:
        sr = w.getframerate()
        x = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(float)
        if w.getnchannels() > 1:
            x = x.reshape(-1, w.getnchannels()).mean(1)
    hop, win = int(sr * 0.01), int(sr * 0.04)
    f0s = []
    for s in range(0, len(x) - win, hop):
        fr = x[s:s+win] - x[s:s+win].mean()
        if np.sqrt((fr**2).mean()) < 300:
            continue
        ac = np.correlate(fr, fr, 'full')[win-1:]
        lo, hi = int(sr / 500), int(sr / 70)
        k = lo + np.argmax(ac[lo:hi])
        if ac[k] > 0.45 * ac[0]:
            f0s.append(sr / k)
    f0s = np.array(f0s)
    return float(np.median(f0s)), float(np.percentile(f0s, 90) - np.percentile(f0s, 10))


if __name__ == '__main__':
    from lumo_voice_gen import SAMPLE_TEXTS  # noqa: E402
    REF = ' '.join(t for _, t in SAMPLE_TEXTS)
    model = WhisperModel('small', device='cpu', compute_type='int8')
    out = {}
    for path in sys.argv[1:]:
        segs, _ = model.transcribe(path, language='de', beam_size=5)
        hyp = ' '.join(s.text.strip() for s in segs)
        with wave.open(path) as w:
            dur = w.getnframes() / w.getframerate()
        med, rng = f0_stats(path)
        out[path.split('/')[-1]] = {
            'wer': round(wer(REF, hyp), 3), 'words_per_min': round(len(words(REF)) / dur * 60),
            'f0_median_hz': round(med), 'f0_range_p10_p90_hz': round(rng), 'transcript': hyp,
        }
    print(json.dumps(out, indent=1, ensure_ascii=False))
