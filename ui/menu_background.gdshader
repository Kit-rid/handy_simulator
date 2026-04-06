shader_type canvas_item;

// --- HOW TO TUNE THIS BACKGROUND ---
// 1) Измени color_a / color_b / glow_color
// 2) speed > 0.0 ускоряет анимацию
// 3) noise_strength усиливает «живость» фона

uniform vec4 color_a : source_color = vec4(0.03, 0.06, 0.12, 1.0);
uniform vec4 color_b : source_color = vec4(0.08, 0.17, 0.32, 1.0);
uniform vec4 glow_color : source_color = vec4(0.24, 0.58, 1.0, 1.0);
uniform float speed : hint_range(0.0, 3.0) = 0.45;
uniform float noise_strength : hint_range(0.0, 0.25) = 0.10;
uniform float glow_strength : hint_range(0.0, 1.0) = 0.34;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 34.345);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * speed;

	float n = noise(uv * 5.2 + vec2(t * 0.5, -t * 0.35));
	float n2 = noise(uv * 10.0 + vec2(-t * 0.8, t * 0.4));
	float combined = mix(n, n2, 0.5);

	vec4 base = mix(color_a, color_b, uv.y + combined * noise_strength);

	float glow = smoothstep(0.55, 0.0, distance(uv, vec2(0.25 + sin(t * 0.55) * 0.12, 0.28 + cos(t * 0.45) * 0.10)));
	float glow2 = smoothstep(0.62, 0.0, distance(uv, vec2(0.78 + cos(t * 0.40) * 0.10, 0.74 + sin(t * 0.35) * 0.08)));

	vec3 final_rgb = base.rgb + glow_color.rgb * (glow + glow2) * glow_strength;
	COLOR = vec4(final_rgb, 1.0);
}
