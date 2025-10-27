// Useful to achieve PSX graphics on simple models where the
// vertex snapping it's not neeeded
shader_type spatial;
render_mode blend_mix, cull_disabled, depth_prepass_alpha, shadows_disabled, specular_disabled, vertex_lighting;

uniform float pixelation = 128.0;
uniform sampler2D albedo_texture : source_color, filter_nearest;
uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec2 uv_scale = vec2(1.0, 1.0);


void fragment() {
    vec2 pixelated_uv = floor((UV * uv_scale) * pixelation) / pixelation;
    vec4 pixelated_texture = texture(albedo_texture, pixelated_uv);
    vec4 final_color = pixelated_texture * albedo_color;

    ALBEDO = final_color.rgb;
    ALPHA = final_color.a;
}

