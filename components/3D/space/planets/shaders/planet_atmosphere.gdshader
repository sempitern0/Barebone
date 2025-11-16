shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_back, unshaded;

uniform vec3 inner_color : source_color = vec3(0.00, 0.10, 0.25);
uniform vec3 outer_color : source_color = vec3(0.55, 0.75, 1.00);
uniform float alpha_base : hint_range(0.0, 1.0) = 0.35;
uniform float fresnel_power : hint_range(0.5, 12.0) = 5.0;
uniform float fresnel_intensity : hint_range(0.0, 8.0) = 3.5;
uniform float horizon_softness : hint_range(0.0, 5.0) = 1.2;
uniform float inner_brightness : hint_range(0.0, 2.0) = 0.35;
uniform bool emit_fresnel = true;


vec3 safe_normalize(vec3 v) {
	float len = max(length(v), 0.0001);
	return v / len;
}

vec3 compute_fresnel(vec3 normal, vec3 view) {
	normal = safe_normalize(normal);
	view   = safe_normalize(view);

	float d = clamp(dot(normal, view), 0.0, 1.0);

	float f = pow(1.0 - d, fresnel_power);
	return outer_color * f * fresnel_intensity;
}

float compute_height_fade(vec3 normal) {
	float h = clamp(normal.y * 0.5 + 0.5, 0.0, 1.0);
	return pow(h, horizon_softness);
}


void fragment() {
	vec3 N = safe_normalize(NORMAL);
	vec3 V = safe_normalize(VIEW);

	vec3 fresnel = compute_fresnel(N, V);
	float height_fade = compute_height_fade(N);

	vec3 base_color = mix(inner_color * inner_brightness, outer_color, height_fade);

	ALBEDO = base_color + fresnel;
	EMISSION = emit_fresnel ? fresnel : vec3(0.0);
	ALPHA = clamp(alpha_base * (0.6 + height_fade * 0.4), 0.0, 1.0);
}
