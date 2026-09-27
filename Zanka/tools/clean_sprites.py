#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""立绘 alpha 后处理：清掉背景里的孤立色块。

为什么需要：
  抠图用的是「从四边洪水填充吃掉接近底色的像素」。如果模型在纯色背景里
  又画了一个独立的漂浮物（残影、误画的球拍/水花之类），它颜色不接近底色，
  洪水绕过去，就会原样留在立绘上。这里把不透明的连通域做一遍标记，
  只保留「最大的那一块 + 与它包围盒相交的块」，其余丢弃。

用法：
  python3 clean_sprites.py                 # 处理 assets/char/*.png
  python3 clean_sprites.py --dry-run       # 只报告，不写回
"""
import argparse
import io
import os
import struct
import sys
import zlib
from collections import deque

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CHAR_DIR = os.path.join(ROOT, "assets/char")


# ---------------------------------------------------------------- PNG 读写

def read_rgba(path):
    d = open(path, "rb").read()
    assert d[:8] == b"\x89PNG\r\n\x1a\n", "不是 PNG"
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


def write_rgba(path, w, h, px):
    def chunk(tag, body):
        c = tag + body
        return struct.pack(">I", len(body)) + c + struct.pack(">I", zlib.crc32(c) & 0xFFFFFFFF)
    stride = w * 4
    rows = b"".join(b"\x00" + bytes(px[y * stride:(y + 1) * stride]) for y in range(h))
    png = (b"\x89PNG\r\n\x1a\n"
           + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
           + chunk(b"IDAT", zlib.compress(rows, 6))
           + chunk(b"IEND", b""))
    tmp = path + ".tmp"
    open(tmp, "wb").write(png)
    os.replace(tmp, path)


# ---------------------------------------------------------------- 孤岛清除

def clean(w, h, px, alpha_th=100, pad=10):
    n = w * h
    opaque = bytearray(n)
    for i in range(n):
        if px[i * 4 + 3] > alpha_th:
            opaque[i] = 1

    labels = [0] * n
    comps = []
    cid = 0
    for start in range(n):
        if not opaque[start] or labels[start]:
            continue
        cid += 1
        dq = deque([start])
        labels[start] = cid
        area = 0
        minx, miny, maxx, maxy = w, h, -1, -1
        while dq:
            q = dq.popleft()
            area += 1
            x = q % w
            y = q // w
            if x < minx:
                minx = x
            if x > maxx:
                maxx = x
            if y < miny:
                miny = y
            if y > maxy:
                maxy = y
            for j in (q - 1 if x > 0 else -1,
                      q + 1 if x < w - 1 else -1,
                      q - w if q >= w else -1,
                      q + w if q < n - w else -1):
                if j >= 0 and opaque[j] and not labels[j]:
                    labels[j] = cid
                    dq.append(j)
        comps.append({"id": cid, "area": area, "box": (minx, miny, maxx, maxy)})

    if not comps:
        return 0, 0
    main = max(comps, key=lambda c: c["area"])
    mx0, my0, mx1, my1 = main["box"]
    # 太小的碎片一律丢掉：形态学处理会在人物周围留下散点噪点
    min_area = max(24, int(w * h * 0.0008))
    keep = {main["id"]}
    for c in comps:
        if c["id"] == main["id"]:
            continue
        if c["area"] < min_area:
            continue
        x0, y0, x1, y1 = c["box"]
        if not (x1 < mx0 - pad or x0 > mx1 + pad or y1 < my0 - pad or y0 > my1 + pad):
            keep.add(c["id"])

    removed = 0
    for i in range(n):
        lab = labels[i]
        if lab and lab not in keep:
            px[i * 4 + 3] = 0
            removed += 1
    dropped = len(comps) - len(keep)
    return dropped, removed


# ---------------------------------------------------------------- 自动裁边

def autocrop(w, h, px, pad=8, alpha_th=100):
    """裁到不透明内容的包围盒（留 pad 边距）。

    为什么需要：SD 每次给的人物大小不一样（有的占满画布，有的缩在中间）。
    游戏里立绘按屏幕高度缩放，不裁的话同一角色不同表情会一大一小。
    """
    minx, miny, maxx, maxy = w, h, -1, -1
    for y in range(h):
        row = y * w
        for x in range(w):
            if px[(row + x) * 4 + 3] > alpha_th:
                if x < minx:
                    minx = x
                if x > maxx:
                    maxx = x
                if y < miny:
                    miny = y
                if y > maxy:
                    maxy = y
    if maxx < 0:
        return w, h, px, False
    x0 = max(0, minx - pad)
    y0 = max(0, miny - pad)
    x1 = min(w - 1, maxx + pad)
    y1 = min(h - 1, maxy + pad)
    nw = x1 - x0 + 1
    nh = y1 - y0 + 1
    if nw == w and nh == h:
        return w, h, px, False
    out = bytearray(nw * nh * 4)
    for y in range(nh):
        src = ((y0 + y) * w + x0) * 4
        dst = y * nw * 4
        out[dst:dst + nw * 4] = px[src:src + nw * 4]
    return nw, nh, out, True


# ---------------------------------------------------------------- 补洞

def fill_holes(w, h, px, alpha_th=120, max_ratio=0.05):
    """把「封闭的透明区域」补回不透明。

    抠图偶尔会啃进人物（浅色衣服和背景同色时），在角色身上留下洞。
    这些洞的特征是：**不与画面边缘连通**。
    补洞时限制面积（默认 5%），避免把「手叉腰形成的背景缝隙」也一起填掉。
    """
    n = w * h
    trans = bytearray(n)
    for i in range(n):
        if px[i * 4 + 3] <= alpha_th:
            trans[i] = 1

    outside = bytearray(n)
    stack = []
    for x in range(w):
        for idx in (x, (h - 1) * w + x):
            if trans[idx] and not outside[idx]:
                outside[idx] = 1
                stack.append(idx)
    for y in range(h):
        for idx in (y * w, y * w + w - 1):
            if trans[idx] and not outside[idx]:
                outside[idx] = 1
                stack.append(idx)
    while stack:
        q = stack.pop()
        x = q % w
        for r in ((q - 1 if x > 0 else -1),
                  (q + 1 if x < w - 1 else -1),
                  (q - w if q >= w else -1),
                  (q + w if q < n - w else -1)):
            if r >= 0 and trans[r] and not outside[r]:
                outside[r] = 1
                stack.append(r)

    limit = int(n * max_ratio)
    seen = bytearray(n)
    filled = 0
    for start in range(n):
        if not trans[start] or outside[start] or seen[start]:
            continue
        comp = []
        dq = deque([start])
        seen[start] = 1
        while dq:
            q = dq.popleft()
            comp.append(q)
            if len(comp) > limit:
                break
            x = q % w
            for r in ((q - 1 if x > 0 else -1),
                      (q + 1 if x < w - 1 else -1),
                      (q - w if q >= w else -1),
                      (q + w if q < n - w else -1)):
                if r >= 0 and trans[r] and not outside[r] and not seen[r]:
                    seen[r] = 1
                    dq.append(r)
        if len(comp) <= limit:
            for q in comp:
                px[q * 4 + 3] = 255
            filled += len(comp)
    return filled


# ---------------------------------------------------------------- 削边

def erode_alpha(w, h, px, r=2, alpha_th=120):
    """把不透明区域收缩 r 像素。

    抠图后人物轮廓外常留一圈灰色的抗锯齿晕（背景色和人物色混合的像素），
    它在游戏里就是用户看到的「灰边」。收缩 1~2 像素即可削掉，代价是人物略瘦一圈。
    """
    n = w * h
    cur = bytearray(1 if px[i * 4 + 3] > alpha_th else 0 for i in range(n))
    for _ in range(r):
        nxt = bytearray(n)
        for y in range(h):
            row = y * w
            for x in range(w):
                if not cur[row + x]:
                    continue
                if ((x > 0 and not cur[row + x - 1]) or
                        (x < w - 1 and not cur[row + x + 1]) or
                        (y > 0 and not cur[row - w + x]) or
                        (y < h - 1 and not cur[row + w + x])):
                    continue
                nxt[row + x] = 1
        cur = nxt
    removed = 0
    for i in range(n):
        if px[i * 4 + 3] > alpha_th and not cur[i]:
            px[i * 4 + 3] = 0
            removed += 1
    return removed


def strip_clean(w, h, px, tol=26, max_frac=0.2, alpha_th=120):
    """清除贴着画面边缘的「均匀色带」。

    模型有时会把背景画成两块色（例如左边一条灰、其余是黑），
    全局参考色只认了主流那一块，另一块就整条留在立绘上。
    做法：从每条边往里走，只要颜色和边缘像素足够接近就继续走，
    一旦遇到明显色差（人物轮廓）就停。只会删「从边缘延伸进来的均匀带」，很安全。
    """
    n = w * h
    bg = bytearray(n)
    maxw = int(w * max_frac)
    maxh = int(h * max_frac)

    def close(i, j):
        o1, o2 = i * 4, j * 4
        return (abs(px[o1] - px[o2]) + abs(px[o1 + 1] - px[o2 + 1]) + abs(px[o1 + 2] - px[o2 + 2])) < tol * 3

    # 左右
    for y in range(h):
        row = y * w
        for x in range(1, maxw):
            if not close(row + x, row):
                break
            bg[row + x] = 1
        for x in range(1, maxw):
            if not close(row + w - 1 - x, row + w - 1):
                break
            bg[row + w - 1 - x] = 1
    # 上下
    for x in range(w):
        for y in range(1, maxh):
            if not close(y * w + x, x):
                break
            bg[y * w + x] = 1
        for y in range(1, maxh):
            if not close((h - 1 - y) * w + x, (h - 1) * w + x):
                break
            bg[(h - 1 - y) * w + x] = 1

    removed = 0
    for i in range(n):
        if bg[i] and px[i * 4 + 3] > alpha_th:
            px[i * 4 + 3] = 0
            removed += 1
    return removed


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--dir", default=CHAR_DIR)
    ap.add_argument("--no-crop", action="store_true", help="只清孤岛，不裁边")
    ap.add_argument("--no-fill", action="store_true", help="不补洞")
    ap.add_argument("--erode", type=int, default=0, help="轮廓收缩像素数（削掉背景灰边）")
    args = ap.parse_args()

    files = sorted(f for f in os.listdir(args.dir) if f.endswith(".png"))
    if not files:
        print("!! %s 下没有 PNG" % args.dir)
        return 1
    total_removed = 0
    for f in files:
        p = os.path.join(args.dir, f)
        r = read_rgba(p)
        if r is None:
            print("  %-44s 跳过（不是 RGBA）" % f)
            continue
        w, h, px = r
        stripped = strip_clean(w, h, px)
        eroded = erode_alpha(w, h, px, args.erode) if args.erode > 0 else 0
        filled = 0
        if not args.no_fill:
            filled = fill_holes(w, h, px)
        dropped, removed = clean(w, h, px)
        total_removed += removed
        nw, nh, npx, cropped = (w, h, px, False)
        if not args.no_crop:
            nw, nh, npx, cropped = autocrop(w, h, px)
        if not args.dry_run and (removed or cropped or filled):
            write_rgba(p, nw, nh, npx)
        print("  %-32s 边带 %5d 削边 %4d 补洞 %4d 孤岛 %3d 裁边 %s (%dx%d->%dx%d)"
              % (f, stripped, eroded, filled, dropped, "是" if cropped else "否", w, h, nw, nh))
    print("合计清除 %d 像素%s" % (total_removed, "（dry-run 未写回）" if args.dry_run else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
