// https://www.youtube.com/watch?v=VkmTr5WBjF8
shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, repeat_disable, filter_nearest;
// This viewport_size is not automatic, this needs to be changed with a script
// with your current project resolution settings.
uniform vec2 viewport_size = vec2(1280, 720);
uniform vec2 virtual_resolution = vec2(320, 180);

const float ps1_dither[16] = float[16](
	-4.0, 0.0, -3.0, 1.0,
	2.0, -2.0, 3.0, -1.0,
	-3.0, 1.0, -4.0, 0.0,
	3.0, -1.0, 2.0, -2.0
);

void fragment() {
	vec3 screen_color = texture(SCREEN_TEXTURE, UV).rgb;

	vec2 virtual_position = floor(FRAGCOORD.xy * (virtual_resolution / viewport_size));
	int x = int(virtual_position.x) % 4;
	int y = int(virtual_position.y) % 4;
	int index = y * 4 + x;
	float dither_offset = (ps1_dither[index] / 8.0);

	vec3 quantized_color = floor( (screen_color * 255.0) / 8.0 + dither_offset) / 31.0;

	COLOR = vec4(quantized_color, 1);
}
