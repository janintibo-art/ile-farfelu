shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

// Fausse ombre ronde et douce sous les persos et les arbres
// (utile sur Quest et téléphone, où les vraies ombres sont coupées).

uniform float strength : hint_range(0.0, 1.0) = 0.4;

void fragment() {
	float d = length(UV - vec2(0.5)) * 2.0;
	ALBEDO = vec3(0.08, 0.06, 0.16);
	ALPHA = strength * (1.0 - smoothstep(0.25, 1.0, d));
}
