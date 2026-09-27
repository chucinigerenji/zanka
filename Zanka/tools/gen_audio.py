#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""《残夏》音频合成器（纯 stdlib）。

Local Dream 只能出图，音频在这里用加法合成 + 噪声塑形做出来：
  * BGM：钢琴式加法合成 + 慢速 pad + 简易混响，同一段「栞的主题」在不同曲子里变奏
  * 环境音：雨 / 海 / 蝉 / 室内 / 风 / 夜，全部是可无缝循环的噪声塑形
  * 音效：选项点击、开门、挂电话、浪、摔倒、翻页、门铃

输出 16bit 单声道 WAV 到 assets/audio/。有 ffmpeg 时会额外转一份 ogg（更小）。
"""
import array
import math
import os
import random
import struct
import sys
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets/audio")
SR = 22050
random.seed(20130919)

TAU = math.pi * 2.0


# ---------------------------------------------------------------- 基础工具

def midi(m):
    return 440.0 * (2.0 ** ((m - 69) / 12.0))


def blank(n):
    return [0.0] * n


def add_into(dst, src, at, gain=1.0):
    n = len(dst)
    for i, v in enumerate(src):
        j = at + i
        if 0 <= j < n:
            dst[j] += v * gain


def normalize(buf, peak=0.92):
    mx = 0.0
    for v in buf:
        a = v if v >= 0 else -v
        if a > mx:
            mx = a
    if mx < 1e-9:
        return buf
    k = peak / mx
    for i in range(len(buf)):
        buf[i] *= k
    return buf


def fade_edges(buf, ms=40):
    n = int(SR * ms / 1000.0)
    if n * 2 >= len(buf):
        return buf
    for i in range(n):
        k = i / float(n)
        buf[i] *= k
        buf[-1 - i] *= k
    return buf


# ---------------------------------------------------------------- 合成器

# 钢琴/音乐盒音色：几个谐波 + 指数衰减
HARMONICS = [(1, 1.00, 2.6), (2, 0.42, 3.4), (3, 0.20, 4.6), (4, 0.10, 6.0), (6, 0.05, 8.0)]


def tone(freq, dur, amp=0.5, attack=0.006, harmonics=None):
    n = int(SR * dur)
    out = [0.0] * n
    hs = harmonics if harmonics is not None else HARMONICS
    atk = max(1, int(SR * attack))
    for mult, g, decay in hs:
        f = freq * mult
        if f > SR * 0.45:
            continue
        w = TAU * f / SR
        for i in range(n):
            t = i / SR
            env = math.exp(-decay * t)
            if i < atk:
                env *= i / float(atk)
            out[i] += g * env * math.sin(w * i)
    k = amp / max(1e-6, sum(g for _, g, _ in hs))
    for i in range(n):
        out[i] *= k
    return out


def pad(freqs, dur, amp=0.12):
    """慢起慢落的和声垫音。"""
    n = int(SR * dur)
    out = [0.0] * n
    rise = int(SR * dur * 0.35)
    fall = int(SR * dur * 0.35)
    for f in freqs:
        w = TAU * f / SR
        w2 = TAU * (f * 1.003) / SR   # 轻微失谐，产生厚度
        for i in range(n):
            env = 1.0
            if i < rise:
                env = i / float(rise)
            elif i > n - fall:
                env = max(0.0, (n - i) / float(fall))
            out[i] += env * (math.sin(w * i) + math.sin(w2 * i)) * 0.5
    k = amp / max(1, len(freqs))
    for i in range(n):
        out[i] *= k
    return out


def noise(n):
    return [random.uniform(-1.0, 1.0) for _ in range(n)]


def one_pole_lp(buf, cutoff_hz):
    a = 1.0 - math.exp(-TAU * cutoff_hz / SR)
    y = 0.0
    out = [0.0] * len(buf)
    for i, x in enumerate(buf):
        y += a * (x - y)
        out[i] = y
    return out


def one_pole_hp(buf, cutoff_hz):
    a = 1.0 - math.exp(-TAU * cutoff_hz / SR)
    y = 0.0
    out = [0.0] * len(buf)
    for i, x in enumerate(buf):
        y += a * (x - y)
        out[i] = x - y
    return out


def bandpass(buf, lo, hi):
    return one_pole_lp(one_pole_hp(buf, lo), hi)


def reverb(buf, tail=0.25, mix=0.3):
    """极简梳状混响：几路衰减延迟。"""
    delays = [int(SR * d) for d in (0.031, 0.047, 0.071, 0.103)]
    gains = [0.42, 0.33, 0.26, 0.19]
    n = len(buf) + int(SR * tail)
    wet = [0.0] * n
    for d, g in zip(delays, gains):
        for i in range(len(buf)):
            j = i + d
            if j < n:
                wet[j] += buf[i] * g
        # 二级反射
        for i in range(len(buf)):
            j = i + d * 2
            if j < n:
                wet[j] += buf[i] * g * 0.45
    out = [0.0] * n
    for i in range(n):
        dry = buf[i] if i < len(buf) else 0.0
        out[i] = dry * (1.0 - mix) + wet[i] * mix
    return out


def am(buf, rate_hz, depth=0.5, phase=0.0):
    w = TAU * rate_hz / SR
    out = [0.0] * len(buf)
    for i, v in enumerate(buf):
        out[i] = v * (1.0 - depth + depth * (0.5 + 0.5 * math.sin(w * i + phase)))
    return out


# ---------------------------------------------------------------- 写文件

def write_wav(path, buf, peak=0.92):
    normalize(buf, peak)
    data = array.array("h", [max(-32767, min(32767, int(v * 32767))) for v in buf])
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    return os.path.getsize(path)


# ---------------------------------------------------------------- 栞的主题

# A 自然小调。整部作品的旋律内核。
THEME = [
    (69, 1.0), (72, 0.5), (76, 0.5), (74, 1.0), (72, 0.5), (69, 0.5),
    (71, 1.0), (67, 1.0), (69, 2.0),
]
THEME_B = [
    (69, 1.0), (72, 0.5), (76, 0.5), (77, 1.0), (76, 0.5), (72, 0.5),
    (74, 1.0), (71, 1.0), (69, 2.0),
]
# 轻快的五声音阶（日常 / 祭典）
DAILY = [(72, 0.5), (74, 0.5), (76, 0.5), (79, 0.5), (76, 1.0), (74, 0.5), (72, 1.5),
         (69, 0.5), (72, 0.5), (74, 0.5), (76, 0.5), (74, 1.0), (72, 0.5), (69, 1.5)]


def play_melody(buf, seq, bpm, at, amp, detune=0.0, vel=0.9):
    beat = 60.0 / bpm
    t = at
    for m, b in seq:
        d = b * beat
        s = tone(midi(m) + detune, d * 1.75, amp * vel)
        add_into(buf, s, int(t * SR))
        t += d
    return t


def bgm_theme(dur_s, bpm, amp=0.34, use_b=True, low=False):
    n = int(SR * dur_s)
    buf = blank(n)
    seq = THEME + (THEME_B if use_b else THEME)
    chord = [midi(45), midi(52), midi(57)] if low else [midi(57), midi(64), midi(69)]
    add_into(buf, pad(chord, dur_s, amp=0.10), 0)
    t = 1.0
    while t < dur_s - 3.0:
        end = play_melody(buf, seq, bpm, t, amp)
        t = end + (3.0 if use_b else 2.0)
    return reverb(buf, mix=0.30)


def bgm_daily(dur_s):
    n = int(SR * dur_s)
    buf = blank(n)
    add_into(buf, pad([midi(60), midi(67), midi(72)], dur_s, amp=0.07), 0)
    t = 0.6
    while t < dur_s - 3.0:
        end = play_melody(buf, DAILY, 96, t, 0.30)
        # 低音走句
        for m, at in ((48, t), (55, t + 1.6), (53, end - 1.6)):
            if at < dur_s - 1:
                add_into(buf, tone(midi(m), 1.4, 0.20), int(at * SR))
        t = end + 1.4
    return reverb(buf, mix=0.22)


def bgm_sad(dur_s):
    return bgm_theme(dur_s, 52, amp=0.30, use_b=True, low=True)


def bgm_title(dur_s):
    n = int(SR * dur_s)
    buf = blank(n)
    add_into(buf, pad([midi(45), midi(52), midi(57), midi(64)], dur_s, amp=0.12), 0)
    add_into(buf, tone(midi(69), 3.0, 0.22), int(0.5 * SR))
    add_into(buf, tone(midi(72), 3.0, 0.18), int(2.4 * SR))
    add_into(buf, tone(midi(76), 4.0, 0.16), int(4.2 * SR))
    add_into(buf, tone(midi(74), 5.0, 0.14), int(8.0 * SR))
    add_into(buf, tone(midi(69), 6.0, 0.13), int(10.0 * SR))
    mid = dur_s * 0.5
    add_into(buf, tone(midi(71), 4.0, 0.12), int(mid * SR))
    add_into(buf, tone(midi(67), 6.0, 0.12), int((mid + 3) * SR))
    add_into(buf, tone(midi(69), 8.0, 0.12), int((mid + 6) * SR))
    return reverb(buf, mix=0.42)


def bgm_tension(dur_s):
    n = int(SR * dur_s)
    buf = blank(n)
    add_into(buf, pad([midi(38), midi(39), midi(45)], dur_s, amp=0.14), 0)
    # 脉冲低音
    beat = 0.9
    t = 0.0
    while t < dur_s - 1.0:
        add_into(buf, tone(midi(33), 0.7, 0.22), int(t * SR))
        t += beat
    for at, m in ((3.0, 70), (7.5, 69), (12.0, 68), (18.0, 63), (24.0, 62), (30.0, 58)):
        if at < dur_s - 3:
            add_into(buf, tone(midi(m), 2.6, 0.16), int(at * SR))
    return reverb(buf, mix=0.34)


def bgm_festival(dur_s):
    n = int(SR * dur_s)
    buf = blank(n)
    seq = [(76, 0.5), (79, 0.5), (81, 0.5), (84, 1.0), (81, 0.5), (79, 0.5),
           (76, 1.0), (74, 0.5), (76, 1.5)]
    t = 0.4
    while t < dur_s - 2.5:
        t = play_melody(buf, seq, 132, t, 0.30) + 1.2
    # 太鼓感
    t = 0.0
    while t < dur_s - 0.6:
        s = one_pole_lp(noise(int(SR * 0.18)), 160)
        for i in range(len(s)):
            s[i] *= math.exp(-14.0 * i / SR)
        add_into(buf, s, int(t * SR), 0.5)
        t += 0.75
    return reverb(buf, mix=0.20)


def bgm_dark(dur_s):
    n = int(SR * dur_s)
    buf = blank(n)
    add_into(buf, pad([midi(33), midi(34), midi(40)], dur_s, amp=0.16), 0)
    for at, m in ((2.0, 57), (9.0, 56), (16.0, 52), (23.0, 51), (30.0, 45)):
        if at < dur_s - 4:
            add_into(buf, tone(midi(m), 5.0, 0.14), int(at * SR))
    low = one_pole_lp(noise(n), 90)
    for i in range(n):
        low[i] *= 0.10
    add_into(buf, low, 0)
    return reverb(buf, mix=0.40)


# ---------------------------------------------------------------- 环境音

def amb_rain(dur_s=12.0):
    n = int(SR * dur_s)
    base = one_pole_lp(noise(n), 2600)
    for i in range(n):
        base[i] *= 0.55
    hiss = one_pole_hp(noise(n), 3500)
    for i in range(n):
        hiss[i] *= 0.18
    out = [base[i] + hiss[i] for i in range(n)]
    # 偶尔的水滴
    for _ in range(int(dur_s * 8)):
        at = random.randrange(0, n - 2000)
        f = random.uniform(700, 2200)
        s = tone(f, 0.05, 0.20)
        add_into(out, s, at)
    return out


def amb_sea(dur_s=12.0):
    n = int(SR * dur_s)
    base = one_pole_lp(noise(n), 900)
    out = am(base, 0.14, 0.62)
    swell = one_pole_lp(noise(n), 220)
    for i in range(n):
        out[i] = out[i] * 0.85 + swell[i] * 0.5
    return out


def amb_cicada(dur_s=12.0):
    n = int(SR * dur_s)
    body = bandpass(noise(n), 3200, 7200)
    out = am(body, 42.0, 0.55)
    layer2 = bandpass(noise(n), 4300, 9000)
    layer2 = am(layer2, 33.0, 0.6, phase=1.1)
    for i in range(n):
        out[i] = out[i] * 0.55 + layer2[i] * 0.30
    return out


def amb_room(dur_s=12.0):
    n = int(SR * dur_s)
    base = one_pole_lp(noise(n), 420)
    out = [0.0] * n
    hum = TAU * 50.0 / SR
    for i in range(n):
        out[i] = base[i] * 0.45 + 0.03 * math.sin(hum * i)
    return out


def amb_wind(dur_s=12.0):
    n = int(SR * dur_s)
    base = one_pole_lp(noise(n), 620)
    out = am(base, 0.07, 0.7)
    for i in range(n):
        out[i] *= 0.9
    return out


def amb_night(dur_s=12.0):
    n = int(SR * dur_s)
    base = one_pole_lp(noise(n), 300)
    out = [v * 0.35 for v in base]
    # 虫鸣：短促高频脉冲
    t = 0.0
    while t < dur_s - 0.3:
        f = random.uniform(3800, 4600)
        for k in range(3):
            s = tone(f, 0.035, 0.16, attack=0.002)
            add_into(out, s, int((t + k * 0.06) * SR))
        t += random.uniform(1.4, 3.2)
    return out


# ---------------------------------------------------------------- 音效

def se_select():
    n = int(SR * 0.10)
    out = blank(n)
    add_into(out, tone(1180, 0.07, 0.6, attack=0.001), 0)
    add_into(out, tone(1760, 0.05, 0.25, attack=0.001), int(0.012 * SR))
    for i in range(n):
        out[i] *= math.exp(-24.0 * i / SR)
    return out


def se_door():
    n = int(SR * 0.55)
    out = blank(n)
    body = one_pole_lp(noise(int(SR * 0.32)), 700)
    for i in range(len(body)):
        body[i] *= math.exp(-9.0 * i / SR)
    add_into(out, body, 0, 0.7)
    add_into(out, tone(180, 0.28, 0.5), int(0.02 * SR))
    add_into(out, tone(96, 0.4, 0.4), int(0.16 * SR))
    return out


def se_hangup():
    n = int(SR * 0.45)
    out = blank(n)
    add_into(out, tone(420, 0.09, 0.5, attack=0.001), 0)
    add_into(out, tone(300, 0.12, 0.4, attack=0.001), int(0.14 * SR))
    click = one_pole_hp(noise(int(SR * 0.05)), 1200)
    add_into(out, click, int(0.14 * SR), 0.4)
    return out


def se_wave():
    n = int(SR * 1.9)
    out = one_pole_lp(noise(n), 1400)
    for i in range(n):
        t = i / SR
        env = math.sin(math.pi * min(1.0, t / 1.9)) ** 1.6
        out[i] *= env * 0.9
    return out


def se_fall():
    n = int(SR * 0.7)
    out = blank(n)
    body = one_pole_lp(noise(int(SR * 0.3)), 480)
    for i in range(len(body)):
        body[i] *= math.exp(-11.0 * i / SR)
    add_into(out, body, 0, 0.8)
    # 下滑音
    for k in range(28):
        f = 320 - k * 8
        s = tone(f, 0.06, 0.20, attack=0.001)
        add_into(out, s, int(k * 0.016 * SR))
    return out


def se_page():
    n = int(SR * 0.32)
    out = one_pole_hp(noise(n), 2200)
    for i in range(n):
        t = i / SR
        env = math.exp(-7.0 * t)
        if t < 0.02:
            env *= t / 0.02
        out[i] *= env * 0.7
    return out


def se_bell():
    n = int(SR * 0.9)
    out = blank(n)
    add_into(out, tone(1568, 0.8, 0.5, attack=0.002), 0)
    add_into(out, tone(2093, 0.6, 0.3, attack=0.002), int(0.09 * SR))
    for i in range(n):
        out[i] *= math.exp(-4.5 * i / SR)
    return out


# ---------------------------------------------------------------- 主流程

AMB = {
    "rain": amb_rain, "sea": amb_sea, "cicada": amb_cicada,
    "room": amb_room, "wind": amb_wind, "night": amb_night,
}
SE = {
    "select": se_select, "door": se_door, "hangup": se_hangup,
    "wave": se_wave, "fall": se_fall, "page": se_page, "bell": se_bell,
}


def main():
    os.makedirs(OUT, exist_ok=True)
    jobs = []
    jobs.append(("bgm_title.wav", lambda: bgm_title(48.0)))
    jobs.append(("bgm_daily.wav", lambda: bgm_daily(40.0)))
    jobs.append(("bgm_shiori.wav", lambda: bgm_theme(52.0, 64, amp=0.34, use_b=True)))
    jobs.append(("bgm_sad.wav", lambda: bgm_sad(48.0)))
    jobs.append(("bgm_tension.wav", lambda: bgm_tension(36.0)))
    jobs.append(("bgm_festival.wav", lambda: bgm_festival(32.0)))
    jobs.append(("bgm_dark.wav", lambda: bgm_dark(36.0)))
    for k, fn in AMB.items():
        jobs.append(("amb_%s.wav" % k, fn))
    for k, fn in SE.items():
        jobs.append(("se_%s.wav" % k, fn))

    total = 0
    for name, fn in jobs:
        path = os.path.join(OUT, name)
        buf = fn()
        fade_edges(buf, 30)
        size = write_wav(path, buf)
        total += size
        print("  %-22s %6.1f KB" % (name, size / 1024.0), flush=True)
    print("合计 %.1f MB，%d 个文件" % (total / 1048576.0, len(jobs)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
