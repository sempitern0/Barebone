// https://godotshaders.com/shader/procedural-sky-blended-cover-wind-and-clouds/
shader_type sky;
render_mode use_debanding;

uniform vec4 sky_top_color : source_color = vec4(0.385, 0.454, 0.55, 1.0);
uniform vec4 sky_horizon_color : source_color = vec4(0.646, 0.656, 0.67, 1.0);
uniform float sky_curve : hint_range(0, 1) = 0.15;
uniform float sky_energy = 1.0; // In Lux.
uniform sampler2D sky_cover : filter_linear, source_color, hint_default_black;
uniform vec4 sky_cover_modulate : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 ground_bottom_color : source_color = vec4(0.2, 0.169, 0.133, 1.0);
uniform vec4 ground_horizon_color : source_color = vec4(0.646, 0.656, 0.67, 1.0);
uniform float ground_curve : hint_range(0, 1) = 0.02;
uniform float ground_energy = 1.0;
uniform float sun_angle_max = 30.0;
uniform float sun_curve : hint_range(0, 1) = 0.15;
uniform float exposure : hint_range(0, 128) = 1.0;

// Wind offset direction (x and y only)
uniform vec2 wind_offset_direction = vec2(0.5, 0.1); // Control direction of offset (x, y)
uniform float wind_speed : hint_range(0.0, 25.0) = 1.0; // Speed of the noise movement over time

// Cloud change settings
uniform bool clouds_density = true; // Volumetric clouds
uniform bool clouds_change = true; // Whether to change the cloud layer or not
uniform float cloud_change_rate : hint_range(0.0, 5.0) = .40; // Rate at which the cloud effect changes

// Pole blending parameters
uniform float pole_blend_shape : hint_range(0.0, 2.0) = 0.05; // How much the noise affects the blend shape
uniform float pole_blend_strength : hint_range(0, 1) = 0.05; // Control blending intensity at poles
uniform float pole_blend_brightness : hint_range(0.0, 1.0) = .3;

// Horizon blending parameters - similar to pole blending
uniform float horizon_blend_shape : hint_range(0.0, 2.0) = 0.05; // How much the noise affects the horizon blend shape
uniform float horizon_blend_strength : hint_range(0, 1) = 0.05; // Control blending intensity at horizon
uniform float horizon_blend_brightness : hint_range(0.0, 1.0) = .3;
uniform float horizon_blend_width : hint_range(0.0, 0.5) = 0.1; // Width of the horizon blend region

group_uniforms Stars;
uniform bool stars = true;
uniform float star_density : hint_range(0.0, 1.0) = 0.01;
uniform float star_size_randomness : hint_range(0.0, 3.0) = 1.0;
uniform float star_brightness : hint_range(0.0, 5.0) = 1.5;
uniform float star_twinkle_speed : hint_range(0.0, 10.0) = 0.01; 
uniform vec4 star_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); 

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

void sky() {
    float v_angle = acos(clamp(EYEDIR.y, -1.0, 1.0));
    float c = (1.0 - v_angle / (PI * 0.5));
    vec3 sky = mix(sky_horizon_color.rgb, sky_top_color.rgb, clamp(1.0 - pow(1.0 - c, 1.0 / sky_curve), 0.0, 1.0));
    sky *= sky_energy;

    if (LIGHT0_ENABLED) {
        float sun_angle = acos(dot(LIGHT0_DIRECTION, EYEDIR));
        if (sun_angle < LIGHT0_SIZE) {
            sky = LIGHT0_COLOR * LIGHT0_ENERGY;
        } else if (sun_angle < sun_angle_max) {
            float c2 = (sun_angle - LIGHT0_SIZE) / (sun_angle_max - LIGHT0_SIZE);
            sky = mix(LIGHT0_COLOR * LIGHT0_ENERGY, sky, clamp(1.0 - pow(1.0 - c2, 1.0 / sun_curve), 0.0, 1.0));
        }
    }

    if (LIGHT1_ENABLED) {
        float sun_angle = acos(dot(LIGHT1_DIRECTION, EYEDIR));
        if (sun_angle < LIGHT1_SIZE) {
            sky = LIGHT1_COLOR * LIGHT1_ENERGY;
        } else if (sun_angle < sun_angle_max) {
            float c2 = (sun_angle - LIGHT1_SIZE) / (sun_angle_max - LIGHT1_SIZE);
            sky = mix(LIGHT1_COLOR * LIGHT1_ENERGY, sky, clamp(1.0 - pow(1.0 - c2, 1.0 / sun_curve), 0.0, 1.0));
        }
    }

    if (LIGHT2_ENABLED) {
        float sun_angle = acos(dot(LIGHT2_DIRECTION, EYEDIR));
        if (sun_angle < LIGHT2_SIZE) {
            sky = LIGHT2_COLOR * LIGHT2_ENERGY;
        } else if (sun_angle < sun_angle_max) {
            float c2 = (sun_angle - LIGHT2_SIZE) / (sun_angle_max - LIGHT2_SIZE);
            sky = mix(LIGHT2_COLOR * LIGHT2_ENERGY, sky, clamp(1.0 - pow(1.0 - c2, 1.0 / sun_curve), 0.0, 1.0));
        }
    }

    if (LIGHT3_ENABLED) {
        float sun_angle = acos(dot(LIGHT3_DIRECTION, EYEDIR));
        if (sun_angle < LIGHT3_SIZE) {
            sky = LIGHT3_COLOR * LIGHT3_ENERGY;
        } else if (sun_angle < sun_angle_max) {
            float c2 = (sun_angle - LIGHT3_SIZE) / (sun_angle_max - LIGHT3_SIZE);
            sky = mix(LIGHT3_COLOR * LIGHT3_ENERGY, sky, clamp(1.0 - pow(1.0 - c2, 1.0 / sun_curve), 0.0, 1.0));
        }
    }

    // Sample the sky cover texture with dynamic offset (only x and y direction)
    vec2 noise_coords = SKY_COORDS.xy + wind_offset_direction * wind_speed * TIME * 0.01;

    // Wrap UVs to keep tiling seamless
    noise_coords = mod(noise_coords, 1.0);

    // Sample the original noise texture
    vec4 sky_cover_texture = texture(sky_cover, noise_coords);

    // Sample flipped noise for Z-offset effect
    vec4 flipped_noise = texture(sky_cover, vec2(noise_coords.x, 1.0 - noise_coords.y));

    // Z blending (cloud change) logic
    float cloud_blend_factor = 0.0;
    if (clouds_change) {
        // Use a sine wave to blend clouds smoothly over time based on the cloud_change_rate
        cloud_blend_factor = 0.5 + 0.5 * sin(TIME * cloud_change_rate);
    }

    // Blend between the original and flipped noise using cloud_blend_factor
    vec4 blended_noise_texture = mix(sky_cover_texture, flipped_noise, cloud_blend_factor);

	if (clouds_density) {
		float cloud_density = smoothstep(0.4, 0.8, blended_noise_texture.r);
		float height_fade = clamp(1.0 - pow(EYEDIR.y, 4.0), 0.0, 1.0);
		float final_density = cloud_density * height_fade;
		vec3 modulated_cloud_color = mix(sky_cover_modulate.rgb, sky, 1.0 - final_density);
		vec3 cloud_color = mix(sky, modulated_cloud_color, final_density);
		sky = mix(sky, cloud_color, final_density * 0.5) * sky_cover_modulate.a;
	}

    // Pole blending
    float base_pole_blend_factor = abs(EYEDIR.y);  // Original blend factor (circular)
    float noise_pole_blend = blended_noise_texture.r * pole_blend_shape;
    float pole_blend_factor = smoothstep(1.0 - pole_blend_strength, 1.0, base_pole_blend_factor + noise_pole_blend);

    // Horizon blending - detect when we're near the horizon
    float horizon_distance = abs(EYEDIR.y);  // This will be close to 0 near the horizon
    float horizon_factor = 1.0 - smoothstep(0.0, horizon_blend_width, horizon_distance);
    float noise_horizon_blend = blended_noise_texture.g * horizon_blend_shape;
    float horizon_blend_factor = smoothstep(1.0 - horizon_blend_strength, 1.0, horizon_factor + noise_horizon_blend);

    // Combine both blend factors (poles and horizon)
    float combined_blend_factor = max(pole_blend_factor, horizon_blend_factor);

    // Blend noise with brightness value based on the combined factor
    vec3 blended_noise = mix(blended_noise_texture.rgb, vec3(pole_blend_brightness), pole_blend_factor);
    blended_noise = mix(blended_noise, vec3(horizon_blend_brightness), horizon_blend_factor);
	sky += (blended_noise * sky_cover_modulate.rgb) * blended_noise_texture.a * sky_cover_modulate.a * sky_energy;

    // Ground blending
    c = (v_angle - (PI * 0.5)) / (PI * 0.5);
    vec3 ground = mix(ground_horizon_color.rgb, ground_bottom_color.rgb, clamp(1.0 - pow(1.0 - c, 1.0 / ground_curve), 0.0, 1.0));
    ground *= ground_energy;

	
	if (stars) {
    // Solo visibles en la parte superior (no en el suelo)
	    float night_factor = clamp(1.0 - LIGHT0_ENERGY * 0.5, 0.0, 1.0);

	     if (EYEDIR.y > 0.0 && night_factor > 0.0) {
	        // Coordenadas esféricas para fijar las estrellas al cielo
	        float azimuth = atan(EYEDIR.x, EYEDIR.z) / (2.0 * PI) + 0.5;
	        float altitude = acos(clamp(EYEDIR.y, -1.0, 1.0)) / PI;
	        vec2 uv = vec2(azimuth, altitude) * 512.0;

	        // Hash base para celda actual
	        vec2 id = floor(uv);
	        vec2 local = fract(uv) - 0.5;
	        float h = hash(id);

	        // Determina si hay una estrella en esta celda
	        float has_star = step(1.0 - star_density, h);

	        // Randomiza el tamaño según el hash y el parámetro de control
	        float size_variation = mix(1.0, 1.0 + star_size_randomness * (h - 0.5), has_star);

	        // Forma circular con falloff suave (no cuadrados)
	        float dist = length(local) * 2.0 / size_variation;
	        float shape = smoothstep(0.3, 0.0, dist);

	        // Parpadeo dinámico
	        float twinkle = 0.6 + 0.4 * sin(TIME * star_twinkle_speed + h * 100.0);

	        // Atenúa hacia el cénit para dar sensación de profundidad
	        float depth_fade = smoothstep(0.0, 0.8, 1.0 - abs(EYEDIR.y));

	        // Intensidad final
	        float star_intensity = has_star * shape * twinkle * depth_fade;

	        // Añadimos el color final
	        sky += star_intensity * star_brightness * star_color.rgb * night_factor;
    	}
	}
	
	COLOR = mix(ground, sky, smoothstep(-0.05, 0.1, EYEDIR.y)) * exposure;
}