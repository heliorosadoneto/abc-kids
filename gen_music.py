"""Gera a música de fundo (caixinha de música + pizzicato), 100% sintetizada. Loop perfeito."""
import numpy as np, wave, random
SR = 44100; BPM = 100; beat = 60 / BPM
bars = 32; total = int(SR * beat * 4 * bars)
out = np.zeros(total)
random.seed(4)

def f(n): return 440 * 2 ** ((n - 69) / 12)

def musicbox(n, dur=1.6, vol=0.22):
    t = np.arange(int(SR * dur)) / SR
    fr = f(n)
    s = (np.sin(2*np.pi*fr*t) + 0.35*np.sin(2*np.pi*fr*3.01*t)*np.exp(-t*9) + 0.15*np.sin(2*np.pi*fr*5.4*t)*np.exp(-t*16))
    env = np.exp(-t * 3.2) * np.minimum(1, t / 0.004)
    return s * env * vol

def pluck(n, dur=0.9, vol=0.18):
    fr = f(n); N = int(SR / fr)
    buf = np.random.uniform(-1, 1, N); res = np.zeros(int(SR * dur))
    for i in range(len(res)):
        res[i] = buf[i % N]
        buf[i % N] = 0.497 * (buf[i % N] + buf[(i + 1) % N])
    return res * vol

def add(sig, at):
    i = int(at * SR)
    for k in range(len(sig)):
        out[(i + k) % total] += sig[k]  # cauda volta ao início = loop sem emenda

# progressão I-V-vi-IV em Dó (alegre)
chords = [[60, 64, 67], [55, 59, 62], [57, 60, 64], [53, 57, 60]]
scale = [72, 74, 76, 79, 81, 84]
np.random.seed(1)
phrase = [[random.choice(scale) for _ in range(8)] for _ in range(4)]
for b in range(bars):
    ch = chords[b % 4]; t0 = b * 4 * beat
    # baixo pizzicato
    add(pluck(ch[0] - 12, 1.2, 0.22), t0)
    add(pluck(ch[0] - 5, 1.0, 0.15), t0 + 2 * beat)
    # arpejo suave
    for i, n in enumerate([ch[0], ch[1], ch[2], ch[1]]):
        add(pluck(n, 0.7, 0.07), t0 + i * beat + beat / 2)
    # melodia de caixinha de música (frases repetidas, variação a cada 8 compassos)
    mel = phrase[(b // 2) % 4] if (b // 8) % 2 == 0 else phrase[(b // 2 + 1) % 4]
    for i in range(4):
        n = mel[(b % 2) * 4 + i]
        if (b * 4 + i) % 7 == 6: continue
        add(musicbox(n), t0 + i * beat)
    if b % 4 == 3: add(musicbox(84, 2.5, 0.12), t0 + 3.5 * beat)

out /= np.max(np.abs(out)) * 1.15
pcm = (out * 32767).astype(np.int16)
with wave.open('/tmp/music.wav', 'wb') as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())
print(total / SR)
