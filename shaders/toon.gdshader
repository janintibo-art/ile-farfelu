shader_type spatial;
render_mode specular_disabled;

// Ombrage "cel shading" façon anime : deux paliers de lumière nets
// + un liseré lumineux sur les bords.

uniform vec4 albedo : source_color = vec4(1.0);
uniform bool use_vertex_color = false;
uniform float rim_amount : hint_range(0.0, 1.0) = 0.0;

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
	EMISSION = ALBEDO * smoothstep(0.74, 0.8, rim) * rim_amount;
}

void light() {
	float ndl = dot(normalize(NORMAL), LIGHT);
	float band = smoothstep(0.0, 0.05, ndl) * 0.8 + smoothstep(0.55, 0.6, ndl) * 0.2;
	DIFFUSE_LIGHT += band * ATTENUATION * LIGHT_COLOR / PI;
}
