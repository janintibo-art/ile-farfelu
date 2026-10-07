shader_type spatial;
render_mode cull_disabled, specular_disabled;

// Touffes d'herbe qui ondulent dans le vent (pointe plus claire, base plus
// sombre, comme dans les décors d'animé).

uniform vec4 base_color : source_color = vec4(0.28, 0.6, 0.25, 1.0);
uniform vec4 tip_color : source_color = vec4(0.72, 0.92, 0.45, 1.0);
uniform float wind = 0.18;

varying float v_h;

void vertex() {
	v_h = clamp(VERTEX.y / 0.4, 0.0, 1.0);
	vec3 w = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float s = sin(TIME * 1.7 + w.x * 0.35 + w.z * 0.27) + 0.4 * sin(TIME * 3.1 + w.x * 1.3);
	VERTEX.x += s * wind * v_h * v_h;
	VERTEX.z += s * wind * 0.5 * v_h * v_h;
	NORMAL = vec3(0.0, 1.0, 0.0);
}

void fragment() {
	ALBEDO = mix(base_color.rgb, tip_color.rgb, v_h);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	DIFFUSE_LIGHT += (0.45 + 0.55 * ATTENUATION) * LIGHT_COLOR / PI;
}
