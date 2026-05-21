shader_type spatial;

uniform float void_phase : hint_range(0.0, 1.0) = 0.0;
uniform float tile_size : hint_range(0.1, 10.0) = 1.0;
uniform float plank_width : hint_range(0.1, 4.0) = 0.5;
uniform float grain_scale : hint_range(1.0, 20.0) = 8.0;
uniform float roughness_base : hint_range(0.0, 1.0) = 0.85;
uniform float wetness : hint_range(0.0, 1.0) = 0.7;
uniform float edge_darkness : hint_range(0.0, 1.0) = 0.6;

const vec3 TEAL_WOOD_BASE   = vec3(0.04, 0.10, 0.12);
const vec3 TEAL_WOOD_GRAIN  = vec3(0.02, 0.06, 0.08);
const vec3 TEAL_TINT        = vec3(0.08, 0.35, 0.38);
const vec3 PURPLE_WOOD_BASE  = vec3(0.07, 0.03, 0.10);
const vec3 PURPLE_WOOD_GRAIN = vec3(0.04, 0.01, 0.07);
const vec3 PURPLE_TINT       = vec3(0.25, 0.05, 0.38);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float hash1(float n) {
	return fract(sin(n) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p *= 2.1;
		a *= 0.5;
	}
	return v;
}

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 wood_base  = mix(TEAL_WOOD_BASE,  PURPLE_WOOD_BASE,  void_phase);
	vec3 wood_grain = mix(TEAL_WOOD_GRAIN, PURPLE_WOOD_GRAIN, void_phase);
	vec3 tint       = mix(TEAL_TINT,       PURPLE_TINT,       void_phase);

	vec3 blend = abs(world_normal);
	blend = pow(blend, vec3(4.0));
	blend /= blend.x + blend.y + blend.z + 0.001;

	float rand_xz = hash1(floor(world_pos.x / (plank_width * tile_size)) * 7.3 + 2.1);
	float rand_zy = hash1(floor(world_pos.z / (plank_width * tile_size)) * 5.7 + 8.4);
	float rand_xy = hash1(floor(world_pos.x / (plank_width * tile_size)) * 3.9 + 6.2);

	float grain =
		fbm(vec2(world_pos.x / tile_size * grain_scale + rand_xz * 10.0, world_pos.z / tile_size)) * blend.y +
		fbm(vec2(world_pos.z / tile_size * grain_scale + rand_zy * 10.0, world_pos.y / tile_size)) * blend.x +
		fbm(vec2(world_pos.x / tile_size * grain_scale + rand_xy * 10.0, world_pos.y / tile_size)) * blend.z;

	float local_x_xz = fract(world_pos.x / (plank_width * tile_size));
	float local_x_zy = fract(world_pos.z / (plank_width * tile_size));
	float edge_mask =
		smoothstep(0.0, 0.08, local_x_xz) * smoothstep(1.0, 0.92, local_x_xz) * blend.y +
		smoothstep(0.0, 0.08, local_x_zy) * smoothstep(1.0, 0.92, local_x_zy) * blend.x;

	float knots = clamp(
		smoothstep(0.08, 0.0, length(fract(world_pos.xz / (tile_size * 3.0) + rand_xz) - 0.5)) * blend.y +
		smoothstep(0.08, 0.0, length(fract(world_pos.zy / (tile_size * 3.0) + rand_zy) - 0.5)) * blend.x,
		0.0, 1.0);

	vec3 base = mix(wood_grain, wood_base, grain);
	base = mix(base, base * (1.0 - edge_darkness * 0.5), 1.0 - edge_mask);
	base = mix(base, wood_grain * 0.3, knots);

	float wet_mask = edge_mask * (1.0 - knots);

	ALBEDO = clamp(base, 0.0, 1.0);
	ROUGHNESS = mix(roughness_base, roughness_base * 0.25, wetness * wet_mask);
	METALLIC = 0.0;
	SPECULAR = mix(0.05, 0.6, wetness * wet_mask);
}
