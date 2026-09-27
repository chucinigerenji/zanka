#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""《残夏》项目静态校验器。

在没有 Godot 可执行文件的环境下，尽可能把「打开编辑器才会发现的问题」提前抓出来：

  1. project.godot / Main.tscn 结构
  2. 所有 .gd 的括号配平、preload/load 路径存在性
  3. 基于内置类成员表的「静态类型误用」检查（GDScript 会对未知成员直接报编译错）
  4. .zs 剧本：括号块配平、标签、跳转目标、资源引用、角色/说话人 id、系统 key、结局 id
  5. 数据文件内部一致性
  6. 标签可达性（从 start 出发的图遍历）

退出码：0 = 无 ERROR；1 = 有 ERROR。
"""
import io
import json
import os
import re
import sys
from collections import deque

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ERRORS = []
WARNS = []


def err(msg):
    ERRORS.append(msg)


def warn(msg):
    WARNS.append(msg)


def rel(p):
    return os.path.relpath(p, ROOT)


def read(path):
    with io.open(path, encoding="utf-8") as f:
        return f.read()


def exists_res(res_path):
    """把 res:// 映射到磁盘。"""
    if not res_path.startswith("res://"):
        return False
    return os.path.exists(os.path.join(ROOT, res_path[6:]))


# ============================================================ 1. project.godot

def check_project():
    p = os.path.join(ROOT, "project.godot")
    if not os.path.exists(p):
        err("缺少 project.godot")
        return {}
    txt = read(p)
    cfg = {}
    section = ""
    for line in txt.splitlines():
        line = line.strip()
        if not line or line.startswith(";"):
            continue
        if line.startswith("[") and line.endswith("]"):
            section = line[1:-1]
            continue
        if "=" in line:
            k, v = line.split("=", 1)
            cfg[section + "/" + k.strip()] = v.strip()

    if "application/config_version" not in cfg and "config_version" not in txt:
        warn("project.godot 未声明 config_version")

    main_scene = cfg.get("application/run/main_scene", "").strip('"')
    if not main_scene:
        err("project.godot 未设置 application/run/main_scene")
    elif not exists_res(main_scene):
        err("主场景不存在：%s" % main_scene)

    # autoload
    autoloads = []
    for k, v in cfg.items():
        if k.startswith("autoload/"):
            name = k.split("/", 1)[1]
            path = v.strip('"').lstrip("*")
            autoloads.append(name)
            if not exists_res(path):
                err("autoload %s 指向不存在的脚本：%s" % (name, path))
    print("  autoload: %s" % ", ".join(autoloads))

    font = cfg.get("gui/theme/custom_font", "").strip('"')
    if font:
        if not exists_res(font):
            err("全局字体不存在：%s（中文会全部变成豆腐块）" % font)
        else:
            print("  全局字体: %s (%.1f KB)" % (font, os.path.getsize(os.path.join(ROOT, font[6:])) / 1024))
    else:
        warn("未设置 gui/theme/custom_font，中文可能无法显示")

    icon = cfg.get("application/config/icon", "").strip('"')
    if icon and not exists_res(icon):
        warn("图标不存在：%s" % icon)
    return cfg


def check_tscn():
    scen_dir = os.path.join(ROOT, "scenes")
    n = 0
    for dirpath, _, files in os.walk(scen_dir):
        for f in files:
            if not f.endswith(".tscn"):
                continue
            n += 1
            p = os.path.join(dirpath, f)
            txt = read(p)
            if not txt.startswith("[gd_scene"):
                err("%s 不是合法的 gd_scene 头" % rel(p))
            for m in re.finditer(r'\[ext_resource[^\]]*path="([^"]+)"', txt):
                if not exists_res(m.group(1)):
                    err("%s 引用不存在的资源：%s" % (rel(p), m.group(1)))
            for m in re.finditer(r'ExtResource\("([^"]+)"\)', txt):
                if ('id="%s"' % m.group(1)) not in txt:
                    err("%s 使用了未定义的 ExtResource(%s)" % (rel(p), m.group(1)))
    print("  场景文件: %d 个" % n)


# ============================================================ 2. GDScript 基础

BUILTIN_MEMBERS = {
    "Control": set("""
    accept_event add_theme_color_override add_theme_constant_override add_theme_font_override
    add_theme_font_size_override add_theme_icon_override add_theme_stylebox_override anchor_bottom anchor_left
    anchor_right anchor_top clip_contents custom_minimum_size focus_mode focus_neighbor_bottom
    focus_neighbor_left focus_neighbor_right focus_neighbor_top focus_next focus_previous get_combined_minimum_size
    get_drag_data get_global_rect get_minimum_size get_parent_area_size get_rect grab_click_focus grab_focus
    has_theme_color_override has_theme_constant_override has_theme_font_override has_theme_font_size_override
    has_theme_icon_override has_theme_stylebox_override hide is_drag_successful is_layout_rtl layout_direction
    localize_numeral_system minimum_size_changed mouse_default_cursor_shape mouse_filter offset_bottom offset_left
    offset_right offset_top pivot_offset position release_focus reset_size rotation rotation_degrees scale
    set_anchor set_anchors_and_offsets_preset set_anchors_preset set_drag_preview set_focus_mode
    set_global_position set_offset set_position set_size size size_flags_horizontal size_flags_vertical
    theme theme_type_variation tooltip_text top_level transparent_bg update_minimum_size warp_mouse
    get_theme_color get_theme_constant get_theme_font get_theme_font_size get_theme_icon get_theme_stylebox
    has_focus is_visible_in_tree find_next_valid_focus find_prev_valid_focus add_child remove_child get_children
    queue_free get_parent get_tree get_viewport set_process set_process_input set_process_unhandled_input
    set_meta get_meta has_meta remove_meta connect disconnect emit_signal call call_deferred set_deferred
    notification to_string get_class is_class has_method has_signal property_list_changed_notify
    print_line print_error
    """.split()),
    "Node2D": set("""
    position rotation rotation_degrees scale skew transform global_position global_rotation global_scale
    z_index z_as_relative show_behind_parent look_at move_local_x move_local_y translate to_local to_global
    apply_scale get_angle_to get_relative_transform_to_parent
    """.split()),
    "CanvasItem": set("""
    modulate self_modulate visible show hide z_index draw_rect draw_line draw_circle draw_texture
    queue_redraw material use_parent_material y_sort_enabled texture_filter texture_repeat clip_children
    get_canvas_item get_global_transform_with_canvas
    """.split()),
    "Node": set("""
    name owner process_mode process_priority process_physics_priority process_thread_group
    add_child add_sibling remove_child get_children get_child get_child_count get_index get_parent get_tree
    get_viewport get_path get_node get_node_or_null find_child find_children has_node is_node_ready
    queue_free free duplicate set_meta get_meta has_meta remove_meta get_meta_list
    connect disconnect is_connected emit_signal call call_deferred callv set set_indexed get get_indexed
    set_deferred set_block_signals is_blocking_signals notify_deferred property_list_changed_notify
    request_ready is_inside_tree is_processing set_process set_process_input set_process_unhandled_input
    set_process_unhandled_key_input set_physics_process set_process_mode set_notify_transform
    notification to_string get_class is_class has_method has_signal add_to_group remove_from_group
    create_tween get_process_delta_time get_physics_process_delta_time get_ticks_msec linear_to_db db_to_linear
    is_in_group get_groups print_tree print_orphan_nodes print_tree_pretty replace_by
    _ready _process _physics_process _input _unhandled_input _unhandled_key_input _draw _notification _enter_tree _exit_tree
    """.split()),
    "RefCounted": set("get_reference_count".split()),
    "Object": set("""
    get get_indexed set set_indexed set_deferred get_meta set_meta has_meta remove_meta get_meta_list
    connect disconnect is_connected emit_signal call call_deferred callv notification to_string get_class
    is_class has_method has_signal free queue_free property_list_changed_notify
    """.split()),
}
BUILTIN_MEMBERS["CanvasLayer"] = set("layer offset follow_viewport enabled show hide add_child get_children custom_viewport".split())
BUILTIN_MEMBERS["Node2D"] |= BUILTIN_MEMBERS["CanvasItem"] | BUILTIN_MEMBERS["Node"]
BUILTIN_MEMBERS["Control"] |= BUILTIN_MEMBERS["CanvasItem"] | BUILTIN_MEMBERS["Node"]

GD_BUILTIN_TYPES = set(BUILTIN_MEMBERS.keys()) | {
    "Label", "Button", "Panel", "PanelContainer", "VBoxContainer", "HBoxContainer", "MarginContainer",
    "CenterContainer", "GridContainer", "ScrollContainer", "ColorRect", "TextureRect", "RichTextLabel",
    "HSlider", "VSlider", "CheckButton", "CheckBox", "OptionButton", "TextureButton", "LineEdit",
    "CanvasLayer", "AudioStreamPlayer", "Timer", "Tween", "Texture2D", "StyleBoxFlat", "ShaderMaterial",
    "Shader", "Font", "AudioStream", "AudioStreamWAV", "Theme", "InputEvent", "Sprite2D",
}

def strip_gd_strings_comments(src):
    """把字符串与注释替换成空白，保留换行，便于括号配平统计。"""
    out = []
    i = 0
    n = len(src)
    while i < n:
        c = src[i]
        if c == "#":
            while i < n and src[i] != "\n":
                out.append(" ")
                i += 1
            continue
        if c in "\"'":
            q = c
            triple = src[i:i + 3] == q * 3
            if triple:
                out.append("   ")
                i += 3
                while i < n and src[i:i + 3] != q * 3:
                    out.append("\n" if src[i] == "\n" else " ")
                    i += 1
                out.append("   ")
                i += 3
            else:
                out.append(" ")
                i += 1
                while i < n and src[i] != q:
                    if src[i] == "\\":
                        out.append("  ")
                        i += 2
                        continue
                    out.append("\n" if src[i] == "\n" else " ")
                    i += 1
                out.append(" ")
                i += 1
            continue
        out.append(c)
        i += 1
    return "".join(out)


def check_gd_files():
    files = []
    for dirpath, _, fs in os.walk(ROOT):
        if "/.godot" in dirpath or "/tools" in dirpath:
            continue
        for f in fs:
            if f.endswith(".gd"):
                files.append(os.path.join(dirpath, f))
    files.sort()
    print("  GDScript 文件: %d 个" % len(files))

    for p in files:
        src = read(p)
        r = rel(p)
        clean = strip_gd_strings_comments(src)
        for open_c, close_c in (("(", ")"), ("[", "]"), ("{", "}")):
            a, b = clean.count(open_c), clean.count(close_c)
            if a != b:
                err("%s 括号不配平：%s=%d %s=%d" % (r, open_c, a, close_c, b))

        # res:// 引用存在性
        for m in re.finditer(r'(?:preload|load)\(\s*"(res://[^"]+)"', src):
            if not exists_res(m.group(1)):
                err("%s 引用了不存在的资源：%s" % (r, m.group(1)))
        for m in re.finditer(r'"(res://[^"]+\.(?:png|wav|ogg|otf|ttf|gd|tscn|tres|gdshader))"', src):
            if not exists_res(m.group(1)):
                err("%s 出现不存在的资源字符串：%s" % (r, m.group(1)))

        # 静态类型误用
        decls = {}
        for m in re.finditer(r'^var\s+([A-Za-z_]\w*)\s*:\s*([A-Za-z_]\w*)\s*$', clean, re.M):
            if m.group(2) in BUILTIN_MEMBERS:
                decls[m.group(1)] = m.group(2)
        for var, cls in decls.items():
            allowed = BUILTIN_MEMBERS[cls]
            for m in re.finditer(r'\b%s\.([A-Za-z_]\w*)' % re.escape(var), clean):
                member = m.group(1)
                if member in allowed:
                    continue
                line_no = clean[:m.start()].count("\n") + 1
                err("%s:%d  %s 声明为 %s，但访问了不存在的成员 '%s'" % (r, line_no, var, cls, member))



# ============================================================ 2b. 符号级检查

GD_KEYWORDS = set("""
if elif else for while match return await not and or in is as pass break continue var func signal
const class_name extends static enum breakpoint super self preload assert yield void int float bool
String Array Dictionary Vector2 Vector3 Color NodePath StringName Callable Tween lambda true false null
PI TAU INF NAN
""".split())

GD_GLOBALS = set("""
print print_rich printerr printt prints printraw push_error push_warning push_warning
preload load range str int float bool len abs absf absi sign signf signi min max mini maxi minf maxf
clamp clampi clampf lerp lerpf inverse_lerp remap round roundi floor floori ceil ceili sqrt pow
sin cos tan asin acos atan atan2 sinh cosh tanh deg_to_rad rad_to_deg randf randf_range randfn
randi randi_range randomize seed wrapi wrapf snapf snappedf is_equal_approx is_zero_approx
is_instance_valid is_instance_of weakref type_exists type_string typeof var_to_str str_to_var
var_to_bytes bytes_to_var instantiate convert ease cubic_interpolate lerp_angle angle_difference
posmod fposmod move_toward nearest_po2 max min deg_to_rad rad_to_deg linear_to_db db_to_linear
""".split())


def collect_symbols(src):
    return {
        "funcs": set(re.findall(r"^(?:static\s+)?func\s+([A-Za-z_]\w*)", src, re.M)),
        "signals": set(re.findall(r"^signal\s+([A-Za-z_]\w*)", src, re.M)),
        "vars": set(re.findall(r"^var\s+([A-Za-z_]\w*)", src, re.M)),
        "consts": set(re.findall(r"^const\s+([A-Za-z_]\w*)", src, re.M)),
        "aliases": dict(re.findall(
            r'^const\s+([A-Za-z_]\w*)\s*:?=\s*preload\("(res://[^"]+)"\)', src, re.M)),
        "enums": set(re.findall(r"\benum\s+\w*\s*\{([^}]*)\}", src))
            and set(x.strip().split("=")[0].strip()
                    for x in re.findall(r"\benum\s+\w*\s*\{([^}]*)\}", src)[0].split(","))
            or set(),
        "localvars": set(re.findall(r"^\s+var\s+([A-Za-z_]\w*)", src, re.M))
            | set(re.findall(r"\bfor\s+([A-Za-z_]\w*)\s+in\b", src))
            | set(re.findall(r"\bfunc\s*\(\s*([A-Za-z_]\w*)", src)),
    }


def check_symbols(cfg):
    autoloads = {}
    for k, v in cfg.items():
        if k.startswith("autoload/"):
            autoloads[k.split("/", 1)[1]] = v.strip('"').lstrip("*")

    all_src = {}
    for dirpath, dirnames, files in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if d not in (".godot", ".git", "tools")]
        for f in files:
            if f.endswith(".gd"):
                ap = os.path.join(dirpath, f)
                key = "res://" + os.path.relpath(ap, ROOT).replace(os.sep, "/")
                all_src[key] = read(ap)

    syms = {k: collect_symbols(v) for k, v in all_src.items()}
    _ALL_SRC.clear()
    _ALL_SRC.update(all_src)
    _SYMS.clear()
    _SYMS.update(syms)
    inst_members = BUILTIN_MEMBERS["Node"] | BUILTIN_MEMBERS["Control"] | BUILTIN_MEMBERS["RefCounted"] | BUILTIN_MEMBERS["CanvasItem"] | BUILTIN_MEMBERS["Object"]

    n_alias = n_al = 0
    for key, src in all_src.items():
        r = rel(os.path.join(ROOT, key[6:]))
        clean = strip_gd_strings_comments(src)
        me = syms[key]

        # --- 自动加载成员
        for name, tpath in autoloads.items():
            if not re.search(r"\b%s\b" % re.escape(name), clean):
                continue
            ts = syms.get(tpath)
            if ts is None:
                continue
            allowed = ts["funcs"] | ts["signals"] | ts["vars"] | ts["consts"] | inst_members
            for m in re.finditer(r"\b%s\.([A-Za-z_]\w*)" % re.escape(name), clean):
                n_al += 1
                if m.group(1) not in allowed:
                    ln = clean[:m.start()].count("\n") + 1
                    err("%s:%d  自动加载 %s 上没有成员 '%s'" % (r, ln, name, m.group(1)))

        # --- preload 别名成员
        for alias, tpath in me["aliases"].items():
            ts = syms.get(tpath)
            if ts is None:
                continue
            allowed = ts["funcs"] | ts["signals"] | ts["vars"] | ts["consts"] | inst_members | {"new"}
            for m in re.finditer(r"\b%s\.([A-Za-z_]\w*)" % re.escape(alias), clean):
                n_alias += 1
                if m.group(1) not in allowed:
                    ln = clean[:m.start()].count("\n") + 1
                    err("%s:%d  预加载别名 %s 指向的脚本没有成员 '%s'" % (r, ln, alias, m.group(1)))

        # --- connect 目标必须存在
        for m in re.finditer(r"\.(?:connect|bind)\(\s*([A-Za-z_]\w*)", clean):
            tgt = m.group(1)
            if tgt in ("func", "self", "Callable"):
                continue
            if tgt not in me["funcs"] and tgt not in me["vars"] and tgt not in me["localvars"]:
                ln = clean[:m.start()].count("\n") + 1
                err("%s:%d  connect/bind 引用了本文件里不存在的函数：%s" % (r, ln, tgt))

        # --- 裸函数调用（弱检查）
        known_local = (me["funcs"] | me["signals"] | me["vars"] | me["localvars"]
                       | me["consts"] | GD_GLOBALS | GD_KEYWORDS | inst_members)
        for m in re.finditer(r"(?<![.\w])([a-z_][A-Za-z_0-9]*)\s*\(", clean):
            fn = m.group(1)
            if fn in known_local:
                continue
            # lambda 形参列表 func(x: int) 会被误判，跳过
            prefix = clean[max(0, m.start() - 6):m.start()]
            if prefix.endswith("func(") or prefix.endswith("func ("):
                continue
            ln = clean[:m.start()].count("\n") + 1
            warn("%s:%d  调用了本文件未定义的函数 '%s'（可能是笔误）" % (r, ln, fn))

    print("  符号检查：自动加载成员访问 %d 处，预加载别名访问 %d 处" % (n_al, n_alias))



# Godot 全局常量（裸用且没有声明，属于合法）
GLOBAL_CONST_EXACT = {"PI", "TAU", "INF", "NAN", "OK", "FAILED", "NONE", "MAX", "MIN",
                      "LEFT", "RIGHT", "TOP", "BOTTOM", "CENTER", "CLOCKWISE", "COUNTERCLOCKWISE",
                      "JSON", "RID", "AABB", "SIDE_LEFT", "SIDE_TOP", "SIDE_RIGHT", "SIDE_BOTTOM"}
GLOBAL_CONST_PREFIX = ("TYPE_", "ERR_", "KEY_", "PROPERTY_", "MOUSE_", "JOY_", "SPKEY_", "MIDI_",
                       "HORIZONTAL_ALIGNMENT_", "VERTICAL_ALIGNMENT_", "ALIGNMENT_", "JUSTIFICATION_",
                       "TEXT_DIRECTION_", "AUTOWRAP_", "CLOCKWISE", "COUNTERCLOCKWISE")


def check_undefined_consts(all_src, syms):
    """裸用的大写常量如果在任何地方都没被声明，就是漏改/打错的标识符。
    GDScript 遇到未定义标识符会直接编译失败 —— 这个检查就是为了抓这类事故。"""
    declared_anywhere = set()
    for me in syms.values():
        declared_anywhere |= me["consts"] | me["vars"] | me["funcs"] | me["signals"] | me.get("enums", set())
    n = 0
    for key, src in all_src.items():
        r = rel(os.path.join(ROOT, key[6:]))
        clean = strip_gd_strings_comments(src)
        mine = syms[key]
        for m in re.finditer(r"(?<![.\w])([A-Z][A-Z0-9_]{2,})\b(?!\s*:?=)", clean):
            name = m.group(1)
            if name in mine["consts"] or name in mine["vars"] or name in mine["funcs"] or name in mine.get("enums", set()):
                continue
            if name in declared_anywhere:
                continue
            if name in GLOBAL_CONST_EXACT or name.startswith(GLOBAL_CONST_PREFIX):
                continue
            ln = clean[:m.start()].count("\n") + 1
            err("%s:%d  使用了未定义的常量 '%s'（GDScript 会编译失败）" % (r, ln, name))
            n += 1
    print("  常量检查：发现 %d 处未定义常量" % n)

# ============================================================ 3. .zs 剧本

def parse_char_db():
    src = read(os.path.join(ROOT, "scripts/core/char_db.gd"))
    names, sprites = set(), set()
    block = re.search(r"const NAMES\s*:=\s*\{(.*?)\n\}", src, re.S)
    if block:
        names = set(re.findall(r'"([^"]*)"\s*:', block.group(1)))
    block = re.search(r"const SPRITES\s*:=\s*\{(.*?)\n\}", src, re.S)
    if block:
        sprites = set(re.findall(r'"([^"]+)"\s*:', block.group(1)))
    return names, sprites


# 各指令的最少参数个数；与 zs_compiler.gd 的 _require 保持一致
ARITY = {
    "bg": 1, "cg": 1, "char": 2, "hide": 1, "bgm": 1, "se": 1, "amb": 1, "fx": 1,
    "cal": 3, "set": 1, "goto": 1, "call": 1, "ending": 1, "wait": 0, "letter": 0,
    "care": 0, "timeslot": 0, "chapter": 0, "log": 0, "fin": 0, "return": 0,
}


def parse_zs(path, known):
    """把 .zs 编译成指令表（与 zs_compiler.gd 同构的简化版），并做静态检查。"""
    src = read(path)
    r = rel(path)
    cmds = []
    labels = {}
    if_stack = []
    choice_stack = []
    lines = src.split("\n")

    for li, raw in enumerate(lines):
        ln = li + 1
        line = raw.strip()
        if not line or line.startswith("#") or line.startswith("//"):
            continue
        if line.startswith("::"):
            name = line[2:].strip()
            if not name:
                err("%s:%d 空标签" % (r, ln))
            elif name in labels:
                err("%s:%d 标签重复：%s" % (r, ln, name))
            else:
                labels[name] = len(cmds)
            continue
        if line.startswith("*"):
            if not choice_stack:
                err("%s:%d '*' 不在 @choice 内" % (r, ln))
                continue
            body = line[1:].strip()
            if "->" not in body:
                err("%s:%d 选项缺少 -> 目标" % (r, ln))
                continue
            text, rest = body.split("->", 1)
            target = rest.split("|", 1)[0].strip()
            cmds[choice_stack[-1]]["options"].append({"text": text.strip(), "target": target, "line": ln})
            continue
        if line.startswith("@"):
            sp = line.find(" ")
            dname = line[1:sp].strip() if sp > 0 else line[1:].strip()
            argstr = line[sp + 1:].strip() if sp > 0 else ""
            args = [x for x in argstr.replace("\u3000", " ").split(" ") if x]
            if dname == "choice":
                choice_stack.append(len(cmds))
                cmds.append({"op": "choice", "options": [], "line": ln})
            elif dname == "endchoice":
                if not choice_stack:
                    err("%s:%d @endchoice 多余" % (r, ln))
                else:
                    ci = choice_stack.pop()
                    if not cmds[ci]["options"]:
                        err("%s:%d @choice 没有选项" % (r, ln))
            elif dname == "if":
                if not argstr:
                    err("%s:%d @if 缺条件" % (r, ln))
                cmds.append({"op": "if", "cond": argstr, "line": ln, "jmp": -1})
                if_stack.append(len(cmds) - 1)
            elif dname == "else":
                if not if_stack:
                    err("%s:%d @else 多余" % (r, ln))
                cmds.append({"op": "else", "line": ln, "jmp": -1})
            elif dname == "endif":
                if not if_stack:
                    err("%s:%d @endif 多余" % (r, ln))
                else:
                    if_stack.pop()
            else:
                need = ARITY.get(dname)
                if need is not None and len(args) < need:
                    err("%s:%d @%s 至少需要 %d 个参数，实际 %d 个（参数之间必须用半角或全角空格分隔）"
                        % (r, ln, dname, need, len(args)))
                cmds.append({"op": dname, "args": args, "line": ln})
            continue
        # 台词 / 旁白
        if "|" not in line:
            err("%s:%d 无法识别（台词需 'id|文本'，旁白需 '|文本'）：%s" % (r, ln, line[:26]))
            continue
        spk, text = line.split("|", 1)
        spk = spk.strip()
        if spk and spk not in known:
            err("%s:%d 未定义的说话人 id：'%s'" % (r, ln, spk))
        if not text.strip():
            warn("%s:%d 空台词" % (r, ln))
        cmds.append({"op": "say", "speaker": spk, "line": ln})

    if if_stack:
        err("%s 有 %d 个 @if 未闭合" % (r, len(if_stack)))
    if choice_stack:
        err("%s 有 %d 个 @choice 未闭合" % (r, len(choice_stack)))
    return cmds, labels


def check_story(known_speakers, sprites, systems, endings):
    story = os.path.join(ROOT, "data/story/main.zs")
    if not os.path.exists(story):
        err("缺少剧本 data/story/main.zs")
        return
    cmds, labels = parse_zs(story, known_speakers)
    print("  剧本指令: %d 条，标签 %d 个" % (len(cmds), len(labels)))

    used_bg, used_cg, used_char, used_bgm, used_amb, used_se = set(), set(), set(), set(), set(), set()
    used_letter, used_care, used_slot, used_ending = set(), set(), set(), set()
    used_flags = set()

    for c in cmds:
        op = c["op"]
        a = c.get("args", [])
        if op == "bg" and a:
            used_bg.add(a[0])
        elif op == "cg" and a:
            used_cg.add(a[0])
        elif op == "char":
            if not a:
                err("第 %d 行 @char 缺参数" % c["line"])
            else:
                used_char.add(a[0])
                if a[0] not in sprites:
                    err("第 %d 行 @char 使用了未定义的立绘 id：%s" % (c["line"], a[0]))
                if len(a) < 2:
                    err("第 %d 行 @char 缺站位参数" % c["line"])
                elif a[1] not in ("l", "c", "r", "left", "center", "right"):
                    err("第 %d 行 @char 站位非法：%s" % (c["line"], a[1]))
        elif op == "bgm" and a:
            used_bgm.add(a[0])
        elif op == "amb" and a:
            used_amb.add(a[0])
        elif op == "se" and a:
            used_se.add(a[0])
        elif op == "letter" and a:
            used_letter.add(a[0])
        elif op == "care" and a:
            used_care.add(a[0])
        elif op == "timeslot" and a:
            used_slot.add(a[0])
        elif op == "ending" and a:
            used_ending.add(a[0])
        elif op == "set" and a:
            used_flags.add(a[0])
        elif op == "if":
            used_flags.add(re.split(r"[^\w]", c["cond"].strip())[0])

    # 资源存在性
    for i in used_bg:
        if i != "none" and not exists_res("res://assets/bg/%s.png" % i):
            err("剧本引用了不存在的背景：%s" % i)
    for i in used_cg:
        if not exists_res("res://assets/cg/%s.png" % i):
            err("剧本引用了不存在的 CG：%s" % i)
    for i in used_bgm:
        if i != "none" and not exists_res("res://assets/audio/bgm_%s.wav" % i):
            warn("缺少 BGM 文件：bgm_%s.wav" % i)
    for i in used_amb:
        if i != "none" and not exists_res("res://assets/audio/amb_%s.wav" % i):
            warn("缺少环境音文件：amb_%s.wav" % i)
    for i in used_se:
        if not exists_res("res://assets/audio/se_%s.wav" % i):
            warn("缺少音效文件：se_%s.wav" % i)

    # 跳转目标
    for c in cmds:
        if c["op"] in ("goto", "call"):
            a = c.get("args", [])
            if not a:
                err("第 %d 行 @%s 缺目标" % (c["line"], c["op"]))
            elif a[0] not in labels:
                err("第 %d 行 @%s 目标标签不存在：%s" % (c["line"], c["op"], a[0]))
        if c["op"] == "choice":
            for o in c["options"]:
                if o["target"] not in labels:
                    err("第 %d 行 选项「%s」目标不存在：%s" % (o["line"], o["text"], o["target"]))

    # 系统数据
    for k in used_letter:
        if k not in systems.get("letters", {}):
            err("@letter %s 在 systems.json 里没有对应条目" % k)
    for k in used_care:
        if k not in systems.get("care_days", {}):
            err("@care %s 在 systems.json 里没有对应条目" % k)
    for k in used_slot:
        if k not in systems.get("timeslots", {}):
            err("@timeslot %s 在 systems.json 里没有对应条目" % k)
    for k in used_ending:
        if k not in endings:
            err("@ending %s 在 endings.json 里没有对应条目" % k)
    for k in endings:
        if k.startswith("_"):
            continue
        if k not in used_ending:
            warn("endings.json 里的结局 '%s' 在剧本中没有被触发" % k)

    # 可达性
    label_index = sorted((v, k) for k, v in labels.items())
    def owner_label(idx):
        best = None
        for v, k in label_index:
            if v <= idx:
                best = k
            else:
                break
        return best
    graph = {k: set() for k in labels}
    for i, c in enumerate(cmds):
        src_label = owner_label(i)
        if src_label is None:
            continue
        if c["op"] in ("goto", "call"):
            a = c.get("args", [])
            if a and a[0] in labels:
                graph[src_label].add(a[0])
        elif c["op"] == "choice":
            for o in c["options"]:
                if o["target"] in labels:
                    graph[src_label].add(o["target"])
        elif c["op"] in ("ending", "fin"):
            pass
        else:
            # 顺序执行到下一个指令；若下一条属于另一个标签，则建立边
            nxt = owner_label(i + 1)
            if nxt is not None and nxt != src_label:
                graph[src_label].add(nxt)
    # 块末尾落到下一个标签
    for k in labels:
        pass
    seen, dq = set(), deque(["start"])
    if "start" not in labels:
        err("剧本没有 ::start 标签")
    while dq:
        x = dq.popleft()
        if x in seen:
            continue
        seen.add(x)
        for y in graph.get(x, ()):
            if y not in seen:
                dq.append(y)
    # 顺序落到下一个标签的边，靠 cmds 扫描补全
    for i, c in enumerate(cmds):
        if c["op"] in ("goto", "call", "ending", "fin", "choice"):
            continue
        cur = owner_label(i)
        nxt = owner_label(i + 1)
        if cur and nxt and cur != nxt and nxt not in seen and cur in seen:
            dq.append(nxt)
    while dq:
        x = dq.popleft()
        if x in seen:
            continue
        seen.add(x)
        for y in graph.get(x, ()):
            if y not in seen:
                dq.append(y)

    orphans = sorted(set(labels) - seen)
    if orphans:
        warn("从 start 不可达的标签（%d 个）：%s" % (len(orphans), ", ".join(orphans)))
    for e in sorted(used_ending):
        pass

    print("  引用资源: 背景 %d / CG %d / 立绘 %d / BGM %d / 环境音 %d / 音效 %d"
          % (len(used_bg), len(used_cg), len(used_char), len(used_bgm), len(used_amb), len(used_se)))
    print("  结局触发: %s" % ", ".join(sorted(used_ending)))


# ============================================================ 4. 数据文件

def check_story_pack():
    """main.json 必须与 main.zs 同步（导出后游戏只读 json）。"""
    import hashlib
    zs = os.path.join(ROOT, "data/story/main.zs")
    js = os.path.join(ROOT, "data/story/main.json")
    if not os.path.exists(zs):
        return
    if not os.path.exists(js):
        err("缺少 data/story/main.json（导出 APK 时剧本会丢失）——请运行 python3 tools/pack_story.py")
        return
    src = read(zs)
    try:
        d = json.loads(read(js))
    except Exception as e:
        err("data/story/main.json 解析失败：%s" % e)
        return
    txt = d.get("text", "")
    if txt != src:
        err("data/story/main.json 与 main.zs 不同步——请重跑 python3 tools/pack_story.py")
    else:
        print("  剧本包: main.json 与 main.zs 同步（%d 行）" % (src.count("\n") + 1))


def check_data():
    systems, endings = {}, {}
    for name, holder in (("systems.json", "systems"), ("endings.json", "endings")):
        p = os.path.join(ROOT, "data", name)
        if not os.path.exists(p):
            err("缺少 data/%s" % name)
            continue
        try:
            d = json.loads(read(p))
        except Exception as e:
            err("data/%s JSON 解析失败：%s" % (name, e))
            continue
        if holder == "systems":
            systems = d
        else:
            endings = d
    for k, v in systems.get("letters", {}).items():
        if not v.get("options"):
            err("systems.json letters/%s 没有选项" % k)
    for k, v in systems.get("care_days", {}).items():
        if not v.get("options"):
            err("systems.json care_days/%s 没有选项" % k)
    for k, v in systems.get("timeslots", {}).items():
        n = int(v.get("slots", 1))
        if len(v.get("options", [])) < n:
            err("systems.json timeslots/%s 选项少于 slot 数" % k)
    for k, v in endings.items():
        if k.startswith("_"):
            continue
        for f in ("title", "text"):
            if not v.get(f):
                err("endings.json %s 缺字段 %s" % (k, f))
        bg = v.get("bg", "")
        if bg and not exists_res("res://assets/bg/%s.png" % bg):
            err("endings.json %s 引用了不存在的背景：%s" % (k, bg))
    print("  数据: letters %d / care_days %d / timeslots %d / endings %d"
          % (len(systems.get("letters", {})), len(systems.get("care_days", {})),
             len(systems.get("timeslots", {})), len([k for k in endings if not k.startswith("_")])))
    return systems, endings


# ============================================================ main

_CFG_CACHE = {}
_ALL_SRC = {}
_SYMS = {}


def check_project_cached():
    return _CFG_CACHE


def main():
    print("=" * 62)
    print("《残夏》项目静态校验")
    print("=" * 62)
    print("[1] 项目配置")
    _CFG_CACHE.update(check_project())
    print("[2] 场景文件")
    check_tscn()
    print("[3] GDScript 基础")
    cfg = check_project_cached()
    check_gd_files()
    print("[3b] 符号级检查")
    check_symbols(cfg)
    check_undefined_consts(_ALL_SRC, _SYMS)
    print("[4] 数据文件")
    systems, endings = check_data()
    check_story_pack()
    print("[5] 剧本")
    names, sprites = parse_char_db()
    print("  CharDB: 说话人 %d 个，立绘 %d 个" % (len(names), len(sprites)))
    check_story(names, sprites, systems, endings)

    print("-" * 62)
    if WARNS:
        print("警告 %d 条：" % len(WARNS))
        for w in WARNS[:40]:
            print("  WARN  " + w)
        if len(WARNS) > 40:
            print("  ... 其余 %d 条省略" % (len(WARNS) - 40))
    if ERRORS:
        print("错误 %d 条：" % len(ERRORS))
        for e in ERRORS[:60]:
            print("  ERR   " + e)
        if len(ERRORS) > 60:
            print("  ... 其余 %d 条省略" % (len(ERRORS) - 60))
        print("校验未通过。")
        return 1
    print("校验通过，没有 ERROR。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
