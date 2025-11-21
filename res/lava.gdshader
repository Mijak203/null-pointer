shader_type spatial;
render_mode unshaded; // Płaski styl bez cieni

// --- Kolory ---
// Base = to tło (np. żółte), Foam = to plamy (np. czerwone)
uniform vec4 color_main : source_color = vec4(1.0, 0.7, 0.2, 1.0);   // Jasny żółty/pomarańcz (Większość lawy)
uniform vec4 color_spots : source_color = vec4(0.9, 0.2, 0.0, 1.0);  // Czerwone plamy (Mniejszość)

// --- Tekstura ---
uniform sampler2D noise_texture : filter_linear_mipmap, repeat_enable;
uniform float texture_scale = 0.8; 

// --- Ruch ---
uniform vec2 speed = vec2(0.03, 0.01);

// --- Ustawienia Miękkości i Ilości ---
uniform float spot_size : hint_range(0.0, 1.0) = 0.6;   // Im wyżej, tym MNIEJ czerwonych plam
uniform float softness : hint_range(0.1, 1.0) = 0.4;    // Wysoka wartość = bardzo miękkie rozmycie

// --- Falowanie ---
uniform float wave_height = 0.1;

void vertex() {
	// Delikatne falowanie
	float wave = sin(TIME + VERTEX.x * 0.5) * cos(TIME * 0.8 + VERTEX.z * 0.5);
	VERTEX.y += wave * wave_height;
}

void fragment() {
	// Przesuwanie tekstury
	vec2 moving_uv = (UV * texture_scale) + (TIME * speed);
	
	// Pobranie szumu
	float noise = texture(noise_texture, moving_uv).r;
	
	// --- LOGIKA MIĘKKICH PLAM ---
	// smoothstep tworzy gradient. 
	// Jeśli softness jest duże, przejście między kolorami jest bardzo łagodne.
	float mask = smoothstep(spot_size, spot_size + softness, noise);
	
	// Mieszamy kolory:
	// Jeśli maska = 0 (ciemny szum) -> Czerwone plamy
	// Jeśli maska = 1 (jasny szum) -> Żółte tło
	vec3 final_color = mix(color_spots.rgb, color_main.rgb, mask);
	
	ALBEDO = final_color;
}