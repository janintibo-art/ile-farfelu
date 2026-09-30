shader_type spatial;
render_mode specular_disabled;

// Mer cartoon : bleu profond au large, turquoise près de la plage,
// anneaux d'écume qui avancent vers le rivage et petits reflets.

uniform vec4 deep_color : source_color = vec4(0.12, 0.42, 0.88, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.28, 0.86, 0.9, 1.0);
uniform vec4 foam_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float shore_radius = 52.0;

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(wpos.x * 0.25 + TIME * 1.2) * 0.06 + cos(wpos.z * 0.2 + TIME * 0.9) * 0.06;
}

void fragment() {
	float d = length(wpos.xz);
	float near = 1.0 - smoothstep(shore_radius - 8.0, shore_radius + 16.0, d);
	vec3 c = mix(deep_color.rgb, shallow_color.rgb, near);
	float wobble = sin(atan(wpos.z, wpos.x) * 9.0 + TIME * 0.7) * 1.5;
	float ring = fract((d + wobble) * 0.18 + TIME * 0.3);
	float band = smoothstep(shore_radius - 14.0, shore_radius - 4.0, d) * (1.0 - smoothstep(shore_radius + 4.0, shore_radius + 14.0, d));
	float foam = step(0.9, ring) * band;
	float sparkle = step(0.992, sin(wpos.x * 0.9 + TIME * 1.5) * sin(wpos.z * 0.7 - TIME * 1.2)) * (1.0 - near);
	c = mix(c, foam_color.rgb, max(foam * 0.85, sparkle * 0.5));
	ALBEDO = c;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR / PI;
}
