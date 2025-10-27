// Useful to achieve PSX graphics on simple models where the 
// vertex snapping it's not neeeded
shader_type spatial;
render_mode blend_mix, cull_disabled, depth_prepass_alpha, shadows_disabled, specular_disabled, vertex_lighting;

uniform sampler2D albedo_tex : source_color, filter_nearest;
uniform float pixelation = 128.0; 

void fragment() {
    vec2 uv = floor(UV * pixelation) / pixelation;  
    vec4 tex = texture(albedo_tex, uv);
    
    ALBEDO = tex.rgb;
    ALPHA = tex.a;
}
