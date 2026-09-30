shader_type spatial;
render_mode unshaded, cull_front;

// Contour noir des personnages (on gonfle le modèle et on affiche l'envers).

uniform vec4 outline_color : source_color = vec4(0.13, 0.08, 0.17, 1.0);
uniform float thickness = 0.012;

void vertex() {
	VERTEX += normalize(NORMAL) * thickness;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
