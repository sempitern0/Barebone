shader_type spatial;

uniform sampler2D noise_texture;
uniform bool realistic = false;
uniform float speed : hint_range(0.0, 1.0) = 0.005;
uniform float brightness : hint_range(0.0, 2.0) = 0.6;
uniform float coverage : hint_range(0.0, 2.0) = 1.0;
uniform float fluffiness : hint_range(0.0, 2.0) = 0.3; 
uniform float threshold : hint_range(0.0, 2.0) = 1.2;
uniform float contrast : hint_range(0.5, 3.0) = 1.2;  


void fragment() {
	vec2 uv1 = fract(UV + TIME * speed * 0.3);
	vec2 uv2 = fract(UV + TIME * speed * (0.3 + fluffiness));

	vec4 noise_1 = texture(noise_texture, uv1);
	vec4 noise_2 = texture(noise_texture, uv2);
	
	if (realistic) {
		float noise_mix = (noise_1.r + noise_2.r * 1.2) * 0.5;
		float cloud_value = pow(noise_mix, contrast);

		cloud_value = cloud_value * coverage;

		ALBEDO = vec3(cloud_value) * brightness;
		ALPHA = smoothstep(0.25, 0.6, cloud_value);
	} else {
		vec4 combined_noise = noise_1 + noise_2;

		ALBEDO = combined_noise.rgb * brightness;
		ALPHA = 1.0;
		if (combined_noise.r < threshold) {
			ALPHA = 0.0;
		}
	}
}
