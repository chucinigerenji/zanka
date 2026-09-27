shader_type canvas_item;

// 背景锐化：512px 原图放大到 1280 宽后偏软，用轻微 unsharp mask 找回一点细节。
// 同时保留一点胶片颗粒感，让「柔」看起来是有意为之。

uniform float sharpness : hint_range(0.0, 1.5) = 0.45;
uniform float grain : hint_range(0.0, 0.15) = 0.028;
uniform float grain_speed = 12.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE;
	vec4 src = texture(TEXTURE, UV);
	vec3 blur = (texture(TEXTURE, UV + vec2(px.x, 0.0)).rgb
		+ texture(TEXTURE, UV - vec2(px.x, 0.0)).rgb
		+ texture(TEXTURE, UV + vec2(0.0, px.y)).rgb
		+ texture(TEXTURE, UV - vec2(0.0, px.y)).rgb) * 0.25;
	vec3 c = src.rgb + (src.rgb - blur) * sharpness;

	// 颗粒（按屏幕坐标，不随图片缩放变化）
	float n = hash(floor(SCREEN_UV * vec2(1920.0, 1080.0)) + vec2(TIME * grain_speed));
	c += (n - 0.5) * grain;

	COLOR = vec4(clamp(c, vec3(0.0), vec3(1.0)), src.a);
}
