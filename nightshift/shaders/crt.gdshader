shader_type canvas_item;

// Post-proceso CRT de los 90: estatica, scanlines, aberracion cromatica y viñeta.
// Refuerzo estetico que tambien oculta limitaciones de produccion (GDD, Pagina 2).

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float aberration = 0.0018;
uniform float scanline_strength = 0.12;
uniform float vignette_strength = 0.55;
uniform float noise_strength = 0.05;

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 off = vec2(aberration, 0.0);
	float r = texture(screen_tex, uv + off).r;
	float g = texture(screen_tex, uv).g;
	float b = texture(screen_tex, uv - off).b;
	vec3 col = vec3(r, g, b);

	float scan = sin(uv.y * 720.0 * 3.14159) * 0.5 + 0.5;
	col *= 1.0 - scanline_strength * scan;

	float n = rand(uv * 900.0 + vec2(TIME)) - 0.5;
	col += n * noise_strength;

	float d = distance(uv, vec2(0.5));
	col *= 1.0 - vignette_strength * smoothstep(0.35, 0.85, d);

	COLOR = vec4(col, 1.0);
}
