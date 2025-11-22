shader_type spatial;
render_mode unshaded;

uniform vec4 color_main : source_color = vec4(1.0, 0.7, 0.2, 1.0);
uniform vec4 color_spots : source_color = vec4(0.9, 0.2, 0.0, 1.0);

uniform sampler2D noise_texture : filter_linear_mipmap, repeat_enable;
uniform float texture_scale = 0.8; 

uniform vec2 speed = vec2(0.03, 0.01);

uniform float spot_size : hint_range(0.0, 1.0) = 0.6;
uniform float softness : hint_range(0.1, 1.0) = 0.4;

uniform float wave_height = 0.1;

void vertex() {
	float wave = sin(TIME + VERTEX.x * 0.5) * cos(TIME * 0.8 + VERTEX.z * 0.5);
	VERTEX.y += wave * wave_height;
}

void fragment() {
	vec2 moving_uv = (UV * texture_scale) + (TIME * speed);
	
	float noise = texture(noise_texture, moving_uv).r;
	
	float mask = smoothstep(spot_size, spot_size + softness, noise);
	
	vec3 final_color = mix(color_spots.rgb, color_main.rgb, mask);
	
	ALBEDO = final_color;
}