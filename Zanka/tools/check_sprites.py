#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""立绘裁切检测：找出「身体被画面边缘切掉」的图。

最典型的症状是头顶被切平——SD 画半身像时经常把人物放得太大，头发顶到画布边缘。
检测方式：看四条边上有多少不透明像素。正常构图的立绘，顶边应该是全透明的。

用法：
  python3 check_sprites.py            # 检查 assets/char/
  python3 check_sprites.py --json     # 机器可读输出
"""
import argparse
import io
import json
import os
import struct
import sys
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CHAR_DIR = os.path.join(ROOT, "assets/char")

# 判定阈值：某条边上有超过这么多不透明像素，就算被切
# 下边不算错：立绘是半身像，本来就在腰部裁断，而且会被对话框盖住
EDGE_TOL = {"top": 20, "left": 80, "right": 80}   # 顶边最要紧；侧边允许少量发丝出画


def read_rgba(path):
    d = open(path, "rb").read()
    if d[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    pos, w, h, ct, idat = 8, 0, 0, 0, b""
    while pos < len(d):
        ln = struct.unpack(">I", d[pos:pos + 4])[0]
        tag = d[pos + 4:pos + 8]
        body = d[pos + 8:pos + 8 + ln]
        if tag == b"IHDR":
            w, h, bd, ct = struct.unpack(">IIBB", body[:10])
        elif tag == b"IDAT":
            idat += body
        pos += 12 + ln
    if ct != 6:
        return None
    raw = zlib.decompress(idat)
    stride = w * 4
    out = bytearray(w * h * 4)
    prev = bytearray(stride)
    p = 0
    for y in range(h):
        f = raw[p]
        p += 1
        line = bytearray(raw[p:p + stride])
        p += stride
        if f == 1:
            for i in range(4, stride):
                line[i] = (line[i] + line[i - 4]) & 255
        elif f == 2:
            for i in range(stride):
                line[i] = (line[i] + prev[i]) & 255
        elif f == 3:
            for i in range(stride):
                a = line[i - 4] if i >= 4 else 0
                line[i] = (line[i] + ((a + prev[i]) >> 1)) & 255
        elif f == 4:
            for i in range(stride):
                a = line[i - 4] if i >= 4 else 0
                b = prev[i]
                c = prev[i - 4] if i >= 4 else 0
                pp = a + b - c
                pa, pb, pc = abs(pp - a), abs(pp - b), abs(pp - c)
                pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                line[i] = (line[i] + pr) & 255
        out[y * stride:(y + 1) * stride] = line
        prev = line
    return w, h, out


def edge_counts(w, h, px):
    opaque = lambda i: 1 if px[i * 4 + 3] > 120 else 0
    return {
        "top": sum(opaque(x) for x in range(w)),
        "bottom": sum(opaque((h - 1) * w + x) for x in range(w)),
        "left": sum(opaque(y * w) for y in range(h)),
        "right": sum(opaque(y * w + w - 1) for y in range(h)),
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--dir", default=CHAR_DIR)
    args = ap.parse_args()

    files = sorted(f for f in os.listdir(args.dir) if f.endswith(".png"))
    report = []
    for f in files:
        p = os.path.join(args.dir, f)
        r = read_rgba(p)
        if r is None:
            continue
        w, h, px = r
        ec = edge_counts(w, h, px)
        bad = [e for e, tol in EDGE_TOL.items() if ec[e] > tol]
        report.append({"file": f, "id": f[:-4], "edges": ec, "bad": bad})

    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=1))
        return 0

    print("%-34s %6s %6s %6s %6s   判定" % ("文件", "上", "下", "左", "右"))
    bad_list = []
    for r in report:
        e = r["edges"]
        verdict = "OK" if not r["bad"] else ("被切: " + ",".join(r["bad"]))
        if r["bad"]:
            bad_list.append(r["id"])
        print("%-34s %6d %6d %6d %6d   %s"
              % (r["id"], e["top"], e["bottom"], e["left"], e["right"], verdict))
    print()
    if bad_list:
        print("需要重画的 %d 张：%s" % (len(bad_list), ", ".join(bad_list)))
        print("单独重画：python3 tools/gen_assets.py --only <id> --force")
    else:
        print("全部 %d 张构图正常。" % len(report))
    return 0


if __name__ == "__main__":
    sys.exit(main())
