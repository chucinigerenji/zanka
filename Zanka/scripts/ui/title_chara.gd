extends Control
## 标题画面的立绘轮播：随机逐张播放全部立绘，约 30 秒换一个；
## 人物左上角挂一个聊天气泡，内容是游戏贴士或角色的心里话；点气泡换下一条。
##
## 为什么单独一个脚本：title_screen.gd 已经负责菜单与两个子面板，
## 这块「会自己动」的演出塞进去会让那个文件更难读。

const UI := preload("res://scripts/core/ui_theme.gd")
const Kit := preload("res://scripts/core/ui_kit.gd")
const CharDB := preload("res://scripts/core/char_db.gd")

const SWITCH_SEC := 30.0        ## 换角色的间隔（秒）
const SPRITE_H_RATIO := 0.74    ## 立绘高度占屏高
const CENTER_X := 0.76          ## 立绘中心横坐标（标题右侧那片空位）
const BUBBLE_W := 310           ## 气泡宽度（高度随文字自动长）
const THINK_SEC := 0.72         ## 「思考」时长：这段时间气泡里只跳点点
const DOT_STEP := 0.17          ## 点点切换间隔
const DOT := "…"           ## 思考中的点点（省略号，字体有字形）
const TOUCH_THINK := 0.34      ## 点部位时的思考时长（比换文案短，戳着玩不拖）

## 轮播的全部立绘（栞的五个表情算五张，按需求「播放全部立绘」）
const CAST := [
	"shiori_normal", "shiori_smile", "shiori_sad", "shiori_casual", "shiori_weak",
	"hitomi", "fumi", "chizuru", "daikan", "hamaguchi", "seiichi", "kiryu", "yuto",
]

## 每个角色 ~10 条：一半是游戏贴士，一半是贴合剧情的心里话。
## ⚠ 只允许用中文字体子集里已有的字，否则真机会渲染成豆腐块 □。
##    改动这里之后，务必跑：
##      python3 tools/check_font_coverage.py scripts/ui/title_chara.gd
const LINES := {
	"shiori": [
		"点我一下，我会再说一句。",
		"存档是自由的。你不用管我。",
		"游戏里没有正确答案。只有你选哪一种以后。",
		"傍晚五点的町内放送，是全町的孩子回家的时间。",
		"关东煮，到夜里十点就不好吃了。",
		"我不太喜欢做长期打算。",
		"如果明年这里要拆，你会来看最后一眼吗？",
		"今天很好。今天很好就够了。",
		"你奶奶的药，早上和晚上不一样。别搞错。",
		"主线走完，还有别的结局在等你。",
	],
	"yuto": [
		"手机转过来放，手指点屏幕就能推进对话。",
		"右上角那排是：回想、自动、跳过、存档、菜单。",
		"左上角的日期可以点，里面是汐浦港的潮汐表。",
		"这张潮汐表，从六月的第一天就贴在我房间的墙上。",
		"我顺路。真的顺路。",
		"奶奶下周二复诊。我记着。",
		"存档位有六个，还有一个自动档。",
		"想回头看刚才那一句，就点回想。",
		"海边的风，晚上比白天凉。",
		"设置里可以把文字速度调快一点。",
	],
	"hitomi": [
		"你俩能不能别在我面前演那种戏，我午饭要出来了。",
		"我不是没考上。我是没报名。",
		"你走吧。真的。这里总得有人留下，但不一定是你。",
		"便利店的半价便当，晚上八点开抢。",
		"选项会记住你选过什么。想反悔就读档。",
		"在大地图上选时段，选了就算过了一天。",
		"信写错了没关系。反正也寄不出去。",
		"对话可以自动播放。一边吃饭一边看。",
		"医院走廊的自动贩卖机，咖啡一百二十日元。",
		"我在这儿守着。你去过你自己的。",
	],
	"fumi": [
		"悠人。你什么时候长这么高了。",
		"奶奶活够了。你去过你自己的。",
		"你谁家的孩子？",
		"傍晚五点左右，我会重复问同一件事。不要纠正我，顺着说就好。",
		"我要回家。",
		"今天的饭，比昨天香。",
		"你妈走的那天，你才到这儿。",
		"记不得喽。",
		"（她看着窗外，很久没有说话。）",
		"在这个游戏里，你也可以慢慢陪一个老人坐一会儿。",
	],
	"chizuru": [
		"我星期三、五、日在这里。",
		"她跟我说，她今年哪都不去。",
		"栞，妈妈不治了。",
		"你上次也这么说。然后你去了。",
		"所以我们都不算数，就这样过吧。",
		"透析要四个小时。来回还要两个小时。",
		"冈田同学。她要是跟你说什么，你就听着。",
		"别怪她。",
		"那句谢谢，我说不出口。",
		"这个游戏里，最安静的地方最痛。",
	],
	"daikan": [
		"小姑娘，我这里只能看感冒。",
		"你去市里。别在这儿耽误。",
		"我这话说了三年了。没有一个人去。",
		"町里的诊所只有我一个人。",
		"有些病不是治不好，是这里看不了。",
		"要开主治医师意见书？找我。我写字很快。",
		"游戏里那份表格，你也要一页一页填。",
		"睡不着的时候，就把文字速度调慢一点。",
		"我今年六十二。一个人守着这间屋子。",
		"你要是难受，就先存个档，明天再回来。",
	],
	"hamaguchi": [
		"我不欠你们家的了。",
		"这事我记了三十年。",
		"你告诉她，我不恨她爹了。",
		"我孙子今年八岁。也是这个病。",
		"三十年前，我在那个厂干了七个月。",
		"信封上的名字，是我自己写上去的。",
		"想全收集，就每个结局都走一遍。",
		"第二周目再看一遍，你会看到不一样的东西。",
		"那本子上的字，我看懂了。",
		"海上的活儿，看天吃饭。",
	],
	"seiichi": [
		"酒没了就去买。别站那儿看我。",
		"渔船份额。你爷爷的，你太爷爷的。到我这代，第三份。",
		"卖了。",
		"那姑娘不错。",
		"你妈走的那天，我什么也没说。",
		"有些话我说不出来。就这么过去了。",
		"想看全部结局，得走三周目。",
		"跳过只跳已读的。没读过的会停下来。",
		"觉得画面在动，可以在设置里关掉。",
		"家里的事，不用你一个人扛。",
	],
	"kiryu": [
		"你是冈田同学吧。",
		"她的治疗费，我在出。",
		"我没有别的意思。",
		"我只是……也不知道该怎么对一个人好。",
		"我从来没想过要她死。",
		"我跟你说的这件事，不会有第二个人知道。",
		"游戏里有些事，是不能反悔的。",
		"存档救得了进度。救不了做过的事。",
		"我也一个人。一个人很久了。",
		"终章之前，先存个档吧。",
	],
}

## 可点部位：归一化到「立绘实际绘制矩形」内的区域（0~1）。
## 顺序就是命中优先级；arm 放在最后当兜底，它有两个框（左右各一）。
const PARTS := [
	{"id": "face", "rects": [Rect2(0.33, 0.01, 0.34, 0.19)]},
	{"id": "chest", "rects": [Rect2(0.30, 0.21, 0.40, 0.20)]},
	{"id": "belly", "rects": [Rect2(0.30, 0.41, 0.40, 0.24)]},
	{"id": "arm", "rects": [Rect2(0.00, 0.18, 0.28, 0.62), Rect2(0.72, 0.18, 0.28, 0.62)]},
]

## 点不同部位说的话（每部位 3 条，循环播放）。
## 外层的 key 是角色 id（char_db 的 base_id），所以栞的五个表情共用一套。
const PART_LINES := {
	"shiori": {
		"face": ["……我脸上有什么吗。", "头发是我自己修的。", "别看太久。"],
		"chest": ["……你在看哪里。", "（她把书包抱紧了一点。）", "这里没什么好看的。"],
		"belly": ["我午饭没吃。", "不吃的时候，它自己会响。", "……不要指这里。"],
		"arm": ["手上这个，不摘的。", "（她把袖子往下拉了拉。）", "这边的袖子洗得发白。"],
	},
	"yuto": {
		"face": ["我比别人黑。", "（他碰了一下脸。）", "没睡好而已。"],
		"chest": ["校服袖口我总是卷着。", "（他把领子理了理。）", "没什么可看的。"],
		"belly": ["中午吃的是饭团。", "不吃也就不觉得了。", "……别碰。"],
		"arm": ["右手有道旧伤。", "跟爸出海的时候伤到的。", "（他把手翻过来给你看。）"],
	},
	"hitomi": {
		"face": ["看什么看，我脸上有东西？", "我笑起来是不是很响。", "别看我。"],
		"chest": ["我说，往哪儿看呢。", "……你这人真的。", "（她抬起手。）"],
		"belly": ["半价便当，两个。", "想吃就吃，别客气。", "（她拍了拍身上。）"],
		"arm": ["搬货搬出来的。", "我搬东西比你快。", "（她比了比手。）"],
	},
	"fumi": {
		"face": ["……你是谁家的孩子？", "（她看着你。）", "我认得你的脸。"],
		"chest": ["（她把手放在心口。）", "这里，有时候会痛。", "老了。"],
		"belly": ["今天吃了两碗饭。", "你吃了吗？", "（她拍了拍你的手。）"],
		"arm": ["手上有洗碗的味道。", "（她的手很暖。）", "扶我一下。"],
	},
	"chizuru": {
		"face": ["……我脸上有病气吧。", "不用为我难过。", "（她别过脸。）"],
		"chest": ["这里没什么好看的。", "（她拉了拉外衣。）", "你别问了。"],
		"belly": ["透析的日子，吃不下。", "星期三、五、日。", "（她按住这里。）"],
		"arm": ["（手上都是点。）看多了就好。", "（手上有一片印子。）", "别看了。"],
	},
	"daikan": {
		"face": ["我这张脸，看了三十年病。", "（他抬眼看了看你。）", "老了，不中用。"],
		"chest": ["听诊器在这儿挂了一辈子。", "白色的外衣洗得发白。", "没什么可看的。"],
		"belly": ["中午吃的是便利店的面。", "一个人住，随便吃点。", "（他笑了一下。）"],
		"arm": ["写字写得太多了。", "意见书，我写得很快。", "（他活动了一下手。）"],
	},
	"hamaguchi": {
		"face": ["看什么看。", "（他看了你一眼。）", "我这张脸不好看。"],
		"chest": ["（他把外衣拉上。）", "在海里五十年了。", "别看。"],
		"belly": ["早上吃了两碗饭。", "干活的，吃得多。", "（他拍了拍腰带。）"],
		"arm": ["提东西提的。", "（他握了握手。）", "比你脸还大。"],
	},
	"seiichi": {
		"face": ["……看我干什么。", "（他没回头。）", "去写作业。"],
		"chest": ["（他把烟按掉。）", "没什么好说的。", "别站那儿。"],
		"belly": ["酒没了就去买。", "（他翻了翻口袋。）", "不吃。"],
		"arm": ["船上的活，都是手干的。", "（他手上都是老皮。）", "让开。"],
	},
	"kiryu": {
		"face": ["……我的脸上有什么吗。", "（他笑了一下。）", "不用这么看我。"],
		"chest": ["西装是旧的。", "（他理了理领口。）", "我不打领带。"],
		"belly": ["中午在车里吃的。", "一个人，随便。", "（他看了看表。）"],
		"arm": ["（他收回手。）", "我不喜欢被人碰。", "对不起。"],
	},
}

var _sprite: TextureRect
var _bubble: PanelContainer
var _name_label: Label
var _line_label: Label
var _tail: Polygon2D
var _tex_cache: Dictionary = {}
var _missing: Dictionary = {}

var _drawn: Rect2 = Rect2()        # 立绘实际画出来的矩形（算部位命中和气泡位置都用它）
var _part_idx: Dictionary = {}     # 部位 -> 下一条要播第几条
var _hit: Control                  # 覆盖立绘的点击层
var _cur: String = ""
var _line_idx: int = 0
var _t: float = 0.0
var _busy: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_sprite = TextureRect.new()
	_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sprite.modulate.a = 0.0
	add_child(_sprite)

	# 立绘点击层：铺满整块，用来判断点到了哪个部位。
	# ⚠ 必须加在气泡【之前】：Godot 的输入是从后往前派发的，
	#   加在气泡后面会把气泡自己的点击吃掉，气泡就点不动了。
	_hit = Control.new()
	_hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hit.mouse_filter = Control.MOUSE_FILTER_STOP
	_hit.gui_input.connect(_on_sprite_input)
	_hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_child(_hit)

	# 气泡：半透明磨砂圆角 + 1px 亮边，点它换下一条
	_bubble = PanelContainer.new()
	_bubble.mouse_filter = Control.MOUSE_FILTER_STOP
	_bubble.add_theme_stylebox_override("panel",
		UI.flat(Color(0.985, 0.976, 0.957, 0.880), 16, UI.C_LINE, 1, 20, 14))
	_bubble.custom_minimum_size = Vector2(BUBBLE_W, 0)
	_bubble.gui_input.connect(_on_bubble_input)
	add_child(_bubble)

	var v := Kit.vbox(6)
	_bubble.add_child(v)
	_name_label = Kit.label("", 16, UI.C_ACCENT)
	v.add_child(_name_label)
	_line_label = Kit.label("", 20, UI.C_TEXT)
	_line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line_label.custom_minimum_size = Vector2(BUBBLE_W - 40, 0)
	v.add_child(_line_label)

	# 气泡的小尾巴，指向人物
	_tail = Polygon2D.new()
	_tail.polygon = PackedVector2Array([Vector2(0, 0), Vector2(24, 0), Vector2(5, 19)])
	_tail.color = Color(0.985, 0.976, 0.957, 0.880)
	add_child(_tail)

	resized.connect(_layout)
	next_chara()
	call_deferred("_layout")


func _process(delta: float) -> void:
	# 标题画面不可见时（进了游戏 / 被弹窗盖住）就停表，别在后台空转；
	# 正在「思考」时也不打表，免得刚说完就被换掉。
	if not is_visible_in_tree() or _busy:
		return
	_t += delta
	if _t >= SWITCH_SEC:
		_t = 0.0
		next_chara()


# ---------------------------------------------------------------- 展示逻辑

func next_chara() -> void:
	# 随机挑一个「跟当前不同」的立绘，避免连续两次同一张
	if _busy:
		return
	var pick := _cur
	for _i in range(8):
		pick = CAST[randi() % CAST.size()]
		if pick != _cur:
			break
	_cur = pick
	var pool: Array = LINES.get(CharDB.base_id(_cur), [])
	_line_idx = randi() % max(1, pool.size())
	_part_idx.clear()          # 换人了，各部位的「说到第几条」也重来
	await _speak(str(pool[_line_idx]) if not pool.is_empty() else "", true)
	_t = 0.0


func next_line() -> void:
	# 同一个角色换下一条
	if _busy:
		return
	var pool: Array = LINES.get(CharDB.base_id(_cur), [])
	if pool.is_empty():
		return
	_line_idx = (_line_idx + 1) % pool.size()
	await _speak(str(pool[_line_idx]), false)
	_t = 0.0          # 点了就重新计时，别刚看完就换人


func _on_bubble_input(ev: InputEvent) -> void:
	var tapped := false
	if ev is InputEventMouseButton and ev.pressed \
			and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		tapped = true
	elif ev is InputEventScreenTouch and ev.pressed:
		tapped = true
	if tapped and not _busy:
		AudioManager.play_se("select")
		next_line()


## 点在立绘上：判断戳到了哪个部位，说那句对应的话。
func _on_sprite_input(ev: InputEvent) -> void:
	var local := Vector2.ZERO
	var tapped := false
	if ev is InputEventMouseButton and ev.pressed \
			and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		local = (ev as InputEventMouseButton).position
		tapped = true
	elif ev is InputEventScreenTouch and ev.pressed:
		local = (ev as InputEventScreenTouch).position
		tapped = true
	if not tapped or _busy:
		return
	var part := _part_at(local)
	if part.is_empty():
		return                 # 点在立绘外面（比如左侧菜单那边），不管
	_touch(part)


## 把点击坐标换算成「立绘实际矩形内的归一化坐标」，再逐个部位框去比。
## 用实际绘制矩形而不是控件矩形：KEEP_ASPECT_CENTERED 会在控件里留白边。
func _part_at(local: Vector2) -> String:
	if _drawn.size.x <= 0.0 or _drawn.size.y <= 0.0 or not _drawn.has_point(local):
		return ""
	var u := (local.x - _drawn.position.x) / _drawn.size.x
	var v := (local.y - _drawn.position.y) / _drawn.size.y
	var uv := Vector2(u, v)
	for p in PARTS:
		for r in p["rects"]:
			if (r as Rect2).has_point(uv):
				return str(p["id"])
	return ""


## 说一句「被戳到」的反应。同一个部位连着点会往后轮。
func _touch(part: String) -> void:
	var by_char: Dictionary = PART_LINES.get(CharDB.base_id(_cur), {})
	var pool: Array = by_char.get(part, [])
	if pool.is_empty():
		return
	_part_idx[part] = (int(_part_idx.get(part, -1)) + 1) % pool.size()
	AudioManager.play_se("select")
	await _speak(str(pool[int(_part_idx[part])]), false, TOUCH_THINK)
	_t = 0.0


## 让角色「开口说话」的完整过程：
##   旧文字淡出 → 气泡里跳点点（像在斟酌怎么说）→ 新文字淡入 + 气泡轻弹一下。
## swap_chara 为真时顺带换立绘（旧立绘先淡出，新立绘在说完之后才淡入）。
func _speak(line: String, swap_chara: bool, think: float = THINK_SEC) -> void:
	_busy = true
	if swap_chara:
		var out := create_tween()
		out.tween_property(_sprite, "modulate:a", 0.0, 0.30)
		await out.finished
		var tex := _get_tex(_cur)
		if tex != null:
			_sprite.texture = tex
		_name_label.text = CharDB.display_name(CharDB.base_id(_cur))
		_layout()
	# 旧文字淡出
	var fade := create_tween()
	fade.tween_property(_line_label, "modulate:a", 0.0, 0.14)
	await fade.finished
	# 思考中：只跳点点
	var acc := 0.0
	var dots := 1
	_line_label.text = DOT
	_line_label.modulate.a = 1.0
	_layout()
	while acc < think and is_visible_in_tree():
		await get_tree().create_timer(DOT_STEP).timeout
		acc += DOT_STEP
		dots = (dots % 3) + 1
		_line_label.text = DOT.repeat(dots)
		_layout()
	# 说出新的一句
	_line_label.text = line
	_layout()
	_line_label.modulate.a = 0.0
	create_tween().tween_property(_line_label, "modulate:a", 1.0, 0.22)
	# 气泡以中心为轴轻弹一下（改 pivot 免得位置跑偏）
	_bubble.pivot_offset = _bubble.size * 0.5
	_bubble.scale = Vector2(0.965, 0.94)
	create_tween().tween_property(_bubble, "scale", Vector2.ONE, 0.26) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if swap_chara:
		create_tween().tween_property(_sprite, "modulate:a", 1.0, 0.45)
	else:
		_sprite.modulate.a = 1.0
	_busy = false


func _get_tex(sprite_id: String) -> Texture2D:
	if _tex_cache.has(sprite_id):
		return _tex_cache[sprite_id]
	if _missing.has(sprite_id):
		return null
	var path: String = CharDB.sprite_path(sprite_id)
	if path.is_empty() or not ResourceLoader.exists(path):
		_missing[sprite_id] = true
		return null
	var tex := load(path) as Texture2D
	_tex_cache[sprite_id] = tex
	return tex


# ---------------------------------------------------------------- 排版

func _layout() -> void:
	if _sprite == null or size.x <= 0.0:
		return
	var sh := size.y * SPRITE_H_RATIO
	var cx := size.x * CENTER_X
	var box := Rect2(cx - sh * 0.5, size.y - sh, sh, sh)
	_sprite.position = box.position
	_sprite.size = box.size

	# KEEP_ASPECT_CENTERED 实际画出来的矩形
	var ar := 1.0
	if _sprite.texture != null and _sprite.texture.get_height() > 0:
		ar = float(_sprite.texture.get_width()) / float(_sprite.texture.get_height())
	var dh := box.size.y
	var dw := dh * ar
	if dw > box.size.x:
		dw = box.size.x
		dh = dw / ar
	var drawn := Rect2(box.position.x + (box.size.x - dw) * 0.5,
		box.position.y + (box.size.y - dh) * 0.5, dw, dh)
	_drawn = drawn

	# 气泡贴在立绘左上角；reset_size 让它按文字算出自身高度
	_bubble.reset_size()
	var bw := _bubble.size.x
	var bh := _bubble.size.y
	# 锚在「底边贴住立绘头顶」：文字变多时气泡向上长，不会整块上下跳
	var bx := clampf(drawn.position.x + 4.0, 8.0, maxf(8.0, size.x - bw - 8.0))
	var bottom := maxf(bh + 8.0, drawn.position.y - 8.0)
	_bubble.position = Vector2(bx, bottom - bh)
	if _tail != null:
		_tail.position = Vector2(bx + 26.0, bottom - 2.0)
