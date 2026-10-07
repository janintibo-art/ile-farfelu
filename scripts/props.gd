extends RefCounted
## Objets à attraper : ballon de plage, noix de coco, onigiris, poulet en
## caoutchouc, et tout ce qu'on achète à la boutique.

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Grabbable := preload("res://scripts/grabbable.gd")
const Island := preload("res://scripts/island.gd")

const INK := Color(0.13, 0.08, 0.17)
const FOODS := ["glace", "ramen", "bonbon"]
const FISH_KINDS := ["sardine", "arcenciel", "dore", "botte", "algue", "slip"]



const PIECE_R := 0.17
const PIECE_COLS := {"roue_a": Color(0.95, 0.66, 0.3), "roue_b": Color(0.4, 0.62, 0.96), "roue_c": Color(0.4, 0.8, 0.5)}


## Un secteur de roue (un tiers de la roue du mardi). Centré sur son propre milieu.
static func sector_mesh(a0: float, a1: float, col: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_color(col)
	var ro := PIECE_R
	var ri := 0.045
	var th := 0.03
	var mid := (a0 + a1) * 0.5
	var c := Vector3(cos(mid), 0.0, sin(mid)) * piece_center_r()
	var n := 8
	for k in n:
		var t0 := lerpf(a0, a1, float(k) / float(n))
		var t1 := lerpf(a0, a1, float(k + 1) / float(n))
		var o0 := Vector3(cos(t0) * ro, 0, sin(t0) * ro) - c
		var o1 := Vector3(cos(t1) * ro, 0, sin(t1) * ro) - c
		var i0 := Vector3(cos(t0) * ri, 0, sin(t0) * ri) - c
		var i1 := Vector3(cos(t1) * ri, 0, sin(t1) * ri) - c
		var up := Vector3(0, th * 0.5, 0)
		_quad(st, i0 + up, o0 + up, o1 + up, i1 + up)
		_quad(st, i0 - up, o0 - up, o1 - up, i1 - up)
		_quad(st, o0 - up, o0 + up, o1 + up, o1 - up)
	var e0 := a0
	var e1 := a1
	for t in [e0, e1]:
		var o := Vector3(cos(t) * ro, 0, sin(t) * ro) - c
		var i := Vector3(cos(t) * ri, 0, sin(t) * ri) - c
		var up := Vector3(0, th * 0.5, 0)
		_quad(st, i - up, o - up, o + up, i + up)
	st.generate_normals()
	return st.commit()


static func piece_center_r() -> float:
	return PIECE_R * 0.62


## Décalage (x, z) du centre d'un morceau par rapport au centre de la roue.
static func piece_offset(kind: String) -> Vector3:
	var k := ["roue_a", "roue_b", "roue_c"].find(kind)
	var mid := (float(k) * TAU / 3.0 + (float(k) + 1.0) * TAU / 3.0) * 0.5
	return Vector3(cos(mid), 0.0, sin(mid)) * piece_center_r()


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for v in [a, b, c, a, c, d, a, c, b, a, d, c]:
		st.add_vertex(v)


static func spawn_all(world: Node3D, house: Node3D, palms: Array) -> void:
	var s := Island.SPAWN
	make(world, "ball", Island.ground(s.x + 2.5, s.y - 2.0) + Vector3(0, 0.5, 0))
	var n := 0
	for p in palms:
		if n >= 7:
			break
		var q: Vector3 = p
		make(world, "coconut", Island.ground(q.x + 0.7, q.z + 0.4) + Vector3(0, 0.3, 0))
		n += 1
	for k in 3:
		make(world, "onigiri", house.to_global(Vector3(-2.85 + k * 0.25, 0.9, -1.6 + (k % 2) * 0.15)))
	make(world, "chicken", house.to_global(Vector3(-2.55, 0.62, 1.2)))
	make(world, "chicken", Island.ground(s.x - 2.0, s.y - 1.0) + Vector3(0, 0.4, 0))


## Dessine l'objet dans un Builder (sert aussi pour les étagères du magasin).
static func paint(b: Builder, kind: String, xf := Transform3D()) -> void:
	var o := xf.origin
	var bs := xf.basis
	match kind:
		"ball":
			var cols := [Color(1, 0.3, 0.3), Color(1, 1, 1), Color(0.3, 0.55, 1.0), Color(1, 0.9, 0.2), Color(1, 1, 1), Color(0.4, 0.85, 0.4)]
			var m := SphereMesh.new()
			m.radius = 0.35
			m.height = 0.7
			m.radial_segments = 24
			m.rings = 12
			b.add_painted(m, xf, func(v: Vector3) -> Color:
				if absf(v.y) > 0.3:
					return Color(1, 1, 1)
				var sector := int(floor((atan2(v.z, v.x) + PI) / (TAU / 6.0))) % 6
				return cols[sector])
		"coconut":
			b.sphere(0.12, o, Color(0.45, 0.28, 0.14), Vector3(1.0, 1.1, 1.0), bs)
			for k in 3:
				b.sphere(0.018, o + bs * Vector3(-0.03 + k * 0.03, 0.1, -0.06 + (k % 2) * 0.02), Color(0.2, 0.12, 0.06), Vector3.ONE, bs, 6)
		"onigiri":
			b.prism(Vector3(0.16, 0.15, 0.07), o, Color(1, 1, 1), bs)
			b.box(Vector3(0.09, 0.07, 0.075), o + bs * Vector3(0, -0.04, 0), Color(0.12, 0.18, 0.14), false, bs)
			b.sphere(0.012, o + bs * Vector3(-0.03, 0.02, -0.036), INK, Vector3.ONE, bs, 6)
			b.sphere(0.012, o + bs * Vector3(0.03, 0.02, -0.036), INK, Vector3.ONE, bs, 6)
		"chicken":
			var y := Color(1.0, 0.85, 0.2)
			b.sphere(0.12, o + bs * Vector3(0, 0, 0.02), y, Vector3(1.0, 0.8, 1.4), bs)
			b.capsule(0.04, 0.2, o + bs * Vector3(0, 0.1, -0.13), y, bs * Basis(Vector3.RIGHT, 0.3))
			b.sphere(0.06, o + bs * Vector3(0, 0.2, -0.17), y, Vector3.ONE, bs)
			b.prism(Vector3(0.05, 0.06, 0.03), o + bs * Vector3(0, 0.27, -0.17), Color(0.95, 0.2, 0.2), bs)
			b.cylinder(0.0, 0.025, 0.06, o + bs * Vector3(0, 0.19, -0.24), Color(1.0, 0.5, 0.1), bs * Basis(Vector3.RIGHT, -PI / 2.0), 6)
			for sx in [-1.0, 1.0]:
				b.sphere(0.012, o + bs * Vector3(sx * 0.03, 0.22, -0.215), INK, Vector3.ONE, bs, 6)
		"canard":
			var y := Color(1.0, 0.85, 0.15)
			b.sphere(0.1, o, y, Vector3(1.0, 0.75, 1.3), bs)
			b.sphere(0.065, o + bs * Vector3(0, 0.1, -0.08), y, Vector3.ONE, bs)
			b.sphere(0.04, o + bs * Vector3(0, 0.09, -0.15), Color(1.0, 0.5, 0.1), Vector3(1.0, 0.4, 1.0), bs, 8)
			for sx in [-1.0, 1.0]:
				b.sphere(0.012, o + bs * Vector3(sx * 0.03, 0.13, -0.13), INK, Vector3.ONE, bs, 6)
		"glace":
			b.cylinder(0.055, 0.0, 0.16, o + bs * Vector3(0, -0.06, 0), Color(0.85, 0.6, 0.3), bs, 10)
			b.sphere(0.06, o + bs * Vector3(0, 0.04, 0), Color(1.0, 0.6, 0.75), Vector3.ONE, bs, 10)
			b.sphere(0.055, o + bs * Vector3(0, 0.11, 0), Color(0.6, 0.85, 1.0), Vector3.ONE, bs, 10)
			b.sphere(0.05, o + bs * Vector3(0, 0.17, 0), Color(0.7, 1.0, 0.6), Vector3.ONE, bs, 10)
			b.sphere(0.018, o + bs * Vector3(0, 0.225, 0), Color(0.95, 0.15, 0.25), Vector3.ONE, bs, 6)
		"ramen":
			b.cylinder(0.12, 0.07, 0.09, o, Color(0.95, 0.3, 0.3), bs, 14)
			b.cylinder(0.11, 0.11, 0.01, o + bs * Vector3(0, 0.04, 0), Color(1.0, 0.85, 0.5), bs, 14)
			b.sphere(0.03, o + bs * Vector3(0.04, 0.05, 0.02), Color.WHITE, Vector3(1, 0.5, 1.3), bs, 8)
			b.sphere(0.015, o + bs * Vector3(0.04, 0.06, 0.02), Color(1.0, 0.75, 0.1), Vector3(1, 0.5, 1), bs, 6)
			b.box(Vector3(0.07, 0.07, 0.005), o + bs * Vector3(-0.05, 0.06, 0.05), Color(0.12, 0.2, 0.12), false, bs * Basis(Vector3.RIGHT, -0.4))
			b.box(Vector3(0.012, 0.012, 0.3), o + bs * Vector3(0.02, 0.07, -0.02), Color(0.8, 0.6, 0.35), false, bs * Basis(Vector3.UP, 0.4))
		"sardine", "arcenciel", "dore":
			var body: Color = {"sardine": Color(0.7, 0.78, 0.88), "arcenciel": Color(0.4, 0.8, 1.0), "dore": Color(1.0, 0.8, 0.15)}[kind]
			var fin: Color = {"sardine": Color(0.45, 0.55, 0.7), "arcenciel": Color(1.0, 0.45, 0.7), "dore": Color(1.0, 0.55, 0.1)}[kind]
			b.sphere(0.1, o, body, Vector3(0.6, 0.8, 1.6), bs, 12)
			if kind == "arcenciel":
				b.sphere(0.1, o + bs * Vector3(0, 0.02, 0.02), Color(1.0, 0.85, 0.3), Vector3(0.62, 0.35, 1.2), bs, 10)
				b.sphere(0.1, o + bs * Vector3(0, -0.03, 0.0), Color(0.6, 1.0, 0.5), Vector3(0.62, 0.3, 1.1), bs, 10)
			b.prism(Vector3(0.02, 0.12, 0.12), o + bs * Vector3(0, 0, 0.19), fin, bs * Basis(Vector3.RIGHT, PI / 2.0))
			b.prism(Vector3(0.015, 0.06, 0.1), o + bs * Vector3(0, 0.09, 0.02), fin, bs)
			for sx in [-1.0, 1.0]:
				b.sphere(0.022, o + bs * Vector3(sx * 0.05, 0.02, -0.1), Color.WHITE, Vector3.ONE, bs, 6)
				b.sphere(0.012, o + bs * Vector3(sx * 0.06, 0.02, -0.11), INK, Vector3.ONE, bs, 6)
			if kind == "dore":
				b.prism(Vector3(0.05, 0.05, 0.02), o + bs * Vector3(0, 0.11, -0.08), Color(1.0, 0.9, 0.3), bs)
		"botte":
			var brown := Color(0.45, 0.3, 0.2)
			b.box(Vector3(0.12, 0.28, 0.14), o + bs * Vector3(0, 0.06, 0.03), brown, false, bs)
			b.box(Vector3(0.12, 0.1, 0.3), o + bs * Vector3(0, -0.12, -0.05), brown, false, bs)
			b.box(Vector3(0.13, 0.03, 0.31), o + bs * Vector3(0, -0.17, -0.05), Color(0.2, 0.15, 0.1), false, bs)
			b.sphere(0.03, o + bs * Vector3(0.02, 0.2, 0.0), Color(0.3, 0.7, 0.3), Vector3(1, 1.5, 1), bs, 6)
		"algue":
			for k in 4:
				b.capsule(0.03, 0.3, o + bs * Vector3((k - 1.5) * 0.04, 0.0, 0), Color(0.2, 0.6, 0.3).lightened(k * 0.05), bs * Basis(Vector3.FORWARD, (k - 1.5) * 0.3))
		"slip":
			var red := Color(0.95, 0.25, 0.3)
			b.box(Vector3(0.3, 0.06, 0.04), o + bs * Vector3(0, 0.07, 0), Color.WHITE, false, bs)
			b.prism(Vector3(0.3, 0.16, 0.05), o + bs * Vector3(0, -0.04, 0), red, bs * Basis(Vector3.FORWARD, PI))
			for k in 3:
				b.sphere(0.018, o + bs * Vector3(-0.07 + k * 0.07, 0.0, -0.028), Color(1.0, 0.85, 0.9), Vector3(1, 1, 0.4), bs, 6)
		"planche":
			var wood := Color(0.7, 0.5, 0.32)
			b.box(Vector3(1.6, 0.06, 0.42), o, wood, false, bs)
			for k in 3:
				b.box(Vector3(1.6, 0.062, 0.012), o + bs * Vector3(0, 0, -0.14 + k * 0.14), wood.darkened(0.2), false, bs)
			for sx in [-0.7, 0.7]:
				b.sphere(0.015, o + bs * Vector3(sx, 0.03, 0), Color(0.5, 0.5, 0.55), Vector3(1, 0.5, 1), bs, 6)
		"bouchon":
			b.cylinder(0.022, 0.018, 0.05, o, Color(0.8, 0.62, 0.4), bs, 10)
		"cuillere":
			var silver := Color(0.85, 0.87, 0.92)
			b.box(Vector3(0.012, 0.004, 0.13), o + bs * Vector3(0, 0, 0.05), silver, false, bs)
			b.sphere(0.025, o + bs * Vector3(0, 0, -0.04), silver, Vector3(1.0, 0.3, 1.4), bs, 10)
		"chaussette":
			var red := Color(0.9, 0.2, 0.22)
			b.capsule(0.035, 0.2, o, red, bs)
			b.capsule(0.035, 0.12, o + bs * Vector3(0, -0.09, -0.05), red, bs * Basis(Vector3.RIGHT, PI / 2.0))
			b.cylinder(0.038, 0.038, 0.03, o + bs * Vector3(0, 0.09, 0), Color.WHITE, bs, 10)
		"cle":
			var copper := Color(0.85, 0.5, 0.25)
			b.torus(0.012, 0.022, o + bs * Vector3(0, 0, -0.04), copper, bs * Basis(Vector3.RIGHT, PI / 2.0))
			b.box(Vector3(0.008, 0.008, 0.07), o + bs * Vector3(0, 0, 0.02), copper, false, bs)
			b.box(Vector3(0.008, 0.02, 0.01), o + bs * Vector3(0, -0.012, 0.05), copper, false, bs)
		"photo":
			# Face avant (+Z) : l'auberge et des gens devant, couleurs sépia
			b.box(Vector3(0.18, 0.13, 0.004), o, Color(0.96, 0.94, 0.88), false, bs)
			b.box(Vector3(0.16, 0.11, 0.002), o + bs * Vector3(0, 0, 0.0025), Color(0.82, 0.7, 0.52), false, bs)
			b.box(Vector3(0.09, 0.05, 0.001), o + bs * Vector3(0, 0.015, 0.0036), Color(0.6, 0.45, 0.3), false, bs)
			b.prism(Vector3(0.1, 0.03, 0.001), o + bs * Vector3(0, 0.055, 0.0036), Color(0.45, 0.32, 0.22), bs)
			for k in 5:
				var x := -0.06 + k * 0.03
				var c := Color(0.35, 0.25, 0.18) if k != 2 else Color(0.9, 0.35, 0.15)
				b.box(Vector3(0.012, 0.03, 0.001), o + bs * Vector3(x, -0.028, 0.0042), c, false, bs)
				b.sphere(0.008, o + bs * Vector3(x, -0.006, 0.0042), c, Vector3(1, 1, 0.2), bs, 6)
		"carnet":
			b.box(Vector3(0.12, 0.17, 0.025), o, Color(0.2, 0.42, 0.55), false, bs)
			b.box(Vector3(0.10, 0.15, 0.027), o + bs * Vector3(0.006, 0, 0), Color(0.96, 0.93, 0.82), false, bs)
			b.box(Vector3(0.012, 0.17, 0.028), o + bs * Vector3(-0.056, 0, 0), Color(0.15, 0.3, 0.42), false, bs)
			b.sphere(0.02, o + bs * Vector3(0.0, 0.0, -0.015), Color(1.0, 0.8, 0.3), Vector3(1, 1, 0.3), bs, 8)
		"cle_chambre":
			var gold := Color(0.95, 0.78, 0.25)
			b.torus(0.012, 0.024, o + bs * Vector3(0, 0, -0.045), gold, bs * Basis(Vector3.RIGHT, PI / 2.0))
			b.box(Vector3(0.009, 0.009, 0.08), o + bs * Vector3(0, 0, 0.02), gold, false, bs)
			b.box(Vector3(0.009, 0.022, 0.012), o + bs * Vector3(0, -0.012, 0.055), gold, false, bs)
			b.box(Vector3(0.05, 0.035, 0.008), o + bs * Vector3(0, 0, -0.095), Color(0.85, 0.3, 0.3), false, bs)
		"poignee":
			var brass := Color(0.9, 0.7, 0.3)
			b.sphere(0.05, o, brass, Vector3.ONE, bs, 12)
			b.cylinder(0.014, 0.014, 0.08, o + bs * Vector3(0, 0, 0.06), brass.darkened(0.15), bs * Basis(Vector3.RIGHT, PI / 2.0), 8)
			b.cylinder(0.04, 0.04, 0.008, o + bs * Vector3(0, 0, 0.1), brass.darkened(0.1), bs * Basis(Vector3.RIGHT, PI / 2.0), 12)
		"bouton":
			b.cylinder(0.05, 0.05, 0.015, o, Color(0.3, 0.55, 0.9), bs, 14)
			b.sphere(0.008, o + bs * Vector3(-0.015, 0.009, -0.012), Color(0.1, 0.15, 0.3), Vector3.ONE, bs, 5)
			b.sphere(0.008, o + bs * Vector3(0.015, 0.009, 0.012), Color(0.1, 0.15, 0.3), Vector3.ONE, bs, 5)
		"corde":
			b.torus(0.018, 0.075, o, Color(0.85, 0.7, 0.45), bs)
			b.torus(0.018, 0.06, o + bs * Vector3(0, 0.025, 0), Color(0.8, 0.65, 0.4), bs)
		"miroir":
			b.box(Vector3(0.16, 0.2, 0.012), o, Color(0.85, 0.6, 0.3), false, bs)
			b.box(Vector3(0.13, 0.17, 0.014), o, Color(0.75, 0.92, 1.0), false, bs)
			b.box(Vector3(0.006, 0.12, 0.016), o + bs * Vector3(0.01, 0.01, 0), Color(0.3, 0.35, 0.45), false, bs * Basis(Vector3.BACK, 0.45))
		"cle_vide":
			var iron := Color(0.55, 0.58, 0.65)
			b.torus(0.014, 0.03, o + bs * Vector3(0, 0, -0.05), iron, bs * Basis(Vector3.RIGHT, PI / 2.0))
			b.box(Vector3(0.012, 0.012, 0.09), o + bs * Vector3(0, 0, 0.025), iron, false, bs)
			b.box(Vector3(0.012, 0.03, 0.014), o + bs * Vector3(0, -0.02, 0.06), iron, false, bs)
			b.box(Vector3(0.012, 0.02, 0.014), o + bs * Vector3(0, -0.014, 0.04), iron, false, bs)
		"roue_a", "roue_b", "roue_c":
			var k := ["roue_a", "roue_b", "roue_c"].find(kind)
			var col: Color = PIECE_COLS[kind]
			b.add_mesh(sector_mesh(float(k) * TAU / 3.0, float(k + 1) * TAU / 3.0, col), xf)
			var cc := piece_offset(kind)
			for t in 5:
				var ang := lerpf(float(k) * TAU / 3.0 + 0.2, float(k + 1) * TAU / 3.0 - 0.2, float(t) / 4.0)
				var p := Vector3(cos(ang) * (PIECE_R + 0.012), 0.0, sin(ang) * (PIECE_R + 0.012)) - cc
				b.box(Vector3(0.03, 0.03, 0.03), o + bs * p, col.darkened(0.2), false, bs * Basis(Vector3.UP, -ang))
		"roue_mardi":
			var tc := Color(0.35, 0.4, 0.6)
			b.cylinder(PIECE_R, PIECE_R, 0.03, o, tc, bs, 20)
			for t in 12:
				var ang := t * TAU / 12.0
				b.box(Vector3(0.04, 0.03, 0.035), o + bs * Vector3(cos(ang) * (PIECE_R + 0.015), 0.0, sin(ang) * (PIECE_R + 0.015)), tc.darkened(0.15), false, bs * Basis(Vector3.UP, -ang))
			b.cylinder(0.05, 0.05, 0.04, o, Color(0.9, 0.8, 0.45), bs, 10)
		"axe":
			var gold := Color(0.95, 0.78, 0.3)
			b.cylinder(0.07, 0.07, 0.05, o, gold, bs, 12)
			for t in 4:
				b.box(Vector3(0.035, 0.05, 0.1), o + bs * (Basis(Vector3.UP, t * PI * 0.5) * Vector3(0, 0, 0.075)), gold.darkened(0.1), false, bs * Basis(Vector3.UP, t * PI * 0.5))
			b.sphere(0.03, o + bs * Vector3(0, 0.04, 0), Color(0.95, 0.4, 0.4), Vector3.ONE, bs, 8)
		"papier_bleu":
			var pb := Color(0.35, 0.55, 1.0)
			b.box(Vector3(0.1, 0.004, 0.07), o, pb, false, bs)
			b.box(Vector3(0.05, 0.004, 0.04), o + bs * Vector3(0.05, 0, -0.04), pb.lightened(0.1), false, bs * Basis(Vector3.UP, 0.5))
			b.box(Vector3(0.09, 0.0045, 0.004), o + bs * Vector3(0, 0, 0.01), Color(0.9, 0.95, 1.0), false, bs)
		"pinceau":
			b.cylinder(0.012, 0.012, 0.22, o + bs * Vector3(0, 0, 0.04), Color(0.8, 0.6, 0.35), bs * Basis(Vector3.RIGHT, PI * 0.5), 8)
			b.cylinder(0.02, 0.02, 0.06, o + bs * Vector3(0, 0, -0.1), Color(0.75, 0.75, 0.8), bs * Basis(Vector3.RIGHT, PI * 0.5), 8)
			b.cylinder(0.02, 0.012, 0.07, o + bs * Vector3(0, 0, -0.16), Color(0.4, 0.62, 1.0), bs * Basis(Vector3.RIGHT, PI * 0.5), 8)
		"orbe_1", "orbe_2", "orbe_3", "orbe_4":
			_orb(b, kind, o, bs)
		"bonbon":
			b.sphere(0.07, o, Color(1.0, 0.5, 0.8), Vector3.ONE, bs, 12)
			b.torus(0.05, 0.072, o, Color.WHITE, bs * Basis(Vector3.FORWARD, 0.5))
			for sx in [-1.0, 1.0]:
				b.prism(Vector3(0.08, 0.06, 0.03), o + bs * Vector3(sx * 0.095, 0, 0), Color(1.0, 0.85, 0.3), bs * Basis(Vector3.FORWARD, sx * PI / 2.0))


## Un souvenir dans une bulle : un petit décor, et le ciel (soleil ou lune) qui
## dit à quel moment de la journée on se trouve.
static func _orb(b: Builder, kind: String, o: Vector3, bs: Basis) -> void:
	b.cylinder(0.06, 0.07, 0.025, o + bs * Vector3(0, -0.1, 0), Color(0.45, 0.35, 0.5), bs, 12)
	b.cylinder(0.075, 0.075, 0.004, o + bs * Vector3(0, -0.085, 0), Color(0.55, 0.8, 0.5), bs, 12)
	match kind:
		"orbe_1":   # Aube : soleil bas à gauche, le boulanger et ses pains
			b.sphere(0.022, o + bs * Vector3(-0.065, -0.045, 0.0), Color(1.0, 0.85, 0.3), Vector3.ONE, bs, 8)
			b.capsule(0.015, 0.05, o + bs * Vector3(0.0, -0.055, 0.0), Color(0.98, 0.96, 0.92), bs)
			b.sphere(0.014, o + bs * Vector3(0.0, -0.022, 0.0), Color(1.0, 0.85, 0.72), Vector3.ONE, bs, 6)
			b.cylinder(0.012, 0.012, 0.014, o + bs * Vector3(0.0, -0.0, 0.0), Color.WHITE, bs, 6)
			for t in 3:
				b.box(Vector3(0.025, 0.012, 0.015), o + bs * Vector3(0.035 + t * 0.012, -0.075 + t * 0.012, 0.01), Color(0.85, 0.6, 0.3), false, bs)
		"orbe_2":   # Milieu de journée : soleil haut, Malo ouvre la porte 7
			b.sphere(0.022, o + bs * Vector3(0.0, 0.055, 0.0), Color(1.0, 0.95, 0.5), Vector3.ONE, bs, 8)
			b.box(Vector3(0.04, 0.07, 0.01), o + bs * Vector3(0.03, -0.045, -0.02), Color(0.4, 0.28, 0.3), false, bs)
			b.box(Vector3(0.012, 0.012, 0.004), o + bs * Vector3(0.03, -0.01, -0.0), Color(1.0, 1.0, 1.0), false, bs)
			b.sphere(0.022, o + bs * Vector3(-0.025, -0.05, 0.015), Color(0.95, 0.6, 0.4), Vector3(1, 1.2, 1), bs, 8)
			b.sphere(0.012, o + bs * Vector3(-0.025, -0.02, 0.015), Color(1.0, 0.85, 0.72), Vector3.ONE, bs, 6)
		"orbe_3":   # Crépuscule : soleil rouge bas à droite, Éléonore court vers le phare
			b.sphere(0.022, o + bs * Vector3(0.065, -0.045, 0.0), Color(1.0, 0.4, 0.25), Vector3.ONE, bs, 8)
			b.cylinder(0.012, 0.016, 0.07, o + bs * Vector3(0.025, -0.045, -0.02), Color(0.95, 0.95, 0.95), bs, 8)
			b.box(Vector3(0.03, 0.01, 0.02), o + bs * Vector3(0.025, -0.012, -0.02), Color(0.9, 0.3, 0.3), false, bs)
			b.capsule(0.012, 0.04, o + bs * Vector3(-0.03, -0.055, 0.01), Color(0.25, 0.5, 0.55), bs * Basis(Vector3.FORWARD, -0.4))
			b.sphere(0.012, o + bs * Vector3(-0.022, -0.03, 0.01), Color(0.45, 0.15, 0.25), Vector3.ONE, bs, 6)
		_:           # Nuit : lune, étoiles, un bateau réparé, la lueur du phare
			b.sphere(0.02, o + bs * Vector3(-0.02, 0.055, 0.0), Color(0.97, 0.97, 1.0), Vector3.ONE, bs, 8)
			for t in 3:
				b.sphere(0.006, o + bs * Vector3(0.03 + t * 0.012, 0.03 + t * 0.02, 0.0), Color(1.0, 1.0, 0.8), Vector3.ONE, bs, 4)
			b.box(Vector3(0.06, 0.018, 0.026), o + bs * Vector3(-0.015, -0.062, 0.0), Color(0.5, 0.35, 0.25), false, bs)
			b.box(Vector3(0.02, 0.006, 0.026), o + bs * Vector3(0.005, -0.05, 0.0), Color(0.85, 0.7, 0.45), false, bs)
			b.box(Vector3(0.006, 0.05, 0.006), o + bs * Vector3(-0.02, -0.03, 0.0), Color(0.4, 0.3, 0.2), false, bs)
			b.box(Vector3(0.012, 0.09, 0.012), o + bs * Vector3(0.06, -0.02, -0.03), Color(0.85, 0.9, 1.0), false, bs * Basis(Vector3.FORWARD, 0.6))


static func make(world: Node3D, kind: String, pos: Vector3) -> RigidBody3D:
	var rb := Grabbable.new()
	rb.name = kind.capitalize()
	rb.kind = kind
	rb.home = pos
	rb.is_food = kind in FOODS
	var b := Builder.new()
	paint(b, kind)
	var shape: Shape3D
	match kind:
		"ball":
			var sh := SphereShape3D.new()
			sh.radius = 0.35
			shape = sh
			rb.radius = 0.35
			rb.mass = 0.3
			var pm := PhysicsMaterial.new()
			pm.bounce = 0.75
			pm.friction = 0.6
			rb.physics_material_override = pm
		"coconut":
			var sh := SphereShape3D.new()
			sh.radius = 0.12
			shape = sh
			rb.radius = 0.12
			rb.mass = 0.6
		"onigiri":
			var sh := BoxShape3D.new()
			sh.size = Vector3(0.16, 0.15, 0.08)
			shape = sh
			rb.radius = 0.09
			rb.mass = 0.15
		"chicken":
			var sh := BoxShape3D.new()
			sh.size = Vector3(0.2, 0.2, 0.34)
			shape = sh
			rb.radius = 0.14
			rb.mass = 0.2
			rb.grab_text = "COUIC !"
			var pm := PhysicsMaterial.new()
			pm.bounce = 0.5
			rb.physics_material_override = pm
		"canard":
			var sh := SphereShape3D.new()
			sh.radius = 0.11
			shape = sh
			rb.radius = 0.11
			rb.mass = 0.1
			rb.grab_text = "COIN !"
		"glace":
			var sh := BoxShape3D.new()
			sh.size = Vector3(0.12, 0.3, 0.12)
			shape = sh
			rb.radius = 0.1
			rb.mass = 0.1
		"sardine", "arcenciel", "dore":
			var sh := BoxShape3D.new()
			sh.size = Vector3(0.12, 0.16, 0.36)
			shape = sh
			rb.radius = 0.14
			rb.mass = 0.2
			rb.grab_text = "Blub !"
		"botte":
			var sh := BoxShape3D.new()
			sh.size = Vector3(0.13, 0.36, 0.32)
			shape = sh
			rb.radius = 0.15
			rb.mass = 0.4
			rb.grab_text = "Pouah !"
		"planche":
			var sh := BoxShape3D.new()
			sh.size = Vector3(1.6, 0.06, 0.42)
			shape = sh
			rb.radius = 0.5
			rb.mass = 2.0
			rb.grab_text = "Hop !"
		"orbe_1", "orbe_2", "orbe_3", "orbe_4":
			var sh := SphereShape3D.new()
			sh.radius = 0.1
			shape = sh
			rb.radius = 0.12
			rb.mass = 0.3
		"roue_a", "roue_b", "roue_c", "roue_mardi", "axe":
			var sh := CylinderShape3D.new()
			sh.radius = 0.09 if kind != "roue_mardi" else 0.17
			sh.height = 0.04
			shape = sh
			rb.radius = 0.13 if kind != "roue_mardi" else 0.18
			rb.mass = 0.2
		"carnet":
			var sh := BoxShape3D.new()
			sh.size = Vector3(0.12, 0.17, 0.03)
			shape = sh
			rb.radius = 0.1
			rb.mass = 0.1
		"miroir":
			var sh := BoxShape3D.new()
			sh.size = Vector3(0.16, 0.2, 0.02)
			shape = sh
			rb.radius = 0.12
			rb.mass = 0.2
		"photo":
			var sh := BoxShape3D.new()
			sh.size = Vector3(0.18, 0.13, 0.01)
			shape = sh
			rb.radius = 0.1
			rb.mass = 0.05
		"ramen":
			var sh := CylinderShape3D.new()
			sh.radius = 0.12
			sh.height = 0.1
			shape = sh
			rb.radius = 0.12
			rb.mass = 0.3
		_:
			var sh := SphereShape3D.new()
			sh.radius = 0.08
			shape = sh
			rb.radius = 0.08
			rb.mass = 0.05
	b.build(rb, Toon.vertex_color(0.008), "Mesh")
	if kind.begins_with("orbe_"):
		var gm := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.095
		sm.height = 0.19
		gm.mesh = sm
		var glass := StandardMaterial3D.new()
		glass.albedo_color = Color(0.75, 0.9, 1.0, 0.28)
		glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glass.cull_mode = BaseMaterial3D.CULL_DISABLED
		gm.material_override = glass
		gm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		rb.add_child(gm)
	if kind == "photo":
		# Au dos de la photo, une phrase écrite à la main
		var back := Label3D.new()
		back.text = "Bienvenue\nà nouveau."
		back.font_size = 48
		back.outline_size = 0
		back.modulate = Color(0.2, 0.15, 0.35)
		back.pixel_size = 0.0011
		back.position = Vector3(0, 0, -0.0035)
		back.rotation.y = PI
		back.double_sided = false
		rb.add_child(back)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	rb.add_child(cs)
	world.add_child(rb)
	rb.global_position = pos
	return rb
