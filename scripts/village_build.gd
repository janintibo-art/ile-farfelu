extends RefCounted
## Les bâtiments de Port-Biscornu, construits en formes simples fusionnées
## (un seul dessin par bâtiment, important pour la Quest 3).
## Chaque bâtiment regarde vers +Z dans son repère local ; on le tourne ensuite.

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Island := preload("res://scripts/island.gd")
const Props := preload("res://scripts/props.gd")

const INK := Color(0.13, 0.08, 0.17)
const WOOD := Color(0.72, 0.5, 0.32)
const DARK_WOOD := Color(0.45, 0.3, 0.2)
const STONE := Color(0.66, 0.62, 0.66)
const GLASS := Color(0.7, 0.9, 1.0)
const WALL_T := 0.22


static func label(parent: Node3D, text: String, pos: Vector3, px := 0.004, col := Color(1.0, 0.92, 0.7), font := 48, yaw := 0.0, outline := 10) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = font
	l.outline_size = outline
	l.modulate = col
	l.outline_modulate = INK
	l.pixel_size = px
	l.position = pos
	l.rotation.y = yaw
	l.double_sided = false
	parent.add_child(l)
	return l


## Un bâtiment vide : fondations, sol, murs (avec une porte au milieu de la
## façade), plafond et toit à deux pans. Renvoie [noeud, builder].
static func shell(world: Node3D, name: String, pos: Vector2, yaw: float, w: float, d: float, h: float,
		wall: Color, roof: Color, floor_col := Color(0.78, 0.6, 0.42), door_w := 1.5) -> Array:
	var n := Node3D.new()
	n.name = name
	world.add_child(n)
	n.position = Vector3(pos.x, Island.VILLAGE_H, pos.y)
	n.rotation.y = yaw
	var b := Builder.new()
	var t := WALL_T
	b.box(Vector3(w + 0.3, 2.6, d + 0.3), Vector3(0, -1.3, 0), STONE, false)
	b.box(Vector3(w, 0.1, d), Vector3(0, -0.02, 0), floor_col, true)
	# Murs
	b.box(Vector3(w, h, t), Vector3(0, h * 0.5, -d * 0.5 + t * 0.5), wall)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(t, h, d), Vector3(sx * (w * 0.5 - t * 0.5), h * 0.5, 0), wall)
	var seg := (w - door_w) * 0.5
	for sx in [-1.0, 1.0]:
		b.box(Vector3(seg, h, t), Vector3(sx * (door_w * 0.5 + seg * 0.5), h * 0.5, d * 0.5 - t * 0.5), wall)
	b.box(Vector3(door_w, h - 2.3, t), Vector3(0, 2.3 + (h - 2.3) * 0.5, d * 0.5 - t * 0.5), wall)
	# Cadre de porte
	b.box(Vector3(0.12, 2.3, t + 0.08), Vector3(-door_w * 0.5 - 0.04, 1.15, d * 0.5 - t * 0.5), DARK_WOOD, false)
	b.box(Vector3(0.12, 2.3, t + 0.08), Vector3(door_w * 0.5 + 0.04, 1.15, d * 0.5 - t * 0.5), DARK_WOOD, false)
	b.box(Vector3(door_w + 0.28, 0.14, t + 0.08), Vector3(0, 2.34, d * 0.5 - t * 0.5), DARK_WOOD, false)
	# Plafond + toit
	b.box(Vector3(w, 0.15, d), Vector3(0, h + 0.07, 0), wall.darkened(0.15), false)
	var rh := minf(w, 8.0) * 0.28 + 0.6
	b.prism(Vector3(w + 0.9, rh, d + 0.9), Vector3(0, h + 0.14 + rh * 0.5, 0), roof)
	b.box(Vector3(w + 0.95, 0.1, 0.12), Vector3(0, h + 0.15, d * 0.5 + 0.4), roof.darkened(0.25), false)
	# Fenêtres sur les côtés et deux de chaque côté de la porte
	_windows(b, w, d, h, door_w)
	return [n, b]


static func _windows(b: Builder, w: float, d: float, h: float, door_w: float) -> void:
	var wy := minf(1.6, h * 0.45)
	# Façade
	var fx := door_w * 0.5 + (w - door_w) * 0.25
	if (w - door_w) * 0.5 > 1.4:
		for sx in [-1.0, 1.0]:
			_window(b, Vector3(sx * fx, wy, d * 0.5 + 0.0), 0.0)
	# Côtés
	var k := maxi(int(d / 3.2), 1)
	for i in k:
		var z := -d * 0.5 + (i + 0.5) * d / float(k)
		for sx in [-1.0, 1.0]:
			_window(b, Vector3(sx * w * 0.5, wy, z), PI * 0.5 * sx)


static func _window(b: Builder, p: Vector3, yaw: float) -> void:
	var bs := Basis(Vector3.UP, yaw)
	b.box(Vector3(0.95, 0.95, 0.06), p + bs * Vector3(0, 0, 0.0), DARK_WOOD, false, bs)
	b.box(Vector3(0.78, 0.78, 0.08), p + bs * Vector3(0, 0, 0.0), GLASS, false, bs)
	b.box(Vector3(0.05, 0.78, 0.09), p + bs * Vector3(0, 0, 0.0), DARK_WOOD, false, bs)
	b.box(Vector3(0.78, 0.05, 0.09), p + bs * Vector3(0, 0, 0.0), DARK_WOOD, false, bs)
	b.box(Vector3(1.1, 0.07, 0.2), p + bs * Vector3(0, -0.52, 0.06), WOOD, false, bs)
	var fc: Color = [Color(1.0, 0.5, 0.6), Color(1.0, 0.85, 0.3), Color(0.8, 0.55, 1.0)][int(absf(p.x * 3.0 + p.z)) % 3]
	for k in 3:
		b.sphere(0.07, p + bs * Vector3(-0.3 + k * 0.3, -0.42, 0.08), fc, Vector3.ONE, Basis(), 6)


# --- Petits mobiliers --------------------------------------------------------------

static func table(b: Builder, p: Vector3, r := 0.55, col := WOOD) -> void:
	b.cylinder(r, r, 0.07, p + Vector3(0, 0.78, 0), col, Basis(), 12)
	b.cylinder(0.07, 0.1, 0.78, p + Vector3(0, 0.39, 0), col.darkened(0.25), Basis(), 8)
	b.cylinder(0.3, 0.3, 0.05, p + Vector3(0, 0.03, 0), col.darkened(0.3), Basis(), 10)


static func stool(b: Builder, p: Vector3, col := Color(0.85, 0.4, 0.35)) -> void:
	b.cylinder(0.22, 0.22, 0.07, p + Vector3(0, 0.5, 0), col, Basis(), 10)
	b.cylinder(0.04, 0.05, 0.5, p + Vector3(0, 0.25, 0), DARK_WOOD, Basis(), 6)


static func mug(b: Builder, p: Vector3, col := Color(0.95, 0.85, 0.5)) -> void:
	b.cylinder(0.06, 0.05, 0.11, p + Vector3(0, 0.055, 0), col, Basis(), 8)
	b.torus(0.012, 0.035, p + Vector3(0.07, 0.055, 0), col, Basis(Vector3.RIGHT, PI * 0.5))


static func bottle(b: Builder, p: Vector3, col: Color) -> void:
	b.cylinder(0.05, 0.06, 0.2, p + Vector3(0, 0.1, 0), col, Basis(), 8)
	b.cylinder(0.02, 0.04, 0.1, p + Vector3(0, 0.25, 0), col, Basis(), 8)
	b.cylinder(0.025, 0.025, 0.03, p + Vector3(0, 0.32, 0), Color(0.9, 0.8, 0.5), Basis(), 6)


static func crate(b: Builder, p: Vector3, size := Vector3(0.5, 0.35, 0.4), col := Color(0.8, 0.6, 0.35), yaw := 0.0) -> void:
	var bs := Basis(Vector3.UP, yaw)
	b.box(size, p + Vector3(0, size.y * 0.5, 0), col, true, bs)
	b.box(Vector3(size.x + 0.02, 0.04, size.z + 0.02), p + Vector3(0, size.y * 0.5, 0), col.darkened(0.2), false, bs)


static func plant(b: Builder, p: Vector3) -> void:
	b.cylinder(0.2, 0.15, 0.3, p + Vector3(0, 0.15, 0), Color(0.85, 0.45, 0.35), Basis(), 8)
	b.sphere(0.28, p + Vector3(0, 0.55, 0), Color(0.35, 0.72, 0.4), Vector3(1.0, 1.1, 1.0), Basis(), 8)
	b.sphere(0.16, p + Vector3(0.12, 0.8, 0.05), Color(0.45, 0.82, 0.45), Vector3.ONE, Basis(), 6)


static func flag(b: Builder, p: Vector3, height := 2.4) -> void:
	b.cylinder(0.025, 0.03, height, p + Vector3(0, height * 0.5, 0), Color(0.8, 0.75, 0.6), Basis(), 6)
	for k in 3:
		var c: Color = [Color(0.3, 0.45, 0.95), Color.WHITE, Color(0.95, 0.3, 0.3)][k]
		b.box(Vector3(0.18, 0.5, 0.02), p + Vector3(0.1 + k * 0.18, height - 0.3, 0), c, false)


## Une façade colorée (maison de la rue des Traverses, pas visitable).
static func house(world: Node3D, name: String, pos: Vector2, yaw: float, w: float, d: float, h: float,
		wall: Color, roof: Color, sign_text := "") -> Node3D:
	var s: Array = shell(world, name, pos, yaw, w, d, h, wall, roof)
	var n: Node3D = s[0]
	var b: Builder = s[1]
	# La porte est fermée (maison pas visitable)
	b.box(Vector3(1.5, 2.3, 0.1), Vector3(0, 1.15, d * 0.5 - 0.2), Color(0.55, 0.38, 0.28), true)
	b.sphere(0.06, Vector3(0.5, 1.1, d * 0.5 - 0.1), Color(0.95, 0.8, 0.3), Vector3.ONE, Basis(), 8)
	b.box(Vector3(0.9, 0.9, 0.08), Vector3(0, 1.4, d * 0.5 - 0.14), Color(0.62, 0.43, 0.32), false)
	# Cheminée
	b.box(Vector3(0.5, 1.2, 0.5), Vector3(w * 0.25, h + 1.0, -d * 0.2), STONE.darkened(0.1), false)
	b.build(n, Toon.vertex_color(0.01), "Mesh")
	if sign_text != "":
		label(n, sign_text, Vector3(0, h + 0.1, d * 0.5 + 0.55), 0.0034, Color(1.0, 0.95, 0.75), 56)
	return n


## Un étal de marché, déjà rangé (le marché du mardi a eu lieu).
static func stall(b: Builder, p: Vector3, yaw: float, stripe: Color) -> void:
	var bs := Basis(Vector3.UP, yaw)
	b.box(Vector3(2.0, 0.08, 0.9), p + bs * Vector3(0, 0.9, 0), WOOD, true, bs)
	b.box(Vector3(2.0, 0.9, 0.9), p + bs * Vector3(0, 0.45, 0), WOOD.darkened(0.15), true, bs)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(0.07, 2.4, 0.07), p + bs * Vector3(sx * 1.0, 1.2, -0.42), DARK_WOOD, false, bs)
		b.box(Vector3(0.07, 2.2, 0.07), p + bs * Vector3(sx * 1.0, 1.1, 0.42), DARK_WOOD, false, bs)
	for k in 6:
		var c := stripe if k % 2 == 0 else Color(1, 1, 1)
		b.box(Vector3(0.34, 0.06, 1.2), p + bs * Vector3(-0.85 + k * 0.34, 2.28 - 0.02 * absf(k - 2.5), 0.0), c, false, bs * Basis(Vector3.RIGHT, 0.12))
	# Cageots empilés et nappe pliée
	crate(b, p + bs * Vector3(-0.55, 0.98, 0), Vector3(0.45, 0.2, 0.35), Color(0.82, 0.62, 0.38), yaw)
	crate(b, p + bs * Vector3(-0.55, 1.18, 0), Vector3(0.4, 0.2, 0.3), Color(0.78, 0.58, 0.34), yaw + 0.3)
	b.box(Vector3(0.5, 0.06, 0.4), p + bs * Vector3(0.45, 0.99, 0), stripe.lightened(0.2), false, bs)


static func fountain(b: Builder, p: Vector3) -> void:
	b.cylinder(1.9, 2.0, 0.55, p + Vector3(0, 0.27, 0), STONE, Basis(), 20)
	b.cylinder(1.65, 1.65, 0.06, p + Vector3(0, 0.55, 0), Color(0.45, 0.8, 1.0), Basis(), 20)
	b.cylinder(0.3, 0.4, 1.2, p + Vector3(0, 1.0, 0), STONE.lightened(0.1), Basis(), 12)
	b.cylinder(0.8, 0.3, 0.2, p + Vector3(0, 1.55, 0), STONE.lightened(0.15), Basis(), 14)
	b.cylinder(0.65, 0.65, 0.04, p + Vector3(0, 1.66, 0), Color(0.45, 0.8, 1.0), Basis(), 14)
	b.sphere(0.2, p + Vector3(0, 1.95, 0), Color(0.55, 0.85, 1.0), Vector3(1.0, 1.3, 1.0), Basis(), 10)
	b.collider(Vector3(3.9, 1.0, 3.9), p + Vector3(0, 0.5, 0))


static func lighthouse(world: Node3D, pos: Vector2, height := 15.0) -> Node3D:
	var n := Node3D.new()
	n.name = "Phare"
	world.add_child(n)
	var base_y := Island.height(pos.x, pos.y)
	n.position = Vector3(pos.x, base_y, pos.y)
	var b := Builder.new()
	b.cylinder(3.2, 3.6, 1.4, Vector3(0, -0.2, 0), STONE, Basis(), 14)
	var seg := 5
	var sh := height / float(seg)
	for k in seg:
		var t0 := 1.0 - float(k) / float(seg)
		var r := 1.7 + 0.8 * t0
		var col := Color(0.97, 0.97, 0.98) if k % 2 == 0 else Color(0.92, 0.28, 0.3)
		b.cylinder(r - 0.1, r + 0.05, sh + 0.02, Vector3(0, 0.5 + sh * (k + 0.5), 0), col, Basis(), 14)
	var top := 0.5 + height
	b.cylinder(2.5, 2.1, 0.3, Vector3(0, top + 0.15, 0), DARK_WOOD, Basis(), 14)
	b.cylinder(1.25, 1.25, 1.6, Vector3(0, top + 1.1, 0), Color(1.0, 0.95, 0.65), Basis(), 12)
	for k in 8:
		var a := k * TAU / 8.0
		b.box(Vector3(0.1, 1.7, 0.1), Vector3(cos(a) * 1.3, top + 1.1, sin(a) * 1.3), DARK_WOOD, false)
	b.cylinder(0.0, 1.7, 1.0, Vector3(0, top + 2.4, 0), Color(0.92, 0.28, 0.3), Basis(), 12)
	b.sphere(0.2, Vector3(0, top + 3.0, 0), Color(1.0, 0.85, 0.3), Vector3.ONE, Basis(), 8)
	# La porte (côté sud-ouest, vers le village) : barrée, chaîne et cadenas
	var door_dir := Vector3(-0.6, 0, 0.8).normalized()
	var door_pos := door_dir * 2.45 + Vector3(0, 1.2, 0)
	var db := Basis(Vector3.UP, atan2(door_dir.x, door_dir.z))
	b.box(Vector3(1.4, 2.3, 0.2), door_pos, Color(0.4, 0.28, 0.22), false, db)
	for k in 3:
		b.box(Vector3(1.5, 0.12, 0.08), door_pos + db * Vector3(0, -0.8 + k * 0.8, 0.12), Color(0.3, 0.22, 0.2), false, db)
	b.torus(0.03, 0.12, door_pos + db * Vector3(0, 0.0, 0.16), Color(0.6, 0.62, 0.68), db)
	b.box(Vector3(0.18, 0.2, 0.08), door_pos + db * Vector3(0, -0.2, 0.18), Color(0.85, 0.7, 0.2), false, db)
	b.collider(Vector3(4.4, height + 1.5, 4.4), Vector3(0, (height + 1.5) * 0.5 - 0.5, 0))
	b.build(n, Toon.vertex_color(0.012), "Mesh")
	label(n, "FERMÉ depuis plusieurs semaines.\nPar ordre de personne.", door_pos + door_dir * 0.6 + Vector3(0, 1.5, 0), 0.0034, Color(1.0, 0.85, 0.6), 48, atan2(door_dir.x, door_dir.z))
	return n


static func boat(b: Builder, p: Vector3, yaw: float, hull: Color, sail: Color) -> void:
	var bs := Basis(Vector3.UP, yaw)
	b.box(Vector3(1.1, 0.45, 2.8), p + bs * Vector3(0, 0.15, 0), hull, false, bs)
	b.prism(Vector3(1.1, 0.45, 1.0), p + bs * Vector3(0, 0.15, -1.9), hull, bs * Basis(Vector3.RIGHT, -PI * 0.5))
	b.box(Vector3(1.14, 0.1, 2.9), p + bs * Vector3(0, 0.38, 0), hull.lightened(0.3), false, bs)
	b.box(Vector3(0.08, 3.0, 0.08), p + bs * Vector3(0, 1.8, -0.2), DARK_WOOD, false, bs)
	b.prism(Vector3(1.4, 2.4, 0.04), p + bs * Vector3(0, 2.0, 0.5), sail, bs)
	b.collider(Vector3(1.1, 0.5, 2.8), p + bs * Vector3(0, 0.1, 0), bs)
