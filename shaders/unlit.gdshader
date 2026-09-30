shader_type spatial;
render_mode unshaded, cull_disabled;

// Trait lumineux qui sort de la main quand on vise un perso.

uniform vec4 color : source_color = vec4(1.0, 0.92, 0.3, 1.0);

void fragment() {
	ALBEDO = color.rgb;
}
