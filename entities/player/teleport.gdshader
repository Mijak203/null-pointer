shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// Kolor klocka
uniform vec4 albedo : source_color = vec4(0.46, 1.0, 0.67, 1.0); // Twój zielony kolor
uniform float roughness : hint_range(0.0, 1.0) = 0.5;

// Ustawienia teleportacji
uniform sampler2D noise_texture; // Tekstura szumu (ważne!)
uniform float progress : hint_range(0.0, 1.0) = 0.0; // 0 = widoczny, 1 = zniknięty
uniform float edge_width = 0.1;
uniform vec4 emission_color : source_color = vec4(0.0, 0.8, 1.0, 1.0); // Błękitny błysk
uniform float emission_strength = 5.0;

void fragment() {
	vec4 noise = texture(noise_texture, UV);
	float noise_value = noise.r;

	// Logika znikania
	float cut_off = progress * (1.0 + edge_width);

	// Baza (normalny wygląd)
	ALBEDO = albedo.rgb;
	ROUGHNESS = roughness;
	ALPHA = 1.0;

	// Jeśli jesteśmy w fazie znikania
	if (noise_value < cut_off) {
		// Część już zniknięta - przezroczysta
		ALPHA = 0.0;
	}
	// Krawędź teleportacji (BŁYSK)
	else if (noise_value < cut_off + edge_width && progress > 0.0) {
		// Mieszamy kolor z emisją na krawędzi
		ALBEDO = emission_color.rgb;
		EMISSION = emission_color.rgb * emission_strength;
	}
}