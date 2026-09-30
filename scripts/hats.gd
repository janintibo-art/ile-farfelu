extends RefCounted
## Les chapeaux, dessinés en formes simples. "top" = point posé sur le haut
## de la tête du chibi.

const Builder := preload("res://scripts/builder.gd")


static func add(b: Builder, id: String, top: Vector3, s := 1.0) -> void:
	match id:
		"paille":
			var straw := Color(0.98, 0.85, 0.45)
			b.cylinder(0.44 * s, 0.46 * s, 0.03 * s, top + Vector3(0, 0.0, 0), straw, Basis(), 16)
			b.cylinder(0.2 * s, 0.23 * s, 0.17 * s, top + Vector3(0, 0.09 * s, 0), straw, Basis(), 14)
			b.cylinder(0.235 * s, 0.235 * s, 0.05 * s, top + Vector3(0, 0.04 * s, 0), Color(0.9, 0.25, 0.3), Basis(), 14)
		"casquette":
			var red := Color(0.95, 0.3, 0.3)
			b.sphere(0.27 * s, top + Vector3(0, -0.02 * s, 0.02 * s), red, Vector3(1.1, 0.55, 1.1))
			b.box(Vector3(0.3, 0.025, 0.26) * s, top + Vector3(0, -0.04 * s, -0.3 * s), Color.WHITE, false, Basis(Vector3.RIGHT, 0.12))
			b.sphere(0.035 * s, top + Vector3(0, 0.13 * s, 0.02 * s), Color.WHITE)
		"lapin":
			for sx in [-1.0, 1.0]:
				var tilt := Basis(Vector3.FORWARD, -sx * 0.18)
				b.capsule(0.06 * s, 0.42 * s, top + Vector3(sx * 0.1, 0.2, 0) * s, Color.WHITE, tilt, Vector3(1, 1, 0.5))
				b.capsule(0.035 * s, 0.32 * s, top + Vector3(sx * 0.1, 0.2, -0.02) * s, Color(1.0, 0.7, 0.8), tilt, Vector3(1, 1, 0.4))
			b.torus(0.2 * s, 0.24 * s, top + Vector3(0, -0.03 * s, 0), Color(1.0, 0.7, 0.8), Basis(Vector3.RIGHT, 0.2))
		"sorcier":
			var purple := Color(0.45, 0.25, 0.75)
			b.cylinder(0.44 * s, 0.46 * s, 0.03 * s, top, purple.darkened(0.15), Basis(), 16)
			b.cylinder(0.02 * s, 0.25 * s, 0.5 * s, top + Vector3(0, 0.25 * s, 0.03 * s), purple, Basis(Vector3.RIGHT, 0.2), 12)
			b.sphere(0.05 * s, top + Vector3(0, 0.5 * s, 0.13 * s), Color(1.0, 0.9, 0.3))
			b.cylinder(0.255 * s, 0.26 * s, 0.05 * s, top + Vector3(0, 0.035 * s, 0), Color(1.0, 0.85, 0.2), Basis(), 14)
		"couronne":
			var gold := Color(1.0, 0.82, 0.2)
			b.cylinder(0.2 * s, 0.2 * s, 0.1 * s, top + Vector3(0, 0.05 * s, 0), gold, Basis(), 14)
			for k in 6:
				var a := k * TAU / 6.0
				b.spike(0.05 * s, 0.12 * s, top + Vector3(cos(a) * 0.18, 0.15, sin(a) * 0.18) * s, Vector3.UP, gold)
				b.sphere(0.028 * s, top + Vector3(cos(a) * 0.2, 0.05, sin(a) * 0.2) * s, [Color(1, 0.2, 0.3), Color(0.3, 0.6, 1.0), Color(0.3, 0.9, 0.4)][k % 3])
