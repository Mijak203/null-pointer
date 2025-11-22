shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_always;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform vec4 matrix_color : source_color = vec4(0.0, 1.0, 0.2, 1.0);
uniform sampler2D matrix_texture : filter_nearest, repeat_enable;
uniform float text_scale = 3.0;
uniform float matrix_strength : hint_range(0.0, 1.0) = 0.5;

uniform vec4 bug_color : source_color = vec4(1.0, 0.0, 0.5, 1.0); 
uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.5;
uniform float glitch_speed = 10.0;
uniform float block_size = 5.0;

uniform float emission_strength : hint_range(0.0, 5.0) = 1.0;

uniform float transparency_alpha : hint_range(0.0, 1.0) = 1.0;

varying vec3 world_pos;

float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	float snap_time = floor(TIME * glitch_speed);
	float noise = random(vec2(snap_time, VERTEX.y));
	
	if (noise > (1.0 - glitch_intensity * 0.3)) {
		float offset = (random(vec2(noise, snap_time)) - 0.5) * 0.2;
		VERTEX.x += offset;
		VERTEX.z += offset;
	}
}

vec3 get_triplanar_code(vec3 pos, vec3 norm, float time) {
	vec2 uv_x = pos.zy * text_scale + vec2(0.0, time);
	vec2 uv_y = pos.xz * text_scale + vec2(time * 0.5, 0.0);
	vec2 uv_z = pos.xy * text_scale + vec2(0.0, time);
	
	float snap_time = floor(TIME * glitch_speed);
	float noise = random(floor(pos.xy * block_size) + snap_time);
	
	if (noise > (1.0 - glitch_intensity * 0.5)) {
		vec2 shift = vec2(random(vec2(noise, 1.0)), 0.0) * 0.5;
		uv_x += shift;
		uv_z += shift;
	}

	vec3 col_x = texture(matrix_texture, uv_x).rgb;
	vec3 col_y = texture(matrix_texture, uv_y).rgb;
	vec3 col_z = texture(matrix_texture, uv_z).rgb;
	
	vec3 weights = abs(norm);
	weights = pow(weights, vec3(4.0));
	weights /= (weights.x + weights.y + weights.z);
	
	return col_x * weights.x + col_y * weights.y + col_z * weights.z;
}

void fragment() {
	float snap_time = floor(TIME * glitch_speed);
	// Sprawdzamy glitch na podstawie pozycji w świecie (kwadratowe bloki)
	float glitch_noise = random(floor(world_pos.xy * block_size) + snap_time);
	bool is_glitching = glitch_noise > (1.0 - glitch_intensity * 0.2);

	vec2 main_uv = UV;
	
	if (is_glitching) {
		float shift = (random(vec2(snap_time, UV.y)) - 0.5) * 0.1;
		main_uv.x += shift;
	}
	
	vec4 tex_color = texture(albedo_texture, main_uv) * tint_color;
	
	float time = TIME * -1.0;
	vec3 code = get_triplanar_code(world_pos, normalize(NORMAL), time);
	float code_mask = step(0.5, code.r);
	
	vec3 final_color = tex_color.rgb;
	
	final_color = mix(final_color, matrix_color.rgb, code_mask * matrix_strength);
	
	if (is_glitching) {
		final_color = mix(final_color, bug_color.rgb, 0.8);
		final_color = 1.0 - final_color; 
	}
	
	float scanline = sin(SCREEN_UV.y * 200.0 + TIME * 10.0) * 0.1 + 0.9;
	
	ALBEDO = final_color * scanline;
	
	float glow_mask = (code_mask * matrix_strength) + (is_glitching ? 1.0 : 0.0);
	EMISSION = ALBEDO * (emission_strength * 0.2 + glow_mask * emission_strength);
	
	ALPHA = tex_color.a * transparency_alpha;
}