extends RefCounted
## Les épées. Modèle le long de +Y : la poignée est à l'origine (dans la
## paume), la lame monte jusqu'à ~0.95 m.

const Builder := preload("res://scripts/builder.gd")

const NAMES := ["", "Épée Rock'n'Roll", "Épée électrique", "Épée de feu"]
const DAMAGE := [0, 1, 2, 3]
const BLADE := [Color(0.85, 0.88, 0.95), Color(0.85, 0.88, 0.95), Color(1.0, 0.92, 0.3), Color(1.0, 0.45, 0.15)]
const TRIM := [Color(1, 0.4, 0.7), Color(1.0, 0.35, 0.7), Color(0.3, 0.7, 1.0), Color(1.0, 0.85, 0.2)]


static func add(b: Builder, level: int, xf := Transform3D()) -> void:
	var lv := clampi(level, 1, 3)
	var o := xf.origin
	var bs := xf.basis
	b.cylinder(0.022, 0.022, 0.2, o + bs * Vector3(0, 0.0, 0), Color(0.25, 0.15, 0.1), bs, 8)
	b.sphere(0.035, o + bs * Vector3(0, -0.11, 0), TRIM[lv], Vector3.ONE, bs, 8)
	b.box(Vector3(0.22, 0.035, 0.05), o + bs * Vector3(0, 0.11, 0), TRIM[lv], false, bs)
	b.box(Vector3(0.06, 0.7, 0.014), o + bs * Vector3(0, 0.48, 0), BLADE[lv], false, bs)
	b.prism(Vector3(0.06, 0.1, 0.014), o + bs * Vector3(0, 0.88, 0), BLADE[lv], bs)
	# Décor de lame : un éclair, des étincelles ou des flammes
	b.box(Vector3(0.014, 0.5, 0.018), o + bs * Vector3(0, 0.45, 0), TRIM[lv], false, bs * Basis(Vector3.FORWARD, 0.06))
	if lv == 3:
		for k in 4:
			b.spike(0.025, 0.09, o + bs * Vector3(0.04 * (1 if k % 2 == 0 else -1), 0.3 + k * 0.14, 0), bs * Vector3(1 if k % 2 == 0 else -1, 0.6, 0), Color(1.0, 0.7, 0.1))
