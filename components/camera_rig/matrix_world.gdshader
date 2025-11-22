shader_type canvas_item;

// --- USTAWIENIA MATRIXA ---
uniform vec4 base_color : source_color = vec4(0.0, 0.2, 0.0, 1.0); // Ciemne tło
uniform vec4 code_color : source_color = vec4(0.2, 1.0, 0.4, 1.0); // Kolor znaków
uniform float density : hint_range(0.0, 1.0) = 0.3; // Gęstość kodu
uniform float speed = 2.0; // Prędkość spadania
uniform float grid_size = 30.0; // Wielkość "znaków"

// --- USTAWIENIA GŁĘBI (Żeby kod znikał w dali) ---
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// Funkcja losowa
float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
	// 1. Pobierz obraz gry (to co widzi kamera)
	vec4 screen_color = texture(screen_texture, SCREEN_UV);
	
	// 2. Podziel ekran na siatkę (jak znaki w terminalu)
	vec2 grid_uv = floor(UV * grid_size); // Współrzędne kratki
	vec2 sub_uv = fract(UV * grid_size);  // Współrzędne wewnątrz kratki
	
	// 3. Animacja spadania
	// Przesuwamy "czas" różnie dla każdej kolumny, żeby nie spadały równo
	float column_offset = random(vec2(grid_uv.x, 0.0));
	float time_pos = TIME * speed + column_offset * 10.0;
	
	// Obliczamy, która "litera" w kolumnie się teraz świeci
	float drop_pos = floor(grid_uv.y + time_pos);
	
	// Losujemy, czy w tym miejscu jest znak
	float char_random = random(vec2(grid_uv.x, drop_pos));
	
	// 4. Generowanie "znaku"
	float is_char = step(1.0 - density, char_random);
	
	// Zanikanie ogona (trail)
	float trail = fract(grid_uv.y + time_pos); // 0.0 do 1.0 wzdłuż spadania
	trail = pow(trail, 4.0); // Wyostrzamy, żeby tylko czoło świeciło mocno
	
	// 5. Mieszanie z grą
	// Zamiast zastępować obraz, "dodajemy" kod do świata gry (tryb Overlay)
	// Jeśli chcesz efektu monitora CRT, możesz tu dodać linie skanowania.
	
	vec3 matrix_effect = code_color.rgb * is_char * trail;
	
	// Opcja A: Subtelny nakładka na świat (Screen Mode)
	// COLOR.rgb = screen_color.rgb + matrix_effect;
	
	// Opcja B: "Widzenie w kodzie" (Zielony filtr + znaki)
	float gray = dot(screen_color.rgb, vec3(0.299, 0.587, 0.114)); // Desaturacja gry
	vec3 world_tint = vec3(0.0, gray * 0.5, 0.0); // Zielonkawy świat
	
	COLOR.rgb = world_tint + matrix_effect * 2.0;
	COLOR.a = 1.0;
}