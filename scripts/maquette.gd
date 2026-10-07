extends Node3D
## Les Mains du Dehors : le souvenir de l'horloge. Une plate-forme sous un ciel
## étoilé, la maquette de Port-Biscornu et quatre orbes (aube, midi, crépuscule,
## nuit) à replacer dans l'ordre du temps, de gauche à droite.
## Le soleil (ou la lune) de chaque orbe donne l'heure. Un mauvais ordre
## renvoie les orbes en l'air ; réussir rend le mardi au village.

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Fx := preload("res://scripts/fx.gd")
const Save := preload("res://scripts/save.gd")
const Props := preload("res://scripts/props.gd")

const P := Vector3(0.0, 90.0, 0.0)
const SLOT_Z := -1.6
const SLOT_X := [-1.2, -0.4, 0.4, 1.2]

var v
var player
var built := false
var active := false
var orbs: Array = []
var slot_of: Dictionary = {}
var _fade: MeshInstance3D
var _mat: StandardMaterial3D
var _ret := Vector3.ZERO
var _done: Callable
var _busy := false


func setup(p_village, p_player) -> void:
	v = p_village
	player = p_player


func _build_scene() -> void:
	built = true
	visible = false
	var b := Builder.new()
	b.box(Vector3(16, 0.5, 16), P + Vector3(0, -0.25, 0), Color(0.25, 0.22, 0.35), true)
	# Table des souvenirs
	b.box(Vector3(3.8, 0.1, 1.9), P + Vector3(0, 0.9, -1.1), Color(0.5, 0.36, 0.28), true)
	for sx in [-1.7, 1.7]:
		for sz in [-0.3, -1.9]:
			b.box(Vector3(0.12, 0.9, 0.12), P + Vector3(sx, 0.45, sz), Color(0.35, 0.25, 0.2), false)
	for i in 4:
		b.cylinder(0.26, 0.26, 0.03, P + Vector3(SLOT_X[i], 0.97, SLOT_Z), Color(1.0, 0.9, 0.5).darkened(0.1 * i), Basis(), 14)
	# La maquette de Port-Biscornu (échelle 1/5) derrière la table
	var base := P + Vector3(0, 0.0, -7.0)
	b.box(Vector3(10.0, 0.5, 6.0), base + Vector3(0, 0.25, 0), Color(0.45, 0.7, 0.45), true)
	var bl := [
		[Vector2(-15.0, -50.0), 9.0, 10.0, 3.4, Color(0.95, 0.8, 0.55)],
		[Vector2(0.0, -58.0), 13.0, 8.0, 4.3, Color(0.97, 0.93, 0.82)],
		[Vector2(13.5, -48.5), 5.5, 6.0, 3.0, Color(0.62, 0.88, 0.76)],
		[Vector2(-9.0, -44.0), 5.0, 5.0, 3.2, Color(1.0, 0.82, 0.58)],
		[Vector2(9.0, -44.0), 5.0, 5.0, 3.2, Color(0.55, 0.75, 1.0)],
		[Vector2(-18.5, -58.5), 4.6, 5.0, 3.0, Color(1.0, 0.72, 0.8)],
		[Vector2(18.5, -58.5), 4.6, 5.0, 3.0, Color(0.66, 0.63, 0.62)],
		[Vector2(10.5, -60.0), 5.0, 4.0, 3.0, Color(0.78, 0.65, 0.48)],
	]
	for h in bl:
		var q: Vector2 = h[0]
		var o := Vector3(q.x * 0.2, 0.5, (q.y + 52.0) * 0.2)
		b.box(Vector3(float(h[1]) * 0.2, float(h[3]) * 0.2, float(h[2]) * 0.2), base + o + Vector3(0, float(h[3]) * 0.1, 0), h[4], false)
		b.prism(Vector3(float(h[1]) * 0.22, 0.4, float(h[2]) * 0.22), base + o + Vector3(0, float(h[3]) * 0.2 + 0.2, 0), Color(0.75, 0.35, 0.3), Basis())
	b.cylinder(0.4, 0.5, 3.0, base + Vector3(5.0 - 0.5, 2.0, 1.0), Color(0.95, 0.3, 0.3), Basis(), 10)
	b.build(self, Toon.vertex_color(0.01), "Mesh")
	# Dôme étoilé
	var dome := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 45.0
	sm.height = 90.0
	sm.radial_segments = 24
	sm.rings = 12
	dome.mesh = sm
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(0.04, 0.04, 0.16)
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.cull_mode = BaseMaterial3D.CULL_FRONT
	dome.material_override = dm
	add_child(dome)
	dome.global_position = P + Vector3(0, 5.0, 0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var stars := Builder.new()
	for i in 90:
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.05, 1), rng.randf_range(-1, 1)).normalized() * 40.0
		stars.sphere(0.25, P + Vector3(0, 5.0, 0) + d, Color(1.0, 0.97, 0.7), Vector3.ONE, Basis(), 4)
	stars.build(self, Toon.vertex_color(0.0), "Stars")
	var lt := OmniLight3D.new()
	lt.omni_range = 14.0
	lt.light_energy = 1.4
	add_child(lt)
	lt.global_position = P + Vector3(0, 4.0, 1.0)
	_label("LES MAINS DU DEHORS\nRemets les souvenirs dans l'ordre du temps  →", P + Vector3(0, 2.2, -2.2))


func _label(text: String, pos: Vector3) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = 48
	l.pixel_size = 0.004
	l.outline_size = 10
	l.outline_modulate = Color(0.13, 0.08, 0.17)
	l.modulate = Color(0.9, 0.85, 1.0)
	add_child(l)
	l.global_position = pos


func _fade_node() -> void:
	if _fade and is_instance_valid(_fade):
		return
	_fade = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.4
	sm.height = 0.8
	sm.radial_segments = 16
	sm.rings = 8
	_fade.mesh = sm
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0, 0, 0, 0)
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat.no_depth_test = true
	_mat.render_priority = 100
	_fade.material_override = _mat
	player.camera.add_child(_fade)


func _fade_to(a0: float, a1: float, t: float) -> Tween:
	_fade_node()
	var tw := create_tween()
	tw.tween_method(func(a: float): _mat.albedo_color = Color(0, 0, 0, a), a0, a1, t)
	return tw


func start(cb: Callable) -> void:
	if _busy:
		return
	_busy = true
	_done = cb
	if not built:
		_build_scene()
	_ret = v.nodes["mairie"].to_global(Vector3(0, 0.4, 1.8))
	v._pico("Attends, le cadran s'ouvre... Je n'aime pas quand les horloges ouvrent des choses.")
	var tw := _fade_to(0.0, 1.0, 1.2)
	tw.tween_callback(_enter)


func _enter() -> void:
	player.global_position = P + Vector3(0, 0.1, 3.0)
	player._vy = 0.0
	player._face_yaw(0.0)
	player._place_origin(true, 0.0)
	visible = true
	_spawn_orbs()
	active = true
	var tw := _fade_to(1.0, 0.0, 1.5)
	tw.tween_callback(func():
		Fx.text(v.world, P + Vector3(0, 2.0, 0.5), "UNE JOURNÉE EN QUATRE SOUVENIRS", Color(0.9, 0.85, 1.0), 1.0, 4.0)
		v._pico("Quatre boules avec un petit monde dedans. Un soleil, une lune... Le temps passe de gauche à droite, non ?"))


func _spawn_orbs() -> void:
	_clear_orbs()
	var order := [1, 2, 3, 4]
	var tries := 0
	while tries < 20:
		order.shuffle()
		tries += 1
		if order != [1, 2, 3, 4]:
			break
	for i in 4:
		var rb := Props.make(v.world, "orbe_%d" % order[i], P + Vector3(SLOT_X[i], 1.1, -0.55))
		orbs.append(rb)


func _clear_orbs() -> void:
	for rb in orbs:
		if is_instance_valid(rb):
			player.release_item(rb)
			rb.queue_free()
	orbs.clear()
	slot_of.clear()


func _held(rb) -> bool:
	return rb.has_meta("held_by") or player._held_desktop == rb


func _physics_process(delta: float) -> void:
	if not active or _busy_end:
		return
	if _cool > 0.0:
		_cool -= delta
		return
	for rb in orbs:
		if not is_instance_valid(rb):
			continue
		if rb.global_position.y < P.y - 2.0:
			rb.global_position = P + Vector3(0, 1.3, -0.55)
			rb.linear_velocity = Vector3.ZERO
		if _held(rb):
			slot_of.erase(rb)
			continue
		if slot_of.has(rb):
			continue
		for i in 4:
			var sp: Vector3 = P + Vector3(SLOT_X[i], 1.13, SLOT_Z)
			if rb.global_position.distance_to(sp) < 0.4 and not slot_of.values().has(i):
				slot_of[rb] = i
				rb.freeze = true
				rb.linear_velocity = Vector3.ZERO
				rb.global_position = sp
				Fx.text(v.world, sp + Vector3(0, 0.3, 0), "clac", Color(1.0, 0.9, 0.5), 0.5, 0.6)
				break
	if slot_of.size() == 4:
		_evaluate()


var _busy_end := false
var _cool := 0.0


func _evaluate() -> void:
	var ok := true
	for rb in slot_of:
		var want: int = int(slot_of[rb]) + 1
		if str(rb.get("kind")) != "orbe_%d" % want:
			ok = false
	if ok:
		_busy_end = true
		for rb in orbs:
			Fx.puff(v.world, rb.global_position, Color(1.0, 0.95, 0.6))
		Fx.text(v.world, P + Vector3(0, 2.0, -1.0), "L'AUBE, MIDI, LE CRÉPUSCULE, LA NUIT.\nLE MARDI EXISTAIT.", Color(1.0, 0.95, 0.6), 1.2, 4.0)
		v._pico("Aube, midi, crépuscule, nuit... Un vrai mardi. Complet. Avec un début et une fin !")
		get_tree().create_timer(4.0).timeout.connect(_leave)
	else:
		var fails: int = int(Save.story.get("fails", 0)) + 1
		Save.story["fails"] = fails
		Save.save_game()
		Fx.text(v.world, P + Vector3(0, 2.0, -1.0), "Les souvenirs se dispersent !", Color(1.0, 0.6, 0.5), 1.0, 2.5)
		var xs := [0, 1, 2, 3]
		xs.shuffle()
		for i in orbs.size():
			var rb = orbs[i]
			if is_instance_valid(rb):
				Fx.puff(v.world, rb.global_position, Color(0.8, 0.8, 1.0))
				rb.freeze = false
				rb.linear_velocity = Vector3.ZERO
				rb.global_position = P + Vector3(SLOT_X[xs[i]], 1.3, -0.55)
		slot_of.clear()
		_cool = 1.5
		if fails >= 2:
			v._pico("Un indice : regarde où est le soleil. Bas à gauche, haut au milieu, bas à droite... et la lune pour finir.")
		else:
			v._pico("Pas dans cet ordre. Regarde le ciel de chaque petit monde.")


func _leave() -> void:
	var tw := _fade_to(0.0, 1.0, 1.2)
	tw.tween_callback(_return)


func _return() -> void:
	active = false
	visible = false
	_clear_orbs()
	player.global_position = _ret
	player._vy = 0.0
	player._face_yaw(0.0)
	player._place_origin(true, 0.0)
	Save.story["mardi"] = true
	Save.save_game()
	var tw := _fade_to(1.0, 0.0, 1.5)
	tw.tween_callback(func():
		_busy = false
		_busy_end = false
		Fx.text(v.world, player._front(2.0) + Vector3(0, 1.0, 0), "L'HORLOGE REPART", Color(1.0, 0.95, 0.6), 1.2, 3.5)
		v._pico("Elle tourne ! Le mardi est revenu. Tout le monde va se souvenir de quelque chose. Probablement de travers.")
		if _done.is_valid():
			_done.call())
