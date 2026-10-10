extends Node3D
## Le Grand Registre : chapitre 7 « Tout ce qui mérite d'être oublié » et dernier donjon,
## très haut dans le ciel (y = 1400). On entre dans le livre qui contient l'île.
##   1. Les Déchirures : trois morceaux de monde à recoudre avec le bon symbole.
##   2. La Table des Histoires : choisir SEPT histoires qui méritent d'être gardées.
##   3. La Dernière Page : Basile, Lina, et le dernier choix (Conserver / Libérer / Continuer l'histoire).
## « Continuer l'histoire » n'apparaît que si au moins trois des sept histoires choisies
## sont des petites histoires d'habitants (quêtes secondaires).

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Fx := preload("res://scripts/fx.gd")
const Save := preload("res://scripts/save.gd")
const Island := preload("res://scripts/island.gd")
const Characters := preload("res://scripts/characters.gd")
const Talker := preload("res://scripts/talker.gd")
const ChoiceBtn := preload("res://scripts/choice_button.gd")
const Bells := preload("res://scripts/bells.gd")

const Y := 1400.0
const X0 := -18.0
const DX := 18.0
const PAPER := Color(0.86, 0.84, 0.78)
const INK := Color(0.2, 0.18, 0.3)
const GOLD := Color(0.95, 0.78, 0.3)
const WALLS := [Color(0.9, 0.92, 1.0), Color(1.0, 0.94, 0.85), Color(1.0, 0.9, 0.93)]

## Les déchirures : [titre, indice, [symboles], bon symbole]
const TEARS := [
	{"hint": "« Là où le mardi a disparu »", "sym": ["Un phare", "Une horloge", "Une pâtisserie"], "ok": 0, "col": Color(0.95, 0.75, 0.35)},
	{"hint": "« Là où deux familles se disputent un pont »", "sym": ["Un arbre", "Un pont", "Un puits"], "ok": 1, "col": Color(0.55, 0.85, 0.5)},
	{"hint": "« Là où les souvenirs flottent »", "sym": ["Une plume", "Une chaise", "Une bulle"], "ok": 2, "col": Color(0.55, 0.8, 0.95)},
]

## Les histoires : [flag, titre court, ce qu'on se rappelle, petite histoire d'habitant ?]
const STORIES := [
	["ch1_done", "Le mardi retrouvé", "Une journée effacée pour retrouver un père.", false],
	["pont_ok", "Le pont de Virevolte", "Deux familles, un pont, une même écriture.", false],
	["b_done", "Les bulles de Brumelune", "Des souvenirs rendus, ou refusés.", false],
	["k_done", "Les cloches de Belloche", "Le village qui a retrouvé sa voix.", false],
	["h_done", "Les minutes de Hautes-Miettes", "Un homme qui rendait le temps.", false],
	["ch6_done", "Lina et son phare", "Une enfant, un dessin, une phrase répétée.", false],
	["pico_page", "Pico, la page vivante", "Un petit être de papier qui chante faux.", false],
	["fish_solved", "Le poisson rancunier", "Quinze ans de rancune, enfin finis.", true],
	["door_open", "La porte sans maison", "Elle a ouvert sur rien. C'était déjà beaucoup.", true],
	["portrait_ok", "Le portrait consolé", "Le peintre n'avait que du vert.", true],
	["rien_gift", "Le Marchand de Rien", "Cinq achats de rien, un cadeau de tout.", true],
	["bouton_ok", "Le bouton « NE PAS APPUYER »", "Quelqu'un a fini par appuyer.", true],
	["plank_given", "La planche de Gérard", "Une planche passée de main en main.", true],
]

var v
var player
var built := false
var active := false
var busy := false
var gates: Array = []
var ele
var bas
var lina
var last_room := -1
var said := {}
var chosen: Array = []
var _ret := Vector3.ZERO
var _tear_nodes: Array = []
var _sealed: Array = [false, false, false]
var _story_btns: Array = []
var _count_lbl: Label3D
var _avail_lbl: Label3D
var _avail_n := -1
var _final_on := false
var _choice_on := false
var _hint_n := 0
var _t := 0.0
var _floaters: Array = []


func setup(p_village, p_player) -> void:
	v = p_village
	player = p_player
	visible = false


func ro(i: int) -> Vector3:
	return Vector3(X0 + DX * i, Y, 0.0)


func cur() -> int:
	return clampi(int(floor((player.global_position.x - X0 + DX * 0.5) / DX)), 0, 2)


func solved() -> int:
	return int(Save.story.get("r_room", 0))


func _s(k: String) -> bool:
	return Save.story.get(k, false)


func _flag(k: String) -> void:
	Save.story[k] = true
	Save.save_game()


func _later(t: float, c: Callable) -> void:
	v.get_tree().create_timer(t).timeout.connect(c)


func _pico(t: String) -> void:
	v._pico(t)


func _say_ele(t: String) -> void:
	if ele:
		ele.chibi.say(t, 2.5 + t.length() * 0.055)


func _hot(i: int, pos: Vector3, text: String, cb: Callable, cond: Callable, width := 1.8, dist := 3.8) -> ChoiceBtn:
	v.x.hotspot(get_child(i), pos, text, cb, func(): return active and not busy and cur() == i and cond.call(), width, dist)
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
		"b":
			bas.chibi.say(text, d)
		"l":
			lina.chibi.say(text, d)
		"t":
			Fx.text(v.world, ro(cur()) + Vector3(0, 3.6, -1.5), text, Color(1.0, 0.95, 0.8), 0.6, d)
		_:
			_pico(text)


func _seq_end(done: Callable) -> void:
	busy = false
	if done.is_valid():
		done.call()


func _label(parent: Node3D, text: String, pos: Vector3, yaw := 0.0, px := 0.004, col := INK) -> Label3D:
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


func _person(id: String, def: Dictionary, room: int, pos: Vector3, yaw: float) -> Talker:
	var t := Talker.new()
	t.name = id.capitalize()
	get_child(room).add_child(t)
	t.position = pos
	t.setup(v, player, def)
	t.rest_yaw = yaw
	return t


func _story_ok(i: int) -> bool:
	return _s(STORIES[i][0])


# --- Construction -------------------------------------------------------------------------------

func _build_scene() -> void:
	built = true
	for i in 3:
		var r := Node3D.new()
		r.name = "Page%d" % (i + 1)
		add_child(r)
		r.position = ro(i)
		_shell(r, i)
	_corridors()
	_r1(get_child(0))
	_r2(get_child(1))
	_r3(get_child(2))
	ele = Talker.new()
	ele.name = "EleonoreRegistre"
	add_child(ele)
	ele.setup(v, player, Characters.ELEONORE)
	ele.rest_yaw = -PI * 0.5


func _shell(r: Node3D, i: int) -> void:
	var b := Builder.new()
	var wc: Color = WALLS[i]
	b.box(Vector3(15, 0.4, 10), Vector3(0, -0.2, 0), PAPER, true)
	# lignes d'un cahier
	for k in 7:
		b.box(Vector3(14.6, 0.02, 0.04), Vector3(0, 0.01, -4.2 + k * 1.4), Color(0.7, 0.8, 0.95), false)
	b.box(Vector3(0.04, 0.02, 9.6), Vector3(-6.4, 0.012, 0), Color(0.95, 0.6, 0.6), false)
	# rebords (le livre est ouvert sur le vide)
	var h := 1.5
	b.box(Vector3(15, h, 0.3), Vector3(0, h * 0.5, 5.0), wc, true)
	b.box(Vector3(15, h, 0.3), Vector3(0, h * 0.5, -5.0), wc, true)
	for sx in [-1.0, 1.0]:
		var open_side: bool = (sx < 0.0 and i > 0) or (sx > 0.0 and i < 2)
		if open_side:
			b.box(Vector3(0.3, h, 4.0), Vector3(sx * 7.35, h * 0.5, -3.0), wc, true)
			b.box(Vector3(0.3, h, 4.0), Vector3(sx * 7.35, h * 0.5, 3.0), wc, true)
		else:
			b.box(Vector3(0.3, h, 10.0), Vector3(sx * 7.35, h * 0.5, 0), wc, true)
	b.build(r, Toon.vertex_color(0.01), "Shell")
	var lt := OmniLight3D.new()
	lt.omni_range = 18.0
	lt.light_energy = 0.8
	lt.light_color = Color(1.0, 0.98, 0.92)
	r.add_child(lt)
	lt.position = Vector3(0, 5.5, 0)
	var g: Node3D = null
	if i < 2:
		g = Node3D.new()
		g.name = "Gate"
		r.add_child(g)
		var gb := Builder.new()
		for k in 5:
			gb.box(Vector3(0.12, 2.6, 0.12), Vector3(7.3, 1.3, -0.8 + k * 0.4), Color(0.6, 0.5, 0.3), true)
		gb.box(Vector3(0.14, 0.14, 2.0), Vector3(7.3, 1.3, 0), Color(0.6, 0.5, 0.3), false)
		gb.build(g, Toon.vertex_color(0.01), "Bars")
	gates.append(g)
	var names := ["LES DÉCHIRURES", "LA TABLE DES HISTOIRES", "LA DERNIÈRE PAGE"]
	_label(r, names[i], Vector3(-7.1, 3.2, -2.8), PI * 0.5, 0.011, Color(0.35, 0.3, 0.5))
	_decor(r, i)


func _decor(r: Node3D, i: int) -> void:
	# des morceaux du monde qui flottent derrière la page (hors de portée)
	var b := Builder.new()
	var fl: Array = []
	match i:
		0:
			# maison de Port-Biscornu
			b.box(Vector3(2.4, 1.8, 2.0), Vector3(-5.0, 4.0, -10.0), Color(0.95, 0.85, 0.7), false)
			b.box(Vector3(2.8, 0.3, 2.4), Vector3(-5.0, 5.05, -10.0), Color(0.8, 0.3, 0.3), false, Basis(Vector3.FORWARD, 0.0))
			b.box(Vector3(0.5, 0.9, 0.1), Vector3(-5.0, 3.55, -8.95), Color(0.5, 0.3, 0.2), false)
			# arbre de Virevolte
			b.cylinder(0.25, 0.3, 2.2, Vector3(1.0, 3.2, -11.0), Color(0.5, 0.35, 0.25), Basis(), 8)
			b.sphere(1.5, Vector3(1.0, 5.2, -11.0), Color(0.55, 0.85, 0.5), Vector3(1, 0.9, 1), Basis(), 10)
			# cloche
			b.sphere(0.8, Vector3(6.5, 5.0, -9.5), GOLD, Vector3(1, 1.1, 1), Basis(), 10)
			b.box(Vector3(0.1, 0.8, 0.1), Vector3(6.5, 6.1, -9.5), Color(0.4, 0.3, 0.2), false)
		1:
			# pages géantes
			for k in 5:
				b.box(Vector3(3.0, 4.0, 0.06), Vector3(-6.0 + k * 3.0, 5.0 + (k % 2) * 1.0, -11.0 - (k % 3) * 1.5), PAPER, false, Basis(Vector3.UP, 0.3 * (k - 2)) * Basis(Vector3.RIGHT, 0.15))
		2:
			# la dernière page : un grand disque blanc derrière
			b.cylinder(7.0, 7.0, 0.15, Vector3(0, 6.0, -13.0), Color(1.0, 0.99, 0.95), Basis(Vector3.RIGHT, PI * 0.5), 24)
			b.torus(0.12, 7.0, Vector3(0, 6.0, -12.9), GOLD, Basis(Vector3.RIGHT, PI * 0.5))
	b.build(r, Toon.vertex_color(0.01), "Flottants")
	_floaters.append(r.get_child(r.get_child_count() - 1))


func _corridors() -> void:
	var b := Builder.new()
	for i in 2:
		var cx: float = X0 + DX * i + DX * 0.5
		b.box(Vector3(3.0, 0.4, 2.0), Vector3(cx, Y - 0.2, 0), PAPER.darkened(0.08), true)
		for sz in [-1.0, 1.0]:
			b.box(Vector3(3.0, 1.2, 0.2), Vector3(cx, Y + 0.6, sz * 1.0), Color(0.9, 0.9, 0.95), true)
	b.build(self, Toon.vertex_color(0.01), "Corridors")


func _open_gate(i: int) -> void:
	if i >= gates.size():
		return
	var g = gates[i]
	if g != null and is_instance_valid(g):
		Fx.puff(v.world, g.global_position + Vector3(0, 1.2, 0), Color(1.0, 0.95, 0.7))
		g.queue_free()
	gates[i] = null


func _solve(i: int) -> void:
	_open_gate(i)
	Save.story["r_room"] = maxi(solved(), i + 1)
	Save.save_game()
	Fx.text(v.world, ro(i) + Vector3(6.0, 2.5, 0), "PASSAGE OUVERT", Color(1.0, 0.95, 0.6), 1.0, 2.5)
	Bells.play(v.world, "bell", 392.0, ro(i) + Vector3(6.0, 2.0, 0), 0.0)


# --- Salle 1 : les déchirures ----------------------------------------------------------------------

func _r1(r: Node3D) -> void:
	var xs := [-4.5, 0.0, 4.5]
	_label(r, "Trois morceaux du monde se sont décousus.\nRecousez chaque déchirure avec le bon symbole.", Vector3(0, 4.6, -4.6), 0.0, 0.0065, Color(0.3, 0.25, 0.45))
	for k in 3:
		var x: float = xs[k]
		var t := Node3D.new()
		t.name = "Dechirure%d" % k
		r.add_child(t)
		var b := Builder.new()
		var tc: Color = TEARS[k]["col"]
		# une fente irrégulière dans le mur du fond
		b.box(Vector3(0.9, 3.4, 0.3), Vector3(x, 2.4, -4.82), Color(0.1, 0.08, 0.2), false)
		for j in 5:
			b.box(Vector3(0.28, 0.5, 0.34), Vector3(x + (j % 2 - 0.5) * 0.8, 1.2 + j * 0.65, -4.8), PAPER, false, Basis(Vector3.BACK, 0.5 * (j % 3 - 1)))
		b.box(Vector3(1.8, 0.12, 0.25), Vector3(x, 4.35, -4.7), tc, false)
		b.build(t, Toon.vertex_color(0.01), "Fente")
		_label(t, TEARS[k]["hint"], Vector3(x, 3.9, -4.55), 0.0, 0.0034, Color(0.3, 0.2, 0.3)).autowrap_mode = TextServer.AUTOWRAP_OFF
		_tear_nodes.append(t)
		var syms: Array = TEARS[k]["sym"]
		for j in 3:
			var kk := k
			var jj := j
			_hot(0, Vector3(x, 1.0 + j * 0.34, -4.2), syms[j], func(): _stitch(kk, jj), func(): return not _sealed[kk], 1.7)
	# le facteur, personnage oublié
	var f := _person("facteur", Characters.FACTEUR_OUBLIE, 0, Vector3(-2.2, 0.05, 2.4), PI * 0.9)
	_hot(0, Vector3(-2.2, 2.0, 2.4), "Parler au Facteur", func():
		var n := int(said.get("facteur", 0))
		said["facteur"] = n + 1
		f.chibi.say(["Je distribue du courrier à des gens que personne n'a écrits. Ça fait peu de monde, mais ils sont ponctuels.", "Pour les déchirures, demandez-vous ce que chaque endroit avait de plus étrange. Chaque village a signé son monde avec une seule chose.", "Un phare, un pont, une bulle... Je ne dis rien. Je fais juste ma tournée."][n % 3], 6.0), func(): return true, 1.8)
	_hot(0, Vector3(-6.0, 1.2, 3.5), "Sortir du Registre", func(): exit(), func(): return true, 1.8)


func _stitch(k: int, j: int) -> void:
	if _sealed[k]:
		return
	var syms: Array = TEARS[k]["sym"]
	var x: float = [-4.5, 0.0, 4.5][k]
	if j == int(TEARS[k]["ok"]):
		_sealed[k] = true
		var t: Node3D = _tear_nodes[k]
		t.visible = false
		var tc: Color = TEARS[k]["col"]
		Fx.puff(v.world, ro(0) + Vector3(x, 2.4, -4.0), tc)
		Fx.text(v.world, ro(0) + Vector3(x, 3.6, -3.8), "✔ " + syms[j], Color(0.8, 1.0, 0.8), 1.0, 3.0)
		Bells.play(v.world, "marimba", 329.63 * pow(1.1225, k * 2), ro(0) + Vector3(x, 2.0, -3.8), -2.0)
		# le morceau de monde se pose sur la page
		var b := Builder.new()
		b.sphere(0.5, Vector3(x, 2.4, -4.4), tc, Vector3(1, 1, 0.3), Basis(), 8)
		b.build(get_child(0), Toon.vertex_color(0.01), "Recousu%d" % k)
		if _sealed[0] and _sealed[1] and _sealed[2]:
			_later(0.8, _tears_done)
	else:
		Bells.play(v.world, "boing", 0.0, ro(0) + Vector3(x, 1.5, -3.8), -4.0)
		_hint_n += 1
		_pico(["Non, ça ne colle pas. Pense à ce que ce village avait d'unique, pas à ce qu'il avait en commun avec les autres.", "Raté. Le Facteur sait peut-être mieux que moi.", "Ce symbole n'a pas pris. La page s'est un peu fripée."][_hint_n % 3])


func _tears_done() -> void:
	_flag("r_tears")
	_solve(0)
	_seq([
		["e", "Tout tient. Trois villages recousus. Ce n'est pas rien."],
		["p", "Le livre est un peu moins déchiré. Je me sens un peu moins déchiré aussi, d'ailleurs."],
		["t", "Une voix, venue de partout : « Entrez. Choisissez ce qui mérite de rester. »"],
	], func(): pass)


# --- Salle 2 : la table des histoires -----------------------------------------------------------------------

func _r2(r: Node3D) -> void:
	var b := Builder.new()
	# grand lutrin
	b.box(Vector3(10.0, 0.9, 0.4), Vector3(0, 0.45, -4.3), Color(0.55, 0.4, 0.3), true)
	b.box(Vector3(10.4, 3.9, 0.15), Vector3(0, 3.1, -4.85), Color(1.0, 0.98, 0.92), false)
	b.build(r, Toon.vertex_color(0.01), "Lutrin")
	_label(r, "Choisissez SEPT histoires qui méritent d'être gardées.\nLes autres ne disparaissent pas : elles retournent à ceux qui les racontent.", Vector3(0, 5.0, -4.7), 0.0, 0.0058, Color(0.3, 0.25, 0.45))
	_count_lbl = _label(r, "Gardées : 0 / 7", Vector3(0, 0.55, -4.0), 0.0, 0.006, Color(0.45, 0.25, 0.2))
	_avail_lbl = _label(r, "", Vector3(5.5, 0.55, -4.0), 0.0, 0.0035, Color(0.4, 0.4, 0.5))
	for i in STORIES.size():
		var col := i % 3
		var row := i / 3
		var x := -4.3 + col * 4.3
		var y := 4.1 - row * 0.62
		var ii := i
		var bt := _hot(1, Vector3(x, y, -4.3), "☐ " + STORIES[i][1], func(): _toggle(ii), func(): return _story_ok(ii), 3.2, 8.5)
		_story_btns.append(bt)
	_hot(1, Vector3(0, 1.0, -4.3), "Sceller ces sept histoires", _seal, func(): return chosen.size() == 7, 2.6, 8.5)
	var fee := _person("fee", Characters.FEE, 1, Vector3(3.8, 0.05, 2.6), PI * 1.1)
	_hot(1, Vector3(3.8, 2.0, 2.6), "Parler à la Fée", func():
		var n := int(said.get("fee", 0))
		said["fee"] = n + 1
		fee.chibi.say(["Choisir sept histoires, c'est en laisser tomber d'autres. Ça fait mal. Mais laisser tomber, ce n'est pas détruire.", "Les grandes histoires tiennent toutes seules. Ce sont les petites, celles des habitants, qui ont besoin de quelqu'un pour les redire.", "Il paraît qu'il existe une troisième fin. Il faudrait garder au moins trois petites histoires. Je dis ça, je ne dis rien."][n % 3], 7.0), func(): return true, 1.8)
	_hot(1, Vector3(-6.0, 1.2, 3.5), "Sortir du Registre", func(): exit(), func(): return true, 1.8)


func _toggle(i: int) -> void:
	var id: String = STORIES[i][0]
	if chosen.has(id):
		chosen.erase(id)
	else:
		if chosen.size() >= 7:
			_pico("Sept, pas huit. Retire-en une, d'abord. Je sais, c'est horrible.")
			return
		chosen.append(id)
		Fx.text(v.world, ro(1) + Vector3(0, 5.8, -3.0), "« %s »" % STORIES[i][2], Color(1.0, 0.95, 0.75), 0.7, 3.0)
	_refresh_stories()


func _refresh_stories() -> void:
	for i in STORIES.size():
		var on: bool = chosen.has(STORIES[i][0])
		_story_btns[i].label.text = ("☑ " if on else "☐ ") + STORIES[i][1]
	_count_lbl.text = "Gardées : %d / 7" % chosen.size()
	var n := 0
	for i in STORIES.size():
		if _story_ok(i):
			n += 1
	_avail_lbl.text = "Histoires vécues : %d / %d" % [n, STORIES.size()]


func _small_count() -> int:
	var n := 0
	for i in STORIES.size():
		if STORIES[i][3] and chosen.has(STORIES[i][0]):
			n += 1
	return n


func _seal() -> void:
	Save.story["r_chosen"] = chosen.duplicate()
	Save.story["r_small"] = _small_count()
	Save.save_game()
	Bells.play(v.world, "bell", 440.0, ro(1) + Vector3(0, 2.0, -3.5), 0.0)
	Fx.puff(v.world, ro(1) + Vector3(0, 2.5, -3.8), Color(1.0, 0.95, 0.7))
	var small := _small_count()
	var first := not _s("r_sealed")
	_flag("r_sealed")
	_solve(1)
	if not first:
		return
	_seq([
		["e", "Sept histoires. Pas les plus grandes : les vôtres."],
		["p", "Dont %d petite(s) histoire(s) d'habitants. Je ne dis pas que ça change quelque chose. Je le pense très fort." % small],
		["t", "Une voix : « La dernière page vous attend. »"],
	], func(): pass)


# --- Salle 3 : la dernière page ---------------------------------------------------------------------------

func _r3(r: Node3D) -> void:
	var b := Builder.new()
	b.box(Vector3(3.0, 0.2, 3.0), Vector3(0, 0.1, -1.5), Color(1.0, 0.98, 0.9), false)
	b.build(r, Toon.vertex_color(0.01), "Estrade")
	bas = _person("basile", Characters.BASILE_PLUME, 2, Vector3(1.4, 0.2, -1.8), PI * 0.8)
	lina = _person("lina", Characters.LINA, 2, Vector3(-1.4, 0.2, -1.8), PI * 1.2)
	_hot(2, Vector3(-6.0, 1.2, 3.5), "Sortir du Registre", func(): exit(), func(): return not _final_on, 1.8)
	_hot(2, Vector3(0, 1.0, 2.6), "Conserver : refermer le Registre", func(): _ending("conserver"), func(): return _choice_on, 3.2, 7.0)
	_hot(2, Vector3(0, 1.35, 2.6), "Libérer : briser les protections", func(): _ending("liberer"), func(): return _choice_on, 3.2, 7.0)
	_hot(2, Vector3(0, 1.7, 2.6), "Continuer l'histoire : le donner aux habitants", func(): _ending("continuer"), func(): return _choice_on and int(Save.story.get("r_small", 0)) >= 3, 3.8, 7.0)
	_hot(2, Vector3(0, 0.65, 2.6), "(Parler à Basile)", func():
		if _s("ch7_done"):
			bas.chibi.say(_basile_after(), 6.0)
		else:
			bas.chibi.say("Dites-moi quand vous aurez décidé.", 3.0), func(): return not _choice_on, 1.8)


func _basile_after() -> String:
	match String(Save.story.get("ending", "")):
		"conserver":
			return "Rien ne bouge plus. C'est ce que je voulais. Je ne sais plus pourquoi je tremble."
		"liberer":
			return "Elle est partie en riant. Je crois que c'était la première fois que je pouvais l'entendre sans la retenir."
		"continuer":
			return "Les gens racontent. Parfois mal. Souvent faux. Jamais pareil. Lina a dessiné un autre phare ce matin."
	return "Merci d'être venus."


func _finale() -> void:
	if _final_on:
		return
	_final_on = true
	_choice_on = false
	bas.global_position = ro(2) + Vector3(1.4, 0.2, -1.8)
	var small := int(Save.story.get("r_small", 0))
	var lines := [
		["b", "Vous êtes allés plus loin que mon père. Il est parti avant de savoir ce qu'il voulait faire des pages."],
		["l", "Papa ! Regarde, j'ai dessiné l'île ! Elle a un phare qui regarde la mer."],
		["b", "Il regarde la mer. Exactement, ma chérie."],
		["e", "Il y a trois façons de finir un livre : le fermer, le brûler, ou le donner."],
		["b", "Conserver : je referme le Registre. L'île ne changera presque plus. Personne ne disparaît. Lina reste. Mais plus rien ne naîtra."],
		["b", "Libérer : je brise les protections. L'île vit, change, oublie. Elle est libre. Et Lina, qui n'est qu'un souvenir que je garde, s'en va."],
		["p", "Et la troisième ?" if small >= 3 else "Je crois qu'il y a une troisième voie, mais elle semble fermée pour l'instant."],
	]
	if small >= 3:
		lines.append(["b", "La troisième : vous avez gardé des histoires qui n'appartiennent à personne... et à tout le monde. Donner le Registre à ceux qui y vivent. Ils le raconteront mal, mais ils le raconteront."])
	else:
		lines.append(["b", "La troisième n'existe que si vous avez gardé assez de petites histoires, celles d'habitants. Vous pouvez retourner sur l'île, aider quelqu'un, revenir choisir autrement."])
	_seq(lines, func():
		_choice_on = true
		if int(Save.story.get("r_small", 0)) < 3:
			_pico("Pour la troisième voie : trois petites histoires, minimum. Je ne dis pas ça pour te presser. Si, un peu."))


func _ending(kind: String) -> void:
	_choice_on = false
	var lines: Array = []
	match kind:
		"conserver":
			lines = [
				["b", "Alors je referme. Doucement."],
				["l", "Papa ! Regarde, j'ai dessiné l'île ! Elle a un phare qui regarde la mer."],
				["b", "Il regarde la mer. Exactement. Je te le dirai demain aussi."],
				["e", "Les jours se ressembleront tous. Mais plus personne ne disparaîtra. C'est un choix. Ce n'est pas le mien."],
				["p", "Je reste une page. Ça va. C'est confortable, une page. Mais je n'ai plus de verso."],
				["t", "FIN : « Conserver ». L'île est parfaitement stable. Plus rien ne la dérange, plus rien ne la change."],
			]
		"liberer":
			lines = [
				["b", "Alors je libère. Lina..."],
				["l", "Papa ! Regarde, j'ai dessiné l'île ! Elle a un phare qui... qui regarde... un peu ailleurs ?"],
				["b", "Il peut regarder où il veut, ma chérie."],
				["l", "Alors je vais voir où il regarde. Au revoir, papa. Tu me raconteras ?"],
				["e", "Elle s'efface comme un dessin qui a fini d'être regardé. Mon père aurait pleuré. Moi aussi."],
				["p", "Les anomalies s'arrêtent. L'île redevient libre. Et plus personne ne retient plus personne."],
				["t", "FIN : « Libérer ». L'île est libre. Certaines choses oubliées ne reviendront jamais."],
			]
		_:
			lines = [
				["b", "Alors donnons-le. Tout entier. Aux gens qui y vivent."],
				["t", "Les sept histoires choisies s'envolent de la page, une à une, vers ceux qui les racontent."],
				["l", "Papa, regarde... j'ai dessiné autre chose. Un phare, oui. Mais il regarde les bateaux."],
				["b", "C'est... c'est nouveau. Tu ne l'as jamais dit comme ça."],
				["e", "Elle ne répète plus. Elle raconte. Ce n'est plus un souvenir : c'est une histoire."],
				["p", "Et moi ? Je ne suis plus une page ? Je suis juste... Pico ? Chic. Je chante faux, mais je chante pour moi."],
				["b", "Préserver quelqu'un, ce n'est pas empêcher le monde d'avancer. J'aurais dû le comprendre il y a vingt-sept ans."],
				["t", "FIN : « Continuer l'histoire ». L'île appartient à ceux qui y vivent."],
			]
	_seq(lines, func(): _end_chapter(kind))


func _end_chapter(kind: String) -> void:
	var first := not _s("ch7_done")
	Save.story["ending"] = kind
	Save.story["ch7_done"] = true
	Save.story["endings_seen"] = (Save.story.get("endings_seen", []) as Array)
	var seen: Array = Save.story["endings_seen"]
	if not seen.has(kind):
		seen.append(kind)
	if first:
		Save.shells += 150
	Save.save_game()
	var title: String = {"conserver": "Conserver", "liberer": "Libérer", "continuer": "Continuer l'histoire"}[kind]
	Fx.text(v.world, ro(2) + Vector3(0, 4.2, -1.0), "FIN — « %s »" % title, Color(1.0, 0.95, 0.5), 1.6, 8.0)
	if first:
		Fx.text(v.world, ro(2) + Vector3(0, 3.4, -1.0), "+150 coquillages", Color(1.0, 0.9, 0.5), 0.8, 5.0)
	_later(5.0, func(): Fx.text(v.world, ro(2) + Vector3(0, 3.6, -1.0), "L'Île Farfelue continue. Merci d'avoir joué.", Color(0.9, 0.95, 1.0), 0.8, 6.0))
	_later(9.0, func():
		_final_on = false
		exit())


# --- Entrée et sortie ----------------------------------------------------------------------------------

func event(ev: String, _node) -> void:
	if ev == "r_go":
		enter()


func enter() -> void:
	if busy:
		return
	busy = true
	if player.global_position.y < 100.0:
		_ret = player.global_position
	else:
		_ret = Vector3(4.2, Island.height(4.2, -39.5) + 0.2, -39.5)
	var tw: Tween = v.maquette._fade_to(0.0, 1.0, 1.0)
	tw.tween_callback(_enter_now)


func _enter_now() -> void:
	if not built:
		_build_scene()
	visible = true
	active = true
	chosen = []
	for id in Save.story.get("r_chosen", []):
		chosen.append(id)
	_refresh_stories()
	for i in 3:
		if i < solved():
			_open_gate(i)
	if _s("r_tears"):
		for k in 3:
			_sealed[k] = true
			_tear_nodes[k].visible = false
	var start := mini(solved(), 2)
	player.global_position = ro(start) + Vector3(-6.0, 0.15, 0)
	player._vy = 0.0
	player._face_yaw(-PI * 0.5)
	player._place_origin(true, 0.0)
	last_room = -1
	_final_on = false
	_choice_on = false
	var tw: Tween = v.maquette._fade_to(1.0, 0.0, 1.2)
	tw.tween_callback(_unbusy)
	Fx.text(v.world, ro(start) + Vector3(-3.0, 3.0, 0), "LE GRAND REGISTRE", Color(1.0, 0.95, 0.7), 1.2, 3.5)


func _unbusy() -> void:
	busy = false
	if not _s("r_intro"):
		_flag("r_intro")
		_seq([
			["e", "Nous sommes dans le livre. Au sens propre. Mon père a marché ici."],
			["p", "Ça sent l'encre et moi. C'est la première fois que je me sens chez moi, et ça m'inquiète."],
			["t", "« Trois déchirures. Trois symboles. Recousez ce qui tient encore. »"],
		], func(): pass)


func exit() -> void:
	if busy:
		return
	busy = true
	var tw: Tween = v.maquette._fade_to(0.0, 1.0, 1.0)
	tw.tween_callback(_exit_now)


func _exit_now() -> void:
	active = false
	visible = false
	_final_on = false
	_choice_on = false
	v.y.place_eleonore()
	player.global_position = _ret
	player._vy = 0.0
	player._face_yaw(PI)
	player._place_origin(true, 0.0)
	var tw2: Tween = v.maquette._fade_to(1.0, 0.0, 1.2)
	tw2.tween_callback(func(): busy = false)


func _on_room(i: int) -> void:
	if ele:
		ele.global_position = ro(i) + Vector3(-4.8, 0.05, 2.5)
		ele.chibi.rotation.y = 0.0
	if i == 1 and not said.has("r1"):
		said["r1"] = true
		_later(1.2, func(): _say_ele("Sept histoires. Chaque porte que tu as ouverte sur l'île a laissé une trace. Celles que tu n'as pas ouvertes manqueront."))
	if i == 2:
		_later(1.0, _finale)


func _physics_process(delta: float) -> void:
	if not active or player == null:
		return
	_t += delta
	for k in _floaters.size():
		var f: Node3D = _floaters[k]
		if is_instance_valid(f):
			f.position.y = sin(_t * 0.6 + k) * 0.25
	if busy:
		return
	var pp: Vector3 = player.global_position
	if pp.y < Y - 6.0:
		player.global_position = ro(clampi(solved(), 0, 2)) + Vector3(-6.0, 0.2, 0)
		return
	var c := cur()
	if c != last_room:
		last_room = c
		_on_room(c)
