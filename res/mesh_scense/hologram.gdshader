shader_type spatial;

uniform sampler2D img;
uniform float x_scale = 10.0;
uniform float y_scale = 10.0;
uniform float time = 0.5;

// --- NOWOŚĆ: Suwak jasności (0.0 = czarne, 1.0 = jasne) ---
uniform float brightness_strength : hint_range(0.0, 1.0) = 0.2;

void fragment(){
	float x = mod(UV.x, 1.0/x_scale);
	float y = mod(UV.y, 1.0/y_scale);

	// ZMIANA: Mnożymy kolor przez siłę jasności
	EMISSION = vec3(0.0, 1.0, 0.0) * brightness_strength;

	float direction;
	if(mod(UV.x, 2.0/x_scale)-mod(x, 1.0/x_scale) == 0.0){
		direction = -TIME/3.0;
	}else{
		direction = TIME/3.0;
	}

	vec3 tex = texture(img, vec2(x*x_scale, direction+TIME+y*y_scale)).rgb;
	float brightness = mod(UV.y - (TIME*time) + y + UV.x-x, 0.5);

	ALPHA = 0.1 + pow(tex.x * brightness, 0.75);

	if(ALPHA > 0.5){
		// ZMIANA: Tutaj też mnożymy przez jasność
		EMISSION = vec3(0.5, 1.0, 0.5) * brightness_strength;
	}

	// Opcjonalnie: Jeśli chcesz, żeby całość była bardziej przezroczysta (mniej widoczna),
	// możesz też przyciemnić Alpha:
	// ALPHA *= 0.5;
}