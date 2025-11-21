shader_type spatial;
// unshaded = ignoruje słońce (zawsze jasny), blend_add = efekt lasera, cull_disabled = widać wnętrze
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

// --- KOLORY ---
uniform vec4 beam_color : source_color = vec4(0.2, 1.0, 0.5, 1.0); // Neonowy zielony/cyjan
uniform float intensity : hint_range(1.0, 10.0) = 3.0; // Siła świecenia

// --- VOXELE / PIKSELE ---
uniform float pixel_size : hint_range(10.0, 100.0) = 30.0; // Ile "kwadratów" szerokości ma promień
uniform float gap_size : hint_range(0.0, 0.5) = 0.1; // Odstępy między voxelami (siatka)

// --- RUCH ---
uniform float scroll_speed = 2.0;
uniform sampler2D noise_texture : filter_nearest, repeat_enable; // Ważne: filter_nearest dla ostrości

// --- ZANIKANIE ---
uniform float top_fade : hint_range(0.0, 1.0) = 0.2;
uniform float bottom_fade : hint_range(0.0, 1.0) = 0.1;

void fragment() {
	// 1. Ukrycie wieczka (standardowo)
	if (NORMAL.y > 0.9) discard;

	// 2. PIKSELIZACJA (Klucz do stylu Voxel)
	// Zaokrąglamy współrzędne UV do siatki (np. 30x30 pól)
	vec2 voxel_uv = floor(UV * pixel_size) / pixel_size;
	
	// 3. Ruch "cyfrowy"
	// Przesuwamy teksturę w pionie
	vec2 moving_uv = voxel_uv + vec2(0.0, -TIME * scroll_speed * 0.1);
	
	// 4. Pobranie wzoru (szumu)
	// Używamy tekstury, żeby zdecydować, które voxele świecą
	float noise = texture(noise_texture, moving_uv).r;
	
	// 5. Efekt "Digital Cutout" (Progowanie)
	// Zamiast miękkiego gradientu, robimy twarde cięcie: albo świeci, albo nie.
	// To daje efekt latających kwadracików.
	float beam_mask = step(0.5, noise); // 0.5 to próg gęstości
	
	// 6. Dodanie siatki (opcjonalne odstępy między voxelami)
	// Sprawdzamy ułamek UV wewnątrz każdego voxela
	vec2 local_uv = fract(UV * pixel_size);
	// Jeśli jesteśmy na krawędzi voxela, wygaszamy (robimy siatkę)
	float grid_mask = step(gap_size, local_uv.x) * step(gap_size, 1.0 - local_uv.x) * step(gap_size, local_uv.y) * step(gap_size, 1.0 - local_uv.y);
	
	// 7. Zanikanie Góra/Dół (Gradient)
	float fade = smoothstep(0.0, top_fade, UV.y) * smoothstep(1.0, 1.0 - bottom_fade, UV.y);
	
	// --- ŁĄCZENIE ---
	vec3 final_color = beam_color.rgb * intensity;
	float final_alpha = beam_mask * grid_mask * fade * beam_color.a;
	
	ALBEDO = final_color;
	ALPHA = final_alpha;
}