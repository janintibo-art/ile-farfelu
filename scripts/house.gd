extends Node3D
## La maison visitable : salon, coin cuisine et chambre, porte qui s'ouvre
## toute seule quand on s'approche (en grinçant, évidemment).

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Island := preload("res://scripts/island.gd")
const Fx := preload("res://scripts/fx.gd")

const FL := 0.03    # dessus du plancher
const WH := 3.0     # hauteur des murs
const T := 0.2      # épaisseur des murs

const WALL := Color(1.0, 0.95, 0.84)
const WALL_IN := Color(0.78, 0.93, 0.86)
const WOOD := Color(0.78, 0.56, 0.36)
const WOOD_DARK := Color(0.55, 0.36, 0.22)
const WHITE := Color(0.96, 0.96, 0.98)

var player: Node3D
var door_hinge: Node3D
var _door_angle := 0.0
var _door_open := false


func build() -> void:
	position = Vector3(Island.HOUSE_POS.x, Island.HOUSE_H, Island.HOUSE_POS.y)
	var b := Builder.new()

	# Sol et fondations
	b.box(Vector3(10.6, 1.2, 8.6), Vector3(0, FL - 0.1 - 0.6, 0), Color(0.7, 0.66, 0.62))
	b.box(Vector3(10.2, 0.2, 8.2), Vector3(0, FL - 0.1, 0), WOOD)
	b.box(Vector3(2.4, 0.06, 1.4), Vector3(0, FL - 0.03, 4.8), WOOD_DARK)

	# Murs extérieurs (avec porte et fenêtres)
	_wall_x(b, 4.0, -5.1, 5.1, [[-3.8, -2.2, 1.0, 2.2], [-0.7, 0.7, 0.0, 2.3], [2.2, 3.8, 1.0, 2.2]], WALL)
	_wall_x(b, -4.0, -5.1, 5.1, [[-3.6, -1.6, 1.1, 2.2], [2.0, 4.0, 1.0, 2.2]], WALL)
	_wall_z(b, -5.0, -3.9, 3.9, [[-1.0, 1.0, 1.0, 2.2]], WALL)
	_wall_z(b, 5.0, -3.9, 3.9, [[-0.2, 1.4, 1.0, 2.2]], WALL)
	# Cloison entre salon et chambre
	_wall_z(b, 1.0, -3.9, 3.9, [[-0.7, 0.6, 0.0, 2.3]], WALL_IN)

	# Plafond, toit, cheminée
	b.box(Vector3(10.2, 0.1, 8.2), Vector3(0, FL + WH + 0.05, 0), WHITE, false)
	b.prism(Vector3(9.2, 2.3, 11.0), Vector3(0, FL + WH + 1.2, 0), Color(0.95, 0.38, 0.35), Basis(Vector3.UP, PI / 2.0))
	b.box(Vector3(0.6, 1.6, 0.6), Vector3(3.0, FL + WH + 1.6, -1.8), Color(0.75, 0.4, 0.32), false)
	b.box(Vector3(11.2, 0.12, 0.3), Vector3(0, FL + WH + 0.1, 4.45), Color(0.85, 0.3, 0.3), false)

	# Rebords de fenêtres
	for x in [-3.0, 3.0]:
		b.box(Vector3(1.8, 0.08, 0.35), Vector3(x, FL + 1.0, 4.1), WHITE, false)
		b.box(Vector3(1.6, 0.25, 0.25), Vector3(x, FL + 0.85, 4.25), Color(0.9, 0.45, 0.35), false)
		for k in 4:
			b.sphere(0.09, Vector3(x - 0.55 + k * 0.37, FL + 1.06, 4.25), [Color(1, 0.4, 0.55), Color(1, 0.85, 0.3), Color(0.7, 0.5, 1)][k % 3])

	_living_room(b)
	_kitchen(b)
	_bedroom(b)
	b.build(self, Toon.vertex_color(), "House")

	_door()
	_signs()
	_lights()


# --- Murs -------------------------------------------------------------------

## Mur parallèle à X, à la profondeur z. holes = [[x0, x1, bas, haut], ...]
func _wall_x(b: Builder, z: float, x0: float, x1: float, holes: Array, col: Color) -> void:
	var cur := x0
	for h in holes:
		var a: float = h[0]
		var e: float = h[1]
		if a > cur:
			b.box(Vector3(a - cur, WH, T), Vector3((cur + a) * 0.5, FL + WH * 0.5, z), col)
		if h[2] > 0.001:
			b.box(Vector3(e - a, h[2], T), Vector3((a + e) * 0.5, FL + h[2] * 0.5, z), col)
		b.box(Vector3(e - a, WH - h[3], T), Vector3((a + e) * 0.5, FL + (h[3] + WH) * 0.5, z), col)
		cur = e
	if x1 > cur:
		b.box(Vector3(x1 - cur, WH, T), Vector3((cur + x1) * 0.5, FL + WH * 0.5, z), col)


## Mur parallèle à Z, à la position x.
func _wall_z(b: Builder, x: float, z0: float, z1: float, holes: Array, col: Color) -> void:
	var cur := z0
	for h in holes:
		var a: float = h[0]
		var e: float = h[1]
		if a > cur:
			b.box(Vector3(T, WH, a - cur), Vector3(x, FL + WH * 0.5, (cur + a) * 0.5), col)
		if h[2] > 0.001:
			b.box(Vector3(T, h[2], e - a), Vector3(x, FL + h[2] * 0.5, (a + e) * 0.5), col)
		b.box(Vector3(T, WH - h[3], e - a), Vector3(x, FL + (h[3] + WH) * 0.5, (a + e) * 0.5), col)
		cur = e
	if z1 > cur:
		b.box(Vector3(T, WH, z1 - cur), Vector3(x, FL + WH * 0.5, (cur + z1) * 0.5), col)


# --- Pièces -----------------------------------------------------------------

func _living_room(b: Builder) -> void:
	var teal := Color(0.25, 0.72, 0.75)
	# Tapis
	b.box(Vector3(3.0, 0.02, 2.4), Vector3(-2.6, FL + 0.01, 1.3), Color(1.0, 0.62, 0.72), false)
	# Canapé contre le mur de gauche
	b.box(Vector3(0.9, 0.45, 2.2), Vector3(-4.4, FL + 0.225, 1.3), teal)
	b.box(Vector3(0.25, 0.9, 2.2), Vector3(-4.76, FL + 0.45, 1.3), teal.darkened(0.1))
	b.box(Vector3(0.9, 0.62, 0.22), Vector3(-4.4, FL + 0.31, 0.2), teal.darkened(0.1))
	b.box(Vector3(0.9, 0.62, 0.22), Vector3(-4.4, FL + 0.31, 2.4), teal.darkened(0.1))
	b.box(Vector3(0.2, 0.42, 0.42), Vector3(-4.55, FL + 0.66, 0.8), Color(1, 0.85, 0.3), false, Basis(Vector3.RIGHT, 0.3))
	b.box(Vector3(0.2, 0.42, 0.42), Vector3(-4.55, FL + 0.66, 1.8), Color(1, 0.5, 0.6), false, Basis(Vector3.RIGHT, -0.25))
	# Table basse (+ une pile de mangas)
	b.box(Vector3(1.0, 0.08, 0.7), Vector3(-2.8, FL + 0.42, 1.3), WOOD)
	for p in [Vector2(-3.2, 1.05), Vector2(-2.4, 1.05), Vector2(-3.2, 1.55), Vector2(-2.4, 1.55)]:
		b.box(Vector3(0.06, 0.4, 0.06), Vector3(p.x, FL + 0.2, p.y), WOOD_DARK, false)
	var manga_cols := [Color(0.9, 0.3, 0.3), Color(0.3, 0.5, 0.9), Color(1.0, 0.8, 0.2), Color(0.4, 0.8, 0.4)]
	for k in 4:
		b.box(Vector3(0.22, 0.04, 0.3), Vector3(-3.05, FL + 0.48 + k * 0.042, 1.45), manga_cols[k], false, Basis(Vector3.UP, k * 0.25))
	# Meuble télé contre la cloison
	b.box(Vector3(0.5, 0.5, 1.6), Vector3(0.6, FL + 0.25, 1.8), WOOD_DARK)
	b.box(Vector3(0.08, 0.8, 1.3), Vector3(0.75, FL + 0.95, 1.8), Color(0.12, 0.12, 0.15), false)
	b.box(Vector3(0.01, 0.68, 1.18), Vector3(0.705, FL + 0.95, 1.8), Color(0.3, 0.75, 1.0), false)
	# Plante verte
	b.cylinder(0.22, 0.17, 0.4, Vector3(-4.5, FL + 0.2, 3.5), Color(0.85, 0.45, 0.3))
	for k in 5:
		b.sphere(0.2, Vector3(-4.5 + cos(k * 1.3) * 0.12, FL + 0.6 + k * 0.1, 3.5 + sin(k * 1.3) * 0.12), Color(0.3, 0.7, 0.3).lightened(k * 0.05))


func _kitchen(b: Builder) -> void:
	# Plan de travail le long du mur du fond
	b.box(Vector3(3.2, 0.9, 0.6), Vector3(-3.3, FL + 0.45, -3.55), WHITE)
	b.box(Vector3(3.3, 0.06, 0.66), Vector3(-3.3, FL + 0.93, -3.55), WOOD_DARK)
	b.cylinder(0.16, 0.14, 0.2, Vector3(-4.2, FL + 1.06, -3.55), Color(0.9, 0.3, 0.3))
	b.cylinder(0.18, 0.18, 0.02, Vector3(-4.2, FL + 1.17, -3.55), Color(0.9, 0.3, 0.3).darkened(0.2))
	b.box(Vector3(0.5, 0.02, 0.35), Vector3(-2.9, FL + 0.97, -3.55), Color(0.95, 0.85, 0.6), false)
	# Frigo rétro plein de magnets
	b.box(Vector3(0.8, 1.9, 0.7), Vector3(-1.1, FL + 0.95, -3.5), Color(0.6, 0.85, 1.0))
	b.box(Vector3(0.05, 0.5, 0.05), Vector3(-0.8, FL + 1.3, -3.12), WHITE, false)
	var mag := [Color(1, 0.4, 0.4), Color(1, 0.9, 0.3), Color(0.5, 0.9, 0.5), Color(0.9, 0.5, 1)]
	for k in 4:
		b.box(Vector3(0.1, 0.1, 0.02), Vector3(-1.3 + (k % 2) * 0.2, FL + 1.1 + (k / 2) * 0.3, -3.14), mag[k], false)
	# Table ronde et tabourets
	b.cylinder(0.65, 0.65, 0.06, Vector3(-2.6, FL + 0.75, -1.6), WOOD)
	b.cylinder(0.08, 0.2, 0.72, Vector3(-2.6, FL + 0.36, -1.6), WOOD_DARK)
	for sx in [-1.0, 1.0]:
		b.cylinder(0.22, 0.22, 0.06, Vector3(-2.6 + sx * 1.0, FL + 0.48, -1.6), Color(1.0, 0.6, 0.3))
		b.cylinder(0.05, 0.12, 0.46, Vector3(-2.6 + sx * 1.0, FL + 0.23, -1.6), WOOD_DARK)


func _bedroom(b: Builder) -> void:
	# Lit
	b.box(Vector3(1.6, 0.4, 2.2), Vector3(4.05, FL + 0.2, -2.7), WOOD)
	b.box(Vector3(1.5, 0.2, 2.1), Vector3(4.05, FL + 0.5, -2.7), WHITE)
	b.box(Vector3(1.54, 0.1, 1.4), Vector3(4.05, FL + 0.63, -2.25), Color(1.0, 0.55, 0.65), false)
	b.box(Vector3(1.0, 0.15, 0.4), Vector3(4.05, FL + 0.68, -3.45), WHITE, false)
	b.box(Vector3(1.6, 0.9, 0.12), Vector3(4.05, FL + 0.45, -3.86), WOOD_DARK)
	# Peluche géante de chat-patate
	var cream := Color(1.0, 0.92, 0.75)
	b.sphere(0.38, Vector3(2.0, FL + 0.36, -3.3), cream, Vector3(1.0, 0.9, 1.0))
	b.sphere(0.28, Vector3(2.0, FL + 0.9, -3.3), cream)
	for sx in [-1.0, 1.0]:
		b.prism(Vector3(0.14, 0.16, 0.06), Vector3(2.0 + sx * 0.15, FL + 1.18, -3.3), cream, Basis(Vector3.FORWARD, -sx * 0.35))
		b.sphere(0.035, Vector3(2.0 + sx * 0.09, FL + 0.93, -3.04), Color(0.13, 0.08, 0.17))
		b.sphere(1.0, Vector3(2.0 + sx * 0.16, FL + 0.84, -3.06), Color(1, 0.6, 0.65), Vector3(0.05, 0.03, 0.02))
	b.collider(Vector3(0.8, 1.1, 0.8), Vector3(2.0, FL + 0.55, -3.3))
	# Bureau
	b.box(Vector3(1.3, 0.06, 0.6), Vector3(2.2, FL + 0.75, 3.5), WOOD)
	for p in [Vector2(1.65, 3.3), Vector2(2.75, 3.3), Vector2(1.65, 3.7), Vector2(2.75, 3.7)]:
		b.box(Vector3(0.05, 0.72, 0.05), Vector3(p.x, FL + 0.36, p.y), WOOD_DARK, false)
	b.cylinder(0.02, 0.02, 0.4, Vector3(2.7, FL + 0.98, 3.6), Color(0.2, 0.2, 0.2))
	b.cylinder(0.06, 0.16, 0.18, Vector3(2.7, FL + 1.2, 3.6), Color(1.0, 0.85, 0.3))
	# Armoire
	b.box(Vector3(0.6, 2.0, 1.4), Vector3(4.6, FL + 1.0, 2.5), WOOD_DARK)
	b.box(Vector3(0.02, 1.8, 0.02), Vector3(4.29, FL + 1.0, 2.5), WOOD, false)
	# Poster
	b.box(Vector3(0.02, 1.0, 0.75), Vector3(1.11, FL + 1.7, -2.0), Color(1.0, 0.85, 0.3), false)
	# Tapis rond
	b.cylinder(1.0, 1.0, 0.02, Vector3(3.0, FL + 0.01, 0.4), Color(0.45, 0.65, 1.0), Basis(), 20)


# --- Porte, panneaux, lumières ---------------------------------------------

func _door() -> void:
	door_hinge = Node3D.new()
	door_hinge.name = "DoorHinge"
	door_hinge.position = Vector3(-0.7, FL, 4.0)
	add_child(door_hinge)
	var b := Builder.new()
	b.box(Vector3(1.38, 2.28, 0.08), Vector3(0.69, 1.14, 0), Color(0.62, 0.35, 0.8))
	b.box(Vector3(1.1, 0.06, 0.1), Vector3(0.69, 1.6, 0), Color(0.5, 0.25, 0.65), false)
	b.box(Vector3(1.1, 0.06, 0.1), Vector3(0.69, 0.6, 0), Color(0.5, 0.25, 0.65), false)
	b.sphere(0.06, Vector3(1.2, 1.1, 0.07), Color(1.0, 0.85, 0.2))
	b.sphere(0.06, Vector3(1.2, 1.1, -0.07), Color(1.0, 0.85, 0.2))
	# Petit coeur sur la porte
	b.sphere(0.07, Vector3(0.64, 1.95, 0.045), Color(1, 0.35, 0.5), Vector3(1, 1, 0.3))
	b.sphere(0.07, Vector3(0.74, 1.95, 0.045), Color(1, 0.35, 0.5), Vector3(1, 1, 0.3))
	b.prism(Vector3(0.2, 0.13, 0.02), Vector3(0.69, 1.87, 0.045), Color(1, 0.35, 0.5), Basis(Vector3.FORWARD, PI))
	b.build(door_hinge, Toon.vertex_color(0.008), "Door")


func _signs() -> void:
	var sign := Label3D.new()
	sign.text = "MAISON FARFELUE"
	sign.font_size = 96
	sign.outline_size = 24
	sign.modulate = Color(1.0, 0.85, 0.25)
	sign.outline_modulate = Color(0.13, 0.08, 0.17)
	sign.pixel_size = 0.004
	sign.position = Vector3(0, FL + 2.65, 4.12)
	add_child(sign)

	var tv := Label3D.new()
	tv.text = "ÉPISODE 1042\nLe cocotier\ncontre-attaque !"
	tv.font_size = 48
	tv.outline_size = 12
	tv.outline_modulate = Color(0.1, 0.2, 0.5)
	tv.pixel_size = 0.0035
	tv.position = Vector3(0.69, FL + 0.95, 1.8)
	tv.rotation.y = -PI / 2.0
	add_child(tv)

	var poster := Label3D.new()
	poster.text = "HÉROS\nDU\nDIMANCHE"
	poster.font_size = 64
	poster.outline_size = 16
	poster.modulate = Color(0.95, 0.3, 0.3)
	poster.outline_modulate = Color.WHITE
	poster.pixel_size = 0.004
	poster.position = Vector3(1.13, FL + 1.7, -2.0)
	poster.rotation.y = PI / 2.0
	add_child(poster)


func _lights() -> void:
	var l1 := OmniLight3D.new()
	l1.position = Vector3(-2.2, FL + 2.6, 0.0)
	l1.light_color = Color(1.0, 0.9, 0.75)
	l1.light_energy = 1.3
	l1.omni_range = 7.5
	add_child(l1)
	var l2 := OmniLight3D.new()
	l2.position = Vector3(3.0, FL + 2.6, -0.5)
	l2.light_color = Color(1.0, 0.8, 0.9)
	l2.light_energy = 1.2
	l2.omni_range = 6.0
	add_child(l2)


func _physics_process(delta: float) -> void:
	if player == null:
		return
	var door_world := to_global(Vector3(0, 1.0, 4.0))
	var d := Vector2(player.global_position.x - door_world.x, player.global_position.z - door_world.z).length()
	var want := d < 2.4
	if want and not _door_open:
		Fx.text(get_parent(), door_world + Vector3(0, 1.6, 0.6), "GRIIINCE !", Color(0.8, 0.6, 1.0), 0.7)
	_door_open = want
	_door_angle = lerpf(_door_angle, 1.75 if want else 0.0, clampf(delta * 3.0, 0.0, 1.0))
	door_hinge.rotation.y = _door_angle
