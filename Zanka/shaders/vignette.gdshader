shader_type canvas_item;

// 暗角 / 病征演出：强度由 effect_level 与剧本 @fx 控制。
uniform float strength : hint_range(0.0, 1.5) = 0.0;

void fragment() {
	vec2 d = UV - vec2(0.5);
	d.x *= 0.5625;                       // 1280x720 -> 让暗角在视觉上是正圆
	float dist = length(d);
	float v = smoothstep(0.28, 0.62, dist) * strength;
	COLOR = vec4(0.0, 0.0, 0.0, clamp(v, 0.0, 1.0));
}
