shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, unshaded;

uniform vec4 base_color : source_color = vec4(1.0, 0.1, 0.1, 0.35);
uniform sampler2D noise_tex;

uniform float scroll_speed = 1.5;
uniform float glitch_intensity = 0.25;
uniform float scanline_strength = 0.3;
uniform float pulse_speed = 3.0;

void fragment()
{
    vec2 uv = UV;

    // Scrollowanie bariery (podstawowy ruch)
    uv.y += TIME * scroll_speed;

    // Noise do glitchowania
    float n = texture(noise_tex, uv * 2.0).r;

    // Glitch poziomy (nagłe przesunięcia X)
    float glitch_x = (texture(noise_tex, vec2(TIME * 1.3, uv.y * 3.0)).r - 0.5)
                     * glitch_intensity;

    uv.x += glitch_x;

    // Scanlines (jak w uszkodzonym ekranie)
    float scan = step(0.95, fract(uv.y * 25.0)) * scanline_strength;

    // Pulsowanie przezroczystości
    float pulse = sin(TIME * pulse_speed + uv.y * 5.0) * 0.1;

    // Alpha końcowe
    float alpha = base_color.a + n * 0.4 + pulse + scan;
    alpha = clamp(alpha, 0.1, 1.0);

    // Emisja (świecenie)
    vec3 col = base_color.rgb * (1.0 + n * 1.5 + scan * 2.0);
    EMISSION = col * 2.0 * alpha;

    ALBEDO = col;
    ALPHA = alpha;
}
