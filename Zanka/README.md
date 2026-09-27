# 《残夏 -The Last Tide-》

> 汐浦町，最后一个夏天。

一个现实主义向的悲剧恋爱 ADV（2D 剧情冒险）。日本海侧一个正在衰败的渔港小镇，
一个照顾失智祖母的高三男生，一个把「不治疗」当成送给家人的礼物的转学女生。
他们各自悄悄为对方安排「没有自己的以后」。

**引擎**：Godot 4（GDScript）　**分辨率**：1280×720　**渲染**：GL Compatibility　**手机构型**：横屏

---

## 一、怎么打开

1. 用 Godot 4 编辑器打开本目录（`project.godot`）。
2. 首次打开会导入 `assets/` 下的图片与音频，稍等一会儿。
3. 按 **F5** 运行。主场景是 `scenes/Main.tscn`。

> 项目里**只有 1 个 .tscn 文件**，所有界面都是用 GDScript 在运行时构建的。
> 这样做的原因：手写 `.tscn` 极易因为格式问题让整个项目打不开，而纯代码 UI 可以静态校验。

## 二、操作

| 操作 | 键盘 / 鼠标 | 手机 |
|---|---|---|
| 推进对话 | 左键 / 空格 / 回车 | 点屏幕 |
| 跳过打字动画 | 同上（先点一下） | 点屏幕 |
| 自动播放 | `A` 键，或 HUD「自动」 | HUD「自动」 |
| 快速跳过 | `Ctrl`，或 HUD「跳过」 | HUD「跳过」 |
| 打开菜单 | `Esc`，或 HUD「菜单」 | HUD「菜单」 |
| 关闭弹窗 | `Esc` | 弹窗右上角 ✕ |

## 三、目录结构

```
Zanka/
├── project.godot            项目配置（5 个自动加载单例）
├── icon.svg
├── scenes/Main.tscn         唯一的场景文件
├── shaders/
│   ├── bg_sharpen.gdshader  背景锐化 + 胶片颗粒（512px 原图放大后找回细节）
│   └── vignette.gdshader    暗角，承载「病征演出」
├── scripts/
│   ├── main.gd              主控：标题 / 游戏 / 结局三个画面切换
│   ├── autoload/
│   │   ├── game_config.gd   设置（文字速度、音量、演出强度、全屏）
│   │   ├── game_state.gd    旗标、回忆点、信件、照护评分、周目、解锁数据
│   │   ├── save_manager.gd  6 个手动档 + 1 个自动档 + 全局解锁
│   │   ├── audio_manager.gd BGM 交叉淡入 / 环境音 / 音效池
│   │   └── story_engine.gd  剧本执行器（含舞台状态快照，读档能还原画面）
│   ├── core/
│   │   ├── zs_compiler.gd   .zs 剧本编译器
│   │   ├── char_db.gd       角色名 / 名牌配色 / 立绘映射
│   │   ├── ui_theme.gd      统一视觉风格 + Theme 构建
│   │   └── ui_kit.gd        UI 构建小工具
│   └── ui/                  12 个界面组件（全程序化构建）
├── data/
│   ├── story/main.zs        全部剧情（1627 行 / 21 个标签 / 5 个结局）
│   ├── systems.json         信件 / 照护日志 / 时间编排 的数据
│   ├── tides.json           汐浦港潮汐表（终章伏笔的载体）
│   ├── endings.json         5 个结局的展示文案
│   └── story/main.json      main.zs 的打包产物（运行时实际读这个）
├── assets/
│   ├── bg/                  18 张背景（512×320）
│   ├── char/                13 张立绘（512×512，自动抠图带 alpha）
│   ├── cg/                  5 张事件 CG（512×320）
│   ├── audio/               7 BGM + 6 环境音 + 7 音效（16bit WAV）
│   └── ui/                  中文字体（Noto Sans/Serif CJK SC 子集，含 1217 字）
└── tools/                   生成与校验脚本（Python，不参与游戏运行）
```

## 四、剧本语法（`.zs`）

```
# 注释
::标签名                          跳转目标
shiori|台词内容                    角色 id | 文本   ← 说话
|旁白文本                          以 | 开头     ← 旁白
@bg bg_seawall_rain 1.2          背景（fade 秒）
@cg cg_piano 1.0                 事件 CG
@cg_hide 1.0
@char shiori_normal c 0.9        立绘（id 站位 l/c/r fade）
@hide all 0.8
@bgm shiori 2.0                  背景音乐（none = 停）
@amb rain 2.0                    环境音（可与 BGM 并存）
@se door                         音效
@fx shake 14                     shake / flash / vignette / breath / blackout / blackout_end
@wait 1.2
@cal 6/17　小潮　傍晚             更新 HUD 上的日期与潮汐
@chapter 第一章　蝉时雨           章节标题演出 + 自动存档
@log 记录一条到「当前状态」
@set flag value / @if 条件 / @else / @endif / @goto / @call / @return
@choice ... * 选项 -> 标签 | flag=值 ... @endchoice
@letter prologue                 触发信件系统
@care day1                       触发照护日志
@timeslot ch1                    触发时间编排
@ending true                     触发结局（id 对应 endings.json）
@fin                             剧本结束
```

条件支持：`@if flag` / `@if !flag` / `@if flag == 值` / `>=` / `<=` / `>` / `<`。

## 五、重新生成素材

```bash
# 剧本打包（★ 改完 main.zs 后必须跑，否则导出的 APK 里没有剧本）
python3 tools/pack_story.py

# 图片（需要 Local Dream 开启「设备互联 → 受控模式」）
python3 tools/gen_assets.py              # 断点续跑，已存在的跳过
python3 tools/gen_assets.py --only bg_   # 只跑背景
python3 tools/gen_assets.py --force      # 全部重生成

# 音频（纯 stdlib 合成，不需要任何外部依赖）
python3 tools/gen_audio.py

# 中文字体子集化（从系统 NotoSansCJK / NotoSerifCJK 抽取项目用到的字）
python3 tools/make_font.py

# ---- 立绘 alpha 重建（一条命令跑完整条流水线，可反复跑）----
python3 tools/rebuild_sprites.py
# 内部固定顺序：抠图 -> 切断细通道 -> 清边缘均匀色带 -> 轮廓收缩削灰边 -> 清碎块 + 裁边归一化
# 每一步都会保留原始 RGB，所以随时可以整条重跑，不会越修越坏。

# 立绘构图体检：发现头顶/身体被画面边缘切掉的图
python3 tools/check_sprites.py

# 导出可读版剧本全文（Markdown，脱离 Godot 通读审稿）
python3 tools/export_script.py

# 静态校验（交付前必跑）
python3 tools/validate.py
```

美术提示词全部写在 `tools/asset_manifest.json` 里，方便逐条改。

## 六、校验器做了什么

`tools/validate.py` 在没有 Godot 可执行文件的环境下，尽可能把「打开编辑器才会发现的问题」提前抓出来：

1. `project.godot` / `Main.tscn` 结构与资源存在性（含「全局字体是否存在」——缺了中文会全变豆腐块）
2. 所有 `.gd` 的括号配平、`preload/load` 路径存在性
3. **静态类型误用**：GDScript 对 `var x: Control` 上的未知成员会直接报编译错，这里按内置类成员表逐个核对
4. **符号级检查**：自动加载单例的成员访问、`preload` 别名指向的脚本成员、`connect()` 引用的函数是否真的存在
5. `.zs` 剧本：块配平、标签唯一性、跳转目标、背景/CG/立绘 id、说话人 id、BGM/环境音/音效文件、系统数据 key、结局 id
6. **剧本包同步**：`main.json` 必须与 `main.zs` 一致（`data/story/main.zs` 是编辑源，
   `main.json` 是运行时读的打包产物——Godot 导出时只有能被识别为资源的文件才会进 APK）
7. **立绘构图体检**：`check_sprites.py` 检查四条边上有没有不透明像素——头顶被切平就是它抓出来的
8. **未定义常量**：裸用的大写常量若在任何地方都没声明，GDScript 会直接编译失败（这个检查抓到过一次真实的漏改事故）
9. **标签可达性**：从 `::start` 出发做图遍历，报出不可达的标签（防止写出永远走不到的剧情）
10. 数据文件内部一致性（`endings.json` 引用的背景是否存在等）

## 七、已知边界

* 图片由本地 Stable Diffusion（Anything V5）在 512 分辨率生成后放大，柔化是既定风格；
  背景着色器带轻微 unsharp + 颗粒，让「软」看起来是有意为之。
* 立绘走的是「**纯黑底 + 自适应抠图**」路线：
  - 提示词里把 `(solid black background:1.6), (simple background:1.4)` 放在**最前面**，并保留
	`masterpiece, best quality...` 质量前缀。前缀不能省——实测去掉它，SD1.5 会画重复人像和纯色块。
  - 抠图取四边像素中位数当背景参考色（不假设是黑是白），按容差做边界洪水填充 + 1px 羽化。
	参考色接近纯白时容差自动压到 15，避免背景白顺着白衬衫填进去。
  - 为什么不用白底：角色穿白衬衫时，背景白和衣服白连通，宽松阈值会把衣服一起填掉（实测踩过）。
	黑底从根上避开了这个歧义。
* 已知瑕疵：少数立绘上会残留模型自己加的漂浮色块（如医生肩上、祖母手边的灰色块）。
  这类色块与角色连通，孤岛清除清不掉——`tools/clean_sprites.py` 能处理的是**断开**的孤岛。
  重新抽一次卡（`python3 gen_assets.py --only <id> --force`）通常能换掉。
* 立绘是**腰部以上的半身像**，按屏高 80% 摆放，底边压出屏幕外——对话框正好盖住下三分之一，
  所以画面里看不到腿部裁切。
* 无语音。`scripts/ui/dialogue_box.gd` 的打字机速度可以按设置调节。
* 周目继承：已解锁的结局 / CG / 信件 / 记忆碎片存在 `user://global.json`，跨存档保留。
