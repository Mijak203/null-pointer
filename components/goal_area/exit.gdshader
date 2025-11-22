shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform vec4 beam_color : source_color = vec4(0.2, 1.0, 0.5, 1.0);
uniform float intensity : hint_range(1.0, 10.0) = 3.0;

uniform float pixel_size : hint_range(10.0, 100.0) = 30.0;
uniform float gap_size : hint_range(0.0, 0.5) = 0.1;

uniform float scroll_speed = 2.0;
uniform sampler2D noise_texture : filter_nearest, repeat_enable;

uniform float top_fade : hint_range(0.0, 1.0) = 0.2;
uniform float bottom_fade : hint_range(0.0, 1.0) = 0.1;

void fragment() {
	if (NORMAL.y > 0.9) discard;

	vec2 voxel_uv = floor(UV * pixel_size) / pixel_size;
	
	vec2 moving_uv = voxel_uv + vec2(0.0, -TIME * scroll_speed * 0.1);
	
	float noise = texture(noise_texture, moving_uv).r;
	
	float beam_mask = step(0.5, noise);
	
	vec2 local_uv = fract(UV * pixel_size);
	float grid_mask = step(gap_size, local_uv.x) * step(gap_size, 1.0 - local_uv.x) * step(gap_size, local_uv.y) * step(gap_size, 1.0 - local_uv.y);
	
	float fade = smoothstep(0.0, top_fade, UV.y) * smoothstep(1.0, 1.0 - bottom_fade, UV.y);
	
	vec3 final_color = beam_color.rgb * intensity;
	float final_alpha = beam_mask * grid_mask * fade * beam_color.a;
	
	ALBEDO = final_color;
	ALPHA = final_alpha;
}