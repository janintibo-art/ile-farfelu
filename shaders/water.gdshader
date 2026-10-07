shader_type spatial;
render_mode specular_disabled;

// Mer cartoon (version Quest 3) : bleu profond au large, turquoise et lagon
// près de la plage, vagues qui ondulent, motif de reflets animé façon
// "caustiques" d'animé, anneaux d'écume, éclat du soleil et reflet du ciel
// sur les bords (effet de Fresnel).

uniform vec4 deep_color : source_color = vec4(0.1, 0.36, 0.82, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.25, 0.85, 0.88, 1.0);
uniform vec4 lagoon_color : source_color = vec4(0.55, 0.95, 0.88, 1.0);
uniform vec4 sky_color : source_color = vec4(0.72, 0.88, 1.0, 1.0);
uniform vec4 foam_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D shore_map : filter_linear, repeat_disable;
uniform float map_size = 200.0;   // largeur (m) couverte par la carte du relief
uniform float map_range = 6.0;    // la carte stocke la hauteur du sol entre -range/2 et +range/2

varying vec3 wpos;

float wave(vec2 p, float t) {
	return sin(p.x * 0.25 + t * 1.2) * 0.06 + cos(p.y * 0.2 + t * 0.9) * 0.06
		+ sin((p.x + p.y) * 0.6 + t * 2.1) * 0.025;
}

// Petit motif de cellules (reflets qui dansent sous la surface)
float cells(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d = 1.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = fract(sin(vec2(dot(i + g, vec2(127.1, 311.7)), dot(i + g, vec2(269.5, 183.3)))) * 43758.5453);
			o = 0.5 + 0.4 * sin(TIME * 0.8 + 6.2831 * o);
			d = min(d, length(g + o - f));
		}
	}
	return d;
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += wave(wpos.xz, TIME);
	float e = 0.5;
	float hx = wave(wpos.xz + vec2(e, 0.0), TIME) - wave(wpos.xz - vec2(e, 0.0), TIME);
	float hz = wave(wpos.xz + vec2(0.0, e), TIME) - wave(wpos.xz - vec2(0.0, e), TIME);
	NORMAL = normalize(vec3(-hx, 2.0 * e, -hz));
}

void fragment() {
	// Relief du sol sous l'eau (carte pré-calculée) : fonctionne pour toute forme d'île
	vec2 uv = wpos.xz / map_size + 0.5;
	float hg = texture(shore_map, uv).r * map_range - map_range * 0.5;
	float near = smoothstep(-2.0, -0.3, hg);
	float lagoon = smoothstep(-1.0, -0.1, hg);
	vec3 c = mix(deep_color.rgb, shallow_color.rgb, near);
	c = mix(c, lagoon_color.rgb, lagoon * 0.6);
	// Reflets qui dansent, surtout dans l'eau peu profonde
	float cl = cells(wpos.xz * 0.35);
	c += vec3(0.25, 0.3, 0.25) * smoothstep(0.08, 0.0, abs(cl - 0.55)) * (0.25 + near * 0.6);
	// Écume : des lignes qui suivent le rivage et avancent vers la plage
	float wobble = sin(wpos.x * 0.35 + TIME * 0.7) * 0.15 + cos(wpos.z * 0.3 + TIME * 0.5) * 0.15;
	float ring = fract((hg + wobble) * 0.55 - TIME * 0.12);
	float band = smoothstep(-0.95, -0.45, hg) * (1.0 - smoothstep(-0.25, 0.15, hg));
	float foam = step(0.88, ring) * band;
	c = mix(c, foam_color.rgb, foam * 0.85);
	// Reflet du ciel sur les bords (Fresnel)
	float fres = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 4.0);
	c = mix(c, sky_color.rgb, fres * 0.55);
	ALBEDO = c;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	DIFFUSE_LIGHT += (0.75 + 0.25 * ATTENUATION) * LIGHT_COLOR / PI;
	// Éclats du soleil : petites étoiles nettes sur les vagues
	vec3 h = normalize(LIGHT + VIEW);
	float s = smoothstep(0.985, 0.99, dot(normalize(NORMAL), h));
	SPECULAR_LIGHT += s * LIGHT_COLOR * 1.5;
}
