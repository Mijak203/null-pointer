shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

group_uniforms Appearance;
uniform sampler2D main_texture : source_color;
uniform vec3 glitch_color : source_color = vec3(0.0, 1.0, 0.0);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.1;

group_uniforms Wobble_Effect;
uniform float shake_power : hint_range(0.0, 0.1) = 0.02;
uniform float shake_speed : hint_range(0.0, 20.0) = 5.0;
uniform float shake_frequency : hint_range(0.0, 50.0) = 10.0;

group_uniforms Scanline;
uniform float scanline_speed : hint_range(-10.0, 10.0) = 2.0;
uniform float scanline_size : hint_range(0.0, 1.0) = 0.1;

void fragment() {
	vec2 uv = UV;

	float wobble = sin(uv.y * shake_frequency + TIME * shake_speed) * shake_power;

	float scanline = smoothstep(0.5 - scanline_size, 0.5, fract(UV.y - TIME * scanline_speed * 0.2)) * smoothstep(0.5 + scanline_size, 0.5, fract(UV.y - TIME * scanline_speed * 0.2));

	uv.x += wobble + (scanline * shake_power * 2.0);

	vec4 tex = texture(main_texture, uv);

	vec3 final_color = mix(tex.rgb, glitch_color, tint_strength);

	final_color += glitch_color * scanline * tint_strength;

	ALBEDO = final_color;

	EMISSION = final_color * tint_strength;

	METALLIC = 0.1;
	ROUGHNESS = 0.5;
}