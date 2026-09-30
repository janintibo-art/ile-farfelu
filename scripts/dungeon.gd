extends Node3D
## Le Donjon des Boulettes. Il est construit "ailleurs" (haut dans le ciel,
## enfermé dans ses murs) et on y est téléporté par la porte de Riku.
## Plan en cases de 3 m : # mur, . sol, E sortie, C coffre, B coffre doré,
## s slime, c champignon, b chauve-souris, K le Roi Gloubi.

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Fx := preload("res://scripts/fx.gd")
const Monster := preload("res://scripts/monster.gd")
const Chest := preload("res://scripts/chest.gd")

const MAP := [
	"###############",
	"#C.s#.....b.#C#",
	"#...#.#####.#.#",
	"#.c.....c.....#",
	"##.####.#####.#",
	"#b..#C.s#K..B##",
	"#.#.#.###...###",
	"#.#...c.#...#C#",
	"#.#####.##.##.#",
	"#s..C#..s.....#",
	"####.#.####.###",
	"#c.....b......#",
	"#######.#######",
	"#######E#######",
	"###############",
]
const C := 3.0
const WALL_H := 3.5
const ORIGIN := Vector3(-22.5, 200.0, -21.0)
const CHUNK := 5
const MONSTER_TYPES := {"s": "slime", "c": "champi", "b": "bat", "K": "boss"}

var world: Node3D
var player
var monsters: Array = []
var chests: Array = []
var lights: Array = []
var boss_dead := false
var exit_pos := Vector3.ZERO
var _entered_at := 0.0
var _t := 0.0


func cell(i: int, j: int) -> String:
	if j < 0 or j >= MAP.size() or i < 0 or i >= MAP[0].length():
		return "#"
	return MAP[j][i]


func is_floor(i: int, j: int) -> bool:
	return cell(i, j) != "#"


func center(i: int, j: int) -> Vector3:
	return ORIGIN + Vector3(i * C + C * 0.5, 0.0, j * C + C * 0.5)


func build(p_world: Node3D, p_player) -> void:
	world = p_world
	player = p_player
	var w: int = MAP[0].length()
	var h: int = MAP.size()
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var chunks := {}
	var flames := {}
	for j in h:
		for i in w:
			var key := Vector2i(i / CHUNK, j / CHUNK)
			if not chunks.has(key):
				chunks[key] = Builder.new()
				flames[key] = Builder.new()
			var b: Builder = chunks[key]
			var c := center(i, j) - global_position
			if is_floor(i, j):
				var tile := Color(0.62, 0.56, 0.72) if (i + j) % 2 == 0 else Color(0.7, 0.64, 0.8)
				b.box(Vector3(C, 0.2, C), c + Vector3(0, -0.1, 0), tile, false)
				b.box(Vector3(C, 0.2, C), c + Vector3(0, WALL_H + 0.1, 0), Color(0.36, 0.3, 0.44), false)
				_torch(b, flames[key], i, j, c)
			elif _touches_floor(i, j):
				var stone := Color(0.74, 0.68, 0.86).darkened(rng.randf_range(0.0, 0.15))
				b.box(Vector3(C, WALL_H, C), c + Vector3(0, WALL_H * 0.5, 0), stone)
				b.box(Vector3(C + 0.04, 0.3, C + 0.04), c + Vector3(0, 0.15, 0), stone.darkened(0.25), false)
				if rng.randf() < 0.25:
					b.box(Vector3(C + 0.06, 0.5, C + 0.06), c + Vector3(0, WALL_H - 0.6, 0), Color(0.35, 0.6, 0.35), false)
	for key in chunks:
		var mi: MeshInstance3D = chunks[key].build(self, Toon.vertex_color(), "Chunk%d_%d" % [key.x, key.y])
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if not flames[key].empty:
			var fl: MeshInstance3D = flames[key].build(self, Toon.unlit(Color(1.0, 0.65, 0.2)), "Flames")
			fl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Sol et plafond : deux grandes boîtes de collision
	var solid := StaticBody3D.new()
	solid.name = "FloorCeiling"
	add_child(solid)
	var size := Vector3(w * C, 0.2, h * C)
	var mid := ORIGIN + Vector3(w * C * 0.5, 0, h * C * 0.5) - global_position
	for y in [-0.1, WALL_H + 0.1]:
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		cs.position = mid + Vector3(0, y, 0)
		solid.add_child(cs)

	# Coffres, sortie, panneaux
	for j in h:
		for i in w:
			var ch := cell(i, j)
			if ch == "C" or ch == "B":
				var chest := Chest.new()
				add_child(chest)
				chest.global_position = center(i, j)
				chest.setup(self, ch == "B")
				chest.global_rotation.y = _face_open(i, j)
				chests.append(chest)
			elif ch == "E":
				exit_pos = center(i, j)
				_exit_stairs(i, j)
	_sign(center(7, 11) + Vector3(0, 2.4, -1.4), "Défense de nourrir les slimes", 0.0)
	_sign(center(10, 8) + Vector3(0, 2.6, 0.0), "SALLE DU TRÔNE\n(du Roi Gloubi)", 0.0)
	_sign(center(4, 5) + Vector3(0, 2.4, 0.0), "Ici, un champignon\na mangé un aventurier.\nEnfin, il a essayé.", PI / 2.0)


func _touches_floor(i: int, j: int) -> bool:
	for dj in [-1, 0, 1]:
		for di in [-1, 0, 1]:
			if is_floor(i + di, j + dj):
				return true
	return false


func _face_open(i: int, j: int) -> float:
	# Oriente le coffre vers une case libre voisine (avant du coffre = -Z)
	var dirs := [[0, 1], [1, 0], [-1, 0], [0, -1]]
	for d in dirs:
		if is_floor(i + d[0], j + d[1]) and cell(i + d[0], j + d[1]) not in ["C", "B"]:
			return atan2(-float(d[0]), -float(d[1]))
	return 0.0


func _torch(b: Builder, fb: Builder, i: int, j: int, c: Vector3) -> void:
	if (i * 7 + j * 3) % 4 != 0:
		return
	for d in [[0, -1], [1, 0], [-1, 0], [0, 1]]:
		if not is_floor(i + d[0], j + d[1]):
			var n := Vector3(d[0], 0, d[1])
			var p := c + n * (C * 0.5 - 0.15) + Vector3(0, 2.1, 0)
			b.box(Vector3(0.08, 0.4, 0.08), p + Vector3(0, -0.2, 0) - n * 0.08, Color(0.35, 0.22, 0.12), false, Basis(n.cross(Vector3.UP).normalized(), 0.35) if n != Vector3.ZERO else Basis())
			fb.sphere(0.1, p + Vector3(0, 0.05, 0) - n * 0.15, Color.WHITE, Vector3(1.0, 1.5, 1.0))
			var l := OmniLight3D.new()
			l.light_color = Color(1.0, 0.72, 0.4)
			l.light_energy = 1.6
			l.omni_range = 7.5
			l.omni_attenuation = 1.2
			add_child(l)
			l.position = p - n * 0.4
			lights.append(l)
			return


func _exit_stairs(i: int, j: int) -> void:
	var b := Builder.new()
	var c := center(i, j) - global_position
	for k in 5:
		b.box(Vector3(2.4, 0.2, 0.5), c + Vector3(0, 0.1 + k * 0.2, 0.9 - k * 0.1), Color(0.6, 0.55, 0.7).lightened(k * 0.04), false)
	b.build(self, Toon.vertex_color(), "ExitStairs")
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.85
	tm.outer_radius = 1.0
	ring.mesh = tm
	ring.material_override = Toon.unlit(Color(0.5, 1.0, 0.8))
	add_child(ring)
	ring.global_position = center(i, j) + Vector3(0, 1.4, 0.6)
	ring.rotation.x = PI / 2.0
	_sign(center(i, j) + Vector3(0, 2.8, 0.2), "SORTIE", 0.0)


func _sign(pos: Vector3, txt: String, yaw: float) -> void:
	var l := Label3D.new()
	l.text = txt
	l.font_size = 48
	l.outline_size = 14
	l.modulate = Color(1.0, 0.85, 0.4)
	l.outline_modulate = Color(0.13, 0.08, 0.17)
	l.pixel_size = 0.004
	l.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	add_child(l)
	l.global_position = pos


# --- Vie du donjon ------------------------------------------------------------

func start_position() -> Vector3:
	return center(7, 12) + Vector3(0, 0.1, 0)


func on_enter() -> void:
	_entered_at = _t
	boss_dead = false
	for m in monsters:
		if is_instance_valid(m):
			m.queue_free()
	monsters.clear()
	for chest in chests:
		chest.reset()
	for j in MAP.size():
		for i in MAP[0].length():
			var ch := cell(i, j)
			if MONSTER_TYPES.has(ch):
				spawn_monster(MONSTER_TYPES[ch], center(i, j) + Vector3(0, 0.3, 0))


func spawn_monster(type: String, pos: Vector3) -> void:
	var m := Monster.new()
	m.name = "Monster_" + type
	world.add_child(m)
	m.global_position = pos
	m.setup(type, player, self)
	monsters.append(m)


func on_boss_dead() -> void:
	boss_dead = true


func _process(delta: float) -> void:
	_t += delta
	if player == null or not player.in_dungeon:
		return
	# Les torches vacillent
	for k in lights.size():
		lights[k].light_energy = 1.5 + sin(_t * 9.0 + k * 1.7) * 0.12 + sin(_t * 23.0 + k) * 0.06
	# Sortie
	if _t - _entered_at > 2.0:
		var d: Vector3 = player.global_position - exit_pos
		if Vector2(d.x, d.z).length() < 1.1 and absf(d.y) < 2.0:
			player.exit_dungeon(false)
