extends Node3D
## Le Phare de l'Envers : le premier vrai donjon de l'histoire (aucun ennemi).
## Six salles à la suite, très haut dans le ciel au-dessus de l'île
## (comme la maquette) : l'escalier impossible, les fenêtres, la pièce
## penchée, la maquette, la chambre du gardien, le sommet.
## La progression (nombre de salles résolues) est sauvegardée.

const Toon := preload("res://scripts/toon.gd")
const Island := preload("res://scripts/island.gd")
const Builder := preload("res://scripts/builder.gd")
const Fx := preload("res://scripts/fx.gd")
const Save := preload("res://scripts/save.gd")
const Props := preload("res://scripts/props.gd")
const Characters := preload("res://scripts/characters.gd")
const Talker := preload("res://scripts/talker.gd")

const Y := 300.0
const X0 := -45.0
const DX := 18.0
const TILT := 0.105    # ~6 degrés
const WALLS := [Color(0.95, 0.93, 0.88), Color(0.85, 0.92, 0.98), Color(0.98, 0.9, 0.82), Color(0.9, 0.9, 1.0), Color(0.93, 0.85, 0.75), Color(0.12, 0.1, 0.25)]

var v
var player
var built := false
var active := false
var busy := false
var gates: Array = []
var ele
var last_room := -1
var said := {}
# salle 1
var loops := 0
var stairs_fixed := false
var odd := 0
var lever: Node3D
var lever_shown := false
# salle 2
var win_ok := 0
var wrong2 := 0
# salle 3
var ball: RigidBody3D
var planks: Array = []
var ball_t := 0.0
var hint3 := 0.0
var ball_done := false
# salle 4
var rings: Array = []
var ring_k: Array = [0, 0, 0, 0, 0]
var s4_done := false
# salle 6
var page_label: Label3D
var page_node: Node3D
var page_done := false


func setup(p_village, p_player) -> void:
	v = p_village
	player = p_player
	visible = false


func ro(i: int) -> Vector3:
	return Vector3(X0 + DX * i, Y, 0.0)


func cur() -> int:
	return clampi(int(floor((player.global_position.x - X0 + DX * 0.5) / DX)), 0, 5)


func solved() -> int:
	return int(Save.story.get("phare_room", 0))


func _say_ele(t: String) -> void:
	if ele:
		ele.chibi.say(t, 2.5 + t.length() * 0.055)


func _pico(t: String) -> void:
	v._pico(t)


func _later(t: float, c: Callable) -> void:
	v.get_tree().create_timer(t).timeout.connect(c)


func _hot(i: int, pos: Vector3, text: String, cb: Callable, cond: Callable, width := 1.7) -> void:
	v.x.hotspot(get_child(i), pos, text, cb, func(): return active and cur() == i and cond.call(), width, 3.4)


# --- Construction ------------------------------------------------------------------------------

func _build_scene() -> void:
	built = true
	for i in 6:
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
	_r6(get_child(5))
	ele = Talker.new()
	ele.name = "Eleonore"
	add_child(ele)
	ele.setup(v, player, Characters.ELEONORE)
	ele.rest_yaw = -PI * 0.5


func _shell(r: Node3D, i: int) -> void:
	var b := Builder.new()
	var wc: Color = WALLS[i]
	var h := 6.0
	if i != 2:
		b.box(Vector3(15, 0.4, 10), Vector3(0, -0.2, 0), Color(0.62, 0.5, 0.4), true)
	else:
		b.box(Vector3(15, 0.4, 10), Vector3(0, -1.6, 0), Color(0.3, 0.25, 0.25), true)
	b.box(Vector3(15, 0.2, 10), Vector3(0, h + 0.1, 0), wc.darkened(0.2), true)
	b.box(Vector3(15, h, 0.3), Vector3(0, h * 0.5, -5.0), wc, true)
	b.box(Vector3(15, h, 0.3), Vector3(0, h * 0.5, 5.0), wc, true)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(0.3, h, 4.0), Vector3(sx * 7.35, h * 0.5, -3.0), wc, true)
		b.box(Vector3(0.3, h, 4.0), Vector3(sx * 7.35, h * 0.5, 3.0), wc, true)
		b.box(Vector3(0.3, h - 2.6, 2.0), Vector3(sx * 7.35, 2.6 + (h - 2.6) * 0.5, 0), wc, true)
	for k in 5:
		b.box(Vector3(15, 0.25, 0.32), Vector3(0, 0.15 + k * 1.2, -4.99), Color(0.92, 0.3, 0.32) if k % 2 == 0 else wc.lightened(0.05), false)
	b.build(r, Toon.vertex_color(0.01), "Shell")
	var lt := OmniLight3D.new()
	lt.omni_range = 14.0
	lt.light_energy = 1.3
	r.add_child(lt)
	lt.position = Vector3(0, 5.0, 0)
	# La porte de sortie (est) est fermée par une grille
	var g := Node3D.new()
	g.name = "Gate"
	r.add_child(g)
	var gb := Builder.new()
	for k in 5:
		gb.box(Vector3(0.12, 2.6, 0.12), Vector3(7.3, 1.3, -0.8 + k * 0.4), Color(0.35, 0.3, 0.4), true)
	gb.box(Vector3(0.14, 0.14, 2.0), Vector3(7.3, 1.3, 0), Color(0.35, 0.3, 0.4), false)
	gb.build(g, Toon.vertex_color(0.01), "Bars")
	gates.append(g)
	_label(r, "SALLE %d" % (i + 1), Vector3(-7.1, 4.6, -1.8), PI * 0.5, 0.012)


func _label(parent: Node3D, text: String, pos: Vector3, yaw := 0.0, px := 0.004, col := Color(0.25, 0.2, 0.3)) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = 48
	l.pixel_size = px
	l.outline_size = 0
	l.modulate = col
	l.rotation.y = yaw
	l.position = pos
	parent.add_child(l)


func _corridors() -> void:
	var b := Builder.new()
	for i in 5:
		var cx: float = X0 + DX * i + DX * 0.5
		b.box(Vector3(3.0, 0.4, 2.0), Vector3(cx, Y - 0.2, 0), Color(0.5, 0.4, 0.35), true)
		b.box(Vector3(3.0, 0.2, 2.0), Vector3(cx, Y + 3.0, 0), Color(0.5, 0.4, 0.35), true)
		for sz in [-1.0, 1.0]:
			b.box(Vector3(3.0, 3.0, 0.2), Vector3(cx, Y + 1.5, sz * 1.0), Color(0.85, 0.82, 0.78), true)
	b.build(self, Toon.vertex_color(0.01), "Corridors")


func _open_gate(i: int) -> void:
	var g: Node3D = gates[i]
	if g and is_instance_valid(g):
		Fx.puff(v.world, g.global_position + Vector3(0, 1.2, 0), Color(0.9, 0.9, 1.0))
		g.queue_free()
	gates[i] = null


func _solve(i: int) -> void:
	_open_gate(i)
	Save.story["phare_room"] = maxi(solved(), i + 1)
	Save.save_game()
	Fx.text(v.world, ro(i) + Vector3(6.0, 2.5, 0), "PORTE OUVERTE", Color(0.7, 1.0, 0.75), 1.0, 2.5)


# --- Salle 1 : l'escalier impossible -------------------------------------------------------------

func _r1(r: Node3D) -> void:
	var b := Builder.new()
	var ang := atan2(2.4, 7.0)
	b.box(Vector3(7.4, 0.3, 1.8), Vector3(-0.5, 1.05, -3.5), Color(0.75, 0.6, 0.45), true, Basis(Vector3.BACK, ang))
	for k in 8:
		b.box(Vector3(0.12, 0.04, 1.8), Vector3(-3.6 + k * 0.9, 0.36 + k * 0.3, -3.5), Color(0.5, 0.35, 0.3), false)
	b.box(Vector3(3.0, 0.3, 1.8), Vector3(4.5, 2.25, -3.5), Color(0.75, 0.6, 0.45), true)
	b.box(Vector3(3.0, 0.1, 0.1), Vector3(4.5, 3.0, -4.3), Color(0.5, 0.35, 0.3), false)
	odd = randi() % 4
	for k in 4:
		var x := -4.5 + k * 3.0
		var frame := Color(0.85, 0.65, 0.2) if k != odd else Color(0.88, 0.6, 0.2)
		b.box(Vector3(1.6, 1.2, 0.08), Vector3(x, 2.4, 4.82), frame, false)
		b.box(Vector3(1.4, 1.0, 0.06), Vector3(x, 2.4, 4.78), Color(0.6, 0.85, 1.0), false)
		b.box(Vector3(1.4, 0.35, 0.07), Vector3(x, 2.07, 4.77), Color(0.45, 0.78, 0.45), false)
		var sun := Color(1.0, 0.9, 0.3) if k != odd else Color(1.0, 0.72, 0.3)
		b.cylinder(0.14, 0.14, 0.07, Vector3(x + 0.35, 2.65, 4.76), sun, Basis(Vector3.RIGHT, PI * 0.5), 10)
	b.build(r, Toon.vertex_color(0.01), "Stairs")
	_label(r, "Étage 1\n(le même)", Vector3(4.5, 3.4, -4.7), 0.0, 0.005)
	for k in 4:
		var x := -4.5 + k * 3.0
		_hot(0, Vector3(x, 1.4, 4.3), "Retourner le tableau", _flip.bind(k), func(): return loops >= 1 and not lever_shown and not stairs_fixed, 1.6)
	lever = Node3D.new()
	lever.name = "Levier"
	r.add_child(lever)
	var lb := Builder.new()
	lb.box(Vector3(0.3, 0.3, 0.12), Vector3(0, 0, 0), Color(0.3, 0.3, 0.35), false)
	lb.box(Vector3(0.08, 0.5, 0.08), Vector3(0, 0.25, 0.1), Color(0.85, 0.2, 0.2), false, Basis(Vector3.BACK, 0.4))
	lb.sphere(0.1, Vector3(-0.1, 0.5, 0.1), Color(0.95, 0.3, 0.3), Vector3.ONE, Basis(), 8)
	lb.build(lever, Toon.vertex_color(0.008), "Mesh")
	lever.visible = false
	_hot(0, Vector3(0, 1.4, 4.3), "Tirer le levier", _lever, func(): return lever_shown and not stairs_fixed, 1.5)


func _flip(k: int) -> void:
	if k == odd:
		lever_shown = true
		lever.position = Vector3(-4.5 + k * 3.0, 2.3, 4.78)
		lever.visible = true
		for h in v.x.hot:
			pass
		Fx.text(v.world, ro(0) + Vector3(-4.5 + k * 3.0, 3.2, 3.8), "Un levier derrière le tableau !", Color(1.0, 0.95, 0.6), 0.8, 3.0)
		_say_ele("Le soleil était plus orange. Tu as l'œil.")
		_move_lever_hot(k)
	else:
		Fx.text(v.world, ro(0) + Vector3(-4.5 + k * 3.0, 3.2, 3.8), "Rien. Un mur.", Color(1.0, 0.8, 0.7), 0.8, 2.0)
		if loops >= 3:
			_pico("Un des soleils est plus orange que les autres. Je ne dis pas lequel. Parce que je regarde mal.")


func _move_lever_hot(k: int) -> void:
	for h in v.x.hot:
		var bt = h["btn"]
		if bt.label.text == "Tirer le levier":
			bt.get_parent().remove_child(bt)
			get_child(0).add_child(bt)
			bt.position = Vector3(-4.5 + k * 3.0, 1.4, 4.2)


func _lever() -> void:
	stairs_fixed = true
	Fx.text(v.world, ro(0) + Vector3(0, 3.5, 0), "CLONK ! L'escalier reprend sa place.", Color(0.7, 1.0, 0.75), 1.0, 3.0)
	_say_ele("Il monte enfin quelque part. C'est vexant.")
	_solve(0)


# --- Salle 2 : les fenêtres -----------------------------------------------------------------------

func _window(r: Node3D, k: int, fountain: bool, boats: int, house: Color, light2: Color) -> void:
	var x := -5.25 + k * 3.5
	var b := Builder.new()
	b.box(Vector3(2.8, 2.5, 0.1), Vector3(x, 2.7, -4.78), Color(0.35, 0.28, 0.3), false)
	b.box(Vector3(2.5, 2.2, 0.12), Vector3(x, 2.7, -4.74), Color(0.55, 0.82, 1.0), false)
	b.box(Vector3(2.5, 0.8, 0.14), Vector3(x, 1.95, -4.7), Color(0.4, 0.7, 0.45), false)
	b.box(Vector3(2.5, 0.35, 0.14), Vector3(x, 2.2 - 0.4, -4.7), Color(0.3, 0.6, 0.9), false)
	if fountain:
		b.cylinder(0.3, 0.35, 0.14, Vector3(x - 0.2, 2.45, -4.62), Color(0.6, 0.85, 0.95), Basis(Vector3.RIGHT, PI * 0.5), 10)
	b.box(Vector3(0.55, 0.5, 0.15), Vector3(x + 0.7, 2.7, -4.62), house, false)
	b.box(Vector3(0.2, 1.3, 0.15), Vector3(x - 0.95, 2.9, -4.62), light2, false)
	b.box(Vector3(0.2, 0.3, 0.16), Vector3(x - 0.95, 3.2, -4.62), Color.WHITE if light2 != Color(0.2, 0.3, 0.9) else Color(0.2, 0.3, 0.9), false)
	var bc := [Color(0.35, 0.6, 0.85), Color(0.95, 0.5, 0.35), Color(0.45, 0.75, 0.5)]
	for j in boats:
		b.box(Vector3(0.28, 0.1, 0.15), Vector3(x - 0.7 + j * 0.5, 2.0, -4.62), bc[j], false)
	for j in 3:
		b.box(Vector3(0.1, 0.5, 0.02), Vector3(x - 0.1 + j * 0.25, 3.35, -4.7), Color(0.2, 0.2, 0.25), false)
	b.build(r, Toon.vertex_color(0.008), "Fenetre%d" % k)


func _r2(r: Node3D) -> void:
	win_ok = randi() % 4
	var variants := [
		[false, 3, Color(0.4, 0.62, 1.0), Color(0.92, 0.28, 0.3)],
		[true, 3, Color(1.0, 0.82, 0.3), Color(0.92, 0.28, 0.3)],
		[true, 2, Color(0.4, 0.62, 1.0), Color(0.92, 0.28, 0.3)],
		[true, 3, Color(0.4, 0.62, 1.0), Color(0.2, 0.3, 0.9)],
	]
	var good := [true, 3, Color(0.4, 0.62, 1.0), Color(0.92, 0.28, 0.3)]
	var pool: Array = variants.duplicate()
	for k in 4:
		var d: Array
		if k == win_ok:
			d = good
		else:
			d = pool.pop_front()
		_window(r, k, d[0], d[1], d[2], d[3])
		_hot(1, Vector3(-5.25 + k * 3.5, 1.1, -4.2), "Ouvrir cette fenêtre", _open_win.bind(k), func(): return not Save.story.get("win_done", false) and solved() < 2, 1.6)
	_label(r, "Une seule fenêtre montre le Port-Biscornu d'AUJOURD'HUI.", Vector3(0, 4.9, -4.7), 0.0, 0.0042)


func _open_win(k: int) -> void:
	if k == win_ok:
		Save.story["win_done"] = true
		Fx.text(v.world, ro(1) + Vector3(0, 3.2, -3.6), "L'AIR DU DEHORS ! C'est bien aujourd'hui.", Color(0.7, 1.0, 0.75), 0.9, 3.0)
		_say_ele("Fontaine, trois bateaux, maison bleue, phare rouge et blanc. Voilà.")
		_solve(1)
	else:
		wrong2 += 1
		Fx.text(v.world, ro(1) + Vector3(-5.25 + k * 3.5, 3.4, -3.6), "Port-Biscornu... mais il y a longtemps.", Color(1.0, 0.8, 0.7), 0.8, 2.5)
		if wrong2 >= 2:
			_pico("Compare avec le village : la fontaine, les trois bateaux, la couleur de la maison de Marguerite, le phare.")


# --- Salle 3 : la pièce penchée ---------------------------------------------------------------------

func _r3(r: Node3D) -> void:
	var slab := StaticBody3D.new()
	slab.name = "FloorTilt"
	r.add_child(slab)
	slab.position = Vector3(0, -0.2, 0)
	slab.rotation.x = TILT
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(15, 0.4, 10)
	cs.shape = sh
	slab.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(15, 0.4, 10)
	mi.mesh = bm
	mi.material_override = Toon.flat(Color(0.88, 0.8, 0.65))
	slab.add_child(mi)
	var plate := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 1.0
	pm.bottom_radius = 1.0
	pm.height = 0.06
	plate.mesh = pm
	plate.material_override = Toon.flat(Color(0.4, 0.95, 0.5))
	slab.add_child(plate)
	plate.position = Vector3(-4.6, 0.22, 3.8)
	var sb := Builder.new()
	sb.box(Vector3(15, 1.7, 0.3), Vector3(0, -0.8, 5.0), Color(0.5, 0.4, 0.35), true)
	sb.build(r, Toon.vertex_color(0.01), "SouthFix")
	_label(r, "↓ ICI", Vector3(-4.6, 1.2, 4.6), PI, 0.01, Color(0.2, 0.7, 0.3))
	_label(r, "Le sol penche. La boule roule.\nGuide-la avec des planches.", Vector3(0, 3.8, -4.7), 0.0, 0.0045)


func _spawn_r3() -> void:
	if ball and is_instance_valid(ball):
		ball.queue_free()
	ball = RigidBody3D.new()
	ball.mass = 1.5
	var pmat := PhysicsMaterial.new()
	pmat.friction = 0.3
	pmat.bounce = 0.15
	ball.physics_material_override = pmat
	ball.collision_layer = 2
	ball.collision_mask = 1 | 2
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 0.25
	cs.shape = sh
	ball.add_child(cs)
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.25
	sm.height = 0.5
	mi.mesh = sm
	mi.material_override = Toon.flat(Color(0.75, 0.78, 0.85))
	ball.add_child(mi)
	get_child(2).add_child(ball)
	ball.position = Vector3(1.5, 1.0, -4.2)
	ball_t = 0.0


func _spawn_planks() -> void:
	for p in planks:
		if is_instance_valid(p):
			p.queue_free()
	planks.clear()
	for k in 3:
		var rb := Props.make(v.world, "planche", ro(2) + Vector3(-6.0, 1.0 + k * 0.15, -3.0 + k * 1.2))
		rb.no_reset = true
		rb.global_position = ro(2) + Vector3(-6.0, 1.0 + k * 0.15, -3.0 + k * 1.2)
		planks.append(rb)


func _held(rb) -> bool:
	return rb.has_meta("held_by") or player._held_desktop == rb


# --- Salle 4 : la maquette ------------------------------------------------------------------------------

func _r4(r: Node3D) -> void:
	var b := Builder.new()
	b.box(Vector3(2.4, 0.15, 2.4), Vector3(0, 0.9, 0), Color(0.5, 0.36, 0.28), true)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			b.box(Vector3(0.12, 0.9, 0.12), Vector3(sx * 1.0, 0.45, sz * 1.0), Color(0.35, 0.25, 0.2), false)
	b.build(r, Toon.vertex_color(0.01), "Table")
	var cols := [Color(0.97, 0.97, 0.98), Color(0.92, 0.28, 0.3), Color(0.97, 0.97, 0.98), Color(0.92, 0.28, 0.3), Color(0.97, 0.97, 0.98)]
	rings.clear()
	var ks := [0, randi() % 3 + 1, randi() % 4, randi() % 3 + 1, 0]
	for i in 5:
		var n := Node3D.new()
		n.name = "Anneau%d" % i
		r.add_child(n)
		n.position = Vector3(0, 1.1 + i * 0.4, 0)
		var rb := Builder.new()
		rb.cylinder(0.5 - 0.03 * i, 0.5 - 0.03 * i, 0.38, Vector3.ZERO, cols[i], Basis(), 14)
		rb.box(Vector3(0.1, 0.4, 0.18), Vector3(0, 0, -(0.5 - 0.03 * i)), Color(1.0, 0.9, 0.2), false)
		rb.build(n, Toon.vertex_color(0.008), "Mesh")
		rings.append(n)
		ring_k[i] = ks[i]
		n.rotation.y = ks[i] * PI * 0.5
	var names := ["2e section", "3e section", "4e section"]
	for j in 3:
		_hot(3, Vector3(-1.5 + j * 1.5, 1.5, 2.3), "Tourner la " + names[j], _turn.bind(j + 1), func(): return not s4_done and solved() < 4, 1.6)
	_label(r, "LES MAINS DU DEHORS\nAligne les trois sections :\nla bande jaune doit former un escalier.", Vector3(0, 4.3, -4.7), 0.0, 0.0045)


func _turn(i: int) -> void:
	ring_k[i] = (ring_k[i] + 1) % 4
	var tw := create_tween()
	tw.tween_property(rings[i], "rotation:y", ring_k[i] * PI * 0.5, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(_check4)


func _check4() -> void:
	if s4_done:
		return
	for i in 5:
		if ring_k[i] % 4 != 0:
			return
	s4_done = true
	Fx.text(v.world, ro(3) + Vector3(0, 3.0, 0), "L'ESCALIER SE RECONNECTE", Color(1.0, 0.95, 0.6), 1.1, 3.0)
	_say_ele("Les couloirs vont bouger. Ne regarde pas les murs, c'est impoli.")
	_pico("Je suis redevenu grand. Ou le phare est redevenu petit. Dans les deux cas, ça sent l'arnaque.")
	_later(1.5, _solve.bind(3))


# --- Salle 5 : la chambre du gardien ------------------------------------------------------------------

func _r5(r: Node3D) -> void:
	var b := Builder.new()
	b.box(Vector3(2.2, 0.5, 1.2), Vector3(-5.2, 0.25, -3.8), Color(0.55, 0.38, 0.3), true)
	b.box(Vector3(2.0, 0.2, 1.1), Vector3(-5.2, 0.6, -3.8), Color(0.85, 0.8, 0.9), false)
	b.box(Vector3(2.4, 0.9, 0.9), Vector3(1.0, 0.45, -4.2), Color(0.5, 0.36, 0.28), true)
	b.box(Vector3(0.5, 0.05, 0.4), Vector3(0.4, 0.92, -4.2), Color(0.97, 0.94, 0.85), false, Basis(Vector3.UP, 0.2))
	b.box(Vector3(0.4, 0.07, 0.3), Vector3(1.8, 0.93, -4.2), Color(0.55, 0.2, 0.2), false)
	for k in 5:
		b.box(Vector3(0.7, 0.5, 0.03), Vector3(-2.0 + k * 1.2, 3.0, -4.82), Color(0.93, 0.86, 0.7), false)
	b.box(Vector3(1.2, 1.6, 0.1), Vector3(5.5, 2.5, -4.82), Color(0.35, 0.28, 0.3), false)
	b.box(Vector3(1.0, 1.4, 0.12), Vector3(5.5, 2.5, -4.78), Color(0.1, 0.1, 0.3), false)
	b.build(r, Toon.vertex_color(0.01), "Chambre")
	_label(r, "CARTES · PHOTOS · JOURNAL", Vector3(0, 4.6, -4.7), 0.0, 0.005)
	_hot(4, Vector3(0.4, 1.6, -3.4), "Regarder la vieille photographie", _photo, func(): return not Save.story.get("gphoto", false) or solved() < 5, 1.9)
	_hot(4, Vector3(1.8, 1.6, -3.4), "Lire le journal du gardien", _diary, func(): return not Save.story.get("gdiary", false) or solved() < 5, 1.9)


func _photo() -> void:
	Save.story["gphoto"] = true
	Save.save_game()
	var p := ro(4) + Vector3(0.4, 2.2, -2.8)
	Fx.text(v.world, p, "ARMAND CHARDON · MALO BRINDAVOINE\nPÉTRONILLE (bien plus jeune) · BASILE PLUME", Color(1.0, 0.95, 0.7), 0.6, 5.0)
	_say_ele("Mon père... Et Malo ? Et Pétronille ? Et Basile ?! Ils se connaissaient tous.")
	_pico("Tout le monde sourit sur cette photo. Ça fait toujours un peu peur.")
	_check5()


func _diary() -> void:
	Save.story["gdiary"] = true
	Save.save_game()
	var p := ro(4) + Vector3(1.8, 2.2, -2.8)
	Fx.text(v.world, p, "« Mardi. La page est arrivée.\nJe l'ai accrochée au sommet. »", Color(1.0, 0.95, 0.7), 0.6, 5.0)
	_later(2.0, func(): Fx.text(v.world, p + Vector3(0, -0.4, 0), "« Si quelqu'un la lit, qu'il sache :\naucun retour n'est prévu. »", Color(1.0, 0.8, 0.7), 0.6, 5.0))
	_check5()


func _check5() -> void:
	if Save.story.get("gphoto", false) and Save.story.get("gdiary", false) and solved() < 5:
		_later(2.5, _solve.bind(4))


# --- Salle 6 : le sommet -----------------------------------------------------------------------------

func _r6(r: Node3D) -> void:
	var b := Builder.new()
	for k in 6:
		var a := k * TAU / 6.0
		b.cylinder(0.7, 0.7, 0.2, Vector3(cos(a) * 2.6, 0.2 + (k % 2) * 3.2, sin(a) * 2.6 - 0.0), Color(0.85, 0.7, 0.25).darkened(0.05 * k), Basis(Vector3.RIGHT, PI * 0.5), 12)
	b.cylinder(1.2, 1.4, 0.3, Vector3(0, 0.15, 0), Color(0.3, 0.28, 0.4), Basis(), 14)
	b.build(r, Toon.vertex_color(0.01), "Mecanisme")
	page_node = Node3D.new()
	page_node.name = "Page"
	r.add_child(page_node)
	page_node.position = Vector3(0, 2.5, 0)
	var pb := Builder.new()
	pb.box(Vector3(1.0, 1.4, 0.03), Vector3.ZERO, Color(0.97, 0.94, 0.85), false)
	pb.build(page_node, Toon.vertex_color(0.006), "Mesh")
	page_label = Label3D.new()
	page_label.text = "..."
	page_label.font_size = 40
	page_label.pixel_size = 0.0028
	page_label.outline_size = 0
	page_label.modulate = Color(0.2, 0.1, 0.3)
	page_label.position = Vector3(0, 0, 0.03)
	page_label.double_sided = true
	page_node.add_child(page_label)
	_hot(5, Vector3(0, 1.4, 2.6), "Sortir du phare", exit, func(): return Save.story.get("page1", false), 1.5)


func _page_event() -> void:
	page_done = true
	var nm: String = v._name().to_upper()
	page_label.text = nm
	Fx.text(v.world, ro(5) + Vector3(0, 3.8, 1.0), "La page réagit...", Color(0.9, 0.85, 1.0), 0.9, 3.0)
	_later(2.5, func(): page_label.text = nm + "\n\nRETOUR :\nNON PRÉVU")
	_later(4.0, func(): _say_ele("« Retour » ?"))
	_later(6.0, func(): _pico("J'allais justement poser exactement la même question."))
	_later(8.5, _page_end)


func _page_end() -> void:
	Save.story["page1"] = true
	Save.story["phare_room"] = 6
	Save.story["phare_done"] = true
	Save.save_game()
	Fx.text(v.world, ro(5) + Vector3(0, 3.8, 1.0), "LA PREMIÈRE PAGE DU REGISTRE", Color(1.0, 0.95, 0.5), 1.2, 4.0)
	_later(2.0, func(): Fx.text(v.world, ro(5) + Vector3(0, 3.2, 1.0), "Un symbole... le même qu'au dos de la photo de la plage.", Color(0.9, 0.95, 1.0), 0.6, 5.0))
	_pico("Elle ne se lit pas encore. Mais ce symbole, je l'ai déjà vu. Au dos de la photo. Je le garde pour moi. Pour l'instant.")


# --- Entrée / sortie ----------------------------------------------------------------------------------------

func enter() -> void:
	if busy:
		return
	busy = true
	v._pico("Le cadenas s'ouvre tout seul. Je note que tout s'ouvre tout seul, ici.")
	var tw: Tween = v.maquette._fade_to(0.0, 1.0, 1.0)
	tw.tween_callback(_enter_now)


func _enter_now() -> void:
	if not built:
		_build_scene()
	visible = true
	active = true
	var s := mini(solved(), 5)
	for i in 6:
		if i < solved() and gates[i]:
			_open_gate(i)
	if not Save.story.get("phare_done", false):
		pass
	_spawn_planks()
	_spawn_r3()
	if s == 2 and false:
		pass
	player.global_position = ro(s) + Vector3(-6.0, 0.15, 0)
	player._vy = 0.0
	player._face_yaw(-PI * 0.5)
	player._place_origin(true, 0.0)
	last_room = -1
	var tw: Tween = v.maquette._fade_to(1.0, 0.0, 1.2)
	tw.tween_callback(func():
		busy = false
		Fx.text(v.world, ro(s) + Vector3(-3.0, 3.0, 0), "LE PHARE DE L'ENVERS", Color(1.0, 0.95, 0.7), 1.2, 3.5))


func exit() -> void:
	if busy:
		return
	busy = true
	var tw: Tween = v.maquette._fade_to(0.0, 1.0, 1.0)
	tw.tween_callback(_exit_now)


func _exit_now() -> void:
	active = false
	visible = false
	var lh: Node3D = v.nodes["phare"]
	var dir := Vector3(-0.6, 0, 0.8).normalized()
	var ex: float = lh.global_position.x + dir.x * 4.6
	var ez: float = lh.global_position.z + dir.z * 4.6
	player.global_position = Vector3(ex, Island.height(ex, ez) + 0.4, ez)
	player._vy = 0.0
	player._face_yaw(atan2(-dir.x, -dir.z) + PI)
	player._place_origin(true, 0.0)
	for p in planks:
		if is_instance_valid(p):
			p.queue_free()
	planks.clear()
	if ball and is_instance_valid(ball):
		ball.queue_free()
	var tw: Tween = v.maquette._fade_to(1.0, 0.0, 1.2)
	tw.tween_callback(func(): busy = false)
	v.after_phare()


# --- Boucle ---------------------------------------------------------------------------------------------------------

func _on_room(i: int) -> void:
	_say_ele_for(i)
	if ele:
		ele.global_position = ro(i) + Vector3(-4.8, 0.05, 2.5)
		ele.chibi.rotation.y = 0.0


func _say_ele_for(i: int) -> void:
	if said.has(i):
		return
	said[i] = true
	var lines := [
		"Premier étage. Normalement. Je compte les étages, c'est un défaut de famille.",
		"Quatre fenêtres, une seule vraie. Le village d'aujourd'hui, c'est ce qui est vrai.",
		"Ça penche ! Rien ne doit rouler tout seul dans un phare. Sauf les mauvaises idées.",
		"Les Mains du Dehors... elles sont revenues. Elles aiment les maquettes.",
		"La chambre de mon père. Il n'y a jamais eu de gardien. Tout le monde le sait. Moi aussi.",
		"Le sommet. Pas de lampe. Une page. C'est très cinq étoiles.",
	]
	_later(1.2, func(): _say_ele(lines[i]))
	if i == 0:
		_later(5.0, func(): _pico("Pas d'ennemis. Que des énigmes. C'est le genre de donjon que j'aime : celui où je ne me bats pas."))


func _physics_process(delta: float) -> void:
	if not active or busy:
		return
	var pp: Vector3 = player.global_position
	if pp.y < Y - 6.0:
		player.global_position = ro(clampi(solved(), 0, 5)) + Vector3(-6.0, 0.2, 0)
		return
	var c := cur()
	if c != last_room:
		last_room = c
		_on_room(c)
	# Salle 1 : la boucle de l'escalier
	if c == 0 and not stairs_fixed and pp.y > Y + 2.1 and pp.x > ro(0).x + 2.5:
		loops += 1
		player.global_position = ro(0) + Vector3(-4.6, 0.2, -3.5)
		player._vy = 0.0
		Fx.text(v.world, player.global_position + Vector3(0, 1.8, 1.0), "Étage 1... encore.", Color(1.0, 0.9, 0.7), 0.9, 1.8)
		if loops == 2:
			_say_ele("Les tableaux. Ils ne sont jamais tout à fait pareils.")
		if loops == 4:
			_pico("On monte, on monte, et on est toujours en bas. Même moi, je trouve ça étrange.")
	# Salle 3 : la boule
	if c == 2 and not ball_done and ball and is_instance_valid(ball):
		ball_t += delta
		hint3 += delta
		var lp: Vector3 = ball.global_position - ro(2)
		if lp.x < -1.5 and lp.x > -7.2 and lp.z > 3.0:
			ball_done = true
			ball.freeze = true
			Fx.text(v.world, ball.global_position + Vector3(0, 1.0, 0), "CLIC !", Color(1.0, 0.95, 0.5), 1.0, 1.5)
			_say_ele("Un mécanisme qui adore les boules. Je me sens moins seule.")
			_later(1.0, _solve.bind(2))
		elif ball_t > 9.0 or lp.y < -1.5 or absf(lp.x) > 8.0:
			_spawn_r3()
		if hint3 > 40.0:
			hint3 = 0.0
			_pico("Une planche posée en biais renvoie la boule de côté. Je le sais parce que je suis un papier : je glisse très bien.")
	if c == 2:
		for p in planks:
			if is_instance_valid(p) and not p.freeze and not _held(p) and p.linear_velocity.length() < 0.15 and p.global_position.distance_to(ro(2)) < 9.0 and p.global_position.y > Y - 1.0:
				var xf: Transform3D = p.global_transform
				p.freeze = true
				p.global_transform = xf
	# Salle 6 : la page
	if c == 5 and not page_done and not Save.story.get("page1", false):
		var d: float = (pp - (ro(5) + Vector3(0, 0, 0))).length()
		if d < 3.4 and solved() >= 5:
			_page_event()
	if page_node:
		page_node.rotation.y = sin(Time.get_ticks_msec() / 900.0) * 0.25
