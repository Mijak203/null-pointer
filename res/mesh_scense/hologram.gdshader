shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// --- TEKSTURA I KOLOR ---
group_uniforms Appearance;
uniform sampler2D main_texture : source_color;
uniform vec3 glitch_color : source_color = vec3(0.0, 1.0, 0.0); // Zielony
uniform float tint_strength : hint_range(0.0, 1.0) = 0.1; // 0.1 = Bardzo słaba zieleń (TYLKO ZAFARB)

// --- USTAWIENIA FALOWANIA (WOBBLE) ---
group_uniforms Wobble_Effect;
uniform float shake_power : hint_range(0.0, 0.1) = 0.02; // Jak szeroko faluje (amplituda)
uniform float shake_speed : hint_range(0.0, 20.0) = 5.0; // Jak szybko płynie fala
uniform float shake_frequency : hint_range(0.0, 50.0) = 10.0; // Jak gęste są fale

// --- DODATKOWY PASEK ZAKŁÓCEŃ (SCANLINE) ---
group_uniforms Scanline;
uniform float scanline_speed : hint_range(-10.0, 10.0) = 2.0; // Pasek przesuwający się w dół
uniform float scanline_size : hint_range(0.0, 1.0) = 0.1; // Szerokość paska

void fragment() {
	vec2 uv = UV;

	// 1. OBLICZANIE FALOWANIA (Sinusoida)
	// Obraz przesuwa się w lewo i prawo w zależności od wysokości (Y) i czasu
	float wobble = sin(uv.y * shake_frequency + TIME * shake_speed) * shake_power;

	// 2. PASEK ZAKŁÓCEŃ (Wędrujący "garb")
	// Dodajemy jeden większy pasek, który przelatuje przez ekran
	float scanline = smoothstep(0.5 - scanline_size, 0.5, fract(UV.y - TIME * scanline_speed * 0.2)) * smoothstep(0.5 + scanline_size, 0.5, fract(UV.y - TIME * scanline_speed * 0.2));

	// Dodajemy pasek do głównego falowania
	uv.x += wobble + (scanline * shake_power * 2.0);

	// 3. POBRANIE TEKSTURY Z PRZESUNIĘTEGO MIEJSCA
	vec4 tex = texture(main_texture, uv);

	// 4. KOLOROWANIE (Delikatne!)
	// Używamy mix z bardzo małą wartością tint_strength (np. 0.1)
	vec3 final_color = mix(tex.rgb, glitch_color, tint_strength);

	// Dodajemy trochę jaśniejszy kolor tam, gdzie przelatuje pasek zakłóceń
	final_color += glitch_color * scanline * tint_strength;

	ALBEDO = final_color;

	// EMISSION - bardzo słabe, żeby nie świeciło jak żarówka
	EMISSION = final_color * tint_strength;

	METALLIC = 0.1;
	ROUGHNESS = 0.5;
}