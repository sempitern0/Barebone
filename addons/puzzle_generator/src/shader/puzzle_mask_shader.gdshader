shader_type canvas_item;

uniform sampler2D mask_texture : repeat_disable, filter_nearest;
uniform vec2 mask_resolution = vec2(256.0, 256.0);
uniform vec4 region_rect_uv_data;

uniform bool outline = true;
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_thickness : hint_range(1.0, 16.0) = 3.0;
uniform float outline_softness : hint_range(0.0, 4.0) = 2.0;


float get_mask_soft(vec2 uv) {
    vec2 px = 1.0 / mask_resolution;

    float c  = texture(mask_texture, uv).r * 0.4;
    float n  = texture(mask_texture, uv + vec2(0.0,  px.y)).r * 0.1;
    float s  = texture(mask_texture, uv + vec2(0.0, -px.y)).r * 0.1;
    float e  = texture(mask_texture, uv + vec2( px.x, 0.0)).r * 0.1;
    float w  = texture(mask_texture, uv + vec2(-px.x, 0.0)).r * 0.1;
    float ne = texture(mask_texture, uv + vec2( px.x,  px.y)).r * 0.05;
    float nw = texture(mask_texture, uv + vec2(-px.x,  px.y)).r * 0.05;
    float se = texture(mask_texture, uv + vec2( px.x, -px.y)).r * 0.05;
    float sw = texture(mask_texture, uv + vec2(-px.y, -px.x)).r * 0.05;

    return c + n + s + e + w + ne + nw + se + sw;
}

// Muestreo sin suavizado (para detectar bordes duros)
float get_mask(vec2 uv) {
    return texture(mask_texture, uv).r;
}


void fragment() {
    vec4 base_color = texture(TEXTURE, UV);
    vec2 region_uv = (UV - region_rect_uv_data.xy) / region_rect_uv_data.zw;

    float m_soft = get_mask_soft(region_uv);

 	if (!outline) {
        base_color.a *= m_soft;
        COLOR = base_color;
    } else {
	    float m = get_mask(region_uv);

	    vec2 px = outline_thickness / mask_resolution;

	    float n  = get_mask(region_uv + vec2(px.x, 0.0));
	    float s  = get_mask(region_uv - vec2(px.x, 0.0));
	    float e  = get_mask(region_uv + vec2(0.0, px.y));
	    float w  = get_mask(region_uv - vec2(0.0, px.y));
	    float ne = get_mask(region_uv + vec2(px.x, px.y));
	    float nw = get_mask(region_uv + vec2(-px.x, px.y));
	    float se = get_mask(region_uv + vec2(px.x, -px.y));
	    float sw = get_mask(region_uv + vec2(-px.x, -px.y));

	    bool is_edge = (m > 0.5) && (
	        n < 0.5 || s < 0.5 || e < 0.5 || w < 0.5 ||
	        ne < 0.5 || nw < 0.5 || se < 0.5 || sw < 0.5
	    );

	    vec4 out_color;

	    if (is_edge) {
	        float a = mix(1.0, m_soft, outline_softness);
	        out_color = vec4(outline_color.rgb, outline_color.a * a);
	    } else {
	        base_color.a *= m_soft;
	        out_color = base_color;
	    }

	    COLOR = out_color;
	}
}
