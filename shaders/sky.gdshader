shader_type sky;

// Ciel d'animé : dégradé bleu profond -> horizon clair et chaud, soleil net
// avec halo, et une bande de brume douce sur l'horizon.

uniform vec3 top_color : source_color = vec3(0.16, 0.42, 0.95);
uniform vec3 mid_color : source_color = vec3(0.45, 0.72, 1.0);
uniform vec3 horizon_color : source_color = vec3(0.95, 0.93, 0.88);
uniform vec3 ground_color : source_color = vec3(0.2, 0.45, 0.8);
uniform vec3 sun_color : source_color = vec3(1.0, 0.95, 0.8);
uniform float night = 0.0;

void sky() {
	float y = EYEDIR.y;
	vec3 c;
	if (y > 0.0) {
		float a = pow(clamp(y, 0.0, 1.0), 0.45);
		c = mix(horizon_color, mid_color, smoothstep(0.0, 0.35, a));
		c = mix(c, top_color, smoothstep(0.35, 1.0, a));
	} else {
		c = mix(horizon_color, ground_color, smoothstep(0.0, 0.08, -y));
	}
	// Soleil (lumière directionnelle 0)
	if (LIGHT0_ENABLED) {
		float s = dot(EYEDIR, LIGHT0_DIRECTION);
		c += sun_color * smoothstep(0.9993, 0.9996, s) * 2.0;
		c += sun_color * pow(max(s, 0.0), 180.0) * 0.6;
		c += sun_color * pow(max(s, 0.0), 12.0) * 0.12;
	}
	COLOR = mix(c, c * vec3(0.12, 0.1, 0.25), night);
}
