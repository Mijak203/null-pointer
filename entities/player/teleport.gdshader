shader_type spatial;
// ZMIANA 1: Dodano 'depth_prepass_alpha'.
// To kluczowe, by cień uwzględniał dziury w modelu.
render_mode blend_mix, depth_draw_opaque, cull_back, depth_prepass_alpha;

// Kolor klocka
uniform vec4 albedo : source_color = vec4(0.46, 1.0, 0.67, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.5;

// Ustawienia teleportacji
uniform sampler2D noise_texture;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float edge_width = 0.1;
uniform vec4 emission_color : source_color = vec4(0.0, 0.8, 1.0, 1.0);
uniform float emission_strength = 5.0;

void fragment() {
    vec4 noise = texture(noise_texture, UV);
    float noise_value = noise.r;

    // Logika znikania
    float cut_off = progress * (1.0 + edge_width);

    // Baza
    ALBEDO = albedo.rgb;
    ROUGHNESS = roughness;
    ALPHA = 1.0;

    // Jeśli jesteśmy w fazie znikania
    if (noise_value < cut_off) {
        // ZMIANA 2: Używamy 'discard' zamiast 'ALPHA = 0.0'
        // 'discard' sprawia, że piksel znika fizycznie z bufora głębi i cienia.
        discard;
    }
    // Krawędź teleportacji (BŁYSK)
    else if (noise_value < cut_off + edge_width && progress > 0.0) {
        ALBEDO = emission_color.rgb;
        EMISSION = emission_color.rgb * emission_strength;
    }
}