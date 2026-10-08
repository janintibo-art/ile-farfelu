extends Node3D
## La Maison de Travers : le donjon du chapitre 2 (aucun ennemi).
## Cinq salles à la suite, très haut dans le ciel (y = 600) :
##   1. le vestibule poli (trois portes qui mentent, une seule inscription dit vrai)
##   2. les pièces secouées (remettre les pièces de la maison à leur place)
##   3. la porte minuscule (petite dehors, gigantesque dedans : il faut y chercher la clé)
##   4. la fenêtre qui devient porte (les étiquettes ont été posées par un menteur)
##   5. le Mot Juste (la vérité face à Maître Anselme)
## La progression est sauvegardée (Save.story["tr_room"]).

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Fx := preload("res://scripts/fx.gd")
const Save := preload("res://scripts/save.gd")
const Characters := preload("res://scripts/characters.gd")
const Talker := preload("res://scripts/talker.gd")

const Y := 600.0
const X0 := -36.0
const DX := 18.0
const GIANT := Vector3(0.0, 600.0, 48.0)
const WALLS := [Color(0.98, 0.9, 0.88), Color(0.88, 0.93, 0.98), Color(0.95, 0.95, 0.82), Color(0.9, 0.88, 0.98), Color(0.9, 0.85, 0.95)]
const GOAL := ["CAVE", "SALON", "CUISINE", "CHAMBRE", "GRENIER", ""]

var v
var player
var built := false
var active := false
var busy := false
var gates: Array = []
var ele
var anselme
var giant: Node3D
var last_room := -1
var said := {}
# salle 1
var door_tries := 0
# salle 2
var tiles: Array = []
var tile_btns: Array = []
# salle 4
var win_wrong := 0
# salle 5
var truth_n := 0
var confront := false


func setup(p_village, p_player) -> void:
	v = p_village
	player = p_player
	visible = false


func ro(i: int) -> Vector3:
	return Vector3(X0 + DX * i, Y, 0.0)


func cur() -> int:
	return clampi(int(floor((player.global_position.x - X0 + DX * 0.5) / DX)), 0, 4)


func solved() -> int:
	return int(Save.story.get("tr_room", 0))


func _s(k: String) -> bool:
	return Save.story.get(k, false)


func _say_ele(t: String) -> void:
	if ele:
		ele.chibi.say(t, 2.5 + t.length() * 0.055)


func _say_ans(t: String) -> void:
	if anselme:
		anselme.chibi.say(t, 2.5 + t.length() * 0.055)


func _pico(t: String) -> void:
	v._pico(t)


func _later(t: float, c: Callable) -> void:
	v.get_tree().create_timer(t).timeout.connect(c)


func _hot(i: int, pos: Vector3, text: String, cb: Callable, cond: Callable, width := 1.7) -> ChoiceBtn:
	v.x.hotspot(get_child(i), pos, text, cb, func(): return active and not busy and cur() == i and cond.call(), width, 3.6)
	return v.x.hot.back()["btn"]


# Petit alias pour typer les boutons
const ChoiceBtn := preload("res://scripts/choice_button.gd")


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
	_giant()
	ele = Talker.new()
	ele.name = "EleonoreMaison"
	add_child(ele)
	ele.setup(v, player, Characters.ELEONORE)
	ele.rest_yaw = -PI * 0.5
	anselme = Talker.new()
	anselme.name = "AnselmeMaison"
	add_child(anselme)
	anselme.setup(v, player, Characters.ANSELME)
	anselme.rest_yaw = PI * 0.5
	anselme.visible = false
	anselme.position = ro(4) + Vector3(3.0, 0.05, 0.0)


func _shell(r: Node3D, i: int) -> void:
	var b := Builder.new()
	var wc: Color = WALLS[i]
	var h := 6.0
	b.box(Vector3(15, 0.4, 10), Vector3(0, -0.2, 0), Color(0.62, 0.5, 0.4), true)
	b.box(Vector3(15, 0.2, 10), Vector3(0, h + 0.1, 0), wc.darkened(0.2), true)
	b.box(Vector3(15, h, 0.3), Vector3(0, h * 0.5, -5.0), wc, true)
	b.box(Vector3(15, h, 0.3), Vector3(0, h * 0.5, 5.0), wc, true)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(0.3, h, 4.0), Vector3(sx * 7.35, h * 0.5, -3.0), wc, true)
		b.box(Vector3(0.3, h, 4.0), Vector3(sx * 7.35, h * 0.5, 3.0), wc, true)
		b.box(Vector3(0.3, h - 2.6, 2.0), Vector3(sx * 7.35, 2.6 + (h - 2.6) * 0.5, 0), wc, true)
	# Des rayures qui ne sont jamais droites (la maison est de travers)
	for k in 5:
		b.box(Vector3(15, 0.2, 0.32), Vector3(0, 0.3 + k * 1.2 + (i % 2) * 0.1, -4.99), Color(0.55, 0.4, 0.7) if k % 2 == 0 else wc.lightened(0.05), false, Basis(Vector3.BACK, 0.02 * (k - 2)))
	b.build(r, Toon.vertex_color(0.01), "Shell")
	var lt := OmniLight3D.new()
	lt.omni_range = 14.0
	lt.light_energy = 1.3
	r.add_child(lt)
	lt.position = Vector3(0, 5.0, 0)
	var g := Node3D.new()
	g.name = "Gate"
	r.add_child(g)
	var gb := Builder.new()
	for k in 5:
		gb.box(Vector3(0.12, 2.6, 0.12), Vector3(7.3, 1.3, -0.8 + k * 0.4), Color(0.4, 0.3, 0.5), true)
	gb.box(Vector3(0.14, 0.14, 2.0), Vector3(7.3, 1.3, 0), Color(0.4, 0.3, 0.5), false)
	gb.build(g, Toon.vertex_color(0.01), "Bars")
	gates.append(g)
	_label(r, "SALLE %d" % (i + 1), Vector3(-7.1, 4.6, -1.8), PI * 0.5, 0.012)


func _label(parent: Node3D, text: String, pos: Vector3, yaw := 0.0, px := 0.004, col := Color(0.25, 0.2, 0.3)) -> Label3D:
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
		b.box(Vector3(3.0, 0.4, 2.0), Vector3(cx, Y - 0.2, 0), Color(0.5, 0.4, 0.35), true)
		b.box(Vector3(3.0, 0.2, 2.0), Vector3(cx, Y + 3.0, 0), Color(0.5, 0.4, 0.35), true)
		for sz in [-1.0, 1.0]:
			b.box(Vector3(3.0, 3.0, 0.2), Vector3(cx, Y + 1.5, sz * 1.0), Color(0.85, 0.82, 0.78), true)
	b.build(self, Toon.vertex_color(0.01), "Corridors")


func _open_gate(i: int) -> void:
	if i >= gates.size():
		return
	var g: Node3D = gates[i]
	if g and is_instance_valid(g):
		Fx.puff(v.world, g.global_position + Vector3(0, 1.2, 0), Color(0.9, 0.85, 1.0))
		g.queue_free()
	gates[i] = null


func _solve(i: int) -> void:
	_open_gate(i)
	Save.story["tr_room"] = maxi(solved(), i + 1)
	Save.save_game()
	Fx.text(v.world, ro(i) + Vector3(6.0, 2.5, 0), "PORTE OUVERTE", Color(0.7, 1.0, 0.75), 1.0, 2.5)


# --- Salle 1 : les trois portes qui mentent ------------------------------------------------------------

func _r1(r: Node3D) -> void:
	var b := Builder.new()
	var cols := [Color(0.85, 0.5, 0.45), Color(0.45, 0.65, 0.85), Color(0.6, 0.8, 0.5)]
	for k in 3:
		var x := -4.0 + k * 4.0
		b.box(Vector3(1.8, 2.8, 0.12), Vector3(x, 1.4, -4.78), cols[k], false)
		b.box(Vector3(0.12, 0.12, 0.1), Vector3(x + 0.6, 1.3, -4.7), Color(0.95, 0.85, 0.3), false)
	b.build(r, Toon.vertex_color(0.01), "Portes")
	var txt := ["A : « La sortie est derrière\ncette porte. »", "B : « La sortie n'est pas\nderrière la porte A. »", "C : « La sortie n'est pas\nderrière cette porte. »"]
	for k in 3:
		_label(r, txt[k], Vector3(-4.0 + k * 4.0, 3.7, -4.68), 0.0, 0.0042)
	_label(r, "LA MAISON DE TRAVERS\nBienvenue. Tout ce qui est écrit ici est poli.\nUNE SEULE INSCRIPTION DIT VRAI.", Vector3(0, 5.0, -4.68), 0.0, 0.0045, Color(0.4, 0.2, 0.5))
	for k in 3:
		_hot(0, Vector3(-4.0 + k * 4.0, 1.1, -3.9), "Ouvrir la porte " + "ABC"[k], _door.bind(k), func(): return solved() < 1, 1.5)
	_hot(0, Vector3(-6.2, 1.2, 3.0), "Sortir de la maison", func(): exit(), func(): return true, 1.8)


func _door(k: int) -> void:
	if k == 2:
		_say_ele("C. Si A disait vrai, B aussi... Une seule vraie. C'est la seule qui tient. La maison avait l'air sûre d'elle.")
		Fx.text(v.world, ro(0) + Vector3(4.0, 3.0, -3.5), "CLIC ! La vraie sortie.", Color(0.7, 1.0, 0.75), 1.0, 2.5)
		_solve(0)
	else:
		door_tries += 1
		Fx.text(v.world, ro(0) + Vector3(-4.0 + k * 4.0, 3.0, -3.5), "Un placard. Il a répété trois fois « sortie » : il y croit.", Color(1.0, 0.8, 0.7), 0.6, 3.0)
		if door_tries == 2:
			_say_ele("Une seule inscription dit vrai. Essaie les trois cas : si A est vrai, que valent B et C ?")


# --- Salle 2 : les pièces secouées ---------------------------------------------------------------------------------

func _r2(r: Node3D) -> void:
	_label(r, "LA MAISON A ÉTÉ SECOUÉE\nRemettez les pièces comme sur le plan.\nCAVE · SALON · CUISINE\nCHAMBRE · GRENIER · (vide)", Vector3(0, 4.2, -4.68), 0.0, 0.0048, Color(0.4, 0.2, 0.5))
	tile_btns.clear()
	_shuffle_tiles()
	for i in 6:
		var c := i % 3
		var row := i / 3
		var bt := _hot(1, Vector3((c - 1) * 1.6, 2.5 - row * 0.4, -3.9), tiles[i] if tiles[i] != "" else "(vide)", _tile.bind(i), func(): return solved() < 2, 1.4)
		tile_btns.append(bt)
	_hot(1, Vector3(-5.2, 1.2, 3.0), "Mélanger de nouveau", _reshuffle, func(): return solved() < 2, 1.7)


func _reshuffle() -> void:
	_shuffle_tiles()
	_refresh_tiles()


func _shuffle_tiles() -> void:
	tiles = GOAL.duplicate()
	var e := 5
	for n in 60:
		var nb: Array = []
		var c := e % 3
		var row := e / 3
		if c > 0:
			nb.append(e - 1)
		if c < 2:
			nb.append(e + 1)
		if row > 0:
			nb.append(e - 3)
		if row < 1:
			nb.append(e + 3)
		var m: int = nb[randi() % nb.size()]
		tiles[e] = tiles[m]
		tiles[m] = ""
		e = m
	if tiles == GOAL:
		tiles[5] = tiles[4]
		tiles[4] = ""


func _refresh_tiles() -> void:
	for i in tile_btns.size():
		tile_btns[i].label.text = tiles[i] if tiles[i] != "" else "(vide)"


func _tile(i: int) -> void:
	var e: int = tiles.find("")
	var ci := i % 3
	var ri := i / 3
	var ce := e % 3
	var re := e / 3
	var adj: bool = (ci == ce and absi(ri - re) == 1) or (ri == re and absi(ci - ce) == 1)
	if not adj or tiles[i] == "":
		return
	tiles[e] = tiles[i]
	tiles[i] = ""
	_refresh_tiles()
	if tiles == GOAL:
		Fx.text(v.world, ro(1) + Vector3(0, 3.4, -3.0), "TOUT EST À SA PLACE", Color(0.7, 1.0, 0.75), 1.0, 2.5)
		_say_ele("La cave en bas, le grenier en haut. Une maison qui range ses pièces, c'est suspect... mais poli.")
		_solve(1)


# --- Salle 3 : la porte minuscule ------------------------------------------------------------------------------------

func _r3(r: Node3D) -> void:
	var b := Builder.new()
	b.box(Vector3(0.1, 0.9, 0.5), Vector3(-7.15, 0.45, 3.0), Color(0.85, 0.65, 0.3), false)
	b.box(Vector3(0.12, 0.12, 0.7), Vector3(-7.14, 0.95, 3.0), Color(0.5, 0.35, 0.25), false)
	b.build(r, Toon.vertex_color(0.01), "PetiteDoor")
	_label(r, "CE QUI EST PETIT DEHORS\nEST GRAND DEDANS.", Vector3(0, 4.2, -4.68), 0.0, 0.0055, Color(0.4, 0.2, 0.5))
	_label(r, "(entrée de poche)", Vector3(-7.0, 1.4, 3.0), PI * 0.5, 0.003)
	_hot(2, Vector3(-5.9, 1.0, 3.0), "Entrer par la porte minuscule", _into_giant, func(): return solved() < 3 and not _s("tr_key"), 2.2)
	_hot(2, Vector3(6.0, 1.3, 1.6), "Ouvrir avec la clé géante", _use_key, func(): return _s("tr_key") and solved() < 3, 2.2)
	_hot(2, Vector3(-5.9, 1.2, -3.0), "Sortir de la maison", func(): exit(), func(): return true, 1.8)


func _giant() -> void:
	giant = Node3D.new()
	giant.name = "SalleGeante"
	add_child(giant)
	giant.position = GIANT
	var b := Builder.new()
	var wc := Color(0.98, 0.92, 0.8)
	b.box(Vector3(40, 0.4, 28), Vector3(0, -0.2, 0), Color(0.62, 0.5, 0.4), true)
	b.box(Vector3(40, 0.2, 28), Vector3(0, 16.1, 0), wc.darkened(0.2), true)
	b.box(Vector3(40, 16, 0.3), Vector3(0, 8, -14), wc, true)
	b.box(Vector3(40, 16, 0.3), Vector3(0, 8, 14), wc, true)
	b.box(Vector3(0.3, 16, 28), Vector3(-20, 8, 0), wc, true)
	b.box(Vector3(0.3, 16, 28), Vector3(20, 8, 0), wc, true)
	# Une table géante, un lit géant, une chaise géante, une tasse géante
	b.box(Vector3(10, 0.8, 6), Vector3(-6, 5.0, -6), Color(0.6, 0.4, 0.28), true)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			b.box(Vector3(0.7, 4.6, 0.7), Vector3(-6 + sx * 4.5, 2.3, -6 + sz * 2.5), Color(0.5, 0.33, 0.22), true)
	b.box(Vector3(9, 3.0, 5.0), Vector3(10, 1.5, 6), Color(0.85, 0.6, 0.65), true)
	b.box(Vector3(9, 0.8, 5.2), Vector3(10, 3.4, 6), Color(0.95, 0.95, 0.98), false)
	b.cylinder(0.9, 0.7, 1.4, Vector3(-3, 6.1, -6), Color(0.95, 0.85, 0.5), Basis(), 10)
	# La clé géante, posée sur la table
	b.cylinder(0.5, 0.5, 0.2, Vector3(-8.5, 5.5, -6), Color(0.95, 0.8, 0.25), Basis(Vector3.RIGHT, PI * 0.5), 12)
	b.box(Vector3(3.2, 0.3, 0.2), Vector3(-6.4, 5.5, -6), Color(0.95, 0.8, 0.25), false)
	b.box(Vector3(0.3, 0.7, 0.2), Vector3(-5.2, 5.2, -6), Color(0.95, 0.8, 0.25), false)
	b.build(giant, Toon.vertex_color(0.01), "Mesh")
	var lt := OmniLight3D.new()
	lt.omni_range = 40.0
	lt.light_energy = 1.4
	giant.add_child(lt)
	lt.position = Vector3(0, 13, 0)
	_label(giant, "SALLE DE TAILLE NORMALE\n(pour un géant)", Vector3(0, 9.0, 13.7), PI, 0.02, Color(0.4, 0.2, 0.5))
	v.x.hotspot(giant, Vector3(-6.4, 5.9, -4.0), "Prendre la clé géante", _take_key, func(): return active and not busy and _in_giant() and not _s("tr_key"), 2.0, 9.0)
	v.x.hotspot(giant, Vector3(0, 1.4, 11.5), "Ressortir par la porte de poche", _out_giant, func(): return active and not busy and _in_giant(), 2.4, 9.0)


func _in_giant() -> bool:
	return player.global_position.z > 20.0


func _into_giant() -> void:
	busy = true
	var tw: Tween = v.maquette._fade_to(0.0, 1.0, 0.7)
	tw.tween_callback(_into_giant_now)


func _into_giant_now() -> void:
	player.global_position = GIANT + Vector3(0, 0.15, 11.0)
	player._vy = 0.0
	player._face_yaw(0.0)
	player._place_origin(true, 0.0)
	var tw2: Tween = v.maquette._fade_to(1.0, 0.0, 0.8)
	tw2.tween_callback(_into_giant_done)


func _into_giant_done() -> void:
	busy = false
	_say_ele("Tout est énorme ! Ou alors c'est nous. Je préfère ne pas trancher.")
	_later(3.5, _giant_pico)


func _giant_pico() -> void:
	_pico("Une table de la taille d'une maison. La clé, là-haut, est faite pour ouvrir une porte de cathédrale. Il faut la prendre.")


func _take_key() -> void:
	Save.story["tr_key"] = true
	Save.save_game()
	Fx.text(v.world, giant.global_position + Vector3(-6.4, 7.0, -4.0), "CLÉ GÉANTE !", Color(1.0, 0.9, 0.4), 1.0, 3.0)
	_say_ele("On ne la met pas dans la poche. On la fait glisser derrière nous. Mais prenons-la.")


func _out_giant() -> void:
	busy = true
	var tw: Tween = v.maquette._fade_to(0.0, 1.0, 0.7)
	tw.tween_callback(_out_giant_now)


func _out_giant_now() -> void:
	player.global_position = ro(2) + Vector3(-5.2, 0.15, 3.0)
	player._vy = 0.0
	player._face_yaw(-PI * 0.5 + PI)
	player._place_origin(true, 0.0)
	var tw2: Tween = v.maquette._fade_to(1.0, 0.0, 0.8)
	tw2.tween_callback(_unbusy)


func _unbusy() -> void:
	busy = false


func _use_key() -> void:
	Fx.text(v.world, ro(2) + Vector3(6.0, 2.6, 1.6), "CLONK ! La clé est énorme, la serrure aussi.", Color(0.7, 1.0, 0.75), 0.9, 3.0)
	_solve(2)


# --- Salle 4 : la fenêtre qui devient porte ----------------------------------------------------------------------

func _r4(r: Node3D) -> void:
	var b := Builder.new()
	var views := [Color(0.35, 0.65, 0.4), Color(0.95, 0.65, 0.8), Color(0.55, 0.8, 1.0)]
	for k in 3:
		var x := -4.0 + k * 4.0
		b.box(Vector3(2.0, 2.0, 0.1), Vector3(x, 2.4, -4.78), Color(0.85, 0.65, 0.25), false)
		b.box(Vector3(1.7, 1.7, 0.08), Vector3(x, 2.4, -4.72), views[k], false)
	# Le « jardin » : des fleurs sur la fenêtre du milieu
	for f in 6:
		b.sphere(0.09, Vector3(-0.6 + f * 0.24, 1.85 + (f % 2) * 0.12, -4.66), Color(1.0, 0.95, 0.4) if f % 2 == 0 else Color(1.0, 0.4, 0.5), Vector3.ONE, Basis(), 5)
	b.build(r, Toon.vertex_color(0.01), "Fenetres")
	var labs := ["JARDIN", "CIEL", "FORÊT"]
	for k in 3:
		_label(r, labs[k], Vector3(-4.0 + k * 4.0, 1.1, -4.68), 0.0, 0.007)
		_hot(3, Vector3(-4.0 + k * 4.0, 0.7, -3.9), "Retourner cette fenêtre", _win.bind(k), func(): return solved() < 4, 1.8)
	_label(r, "RETOURNEZ LA FENÊTRE QUI DONNE SUR LE JARDIN.\n(Les étiquettes ont été posées par un menteur.)", Vector3(0, 4.5, -4.68), 0.0, 0.0042, Color(0.4, 0.2, 0.5))


func _win(k: int) -> void:
	if k == 1:
		Fx.text(v.world, ro(3) + Vector3(0, 3.6, -3.4), "La fenêtre se retourne : c'est une porte !", Color(0.7, 1.0, 0.75), 0.9, 3.0)
		_say_ele("Les couleurs ne mentent pas : le jardin, ce sont les fleurs. L'étiquette « CIEL » était polie, pas honnête.")
		_solve(3)
	else:
		win_wrong += 1
		Fx.text(v.world, ro(3) + Vector3(-4.0 + k * 4.0, 3.5, -3.4), "Elle se retourne... sur un mur. Un mur poli.", Color(1.0, 0.8, 0.7), 0.6, 3.0)
		if win_wrong == 2:
			_say_ele("Un jardin, ça a des fleurs. Regarde ce qui est dessiné, pas ce qui est écrit.")


# --- Salle 5 : le Mot Juste -----------------------------------------------------------------------------------------

func _r5(r: Node3D) -> void:
	var b := Builder.new()
	b.cylinder(0.6, 0.8, 1.1, Vector3(0, 0.55, 0), Color(0.75, 0.7, 0.85), Basis(), 12)
	b.sphere(0.22, Vector3(0, 1.45, 0), Color(1.0, 0.9, 0.4), Vector3(1.0, 0.7, 1.0), Basis(), 10)
	b.build(r, Toon.vertex_color(0.01), "Piedestal")
	_label(r, "LE MOT JUSTE", Vector3(0, 2.4, 0.1), 0.0, 0.007, Color(0.6, 0.4, 0.1))
	_hot(4, Vector3(0, 1.1, 1.6), "Prendre le Mot Juste", _take_word, func(): return not _s("mot_juste") and not confront, 1.9)
	_hot(4, Vector3(-1.4, 1.1, 1.9), "Dire : « Mon père existe. »", _say_truth, func(): return confront and truth_n < 3 and not _s("ch2_done"), 2.4)
	_hot(4, Vector3(-5.2, 1.2, 3.0), "Sortir de la maison", func(): exit(), func(): return _s("mot_juste") or true, 1.8)


func _take_word() -> void:
	confront = true
	busy = true
	anselme.visible = true
	Fx.puff(v.world, ro(4) + Vector3(3.0, 1.2, 0), Color(0.7, 0.5, 1.0))
	Save.add_item("mot_juste")
	Save.story["mot_juste"] = true
	Save.save_game()
	Fx.text(v.world, ro(4) + Vector3(0, 2.0, 0), "→ Sac : Le Mot Juste", Color(1.0, 0.95, 0.7), 0.9, 3.0)
	_later(1.0, func(): _say_ans("Vous n'auriez pas dû le prendre. Il fait entendre ce que je ne veux pas dire."))
	_later(4.5, func(): _say_ele("Maître Anselme ! Vous nous avez suivis."))
	_later(7.5, func(): _say_ans("Je suis un homme de confiance. Les deux familles me font confiance. Les deux ont raison."))
	_later(10.5, func(): Fx.text(v.world, ro(4) + Vector3(2.0, 2.4, 0), "LE MOT JUSTE : MENSONGE", Color(1.0, 0.45, 0.45), 0.9, 3.0))
	_later(13.5, func(): _say_ans("Je n'ai écrit aucun acte. L'encre n'est pas de moi."))
	_later(16.5, func(): Fx.text(v.world, ro(4) + Vector3(2.0, 2.4, 0), "LE MOT JUSTE : MENSONGE", Color(1.0, 0.45, 0.45), 0.9, 3.0))
	_later(19.5, func(): _say_ans("... Quelqu'un du Château m'a demandé de faire répéter à la forêt que le Grand Cartographe n'a jamais existé."))
	_later(22.0, func(): Fx.text(v.world, ro(4) + Vector3(2.0, 2.4, 0), "LE MOT JUSTE : VRAI", Color(0.5, 1.0, 0.6), 1.0, 3.5))
	_later(25.0, func(): _say_ele("Mon père... La forêt le répète depuis des mois. Et si elle y arrivait ? Il disparaîtrait pour de bon."))
	_later(29.0, _ask_truth)


func _ask_truth() -> void:
	_pico("Une phrase fausse répétée trois fois devient vraie, ici. Une phrase vraie, trois fois aussi, non ? C'est de la politesse inversée.")
	_say_ele("Aide-moi. Dis-le avec moi, trois fois : « Mon père existe. » Le Mot Juste fera le reste.")
	busy = false


func _say_truth() -> void:
	truth_n += 1
	var line := ["« Mon père existe. »", "« Mon père existe. » (de plus en plus fort)", "« MON PÈRE EXISTE. »"]
	Fx.text(v.world, ro(4) + Vector3(-1.4, 2.5, 1.6), line[truth_n - 1], Color(1.0, 0.95, 0.6), 0.8 + 0.2 * truth_n, 2.5)
	Fx.puff(v.world, ro(4) + Vector3(0, 1.4, 0), Color(1.0, 0.9, 0.5))
	if truth_n >= 3:
		busy = true
		_later(1.5, _finish)


func _finish() -> void:
	Fx.text(v.world, ro(4) + Vector3(0, 3.2, 0), "LA MAISON SE REDRESSE", Color(0.7, 1.0, 0.75), 1.4, 4.0)
	_later(2.5, func(): _say_ans("Ça... ça ne s'était jamais produit. Une vérité qui reste vraie. Je... retire ce que j'ai fait faire à la forêt."))
	_later(6.5, func(): _say_ele("Il existe, donc. Il a existé. Je le retrouverai. Merci, " + v._name() + "."))
	_later(10.5, _end_chapter)
	_later(14.0, func(): Fx.text(v.world, ro(4) + Vector3(0, 2.6, 0), "À suivre : Brumelune, dans le marais des Murmures...", Color(0.9, 0.95, 1.0), 0.7, 6.0))


func _end_chapter() -> void:
	Save.story["ch2_done"] = true
	Save.shells += 30
	Save.save_game()
	Fx.text(v.world, ro(4) + Vector3(0, 3.0, 0), "CHAPITRE 2 TERMINÉ", Color(1.0, 0.95, 0.5), 1.6, 6.0)
	Fx.text(v.world, ro(4) + Vector3(0, 2.0, 0), "+30 coquillages · Le Mot Juste", Color(1.0, 0.9, 0.5), 0.8, 4.0)
	busy = false


# --- Entrée et sortie --------------------------------------------------------------------------------------------------

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
	if _s("ch2_done"):
		anselme.visible = true
	var tw: Tween = v.maquette._fade_to(1.0, 0.0, 1.2)
	tw.tween_callback(_unbusy)
	Fx.text(v.world, ro(s) + Vector3(-3.0, 3.0, 0), "LA MAISON DE TRAVERS", Color(1.0, 0.95, 0.7), 1.2, 3.5)


func exit() -> void:
	if busy:
		return
	busy = true
	var tw: Tween = v.maquette._fade_to(0.0, 1.0, 1.0)
	tw.tween_callback(_exit_now)


func _exit_now() -> void:
	active = false
	visible = false
	player.global_position = Vector3(0.0, 500.1, -49.0)
	player._vy = 0.0
	player._face_yaw(0.0)
	player._place_origin(true, 0.0)
	var tw2: Tween = v.maquette._fade_to(1.0, 0.0, 1.2)
	tw2.tween_callback(_unbusy)


# --- Boucle --------------------------------------------------------------------------------------------------------------

func _on_room(i: int) -> void:
	if said.has(i):
		return
	said[i] = true
	var lines := [
		"Une maison qui écrit « poli » sur ses portes. Quand on écrit ça, c'est qu'on cache quelque chose.",
		"Quelqu'un a rangé tout ça de travers, puis l'a remis à l'endroit. C'est de l'humour de notaire.",
		"Une porte de poche. Ici, je m'attends à tout : une porte dans une porte, une clé dans une clé.",
		"Des fenêtres qui s'inversent. Je n'ai jamais aimé ce qui se retourne contre moi.",
		"Le Mot Juste. J'ai lu dans les livres de mon père que la vérité se trouve au bout de la politesse.",
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
	if pp.z > 20.0:
		return
	var c := cur()
	if c != last_room:
		last_room = c
		_on_room(c)
