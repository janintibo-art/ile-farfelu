shader_type spatial;
render_mode specular_disabled;

// Ombrage "cel shading" façon anime (version Quest 3) :
// - trois paliers de lumière nets, ombres portées comprises
// - ombre teintée (violet doux plutôt que gris, comme dans les animés)
// - reflet brillant net (cheveux, objets) et liseré lumineux sur les bords

uniform vec4 albedo : source_color = vec4(1.0);
uniform bool use_vertex_color = false;
uniform float rim_amount : hint_range(0.0, 1.0) = 0.0;
uniform float gloss : hint_range(0.0, 1.0) = 0.0;
uniform vec4 shade_tint : source_color = vec4(0.72, 0.68, 0.95, 1.0);

varying vec3 v_col;

void vertex() {
	// Les couleurs de sommets sont écrites en sRGB : on les repasse en linéaire
	v_col = use_vertex_color ? pow(COLOR.rgb, vec3(2.2)) : vec3(1.0);
}

void fragment() {
	ALBEDO = albedo.rgb * v_col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	float rim = 1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	EMISSION = ALBEDO * smoothstep(0.72, 0.78, rim) * rim_amount;
}

void light() {
	float ndl = dot(normalize(NORMAL), LIGHT);
	float lit = smoothstep(0.0, 0.04, ndl) * ATTENUATION;
	float top = smoothstep(0.55, 0.6, ndl) * ATTENUATION;
	// Partie à l'ombre : teinte froide plutôt que noir
	vec3 shade = shade_tint.rgb * 0.35;
	vec3 band = mix(shade, vec3(0.85), lit) + vec3(0.15) * top;
	DIFFUSE_LIGHT += band * LIGHT_COLOR / PI;
	if (gloss > 0.0) {
		vec3 h = normalize(LIGHT + VIEW);
		float spec = smoothstep(0.9, 0.93, dot(normalize(NORMAL), h)) * lit * gloss;
		SPECULAR_LIGHT += spec * LIGHT_COLOR * 0.6;
	}
}
