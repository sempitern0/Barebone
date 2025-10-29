shader_type canvas_item;

uniform sampler2D mask_texture : repeat_disable, filter_nearest;
uniform vec2 mask_resolution = vec2(256.0, 256.0);
uniform float texel_smoothness : hint_range(0.0, 2.0) = 1.0;

uniform vec4 region_rect_uv_data;

float sample_mask(vec2 uv) {
    float v = 0.0;

    vec2 texel = texel_smoothness / mask_resolution;

    v += texture(mask_texture, uv).r;
    v += texture(mask_texture, uv + vec2(texel.x, 0.0)).r;
    v += texture(mask_texture, uv - vec2(texel.x, 0.0)).r;
    v += texture(mask_texture, uv + vec2(0.0, texel.y)).r;
    v += texture(mask_texture, uv - vec2(0.0, texel.y)).r;

    return v / 5.0;
}

void fragment() {
    vec4 base_color = texture(TEXTURE, UV);
    vec2 region_uv = (UV - region_rect_uv_data.xy) / region_rect_uv_data.zw;
    float mask_value = sample_mask(region_uv);

    base_color.a *= mask_value;
    COLOR = base_color;
}
