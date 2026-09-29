#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""UI 设计稿渲染器。

为什么要它
----------
《残夏》的 UI **全部由 GDScript 在运行时构建**（工程里只有一个 6 行的 .tscn），
所以没有 Godot 运行环境时，任何 UI 改动都是「盲改」。
这个脚本用**项目真实的字体、背景图、立绘**，把 scripts/core/ui_theme.gd 里的
设计令牌与 scripts/ui/*.gd 里的几何参数按同一套几何渲染成 PNG，
只替换设计变量，用来快速迭代界面（渲染 → 看 → 调，几秒钟一轮）。

它与真机的关系
--------------
它是**设计稿**，不是引擎截图：字体度量、容器自动布局会有像素级出入。
最终仍需在 Godot 里 F5 实跑确认（尤其换行与动态尺寸）。

用法
----
    python3 tools/ui_mockup.py                  # 全部画面，当前设计
    python3 tools/ui_mockup.py --variant all    # 全部画面，所有方案都出
    python3 tools/ui_mockup.py --variant paper  # 只出新方案
    python3 tools/ui_mockup.py --outdir tools/_ui
"""
import argparse
import os

from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W, H = 1280, 720
SANS = os.path.join(ROOT, "assets/ui/ZankaSans.otf")
SERIF = os.path.join(ROOT, "assets/ui/ZankaSerif.otf")
BG_DIR = os.path.join(ROOT, "assets/bg")
CHAR_DIR = os.path.join(ROOT, "assets/char")

_fc = {}


def font(path, size):
    k = (path, size)
    if k not in _fc:
        _fc[k] = ImageFont.truetype(path, size)
    return _fc[k]


def rgba(c):
    """浮点 (r,g,b[,a]) -> 0-255 元组。"""
    if len(c) == 3:
        c = (c[0], c[1], c[2], 1.0)
    return tuple(max(0, min(255, int(v * 255))) for v in c)


def over(c, a):
    """把颜色 c 的 alpha 覆盖为 a。"""
    return (c[0], c[1], c[2], a)


# ----------------------------------------------------------------- 设计令牌
CURRENT = {
    "key": "current",
    "text": (0.910, 0.898, 0.867),
    "dim": (0.635, 0.655, 0.690),
    "accent": (0.788, 0.541, 0.365),
    "paper": (0.937, 0.914, 0.863),
    "box": (0.043, 0.051, 0.071, 0.880),
    "box_soft": (0.078, 0.086, 0.114, 0.900),
    "line": (0.596, 0.624, 0.686, 0.400),
    "line_soft": (0.596, 0.624, 0.686, 0.180),
    "hilite": (0.878, 0.639, 0.451),
    "dbox_bg": (0.031, 0.039, 0.055, 0.900),
    "dbox_edge": (0.788, 0.541, 0.365, 0.450),
    "dbox_radius": 12,
    "dbox_edge_w": 2,
    "dbox_text": (0.910, 0.898, 0.867),
    "hud_bg": (0.031, 0.039, 0.055, 0.660),
    "plate_bg": (0.078, 0.086, 0.114, 0.960),
    "plate_text": None,           # None = 用角色名牌配色
    "btn_bg": (0.098, 0.106, 0.137, 0.860),
    "btn_edge": (0.596, 0.624, 0.686, 0.180),
    "btn_text": (0.910, 0.898, 0.867),
    "btn_radius": 8,
    "panel_bg": (0.043, 0.051, 0.071, 0.975),
    "panel_text": (0.937, 0.914, 0.863),
    "dim_overlay": (0.020, 0.024, 0.035, 0.760),
    "hairline": (0.596, 0.624, 0.686, 0.180),
    "shadow": 0,                  # 0 = 无投影
    "btn_style": "box",
    "dbox_top": -252,
    "dbox_bottom": -22,
}

# 新方案：和纸 / 褪色（对齐企划 05「纸质质感、褪色商店街配色、低饱和暖灰」）
PAPER = {
    "key": "paper",
    "text": (0.153, 0.137, 0.125),          # 墨
    "dim": (0.443, 0.412, 0.376),           # 淡墨
    "accent": (0.643, 0.208, 0.145),        # 朱
    "paper": (0.969, 0.957, 0.929),         # 和纸
    "box": (0.969, 0.957, 0.929, 0.930),
    "box_soft": (0.941, 0.925, 0.890, 0.960),
    "line": (0.298, 0.263, 0.227, 0.300),
    "line_soft": (0.298, 0.263, 0.227, 0.140),
    "hilite": (0.643, 0.208, 0.145),
    "dbox_bg": (0.976, 0.965, 0.941, 0.928),
    "dbox_edge": (0.643, 0.208, 0.145, 1.000),
    "dbox_radius": 3,
    "dbox_edge_w": 3,
    "dbox_text": (0.153, 0.137, 0.125),
    "hud_bg": (0.976, 0.965, 0.941, 0.780),
    "plate_bg": (0.180, 0.161, 0.145, 0.960),
    "plate_text": (0.969, 0.957, 0.929),
    "btn_bg": (0.976, 0.965, 0.941, 0.300),
    "btn_edge": (0.298, 0.263, 0.227, 0.260),
    "btn_text": (0.153, 0.137, 0.125),
    "btn_radius": 2,
    "panel_bg": (0.976, 0.965, 0.941, 0.982),
    "panel_text": (0.153, 0.137, 0.125),
    "dim_overlay": (0.098, 0.086, 0.075, 0.660),
    "hairline": (0.298, 0.263, 0.227, 0.200),
    "shadow": 16,
    "btn_style": "row",
    "dbox_top": -218,
    "dbox_bottom": -28,
}

FROSTED = {
    "key": "frosted",
    "text": (0.145, 0.129, 0.118),          # 墨
    "dim": (0.420, 0.390, 0.360),
    "accent": (0.643, 0.208, 0.145),        # 朱
    "paper": (0.985, 0.976, 0.957),
    "box": (0.985, 0.976, 0.957, 0.820),
    "box_soft": (0.965, 0.953, 0.930, 0.860),
    "line": (1.0, 1.0, 1.0, 0.55),          # 玻璃亮边（高光），不再是深色线
    "line_soft": (1.0, 1.0, 1.0, 0.28),
    "hilite": (0.643, 0.208, 0.145),
    "dbox_bg": (0.985, 0.976, 0.957, 0.800),
    "dbox_edge": (0.643, 0.208, 0.145, 1.0),
    "dbox_radius": 18,
    "dbox_edge_w": 2,
    "dbox_text": (0.145, 0.129, 0.118),
    "hud_bg": (0.985, 0.976, 0.957, 0.620),
    "plate_bg": (0.145, 0.129, 0.118, 0.820),
    "plate_text": (0.985, 0.976, 0.957),
    "btn_bg": (1, 1, 1, 0.0),
    "btn_edge": (1, 1, 1, 0.0),
    "btn_text": (0.145, 0.129, 0.118),
    "btn_radius": 12,
    "panel_bg": (0.985, 0.976, 0.957, 0.840),
    "panel_text": (0.145, 0.129, 0.118),
    "dim_overlay": (0.130, 0.115, 0.100, 0.500),   # 黑幕更淡，透出背景
    "hairline": (0.145, 0.129, 0.118, 0.10),
    "shadow": 24,
    "btn_style": "pill",                    # 圆润软底，不再是一条条细线
    "dbox_top": -208,
    "dbox_bottom": -36,
}

VARIANTS = {"current": CURRENT, "paper": PAPER, "frosted": FROSTED}

# 角色名牌配色（char_db.gd COLORS）
NAME_COLORS = {
    "shiori": (0.85, 0.88, 0.95), "yuto": (0.86, 0.82, 0.74),
    "hitomi": (0.98, 0.80, 0.62), "fumi": (0.82, 0.84, 0.78),
    "chizuru": (0.78, 0.80, 0.86), "daikan": (0.80, 0.86, 0.82),
}


# ----------------------------------------------------------------- 基元

def cover(img, w, h):
    iw, ih = img.size
    s = max(w / iw, h / ih)
    img = img.resize((max(1, int(iw * s + 0.5)), max(1, int(ih * s + 0.5))), Image.LANCZOS)
    return img.crop(((img.width - w) // 2, (img.height - h) // 2,
                     (img.width - w) // 2 + w, (img.height - h) // 2 + h))


def drop_shadow(img, box, radius, spread, alpha=90):
    sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(sh)
    x0, y0, x1, y1 = box
    d.rounded_rectangle((x0 - spread, y0 - spread + 4, x1 + spread, y1 + spread + 4),
                        radius=radius + spread, fill=(0, 0, 0, alpha))
    img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(spread * 0.6)))


def panel(img, box, t, radius=None, fill=None, edge=None, w=1, shadow=None):
    radius = t["dbox_radius"] if radius is None else radius
    fill = t["box"] if fill is None else fill
    edge = t["line_soft"] if edge is None else edge
    sp = t["shadow"] if shadow is None else shadow
    if sp:
        drop_shadow(img, box, radius, sp)
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).rounded_rectangle(box, radius=radius,
                                           fill=rgba(fill), outline=rgba(edge), width=w)
    img.alpha_composite(layer)


def tw(draw, s, f):
    if not s:
        return 0, 0
    b = draw.textbbox((0, 0), s, font=f)
    return b[2] - b[0], b[3] - b[1]


def button(img, box, label, t, fsize=None, active=False, center=True, style=None):
    """按钮。style：
       box —— 现状的实底圆角块
       row —— 和纸方案：无框 + 底边细分隔线 + 悬停/选中时左侧朱色标记（像目录）
       text—— 纯文字 + 朱色下划线
    """
    fsize = fsize or 23
    f = font(SANS, fsize)
    style = style or t.get("btn_style", "box")
    d = ImageDraw.Draw(img)
    if style == "box":
        fill = t["btn_bg"]
        edge = t["btn_edge"]
        txt = t["btn_text"]
        if active:
            fill = over(t["accent"], 0.92)
            edge = over(t["accent"], 1.0)
            txt = (1.0, 0.99, 0.97)
        panel(img, box, t, radius=t["btn_radius"], fill=fill, edge=edge, w=1, shadow=0)
        w, h = tw(d, label, f)
        x = (box[0] + box[2]) / 2 if center else box[0] + 18
        d.text((x, (box[1] + box[3]) / 2), label, font=f, fill=rgba(txt), anchor="mm")
        return
    # row / text：先算文字位置
    x = (box[0] + box[2]) / 2 if center else box[0] + 22
    y = (box[1] + box[3]) / 2
    w, h = tw(d, label, f)
    if style == "row":
        # 普通态：只一条底分隔线；悬停/选中：白 10% 底 + 朱色左标记 + 朱色底线
        d.line((box[0], box[3] - 1, box[2], box[3] - 1), fill=rgba(t["line_soft"]), width=1)
        txt = t["btn_text"]
        if active:
            d.rectangle(box, fill=rgba((1.0, 0.99, 0.97, 0.10)))
            d.rectangle((box[0], box[1], box[0] + 4, box[3]), fill=rgba(t["accent"]))
            d.line((box[0], box[3] - 1, box[2], box[3] - 1), fill=rgba(t["accent"]), width=2)
    elif style == "pill":
        # 简洁方案：平时只有文字；选中/悬停时一块柔和圆底 + 圆头朱色短棒
        txt = t["btn_text"]
        if active:
            ov = Image.new("RGBA", img.size, (0, 0, 0, 0))
            ImageDraw.Draw(ov).rounded_rectangle(
                (box[0], box[1] + 2, box[2], box[3] - 2), radius=11,
                fill=rgba((1.0, 1.0, 1.0, 0.62)))
            img.alpha_composite(ov)
            d.rounded_rectangle((box[0] + 4, box[1] + 15, box[0] + 8, box[3] - 15),
                                radius=2, fill=rgba(t["accent"]))
    else:
        # HUD 小按钮：按下态是朱底纸字（对应 theme 的 pressed stylebox）
        txt = t["btn_text"]
        if active:
            d.rectangle((box[0], box[1] + 6, box[2], box[3] - 6), fill=rgba(t["accent"]))
            txt = (1.0, 0.99, 0.97)
    d.text((x, y), label, font=f, fill=rgba(txt), anchor="mm" if center else "lm")


# ----------------------------------------------------------------- 画面

def scene(bg_name, char_name=None, pos="c"):
    img = Image.new("RGBA", (W, H), rgba((0.043, 0.055, 0.078)))
    p = os.path.join(BG_DIR, bg_name + ".png")
    if os.path.exists(p):
        img.alpha_composite(cover(Image.open(p).convert("RGBA"), W, H))
    if char_name:
        cp = os.path.join(CHAR_DIR, char_name + ".png")
        if os.path.exists(cp):
            ch = Image.open(cp).convert("RGBA")
            sh, sw = H * 0.80, H * 0.80
            cx = W * {"l": 0.235, "c": 0.5, "r": 0.765}.get(pos, 0.5)
            k = min(sw / ch.width, sh / ch.height)
            ch = ch.resize((int(ch.width * k), int(ch.height * k)), Image.LANCZOS)
            img.alpha_composite(ch, (int(cx - ch.width / 2), int(H - sh + H * 0.02)))
    return img


def dialogue(img, t, speaker="三浦 栞", spk_id="shiori",
             line="（抬头，很快地把便当盒塞进书包）看海。"):
    """对应 scripts/ui/dialogue_box.gd。"""
    x0, x1 = 40, W - 40
    y0, y1 = H + t["dbox_top"], H + t["dbox_bottom"]
    panel(img, (x0, y0, x1, y1), t, radius=t["dbox_radius"], fill=t["dbox_bg"],
          edge=t["line_soft"], w=1)
    # 顶边强调线（现状是 accent 细线；新方案是朱色粗线 —— 和纸的“包边”）
    ImageDraw.Draw(img).line((x0 + t["dbox_radius"], y0, x1 - t["dbox_radius"], y0),
                             fill=rgba(t["dbox_edge"]), width=t["dbox_edge_w"])
    d = ImageDraw.Draw(img)
    f = font(SANS, 27)
    d.text((x0 + 36, y0 + 34), line, font=f, fill=rgba(t["dbox_text"]))
    # 名牌
    nf = font(SANS, 24)
    nw, nh = tw(d, speaker, nf)
    px0, py0 = x0 + 12, y0 - 46
    box = (px0, py0, px0 + nw + 44, py0 + nh + 20)
    panel(img, box, t, radius=4 if t["key"] == "paper" else 8,
          fill=t["plate_bg"], edge=t["line"], w=1, shadow=0)
    d = ImageDraw.Draw(img)
    color = t["plate_text"] or NAME_COLORS.get(spk_id, (0.9, 0.9, 0.9))
    d.text((px0 + 22, py0 + 10), speaker, font=nf, fill=rgba(color))
    # 续行指示
    d.text((x1 - 34, y1 - 30), "▼", font=font(SANS, 20), fill=rgba(t["hilite"]), anchor="mm")


def hud(img, t, chapter="序章　梅雨", cal="6/17　傍晚　潮 小潮（満潮18:42）",
        items=("回想", "自动", "跳过", "存档", "菜单")):
    """对应 scripts/ui/hud.gd。"""
    cf, lf = font(SANS, 21), font(SANS, 18)
    d = ImageDraw.Draw(img)
    cw, chh = tw(d, chapter, cf)
    lw, lh = tw(d, cal, lf)
    bw = max(cw, lw) + 36
    bh = 10 + chh + 4 + lh + 10
    box = (28, 22, 28 + bw, 22 + bh)
    panel(img, box, t, radius=t["dbox_radius"] if t["key"] == "paper" else 10,
          fill=t["hud_bg"], edge=t["line_soft"], w=1, shadow=0)
    d = ImageDraw.Draw(img)
    d.text((28 + 18, 22 + 10), chapter, font=cf, fill=rgba(t["paper"] if t["key"] == "current" else t["text"]))
    d.text((28 + 18, 22 + 10 + chh + 4), cal, font=lf, fill=rgba(t["dim"]))
    # 右上按钮
    bwid, bhgt, gap = 76, 42, 8
    total = len(items) * bwid + (len(items) - 1) * gap
    x = W - 28 - total
    for it in items:
        button(img, (x, 22, x + bwid, 22 + bhgt), it, t, fsize=19,
               active=(it == "自动"), style="text")
        x += bwid + gap


def choice(img, t, options=("「……你是打算把自己卖掉吗。」",
                            "「我来想办法。你一定要治。」",
                            "「……好。我听你的。」")):
    """对应 scripts/ui/choice_panel.gd。"""
    f = font(SANS, 24)
    d = ImageDraw.Draw(img)
    wid, hgt, gap = (660, 62, 4) if t["key"] != "frosted" else (640, 58, 6)
    pad = 30 if t["key"] == "current" else 34
    ph = pad * 2 + len(options) * hgt + (len(options) - 1) * gap
    pw = wid + pad * 2
    x0 = (W - pw) / 2
    y0 = (H - ph) / 2 - 40
    panel(img, (x0, y0, x0 + pw, y0 + ph), t,
          radius=(14 if t["key"] == "current" else (4 if t["key"] == "paper" else 18)),
          fill=t["box_soft"] if t["key"] == "current" else (0.976, 0.965, 0.941, 0.965),
          edge=t["line_soft"], w=1)
    y = y0 + pad
    for k, o in enumerate(options):
        button(img, (x0 + pad, y, x0 + pad + wid, y + hgt), o, t, fsize=24,
               center=False, active=(k == 0))
        y += hgt + gap


def chara_showcase(img, t, sprite="char_shiori_uniform_normal",
                   name="三浦 栞", line="点我一下，我会再说一句。"):
    """标题右侧的立绘轮播 + 聊天气泡（对应 scripts/ui/title_chara.gd）。"""
    d = ImageDraw.Draw(img)
    sh = H * 0.74
    cx = W * 0.76
    p = os.path.join(CHAR_DIR, sprite + ".png")
    drawn = (cx - sh / 2, H - sh, cx + sh / 2, H)
    if os.path.exists(p):
        ch = Image.open(p).convert("RGBA")
        k = min(sh / ch.width, sh / ch.height)
        ch = ch.resize((int(ch.width * k), int(ch.height * k)), Image.LANCZOS)
        px = int(cx - ch.width / 2)
        py = int(H - sh + (sh - ch.height) / 2)
        img.alpha_composite(ch, (px, py))
        drawn = (px, py, px + ch.width, py + ch.height)

    f, fn = font(SANS, 20), font(SANS, 16)
    bw = 310
    lines, cur = [], ""
    for c in line:
        if d.textlength(cur + c, font=f) > bw - 40:
            lines.append(cur)
            cur = c
        else:
            cur += c
    lines.append(cur)
    bh = 14 * 2 + 22 + 6 + len(lines) * 28
    bx = max(8, int(drawn[0]) + 4)
    by = max(8, int(drawn[1]) - bh - 8)
    panel(img, (bx, by, bx + bw, by + bh), t, radius=16,
          fill=(0.985, 0.976, 0.957, 0.880), edge=t["line"], w=1)
    d = ImageDraw.Draw(img)
    d.polygon([(bx + 26, by + bh - 2), (bx + 50, by + bh - 2), (bx + 31, by + bh + 17)],
              fill=rgba((0.985, 0.976, 0.957, 0.880)))
    d.text((bx + 20, by + 14), name, font=fn, fill=rgba(t["accent"]))
    yy = by + 14 + 22 + 6
    for ln in lines:
        d.text((bx + 20, yy), ln, font=f, fill=rgba(t["text"]))
        yy += 28


def title_screen(t):
    """对应 scripts/ui/title_screen.gd。"""
    img = Image.new("RGBA", (W, H), rgba((0.043, 0.055, 0.078)))
    p = os.path.join(BG_DIR, "bg_title.png")
    if os.path.exists(p):
        b = Image.open(p).convert("RGBA")
        b = b.resize((int(W * 1.04), int(H * 1.06)), Image.LANCZOS)
        img.alpha_composite(b.crop((int((b.width - W) / 2), int((b.height - H) / 2),
                                    int((b.width - W) / 2) + W, int((b.height - H) / 2) + H)))
    if t["key"] == "paper":      # 和纸方案：整屏洗成浅淡底纹，墨字才压得住
        img.alpha_composite(Image.new("RGBA", (W, H), (247, 243, 236, 165)))
    elif t["key"] == "frosted":
        # 磨砂方案：整屏只轻提一点，靠左侧一块磨砂卡承载墨字，右侧保留画面
        img.alpha_composite(Image.new("RGBA", (W, H), (250, 246, 238, 40)))
    else:                        # 现状：冷蓝黑幕 + 亮字
        img.alpha_composite(Image.new("RGBA", (W, H), rgba((0.02, 0.03, 0.05, 0.55))))
    if t["key"] == "frosted":
        panel(img, (50, 38, 50 + 596, H - 38), t, radius=22,
              fill=(0.985, 0.976, 0.957, 0.720), edge=(1, 1, 1, 0.45), w=1)
    d = ImageDraw.Draw(img)
    y = 74
    d.text((90, y), "残 夏", font=font(SERIF, 80), fill=rgba(t["paper"] if t["key"] == "current" else t["text"]))
    y += 108
    d.text((92, y), "The Last Tide", font=font(SANS, 24), fill=rgba(t["accent"]))
    y += 46
    d.text((92, y), "汐浦町，最后一个夏天。", font=font(SANS, 22),
           fill=rgba(t["text"] if t["key"] == "current" else t["dim"]))
    y += 52
    items = ["开始新的一周目", "继续游戏", "读取进度", "鉴赏与信件", "游戏设置", "退出"]
    for i, it in enumerate(items):
        wide = 380 if t["key"] == "current" else (340 if t["key"] == "paper" else 360)
        button(img, (86, y, 86 + wide, y + 44), it, t, fsize=22, center=False,
               active=(i == 0))
        y += 44 + (6 if t["key"] != "current" else 10)
    chara_showcase(img, t)
    d = ImageDraw.Draw(img)
    d.text((96, H - 56), "已解锁结局 1 / 5　　第 1 周目", font=font(SANS, 18), fill=rgba(t["dim"]))
    return img


def overlay(img, t, title="菜单", items=("读取进度", "游戏设置", "鉴赏与信件",
                                        "当前状态", "汐浦港　潮汐表", "返回标题画面")):
    """对应 scripts/ui/overlay_shell.gd + menu_panel.gd。"""
    img.alpha_composite(Image.new("RGBA", (W, H), rgba(t["dim_overlay"])))
    f = font(SANS, 32)
    d = ImageDraw.Draw(img)
    pad = (30, 24) if t["key"] == "current" else ((34, 26) if t["key"] == "paper" else (36, 28))
    bw, bh, bsep = 820, 58, 12
    pw = max(940, bw + pad[0] * 2)
    head = 46
    ph = pad[1] * 2 + head + 16 + 1 + 16 + len(items) * bh + (len(items) - 1) * bsep + 16 + 44
    x0 = (W - pw) / 2
    y0 = (H - ph) / 2
    panel(img, (x0, y0, x0 + pw, y0 + ph), t,
          radius=16 if t["key"] == "current" else 4,
          fill=t["panel_bg"], edge=t["line"], w=1)
    d.text((x0 + pad[0], y0 + pad[1] + 6), title, font=f,
           fill=rgba(t["panel_text"]))
    button(img, (x0 + pw - pad[0] - 88, y0 + pad[1], x0 + pw - pad[0], y0 + pad[1] + 44),
           "关闭", t, fsize=22)
    y = y0 + pad[1] + head + 16
    if t["key"] != "frosted":      # 简洁方案不画分隔线，靠间距分组
        ImageDraw.Draw(img).line((x0 + pad[0], y, x0 + pw - pad[0], y),
                                 fill=rgba(t["hairline"]), width=1)
    y += 17
    for k, it in enumerate(items):
        button(img, (x0 + pad[0], y, x0 + pad[0] + bw, y + bh), it, t, fsize=23,
               center=False, active=(k == 0))
        y += bh + bsep
    y += 4
    button(img, (x0 + pw - pad[0] - 160, y, x0 + pw - pad[0], y + 44), "回到游戏", t, fsize=22)


# ----------------------------------------------------------------- 主流程

SCREENS = {
    "01_对话画面": lambda t: (lambda im: (dialogue(im, t), hud(im, t), im)[-1])(
        scene("bg_seawall_rain", "char_shiori_uniform_normal", "c")),
    "02_选择支": lambda t: (lambda im: (dialogue(im, t, line="我该说点什么。"),
                                     hud(im, t), choice(im, t), im)[-1])(
        scene("bg_hospital_corridor", "char_shiori_weak", "r")),
    "03_标题画面": title_screen,
    "04_菜单弹窗": lambda t: (lambda im: (dialogue(im, t), hud(im, t), overlay(im, t), im)[-1])(
        scene("bg_classroom", "char_shiori_uniform_smile", "c")),
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--variant", default="current", help="current | paper | all")
    ap.add_argument("--outdir", default=os.path.join(ROOT, "tools/_ui"))
    args = ap.parse_args()
    variants = list(VARIANTS) if args.variant == "all" else [args.variant]
    os.makedirs(args.outdir, exist_ok=True)
    for v in variants:
        t = VARIANTS[v]
        for name, fn in SCREENS.items():
            img = fn(t)
            out = os.path.join(args.outdir, f"{name}__{v}.png")
            img.convert("RGB").save(out, quality=95)
            print("  %-14s %-8s -> %s" % (name, v, os.path.relpath(out, ROOT)))
    print("\n完成。%d 个方案 × %d 个画面" % (len(variants), len(SCREENS)))


if __name__ == "__main__":
    main()
