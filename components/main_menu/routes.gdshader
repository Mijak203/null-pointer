shader_type canvas_item;

// --- KOLORY ---
uniform vec4 bg_color : source_color = vec4(0.0, 0.02, 0.0, 1.0);
uniform vec4 rain_color : source_color = vec4(0.0, 1.0, 0.3, 1.0);
uniform vec4 head_color : source_color = vec4(0.8, 1.0, 0.8, 1.0);

// --- USTAWIENIA ---
uniform float chars_scale : hint_range(10.0, 200.0) = 50.0;
uniform float speed : hint_range(0.1, 10.0) = 3.0;
// Im mniejsza wartość, tym gęściej padają kolejne "krople" jedna po drugiej
uniform float rain_loop_size = 15.0;

// --- BLUR (MIĘKKOŚĆ) ---
uniform float blur_amount : hint_range(0.0, 0.5) = 0.1; // Rozmycie krawędzi znaków

// Funkcja losowa
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Funkcja rysująca "0" (z obsługą miękkich krawędzi)
float draw_zero(vec2 uv, float blur) {
	vec2 center = abs(uv - 0.5);
	float shape = max(center.x * 1.5, center.y);

	// Używamy smoothstep zamiast step dla rozmycia
	float outer = smoothstep(0.4 + blur, 0.4 - blur, shape);
	float inner = smoothstep(0.25 + blur, 0.25 - blur, shape);

	return max(0.0, outer - inner);
}

// Funkcja rysująca "1" (z obsługą miękkich krawędzi)
float draw_one(vec2 uv, float blur) {
	vec2 center = abs(uv - 0.5);

	float line_x = smoothstep(0.1 + blur, 0.1 - blur, center.x);
	float line_y = smoothstep(0.4 + blur, 0.4 - blur, center.y);

	return line_x * line_y;
}

void fragment() {
	// 1. Podział ekranu
	vec2 grid_uv = floor(UV * chars_scale);
	vec2 cell_uv = fract(UV * chars_scale);

	// Marginesy z miękkim wygaszaniem (blur)
	// Dzięki temu znaki nie stykają się ostro
	float padding_x = smoothstep(0.0, blur_amount, cell_uv.x) * smoothstep(1.0, 1.0 - blur_amount, cell_uv.x);
	float padding_y = smoothstep(0.0, blur_amount, cell_uv.y) * smoothstep(1.0, 1.0 - blur_amount, cell_uv.y);
	float padding = padding_x * padding_y;

	// 2. Logika Nieskończonego Spadania
	float column_offset = random(vec2(grid_uv.x, 0.0));

	// Globalny czas przesuwamy w dół
	float time_pos = TIME * speed + column_offset * 100.0;

	// KLUCZ DO PĘTLI: Używamy 'mod' (reszta z dzielenia), aby pozycja "głowy"
	// wracała na górę co 'rain_loop_size' kratek.
	// Dodajemy grid_uv.y, aby ruch był względny do pozycji na ekranie.
	float loop_pos = mod(time_pos - grid_uv.y, rain_loop_size);

	// Odległość od głowy (w tej zapętlonej przestrzeni)
	// loop_pos to "ile kratek temu przeszła głowa"
	float dist_to_head = loop_pos;

	// 3. Maska Deszczu
	// Ogon ciągnie się za głową. Im większy rain_loop_size w stosunku do ogona, tym większa przerwa.
	// Jeśli dist_to_head jest bardzo duże, to znaczy że jesteśmy w "pustej przestrzeni" przed kolejną kroplą.
	float trail_alpha = max(0.0, 1.0 - (dist_to_head * 0.2)); // 0.2 decyduje o długości ogona
	trail_alpha = pow(trail_alpha, 3.0); // Wyostrzanie zanikania

	// Czy to czoło? (Pierwsza kratka ogona)
	float is_head = step(dist_to_head, 1.0) * step(0.0, dist_to_head);

	// 4. Rysowanie (tylko tam gdzie coś widać)
	vec3 final_color = bg_color.rgb;

	if (trail_alpha > 0.01) {
		// Losowanie znaku (migotanie w czasie, niezależne od spadania)
		float char_seed = random(grid_uv + vec2(floor(TIME * 2.0), 0.0));
		float char_shape = 0.0;

		if (char_seed > 0.5) {
			char_shape = draw_one(cell_uv, blur_amount);
		} else {
			char_shape = draw_zero(cell_uv, blur_amount);
		}

		// Kolorowanie
		if (char_shape > 0.1) {
			vec3 tint = mix(rain_color.rgb, head_color.rgb, is_head);

			// Nakładamy jasność znaku * jasność ogona * marginesy
			final_color = mix(bg_color.rgb, tint, char_shape * trail_alpha * padding);

			// Dodatkowy glow (proste rozjaśnienie)
			final_color += tint * trail_alpha * 0.5 * blur_amount;
		}
	}

	COLOR = vec4(final_color, 1.0);
}