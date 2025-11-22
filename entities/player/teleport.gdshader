shader_type spatial;
// depth_prepass_alpha: Kluczowe dla cieni przy użyciu 'discard'
// cull_disabled: Widać wnętrze klocka przy znikaniu
render_mode blend_mix, depth_draw_opaque, cull_disabled, depth_prepass_alpha;

// --- SEKCJA 1: WYGLĄD GRACZA (GLITCH) ---
uniform vec4 main_color : source_color = vec4(0.0, 1.0, 0.5, 1.0); // Kolor hologramu
uniform sampler2D player_texture : source_color, filter_nearest; // Ikonka gracza
uniform float emission_strength : hint_range(1.0, 10.0) = 3.0;

// Glitch Params
uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.1; // Siła trzęsienia
uniform float glitch_speed = 20.0;
uniform float chromatic_aberration : hint_range(0.0, 0.5) = 0.02; // Rozjeżdżanie kolorów

// Hologram Params
uniform float scanline_density = 50.0;
uniform float scanline_speed = -2.0;

// --- SEKCJA 2: TELEPORTACJA (DISSOLVE) ---
uniform sampler2D noise_texture; // Wzór znikania
uniform float progress : hint_range(0.0, 1.0) = 0.0; // 0 = widoczny, 1 = zniknięty
uniform float edge_width = 0.05;
uniform vec4 teleport_edge_color : source_color = vec4(0.0, 0.8, 1.0, 1.0); // Kolor krawędzi znikania

// Funkcja losowa
float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

void vertex() {
	// --- LOGIKA GLITCHA (Wierzchołki) ---
	float snap_time = floor(TIME * glitch_speed);
	float noise = random(vec2(snap_time, VERTEX.y));
	
	// Jeśli wylosowano glitch
	if (noise > (1.0 - glitch_intensity * 0.5)) {
		float offset = (random(vec2(noise, snap_time)) - 0.5) * 0.1;
		VERTEX.x += offset;
		VERTEX.z += offset;
	}
}

void fragment() {
	// ==========================================
	// KROK 1: OBLICZANIE KOLORU (GLITCH LOOK)
	// ==========================================
	
	float snap_time = floor(TIME * glitch_speed);
	float glitch_trigger = random(vec2(snap_time, UV.y));
	float current_aberration = (glitch_trigger > 0.9) ? chromatic_aberration : 0.0;
	
	// 1a. Chromatic Aberration (RGB Split)
	float r = texture(player_texture, UV + vec2(current_aberration, 0.0)).r;
	float g = texture(player_texture, UV).g;
	float b = texture(player_texture, UV - vec2(current_aberration, 0.0)).b;
	vec3 tex_color = vec3(r, g, b);
	
	// Jeśli nie masz tekstury, odkomentuj to:
	// vec3 tex_color = vec3(1.0);

	// 1b. Scanlines (Paski)
	float scanline = sin(SCREEN_UV.y * scanline_density + TIME * scanline_speed) * 0.1 + 0.9;
	
	// 1c. Fresnel (Krawędzie)
	float fresnel = pow(1.0 - dot(NORMAL, VIEW), 3.0);
	vec3 rim = main_color.rgb * fresnel * 2.0;
	
	// Składanie wyglądu podstawowego
	vec3 final_albedo = (tex_color * main_color.rgb + rim) * scanline;
	vec3 final_emission = final_albedo * emission_strength;

	// ==========================================
	// KROK 2: LOGIKA ZNIKANIA (TELEPORT)
	// ==========================================
	
	float noise_val = texture(noise_texture, UV).r;
	float cut_off = progress * (1.0 + edge_width);

	// Sprawdzamy czy ten piksel ma zniknąć
	if (noise_val < cut_off) {
		// Jeśli tak -> Wyrzucamy go (znika też z cienia!)
		discard;
	}
	
	// Sprawdzamy czy jesteśmy na krawędzi znikania (BŁYSK)
	if (noise_val < cut_off + edge_width && progress > 0.0) {
		// Nadpisujemy kolor kolorem teleportu
		final_albedo = teleport_edge_color.rgb;
		final_emission = teleport_edge_color.rgb * emission_strength * 2.0; // Jaśniejszy błysk
	}

	// ==========================================
	// KROK 3: WYJŚCIE
	// ==========================================
	
	ALBEDO = final_albedo;
	EMISSION = final_emission;
	
	// Glitch flash (biały błysk przy mocnym lagu)
	if (glitch_trigger > 0.98 && progress < 0.1) {
		ALBEDO = vec3(1.0);
		EMISSION = vec3(5.0);
	}
	
	ALPHA = 1.0; // discard załatwia przezroczystość
}