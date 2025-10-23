//https://godotshaders.com/shader/fears-to-fathom-shader/
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;

uniform float aberration_strength : hint_range(0.0, 5.0) = 3.0;
uniform float blur_strength : hint_range(0.0, 3.0) = 2.0;
uniform float noise_strength : hint_range(0.0, 0.3) = 0.048;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.78;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.016;
uniform float distortion_strength : hint_range(0.0, 1.0) = 0.1;
uniform float ghost_strength : hint_range(0.0,0.3)=0.12;
uniform float flicker_strength : hint_range(0.0, 0.1) = 0.005; 

float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898,78.233))) * 43758.5453);
}

vec3 blur_sample(vec2 uv) {
    vec2 texel = 1.0 / vec2(textureSize(screen_tex,0));
    vec3 col = texture(screen_tex, uv).rgb;
    col += texture(screen_tex, uv + vec2(texel.x, 0.0)).rgb;
    col += texture(screen_tex, uv - vec2(texel.x, 0.0)).rgb;
    col += texture(screen_tex, uv + vec2(0.0, texel.y)).rgb;
    col += texture(screen_tex, uv - vec2(0.0, texel.y)).rgb;
    return col / 5.0;
}

void fragment() {
    vec2 uv = SCREEN_UV;

    float wave = sin(uv.y * 200.0 + TIME * 10.0) * 0.002 * distortion_strength;
    uv.x += wave;

    uv.y += (rand(vec2(uv.y * 100.0, TIME * 10.0)) - 0.5) * 0.002;

    vec2 offset = (uv - 0.5) * 0.004 * aberration_strength;
    float r = texture(screen_tex, uv + offset).r;
    float g = texture(screen_tex, uv).g;
    float b = texture(screen_tex, uv - offset).b;
    vec3 col = vec3(r, g, b);


    col = mix(col, blur_sample(uv), blur_strength);


    vec2 ghost_uv = uv;
    ghost_uv.x -= 0.01;
    vec3 ghost_col = texture(screen_tex, ghost_uv).rgb;
    col = mix(col, ghost_col, ghost_strength);

    float scanline = sin(uv.y * 800.0 + sin(TIME*5.0)*10.0) * 0.5 + 0.5;
    col *= 1.0 - scanline * scanline_strength;


    float noise = (rand(uv * TIME * 50.0) - 0.5) * 2.0 * noise_strength;
    col += noise;


    float dist = distance(uv, vec2(0.5));
    float vignette = smoothstep(0.6, 0.9, dist);
    col *= mix(1.0, 1.0 - vignette, vignette_strength);

    float flicker = 1.0 + flicker_strength * (sin(TIME * 50.0) + (rand(vec2(TIME*10.0,0.0))-0.5));
    col *= flicker;

    COLOR = vec4(col, 1.0);
}
