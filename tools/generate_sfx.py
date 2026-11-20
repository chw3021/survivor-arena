#!/usr/bin/env python3
"""Higher-quality arcade SFX for Survivor Arena (stdlib only).

Layers body/click/noise, simple filters, pitch sweeps, short delay/reverb,
44.1kHz PCM, soft-clip + peak normalize. Not photoreal — gamey but cleaner.
BGM is authored separately at assets/bgm/arena.wav.
"""
from __future__ import annotations

import math
import os
import random
import struct
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "sfx")
RATE = 44100
RNG = random.Random(42)


def clamp(x: float, lo: float = -1.0, hi: float = 1.0) -> float:
    return lo if x < lo else hi if x > hi else x


def soft_clip(x: float) -> float:
    # Gentle tanh-ish saturation before hard clamp.
    return math.tanh(x * 1.15) * 0.98


def write_wav(name: str, samples: list[float], rate: int = RATE) -> None:
    path = os.path.join(OUT, name)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        frames = bytearray()
        for s in samples:
            v = int(clamp(s) * 32767.0)
            frames += struct.pack("<h", v)
        w.writeframes(frames)
    print("wrote", path, f"({len(samples) / rate:.3f}s)")


def env_adsr(i: int, n: int, a: float, d: float, s: float, r: float) -> float:
    t = i / max(1, n - 1)
    if t < a:
        return t / max(1e-6, a)
    if t < a + d:
        return 1.0 - (1.0 - s) * ((t - a) / max(1e-6, d))
    if t < 1.0 - r:
        return s
    return s * max(0.0, 1.0 - (t - (1.0 - r)) / max(1e-6, r))


def osc(kind: str, phase: float) -> float:
    # phase in [0, 1)
    if kind == "sine":
        return math.sin(phase * 2.0 * math.pi)
    if kind == "triangle":
        return 1.0 - 4.0 * abs(phase - 0.5)
    if kind == "saw":
        return 2.0 * phase - 1.0
    if kind == "noise":
        return RNG.uniform(-1.0, 1.0)
    # soft square (less harsh aliasing feel than hard square)
    return 1.0 if phase < 0.5 else -1.0


def tone(
    freq: float,
    dur: float,
    vol: float = 0.4,
    kind: str = "sine",
    a: float = 0.01,
    d: float = 0.12,
    s: float = 0.45,
    r: float = 0.3,
) -> list[float]:
    n = max(1, int(RATE * dur))
    out = [0.0] * n
    phase = 0.0
    for i in range(n):
        out[i] = osc(kind, phase) * vol * env_adsr(i, n, a, d, s, r)
        phase = (phase + freq / RATE) % 1.0
    return out


def sweep(
    f0: float,
    f1: float,
    dur: float,
    vol: float = 0.35,
    kind: str = "sine",
    curve: float = 1.0,
    a: float = 0.005,
    d: float = 0.18,
    s: float = 0.35,
    r: float = 0.4,
) -> list[float]:
    n = max(1, int(RATE * dur))
    out = [0.0] * n
    phase = 0.0
    for i in range(n):
        u = i / max(1, n - 1)
        u = u ** curve
        freq = f0 + (f1 - f0) * u
        out[i] = osc(kind, phase) * vol * env_adsr(i, n, a, d, s, r)
        phase = (phase + max(20.0, freq) / RATE) % 1.0
    return out


def noise_burst(dur: float, vol: float = 0.3, a: float = 0.0, d: float = 0.15, s: float = 0.25, r: float = 0.55) -> list[float]:
    n = max(1, int(RATE * dur))
    return [RNG.uniform(-1.0, 1.0) * vol * env_adsr(i, n, a, d, s, r) for i in range(n)]


def lowpass(samples: list[float], cutoff_hz: float) -> list[float]:
    if not samples:
        return samples
    # one-pole LPF
    x = math.exp(-2.0 * math.pi * cutoff_hz / RATE)
    a0 = 1.0 - x
    y = 0.0
    out = [0.0] * len(samples)
    for i, s in enumerate(samples):
        y = a0 * s + x * y
        out[i] = y
    return out


def highpass(samples: list[float], cutoff_hz: float) -> list[float]:
    if not samples:
        return samples
    # y[n] = a0*(x[n]-x[n-1]) + a1*y[n-1] approx via LP subtract
    lp = lowpass(samples, cutoff_hz)
    return [samples[i] - lp[i] for i in range(len(samples))]


def mix(*tracks: list[float], vols: list[float] | None = None) -> list[float]:
    if not tracks:
        return []
    n = max(len(t) for t in tracks)
    out = [0.0] * n
    for ti, track in enumerate(tracks):
        g = 1.0 if vols is None else vols[ti]
        for i, s in enumerate(track):
            out[i] += s * g
    return out


def pad_to(samples: list[float], n: int) -> list[float]:
    if len(samples) >= n:
        return samples[:n]
    return samples + [0.0] * (n - len(samples))


def offset(samples: list[float], delay_sec: float) -> list[float]:
    d = max(0, int(RATE * delay_sec))
    return [0.0] * d + samples


def delay_echo(samples: list[float], delay_sec: float, feedback: float = 0.28, mix_amt: float = 0.22) -> list[float]:
    d = max(1, int(RATE * delay_sec))
    out = [0.0] * (len(samples) + d * 3)
    for i, s in enumerate(samples):
        out[i] += s
        # 2 taps
        if i + d < len(out):
            out[i + d] += s * mix_amt
        if i + 2 * d < len(out):
            out[i + 2 * d] += s * mix_amt * feedback
    return out


def early_reverb(samples: list[float], wet: float = 0.18) -> list[float]:
    # Very short "room" via a few filtered taps — keeps arcade feel.
    taps = [
        (0.012, 0.35),
        (0.021, 0.22),
        (0.033, 0.14),
        (0.047, 0.09),
    ]
    wet_buf = [0.0] * (len(samples) + int(RATE * 0.08))
    for delay_sec, gain in taps:
        d = int(RATE * delay_sec)
        for i, s in enumerate(samples):
            wet_buf[i + d] += s * gain
    wet_buf = lowpass(wet_buf, 4200.0)
    dry = pad_to(samples, len(wet_buf))
    return [dry[i] * (1.0 - wet) + wet_buf[i] * wet for i in range(len(dry))]


def finalize(samples: list[float], peak: float = 0.88) -> list[float]:
    if not samples:
        return samples
    # trim tiny trailing silence but keep a few ms
    end = len(samples) - 1
    while end > 0 and abs(samples[end]) < 1e-4:
        end -= 1
    samples = samples[: min(len(samples), end + int(RATE * 0.02))]
    clipped = [soft_clip(s) for s in samples]
    m = max(1e-9, max(abs(x) for x in clipped))
    scale = peak / m
    return [clamp(x * scale) for x in clipped]


# --- per-SFX algorithms -------------------------------------------------


def gunshot() -> list[float]:
    # click + mid body thump + noise crack + short room
    click = highpass(tone(2400, 0.018, 0.55, "triangle", a=0.0, d=0.25, s=0.1, r=0.6), 1200)
    body = lowpass(sweep(280, 70, 0.11, 0.7, "sine", curve=1.6, a=0.0, d=0.2, s=0.25, r=0.55), 900)
    shell = sweep(900, 220, 0.07, 0.28, "triangle", curve=1.2)
    crack = highpass(noise_burst(0.09, 0.55, a=0.0, d=0.12, s=0.2, r=0.7), 1800)
    crack = lowpass(crack, 9000)
    layered = mix(click, body, shell, crack, vols=[1.0, 1.0, 0.7, 0.85])
    return finalize(early_reverb(layered, 0.14))


def reload_sfx() -> list[float]:
    # metallic click → slide → latch clack
    click = highpass(tone(2100, 0.035, 0.4, "triangle", a=0.0, d=0.2, s=0.15, r=0.55), 900)
    slide = lowpass(sweep(720, 240, 0.14, 0.38, "saw", curve=0.8, a=0.02, d=0.2, s=0.4, r=0.4), 2600)
    hiss = lowpass(highpass(noise_burst(0.12, 0.18, a=0.05, d=0.2, s=0.3, r=0.5), 1500), 7000)
    clack = mix(
        tone(280, 0.05, 0.4, "sine", a=0.0, d=0.25, s=0.2, r=0.5),
        highpass(tone(1600, 0.03, 0.25, "triangle", a=0.0, d=0.3, s=0.1, r=0.55), 800),
    )
    gap1 = [0.0] * int(RATE * 0.035)
    gap2 = [0.0] * int(RATE * 0.045)
    seq = click + gap1 + mix(slide, hiss) + gap2 + clack
    return finalize(delay_echo(seq, 0.028, feedback=0.18, mix_amt=0.12))


def dash_sfx() -> list[float]:
    whoosh = sweep(180, 1100, 0.16, 0.42, "sine", curve=0.7, a=0.02, d=0.15, s=0.45, r=0.4)
    air = highpass(noise_burst(0.18, 0.32, a=0.0, d=0.18, s=0.35, r=0.5), 600)
    air = lowpass(air, 6500)
    body = lowpass(sweep(90, 220, 0.12, 0.28, "sine", curve=0.9), 500)
    layered = mix(whoosh, air, body, vols=[1.0, 0.9, 0.7])
    return finalize(early_reverb(layered, 0.12))


def hurt_sfx() -> list[float]:
    # dull impact + descending grit
    thump = lowpass(sweep(220, 70, 0.18, 0.55, "sine", curve=1.4, a=0.0, d=0.2, s=0.3, r=0.55), 450)
    grit = lowpass(highpass(noise_burst(0.14, 0.28, a=0.0, d=0.15, s=0.25, r=0.6), 400), 2500)
    sting = sweep(480, 140, 0.12, 0.28, "triangle", curve=1.3)
    layered = mix(thump, grit, sting, vols=[1.0, 0.8, 0.65])
    return finalize(early_reverb(layered, 0.16))


def hit_sfx() -> list[float]:
    # punchy confirm tick for dealing damage
    tick = highpass(tone(980, 0.028, 0.45, "triangle", a=0.0, d=0.3, s=0.1, r=0.55), 700)
    body = sweep(620, 180, 0.07, 0.4, "sine", curve=1.5, a=0.0, d=0.25, s=0.2, r=0.5)
    spark = highpass(noise_burst(0.04, 0.22, a=0.0, d=0.25, s=0.1, r=0.6), 2500)
    layered = mix(tick, body, spark, vols=[1.0, 0.9, 0.7])
    return finalize(layered)


def weapon_switch() -> list[float]:
    a = tone(392, 0.05, 0.28, "triangle", a=0.01, d=0.2, s=0.35, r=0.4)
    b = tone(587, 0.06, 0.32, "triangle", a=0.01, d=0.2, s=0.35, r=0.4)
    c = tone(784, 0.07, 0.22, "sine", a=0.01, d=0.25, s=0.25, r=0.45)
    click = highpass(noise_burst(0.025, 0.15, a=0.0, d=0.3, s=0.1, r=0.55), 2000)
    seq = mix(a, offset(b, 0.045), offset(c, 0.09), offset(click, 0.02))
    return finalize(delay_echo(seq, 0.035, feedback=0.15, mix_amt=0.1))


def explosion_sfx() -> list[float]:
    # deep boom + mid crack + long noise tail
    boom = lowpass(sweep(140, 28, 0.42, 0.85, "sine", curve=1.8, a=0.0, d=0.18, s=0.35, r=0.55), 220)
    mid = lowpass(sweep(320, 60, 0.28, 0.45, "triangle", curve=1.5), 700)
    crack = highpass(noise_burst(0.12, 0.7, a=0.0, d=0.1, s=0.25, r=0.65), 900)
    crack = lowpass(crack, 6000)
    tail = lowpass(noise_burst(0.45, 0.4, a=0.0, d=0.12, s=0.4, r=0.55), 1200)
    layered = mix(boom, mid, crack, tail, vols=[1.0, 0.75, 0.85, 0.7])
    return finalize(early_reverb(layered, 0.22))


def electric_sfx() -> list[float]:
    # crackle + descending buzz + sparse sparks
    zap = sweep(1800, 420, 0.09, 0.4, "saw", curve=1.1, a=0.0, d=0.2, s=0.25, r=0.5)
    zap = highpass(zap, 300)
    buzz_n = int(RATE * 0.16)
    buzz = [0.0] * buzz_n
    phase = 0.0
    for i in range(buzz_n):
        freq = 90.0 + 40.0 * math.sin(i / RATE * 40.0)
        # gated square buzz
        gate = 1.0 if (i // max(1, int(RATE * 0.004))) % 2 == 0 else 0.15
        buzz[i] = osc("square", phase) * 0.28 * gate * env_adsr(i, buzz_n, 0.0, 0.1, 0.55, 0.4)
        phase = (phase + freq / RATE) % 1.0
    sparks = [0.0] * int(RATE * 0.18)
    for _ in range(7):
        start = RNG.randint(0, max(0, len(sparks) - int(RATE * 0.01)))
        burst = highpass(noise_burst(0.012, 0.45, a=0.0, d=0.35, s=0.05, r=0.55), 2500)
        for j, s in enumerate(burst):
            if start + j < len(sparks):
                sparks[start + j] += s
    layered = mix(zap, buzz, sparks, vols=[1.0, 0.85, 0.7])
    layered = highpass(layered, 180)
    return finalize(delay_echo(layered, 0.018, feedback=0.25, mix_amt=0.16))


def pickup_sfx() -> list[float]:
    notes = [523.25, 659.25, 783.99, 1046.5]
    parts: list[list[float]] = []
    for i, f in enumerate(notes):
        kind = "sine" if i < 3 else "triangle"
        parts.append(offset(tone(f, 0.07 + i * 0.01, 0.28 - i * 0.02, kind, a=0.01, d=0.2, s=0.3, r=0.45), i * 0.045))
    chime = mix(*parts)
    sparkle = highpass(noise_burst(0.08, 0.08, a=0.1, d=0.2, s=0.2, r=0.5), 4000)
    layered = mix(chime, offset(sparkle, 0.05), vols=[1.0, 0.5])
    return finalize(delay_echo(layered, 0.05, feedback=0.2, mix_amt=0.18))


# --- weapon-specific shots / reloads ------------------------------------


def shot_pistol() -> list[float]:
    # snappy handgun: sharp click + short body
    click = highpass(tone(2800, 0.014, 0.6, "triangle", a=0.0, d=0.3, s=0.08, r=0.55), 1400)
    body = lowpass(sweep(340, 90, 0.08, 0.62, "sine", curve=1.7, a=0.0, d=0.25, s=0.2, r=0.5), 1000)
    crack = highpass(noise_burst(0.05, 0.4, a=0.0, d=0.2, s=0.12, r=0.6), 2200)
    return finalize(early_reverb(mix(click, body, crack, vols=[1.0, 1.0, 0.7]), 0.1))


def shot_shotgun() -> list[float]:
    # fat boom + pellet hiss
    boom = lowpass(sweep(180, 45, 0.22, 0.85, "sine", curve=1.6, a=0.0, d=0.18, s=0.3, r=0.55), 280)
    body = lowpass(sweep(420, 90, 0.14, 0.5, "triangle", curve=1.3), 800)
    pellets = highpass(noise_burst(0.16, 0.55, a=0.0, d=0.12, s=0.3, r=0.6), 1200)
    pellets = lowpass(pellets, 7500)
    return finalize(early_reverb(mix(boom, body, pellets, vols=[1.0, 0.8, 0.9]), 0.18))


def shot_assault() -> list[float]:
    # tight rifle crack for full-auto feel
    click = highpass(tone(1900, 0.012, 0.5, "triangle", a=0.0, d=0.35, s=0.05, r=0.5), 1100)
    body = lowpass(sweep(400, 120, 0.06, 0.55, "sine", curve=1.4, a=0.0, d=0.3, s=0.15, r=0.5), 1200)
    crack = highpass(noise_burst(0.04, 0.35, a=0.0, d=0.3, s=0.08, r=0.55), 2000)
    return finalize(mix(click, body, crack, vols=[1.0, 0.95, 0.75]))


def shot_sniper() -> list[float]:
    # heavy long report + echo
    boom = lowpass(sweep(220, 50, 0.28, 0.8, "sine", curve=1.7, a=0.0, d=0.15, s=0.35, r=0.55), 350)
    crack = highpass(noise_burst(0.1, 0.65, a=0.0, d=0.12, s=0.2, r=0.65), 1500)
    ring = sweep(1400, 280, 0.18, 0.28, "triangle", curve=1.2, a=0.0, d=0.2, s=0.25, r=0.55)
    layered = mix(boom, crack, ring, vols=[1.0, 0.9, 0.55])
    return finalize(delay_echo(early_reverb(layered, 0.2), 0.055, feedback=0.22, mix_amt=0.2))


def shot_mg() -> list[float]:
    # thick short chatter for MG
    thump = lowpass(sweep(260, 80, 0.05, 0.7, "sine", curve=1.5, a=0.0, d=0.35, s=0.1, r=0.5), 700)
    grit = highpass(noise_burst(0.035, 0.4, a=0.0, d=0.35, s=0.08, r=0.5), 900)
    grit = lowpass(grit, 5000)
    return finalize(mix(thump, grit, vols=[1.0, 0.85]))


def shot_flame() -> list[float]:
    # continuous whoosh / burn spit
    roar = lowpass(noise_burst(0.14, 0.55, a=0.02, d=0.15, s=0.55, r=0.35), 1800)
    roar = highpass(roar, 120)
    flutter_n = int(RATE * 0.14)
    flutter = [0.0] * flutter_n
    phase = 0.0
    for i in range(flutter_n):
        freq = 55.0 + 25.0 * math.sin(i / RATE * 28.0)
        flutter[i] = osc("saw", phase) * 0.18 * env_adsr(i, flutter_n, 0.05, 0.2, 0.55, 0.35)
        phase = (phase + freq / RATE) % 1.0
    flutter = lowpass(flutter, 900)
    spit = highpass(noise_burst(0.04, 0.3, a=0.0, d=0.25, s=0.1, r=0.55), 2500)
    return finalize(mix(roar, flutter, spit, vols=[1.0, 0.7, 0.45]))


def shot_taser() -> list[float]:
    # close-range zap crack
    zap = sweep(2200, 380, 0.07, 0.48, "saw", curve=1.2, a=0.0, d=0.25, s=0.2, r=0.5)
    buzz_n = int(RATE * 0.1)
    buzz = [0.0] * buzz_n
    phase = 0.0
    for i in range(buzz_n):
        gate = 1.0 if (i // max(1, int(RATE * 0.003))) % 2 == 0 else 0.2
        buzz[i] = osc("square", phase) * 0.32 * gate * env_adsr(i, buzz_n, 0.0, 0.15, 0.5, 0.4)
        phase = (phase + (110.0 + 30.0 * math.sin(i / RATE * 50.0)) / RATE) % 1.0
    spark = highpass(noise_burst(0.03, 0.35, a=0.0, d=0.4, s=0.05, r=0.5), 2800)
    return finalize(delay_echo(mix(zap, buzz, spark, vols=[1.0, 0.8, 0.6]), 0.012, 0.2, 0.12))


def shot_emp() -> list[float]:
    # soft launch + electric bloom
    thump = lowpass(sweep(160, 55, 0.12, 0.55, "sine", curve=1.4, a=0.0, d=0.2, s=0.3, r=0.5), 400)
    bloom = sweep(900, 220, 0.16, 0.35, "triangle", curve=0.9, a=0.02, d=0.2, s=0.35, r=0.45)
    crackle = highpass(noise_burst(0.1, 0.28, a=0.05, d=0.2, s=0.25, r=0.5), 1800)
    return finalize(early_reverb(mix(thump, bloom, crackle, vols=[1.0, 0.75, 0.7]), 0.16))


def reload_pistol() -> list[float]:
    # mag out → mag in → slide
    out_c = highpass(tone(1800, 0.025, 0.32, "triangle", a=0.0, d=0.3, s=0.1, r=0.5), 900)
    mag = lowpass(mix(
        tone(220, 0.05, 0.35, "sine", a=0.0, d=0.3, s=0.2, r=0.5),
        highpass(noise_burst(0.04, 0.15, a=0.0, d=0.3, s=0.1, r=0.5), 1200),
    ), 2400)
    slide = highpass(sweep(1600, 700, 0.06, 0.3, "triangle", curve=0.8), 600)
    gap = [0.0] * int(RATE * 0.04)
    return finalize(out_c + gap + mag + gap + slide)


def reload_shotgun() -> list[float]:
    # pump: forward clack + back slide
    pump1 = mix(
        tone(180, 0.04, 0.4, "sine", a=0.0, d=0.3, s=0.15, r=0.5),
        highpass(tone(900, 0.03, 0.28, "triangle", a=0.0, d=0.35, s=0.08, r=0.5), 500),
    )
    slide = lowpass(highpass(noise_burst(0.1, 0.28, a=0.02, d=0.2, s=0.35, r=0.45), 400), 3500)
    pump2 = highpass(tone(1200, 0.035, 0.35, "triangle", a=0.0, d=0.3, s=0.1, r=0.55), 700)
    gap = [0.0] * int(RATE * 0.055)
    return finalize(early_reverb(pump1 + gap + mix(slide, pump2), 0.1))


def reload_rifle() -> list[float]:
    # AR mag swap + bolt
    click = highpass(tone(2400, 0.02, 0.35, "triangle", a=0.0, d=0.35, s=0.08, r=0.5), 1000)
    mag = lowpass(sweep(500, 180, 0.1, 0.4, "saw", curve=0.9, a=0.02, d=0.25, s=0.35, r=0.4), 2200)
    bolt = mix(
        tone(320, 0.04, 0.35, "sine", a=0.0, d=0.3, s=0.15, r=0.5),
        highpass(tone(1500, 0.025, 0.28, "triangle", a=0.0, d=0.35, s=0.08, r=0.5), 800),
    )
    gap = [0.0] * int(RATE * 0.04)
    return finalize(click + gap + mag + gap + bolt)


def reload_heavy() -> list[float]:
    # belt / heavy mag clunk (sniper / MG)
    clunk = lowpass(sweep(140, 60, 0.12, 0.55, "sine", curve=1.2, a=0.0, d=0.2, s=0.35, r=0.5), 500)
    scrape = lowpass(highpass(noise_burst(0.16, 0.28, a=0.05, d=0.2, s=0.4, r=0.4), 500), 2800)
    latch = highpass(tone(700, 0.05, 0.4, "triangle", a=0.0, d=0.25, s=0.15, r=0.55), 400)
    gap = [0.0] * int(RATE * 0.06)
    return finalize(early_reverb(clunk + gap + scrape + gap + latch, 0.12))


def reload_energy() -> list[float]:
    # capacitor charge + soft click (taser / EMP)
    charge = sweep(180, 920, 0.18, 0.35, "sine", curve=0.85, a=0.05, d=0.15, s=0.55, r=0.35)
    hum = tone(110, 0.2, 0.18, "sine", a=0.05, d=0.2, s=0.5, r=0.35)
    spark = highpass(noise_burst(0.05, 0.22, a=0.0, d=0.3, s=0.1, r=0.55), 2200)
    click = highpass(tone(1600, 0.03, 0.28, "triangle", a=0.0, d=0.35, s=0.08, r=0.5), 900)
    return finalize(delay_echo(mix(charge, hum, offset(spark, 0.12), offset(click, 0.16), vols=[1.0, 0.7, 0.6, 0.8]), 0.02, 0.18, 0.12))


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    common = {
        "gunshot.wav": gunshot,
        "reload.wav": reload_sfx,
        "dash.wav": dash_sfx,
        "hurt.wav": hurt_sfx,
        "hit.wav": hit_sfx,
        "weapon_switch.wav": weapon_switch,
        "explosion.wav": explosion_sfx,
        "electric.wav": electric_sfx,
        "pickup.wav": pickup_sfx,
        "shot_pistol.wav": shot_pistol,
        "shot_shotgun.wav": shot_shotgun,
        "shot_assault.wav": shot_assault,
        "shot_sniper.wav": shot_sniper,
        "shot_mg.wav": shot_mg,
        "shot_flame.wav": shot_flame,
        "shot_taser.wav": shot_taser,
        "shot_emp.wav": shot_emp,
        "reload_pistol.wav": reload_pistol,
        "reload_shotgun.wav": reload_shotgun,
        "reload_rifle.wav": reload_rifle,
        "reload_heavy.wav": reload_heavy,
        "reload_energy.wav": reload_energy,
    }
    for name, fn in common.items():
        write_wav(name, fn())
    print("done (sfx only; bgm stays at assets/bgm/arena.wav)")


if __name__ == "__main__":
    main()
