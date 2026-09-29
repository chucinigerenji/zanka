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

## 九、UI 设计（和纸方案）

UI **全部由 GDScript 运行时构建**（工程里只有一个 6 行的 `.tscn`），
所以样式全部收敛在两个文件里，改这两处就全局生效：

| 文件 | 管什么 |
|---|---|
| `scripts/core/ui_theme.gd` | 配色常量、圆角、Button/Panel/滚动条主题、和纸材质 |
| `scripts/core/ui_kit.gd` | 三种按钮工厂与面板工厂 |

### 设计方向

对齐企划 05 写的美术基调——「低饱和、暖灰、洗褪色的夏天」「纸质质感、褪色商店街配色、
手写体标题」。做法是把 UI 从「深色玻璃盒」换成 **和纸底 + 墨字 + 朱色点缀**：

* **面板 = 暖白和纸**，圆角很小（`R_BOX=3` / `R_PANEL=4`）——纸不会有大圆角，
  这一点是从「看着像网页/输入框」里救回质感的关键；
* **文字 = 暖墨色**（`C_TEXT`），不是纯黑；
* **强调 = 朱色**（`C_ACCENT`），全界面只有这一处彩色（顶边包边、悬停标记、当前项）；
* **按钮分三种**，别再混用：
  | 工厂 | 外观 | 用在哪 |
  |---|---|---|
  | `Kit.button()` | 淡描边小方块 | `✕`、`回到游戏` 这类孤立动作 |
  | `Kit.row_button()` | 无框 + 底分隔线，悬停出朱色左标记 | 标题菜单、选项支、弹窗列表（**用方框会像输入框**） |
  | `Kit.text_button()` | 纯文字，按下朱底纸字 | HUD 上的 回想/自动/跳过/存档/菜单 |

### 和纸颗粒

`shaders/paper.gdshader` 给面板加极轻的纸纹（细噪点 + 竖向纤维）。
它**只扰动 RGB、完全不碰 alpha**，所以材质没挂上或编译失败都只是「少了纸纹」，
不会让面板透明或遮住文字——这是刻意的低风险设计。挂在 `UI.apply_paper(control)`。

### 改 UI 前先看设计稿

`tools/ui_mockup.py` 用**项目真实的字体、背景图、立绘**，把上述设计令牌与几何
一比一渲染成 PNG（同一套几何、只换设计变量），所以不用开 Godot 就能快速迭代：

```bash
python3 tools/ui_mockup.py                  # 当前设计
python3 tools/ui_mockup.py --variant paper  # 和纸方案
python3 tools/ui_mockup.py --variant all    # 两套都出（做前后对比）
# 输出在 tools/_ui/，成品设计稿见 预览/UI设计稿.png
```

⚠ 它是**设计稿不是引擎截图**：字体度量与容器自动布局会有像素级出入，
改完仍要在 Godot 里 F5 实跑确认（尤其换行与动态尺寸）。
⚠ 改 UI 文案时注意：中文字体是**子集化**的，只有出现在项目文本文件里的字才有字形。
若必须用新字，得重跑 `tools/make_font.py`（依赖 `fontTools`，本机未安装）。
