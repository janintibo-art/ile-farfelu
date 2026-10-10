extends RefCounted
## Chapitre 4, première partie : BELLOCHE, « la ville qui perdit sa musique ».
## Village de carillonneurs sur un plateau (zone y = 900). Plus aucun instrument n'y sonne
## et les habitants ont perdu la voix. Trois énigmes sonores (tambours, oiseau caché, mélodie
## de cloches) permettent de sonner la Grosse Cloche. Sous le clocher : la Cathédrale des Échos.

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Fx := preload("res://scripts/fx.gd")
const Save := preload("res://scripts/save.gd")
const Characters := preload("res://scripts/characters.gd")
const VB := preload("res://scripts/village_build.gd")
const Island := preload("res://scripts/island.gd")
const Bells := preload("res://scripts/bells.gd")

const P := Vector3(0.0, 900.0, 0.0)
const STONE := Color(0.72, 0.7, 0.68)
const WOODC := Color(0.6, 0.42, 0.3)
const GRASS := Color(0.5, 0.75, 0.4)

const DRUM_SEQ := [0, 2, 1, 0]
const DRUM_KINDS := ["wood", "metal", "stone"]
const DRUM_NAMES := ["bois", "métal", "pierre"]
const DRUM_POS := [Vector3(10.5, 0.0, 22.0), Vector3(13.0, 0.0, 22.6), Vector3(15.5, 0.0, 22.0)]

const BIRD_TREES := [Vector3(-18.0, 0.0, 14.0), Vector3(-22.0, 0.0, 22.0), Vector3(-15.0, 0.0, 28.0)]
const BIRD_RIGHT := 1

const BELL_NOTES := [Bells.DO, Bells.RE, Bells.MI, Bells.SOL, Bells.LA]
const BELL_NAMES := ["rouge", "orange", "verte", "bleue", "violette"]
const BELL_COLS := [Color(0.95, 0.35, 0.35), Color(1.0, 0.65, 0.25), Color(0.5, 0.85, 0.4), Color(0.4, 0.65, 1.0), Color(0.75, 0.5, 0.95)]
const BELL_SEQ := [0, 2, 3, 2, 0]
const BELL_POS := [Vector3(-4.0, 0.0, 2.0), Vector3(-2.0, 0.0, 2.0), Vector3(0.0, 0.0, 2.0), Vector3(2.0, 0.0, 2.0), Vector3(4.0, 0.0, 2.0)]

const BIG_POS := Vector3(0.0, 10.2, -8.0)

var v
var root: Node3D
var big: Node3D
var deco: Array = []
var bird: Node3D
var _busy := false
var _ret := Vector3.ZERO
var _t := 0.0
var _lock := false
var _in := {"drum": [], "bell": []}
var _last_hit := {"drum": 0.0, "bell": 0.0}
var _big_amp := 0.0


func build() -> void:
	Save.story["at_k"] = false
	root = Node3D.new()
	root.name = "Belloche"
	v.add_child(root)
	root.position = P
	root.visible = false
	_ground()
	_tower()
	_bell_frames()
	_workshop()
	_trees()
	_drums()
	_bell_stand()
	_jars()
	_people()
	_hotspots()


func _s(k: String) -> bool:
	return Save.story.get(k, false)


func _later(t: float, c: Callable) -> void:
	v.get_tree().create_timer(t).timeout.connect(c)


func active() -> bool:
	return root != null and root.visible


func _all_solved() -> bool:
	return _s("k_drum") and _s("k_bird") and _s("k_bell")


func _say_npc(id: String, t: String) -> void:
	var sp: Dictionary = v._speaker(id)
	if sp.is_empty():
		return
	Fx.text(v.world, sp["node"].global_position + Vector3(0, 2.1, 0), t, Color(1.0, 0.98, 0.9), 0.55, 6.0)


# --- Décor -------------------------------------------------------------------------------------

func _ground() -> void:
	var sea := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(600.0, 600.0)
	sea.mesh = pm
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.45, 0.7, 0.85)
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sea.material_override = sm
	root.add_child(sea)
	sea.position = Vector3(0, -30.0, 0)
	var b := Builder.new()
	b.box(Vector3(64.0, 1.0, 84.0), Vector3(0, -0.5, -2.0), GRASS, true)
	b.cylinder(32.0, 22.0, 28.0, Vector3(0, -15.0, -2.0), Color(0.55, 0.5, 0.45), Basis(), 12)
	# Chemin dallé
	b.box(Vector3(3.0, 0.04, 70.0), Vector3(0, 0.02, 5.0), Color(0.85, 0.8, 0.7), false)
	b.box(Vector3(30.0, 0.04, 3.0), Vector3(0, 0.02, 20.0), Color(0.85, 0.8, 0.7), false)
	b.box(Vector3(14.0, 0.04, 14.0), Vector3(0, 0.02, 3.0), Color(0.88, 0.84, 0.74), false)
	for sx in [-1, 1]:
		b.collider(Vector3(2.0, 10.0, 90.0), Vector3(sx * 33.0, 4.0, -2.0))
	b.collider(Vector3(66.0, 10.0, 2.0), Vector3(0, 4.0, -45.0))
	b.collider(Vector3(66.0, 10.0, 2.0), Vector3(0, 4.0, 41.0))
	b.build(root, Toon.vertex_color(0.006), "Plateau")
	VB.label(root, "BELLOCHE", Vector3(0, 3.4, 36.5), 0.0085, Color(1, 0.95, 0.8), 56, 0.0, 10)
	VB.label(root, "ville des mille cloches", Vector3(0, 2.7, 36.5), 0.0034, Color(1, 0.95, 0.8), 44, 0.0, 6)
	VB.label(root, "(silence garanti depuis hier, ou depuis toujours)", Vector3(0, 2.2, 36.5), 0.0022, Color(1, 0.95, 0.8), 40, 0.0, 6)
	var pb := Builder.new()
	for sx in [-1.6, 1.6]:
		pb.cylinder(0.1, 0.12, 3.6, Vector3(sx, 1.8, 36.4), WOODC.darkened(0.2), Basis(), 6)
	pb.box(Vector3(3.6, 0.2, 0.2), Vector3(0, 3.7, 36.4), WOODC, false)
	pb.build(root, Toon.vertex_color(0.006), "Portique")


func _tower() -> void:
	var b := Builder.new()
	b.box(Vector3(6.0, 8.0, 6.0), Vector3(0, 4.0, -8.0), STONE, true)
	b.box(Vector3(6.4, 0.5, 6.4), Vector3(0, 8.2, -8.0), STONE.darkened(0.12), false)
	for sx in [-2.6, 2.6]:
		for sz in [-2.6, 2.6]:
			b.box(Vector3(0.6, 4.2, 0.6), Vector3(sx, 10.5, -8.0 + sz), STONE, false)
	b.prism(Vector3(7.2, 3.6, 7.2), Vector3(0, 14.6, -8.0), Color(0.75, 0.35, 0.3), Basis())
	b.box(Vector3(1.3, 2.4, 0.15), Vector3(0, 1.2, -4.95), Color(0.35, 0.25, 0.25), false)
	b.build(root, Toon.vertex_color(0.008), "Clocher")
	VB.label(root, "LE CLOCHER", Vector3(0, 6.6, -4.9), 0.006, Color(1, 0.97, 0.85), 52, 0.0, 10)
	big = Node3D.new()
	big.name = "GrosseCloche"
	root.add_child(big)
	big.position = BIG_POS
	var bb := Builder.new()
	bb.cylinder(0.5, 1.5, 2.0, Vector3(0, -0.8, 0), Color(0.85, 0.65, 0.25), Basis(), 14)
	bb.sphere(0.35, Vector3(0, -2.0, 0), Color(0.4, 0.3, 0.2), Vector3.ONE, Basis(), 8)
	bb.cylinder(0.12, 0.12, 0.8, Vector3(0, 0.6, 0), WOODC.darkened(0.3), Basis(), 6)
	bb.build(big, Toon.vertex_color(0.006), "Cloche")
	var rb := Builder.new()
	rb.cylinder(0.03, 0.03, 2.6, Vector3(1.9, 1.5, -4.7), Color(0.85, 0.75, 0.55), Basis(), 4)
	rb.sphere(0.12, Vector3(1.9, 0.15, -4.7), Color(0.7, 0.2, 0.2), Vector3.ONE, Basis(), 6)
	rb.build(root, Toon.vertex_color(0.0), "Corde")


func _bell_frames() -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.06
	mesh.bottom_radius = 0.26
	mesh.height = 0.44
	mesh.radial_segments = 8
	var mat := Toon.flat(Color(0.9, 0.7, 0.3))
	var frames := [Vector3(-24.0, 0.0, 4.0), Vector3(24.0, 0.0, 6.0), Vector3(-24.0, 0.0, -22.0), Vector3(24.0, 0.0, -22.0)]
	for f in frames:
		var fb := Builder.new()
		fb.box(Vector3(0.25, 3.4, 0.25), f + Vector3(-3.4, 1.7, 0), WOODC, false)
		fb.box(Vector3(0.25, 3.4, 0.25), f + Vector3(3.4, 1.7, 0), WOODC, false)
		fb.box(Vector3(7.4, 0.22, 0.28), f + Vector3(0, 3.4, 0), WOODC.darkened(0.1), false)
		fb.build(root, Toon.vertex_color(0.006), "Cadre")
		for k in 6:
			var piv := Node3D.new()
			root.add_child(piv)
			piv.position = f + Vector3(-2.75 + k * 1.1, 3.3, 0)
			var m := MeshInstance3D.new()
			m.mesh = mesh
			m.material_override = mat
			piv.add_child(m)
			m.position = Vector3(0, -0.3, 0)
			deco.append({"n": piv, "amp": 0.0, "ph": float(deco.size()) * 0.7, "note": BELL_NOTES[deco.size() % 5]})


func _workshop() -> void:
	var b := Builder.new()
	var c := Vector3(-14.0, 0.0, 6.0)
	b.box(Vector3(5.0, 3.0, 4.4), c + Vector3(0, 1.5, 0), Color(0.95, 0.88, 0.7), true)
	b.prism(Vector3(5.8, 1.5, 5.2), c + Vector3(0, 3.7, 0), Color(0.4, 0.55, 0.7), Basis())
	b.box(Vector3(1.0, 1.9, 0.12), c + Vector3(2.0, 0.95, 2.25), Color(0.4, 0.3, 0.3), false)
	b.build(root, Toon.vertex_color(0.008), "Atelier")
	VB.label(root, "ATELIER DE FLÛTES", c + Vector3(0, 3.0, 2.35), 0.0034, Color(1, 0.97, 0.85), 52, 0.0, 10)
	VB.label(root, "(ouvert, mais muet)", c + Vector3(0, 2.4, 2.35), 0.0022, Color(1, 0.97, 0.85), 44, 0.0, 6)


func _trees() -> void:
	var b := Builder.new()
	var all: Array = BIRD_TREES.duplicate()
	all.append_array([Vector3(-26.0, 0.0, 34.0), Vector3(26.0, 0.0, 30.0), Vector3(-10.0, 0.0, 36.0), Vector3(22.0, 0.0, 10.0), Vector3(-28.0, 0.0, -6.0)])
	for p in all:
		b.cylinder(0.3, 0.4, 3.0, p + Vector3(0, 1.5, 0), WOODC.darkened(0.2), Basis(), 6)
		b.sphere(2.2, p + Vector3(0, 4.2, 0), Color(0.35, 0.65, 0.35), Vector3(1.0, 0.9, 1.0), Basis(), 9)
		b.sphere(1.5, p + Vector3(1.1, 3.4, 0.6), Color(0.4, 0.72, 0.38), Vector3.ONE, Basis(), 8)
	b.build(root, Toon.vertex_color(0.006), "Arbres")
	bird = Node3D.new()
	root.add_child(bird)
	var bb := Builder.new()
	bb.sphere(0.12, Vector3.ZERO, Color(1.0, 0.85, 0.2), Vector3(1.0, 0.9, 1.3), Basis(), 6)
	bb.sphere(0.07, Vector3(0, 0.1, 0.12), Color(1.0, 0.85, 0.2), Vector3.ONE, Basis(), 5)
	bb.box(Vector3(0.03, 0.03, 0.09), Vector3(0, 0.1, 0.2), Color(1.0, 0.5, 0.2), false)
	bb.build(bird, Toon.vertex_color(0.0), "Oiseau")
	bird.visible = false


func _drums() -> void:
	var b := Builder.new()
	var cols := [Color(0.7, 0.5, 0.3), Color(0.75, 0.78, 0.85), Color(0.6, 0.58, 0.55)]
	for i in 3:
		var p: Vector3 = DRUM_POS[i]
		b.cylinder(0.5, 0.45, 0.8, p + Vector3(0, 0.4, 0), cols[i], Basis(), 12)
		b.cylinder(0.52, 0.52, 0.06, p + Vector3(0, 0.83, 0), cols[i].lightened(0.2), Basis(), 12)
	b.build(root, Toon.vertex_color(0.006), "Tambours")


func _bell_stand() -> void:
	var b := Builder.new()
	b.box(Vector3(11.0, 0.15, 0.4), Vector3(0, 0.9, 2.0), WOODC, false)
	for sx in [-5.2, 5.2]:
		b.box(Vector3(0.2, 0.9, 0.3), Vector3(sx, 0.45, 2.0), WOODC.darkened(0.2), false)
	b.build(root, Toon.vertex_color(0.006), "Support")
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.08
	mesh.bottom_radius = 0.38
	mesh.height = 0.6
	mesh.radial_segments = 10
	for i in 5:
		var m := MeshInstance3D.new()
		m.mesh = mesh
		m.material_override = Toon.flat(BELL_COLS[i])
		root.add_child(m)
		m.position = BELL_POS[i] + Vector3(0, 1.3, 0)


func _jars() -> void:
	var b := Builder.new()
	for p in [Vector3(17.0, 0.0, 20.0), Vector3(-12.0, 0.0, 17.0), Vector3(6.5, 0.0, 3.0)]:
		b.sphere(0.5, p + Vector3(0, 0.55, 0), Color(0.78, 0.5, 0.35), Vector3(1.0, 1.1, 1.0), Basis(), 10)
		b.cylinder(0.2, 0.3, 0.25, p + Vector3(0, 1.12, 0), Color(0.78, 0.5, 0.35), Basis(), 8)
		b.box(Vector3(0.5, 0.32, 0.03), p + Vector3(0, 0.6, 0.5), Color(0.97, 0.95, 0.85), false)
	b.build(root, Toon.vertex_color(0.006), "Pots")


func _people() -> void:
	v.x._npc(root, "tam", Characters.TAM, Vector3(13.0, 0.03, 19.5), PI)
	v.x._npc(root, "sifflot", Characters.SIFFLOT, Vector3(-11.0, 0.03, 10.0), 0.0)
	v.x._npc(root, "carillon", Characters.CARILLON, Vector3(-6.5, 0.03, -1.0), PI * 0.5)


func _hotspots() -> void:
	v.x.hotspot(root, Vector3(0, 1.3, 35.0), "Retourner à Port-Biscornu", func(): leave(), func(): return active() and not _busy, 2.0, 4.0)
	# Pots
	for p in [Vector3(17.0, 1.9, 20.0), Vector3(-12.0, 1.9, 17.0), Vector3(6.5, 1.9, 3.0)]:
		v.x.hotspot(root, p, "Lire l'étiquette du pot", _jar, func(): return active(), 1.7, 3.0)
	# Tambours
	for i in 3:
		v.x.hotspot(root, DRUM_POS[i] + Vector3(0, 1.4, 0), "Frapper : " + DRUM_NAMES[i], _hit_drum.bind(i), func(): return active() and not _lock, 1.5, 2.6)
	v.x.hotspot(root, Vector3(13.0, 2.6, 21.0), "Écouter Tam", _play_drums, func(): return active() and not _lock, 1.5, 4.0)
	# Oiseau
	v.x.hotspot(root, Vector3(-14.0, 1.7, 21.0), "Écouter le vent", _wind, func(): return active() and not _lock and not _s("k_bird"), 1.6, 3.5)
	for i in 3:
		var p: Vector3 = BIRD_TREES[i] + Vector3(2.2, 1.7, 0.0)
		v.x.hotspot(root, p, "Regarder dans l'arbre", _look_tree.bind(i), func(): return active() and not _s("k_bird"), 1.6, 3.0)
	# Cloches
	for i in 5:
		v.x.hotspot(root, BELL_POS[i] + Vector3(0, 2.1, 0), "Cloche " + BELL_NAMES[i], _hit_bell.bind(i), func(): return active() and not _lock, 1.3, 2.4)
	v.x.hotspot(root, Vector3(0, 3.3, 2.0), "Écouter l'air", _play_bells, func(): return active() and not _lock, 1.4, 4.0)
	# Grosse Cloche
	v.x.hotspot(root, Vector3(1.9, 1.7, -4.4), "Tirer la corde", _rope, func(): return active() and not _s("k_done") and not _lock, 1.5, 3.0)
	v.x.hotspot(root, Vector3(0, 2.4, -4.5), "Descendre sous le clocher", _descend, func(): return active() and _s("k_done"), 2.0, 3.5)


# --- Voyage ---------------------------------------------------------------------------------------

func travel() -> void:
	if _busy:
		return
	_busy = true
	if v.player.global_position.y < 100.0:
		_ret = v.player.global_position
	else:
		_ret = Vector3(4.2, Island.height(4.2, -39.5) + 0.2, -39.5)
	var tw: Tween = v.maquette._fade_to(0.0, 1.0, 0.9)
	tw.tween_callback(_travel_now)


func _travel_now() -> void:
	if v.b.root != null:
		v.b.root.visible = false
	if v.z.root != null:
		v.z.root.visible = false
	Save.story["at_v"] = false
	Save.story["at_b"] = false
	root.visible = true
	Save.story["at_k"] = true
	Save.story["v4_started"] = true
	Save.save_game()
	var ele: Dictionary = v._speaker("eleonore")
	if not ele.is_empty():
		var node = ele["node"]
		if node.get_parent() != root:
			node.get_parent().remove_child(node)
			root.add_child(node)
		node.position = Vector3(1.8, 0.03, 32.5)
		node.rest_yaw = 0.0
	v.player.global_position = P + Vector3(0, 0.1, 34.0)
	v.player._vy = 0.0
	v.player._face_yaw(0.0)
	v.player._place_origin(true, 0.0)
	var tw2: Tween = v.maquette._fade_to(1.0, 0.0, 1.0)
	tw2.tween_callback(_arrived)


func _arrived() -> void:
	_busy = false
	Fx.text(v.world, P + Vector3(0, 3.0, 30.0), "CHAPITRE 4", Color(1.0, 0.95, 0.5), 1.5, 5.0)
	_later(1.2, func(): Fx.text(v.world, P + Vector3(0, 2.2, 30.0), "LA VILLE QUI PERDIT SA MUSIQUE", Color(1.0, 0.85, 0.5), 0.8, 5.0))
	_later(3.0, func(): v._pico("Des cloches partout, et pas un son. Même le vent passe sur la pointe des pieds. Quelqu'un a rangé la musique, comme on range un mardi."))


func leave() -> void:
	if _busy:
		return
	_busy = true
	var tw: Tween = v.maquette._fade_to(0.0, 1.0, 0.9)
	tw.tween_callback(_leave_now)


func _leave_now() -> void:
	root.visible = false
	Save.story["at_k"] = false
	Save.save_game()
	v.y.place_eleonore()
	v.player.global_position = _ret
	v.player._vy = 0.0
	v.player._place_origin(true, 0.0)
	var tw2: Tween = v.maquette._fade_to(1.0, 0.0, 0.9)
	tw2.tween_callback(_unbusy)


func _unbusy() -> void:
	_busy = false


# --- Énigmes ---------------------------------------------------------------------------------------

func _jar() -> void:
	Save.story["k_jar"] = true
	var p: Vector3 = v.player.global_position + Vector3(0, 2.0, 0) - v.player.global_basis.z * 1.6
	Fx.text(v.world, p, "CONSERVÉ : « Musique, 1 lot » — Château des Versions Officielles", Color(1.0, 0.95, 0.8), 0.5, 6.0)
	if not _s("k_jar_said"):
		Save.story["k_jar_said"] = true
		_later(1.5, func(): v._pico("Encore le Château des Versions Officielles. Ils ont mis la musique en pots. Ce qui explique que près d'un pot, tout répond un peu mieux."))
	Save.save_game()


func _pos_of(i: int, list: Array) -> Vector3:
	return P + list[i]


func _seq_play(kind: String, seq: Array, step: float) -> void:
	_lock = true
	for n in seq.size():
		var i: int = seq[n]
		_later(0.4 + n * step, _tone.bind(kind, i))
	_later(0.6 + seq.size() * step, _unlock)


func _unlock() -> void:
	_lock = false


func _tone(kind: String, i: int) -> void:
	if kind == "drum":
		Bells.play(v.world, DRUM_KINDS[i], 0.0, P + DRUM_POS[i] + Vector3(0, 1.0, 0), 2.0)
	else:
		Bells.play(v.world, "bell", BELL_NOTES[i], P + BELL_POS[i] + Vector3(0, 1.3, 0), 0.0)


func _input_step(key: String, i: int, seq: Array) -> bool:
	if _t - float(_last_hit[key]) > 7.0:
		_in[key] = []
	_last_hit[key] = _t
	var cur: Array = _in[key]
	cur.append(i)
	for n in cur.size():
		if cur[n] != seq[n]:
			_in[key] = []
			Fx.text(v.world, v.player.global_position + Vector3(0, 2.2, 0) - v.player.global_basis.z * 1.5, "Pas tout à fait... on reprend", Color(1.0, 0.8, 0.7), 0.5, 2.5)
			return false
	if cur.size() == seq.size():
		_in[key] = []
		return true
	return false


func _hit_drum(i: int) -> void:
	_tone("drum", i)
	if _s("k_drum"):
		return
	if _input_step("drum", i, DRUM_SEQ):
		_later(0.8, _solve.bind("drum"))


func _play_drums() -> void:
	_in["drum"] = []
	_seq_play("drum", DRUM_SEQ, 0.75)
	_say_npc("tam", "*tape sur ses genoux : bois, pierre... il compte avec les doigts*")


func _hit_bell(i: int) -> void:
	_tone("bell", i)
	_ring_deco(i)
	if _s("k_bell"):
		return
	if _input_step("bell", i, BELL_SEQ):
		_later(0.9, _solve.bind("bell"))


func _play_bells() -> void:
	_in["bell"] = []
	_seq_play("bell", BELL_SEQ, 0.8)
	var sp: Dictionary = v._speaker("carillon")
	if not sp.is_empty():
		_say_npc("carillon", "*dessine l'air : haut, bas, plus haut, bas, le premier*")


func _ring_deco(i: int) -> void:
	for k in 4:
		var d: Dictionary = deco[(i * 3 + k * 5) % deco.size()]
		d["amp"] = 0.45


func _wind() -> void:
	_lock = true
	Fx.text(v.world, v.player.global_position + Vector3(0, 2.2, 0) - v.player.global_basis.z * 1.5, "(un trille, très doux...)", Color(0.9, 1.0, 0.9), 0.5, 3.0)
	_later(0.8, _chirp)
	_later(2.2, _unlock)


func _chirp() -> void:
	Bells.play(v.world, "bird", 0.0, P + BIRD_TREES[BIRD_RIGHT] + Vector3(0, 4.0, 0), 4.0)


func _look_tree(i: int) -> void:
	if i != BIRD_RIGHT:
		var p: Vector3 = P + BIRD_TREES[i] + Vector3(0, 2.4, 0)
		Fx.text(v.world, p, "Rien que des feuilles.", Color(0.9, 1.0, 0.9), 0.55, 2.5)
		return
	bird.visible = true
	bird.global_position = P + BIRD_TREES[i] + Vector3(0.5, 3.2, 1.8)
	Bells.play(v.world, "bird", 0.0, bird.global_position, 3.0)
	_later(0.8, _solve.bind("bird"))


func _solve(k: String) -> void:
	Save.story["k_" + k] = true
	Save.shells += 5
	Save.save_game()
	var msg := {"drum": "LE RYTHME EST RETROUVÉ", "bird": "L'OISEAU EST RETROUVÉ", "bell": "LA MÉLODIE EST RETROUVÉE"}
	var p: Vector3 = v.player.global_position + Vector3(0, 2.6, 0)
	Fx.text(v.world, p, msg[k], Color(0.7, 1.0, 0.75), 0.8, 4.0)
	Fx.text(v.world, p - Vector3(0, 0.6, 0), "+5 coquillages", Color(1.0, 0.9, 0.5), 0.6, 3.0)
	Fx.puff(v.world, v.player.global_position + Vector3(0, 1.5, 0), Color(1.0, 0.9, 0.5))
	if _all_solved():
		_later(2.5, func(): v._pico("Trois sons rendus : un rythme, un oiseau, un air. La Grosse Cloche, au clocher, devrait enfin accepter qu'on tire sa corde."))
	else:
		var left := 0
		for q in ["k_drum", "k_bird", "k_bell"]:
			if not _s(q):
				left += 1
		_later(2.5, func(): v._pico("Un son de retrouvé. Encore %d à rendre au village." % left))


# --- Grosse Cloche --------------------------------------------------------------------------------

func _rope() -> void:
	if not _all_solved():
		_big_amp = 0.25
		Fx.text(v.world, P + Vector3(1.9, 3.4, -4.4), "*frrrt* (la cloche bouge, mais ne dit rien)", Color(1.0, 0.9, 0.8), 0.55, 4.0)
		if not _s("k_rope_said"):
			Save.story["k_rope_said"] = true
			_later(1.2, func(): v._pico("Elle bouge, mais ne sonne pas. Trop de silence dans le village : il lui faut d'abord ses trois sons, comme un escalier sans marches du milieu."))
		return
	_lock = true
	_big_amp = 0.7
	Bells.play(v.world, "bell", 130.8, P + BIG_POS, 6.0)
	_later(1.6, _ring_all)
	_later(5.5, _finale)


func _ring_all() -> void:
	for n in deco.size():
		var d: Dictionary = deco[n]
		_later(0.12 * n, _ring_one.bind(n))
	_big_amp = 0.5


func _ring_one(n: int) -> void:
	var d: Dictionary = deco[n]
	d["amp"] = 0.6
	Bells.play(v.world, "bell", float(d["note"]) * (2.0 if n % 3 == 0 else 1.0), P + d["n"].position, -2.0)


func _finale() -> void:
	Save.story["k_done"] = true
	if not _s("k_paid"):
		Save.story["k_paid"] = true
		Save.shells += 30
	Save.save_game()
	_lock = false
	var p: Vector3 = v.player.global_position + Vector3(0, 2.7, 0)
	Fx.text(v.world, p, "BELLOCHE A RETROUVÉ SA MUSIQUE", Color(1.0, 0.95, 0.5), 1.0, 6.0)
	Fx.text(v.world, p - Vector3(0, 0.6, 0), "+30 coquillages", Color(1.0, 0.9, 0.5), 0.7, 4.0)
	for id in ["tam", "sifflot", "carillon"]:
		var sp: Dictionary = v._speaker(id)
		if not sp.is_empty():
			Fx.puff(v.world, sp["node"].global_position + Vector3(0, 1.6, 0), Color(1.0, 0.9, 0.5))
	Bells.play(v.world, "flute", Bells.SOL, P + Vector3(-11.0, 1.6, 10.0), 2.0)
	_later(1.0, func(): Bells.play(v.world, "flute", Bells.LA, P + Vector3(-11.0, 1.6, 10.0), 2.0))
	_later(2.0, func(): v._pico("Ils parlent. Ils sifflent. Sifflot me regarde comme si j'avais fait ça tout seul, et je n'ai fait que traduire. Il y a une porte au pied du clocher qui vibre. Elle a l'air de chanter faux, un peu."))


func _descend() -> void:
	Save.story["k_door_said"] = true
	Save.save_game()
	v.cat.enter()


# --- Événements des dialogues ----------------------------------------------------------------------

func event(ev: String, _node) -> void:
	match ev:
		"k_go":
			travel()
		"k_back":
			leave()


# --- Boucle -----------------------------------------------------------------------------------------

func update() -> void:
	if not active() or v.player == null:
		return
	_t += 0.016
	for d in deco:
		var a: float = d["amp"]
		if a > 0.003:
			d["n"].rotation.z = a * sin(_t * 7.0 + float(d["ph"]))
			d["amp"] = a * 0.985
		elif _s("k_done"):
			d["n"].rotation.z = 0.04 * sin(_t * 1.3 + float(d["ph"]))
	if _big_amp > 0.003:
		big.rotation.z = _big_amp * sin(_t * 3.0)
		_big_amp *= 0.99
