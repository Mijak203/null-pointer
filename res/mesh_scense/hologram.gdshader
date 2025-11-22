shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// --- 1. TWOJA GRAFIKA (Baza) ---
group_uniforms Base_Texture;
uniform sampler2D main_texture : source_color; // Tu wrzuć obrazek ściany/klocka
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // Opcjonalne przyciemnienie

// --- 2. EFEKT GLITCH (Nakładka) ---
group_uniforms Glitch_Overlay;
uniform sampler2D noise_texture; // Tu wrzuć szum (FastNoiseLite)
uniform vec3 glitch_color : source_color = vec3(0.0, 1.0, 0.0); // Kolor pasków (np. zieleń)
uniform float glitch_strength : hint_range(0.0, 1.0) = 0.5; // Jak bardzo efekt przykrywa teksturę (0 = wcale, 1 = mocno)
uniform float emission_power : hint_range(0.0, 5.0) = 2.0; // Jak mocno paski świecą

// --- 3. RUCH ---
group_uniforms Movement;
uniform float tiling = 3.0; // Jak gęste są paski
uniform float speed = 0.2;  // Jak szybko płyną

void fragment(){
	// KROK 1: Pobierz kolor Twojej głównej tekstury
	vec4 base_tex = texture(main_texture, UV);

	// KROK 2: Oblicz ruch efektu glitch
	vec2 noise_uv = UV * tiling;

	// Trik na "cyfrowy deszcz" - paski przesuwają się w dół
	float column_shift = floor(noise_uv.x);
	// Co druga kolumna przesuwa się w innym tempie dla efektu chaosu
	float move_y = (mod(column_shift, 2.0) == 0.0) ? TIME * speed : TIME * (speed * 1.5);

	vec2 final_noise_uv = vec2(noise_uv.x, noise_uv.y + move_y);
	float noise_value = texture(noise_texture, final_noise_uv).r;

	// KROK 3: MIESZANIE (Najważniejsza część)

	// Obliczamy ostateczny kolor bazy (razem z tintem)
	vec3 final_base = base_tex.rgb * tint_color.rgb;

	// Mieszamy bazę z kolorem glitcha.
	// Używamy "noise_value", żeby efekt był tylko tam, gdzie szum jest biały.
	float mask = noise_value * glitch_strength;

	// ALBEDO: W miejscach glitcha podmieniamy trochę kolor tekstury na kolor glitcha
	ALBEDO = mix(final_base, glitch_color, mask * 0.5);

	// EMISSION: Dodajemy świecenie TYLKO tam gdzie jest glitch
	EMISSION = glitch_color * mask * emission_power;

	// KROK 4: Przezroczystość (Ważne, jeśli Twoja tekstura ma przezroczyste tło, np. logo)
	ALPHA = base_tex.a;

	// Dodajemy opcję Metallic/Roughness, żeby klocek wyglądał ładniej (jak plastik/metal)
	METALLIC = 0.5;
	ROUGHNESS = 0.2;
}