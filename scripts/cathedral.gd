extends Node3D
## La Cathédrale des Échos : le donjon du chapitre 4 (aucun ennemi), très haut dans le ciel (y = 1000).
## Sous le clocher de Belloche. Chaque salle redit un son entendu plus tôt, et il faut le rejouer :
##   1. la nef des cloches (la mélodie de Belloche)
##   2. la voûte aux oiseaux (le chant vient de trois perchoirs : on l'entend d'où il vient)
##   3. la galerie des tambours (le rythme, avec ses silences courts et longs)
##   4. le chœur (remettre les trois phrases dans l'ordre : on obtient la Grande Mélodie)
##   5. la porte muette (trop juste pour s'ouvrir ; seule une fausse note l'ouvre : celle de Pico)
## La progression est sauvegardée (Save.story["ca_room"]).

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Fx := preload("res://scripts/fx.gd")
const Save := preload("res://scripts/save.gd")
const Characters := preload("res://scripts/characters.gd")
const Talker := preload("res://scripts/talker.gd")
const ChoiceBtn := preload("res://scripts/choice_button.gd")
const Bells := preload("res://scripts/bells.gd")

const Y := 1000.0
const X0 := -36.0
const DX := 18.0
const WALLS := [Color(0.85, 0.74, 0.62), Color(0.78, 0.8, 0.7), Color(0.8, 0.68, 0.62), Color(0.72, 0.7, 0.82), Color(0.9, 0.84, 0.7)]
const NOTES := [Bells.DO, Bells.RE, Bells.MI, Bells.SOL, Bells.LA]
const NOTE_NAMES := ["rouge", "orange", "verte", "bleue", "violette"]
const NOTE_COLS := [Color(0.95, 0.35, 0.35), Color(1.0, 0.65, 0.25), Color(0.5, 0.85, 0.4), Color(0.4, 0.65, 1.0), Color(0.75, 0.5, 0.95)]
const MELODY := [0, 2, 3, 2, 0]
const BIRDS := [1, 0, 2, 1]
const PERCH := [Vector3(-4.5, 3.6, -4.2), Vector3(0.0, 3.6, -4.2), Vector3(4.5, 3.6, -4.2)]
const RHYTHM := [0.0, 0.45, 0.9, 2.0]
const ORDER := [1, 2, 0]
const ORDER_NAMES := ["cloches", "oiseaux", "tambours"]

var v
var player
var built := false
var active := false
var busy := false
var gates: Array = []
var ele
var last_room := -1
var said := {}
var _lock := false
var _in := {"bell": [], "bird": [], "order": []}
var _hit_t: Array = []
var door_l: Node3D
var door_r: Node3D
var page_node: MeshInstance3D


func setup(p_village, p_player) -> void:
	v = p_village
	player = p_player
	visible = false


func ro(i: int) -> Vector3:
	return Vector3(X0 + DX * i, Y, 0.0)


func cur() -> int:
	return clampi(int(floor((player.global_position.x - X0 + DX * 0.5) / DX)), 0, 4)


func solved() -> int:
	return int(Save.story.get("ca_room", 0))


func _s(k: String) -> bool:
	return Save.story.get(k, false)


func _later(t: float, c: Callable) -> void:
	v.get_tree().create_timer(t).timeout.connect(c)


func _say_ele(t: String) -> void:
	if ele:
		ele.chibi.say(t, 2.5 + t.length() * 0.055)


func _pico(t: String) -> void:
	v._pico(t)


func _hot(i: int, pos: Vector3, text: String, cb: Callable, cond: Callable, width := 1.7) -> ChoiceBtn:
	v.x.hotspot(get_child(i), pos, text, cb, func(): return active and not busy and cur() == i and cond.call(), width, 3.8)
	return v.x.hot.back()["btn"]


func _seq(lines: Array, done: Callable) -> void:
	busy = true
	var t := 0.6
	for l in lines:
		_later(t, _line.bind(l[0], l[1]))
		t += 2.5 + String(l[1]).length() * 0.055 + 0.7
	_later(t, _seq_end.bind(done))


func _line(who: String, text: String) -> void:
	if who == "e":
		_say_ele(text)
	else:
		_pico(text)


func _seq_end(done: Callable) -> void:
	busy = false
	if done.is_valid():
		done.call()


func _unlock() -> void:
	_lock = false


# --- Sons -----------------------------------------------------------------------------------------

## Une note avec son écho (la cathédrale répond, un peu plus bas et un peu plus tard).
func _bell(i: int, with_echo := true) -> void:
	var p: Vector3 = ro(cur()) + Vector3(-4.0 + i * 2.0, 1.4, -3.5)
	Bells.play(v.world, "bell", NOTES[i], p, 0.0)
	if with_echo:
		_later(0.4, Bells.play.bind(v.world, "bell", NOTES[i], p + Vector3(0, 2.0, 0), -9.0))


func _chirp(k: int, with_echo := true) -> void:
	var p: Vector3 = ro(1) + PERCH[k]
	Bells.play(v.world, "bird", 0.0, p, 3.0)
	if with_echo:
		_later(0.5, Bells.play.bind(v.world, "bird", 0.0, p + Vector3(0, 1.0, 0), -8.0))


func _drum(with_echo := true) -> void:
	var p: Vector3 = ro(2) + Vector3(0, 1.0, -2.0)
	Bells.play(v.world, "stone", 0.0, p, 3.0)
	if with_echo:
		_later(0.35, Bells.play.bind(v.world, "stone", 0.0, p + Vector3(0, 1.5, 0), -9.0))


func _play_melody(step := 0.7) -> float:
	for n in MELODY.size():
		_later(0.3 + n * step, _bell.bind(MELODY[n]))
	return 0.6 + MELODY.size() * step


func _play_birds(step := 0.8) -> float:
	for n in BIRDS.size():
		_later(0.3 + n * step, _chirp.bind(BIRDS[n]))
	return 0.6 + BIRDS.size() * step


func _play_rhythm() -> float:
	for t in RHYTHM:
		_later(0.4 + t, _drum)
	return 1.0 + float(RHYTHM[RHYTHM.size() - 1])


func _lock_for(d: float) -> void:
	_lock = true
	_later(d, _unlock)


func _step(key: String, i: int, seq: Array) -> bool:
	var cur_in: Array = _in[key]
	cur_in.append(i)
	for n in cur_in.size():
		if cur_in[n] != seq[n]:
			_in[key] = []
			_msg(cur(), "Pas tout à fait... l'écho se tait, on reprend")
			return false
	if cur_in.size() == seq.size():
		_in[key] = []
		return true
	return false


func _msg(room: int, text: String) -> void:
	Fx.text(v.world, ro(room) + Vector3(0, 3.8, -3.0), text, Color(1.0, 0.88, 0.7), 0.55, 2.8)


# --- Construction ------------------------------------------------------------------------------

func _build_scene() -> void:
	built = true
	for i in 5:
		var r := Node3D.new()
		r.name = "Salle%d" % (i + 1)
		add_child(r)
		r.position = ro(i)
		_shell(r, i)
	_corridors()
	_r1(get_child(0))
	_r2(get_child(1))
	_r3(get_child(2))
	_r4(get_child(3))
	_r5(get_child(4))
	ele = Talker.new()
	ele.name = "EleonoreCathedrale"
	add_child(ele)
	ele.setup(v, player, Characters.ELEONORE)
	ele.rest_yaw = -PI * 0.5


func _shell(r: Node3D, i: int) -> void:
	var b := Builder.new()
	var wc: Color = WALLS[i]
	var h := 6.0
	b.box(Vector3(15, 0.4, 10), Vector3(0, -0.2, 0), Color(0.55, 0.5, 0.45), true)
	b.box(Vector3(15, 0.2, 10), Vector3(0, h + 0.1, 0), wc.darkened(0.3), true)
	b.box(Vector3(15, h, 0.3), Vector3(0, h * 0.5, 5.0), wc, true)
	if i == 4:
		b.box(Vector3(6.0, h, 0.3), Vector3(-4.5, h * 0.5, -5.0), wc, true)
		b.box(Vector3(6.0, h, 0.3), Vector3(4.5, h * 0.5, -5.0), wc, true)
		b.box(Vector3(3.0, 2.0, 0.3), Vector3(0, 5.0, -5.0), wc, true)
		# La niche derrière la porte
		b.box(Vector3(3.2, 0.4, 4.2), Vector3(0, -0.2, -7.1), Color(0.75, 0.65, 0.4), true)
		b.box(Vector3(3.2, 0.2, 4.2), Vector3(0, h + 0.1, -7.1), wc.darkened(0.3), true)
		for sx in [-1.0, 1.0]:
			b.box(Vector3(0.2, h, 4.2), Vector3(sx * 1.6, h * 0.5, -7.1), wc, true)
		b.box(Vector3(3.2, h, 0.2), Vector3(0, h * 0.5, -9.2), wc, true)
		b.box(Vector3(1.0, 1.0, 0.8), Vector3(0, 0.5, -8.2), Color(0.5, 0.4, 0.3), true)
	else:
		b.box(Vector3(15, h, 0.3), Vector3(0, h * 0.5, -5.0), wc, true)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(0.3, h, 4.0), Vector3(sx * 7.35, h * 0.5, -3.0), wc, true)
		b.box(Vector3(0.3, h, 4.0), Vector3(sx * 7.35, h * 0.5, 3.0), wc, true)
		b.box(Vector3(0.3, h - 2.6, 2.0), Vector3(sx * 7.35, 2.6 + (h - 2.6) * 0.5, 0), wc, true)
	# Piliers et vitraux sur le mur sud
	for k in 5:
		var x := -6.0 + k * 3.0
		b.box(Vector3(0.5, h, 0.5), Vector3(x, h * 0.5, 4.6), wc.darkened(0.15), false)
	var rng := RandomNumberGenerator.new()
	rng.seed = 300 + i
	for k in 4:
		var x2 := -4.5 + k * 3.0
		b.box(Vector3(1.2, 2.6, 0.08), Vector3(x2, 3.4, 4.82), Color.from_hsv(rng.randf(), 0.5, 0.95), false)
	b.build(r, Toon.vertex_color(0.01), "Shell")
	var lt := OmniLight3D.new()
	lt.omni_range = 14.0
	lt.light_energy = 1.2
	lt.light_color = Color(1.0, 0.93, 0.8)
	r.add_child(lt)
	lt.position = Vector3(0, 5.0, 0)
	var g := Node3D.new()
	g.name = "Gate"
	r.add_child(g)
	var gb := Builder.new()
	for k in 5:
		gb.box(Vector3(0.12, 2.6, 0.12), Vector3(7.3, 1.3, -0.8 + k * 0.4), Color(0.55, 0.4, 0.2), true)
	gb.box(Vector3(0.14, 0.14, 2.0), Vector3(7.3, 1.3, 0), Color(0.55, 0.4, 0.2), false)
	gb.build(g, Toon.vertex_color(0.01), "Bars")
	gates.append(g)
	_label(r, "SALLE %d" % (i + 1), Vector3(-7.1, 4.6, -1.8), PI * 0.5, 0.012, Color(0.3, 0.2, 0.1))


func _label(parent: Node3D, text: String, pos: Vector3, yaw := 0.0, px := 0.004, col := Color(0.25, 0.17, 0.1)) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = 48
	l.pixel_size = px
	l.outline_size = 0
	l.modulate = col
	l.rotation.y = yaw
	l.position = pos
	parent.add_child(l)
	return l


func _corridors() -> void:
	var b := Builder.new()
	for i in 4:
		var cx: float = X0 + DX * i + DX * 0.5
		b.box(Vector3(3.0, 0.4, 2.0), Vector3(cx, Y - 0.2, 0), Color(0.5, 0.45, 0.4), true)
		b.box(Vector3(3.0, 0.2, 2.0), Vector3(cx, Y + 3.0, 0), Color(0.5, 0.45, 0.4), true)
		for sz in [-1.0, 1.0]:
			b.box(Vector3(3.0, 3.0, 0.2), Vector3(cx, Y + 1.5, sz * 1.0), Color(0.82, 0.76, 0.66), true)
	b.build(self, Toon.vertex_color(0.01), "Corridors")


func _open_gate(i: int) -> void:
	if i >= gates.size():
		return
	var g: Node3D = gates[i]
	if g and is_instance_valid(g):
		Fx.puff(v.world, g.global_position + Vector3(0, 1.2, 0), Color(1.0, 0.9, 0.6))
		g.queue_free()
	gates[i] = null


func _solve(i: int) -> void:
	_open_gate(i)
	Save.story["ca_room"] = maxi(solved(), i + 1)
	Save.save_game()
	Fx.text(v.world, ro(i) + Vector3(6.0, 2.5, 0), "PORTE OUVERTE", Color(0.7, 1.0, 0.75), 1.0, 2.5)


func _exit_hot(i: int) -> void:
	_hot(i, Vector3(-6.0, 1.2, -3.0), "Remonter au clocher", func(): exit(), func(): return true, 1.8)


# --- Salle 1 : la nef des cloches ------------------------------------------------------------------

func _r1(r: Node3D) -> void:
	var b := Builder.new()
	b.box(Vector3(11.0, 0.15, 0.4), Vector3(0, 0.9, -3.5), Color(0.6, 0.42, 0.3), false)
	b.build(r, Toon.vertex_color(0.01), "Support")
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.08
	mesh.bottom_radius = 0.38
	mesh.height = 0.6
	mesh.radial_segments = 10
	for i in 5:
		var m := MeshInstance3D.new()
		m.mesh = mesh
		m.material_override = Toon.flat(NOTE_COLS[i])
		r.add_child(m)
		m.position = Vector3(-4.0 + i * 2.0, 1.3, -3.5)
		_hot(0, Vector3(-4.0 + i * 2.0, 2.1, -3.5), "Cloche " + NOTE_NAMES[i], _hit_bell.bind(i), func(): return not _lock, 1.3)
	_hot(0, Vector3(0, 3.4, -3.5), "Écouter l'écho", _echo_melody, func(): return not _lock, 1.4)
	_label(r, "NEF DES CLOCHES\nElle redit ce que la ville a chanté.", Vector3(0, 5.0, -4.68), 0.0, 0.0055)
	_label(r, "(rejouez-lui son air, elle vous ouvrira)", Vector3(0, 4.3, -4.68), 0.0, 0.003)
	_exit_hot(0)


func _echo_melody() -> void:
	_in["bell"] = []
	_lock_for(_play_melody())


func _hit_bell(i: int) -> void:
	_bell(i)
	if solved() >= 1:
		return
	if _step("bell", i, MELODY):
		_later(1.0, _r1_done)


func _r1_done() -> void:
	_say_ele("L'air de Belloche. Elle me l'a rendu avec un petit retard, comme tout ce qui est ancien.")
	_solve(0)


# --- Salle 2 : la voûte aux oiseaux ------------------------------------------------------------------

func _r2(r: Node3D) -> void:
	var b := Builder.new()
	for k in 3:
		var p: Vector3 = PERCH[k]
		b.box(Vector3(1.6, 0.12, 0.7), p + Vector3(0, -0.25, 0.2), Color(0.6, 0.42, 0.3), false)
		b.sphere(0.14, p + Vector3(0, 0.0, 0.1), Color(1.0, 0.85, 0.2), Vector3(1.0, 0.9, 1.3), Basis(), 6)
	b.build(r, Toon.vertex_color(0.01), "Perchoirs")
	var names := ["gauche", "au centre", "droite"]
	for k in 3:
		_hot(1, Vector3(PERCH[k].x, 2.2, -3.6), "Perchoir " + names[k], _hit_perch.bind(k), func(): return not _lock, 1.5)
	_hot(1, Vector3(0, 1.3, -3.6), "Écouter la voûte", _echo_birds, func(): return not _lock, 1.5)
	_label(r, "VOÛTE AUX OISEAUX\nCe qui chante sort toujours de quelque part.", Vector3(0, 5.2, -4.68), 0.0, 0.0055)
	_label(r, "(trois perchoirs : écoutez d'où vient chaque trille)", Vector3(0, 4.5, -4.68), 0.0, 0.003)
	_exit_hot(1)


func _echo_birds() -> void:
	_in["bird"] = []
	_lock_for(_play_birds())


func _hit_perch(k: int) -> void:
	_chirp(k)
	if solved() >= 2:
		return
	if _step("bird", k, BIRDS):
		_later(1.0, _r2_done)


func _r2_done() -> void:
	_say_ele("Gauche, centre, droite, centre... non, centre, gauche, droite, centre. Un oiseau très poli, qui change de branche à chaque trille.")
	_solve(1)


# --- Salle 3 : la galerie des tambours -----------------------------------------------------------------

func _r3(r: Node3D) -> void:
	var b := Builder.new()
	b.cylinder(0.7, 0.62, 1.0, Vector3(0, 0.5, -2.0), Color(0.62, 0.58, 0.55), Basis(), 14)
	b.cylinder(0.72, 0.72, 0.07, Vector3(0, 1.03, -2.0), Color(0.78, 0.74, 0.68), Basis(), 14)
	b.build(r, Toon.vertex_color(0.01), "Tambour")
	_hot(2, Vector3(0, 1.9, -2.0), "Frapper le grand tambour", _hit_drum, func(): return not _lock, 2.0)
	_hot(2, Vector3(-3.0, 1.5, -2.0), "Écouter la galerie", _echo_rhythm, func(): return not _lock, 1.6)
	_label(r, "GALERIE DES TAMBOURS\nUn rythme, ce sont des coups et des silences.", Vector3(0, 5.0, -4.68), 0.0, 0.0055)
	_label(r, "(deux coups pressés, un coup qui se fait attendre)", Vector3(0, 4.3, -4.68), 0.0, 0.003)
	_exit_hot(2)


func _echo_rhythm() -> void:
	_hit_t = []
	_lock_for(_play_rhythm())


func _now() -> float:
	return float(Time.get_ticks_msec()) / 1000.0


func _hit_drum() -> void:
	_drum()
	if solved() >= 3:
		return
	if _hit_t.size() > 0 and _now() - float(_hit_t[_hit_t.size() - 1]) > 3.5:
		_hit_t = []
	_hit_t.append(_now())
	if _hit_t.size() < 4:
		return
	var g0: float = _hit_t[1] - _hit_t[0]
	var g1: float = _hit_t[2] - _hit_t[1]
	var g2: float = _hit_t[3] - _hit_t[2]
	_hit_t = []
	if maxf(g0, g1) < 0.95 and g2 > 0.9 and g2 > maxf(g0, g1) * 1.5:
		_later(1.2, _r3_done)
	else:
		_msg(2, "L'écho hésite : deux coups pressés, puis un long silence")


func _r3_done() -> void:
	_say_ele("Deux coups, un silence. Tam serait fier : le silence, c'est ce qui rend le bruit lisible.")
	_solve(2)


# --- Salle 4 : le chœur ------------------------------------------------------------------------------

func _r4(r: Node3D) -> void:
	var b := Builder.new()
	var cols := [Color(0.95, 0.75, 0.3), Color(0.5, 0.85, 0.5), Color(0.75, 0.6, 0.55)]
	for k in 3:
		b.cylinder(0.5, 0.6, 0.9, Vector3(-3.5 + k * 3.5, 0.45, -2.5), cols[k], Basis(), 10)
		b.sphere(0.3, Vector3(-3.5 + k * 3.5, 1.2, -2.5), cols[k].lightened(0.2), Vector3.ONE, Basis(), 8)
	b.build(r, Toon.vertex_color(0.01), "Socles")
	for k in 3:
		_hot(3, Vector3(-3.5 + k * 3.5, 2.0, -2.5), "Phrase des " + ORDER_NAMES[k], _phrase.bind(k), func(): return not _lock, 1.9)
	_label(r, "CHŒUR DES ÉCHOS", Vector3(0, 5.3, -4.68), 0.0, 0.0065)
	_label(r, "« Au matin, un chant léger.\nÀ midi, des pas lourds.\nAu soir, la cloche qui rassemble. »", Vector3(0, 3.8, -4.68), 0.0, 0.0048)
	_exit_hot(3)


func _phrase(k: int) -> void:
	var d := 1.0
	match k:
		0:
			d = _play_melody(0.5)
		1:
			d = _play_birds(0.6)
		_:
			d = _play_rhythm()
	_lock_for(d)
	if solved() >= 4:
		return
	var arr: Array = _in["order"]
	arr.append(k)
	for n in arr.size():
		if arr[n] != ORDER[n]:
			_in["order"] = []
			_later(d + 0.2, _msg.bind(3, "Ce n'est pas l'ordre du jour : on reprend"))
			return
	if arr.size() == ORDER.size():
		_in["order"] = []
		_later(d + 0.6, _grand_melody)


func _grand_melody() -> void:
	_lock = true
	_lock_for(5.0)
	Fx.text(v.world, ro(3) + Vector3(0, 3.8, -2.5), "LA GRANDE MÉLODIE", Color(1.0, 0.95, 0.5), 1.2, 5.0)
	_play_birds(0.7)
	_later(2.4, _play_rhythm)
	_later(3.0, _play_melody.bind(0.6))
	_later(6.8, _r4_done)


func _r4_done() -> void:
	_say_ele("Un oiseau, des pas, une cloche. Mis bout à bout, on dirait une phrase. On dirait même qu'elle a un destinataire.")
	_solve(3)


# --- Salle 5 : la porte muette ----------------------------------------------------------------------

func _r5(r: Node3D) -> void:
	door_l = Node3D.new()
	door_r = Node3D.new()
	r.add_child(door_l)
	r.add_child(door_r)
	door_l.position = Vector3(-0.75, 0, -4.7)
	door_r.position = Vector3(0.75, 0, -4.7)
	for d in [door_l, door_r]:
		var b := Builder.new()
		b.box(Vector3(1.5, 4.0, 0.2), Vector3(0, 2.0, 0), Color(0.45, 0.35, 0.28), true)
		for k in 4:
			b.box(Vector3(1.3, 0.1, 0.24), Vector3(0, 0.7 + k * 0.9, 0), Color(0.85, 0.7, 0.3), false)
		b.build(d, Toon.vertex_color(0.01), "Vantail")
	_label(r, "LA PORTE DU REGISTRE", Vector3(0, 5.2, -4.68), 0.0, 0.0065)
	_label(r, "Fermée depuis 312 ans, à la demande générale.\n« Ouvre seulement à la mélodie parfaite. »", Vector3(0, 4.35, -4.68), 0.0, 0.0038)
	page_node = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.5, 0.04, 0.38)
	page_node.mesh = bm
	page_node.material_override = Toon.unlit(Color(1.0, 0.95, 0.7))
	r.add_child(page_node)
	page_node.position = Vector3(0, 1.1, -8.2)
	page_node.visible = false
	_hot(4, Vector3(0, 1.8, -3.6), "Jouer la Grande Mélodie", _play_grand, func(): return not _lock and not _s("ca_open"), 2.1)
	_hot(4, Vector3(-2.2, 1.4, -3.6), "Laisser Pico chanter", _pico_sings, func(): return not _lock and _s("ca_tried") and not _s("ca_open"), 2.0)
	_hot(4, Vector3(0, 1.8, -7.2), "Prendre la page", _take_page, func(): return _s("ca_open") and not _s("page2"), 1.6)
	_exit_hot(4)


func _play_grand() -> void:
	_lock = true
	_play_birds(0.5)
	_later(1.8, _play_rhythm)
	_later(2.2, _play_melody.bind(0.5))
	_later(5.8, _grand_after)


func _grand_after() -> void:
	_lock = false
	if _s("ca_open"):
		return
	Fx.text(v.world, ro(4) + Vector3(0, 3.0, -4.3), "La porte frémit... et reste fermée.", Color(1.0, 0.9, 0.75), 0.7, 5.0)
	if not _s("ca_tried"):
		Save.story["ca_tried"] = true
		Save.save_game()
		_seq([
			["e", "Parfait. Chaque note à sa place. C'est exactement ce qu'elle déteste : elle a été fermée par des gens qui aimaient la perfection."],
			["p", "Une porte qui n'ouvre que pour du faux ? ...Je vois où ça va. Et ça ne me plaît pas du tout."],
		], _noop)


func _noop() -> void:
	pass


func _pico_sings() -> void:
	_lock = true
	_pico("Bon. On ne rigole pas. Si je rate, c'est volontaire. La, la... laaaa...")
	var fr := [Bells.DO, Bells.MI * 1.07, Bells.SOL * 0.92, Bells.DO * 2.0 * 1.05, Bells.RE * 0.88]
	for n in fr.size():
		_later(1.8 + n * 0.6, Bells.play.bind(v.world, "flute", fr[n], ro(4) + Vector3(0, 2.0, -2.0), 3.0))
	_later(1.8, Fx.text.bind(v.world, ro(4) + Vector3(-1.0, 3.2, -2.5), "♪ la...", Color(1.0, 0.9, 0.7), 0.8, 2.0))
	_later(2.7, Fx.text.bind(v.world, ro(4) + Vector3(0.0, 3.4, -2.5), "♪ la...♭ ?", Color(1.0, 0.8, 0.6), 0.8, 2.0))
	_later(3.6, Fx.text.bind(v.world, ro(4) + Vector3(1.0, 3.2, -2.5), "♪ LAAAA~", Color(1.0, 0.7, 0.6), 1.0, 2.5))
	_later(5.4, _door_open)


func _door_open() -> void:
	Save.story["ca_open"] = true
	Save.save_game()
	Fx.puff(v.world, ro(4) + Vector3(0, 2.0, -4.5), Color(1.0, 0.9, 0.5))
	var tw := create_tween().set_parallel(true)
	tw.tween_property(door_l, "position:x", -3.2, 2.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(door_r, "position:x", 3.2, 2.5).set_trans(Tween.TRANS_SINE)
	Bells.play(v.world, "stone", 0.0, ro(4) + Vector3(0, 1.0, -4.7), 6.0)
	_later(2.0, _unlock)
	_later(2.6, _reveal)


func _reveal() -> void:
	page_node.visible = true
	_seq([
		["e", "Elle s'est ouverte. Pour une fausse note. Toute une cathédrale pour une porte qui attendait une erreur."],
		["p", "Je n'ai chanté faux que pour rire. Je n'ai pas... Éléonore, il y a un nom gravé sur le pupitre."],
		["e", "« VOIX DE SECOURS DU GRAND REGISTRE : PICO. À ne jamais laisser chanter sans surveillance. »"],
		["p", "...Je ne dis jamais rien. C'est ce qu'on me reprochait. Le dire, ce n'était pas à moi, c'était à vous. Je suis rangé dans le Registre, Éléonore. Je suis dans la liste."],
		["e", "Alors ton nom est dans la même écriture que celle de mon père. On n'est pas arrivés ici par hasard. Prends la page, Pico. Elle est à toi, plus qu'à nous."],
	], _noop)


func _take_page() -> void:
	Save.story["page2"] = true
	Save.story["ch4_done"] = true
	Save.shells += 50
	Save.save_game()
	page_node.visible = false
	Fx.puff(v.world, ro(4) + Vector3(0, 1.4, -7.2), Color(1.0, 0.95, 0.6))
	Fx.text(v.world, ro(4) + Vector3(0, 3.6, -3.0), "CHAPITRE 4 TERMINÉ", Color(1.0, 0.95, 0.5), 1.6, 6.0)
	Fx.text(v.world, ro(4) + Vector3(0, 2.8, -3.0), "DEUXIÈME PAGE  ·  +50 coquillages", Color(1.0, 0.9, 0.5), 0.8, 5.0)
	_later(4.5, func(): Fx.text(v.world, ro(4) + Vector3(0, 3.2, -3.0), "À suivre : les Hautes-Miettes, et l'Observatoire Brisé...", Color(0.9, 0.95, 1.0), 0.7, 6.0))


# --- Entrée et sortie --------------------------------------------------------------------------------

func enter() -> void:
	if busy:
		return
	busy = true
	var tw: Tween = v.maquette._fade_to(0.0, 1.0, 1.0)
	tw.tween_callback(_enter_now)


func _enter_now() -> void:
	if not built:
		_build_scene()
	visible = true
	active = true
	for i in 5:
		if i < solved():
			_open_gate(i)
	if _s("ca_open"):
		door_l.position.x = -3.2
		door_r.position.x = 3.2
		page_node.visible = not _s("page2")
	var s := mini(solved(), 4)
	player.global_position = ro(s) + Vector3(-6.0, 0.15, 0)
	player._vy = 0.0
	player._face_yaw(-PI * 0.5)
	player._place_origin(true, 0.0)
	last_room = -1
	var tw: Tween = v.maquette._fade_to(1.0, 0.0, 1.2)
	tw.tween_callback(_unbusy)
	Fx.text(v.world, ro(s) + Vector3(-3.0, 3.0, 0), "LA CATHÉDRALE DES ÉCHOS", Color(1.0, 0.9, 0.6), 1.2, 3.5)


func _unbusy() -> void:
	busy = false


func exit() -> void:
	if busy:
		return
	busy = true
	var tw: Tween = v.maquette._fade_to(0.0, 1.0, 1.0)
	tw.tween_callback(_exit_now)


func _exit_now() -> void:
	active = false
	visible = false
	player.global_position = Vector3(0.0, 900.1, -2.6)
	player._vy = 0.0
	player._face_yaw(PI)
	player._place_origin(true, 0.0)
	var tw2: Tween = v.maquette._fade_to(1.0, 0.0, 1.2)
	tw2.tween_callback(_unbusy)


# --- Boucle --------------------------------------------------------------------------------------------

func _on_room(i: int) -> void:
	if said.has(i):
		return
	said[i] = true
	var lines := [
		"La cathédrale sous le clocher. Les murs gardent tout ce qu'on dit, puis le redisent plus tard, en mieux ou en pire.",
		"Des perchoirs. Un oiseau très poli qui chante d'un seul endroit à la fois. Je préfère les oiseaux impolis, ils se trompent d'arbre.",
		"Un grand tambour. Pas un coup de plus que nécessaire : il paraît que les silences coûtent cher, ici.",
		"Trois socles : un chant, des pas, une cloche. Ça ressemble à une journée. Ou à un testament sonore.",
		"Une porte sans poignée, sans serrure. Elle est fermée depuis plus longtemps que notre île a un nom.",
	]
	_later(1.2, func(): _say_ele(lines[i]))
	if ele:
		ele.global_position = ro(i) + Vector3(-4.8, 0.05, 2.5)
		ele.chibi.rotation.y = 0.0


func _physics_process(_delta: float) -> void:
	if not active or busy or player == null:
		return
	var pp: Vector3 = player.global_position
	if pp.y < Y - 6.0:
		player.global_position = ro(clampi(solved(), 0, 4)) + Vector3(-6.0, 0.2, 0)
		return
	var c := cur()
	if c != last_room:
		last_room = c
		_on_room(c)
