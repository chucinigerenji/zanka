shader_type canvas_item;

// 和纸颗粒：给面板铺一层极轻的纸纹（细噪点 + 竖向纤维）。
//
// 设计约束（重要）：
//   只对 **RGB** 做扰动，**完全不碰 alpha**。
//   所以这个材质即使没挂上、或着色器编译失败，也只是「少了纸纹」，
//   不会让面板透明、消失或遮住文字。采样只用 SCREEN_UV，
//   不去读 TEXTURE —— StyleBoxFlat 是程序化绘制的，没有可采样的纹理。

uniform float grain : hint_range(0.0, 0.2) = 0.030;   // 细噪点强度
uniform float fiber : hint_range(0.0, 0.15) = 0.010;  // 竖向纤维强度
uniform float cells : hint_range(200.0, 3000.0) = 1400.0;  // 噪点密度

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	float n = hash(floor(SCREEN_UV * vec2(cells, cells * 0.5625)));
	float lane = hash(vec2(floor(SCREEN_UV.y * 180.0), 0.0));
	float f = sin(SCREEN_UV.x * 640.0 + lane * 6.283) * 0.5 + 0.5;
	float g = (n - 0.5) * grain + (f - 0.5) * fiber;
	COLOR = vec4(clamp(COLOR.rgb + g, vec3(0.0), vec3(1.0)), COLOR.a);
}
