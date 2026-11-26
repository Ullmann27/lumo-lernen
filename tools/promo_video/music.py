#!/usr/bin/env python3
"""Erzeugt die Musik des Werbevideos vollständig rechnerisch (numpy).

Keine Samples, keine fremden Aufnahmen, keine fremde Melodie: Akkordfolge,
Arpeggio, Bass und Schlagwerk entstehen hier aus Sinus-/Rauschsynthese.
120 BPM, ein Takt = 2 s; die Szenen des Videos liegen auf diesem Raster.

Aufruf: music.py <ziel.wav> <dauer_sekunden>
"""
import sys
import wave
import numpy as np

SR = 44100
BPM = 120.0
BEAT = 60.0 / BPM
BAR = 4 * BEAT
rng = np.random.default_rng(2713)


def hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12.0)


def env(n, a, d, s=0.0, r=0.05):
    """Hüllkurve: Anstieg a, Abfall d auf Pegel s, Ausklang r (Sekunden)."""
    t = np.arange(n) / SR
    e = np.minimum(t / max(a, 1e-4), 1.0)
    e *= s + (1 - s) * np.exp(-np.maximum(t - a, 0) / max(d, 1e-4))
    tail = int(r * SR)
    if 0 < tail < n:
        e[-tail:] *= np.linspace(1, 0, tail)
    return e


def lowpass(x, cutoff):
    """Sanfter Tiefpass 4. Ordnung im Frequenzbereich (reines numpy)."""
    spec = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    return np.fft.irfft(spec / (1 + (f / cutoff) ** 4), len(x))


def add(buf, sig, at, gain=1.0, pan=0.0):
    i = int(at * SR)
    if i >= buf.shape[1]:
        return
    n = min(len(sig), buf.shape[1] - i)
    left = np.cos((pan + 1) * np.pi / 4)
    right = np.sin((pan + 1) * np.pi / 4)
    buf[0, i:i + n] += sig[:n] * gain * left
    buf[1, i:i + n] += sig[:n] * gain * right


def pad(freqs, dur):
    n = int(dur * SR)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for f in freqs:
        for det in (-0.35, 0.0, 0.35):
            ff = f * 2 ** (det / 120.0)
            ph = rng.uniform(0, 2 * np.pi)
            for h, amp in ((1, 1.0), (2, 0.42), (3, 0.22), (4, 0.10), (5, 0.05)):
                out += amp * np.sin(2 * np.pi * ff * h * t + ph * h)
    return out / (len(freqs) * 3) * env(n, 0.45, 9.0, 0.75, 0.5)


def pluck(f, dur=0.5, bright=1.0):
    n = int(dur * SR)
    t = np.arange(n) / SR
    s = np.sin(2 * np.pi * f * t) + 0.5 * bright * np.sin(2 * np.pi * 2 * f * t) * np.exp(-t * 9)
    s += 0.22 * bright * np.sin(2 * np.pi * 3 * f * t) * np.exp(-t * 16)
    return s * env(n, 0.004, 0.16, 0.0, 0.03)


def bell(f, dur=1.6):
    n = int(dur * SR)
    t = np.arange(n) / SR
    mod = np.sin(2 * np.pi * f * 3.01 * t) * 1.6 * np.exp(-t * 5)
    return np.sin(2 * np.pi * f * t + mod) * env(n, 0.003, 0.55, 0.0, 0.1)


def bass(f, dur):
    n = int(dur * SR)
    t = np.arange(n) / SR
    s = np.sin(2 * np.pi * f * t) + 0.35 * np.sin(2 * np.pi * 2 * f * t) + 0.12 * np.sin(2 * np.pi * 3 * f * t)
    return s * env(n, 0.008, 0.5, 0.55, 0.04)


def kick():
    n = int(0.32 * SR)
    t = np.arange(n) / SR
    f = 46 + 95 * np.exp(-t * 34)
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) * np.exp(-t * 11) + 0.25 * np.exp(-t * 400) * rng.standard_normal(n)


def clap():
    n = int(0.22 * SR)
    t = np.arange(n) / SR
    noise = rng.standard_normal(n)
    noise = noise - lowpass(noise, 900)
    noise = lowpass(noise, 5200)
    burst = sum(np.exp(-np.maximum(t - d, 0) * 60) * (t >= d) for d in (0.0, 0.011, 0.023))
    return noise * burst * 0.5


def hat(open_=False):
    n = int((0.16 if open_ else 0.05) * SR)
    t = np.arange(n) / SR
    noise = rng.standard_normal(n)
    noise = noise - lowpass(noise, 6500)
    return noise * np.exp(-t * (22 if open_ else 80))


def riser(dur):
    n = int(dur * SR)
    t = np.arange(n) / SR
    noise = rng.standard_normal(n)
    noise = noise - lowpass(noise, 2500)
    return noise * (t / dur) ** 2.4 * 0.5


# Akkorde (MIDI): C – G – Am – F, mit farbigen Zusatztönen.
CHORDS = [
    ([48, 55, 60, 64, 67, 74], 36, [72, 76, 79, 84]),   # Cadd9
    ([43, 55, 59, 62, 67, 74], 31, [71, 74, 79, 83]),   # G
    ([45, 57, 60, 64, 67, 72], 33, [72, 76, 81, 84]),   # Am7
    ([41, 53, 57, 60, 65, 72], 29, [72, 77, 81, 84]),   # Fmaj
]
ARP = [0, 1, 2, 3, 2, 1, 2, 3]
LEAD = {  # zweitaktige Melodiephrasen je Akkord (Achtelposition, MIDI)
    0: [(0, 79), (2, 76), (3, 79), (5, 84), (6, 83)],
    1: [(0, 83), (2, 79), (4, 74), (6, 79)],
    2: [(0, 81), (2, 76), (3, 81), (5, 84), (6, 88)],
    3: [(0, 84), (2, 81), (4, 77), (6, 79), (7, 81)],
}


def section(bar, bars):
    """Energie je Takt: 0 Ruhe, 1 leicht, 2 Groove, 3 voll, 4 Finale."""
    t = bar * BAR
    for start, level in reversed(SECTIONS):
        if t >= start:
            return level
    return 0


SECTIONS = []


def build(duration, sections):
    global SECTIONS
    SECTIONS = sections
    total = int((duration + 3.0) * SR)
    mus = np.zeros((2, total))      # wird vom Bassdrum-Impuls geduckt
    drm = np.zeros((2, total))
    bars = int(np.ceil(duration / BAR))
    K, C, H, OH = kick(), clap(), hat(), hat(True)
    duck = np.ones(total)
    for bar in range(bars):
        t0 = bar * BAR
        lvl = section(bar, bars)
        nxt = section(bar + 1, bars)
        chord, root, arp = CHORDS[bar % 4]
        last = bar == bars - 1
        add(mus, pad([hz(m) for m in chord], BAR * (3.0 if last else 1.12)), t0, 0.16 + 0.02 * lvl)
        if lvl >= 1:
            for i in range(8):
                note = arp[ARP[i]] + (12 if (lvl >= 3 and i % 4 == 3) else 0)
                p = pluck(hz(note), 0.45, 0.6 + 0.25 * lvl)
                g = (0.10 + 0.02 * lvl) * (1.0 if i % 2 == 0 else 0.72)
                at = t0 + i * BEAT / 2
                add(mus, p, at, g, -0.35 if i % 2 == 0 else 0.35)
                add(mus, p, at + BEAT * 0.75, g * 0.32, 0.5 if i % 2 == 0 else -0.5)
        if lvl == 0 or bar % 4 == 0:
            add(mus, bell(hz(arp[2] + 12)), t0, 0.07, 0.25)
            add(mus, bell(hz(arp[0] + 12)), t0 + BEAT * 2.5, 0.05, -0.3)
        if lvl >= 2:
            pattern = [0, 1.5, 2, 3.5] if lvl >= 3 else [0, 2, 3.5]
            for b in pattern:
                add(mus, bass(hz(root), BEAT * 0.9), t0 + b * BEAT, 0.30)
            for b in range(4):
                add(drm, K, t0 + b * BEAT, 0.62)
                i = int((t0 + b * BEAT) * SR)
                n = int(0.26 * SR)
                if i + n < total:
                    duck[i:i + n] = np.minimum(duck[i:i + n], 0.45 + 0.55 * np.linspace(0, 1, n) ** 0.7)
            for b in (1, 3):
                add(drm, C, t0 + b * BEAT, 0.34)
        elif lvl == 1:
            for b in (0, 2):
                add(drm, K, t0 + b * BEAT, 0.40)
        if lvl >= 2:
            for i in range(8):
                if i % 2 == 1:
                    add(drm, OH if (lvl >= 3 and i == 7) else H, t0 + i * BEAT / 2, 0.11, 0.2)
                elif lvl >= 3:
                    add(drm, H, t0 + i * BEAT / 2, 0.05, -0.2)
        if lvl >= 3:
            for pos, note in LEAD[bar % 4]:
                add(mus, bell(hz(note), 0.9), t0 + pos * BEAT / 2, 0.085, 0.1)
                add(mus, pluck(hz(note - 12), 0.5, 1.2), t0 + pos * BEAT / 2, 0.06, -0.1)
        if nxt > lvl and nxt >= 2:
            add(mus, riser(BAR), t0, 0.07)
        if lvl != section(bar - 1, bars) and lvl >= 2 and bar > 0:
            crash = hat(True)
            crash = np.concatenate([crash, np.zeros(int(0.9 * SR))])
            n = len(crash)
            long = rng.standard_normal(n)
            long = (long - lowpass(long, 5000)) * np.exp(-np.arange(n) / SR * 3.2)
            add(drm, long, t0, 0.16)
    mix = mus * duck + drm
    end = int(duration * SR)
    fade = int(2.2 * SR)
    mix[:, end - fade:end] *= np.linspace(1, 0, fade) ** 1.5
    mix = mix[:, :end]
    mix[:, :int(0.4 * SR)] *= np.linspace(0, 1, int(0.4 * SR))
    mix = np.tanh(mix * 1.5) / np.tanh(1.5)
    mix *= 0.89 / np.max(np.abs(mix))
    return mix


def write(path, mix):
    data = (mix.T * 32767).astype('<i2')
    with wave.open(path, 'wb') as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


if __name__ == '__main__':
    import json
    out, duration = sys.argv[1], float(sys.argv[2])
    sections = json.loads(sys.argv[3]) if len(sys.argv) > 3 else [[0, 0], [8, 1], [16, 2]]
    write(out, build(duration, [tuple(s) for s in sections]))
    print('Musik geschrieben:', out, duration, 's')
