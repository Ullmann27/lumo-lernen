"""Erzeugt Lumo-Sprachclips mit Piper (offline, CC0-Stimmen) und Cartoon-Nachbearbeitung.

Aufruf:  python lumo_voice_gen.py samples <outdir>
         python lumo_voice_gen.py clips <phrases.json> <outdir> <variant>
"""
import json
import os
import subprocess
import sys
import wave

import imageio_ffmpeg
from piper import PiperVoice, SynthesisConfig

VOICES = '/home/user/tools/voices'
FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()

# Gleiche deutsche Beispieltexte für alle drei Varianten.
SAMPLE_TEXTS = [
    ('greeting', 'Hallo! Schön, dass du da bist. Ich bin Lumo, dein Lernfuchs. Heute entdecken wir zusammen etwas Neues!'),
    ('explain', 'Schau mal: Acht plus fünf. Zuerst machen wir die Zehn voll. Acht plus zwei ist zehn. Dann fehlen noch drei. Zehn plus drei ist dreizehn.'),
    ('comfort', 'Hoppla, das war knapp! Fehler sind ganz normal. Beim Üben lernt dein Kopf am meisten. Wir probieren es gemeinsam noch einmal. Du schaffst das!'),
]

# Jede Variante: Modell + Sprecher je Stil, Tempo, Ausdruck, Nachbearbeitung.
# shift_st: Gesamtanhebung der Tonhöhe in Halbtönen.
# formant_st: Anteil davon, der auch die Formanten verschiebt (kleinerer, jüngerer Vokaltrakt).
VARIANTS = {
    'a_hell': {
        'title': 'A – Heller Fuchs (Kerstin, weiblich, klar)',
        'model': 'de_DE-kerstin-low',
        'speaker': {},
        'length': {'greeting': 0.95, 'explain': 1.15, 'comfort': 1.08},
        'noise': 0.72, 'noise_w': 0.85,
        'shift_st': 2.5, 'formant_st': 1.5,
    },
    'b_verspielt': {
        'title': 'B – Verspielter Cartoon-Fuchs (Thorsten: fröhlich bei Begrüßung/Lob, klar beim Erklären)',
        'model': 'de_DE-thorsten-high',
        # Gleicher Sprecher: emotionales Modell (amused/surprised) für Freude, high-Modell für Klarheit.
        'style_model': {'greeting': ('de_DE-thorsten_emotional-medium', 0),
                        'celebrate': ('de_DE-thorsten_emotional-medium', 6),
                        'question': ('de_DE-thorsten_emotional-medium', 0)},
        'speaker': {},
        'length': {'greeting': 0.95, 'explain': 1.2, 'comfort': 1.12},
        'noise': 0.66, 'noise_w': 0.9,
        'shift_st': 5.0, 'formant_st': 2.5,
    },
    'c_erzaehler': {
        'title': 'C – Ruhiger Erzähler-Fuchs (Thorsten high, warm)',
        'model': 'de_DE-thorsten-high',
        'speaker': {},
        'length': {'greeting': 0.98, 'explain': 1.18, 'comfort': 1.1},
        'noise': 0.6, 'noise_w': 0.8,
        'shift_st': 3.5, 'formant_st': 2.0,
    },
}

_loaded = {}


def voice(model):
    if model not in _loaded:
        _loaded[model] = PiperVoice.load(os.path.join(VOICES, model + '.onnx'))
    return _loaded[model]


def synth(variant, style, text, out_wav):
    v = VARIANTS[variant]
    model, speaker = v.get('style_model', {}).get(style, (v['model'], None))
    cfg = SynthesisConfig(
        speaker_id=speaker,
        length_scale=v['length'].get(style, 1.0),
        noise_scale=v['noise'],
        noise_w_scale=v['noise_w'],
    )
    raw = out_wav + '.raw.wav'
    with wave.open(raw, 'wb') as w:
        voice(model).synthesize_wav(text, w, syn_config=cfg)
    sr = voice(model).config.sample_rate
    formant = 2 ** (v['formant_st'] / 12)
    rest = 2 ** ((v['shift_st'] - v['formant_st']) / 12)
    # 1) asetrate verschiebt Tonhöhe+Formanten, atempo gleicht das Tempo aus,
    # 2) rubberband hebt die restliche Tonhöhe formanterhaltend an,
    # 3) EQ: etwas Präsenz/Glanz, weniger Brummen, sanfte Kompression, Lautheit -16 LUFS.
    af = (
        f'asetrate={sr}*{formant:.5f},aresample={sr},atempo={1/formant:.5f},'
        f'rubberband=pitch={rest:.5f}:formant=preserved:pitchq=quality,'
        'highpass=f=110,equalizer=f=3200:t=q:w=1.2:g=3,equalizer=f=250:t=q:w=1:g=-2,'
        'acompressor=threshold=-20dB:ratio=2.5:attack=8:release=120,'
        'loudnorm=I=-16:TP=-1.5:LRA=9,aresample=44100'
    )
    subprocess.run([FFMPEG, '-y', '-loglevel', 'error', '-i', raw, '-af', af, out_wav], check=True)
    os.remove(raw)


_asr = None


def intelligibility(path, text):
    """Wortfehlerrate der Whisper-Transkription gegen den Solltext (0 = perfekt)."""
    global _asr
    from voice_eval import wer
    if _asr is None:
        from faster_whisper import WhisperModel
        _asr = WhisperModel('small', device='cpu', compute_type='int8')
    segs, _ = _asr.transcribe(path, language='de', beam_size=5)
    return wer(text, ' '.join(s.text for s in segs))


def synth_best(variant, style, text, out_wav, takes=4):
    """Erzeugt mehrere Takes und behält den verständlichsten (Qualitätstor)."""
    best = None
    for t in range(takes):
        cand = f'{out_wav}.take{t}.wav'
        synth(variant, style, text, cand)
        score = intelligibility(cand, text)
        if best is None or score < best[0]:
            if best:
                os.remove(best[1])
            best = (score, cand)
        else:
            os.remove(cand)
        if score == 0:
            break
    os.replace(best[1], out_wav)
    return best[0]


def concat(wavs, out, gap=0.7):
    inputs = []
    filt = []
    for i, w in enumerate(wavs):
        inputs += ['-i', w]
        filt.append(f'[{i}:a]apad=pad_dur={gap}[p{i}]')
    filt.append(''.join(f'[p{i}]' for i in range(len(wavs))) + f'concat=n={len(wavs)}:v=0:a=1[o]')
    subprocess.run([FFMPEG, '-y', '-loglevel', 'error', *inputs, '-filter_complex', ';'.join(filt),
                    '-map', '[o]', out], check=True)


def to_m4a(wav, out):
    subprocess.run([FFMPEG, '-y', '-loglevel', 'error', '-i', wav, '-c:a', 'aac', '-b:a', '96k', out], check=True)


def duration(path):
    with wave.open(path) as w:
        return w.getnframes() / w.getframerate()


def samples(outdir):
    os.makedirs(outdir, exist_ok=True)
    report = {}
    for key in VARIANTS:
        parts = []
        for style, text in SAMPLE_TEXTS:
            p = os.path.join(outdir, f'{key}_{style}.wav')
            synth_best(key, style, text, p)
            parts.append(p)
        full = os.path.join(outdir, f'lumo_stimme_{key}.wav')
        concat(parts, full)
        to_m4a(full, full.replace('.wav', '.m4a'))
        report[key] = {'title': VARIANTS[key]['title'], 'seconds': round(duration(full), 1),
                       'parts': {os.path.basename(p): round(duration(p), 1) for p in parts}}
        for p in parts:
            os.remove(p)
    print(json.dumps(report, indent=1, ensure_ascii=False))


if __name__ == '__main__':
    if sys.argv[1] == 'samples':
        samples(sys.argv[2])


# ── Clip-Produktion für die App ─────────────────────────────────────────

def normalize_key(text):
    """Muss exakt LumoVoiceClips.keyFor in lib/core/lumo_voice_clips.dart entsprechen."""
    import re
    t = text.lower()
    t = re.sub(r'[^a-z0-9äöüß]+', ' ', t)
    return ' '.join(t.split())


def envelope(wav_path, fps=20):
    """Lautstärke-Hüllkurve (0–9 je 50 ms) für die Mundbewegung."""
    import numpy as np
    with wave.open(wav_path) as w:
        sr = w.getframerate()
        x = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(float)
        if w.getnchannels() > 1:
            x = x.reshape(-1, w.getnchannels()).mean(1)
    hop = sr // fps
    rms = np.array([np.sqrt((x[i:i+hop] ** 2).mean()) for i in range(0, len(x) - hop + 1, hop)])
    peak = np.percentile(rms, 95) or 1.0
    lvl = np.clip(rms / peak, 0, 1) ** 0.7
    return ''.join(str(int(round(v * 9))) for v in lvl)


MAX_WER = 0.3


def _write_catalog(path, variant, catalog):
    with open(path, 'w') as fh:
        json.dump({'voice': VARIANTS[variant]['title'], 'variant': variant, 'fps': 20,
                   'license': 'Piper-Stimmen thorsten-high / thorsten_emotional: CC0',
                   'clips': catalog}, fh, ensure_ascii=False, separators=(',', ':'))


def clips(phrases_path, outdir, variant):
    import hashlib
    os.makedirs(outdir, exist_ok=True)
    phrases = json.load(open(phrases_path))
    catalog_path = os.path.join(outdir, 'catalog.json')
    old = json.load(open(catalog_path))['clips'] if os.path.exists(catalog_path) else {}
    catalog = {}
    worst = []
    for i, p in enumerate(phrases):
        key = normalize_key(p['text'])
        if key in catalog:
            continue
        cid = hashlib.sha1(f"{variant}|{p['style']}|{key}".encode()).hexdigest()[:12]
        m4a = os.path.join(outdir, cid + '.m4a')
        if key in old and old[key]['id'] == cid and os.path.exists(m4a) and old[key]['wer'] <= MAX_WER:
            catalog[key] = old[key]
            continue
        wav = os.path.join(outdir, cid + '.wav')
        score = synth_best(variant, p['style'], p['text'], wav, takes=3 if key not in old else 8)
        if score > MAX_WER:
            # Unklarer Clip: lieber Geräte-Stimme als falsches Wort.
            os.remove(wav)
            worst.append((score, p['text']))
            print(f'{i+1}/{len(phrases)} AUSGELASSEN {score:.2f} {p["text"]}', flush=True)
            continue
        subprocess.run([FFMPEG, '-y', '-loglevel', 'error', '-i', wav, '-ac', '1', '-ar', '44100',
                        '-c:a', 'aac', '-b:a', '64k', m4a], check=True)
        catalog[key] = {'id': cid, 'text': p['text'], 'style': p['style'],
                        'ms': int(duration(wav) * 1000), 'wer': round(score, 3), 'env': envelope(wav)}
        os.remove(wav)
        worst.append((score, p['text']))
        _write_catalog(catalog_path, variant, {**old, **catalog})
        print(f'{i+1}/{len(phrases)} {score:.2f} {p["text"]}', flush=True)
    for f in os.listdir(outdir):
        if f.endswith('.m4a') and f[:-4] not in {c['id'] for c in catalog.values()}:
            os.remove(os.path.join(outdir, f))
    _write_catalog(catalog_path, variant, catalog)
    worst.sort(reverse=True)
    print('schlechteste:', worst[:8])


if __name__ == '__main__' and sys.argv[1] == 'clips':
    clips(sys.argv[2], sys.argv[3], sys.argv[4])
