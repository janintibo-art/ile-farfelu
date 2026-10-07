extends RefCounted
## La canne à pêche. Modèle le long de +Y : poignée à l'origine, bout de la
## canne en TIP.

const Builder := preload("res://scripts/builder.gd")

const TIP := Vector3(0, 1.45, 0)


static func add(b: Builder, xf := Transform3D()) -> void:
	var o := xf.origin
	var bs := xf.basis
	var cork := Color(0.85, 0.65, 0.4)
	b.cylinder(0.024, 0.026, 0.28, o + bs * Vector3(0, 0.0, 0), cork, bs, 8)
	b.cylinder(0.012, 0.02, 1.2, o + bs * Vector3(0, 0.74, 0), Color(0.2, 0.55, 0.95), bs, 8)
	b.cylinder(0.006, 0.01, 0.2, o + bs * Vector3(0, 1.4, 0), Color(1.0, 0.35, 0.35), bs, 6)
	# Moulinet
	b.cylinder(0.05, 0.05, 0.04, o + bs * Vector3(0.05, 0.1, 0), Color(0.9, 0.9, 0.95), bs * Basis(Vector3.FORWARD, PI / 2.0), 12)
	b.box(Vector3(0.05, 0.012, 0.012), o + bs * Vector3(0.08, 0.1, 0.03), Color(0.3, 0.3, 0.35), false, bs)
	for k in 3:
		b.torus(0.008, 0.014, o + bs * Vector3(0, 0.45 + k * 0.35, 0.018), Color(0.85, 0.85, 0.9), bs * Basis(Vector3.RIGHT, PI / 2.0))
