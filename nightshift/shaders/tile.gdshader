shader_type spatial;
// Superficie de baldosas / ladrillos / tablones procedural para las salas de camaras.
// Sin texturas: todo sale de las UV de la malla, asi que no agrega tiempo de carga.

uniform vec4 color_a : source_color = vec4(0.4, 0.4, 0.4, 1.0);
uniform vec4 color_b : source_color = vec4(0.1, 0.1, 0.1, 1.0);
uniform vec4 grout_color : source_color = vec4(0.05, 0.05, 0.05, 1.0);
uniform vec4 dirt_color : source_color = vec4(0.03, 0.025, 0.02, 1.0);
uniform vec2 tiles = vec2(8.0, 8.0);
uniform float grout = 0.04;
uniform bool checker = false;
uniform bool brick_offset = false;
uniform float variation = 0.25;
uniform float dirt = 0.35;
uniform float dirt_scale = 5.0;
uniform float tile_roughness = 0.5;
uniform float tile_metallic = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 uv = UV * tiles;
	if (brick_offset) {
		uv.x += step(1.0, mod(floor(uv.y), 2.0)) * 0.5;
	}
	vec2 cell = floor(uv);
	vec2 f = fract(uv);
	float inside = step(grout, f.x) * step(grout, f.y) * step(f.x, 1.0 - grout) * step(f.y, 1.0 - grout);
	float chk = checker ? mod(cell.x + cell.y, 2.0) : 0.0;
	vec3 base = mix(color_a.rgb, color_b.rgb, chk);
	base *= 1.0 - variation * 0.5 + variation * hash(cell);
	float n = vnoise(UV * dirt_scale) * 0.65 + vnoise(UV * dirt_scale * 3.1) * 0.35;
	float grime = dirt * smoothstep(0.35, 0.85, n);
	base = mix(base, dirt_color.rgb, grime);
	ALBEDO = mix(grout_color.rgb * (1.0 - grime * 0.5), base, inside);
	ROUGHNESS = mix(0.95, tile_roughness + grime * 0.3, inside);
	METALLIC = tile_metallic * inside;
}
