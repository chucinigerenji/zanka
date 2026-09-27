extends RefCounted
## 角色资料库：显示名、名牌配色、立绘路径、语音/图标等。

const NAMES := {
	"shiori": "三浦 栞",
	"yuto": "冈田 悠人",
	"me": "悠人",
	"hitomi": "佐野 瞳",
	"fumi": "冈田 富美",
	"chizuru": "三浦 千鹤",
	"daikan": "大贯 医生",
	"hamaguchi": "浜口 源治",
	"seiichi": "冈田 诚一",
	"kiryu": "桐生 正人",
	"misaki": "冈田 美咲",
	"akira": "三浦 晓",
	"hayami": "早见 老师",
	"nagabe": "长谷部 店长",
	"narrator": "",
	"": "",
}

const COLORS := {
	"shiori": Color(0.85, 0.88, 0.95),
	"yuto": Color(0.86, 0.82, 0.74),
	"me": Color(0.86, 0.82, 0.74),
	"hitomi": Color(0.98, 0.80, 0.62),
	"fumi": Color(0.82, 0.84, 0.78),
	"chizuru": Color(0.78, 0.80, 0.86),
	"daikan": Color(0.80, 0.86, 0.82),
	"hamaguchi": Color(0.86, 0.72, 0.66),
	"seiichi": Color(0.78, 0.76, 0.72),
	"kiryu": Color(0.72, 0.74, 0.80),
	"misaki": Color(0.90, 0.82, 0.84),
	"akira": Color(0.92, 0.86, 0.70),
	"hayami": Color(0.84, 0.84, 0.90),
	"nagabe": Color(0.80, 0.84, 0.84),
}

## 立绘 id -> 文件。全部由 Local Dream 生成于 assets/char/。
const SPRITES := {
	"shiori_normal": "res://assets/char/char_shiori_uniform_normal.png",
	"shiori_smile": "res://assets/char/char_shiori_uniform_smile.png",
	"shiori_sad": "res://assets/char/char_shiori_uniform_sad.png",
	"shiori_casual": "res://assets/char/char_shiori_casual.png",
	"shiori_weak": "res://assets/char/char_shiori_weak.png",
	"hitomi": "res://assets/char/char_hitomi_uniform.png",
	"fumi": "res://assets/char/char_fumi.png",
	"chizuru": "res://assets/char/char_chizuru.png",
	"daikan": "res://assets/char/char_daikan.png",
	"hamaguchi": "res://assets/char/char_hamaguchi.png",
	"seiichi": "res://assets/char/char_seiichi.png",
	"kiryu": "res://assets/char/char_kiryu.png",
	"yuto": "res://assets/char/char_yuto.png",
}

static func base_id(sprite_id: String) -> String:
	var p: int = sprite_id.find("_")
	return sprite_id if p < 0 else sprite_id.substr(0, p)

static func display_name(speaker_id: String) -> String:
	if speaker_id.is_empty():
		return ""
	if NAMES.has(speaker_id):
		return NAMES[speaker_id]
	return base_id(speaker_id)

static func name_color(speaker_id: String) -> Color:
	if COLORS.has(speaker_id):
		return COLORS[speaker_id]
	var b: String = base_id(speaker_id)
	return COLORS.get(b, Color(0.9, 0.9, 0.9))

static func sprite_path(sprite_id: String) -> String:
	return SPRITES.get(sprite_id, "")

static func is_known_speaker(speaker_id: String) -> bool:
	return speaker_id.is_empty() or NAMES.has(speaker_id)
