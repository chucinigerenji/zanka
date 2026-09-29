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
| 关闭弹窗 | `Esc` | 弹窗右上角的「关闭」 |

> 「跳过」默认**不分已读未读，一律跳过**（否则一周目里每句都是未读，按下去像没反应）；
> 想改成「只看过的才跳」，去设置里取消勾选「跳过时忽略未读文本」。
> 跳过时会**一次性显示完当前这句的打字动画**，不会卡在打字上。

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
│   ├── char/                13 张立绘（语义抠图带 alpha，裁到内容包围盒）
│   ├── cg/                  5 张事件 CG（512×320）
│   ├── audio/               7 BGM + 6 环境音 + 7 音效（16bit WAV）
│   └── ui/                  中文字体（Noto Sans/Serif CJK SC 子集，含 1217 字）
└── tools/                   生成与校验脚本（Python，不参与游戏运行）
	├── regen_sprites.py     立绘出图（Local Dream，带 77token 护栏 + 构图自动重抽）
	├── qc_sprites.py        立绘量化质检（红绳/碎块/软边/构图）+ 对比总览图
	├── install_sprites.py   抠图收尾：清碎块 + 裁边归一化 -> assets/char/
	├── gen_assets.py        背景 / CG 出图（自带旧版洪水填充抠图）
	├── pack_story.py        剧本打包 main.zs -> main.json
	├── validate.py          静态校验（交付前必跑）
	├── check_sprites.py     立绘构图体检（单独跑，validate 不含）
	└── ...                  gen_audio / make_font / export_script / rebuild_sprites 等
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

# ---- 立绘（现在走「语义抠图」路线，见下一节）----
python3 tools/regen_sprites.py                 # 1. 出原图 -> tools/_raw_sprites/（带 77token 护栏）
birefnet-cutout "$PWD"/tools/_raw_sprites/*.png --outdir "$PWD"/tools/_matte --json  # 2. BiRefNet 抠图
python3 tools/install_sprites.py               # 3. 清碎块 + 裁边归一化 -> assets/char/
python3 tools/qc_sprites.py                    # 4. 量化质检（红绳/碎块/软边/构图）
python3 tools/check_sprites.py                 # 5. 构图体检（头顶有没有被切）

# 旧的立绘 alpha 重建（洪水填充方案，只在不想用 BiRefNet 时才用）
python3 tools/rebuild_sprites.py
# 内部固定顺序：抠图 -> 切断细通道 -> 清边缘均匀色带 -> 轮廓收缩削灰边 -> 清碎块 + 裁边归一化
# 每一步都会保留原始 RGB。
# ⚠ 但「可反复跑」并不完全成立：autocrop 之后四边参考色不再是黑底，而是抗锯齿灰，
#   于是每次重跑都会再啃掉一圈角色像素。实测 char_yuto 会持续缩水
#   （475 -> 464 -> 461 -> 457 -> 454 -> 452 -> 451，约 −5% 宽度后收敛），其余 12 张稳定。
#   重跑前先备份 assets/char/。
# ⚠ 不要单独跑 tools/clean_sprites.py / tools/recut.py / tools/flat_cutout.py：
#   前者的 main() 用的是「四边」清色带（会清掉下边缘，与半身像的设计相冲突），
#   后两者是当初被放弃的备选抠图方案，且 flat_cutout 只看 RGB、无视现有 alpha，
#   直接跑会把已经收敛的 13 张立绘全部大改。

# 立绘构图体检：发现头顶/身体被画面边缘切掉的图
python3 tools/check_sprites.py
```

### 立绘流水线（BiRefNet 语义抠图）

立绘不再走 `gen_assets.py` 的洪水填充抠图了——那条路线会留下硬二值边（没有任何抗锯齿）
和灰边。现在拆成四步，每步都可单独重跑：

| 步骤 | 命令 | 干什么 |
|---|---|---|
| 1 出图 | `python3 tools/regen_sprites.py` | Local Dream 出原图（**不抠图**），落 `tools/_raw_sprites/` |
| 2 抠图 | `birefnet-cutout <绝对路径>/*.png --outdir <绝对路径>/tools/_matte --json` | 本机离线 BiRefNet 语义抠图 |
| 3 收尾 | `python3 tools/install_sprites.py` | 清孤立碎块 + 裁到内容包围盒，写回 `assets/char/` |
| 4 质检 | `python3 tools/qc_sprites.py --compare <旧目录>` | 量化指标 + 可选对比总览图 |

两个必须记住的坑：

1. **`birefnet-cutout` 一定要传绝对路径。** 它内部会 `os.chdir(~/birefnet)`，
   相对路径一律报 `FileNotFoundError`。
2. **提示词必须 ≤77 token（CLIP 上限），超了是静默截断。** 服务端不报错，直接把尾部丢掉。
   `regen_sprites.py` 出图前会用 `/tokenize` 核算，溢出即中止。

   > 这个坑真的踩过：旧版立绘提示词 **104 token**、负面 **193 token**。
   > 被丢掉的正好是 `thin red string bracelet on left wrist`（企划里栞「从不摘的红绳」）
   > 和 `cowboy shot / head fully visible`（全部构图控制）——也就是**红绳从来没被画出来过**，
   > 这才是当时反复「构图出画」重抽的真正原因。
   > `qc_sprites.py` 的「红像素」一列就是用来盯这件事的：旧图 0，新图八百多。

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
7. **立绘构图体检**：检查四条边上有没有不透明像素——头顶被切平就是它抓出来的。
   ⚠ 这一步**不在 `validate.py` 里**，要单独跑 `python3 tools/check_sprites.py`（`--json` 可机器读）。
8. **未定义常量**：裸用的大写常量若在任何地方都没声明，GDScript 会直接编译失败（这个检查抓到过一次真实的漏改事故）
9. **标签可达性**：从 `::start` 出发做图遍历，报出不可达的标签（防止写出永远走不到的剧情）
10. 数据文件内部一致性（`endings.json` 引用的背景是否存在等）

## 七、已知边界

* 图片由本地 Stable Diffusion（Anything V5）在 512 分辨率生成后放大，柔化是既定风格；
  背景着色器带轻微 unsharp + 颗粒，让「软」看起来是有意为之。
* 立绘走的是「**平灰底 + BiRefNet 语义抠图**」路线（BiRefNet 改版；之前是纯黑底 + 洪水填充）：
  - 背景用 `flat grey background`。中灰对**黑发**和**白衬衫**两边都有对比；
	旧版用纯黑底是洪水填充的前提，但「黑发贴黑底」本身就是最难的情况，语义抠图不需要这个前提。
  - 抠图用本机离线的 BiRefNet（`birefnet-cutout`），边缘是真正的抗锯齿，
	不再是洪水填充那样的硬二值边（`qc_sprites.py` 的「软边%」：旧 **0.0%** → 新约 **3%**）。
  - 收尾 `install_sprites.py` 先清孤立碎块、再裁到内容包围盒，让 13 个角色在画框里大小一致
	（SD 每次给的人物大小都不一样，不裁就会一大一小）。
* **提示词有 77 token 的硬上限，CLIP 截断是静默的。** 这是本项目踩过最贵的一个坑：
  旧版立绘提示词 104 token，被丢掉的尾部是
  `thin red string bracelet on left wrist, cowboy shot, standing, facing viewer, head fully visible,
  cel shading, clean lineart` —— 也就是**栞的红绳从来没有出现在立绘上**，且构图毫无约束
  （这才是当时反复「构图出画」重抽的真正原因）；负面提示词同样超（193 token），
  连 `lowres / worst quality / bad anatomy` 都被丢掉了。
  现在 `regen_sprites.py` 出图前强制核算 token，溢出直接中止；`qc_sprites.py` 的红像素列做回归。
* 少数立绘上可能残留模型自己画的漂浮色块。与主体**断开**的孤岛会被
  `install_sprites.py` 里的 `clean()` 清掉；与主体**连通**的清不掉，
  只能重抽一张（`python3 tools/regen_sprites.py --only <id> --force` 再抠一次）。
* 立绘是**腰部以上的半身像**，按屏高 80% 摆放，底边压出屏幕外——对话框正好盖住下三分之一，
  所以画面里看不到腿部裁切。
* 无语音。`scripts/ui/dialogue_box.gd` 的打字机速度可以按设置调节。
* 周目继承：已解锁的结局 / CG / 信件 / 记忆碎片存在 `user://global.json`，跨存档保留。

---

## 八、导出 Android APK

`export_presets.cfg` 里已经配好一个 Android 预设（唯一预设，已设为 `runnable`），不用手动新建。

### 0. 每次导出前（不能省）

```bash
python3 tools/pack_story.py     # ★ 改过 main.zs 就必须跑，否则 APK 里没有剧本
python3 tools/validate.py       # 必须 0 ERROR
```

`main.zs` 不是 Godot 能识别的资源类型，**不会**被打进 APK；游戏运行时读的是 `pack_story.py`
产出的 `data/story/main.json`。忘了这一步，装到手机上打开就是「剧本加载失败」。

### 1. 一次性准备（在 Godot 编辑器里）

1. **编辑器设置 → 导出 → Android**：填 Android SDK 路径（要含 `platform-tools` 与 `build-tools`）和 JDK 17。
2. **编辑器 → 管理导出模板**：安装与当前编辑器版本一致的 **Android 导出模板**
   （用官方模板即可——预设里 `gradle_build/use_gradle_build=false`，不要求自建 gradle 工程）。
3. 调试包用 Godot 自动生成的 debug keystore，不必自备签名。

### 2. 导出

**项目 → 导出 → Android → 导出项目**。目标路径已设为 `build/Zanka.apk`（相对项目根，`build/` 已在 `.gitignore` 里）。

预设里几个关键设定，改之前先看懂：

| 设定 | 值 | 为什么 |
|---|---|---|
| `export_filter` | `all_resources` | 背景 / CG / 立绘 / 音频 / 字体全部按资源导出 |
| `include_filter` | `data/story/*.json` | 显式钉住剧本包，防止被漏掉 |
| `exclude_filter` | `预览/*` | `预览/` 三张总览图约 7 MB（还是成对重复的文件），只是审稿素材，不该进包 |
| `architectures` | 只留 `arm64-v8a` | 现代手机都是 arm64；砍掉 armeabi-v7a / x86 可让包体减半 |
| `screen/immersive_mode` | `true` | 视觉小说全屏沉浸，隐藏导航栏 |

`tools/` 目录里有 `.gdignore`，Godot 会整目录跳过，不会被导出。

### 3. 装到手机

把 `build/Zanka.apk` 拷到手机上点安装，或 `adb install -r build/Zanka.apk`。

### 4. 导出后必做的冒烟测试

**不要只看能不能启动**——要确认那几个 JSON 真的都在包里：

1. 标题 →「开始新的一周目」→ 能出第一句旁白（`main.json` 进包了）；
2. 右上「菜单 → 汐浦港 潮汐表」→ 13 行都在，9/19 那行是「朔望大潮 +202cm」（`tides.json` 进包了）；
3. 走完序章 → 弹出「不会寄出的信」面板（`systems.json` 进包了）；
4. 横屏、无导航栏、中文不是豆腐块。

---

## 九、UI 设计（磨砂玻璃方案）

UI **全部由 GDScript 运行时构建**（工程里只有一个 6 行的 `.tscn`），
所以样式全部收敛在两个文件里，改这两处就全局生效：

| 文件 | 管什么 |
|---|---|
| `scripts/core/ui_theme.gd` | 配色常量、圆角、Button/Panel/滚动条主题、和纸材质 |
| `scripts/core/ui_kit.gd` | 三种按钮工厂与面板工厂 |

### 设计方向

基础是企划 05 的美术基调——「低饱和、暖灰、洗褪色的夏天」「纸质质感、褪色商店街配色、
手写体标题」。落到实现上是 **半透明磨砂玻璃 + 墨字 + 朱色点缀**：

* **面板 = 暖白半透明**（`C_BOX` 0.84 / `C_DBOX` 0.80 / `C_HUD` 0.62），
  背景会透过来，这是「高级感」的来源；
* **圆角要大**（`R_BOX=18` / `R_PANEL=22` / `R_BTN=12`）——磨砂玻璃不做直角；
* **边缘是 1px 亮边**（`C_LINE` 白 0.55），不是深色描边。玻璃感全靠这条高光边；
* **面板内部不画任何分隔线**，靠间距分组（这是「简洁」的关键：
  上一版每条菜单项压一条横线，7 条线一叠就很碎）；
* **文字 = 暖墨色**（`C_TEXT`），不是纯黑，压在磨砂底上依然清晰；
* **强调 = 朱色**（`C_ACCENT`），全界面只有这一处彩色（顶边包边、当前项左短棒）；
* **按钮分三种**，别再混用：
  | 工厂 | 外观 | 用在哪 |
  |---|---|---|
  | `Kit.button()` | 淡底小圆角块 | `关闭`、`回到游戏` 这类孤立动作 |
  | `Kit.row_button()` | 平时只有文字；悬停/选中浮出一块柔和圆角底 + 朱色左短棒 | 标题菜单、选项支、弹窗列表 |
  | `Kit.text_button()` | 纯文字；按下（自动/跳过开启）是一块朱色圆角底 | HUD 上的 回想/自动/跳过/存档/菜单 |

> `Kit.row_button()` 的朱色短棒是用 `StyleBoxFlat.border_width_left` 画的，
> 它会跟着圆角一起被裁剪，所以端头看起来是圆的——不需要额外贴图。

### 一个必须记住的坑：字体是子集化的

中文字体只收录了**出现在项目文本文件里的字**（`tools/make_font.py` 收集）。
所以：

* **不要在 UI 里随手引入新字**，否则真机上会渲染成豆腐块 □；
* 这条也适用于符号：弹窗右上角原来是 `✕`(U+2715)，该码位在子集里**没有字形**，
  实际渲染出来是一个空方框。已改成 `关闭`（这两个字panel里本来就在用）。
* 确实需要新字时，得重跑 `tools/make_font.py`（依赖 `fontTools`，本机未安装）。

### 纸纹颗粒

`shaders/paper.gdshader` 给面板加极轻的纸纹（细噪点 + 竖向纤维）。
它**只扰动 RGB、完全不碰 alpha**，所以材质没挂上或编译失败都只是「少了纸纹」，
不会让面板透明或遮住文字——这是刻意的低风险设计。挂在 `UI.apply_paper(control)`。

### 改 UI 前先看设计稿

`tools/ui_mockup.py` 用**项目真实的字体、背景图、立绘**，把上述设计令牌与几何
按同一套几何渲染成 PNG（只换设计变量），所以不用开 Godot 就能快速迭代——
本次「简洁 / 圆润 / 半透明」就是因为能在几秒内出一版稿才敢反复试：

```bash
python3 tools/ui_mockup.py                    # 当前设计（旧）
python3 tools/ui_mockup.py --variant frosted  # 磨砂玻璃方案（现行）
python3 tools/ui_mockup.py --variant all    # 两套都出（做前后对比）
# 输出在 tools/_ui/，成品设计稿见 预览/UI设计稿.png
```

⚠ **这个工具需要 Pillow**。本机 Pillow 已不可用（Python 3.14 没有预编译 wheel、
源码编译也失败），且没有别的光栅化工具（magick / rsvg / ffmpeg 都没有），
所以**设计稿预览目前出不来**；装上 Pillow 即可恢复，不影响游戏运行。
⚠ 它是**设计稿不是引擎截图**：字体度量与容器自动布局会有像素级出入，
改完仍要在 Godot 里 F5 实跑确认（尤其换行与动态尺寸）。
### 标题画面：立绘轮播 + 聊天气泡

`scripts/ui/title_chara.gd` 在标题右侧随机逐张播放**全部 13 张立绘**，
约 **30 秒**换一个（`SWITCH_SEC`）；人物左上角挂一个半透明聊天气泡，
内容是**游戏贴士或角色的心里话**，**点气泡换下一条**（换了会重置计时）。
每个角色约 10 条，共 9 组、90 条，写在 `title_chara.gd` 的 `const LINES` 里。

* 立绘清单在 `const CAST`（栞的五个表情算五张，按「播放全部立绘」处理）；
  台词按角色归档（`LINES` 用 `CharDB.base_id()` 取键），所以栞的五个表情共用一套话。
* 气泡位置跟着立绘实际绘制矩形走（`KEEP_ASPECT_CENTERED` 会留白边，
  直接按控件矩形贴会飘），换分辨率也会重排；气泡锚的是**底边**，
  所以文字变多时向上长，不会整块上下跳。
* 换文案走一段「思考」动画：旧文字淡出 → 气泡里省略号一点一点跳
  （`THINK_SEC` 0.72s）→ 新文字淡入 + 气泡轻弹一下；换角色时立绘也跟着淡出淡入。
  思考期间点气泡无效（`_busy` 挡住），避免连点把动画打断。
* 标题画面不可见时（进了游戏 / 被弹窗盖住）计时会暂停，不在后台空转。
* **点立绘的不同部位会说不同的话**（脸 / 胸 / 肚子 / 手臂）：
  点击区域是**归一化到「立绘实际绘制矩形」**的（不是控件矩形 ——
  `KEEP_ASPECT_CENTERED` 会留白边，按控件算上半身会整体偏），
  定义在 `const PARTS`；台词在 `const PART_LINES`
  （9 角色 × 4 部位 × 3 条，同一部位连点往后轮）。
  点部位的「思考」比换文案短（`TOUCH_THINK` 0.34s vs 0.72s），戳着玩不拖。
  ⚠ 点击层必须加在**气泡之前**：Godot 输入从后往前派发，加在后面会把气泡的点击吃掉。
* 想改文案，直接编辑 `LINES` / `PART_LINES` 即可——但**必须先过字形检查**（见下）。

### 动画清单（刻意都做得很短）

原则：**动效只用来让「变化」被看见，不用来表演**。总时长都压在 0.2~0.4 秒，
不阻塞操作、不拖节奏。

| 位置 | 动效 | 时长 |
|---|---|---|
| 选项卡出现 | 整块渐入 + 每个选项错开 0.03s 从左侧顶出来 | 0.16s / 选项 0.20s |
| **选项卡选择后** | 整块渐出，**渐出结束才通知剧情继续**（否则点完直接切走，没有收尾） | 0.14s |
| 立绘出场 | 淡入 + 从下方浮上来 14px（并进呼吸位移一起算，不能单独改 position） | 0.17s |
| 名牌 | **换说话人时**轻弹一下（同一个人连着说就不弹，否则很吵） | 0.16s |
| HUD 日期 / 潮汐 | 内容变化时淡一下，给一点「时间在走」的感觉 | 0.30s |
| HUD 章节 | 换章时淡入 | 0.40s |
| 背景 / CG 切换 | 双层交叉淡入（原有） | 0.4~1.6s |
| 章节标题演出 | 淡入 → 停留 → 淡出（原有） | 0.7 / 1.9 / 0.9s |

改这些时长：选项卡在 `choice_panel.gd` 顶部；立绘在 `char_layer.gd` 的
`RISE_PX / RISE_SPEED`；HUD 在 `hud.gd` 的 `_fade_in()` 调用处。

### 改文案必跑：字形覆盖检查

```bash
python3 tools/check_font_coverage.py scripts/ui/title_chara.gd
python3 tools/check_font_coverage.py data/story/main.zs
```

中文字体是**子集化**的（只收录生成时项目文本里出现过的字），所以
**新写的任何汉字都可能是豆腐块 □**。这个工具**直接解析字体的 `cmap` 表**
（format 4 / 12）拿覆盖的码点集合，**纯标准库、零依赖**——原先那版靠 Pillow
渲染比对，而本机 Pillow 已经装不回来了（Python 3.14 没有预编译 wheel）。
对 `.gd` 只检查双引号字符串（注释里的字不渲染，不该报）。
挑符号时可以先 `--list-symbols` 看哪些有字形（当前字体 1216 个）。

> 这个检查真的抓到过东西：剧本里我自己加的 `劝`（「因为她劝不动我」）与
> `叠`（「那叠信封」）、潮汐表表头的全角 `／`、以及 `▶`、`备考`、`或`
> ——全都不在子集里，真机上一直显示成空方框。已逐个换成有字形的说法。
> 写「点部位」那 108 条时又抓到 34 个（`胸 肚 臂 腕 饿 疼 摸 惯 红 绳 剪 吵 喂`
> 等），也全部绕开了 —— 注意 **`肚子 / 胸口 / 手臂` 这三个词本身就是缺字的**，
> 只能写成「身上 / 心口 / 手」。
> 新增这个工具后，全部脚本的字符串字形覆盖已到 **100%**。

确实需要新字时，得重跑 `tools/make_font.py`（依赖 `fontTools`，本机未安装）。
