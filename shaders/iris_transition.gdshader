shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float aspect : hint_range(0.2, 4.0) = 1.7777;
uniform vec4 fill_color : source_color = vec4(0.02, 0.04, 0.09, 1.0);
uniform vec4 ring_color : source_color = vec4(0.25, 0.72, 0.98, 1.0);

void fragment() {
	vec2 uv = UV - vec2(0.5);
	uv.x *= aspect;
	float dist = length(uv);
	float max_r = length(vec2(0.5 * aspect, 0.5)) + 0.06;
	float r = mix(max_r, 0.0, progress);
	float edge = 0.018;
	float mask = smoothstep(r - edge, r + edge, dist);
	float ring = smoothstep(r - edge * 2.2, r, dist) * (1.0 - smoothstep(r, r + edge * 2.2, dist));
	vec3 col = mix(fill_color.rgb, ring_color.rgb, ring * 0.85 * step(0.01, progress) * step(progress, 0.99));
	COLOR = vec4(col, mask);
}
