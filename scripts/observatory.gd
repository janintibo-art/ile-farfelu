extends Node3D
## L'Observatoire Brisé : le donjon du chapitre 5 (aucun ennemi), très haut dans le ciel (y = 1200).
## Une horloge astronomique cassée : déplacer une aiguille change l'époque d'un élément du décor.
##   1. la porte brisée (lire le code sur la porte intacte, dans le passé, puis le taper maintenant)
##   2. la serre (une graine, un arbuste, un arbre-pont : l'aiguille choisit l'époque)
##   3. la salle des ombres (deux statues, chacune avec sa propre aiguille : l'ombre doit tomber sur sa dalle)
##   4. le pendule (l'arrêter trois fois de suite quand il passe au milieu : on l'entend tiquer)
##   5. le grand cadran : on remonte il y a vingt-sept ans et on assiste à l'événement ancien.
## La progression est sauvegardée (Save.story["ob_room"]).

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Fx := preload("res://scripts/fx.gd")
const Save := preload("res://scripts/save.gd")
const Characters := preload("res://scripts/characters.gd")
const Talker := preload("res://scripts/talker.gd")
const ChoiceBtn := preload("res://scripts/choice_button.gd")
const Bells := preload("res://scripts/bells.gd")

const Y := 1200.0
const X0 := -36.0
const DX := 18.0
const WALLS := [Color(0.62, 0.58, 0.7), Color(0.6, 0.72, 0.62), Color(0.72, 0.65, 0.6), Color(0.62, 0.66, 0.78), Color(0.78, 0.72, 0.85)]
const SYM_NAMES := ["Soleil", "Lune", "Étoile"]
const DOOR_SEQ := [0, 2, 1]
const AMP := 0.8
const PERIOD := 3.2

var v
var player
var built := false
var active := false
var busy := false
var gates: Array = []
var ele
var cart
var bas
var last_room := -1
var said := {}
var dials := {}
var door_past: Node3D
var door_now: Node3D
var plant: Array = []
var bridge: Node3D
var statue_st := {"a": 1, "b": 1}
var shadows := {}
var plates := {}
var _door_in: Array = []
var _pend: Node3D
var _pend_lbl: Label3D
var _pend_n := 0
var _pend_sign := 1
var _t := 0.0
var _plate_ok := false
var _scene_on := false
var _book: Node3D


func setup(p_village, p_player) -> void:
	v = p_village
	player = p_player
	visible = false


func ro(i: int) -> Vector3:
	return Vector3(X0 + DX * i, Y, 0.0)


func cur() -> int:
	return clampi(int(floor((player.global_position.x - X0 + DX * 0.5) / DX)), 0, 4)


func solved() -> int:
	return int(Save.story.get("ob_room", 0))


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
	var d := 2.5 + text.length() * 0.055
	match who:
		"e":
			_say_ele(text)
		"c":
			cart.chibi.say(text, d)
		"b":
			bas.chibi.say(text, d)
		"t":
			Fx.text(v.world, ro(4) + Vector3(0, 3.6, -2.0), text, Color(0.85, 0.95, 1.0), 0.6, d)
		_:
			_pico(text)


func _seq_end(done: Callable) -> void:
	busy = false
	if done.is_valid():
		done.call()


func _noop() -> void:
	pass


func _set_on(n: Node3D, on: bool) -> void:
	n.visible = on
	for c in n.get_children():
		if c is StaticBody3D:
			c.collision_layer = 1 if on else 0


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
	ele.name = "EleonoreObservatoire"
	add_child(ele)
	ele.setup(v, player, Characters.ELEONORE)
	ele.rest_yaw = -PI * 0.5


func _shell(r: Node3D, i: int) -> void:
	var b := Builder.new()
	var wc: Color = WALLS[i]
	var h := 6.0
	if i == 1:
		b.box(Vector3(5.0, 0.4, 10), Vector3(-5.0, -0.2, 0), Color(0.45, 0.5, 0.45), true)
		b.box(Vector3(5.0, 0.4, 10), Vector3(5.0, -0.2, 0), Color(0.45, 0.5, 0.45), true)
		b.box(Vector3(5.0, 0.2, 10), Vector3(0, -6.5, 0), Color(0.08, 0.08, 0.12), false)
	else:
		b.box(Vector3(15, 0.4, 10), Vector3(0, -0.2, 0), Color(0.45, 0.45, 0.52), true)
	b.box(Vector3(15, 0.2, 10), Vector3(0, h + 0.1, 0), wc.darkened(0.3), true)
	b.box(Vector3(15, h, 0.3), Vector3(0, h * 0.5, -5.0), wc, true)
	b.box(Vector3(15, h, 0.3), Vector3(0, h * 0.5, 5.0), wc, true)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(0.3, h, 4.0), Vector3(sx * 7.35, h * 0.5, -3.0), wc, true)
		b.box(Vector3(0.3, h, 4.0), Vector3(sx * 7.35, h * 0.5, 3.0), wc, true)
		b.box(Vector3(0.3, h - 2.6, 2.0), Vector3(sx * 7.35, 2.6 + (h - 2.6) * 0.5, 0), wc, true)
	# Rouages décoratifs sur le mur sud
	for k in 4:
		var x := -5.0 + k * 3.3
		b.cylinder(1.0, 1.0, 0.2, Vector3(x, 3.4, 4.8), Color(0.75, 0.6, 0.3).darkened(0.1 * k), Basis(Vector3.RIGHT, PI * 0.5), 10)
		b.cylinder(0.3, 0.3, 0.26, Vector3(x, 3.4, 4.8), Color(0.3, 0.25, 0.2), Basis(Vector3.RIGHT, PI * 0.5), 6)
	b.build(r, Toon.vertex_color(0.01), "Shell")
	var lt := OmniLight3D.new()
	lt.omni_range = 14.0
	lt.light_energy = 1.2
	lt.light_color = Color(0.95, 0.9, 1.0)
	r.add_child(lt)
	lt.position = Vector3(0, 5.0, 0)
	var g := Node3D.new()
	g.name = "Gate"
	r.add_child(g)
	var gb := Builder.new()
	for k in 5:
		gb.box(Vector3(0.12, 2.6, 0.12), Vector3(7.3, 1.3, -0.8 + k * 0.4), Color(0.5, 0.4, 0.6), true)
	gb.box(Vector3(0.14, 0.14, 2.0), Vector3(7.3, 1.3, 0), Color(0.5, 0.4, 0.6), false)
	gb.build(g, Toon.vertex_color(0.01), "Bars")
	gates.append(g)
	_label(r, "SALLE %d" % (i + 1), Vector3(-7.1, 4.6, -1.8), PI * 0.5, 0.012, Color(0.2, 0.15, 0.3))


func _label(parent: Node3D, text: String, pos: Vector3, yaw := 0.0, px := 0.004, col := Color(0.2, 0.15, 0.3)) -> Label3D:
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
		b.box(Vector3(3.0, 0.4, 2.0), Vector3(cx, Y - 0.2, 0), Color(0.45, 0.43, 0.5), true)
		b.box(Vector3(3.0, 0.2, 2.0), Vector3(cx, Y + 3.0, 0), Color(0.45, 0.43, 0.5), true)
		for sz in [-1.0, 1.0]:
			b.box(Vector3(3.0, 3.0, 0.2), Vector3(cx, Y + 1.5, sz * 1.0), Color(0.75, 0.72, 0.82), true)
	b.build(self, Toon.vertex_color(0.01), "Corridors")


func _open_gate(i: int) -> void:
	if i >= gates.size():
		return
	var g: Node3D = gates[i]
	if g and is_instance_valid(g):
		Fx.puff(v.world, g.global_position + Vector3(0, 1.2, 0), Color(0.85, 0.8, 1.0))
		g.queue_free()
	gates[i] = null


func _solve(i: int) -> void:
	_open_gate(i)
	Save.story["ob_room"] = maxi(solved(), i + 1)
	Save.save_game()
	Fx.text(v.world, ro(i) + Vector3(6.0, 2.5, 0), "PORTE OUVERTE", Color(0.7, 1.0, 0.75), 1.0, 2.5)


func _exit_hot(i: int) -> void:
	_hot(i, Vector3(-6.0, 1.2, -3.0), "Redescendre", func(): exit(), func(): return true, 1.6)


## Une aiguille : chaque pression passe à l'époque suivante.
func _dial(room: int, id: String, pos: Vector3, labels: Array, on_change: Callable, cond := Callable()) -> void:
	var lb := _label(get_child(room), labels[0], pos + Vector3(0, 0.55, 0), 0.0, 0.0055, Color(1.0, 0.9, 0.5))
	dials[id] = {"n": labels.size(), "labels": labels, "state": 0, "lbl": lb, "cb": on_change}
	var cnd := cond
	if not cond.is_valid():
		cnd = func(): return true
	_hot(room, pos, "Tourner l'aiguille", _turn.bind(id), cnd, 1.7)
	lb.text = labels[0]


func _dial_set(id: String, s: int) -> void:
	var d: Dictionary = dials[id]
	d["state"] = s
	d["lbl"].text = d["labels"][s]


func _turn(id: String) -> void:
	var d: Dictionary = dials[id]
	var s: int = (int(d["state"]) + 1) % int(d["n"])
	_dial_set(id, s)
	Bells.play(v.world, "metal", 0.0, ro(cur()) + Vector3(0, 2.0, -2.0), -3.0)
	d["cb"].call(s)


# --- Salle 1 : la porte brisée -----------------------------------------------------------------------

func _r1(r: Node3D) -> void:
	door_past = Node3D.new()
	r.add_child(door_past)
	var pb := Builder.new()
	pb.box(Vector3(2.6, 3.8, 0.1), Vector3(0, 1.9, -4.62), Color(0.5, 0.35, 0.25), false)
	pb.box(Vector3(2.9, 0.2, 0.2), Vector3(0, 3.9, -4.6), Color(0.35, 0.25, 0.2), false)
	pb.sphere(0.1, Vector3(0.9, 1.8, -4.5), Color(0.9, 0.75, 0.3), Vector3.ONE, Basis(), 6)
	pb.build(door_past, Toon.vertex_color(0.01), "Porte")
	_label(door_past, "AU SOLEIL,\nL'ÉTOILE,\nPUIS LA LUNE.", Vector3(0, 2.3, -4.5), 0.0, 0.0055, Color(1.0, 0.9, 0.6))
	door_now = Node3D.new()
	r.add_child(door_now)
	var nb := Builder.new()
	nb.box(Vector3(2.6, 0.2, 0.2), Vector3(0, 3.9, -4.6), Color(0.35, 0.25, 0.2), false)
	nb.box(Vector3(1.4, 0.15, 0.6), Vector3(-0.6, 0.08, -4.1), Color(0.5, 0.35, 0.25), false, Basis(Vector3.UP, 0.4))
	nb.box(Vector3(0.9, 0.15, 0.5), Vector3(0.7, 0.2, -3.9), Color(0.45, 0.32, 0.22), false, Basis(Vector3.UP, -0.5) * Basis(Vector3.RIGHT, 0.3))
	nb.box(Vector3(0.3, 2.0, 0.1), Vector3(-1.1, 1.0, -4.55), Color(0.5, 0.35, 0.25), false, Basis(Vector3.BACK, 0.2))
	nb.box(Vector3(0.6, 0.15, 0.3), Vector3(0.1, 0.07, -3.6), Color(0.5, 0.35, 0.25), false)
	nb.sphere(0.12, Vector3(1.4, 0.12, -3.5), Color(0.9, 0.75, 0.3), Vector3.ONE, Basis(), 6)
	nb.build(door_now, Toon.vertex_color(0.01), "Debris")
	_label(r, "LA PORTE BRISÉE\nOn ne lit bien qu'avant que ça casse.", Vector3(0, 5.2, -4.68), 0.0, 0.0052)
	var pnl := Builder.new()
	pnl.box(Vector3(2.8, 1.2, 0.2), Vector3(4.3, 1.1, -4.4), Color(0.4, 0.4, 0.5), false)
	pnl.build(r, Toon.vertex_color(0.01), "Panneau")
	_label(r, "SERRURE À SYMBOLES\n(n'existe que maintenant)", Vector3(4.3, 2.1, -4.28), 0.0, 0.0034)
	_set_on(door_past, false)
	_dial(0, "porte", Vector3(-4.2, 1.5, -3.6), ["MAINTENANT", "AVANT"], _door_time)
	for k in 3:
		_hot(0, Vector3(3.3 + k * 1.0, 1.6, -3.9), SYM_NAMES[k], _door_sym.bind(k), func(): return int(dials["porte"]["state"]) == 0 and solved() < 1, 1.0)
	_exit_hot(0)


func _door_time(s: int) -> void:
	_set_on(door_past, s == 1)
	_set_on(door_now, s == 0)


func _door_sym(k: int) -> void:
	Bells.play(v.world, "tick", 0.0, ro(0) + Vector3(4.3, 1.4, -4.0), 2.0)
	_door_in.append(k)
	for n in _door_in.size():
		if _door_in[n] != DOOR_SEQ[n]:
			_door_in = []
			Fx.text(v.world, ro(0) + Vector3(4.3, 2.8, -3.5), "La serrure grince : non.", Color(1.0, 0.85, 0.7), 0.5, 2.5)
			return
	if _door_in.size() == DOOR_SEQ.size():
		_door_in = []
		_later(0.8, _r1_done)


func _r1_done() -> void:
	_say_ele("« Au soleil, l'étoile, puis la lune. » Il fallait lire la porte avant qu'elle casse. Facile, quand on peut remonter le temps.")
	_solve(0)


# --- Salle 2 : la serre ---------------------------------------------------------------------------------

func _r2(r: Node3D) -> void:
	for k in 3:
		var n := Node3D.new()
		r.add_child(n)
		plant.append(n)
	var b0 := Builder.new()
	b0.sphere(0.14, Vector3(-3.6, 0.2, 0), Color(0.55, 0.38, 0.25), Vector3(1.0, 0.7, 1.0), Basis(), 8)
	b0.build(plant[0], Toon.vertex_color(0.0), "Graine")
	var b1 := Builder.new()
	b1.cylinder(0.05, 0.08, 1.4, Vector3(-3.6, 0.7, 0), Color(0.45, 0.3, 0.2), Basis(), 6)
	b1.sphere(0.5, Vector3(-3.6, 1.6, 0), Color(0.4, 0.75, 0.4), Vector3.ONE, Basis(), 8)
	b1.build(plant[1], Toon.vertex_color(0.0), "Arbuste")
	var b2 := Builder.new()
	b2.cylinder(0.35, 0.5, 5.0, Vector3(-3.6, 2.5, 0), Color(0.45, 0.3, 0.2), Basis(), 8)
	b2.sphere(2.0, Vector3(-3.6, 5.0, 0), Color(0.35, 0.7, 0.35), Vector3(1.2, 0.8, 1.2), Basis(), 10)
	b2.box(Vector3(7.2, 0.4, 1.4), Vector3(0, -0.2, 0), Color(0.5, 0.35, 0.22), true)
	b2.sphere(0.8, Vector3(1.0, 0.3, 0.9), Color(0.4, 0.75, 0.4), Vector3(1.2, 0.5, 1.0), Basis(), 6)
	b2.build(plant[2], Toon.vertex_color(0.0), "Arbre")
	var ped := Builder.new()
	ped.cylinder(0.4, 0.5, 0.2, Vector3(-3.6, 0.1, 0), Color(0.6, 0.6, 0.65), Basis(), 10)
	ped.build(r, Toon.vertex_color(0.0), "Socle")
	_label(r, "LA SERRE\nUn trou n'est pas un trou si on attend assez.", Vector3(0, 5.2, -4.68), 0.0, 0.0052)
	_label(r, "(deux aiguilles : une de chaque côté)", Vector3(0, 4.4, -4.68), 0.0, 0.003)
	_plant_state(0)
	_dial(1, "serre_g", Vector3(-6.2, 1.5, -3.2), ["GRAINE", "ARBUSTE", "ARBRE"], _plant_state)
	_dial(1, "serre_d", Vector3(6.2, 1.5, -3.2), ["GRAINE", "ARBUSTE", "ARBRE"], _plant_state)
	_exit_hot(1)


func _plant_state(s: int) -> void:
	for k in 3:
		_set_on(plant[k], k == s)
	for id in ["serre_g", "serre_d"]:
		if dials.has(id):
			_dial_set(id, s)


# --- Salle 3 : les ombres ------------------------------------------------------------------------------

func _r3(r: Node3D) -> void:
	var b := Builder.new()
	for sx in [-2.5, 2.5]:
		b.cylinder(0.35, 0.5, 0.5, Vector3(sx, 0.25, -1.0), Color(0.6, 0.6, 0.65), Basis(), 8)
		b.capsule(0.3, 1.4, Vector3(sx, 1.2, -1.0), Color(0.75, 0.75, 0.8), Basis())
		b.sphere(0.28, Vector3(sx, 2.2, -1.0), Color(0.8, 0.8, 0.85), Vector3.ONE, Basis(), 8)
	b.sphere(0.35, Vector3(0, 5.2, -4.4), Color(1.0, 0.9, 0.5), Vector3.ONE, Basis(), 8)
	b.build(r, Toon.vertex_color(0.01), "Statues")
	for key in ["a", "b"]:
		var sh := Node3D.new()
		r.add_child(sh)
		shadows[key] = sh
		var sb := Builder.new()
		sb.box(Vector3(2.4, 0.03, 0.9), Vector3.ZERO, Color(0.08, 0.08, 0.14), false)
		sb.build(sh, Toon.vertex_color(0.0), "Ombre")
	for key in ["a", "b"]:
		var pl := Node3D.new()
		r.add_child(pl)
		plates[key] = pl
		var pb := Builder.new()
		pb.box(Vector3(1.2, 0.06, 1.2), Vector3.ZERO, Color(0.85, 0.7, 0.3), false)
		pb.build(pl, Toon.vertex_color(0.0), "Dalle")
		pl.position = Vector3(-4.4 if key == "a" else 4.4, 0.05, -1.0)
	_label(r, "LA SALLE DES OMBRES", Vector3(0, 5.5, -4.68), 0.0, 0.0055)
	_label(r, "Au lever du jour, l'ombre fuit vers l'ouest.\nAu coucher, vers l'est. À midi, elle se cache sous les pieds.\nLa dalle du Berger est à l'ouest. Celle de la Dame, à l'est.", Vector3(0, 4.0, -4.68), 0.0, 0.0042)
	_label(r, "LE BERGER", Vector3(-2.5, 2.9, -1.0), 0.0, 0.0045)
	_label(r, "LA DAME", Vector3(2.5, 2.9, -1.0), 0.0, 0.0045)
	_shadow_state("a", 0)
	_shadow_state("b", 0)
	_dial(2, "ombre_a", Vector3(-2.5, 1.6, 1.0), ["MIDI", "SOIR", "MATIN"], _shadow_cb.bind("a"))
	_dial(2, "ombre_b", Vector3(2.5, 1.6, 1.0), ["MIDI", "SOIR", "MATIN"], _shadow_cb.bind("b"))
	_exit_hot(2)


## Les aiguilles tournent MIDI(0) -> SOIR(1) -> MATIN(2) ; ombre : 0 sous les pieds, 1 vers l'est, 2 vers l'ouest.
func _shadow_cb(s: int, key: String) -> void:
	_shadow_state(key, s)
	_check_plates()


func _shadow_state(key: String, s: int) -> void:
	statue_st[key] = s
	var sx := -2.5 if key == "a" else 2.5
	var sh: Node3D = shadows[key]
	match s:
		0:
			sh.position = Vector3(sx, 0.03, -0.8)
			sh.scale = Vector3(0.4, 1.0, 1.0)
		1:
			sh.position = Vector3(sx + 1.4, 0.03, -1.0)
			sh.scale = Vector3.ONE
		_:
			sh.position = Vector3(sx - 1.4, 0.03, -1.0)
			sh.scale = Vector3.ONE
	var ok: bool = (key == "a" and s == 2) or (key == "b" and s == 1)
	var pl: Node3D = plates[key]
	pl.get_child(0).material_override = Toon.unlit(Color(1.0, 0.95, 0.4)) if ok else Toon.vertex_color(0.0)


func _check_plates() -> void:
	if solved() >= 3 or _plate_ok:
		return
	if statue_st["a"] == 2 and statue_st["b"] == 1:
		_plate_ok = true
		Fx.text(v.world, ro(2) + Vector3(0, 3.2, -2.0), "LES DEUX OMBRES TOMBENT JUSTE", Color(0.7, 1.0, 0.75), 0.8, 3.0)
		_later(1.6, _r3_done)


func _r3_done() -> void:
	_say_ele("Le Berger regarde le soleil se coucher, la Dame le voit se lever. Deux ombres, deux sens : même heure pour personne.")
	_solve(2)


# --- Salle 4 : le pendule --------------------------------------------------------------------------------

func _r4(r: Node3D) -> void:
	_pend = Node3D.new()
	r.add_child(_pend)
	_pend.position = Vector3(0, 5.6, -1.5)
	var b := Builder.new()
	b.box(Vector3(0.12, 4.2, 0.12), Vector3(0, -2.1, 0), Color(0.6, 0.5, 0.3), false)
	b.sphere(0.5, Vector3(0, -4.4, 0), Color(0.9, 0.75, 0.3), Vector3.ONE, Basis(), 12)
	b.build(_pend, Toon.vertex_color(0.0), "Pendule")
	var mark := Builder.new()
	mark.box(Vector3(0.1, 0.05, 1.6), Vector3(0, 0.02, -1.5), Color(1.0, 0.6, 0.3), false)
	mark.build(r, Toon.vertex_color(0.0), "Repere")
	_label(r, "LE PENDULE\nÀ l'écoute : il tique chaque fois qu'il passe au milieu.", Vector3(0, 5.5, -4.68), 0.0, 0.0048)
	_label(r, "(arrêtez-le trois fois de suite, pile au milieu)", Vector3(0, 4.7, -4.68), 0.0, 0.003)
	_pend_lbl = _label(r, "0 / 3", Vector3(0, 2.0, -4.6), 0.0, 0.0085, Color(1.0, 0.9, 0.5))
	_hot(3, Vector3(0, 1.3, 2.2), "Arrêter le pendule", _stop_pendulum, func(): return solved() < 4, 2.3)
	_exit_hot(3)


func _pend_angle() -> float:
	return AMP * sin(_t * TAU / PERIOD)


func _stop_pendulum() -> void:
	var s := absf(sin(_t * TAU / PERIOD))
	if s < 0.3:
		_pend_n += 1
		Fx.puff(v.world, _pend.global_position + Vector3(0, -4.2, 0), Color(1.0, 0.9, 0.5))
		_pend_lbl.text = "%d / 3" % _pend_n
		if _pend_n >= 3:
			_later(1.0, _r4_done)
	else:
		_pend_n = 0
		_pend_lbl.text = "0 / 3"
		Fx.text(v.world, ro(3) + Vector3(0, 2.6, 2.0), "Trop tôt, ou trop tard.", Color(1.0, 0.85, 0.7), 0.55, 2.5)


func _r4_done() -> void:
	_say_ele("Au milieu, trois fois de suite. Même mon père n'aurait pas été aussi régulier. Il était toujours en avance, ou en retard d'une idée.")
	_solve(3)


# --- Salle 5 : le grand cadran --------------------------------------------------------------------------------

func _r5(r: Node3D) -> void:
	var b := Builder.new()
	b.cylinder(2.4, 2.4, 0.2, Vector3(0, 2.8, -4.6), Color(0.95, 0.92, 0.85), Basis(Vector3.RIGHT, PI * 0.5), 24)
	b.torus(2.35, 2.65, Vector3(0, 2.8, -4.5), Color(0.8, 0.65, 0.25), Basis(Vector3.RIGHT, PI * 0.5))
	b.box(Vector3(0.18, 1.8, 0.1), Vector3(0.5, 3.4, -4.45), Color(0.15, 0.15, 0.25), false, Basis(Vector3.BACK, -0.5))
	b.box(Vector3(0.12, 2.2, 0.1), Vector3(-0.7, 3.2, -4.4), Color(0.2, 0.2, 0.3), false, Basis(Vector3.BACK, 0.9))
	b.box(Vector3(2.4, 0.9, 1.2), Vector3(0, 0.45, -2.6), Color(0.5, 0.4, 0.35), true)
	b.build(r, Toon.vertex_color(0.01), "Cadran")
	var bk := Builder.new()
	bk.box(Vector3(0.7, 0.1, 0.5), Vector3(0, 0, 0), Color(0.55, 0.2, 0.25), false)
	bk.box(Vector3(0.62, 0.06, 0.44), Vector3(0, 0.07, 0), Color(0.97, 0.94, 0.85), false)
	_book = Node3D.new()
	r.add_child(_book)
	_book.position = Vector3(0, 0.95, -2.6)
	bk.build(_book, Toon.vertex_color(0.0), "Registre")
	_label(r, "LE GRAND CADRAN\nIl se souvient de tout, mais pas dans l'ordre.", Vector3(0, 5.6, -4.68), 0.0, 0.0052)
	_label(r, "« Remonter, c'est regarder. Pas toucher. »", Vector3(0, 4.9, -4.68), 0.0, 0.003)
	cart = Talker.new()
	cart.name = "Cartographe"
	r.add_child(cart)
	cart.setup(v, player, Characters.CARTOGRAPHE)
	cart.position = Vector3(-1.6, 0.03, -2.6)
	cart.rest_yaw = -PI * 0.5
	cart.visible = false
	bas = Talker.new()
	bas.name = "BasileJeune"
	r.add_child(bas)
	bas.setup(v, player, Characters.BASILE_PLUME)
	bas.position = Vector3(1.6, 0.03, -2.6)
	bas.rest_yaw = PI * 0.5
	bas.visible = false
	_dial(4, "epoque", Vector3(-2.4, 1.5, 0.6), ["IL Y A 300 ANS", "IL Y A 27 ANS", "HIER"], _noop_s)
	_hot(4, Vector3(2.4, 1.5, 0.6), "Regarder", _watch, func(): return not _scene_on and not _s("ch5_done"), 1.5)
	_exit_hot(4)


func _noop_s(_s_: int) -> void:
	pass


func _watch() -> void:
	var s := int(dials["epoque"]["state"])
	match s:
		0:
			_seq([
				["t", "Un chantier de pierre. Un écho y grave une porte, encore et encore."],
				["p", "Trois cents ans de portes. Je ne reconnais personne. Essayons plus récent."],
			], _noop)
		2:
			_seq([
				["t", "Hubert Sablier monte l'escalier avec ses pots. Il s'arrête. Le temps rembobine."],
				["e", "On a déjà vu ça. Hier, c'était hier. Remonte plus loin."],
			], _noop)
		_:
			_scene()


func _scene() -> void:
	_scene_on = true
	cart.visible = true
	bas.visible = true
	Fx.puff(v.world, ro(4) + Vector3(0, 1.4, -2.6), Color(0.8, 0.9, 1.0))
	_seq([
		["t", "Il y a vingt-sept ans. Deux hommes, un livre, une île."],
		["b", "Armand, regarde : l'île a encore bougé. La mairie est passée à gauche. Hier, elle était trop à droite."],
		["c", "Elle bouge parce qu'on la raconte, Basile. Le Registre ne décrit pas l'île : c'est l'inverse. Elle existe tant qu'on continue de l'imaginer."],
		["e", "Papa..."],
		["b", "Et si un jour on cessait ? Si l'histoire s'arrêtait en plein milieu ? J'ai peur de tout ce qui s'efface, Armand. Je ne supporte plus d'oublier."],
		["c", "On oublie pour pouvoir continuer. Une île finie, c'est une île morte."],
		["b", "Alors je la finirai. Une version qui ne change plus, où rien ne se perd. Je suis désolé. Je commence maintenant."],
		["t", "Une lumière blanche. Les pages du Registre s'envolent."],
	], _scene_flash)


func _scene_flash() -> void:
	Fx.puff(v.world, ro(4) + Vector3(0, 2.0, -2.6), Color(1.0, 1.0, 1.0))
	Bells.play(v.world, "bell", 130.8, ro(4) + Vector3(0, 2.0, -2.6), 6.0)
	for k in 6:
		var pg := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.3, 0.02, 0.22)
		pg.mesh = bm
		pg.material_override = Toon.unlit(Color(1.0, 0.97, 0.85))
		get_child(4).add_child(pg)
		pg.position = Vector3(0, 1.0, -2.6)
		var tw := create_tween()
		tw.tween_property(pg, "position", Vector3(-4.0 + k * 1.6, 3.0 + (k % 3), -3.5 + (k % 2) * 3.0), 2.0).set_trans(Tween.TRANS_SINE)
		tw.tween_interval(2.0)
		tw.tween_callback(pg.queue_free)
	_book.visible = false
	_seq([
		["c", "Basile, non ! Les pages se séparent ! Je dois les rattraper, toutes, avant qu'elles ne s'oublient !"],
		["c", "...La dernière, la vivante, celle qui parle : va. Cache-toi dans une bouteille. Ne dis rien avant qu'ils soient prêts. Pico."],
		["t", "Une petite page luisante file vers le haut, puis disparaît. Armand court après les autres, et le grand cadran l'avale."],
	], _scene_end)


func _scene_end() -> void:
	cart.visible = false
	bas.visible = false
	_book.visible = true
	_seq([
		["e", "Il n'a pas disparu : il court encore. Il est parti chercher les pages. Mon père est parti chercher les pages."],
		["p", "...La dernière page vivante. Celle qui parle. Éléonore, c'est moi. Je suis une page du Grand Registre. Je ne suis pas dans la liste : je suis ce qui reste de la liste."],
		["e", "Alors tu étais cachée dans une bouteille depuis tout ce temps pour une raison. Et Basile n'a jamais voulu faire de mal : il avait peur. C'est pire, ça se pardonne moins bien."],
		["p", "Si l'île existe tant qu'on la raconte... alors je suis son dernier mot. Je ne chanterai plus jamais faux. Enfin, si. Mais j'essaierai de choisir mes moments."],
	], _end_chapter)


func _end_chapter() -> void:
	_scene_on = false
	if _s("ch5_done"):
		return
	Save.story["ch5_done"] = true
	Save.story["pico_page"] = true
	Save.story["invite"] = true
	Save.shells += 60
	Save.save_game()
	Fx.text(v.world, ro(4) + Vector3(0, 3.8, 0), "CHAPITRE 5 TERMINÉ", Color(1.0, 0.95, 0.5), 1.6, 6.0)
	Fx.text(v.world, ro(4) + Vector3(0, 3.0, 0), "+60 coquillages", Color(1.0, 0.9, 0.5), 0.8, 4.0)
	_later(4.5, func(): Fx.text(v.world, ro(4) + Vector3(0, 3.4, 0), "À suivre : une invitation au bal des Versions Officielles...", Color(0.9, 0.95, 1.0), 0.7, 6.0))


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
	var s := mini(solved(), 4)
	player.global_position = ro(s) + Vector3(-6.0, 0.15, 0)
	player._vy = 0.0
	player._face_yaw(-PI * 0.5)
	player._place_origin(true, 0.0)
	last_room = -1
	var tw: Tween = v.maquette._fade_to(1.0, 0.0, 1.2)
	tw.tween_callback(_unbusy)
	Fx.text(v.world, ro(s) + Vector3(-3.0, 3.0, 0), "L'OBSERVATOIRE BRISÉ", Color(0.85, 0.85, 1.0), 1.2, 3.5)


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
	player.global_position = Vector3(0.0, 1100.1, -7.4)
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
		"L'Observatoire Brisé. Ici, l'horloge ne donne pas l'heure : elle prête des époques. Gardez-les propres.",
		"Un trou, une graine, un arbre. Le sol n'est pas un obstacle, juste un manque de patience.",
		"Deux statues, deux ombres, deux dalles. Chacune a son propre soleil : on ne triche pas avec le Berger.",
		"Un pendule. Pas besoin de comprendre : il suffit d'écouter. Les choses importantes tiquent.",
		"Le grand cadran. Il y a un livre dessus. Je n'ose pas respirer.",
	]
	_later(1.2, func(): _say_ele(lines[i]))
	if ele:
		ele.global_position = ro(i) + Vector3(-4.8, 0.05, 2.5)
		ele.chibi.rotation.y = 0.0


func _physics_process(delta: float) -> void:
	if not active or player == null:
		return
	_t += delta
	if _pend != null:
		var a := _pend_angle()
		_pend.rotation.z = a
		var sg := 1 if a >= 0.0 else -1
		if sg != _pend_sign:
			_pend_sign = sg
			if active and cur() == 3:
				Bells.play(v.world, "tick", 0.0, ro(3) + Vector3(0, 1.2, -1.5), 0.0)
	if busy:
		return
	var pp: Vector3 = player.global_position
	if pp.y < Y - 6.0:
		player.global_position = ro(clampi(solved(), 0, 4)) + Vector3(-6.0, 0.2, 0)
		return
	var c := cur()
	if c != last_room:
		last_room = c
		_on_room(c)
	if c == 1 and solved() < 2 and pp.x > ro(1).x + 3.4 and pp.y > Y - 1.0:
		_say_ele("Traversé ! Et sans se mouiller les pieds : il n'y avait même pas d'eau.")
		_solve(1)
