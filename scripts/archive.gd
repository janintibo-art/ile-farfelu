extends Node3D
## L'Archive Engloutie : le donjon du chapitre 3 (aucun ennemi), très haut dans le ciel (y = 800).
## Cinq salles à la suite :
##   1. la salle des marées (régler le niveau de l'eau dans le bon ordre)
##   2. les souvenirs côte à côte (assembler les bulles qui se complètent)
##   3. la bulle-clé (l'eau la fait monter, mais pas trop)
##   4. la galerie du Cartographe (écouter trois souvenirs)
##   5. Basile Plume (première rencontre, indirecte)
## La progression est sauvegardée (Save.story["ar_room"]).

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Fx := preload("res://scripts/fx.gd")
const Save := preload("res://scripts/save.gd")
const Characters := preload("res://scripts/characters.gd")
const Talker := preload("res://scripts/talker.gd")
const ChoiceBtn := preload("res://scripts/choice_button.gd")

const Y := 800.0
const X0 := -36.0
const DX := 18.0
const WALLS := [Color(0.62, 0.72, 0.85), Color(0.7, 0.8, 0.8), Color(0.62, 0.7, 0.78), Color(0.72, 0.68, 0.85), Color(0.85, 0.82, 0.9)]
const LEVELS := [0.12, 1.5, 3.0]
const TIDE_SEQ := [0, 2, 1]
const FRAGS := [
	["…la clé sous le pot", 0], ["…lettre sans adresse", 1], ["…fenêtre sur la mer", 2],
	["…le pot de basilic", 0], ["…pleurait à la fenêtre", 2], ["…une lettre sans fin", 1],
]

var v
var player
var built := false
var active := false
var busy := false
var gates: Array = []
var ele
var bas
var last_room := -1
var said := {}
var water := {}
var level := {0: 1, 2: 0}
var tide_prog := 0
var tide_fail := 0
var frag_btns: Array = []
var frag_done: Array = [false, false, false, false, false, false]
var frag_sel := -1
var frag_matched := 0
var key_node: MeshInstance3D
var key_btn: ChoiceBtn
var heard := {}
var asked := {}
var talk_ready := false
var talk_over := false


func setup(p_village, p_player) -> void:
	v = p_village
	player = p_player
	visible = false


func ro(i: int) -> Vector3:
	return Vector3(X0 + DX * i, Y, 0.0)


func cur() -> int:
	return clampi(int(floor((player.global_position.x - X0 + DX * 0.5) / DX)), 0, 4)


func solved() -> int:
	return int(Save.story.get("ar_room", 0))


func _s(k: String) -> bool:
	return Save.story.get(k, false)


func _later(t: float, c: Callable) -> void:
	v.get_tree().create_timer(t).timeout.connect(c)


func _say_ele(t: String) -> void:
	if ele:
		ele.chibi.say(t, 2.5 + t.length() * 0.055)


func _say_bas(t: String) -> void:
	if bas:
		bas.chibi.say(t, 2.5 + t.length() * 0.055)


func _pico(t: String) -> void:
	v._pico(t)


func _hot(i: int, pos: Vector3, text: String, cb: Callable, cond: Callable, width := 1.7) -> ChoiceBtn:
	v.x.hotspot(get_child(i), pos, text, cb, func(): return active and not busy and cur() == i and cond.call(), width, 3.8)
	return v.x.hot.back()["btn"]


## Joue une suite de répliques [qui, texte] ("b" Basile, "e" Éléonore, "p" Pico), puis appelle done.
func _seq(lines: Array, done: Callable) -> void:
	busy = true
	var t := 0.6
	for l in lines:
		_later(t, _line.bind(l[0], l[1]))
		t += 2.5 + String(l[1]).length() * 0.055 + 0.7
	_later(t, _seq_end.bind(done))


func _line(who: String, text: String) -> void:
	match who:
		"b":
			_say_bas(text)
		"e":
			_say_ele(text)
		_:
			_pico(text)


func _seq_end(done: Callable) -> void:
	busy = false
	if done.is_valid():
		done.call()


func _noop() -> void:
	pass


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
	ele.name = "EleonoreArchive"
	add_child(ele)
	ele.setup(v, player, Characters.ELEONORE)
	ele.rest_yaw = -PI * 0.5
	bas = Talker.new()
	bas.name = "BasilePlume"
	add_child(bas)
	bas.setup(v, player, Characters.BASILE_PLUME)
	bas.rest_yaw = PI * 0.5
	bas.visible = false
	bas.position = ro(4) + Vector3(2.8, 0.05, 0.0)


func _shell(r: Node3D, i: int) -> void:
	var b := Builder.new()
	var wc: Color = WALLS[i]
	var h := 6.0
	b.box(Vector3(15, 0.4, 10), Vector3(0, -0.2, 0), Color(0.42, 0.45, 0.55), true)
	b.box(Vector3(15, 0.2, 10), Vector3(0, h + 0.1, 0), wc.darkened(0.3), true)
	b.box(Vector3(15, h, 0.3), Vector3(0, h * 0.5, -5.0), wc, true)
	b.box(Vector3(15, h, 0.3), Vector3(0, h * 0.5, 5.0), wc, true)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(0.3, h, 4.0), Vector3(sx * 7.35, h * 0.5, -3.0), wc, true)
		b.box(Vector3(0.3, h, 4.0), Vector3(sx * 7.35, h * 0.5, 3.0), wc, true)
		b.box(Vector3(0.3, h - 2.6, 2.0), Vector3(sx * 7.35, 2.6 + (h - 2.6) * 0.5, 0), wc, true)
	# Étagères de livres le long des murs sud
	var rng := RandomNumberGenerator.new()
	rng.seed = 100 + i
	for row in 4:
		b.box(Vector3(13.0, 0.08, 0.5), Vector3(0, 1.0 + row * 1.2, 4.7), Color(0.4, 0.3, 0.25), false)
		var x := -6.4
		while x < 6.4:
			var w := rng.randf_range(0.12, 0.3)
			var hh := rng.randf_range(0.6, 1.0)
			b.box(Vector3(w, hh, 0.35), Vector3(x + w * 0.5, 1.04 + row * 1.2 + hh * 0.5, 4.7), Color.from_hsv(rng.randf(), 0.35, 0.8), false)
			x += w + 0.02
	b.build(r, Toon.vertex_color(0.01), "Shell")
	var lt := OmniLight3D.new()
	lt.omni_range = 14.0
	lt.light_energy = 1.2
	lt.light_color = Color(0.85, 0.95, 1.0)
	r.add_child(lt)
	lt.position = Vector3(0, 5.0, 0)
	var g := Node3D.new()
	g.name = "Gate"
	r.add_child(g)
	var gb := Builder.new()
	for k in 5:
		gb.box(Vector3(0.12, 2.6, 0.12), Vector3(7.3, 1.3, -0.8 + k * 0.4), Color(0.3, 0.4, 0.55), true)
	gb.box(Vector3(0.14, 0.14, 2.0), Vector3(7.3, 1.3, 0), Color(0.3, 0.4, 0.55), false)
	gb.build(g, Toon.vertex_color(0.01), "Bars")
	gates.append(g)
	_label(r, "SALLE %d" % (i + 1), Vector3(-7.1, 4.6, -1.8), PI * 0.5, 0.012, Color(0.15, 0.2, 0.35))


func _label(parent: Node3D, text: String, pos: Vector3, yaw := 0.0, px := 0.004, col := Color(0.12, 0.15, 0.3)) -> Label3D:
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
		b.box(Vector3(3.0, 0.4, 2.0), Vector3(cx, Y - 0.2, 0), Color(0.4, 0.42, 0.5), true)
		b.box(Vector3(3.0, 0.2, 2.0), Vector3(cx, Y + 3.0, 0), Color(0.4, 0.42, 0.5), true)
		for sz in [-1.0, 1.0]:
			b.box(Vector3(3.0, 3.0, 0.2), Vector3(cx, Y + 1.5, sz * 1.0), Color(0.7, 0.75, 0.82), true)
	b.build(self, Toon.vertex_color(0.01), "Corridors")


func _open_gate(i: int) -> void:
	if i >= gates.size():
		return
	var g: Node3D = gates[i]
	if g and is_instance_valid(g):
		Fx.puff(v.world, g.global_position + Vector3(0, 1.2, 0), Color(0.8, 0.95, 1.0))
		g.queue_free()
	gates[i] = null


func _solve(i: int) -> void:
	_open_gate(i)
	Save.story["ar_room"] = maxi(solved(), i + 1)
	Save.save_game()
	Fx.text(v.world, ro(i) + Vector3(6.0, 2.5, 0), "PORTE OUVERTE", Color(0.7, 1.0, 0.75), 1.0, 2.5)


func _mk_water(r: Node3D, lv: int) -> void:
	var m := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(14.4, 9.4)
	m.mesh = pm
	var mt := StandardMaterial3D.new()
	mt.albedo_color = Color(0.3, 0.6, 0.85, 0.42)
	mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mt.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.material_override = mt
	r.add_child(m)
	m.position = Vector3(0, LEVELS[lv], 0)
	water[r.get_index()] = m


func _level_buttons(i: int, cond: Callable) -> void:
	var names := ["Eau : BASSE", "Eau : MOYENNE", "Eau : HAUTE"]
	for k in 3:
		_hot(i, Vector3(-2.4 + k * 2.4, 1.2, 3.9), names[k], _set_level.bind(i, k), cond, 1.9)


func _set_level(i: int, k: int) -> void:
	var cur_l: int = int(level[i])
	if k == cur_l:
		return
	level[i] = k
	var tw := create_tween()
	tw.tween_property(water[i], "position:y", LEVELS[k], 1.2).set_trans(Tween.TRANS_SINE)
	Fx.text(v.world, ro(i) + Vector3(0, 3.8, 3.0), ["La marée recule...", "L'eau se calme.", "La marée monte !"][k], Color(0.7, 0.9, 1.0), 0.6, 2.0)
	if i == 0:
		_tide_check(k)
	else:
		_key_move()


# --- Salle 1 : les marées -----------------------------------------------------------------------------

func _r1(r: Node3D) -> void:
	_mk_water(r, 1)
	_label(r, "SALLE DES MARÉES\nLes souvenirs se lisent à marée juste.", Vector3(0, 5.0, -4.68), 0.0, 0.0055)
	_label(r, "« La mer a d'abord reculé jusqu'au sol.\nPuis elle est revenue jusqu'au plafond.\nEnfin elle s'est arrêtée au milieu. »", Vector3(0, 3.0, -4.68), 0.0, 0.0045)
	_level_buttons(0, func(): return solved() < 1)
	_hot(0, Vector3(-6.0, 1.2, -3.0), "Sortir de l'Archive", func(): exit(), func(): return true, 1.8)


func _tide_check(k: int) -> void:
	if tide_prog < TIDE_SEQ.size() and k == TIDE_SEQ[tide_prog]:
		tide_prog += 1
		Fx.puff(v.world, ro(0) + Vector3(0, 1.5, -3.0), Color(0.7, 0.9, 1.0))
		if tide_prog >= TIDE_SEQ.size():
			_later(1.4, _tide_done)
	else:
		tide_prog = 1 if k == TIDE_SEQ[0] else 0
		tide_fail += 1
		if tide_fail == 3:
			_later(1.4, func(): _say_ele("Lis la plaque : d'abord le sol, puis le plafond, puis le milieu. La mer raconte dans l'ordre."))


func _tide_done() -> void:
	_say_ele("La mer a dit son histoire dans l'ordre. Elle est plus polie que la forêt.")
	_solve(0)


# --- Salle 2 : les souvenirs côte à côte -------------------------------------------------------------

func _r2(r: Node3D) -> void:
	_label(r, "DEUX SOUVENIRS QUI PARLENT\nDE LA MÊME CHOSE SE COMPLÈTENT.", Vector3(0, 5.0, -4.68), 0.0, 0.0055)
	_label(r, "(un souvenir seul n'ouvre aucune porte)", Vector3(0, 4.3, -4.68), 0.0, 0.003)
	var order := [0, 1, 2, 3, 4, 5]
	for k in 6:
		var c := k % 3
		var row := k / 3
		var bt := _hot(1, Vector3((c - 1) * 2.6, 2.4 - row * 0.5, -3.9), FRAGS[order[k]][0], _frag.bind(k), func(): return solved() < 2 and not frag_done[k], 2.4)
		frag_btns.append(bt)
	_hot(1, Vector3(-6.0, 1.2, -3.0), "Sortir de l'Archive", func(): exit(), func(): return true, 1.8)


func _frag(k: int) -> void:
	if frag_done[k]:
		return
	if frag_sel < 0:
		frag_sel = k
		frag_btns[k].label.text = "▶ " + FRAGS[k][0]
		return
	if frag_sel == k:
		frag_btns[k].label.text = FRAGS[k][0]
		frag_sel = -1
		return
	var a: int = frag_sel
	frag_btns[a].label.text = FRAGS[a][0]
	frag_sel = -1
	if FRAGS[a][1] == FRAGS[k][1]:
		frag_done[a] = true
		frag_done[k] = true
		frag_matched += 1
		Fx.puff(v.world, ro(1) + Vector3(0, 2.0, -3.0), Color(0.8, 0.95, 1.0))
		Fx.text(v.world, ro(1) + Vector3(0, 3.6, -3.0), "ILS SE COMPLÈTENT", Color(0.7, 1.0, 0.75), 0.7, 2.0)
		if frag_matched >= 3:
			_later(1.2, _frags_done)
	else:
		Fx.text(v.world, ro(1) + Vector3(0, 3.6, -3.0), "Ces deux-là ne parlent pas de la même chose.", Color(1.0, 0.85, 0.7), 0.55, 2.5)


func _frags_done() -> void:
	_say_ele("Un pot, une lettre, une fenêtre. Trois histoires entières. Mon père classait toujours par ce qui manque.")
	_solve(1)


# --- Salle 3 : la bulle-clé ----------------------------------------------------------------------------

func _r3(r: Node3D) -> void:
	_mk_water(r, 0)
	var b := Builder.new()
	for sx in [-0.5, 0.5]:
		for sz in [-0.5, 0.5]:
			b.box(Vector3(0.06, 0.9, 0.06), Vector3(3.0 + sx, 0.45, -2.0 + sz), Color(0.3, 0.35, 0.5), false)
	b.box(Vector3(1.2, 0.06, 1.2), Vector3(3.0, 0.9, -2.0), Color(0.3, 0.35, 0.5), false)
	b.build(r, Toon.vertex_color(0.01), "Cage")
	key_node = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.28
	sm.height = 0.56
	key_node.mesh = sm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.85, 0.3, 0.75)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	key_node.material_override = m
	r.add_child(key_node)
	key_node.position = Vector3(3.0, LEVELS[0] + 0.45, -2.0)
	_label(r, "UNE BULLE MONTE AVEC L'EAU.\nTROP BAS : ELLE SE COGNE AU FOND.\nTROP HAUT : ELLE SE COINCE AU PLAFOND.", Vector3(0, 4.6, -4.68), 0.0, 0.0048)
	_level_buttons(2, func(): return solved() < 3)
	key_btn = _hot(2, Vector3(3.0, 1.9, -2.0), "Saisir la bulle-clé", _take_key, func(): return not _s("ar_key") and int(level[2]) == 1, 1.9)
	_hot(2, Vector3(6.0, 1.3, 1.6), "Ouvrir avec la bulle-clé", _use_key, func(): return _s("ar_key") and solved() < 3, 2.1)
	_hot(2, Vector3(-6.0, 1.2, -3.0), "Sortir de l'Archive", func(): exit(), func(): return true, 1.8)


func _key_move() -> void:
	if key_node == null or _s("ar_key"):
		return
	var k: int = int(level[2])
	var yy: float = LEVELS[k] + (0.45 if k == 0 else 0.35)
	if k == 2:
		yy = 5.2
	var tw := create_tween()
	tw.tween_property(key_node, "position:y", yy, 1.2).set_trans(Tween.TRANS_SINE)
	if k == 1:
		_later(1.4, func(): Fx.text(v.world, ro(2) + Vector3(3.0, 3.0, -2.0), "La bulle flotte à hauteur de main.", Color(0.9, 0.95, 1.0), 0.5, 3.0))
	elif k == 2:
		_later(1.4, func(): Fx.text(v.world, ro(2) + Vector3(3.0, 5.6, -2.0), "Coincée au plafond. Trop haut.", Color(1.0, 0.85, 0.7), 0.5, 3.0))


func _take_key() -> void:
	Save.story["ar_key"] = true
	Save.save_game()
	key_node.visible = false
	Fx.text(v.world, ro(2) + Vector3(3.0, 2.2, -2.0), "BULLE-CLÉ !", Color(1.0, 0.9, 0.4), 1.0, 2.5)
	_say_ele("Une clé faite de souvenirs. Elle ouvre sûrement la porte d'où elle vient.")


func _use_key() -> void:
	Fx.text(v.world, ro(2) + Vector3(6.0, 2.6, 1.6), "CLIC ! La serrure se souvient.", Color(0.7, 1.0, 0.75), 0.9, 3.0)
	_solve(2)


# --- Salle 4 : la galerie du Cartographe ---------------------------------------------------------------

func _r4(r: Node3D) -> void:
	var b := Builder.new()
	for k in 3:
		var x := -4.0 + k * 4.0
		b.box(Vector3(1.4, 1.8, 0.1), Vector3(x, 2.2, -4.78), Color(0.9, 0.85, 0.7), false)
		b.sphere(0.32, Vector3(x, 1.2, -4.0), [Color(0.55, 0.8, 1.0), Color(0.75, 0.6, 1.0), Color(1.0, 0.85, 0.5)][k], Vector3.ONE, Basis(), 10)
	b.build(r, Toon.vertex_color(0.01), "Galerie")
	_label(r, "GALERIE DU CARTOGRAPHE\nTrois souvenirs, trois fois la même voix.", Vector3(0, 5.0, -4.68), 0.0, 0.0055)
	var names := ["I", "II", "III"]
	for k in 3:
		_hot(3, Vector3(-4.0 + k * 4.0, 1.9, -3.7), "Écouter la bulle " + names[k], _listen.bind(k), func(): return not heard.has(k) or solved() < 4, 1.9)
	_hot(3, Vector3(-6.0, 1.2, -3.0), "Sortir de l'Archive", func(): exit(), func(): return true, 1.8)


func _listen(k: int) -> void:
	var p := ro(3) + Vector3(-4.0 + k * 4.0, 3.4, -3.4)
	var seqs := [
		[["x", "(deux jeunes voix) « Basile, regarde : l'île bouge quand on la raconte ! » — « Alors racontons-la bien. »"], ["p", "Basile. Encore lui. Il avait l'air plus jeune. Et plus content."]],
		[["x", "« Si on la fige, elle ne bouge plus. » — « Mais elle ne pleurera plus. » — « Elle ne rira plus non plus. »"], ["e", "Mon père et Basile. Ils étaient amis. Je l'ignorais. Il n'en parlait jamais."]],
		[["x", "(le Cartographe, seul) « Éléonore a trois ans. Je n'ai pas le droit de le lui dire. Qu'elle cherche toute seule. »"], ["e", "Il savait que je viendrais. Il m'a laissé un chemin plein de pièges. C'est mal élevé. C'est tout lui."]],
	]
	var cols := [Color(0.7, 0.9, 1.0), Color(0.85, 0.75, 1.0), Color(1.0, 0.9, 0.6)]
	heard[k] = true
	Fx.text(v.world, p, seqs[k][0][1], cols[k], 0.5, 8.0)
	_later(3.0, func(): _line(seqs[k][1][0], seqs[k][1][1]))
	if heard.size() >= 3 and solved() < 4:
		_later(8.5, _gallery_done)


func _gallery_done() -> void:
	if solved() >= 4:
		return
	_say_ele("Il y a quelqu'un dans la dernière salle. Je sens... une version officielle de quelqu'un.")
	_solve(3)


# --- Salle 5 : Basile Plume ----------------------------------------------------------------------------

func _r5(r: Node3D) -> void:
	var b := Builder.new()
	b.cylinder(0.9, 1.0, 0.3, Vector3(2.8, 0.15, 0), Color(0.85, 0.85, 0.95), Basis(), 12)
	b.box(Vector3(3.4, 2.4, 0.1), Vector3(2.8, 1.5, -4.78), Color(0.95, 0.92, 0.82), false)
	b.build(r, Toon.vertex_color(0.01), "Socle")
	_label(r, "LA VERSION OFFICIELLE", Vector3(2.8, 3.1, -4.68), 0.0, 0.0045)
	var qs := [
		["Vous savez ce qui arrive aux souvenirs ?", Vector3(-1.5, 1.7, 2.2)],
		["Arrêter, c'est figer.", Vector3(-1.5, 1.35, 2.2)],
		["Et le Grand Cartographe ?", Vector3(-1.5, 1.0, 2.2)],
	]
	for k in 3:
		_hot(4, qs[k][1], qs[k][0], _ask.bind(k), func(): return talk_ready and not asked.has(k) and not talk_over, 2.7)
	_hot(4, Vector3(-6.0, 1.2, -3.0), "Sortir de l'Archive", func(): exit(), func(): return true, 1.8)


func _meet() -> void:
	if talk_ready or talk_over or _s("ch3_done"):
		return
	bas.visible = true
	Fx.puff(v.world, ro(4) + Vector3(2.8, 1.0, 0.0), Color(0.9, 0.9, 1.0))
	_seq([
		["b", "Bonsoir. Excusez la projection : je n'aime pas me déplacer, et l'eau abîme les chaussures."],
		["b", "Basile Plume, Conservateur Général de l'Île. Vous avez rendu des souvenirs à Brumelune. C'est très bien, et très inquiétant."],
		["e", "C'est vous qui avez demandé à la forêt de répéter que mon père n'existait pas."],
		["b", "Pas exactement. Mais je comprends pourquoi on y a pensé. Posez-moi vos questions. Je suis plus aimable qu'on ne le dit."],
	], _ready_talk)


func _ready_talk() -> void:
	talk_ready = true


func _ask(k: int) -> void:
	asked[k] = true
	var lines: Array = []
	match k:
		0:
			lines = [
				["b", "Parfaitement. Les histoires changent, les souvenirs passent d'une tête à l'autre. Je cherche un moyen de l'arrêter. Définitivement."],
				["b", "Pour que plus personne ne pleure pour un homme qu'il n'a pas connu."],
			]
		1:
			var hort := str(Save.story.get("b_hortense", ""))
			lines = [["b", "Figer ? Protéger. Une chose qui ne change plus ne peut plus être perdue."]]
			if hort == "give":
				lines.append(["b", "Vous avez rendu à Hortense toute sa peine. Était-ce vraiment un cadeau ?"])
			elif hort == "keep":
				lines.append(["b", "Vous avez laissé Léo porter la peine d'un autre. C'est... une forme de conservation. Je l'approuve presque."])
			else:
				lines.append(["b", "Vous avez partagé la mémoire d'Aristide. Voilà exactement ce qu'on ne peut pas garantir : qu'un partage ne s'use pas."])
			lines.append(["p", "Raisonnable. C'est le problème : il est raisonnable."])
		_:
			lines = [
				["b", "Un ami. Un très cher ami. Nous n'avions pas la même peur : lui craignait qu'elle s'arrête, moi qu'elle disparaisse."],
				["b", "Les cloches de Belloche se sont tues. Ce n'est pas moi. Mais ça arrangera peut-être quelqu'un. Venez au château quand vous serez prêts. Le bal est à l'heure."],
			]
	_seq(lines, _after_ask)


func _after_ask() -> void:
	if asked.size() >= 3 and not talk_over:
		talk_over = true
		_seq([
			["b", "À bientôt. Ou à tout à l'heure : ici, c'est presque pareil."],
			["e", "Il croit vraiment ce qu'il dit. C'est ça qui est terrible."],
		], _finish)


func _finish() -> void:
	Fx.puff(v.world, ro(4) + Vector3(2.8, 1.0, 0.0), Color(0.9, 0.9, 1.0))
	bas.visible = false
	Save.story["ch3_done"] = true
	Save.shells += 40
	Save.save_game()
	Fx.text(v.world, ro(4) + Vector3(0, 3.4, 0), "CHAPITRE 3 TERMINÉ", Color(1.0, 0.95, 0.5), 1.6, 6.0)
	Fx.text(v.world, ro(4) + Vector3(0, 2.4, 0), "+40 coquillages", Color(1.0, 0.9, 0.5), 0.8, 4.0)
	_later(4.0, func(): Fx.text(v.world, ro(4) + Vector3(0, 2.9, 0), "À suivre : Belloche, la ville qui perdit sa musique...", Color(0.9, 0.95, 1.0), 0.7, 6.0))


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
	Fx.text(v.world, ro(s) + Vector3(-3.0, 3.0, 0), "L'ARCHIVE ENGLOUTIE", Color(0.85, 0.95, 1.0), 1.2, 3.5)


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
	player.global_position = Vector3(0.0, 700.1, -21.0)
	player._vy = 0.0
	player._face_yaw(0.0)
	player._place_origin(true, 0.0)
	var tw2: Tween = v.maquette._fade_to(1.0, 0.0, 1.2)
	tw2.tween_callback(_unbusy)


# --- Boucle --------------------------------------------------------------------------------------------

func _on_room(i: int) -> void:
	if said.has(i):
		return
	said[i] = true
	var lines := [
		"L'Archive Engloutie. Les souvenirs qu'on n'a pas osé réclamer finissent ici, au sec... enfin, tout est relatif.",
		"Des bulles. Elles aiment qu'on les range par ce dont elles parlent. Mon père faisait pareil.",
		"Une clé en souvenir. Je préfère ça aux clés en métal : elle ne rouille pas, elle se trompe d'époque.",
		"Mon père est passé par ici. Je reconnais son écriture sur les étagères. Il notait « à rendre » partout.",
		"Quelqu'un nous attend. Quelqu'un de calme. C'est le pire genre.",
	]
	_later(1.2, func(): _say_ele(lines[i]))
	if ele:
		ele.global_position = ro(i) + Vector3(-4.8, 0.05, 2.5)
		ele.chibi.rotation.y = 0.0
	if i == 4:
		_later(2.5, _meet)


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
