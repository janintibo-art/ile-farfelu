extends Node3D
## Le Château des Versions Officielles : chapitre 6 « Le bal des Versions Officielles »,
## très haut dans le ciel (y = 1300). Presque pas d'action : on parle, on lit, on observe.
##   1. Hall d'honneur : Basile nous reçoit. Jules et… un deuxième Jules, plus jeune, qui se détestent.
##   2. Galerie des portraits : plaques, dates, et un portrait vexé.
##   3. Salle de bal : six invités. Lesquels sont vrais, lesquels sont des souvenirs,
##      lesquels sont des versions abandonnées ? (miroir, carnet de bal, conversations)
##   4. Couloir des portes : conversations entendues derrière les portes, passage secret.
##   5. Bibliothèque : remettre six événements dans l'ordre (les dates des plaques),
##      puis la Chambre de Lina, et la vérité sur Basile.
## La progression est sauvegardée (Save.story["m_room"]).

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Fx := preload("res://scripts/fx.gd")
const Save := preload("res://scripts/save.gd")
const Island := preload("res://scripts/island.gd")
const Characters := preload("res://scripts/characters.gd")
const Talker := preload("res://scripts/talker.gd")
const ChoiceBtn := preload("res://scripts/choice_button.gd")
const Bells := preload("res://scripts/bells.gd")

const Y := 1300.0
const X0 := -36.0
const DX := 18.0
const WALLS := [Color(0.95, 0.88, 0.72), Color(0.72, 0.4, 0.45), Color(0.85, 0.88, 0.98), Color(0.5, 0.38, 0.3), Color(0.45, 0.62, 0.5)]
const FLOORS := [Color(0.85, 0.82, 0.78), Color(0.45, 0.3, 0.3), Color(0.9, 0.9, 0.95), Color(0.35, 0.27, 0.22), Color(0.4, 0.3, 0.22)]
const GOLD := Color(0.95, 0.78, 0.3)

## Les invités : vérité (real / mem / ver) et ce qu'ils disent à chaque conversation
const GUESTS := {
	"jules": {"truth": "real", "name": "Jules", "lines": [
		"Jules Pivoine, majordome du château depuis toujours. Je sers le thé, la soupe, et mon opinion sur les gens qui arrivent en retard.",
		"Ne regardez pas le jeune homme là-bas. Il porte mon nom et mon plastron. On a l'impression de se croiser dans un mauvais miroir.",
		"Basile m'a dit que c'était « une ancienne version ». J'ai répondu que j'étais une ancienne version aussi. Il a fait semblant de ne pas m'entendre.",
	]},
	"jules2": {"truth": "ver", "name": "Jules (Jeune)", "lines": [
		"Je suis le vrai Jules. Plus rapide, plus souple, plus jeune. L'autre est une version usée. Il a même des genoux qui grincent.",
		"Enfin... je suis le meilleur Jules. Le vrai Jules ? Qui sait. Je crois qu'on m'a retiré du service un mardi.",
		"Peu importe. J'attends qu'on me remplace. On finit toujours par m'oublier derrière une porte. Vous avez vu le vieux ? Il me regarde comme un prix de consolation.",
	]},
	"colonel": {"truth": "real", "name": "Colonel Boutonnière", "lines": [
		"Colonel Amédée Boutonnière, soixante-douze campagnes, onze médailles, quatre vestes. Je me tiens droit parce que mon dos est têtu.",
		"Ah, vous avez regardé le buffet ? Moi je mange tout. Un vrai invité, ça se voit à l'assiette : la mienne est vide, et la sienne, regardez.",
		"Armand Chardon me manque. Il cartographiait mes batailles et les remettait d'aplomb. Basile joue au calme. Il n'a jamais été calme.",
	]},
	"perle": {"truth": "mem", "name": "Mademoiselle Perle", "lines": [
		"Quelle belle soirée, n'est-ce pas ? Vous dansez ? J'ai promis la valse suivante à quelqu'un, mais je ne me souviens plus à qui.",
		"Quelle belle soirée, n'est-ce pas ? Vous dansez ? J'ai promis la valse suivante à quelqu'un, mais je ne me souviens plus à qui.",
		"Quelle belle soirée, n'est-ce pas ? Vous dansez ? J'ai promis la valse suivante à quelqu'un, mais je ne me souviens plus à qui.",
	]},
	"archet": {"truth": "mem", "name": "Monsieur Archet", "lines": [
		"♪ La... la, la la... la, la la la... ♪ (Il recommence au début, à la même note.)",
		"♪ La... la, la la... la, la la la... ♪ (Toujours la même mesure. Le même soupir.)",
		"♪ La... la, la la... la, la la la... ♪ (Il sourit. Exactement comme avant.)",
	]},
	"petra": {"truth": "ver", "name": "Pétra", "lines": [
		"Je suis Pétronille ! La vraie ! Celle qui avait trente ans, du courage et des chaussures pratiques.",
		"Enfin... la plus curieuse. La vieille garde les secrets sur l'étagère. Moi je les pose sur la table et j'attends qu'on les remarque. On m'a trouvée trop bavarde.",
		"« Non retenue », ils ont écrit. Je ne suis pas un brouillon ! Je suis ce qu'elle aurait été si elle avait dit ce qu'elle savait.",
	]},
}
const GUEST_POS := {
	"jules": [2, Vector3(-5.5, 0.05, -2.2), 0.4], "jules2": [2, Vector3(5.5, 0.05, -2.5), -0.4],
	"colonel": [2, Vector3(4.0, 0.05, 1.0), 0.5], "perle": [2, Vector3(-1.5, 0.05, 0.2), 0.3],
	"archet": [2, Vector3(0.0, 0.65, -3.7), 0.0], "petra": [2, Vector3(-3.5, 0.05, 3.0), 0.0],
}

## Les six événements, dans l'ordre chronologique
const EVENTS := ["Fondation du Registre (Basile et Armand)", "Naissance de Lina Plume", "Lina dessine l'île",
	"La Grande Séparation (le matin)", "Armand part chercher les pages (le soir)", "Le château ferme ses portes"]
const EVENT_SHUFFLE := [3, 0, 5, 2, 4, 1]

var v
var player
var built := false
var active := false
var busy := false
var gates: Array = []
var ele
var bas
var lina
var guests := {}
var last_room := -1
var said := {}
var talked := {}
var talk_n := {}
var resolved := {}
var wrong_n := 0
var _ret := Vector3.ZERO
var _panel: Node3D
var _door_lbl: Array = []
var _card_lbls: Array = []
var _tl_progress := 0
var _tl_label: Label3D
var _scene_on := false
var _mirror_lbl: Label3D
var _violin_t := 0.0
var _violin_i := 0
var _perle_t := 3.0
var _cur_lines: Array = []


func setup(p_village, p_player) -> void:
	v = p_village
	player = p_player
	visible = false


func ro(i: int) -> Vector3:
	return Vector3(X0 + DX * i, Y, 0.0)


func cur() -> int:
	return clampi(int(floor((player.global_position.x - X0 + DX * 0.5) / DX)), 0, 4)


func solved() -> int:
	return int(Save.story.get("m_room", 0))


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


func _hot(i: int, pos: Vector3, text: String, cb: Callable, cond: Callable, width := 1.8) -> ChoiceBtn:
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
		"b":
			bas.chibi.say(text, d)
		"j":
			guests["jules"].chibi.say(text, d)
		"j2":
			guests["jules2"].chibi.say(text, d)
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


func _set_on(n: Node3D, on: bool) -> void:
	n.visible = on
	for c in n.get_children():
		if c is StaticBody3D:
			c.collision_layer = 1 if on else 0


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


func _person(id: String, def: Dictionary, room: int, pos: Vector3, yaw: float) -> Talker:
	var t := Talker.new()
	t.name = id.capitalize()
	get_child(room).add_child(t)
	t.position = pos
	t.setup(v, player, def)
	t.rest_yaw = yaw
	return t


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
	ele.name = "EleonoreChateau"
	add_child(ele)
	ele.setup(v, player, Characters.ELEONORE)
	ele.rest_yaw = -PI * 0.5


func _shell(r: Node3D, i: int) -> void:
	var b := Builder.new()
	var wc: Color = WALLS[i]
	var h := 6.5
	b.box(Vector3(15, 0.4, 10), Vector3(0, -0.2, 0), FLOORS[i], true)
	b.box(Vector3(15, 0.2, 10), Vector3(0, h + 0.1, 0), wc.darkened(0.3), true)
	b.box(Vector3(15, h, 0.3), Vector3(0, h * 0.5, 5.0), wc, true)
	if i == 4:
		# mur du fond avec l'ouverture (fermée par un panneau) vers la Chambre de Lina
		b.box(Vector3(6.0, h, 0.3), Vector3(-4.5, h * 0.5, -5.0), wc, true)
		b.box(Vector3(6.0, h, 0.3), Vector3(4.5, h * 0.5, -5.0), wc, true)
		b.box(Vector3(3.0, h - 3.0, 0.3), Vector3(0, 3.0 + (h - 3.0) * 0.5, -5.0), wc, true)
	else:
		b.box(Vector3(15, h, 0.3), Vector3(0, h * 0.5, -5.0), wc, true)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(0.3, h, 4.0), Vector3(sx * 7.35, h * 0.5, -3.0), wc, true)
		b.box(Vector3(0.3, h, 4.0), Vector3(sx * 7.35, h * 0.5, 3.0), wc, true)
		b.box(Vector3(0.3, h - 2.6, 2.0), Vector3(sx * 7.35, 2.6 + (h - 2.6) * 0.5, 0), wc, true)
	# plinthes dorées
	b.box(Vector3(15, 0.25, 0.1), Vector3(0, 0.12, 4.82), GOLD.darkened(0.2), false)
	b.build(r, Toon.vertex_color(0.01), "Shell")
	var lt := OmniLight3D.new()
	lt.omni_range = 15.0
	lt.light_energy = 1.2
	lt.light_color = Color(1.0, 0.94, 0.82)
	r.add_child(lt)
	lt.position = Vector3(0, 5.0, 0)
	# lustre
	var cb := Builder.new()
	cb.cylinder(0.02, 0.02, 1.2, Vector3(0, 5.8, 0), Color(0.4, 0.35, 0.3), Basis(), 5)
	cb.torus(0.04, 0.5, Vector3(0, 5.15, 0), GOLD, Basis())
	cb.torus(0.04, 0.9, Vector3(0, 5.0, 0), GOLD, Basis())
	for k in 8:
		var a := k * TAU / 8.0
		cb.sphere(0.1, Vector3(cos(a) * 0.9, 5.18, sin(a) * 0.9), Color(1.0, 0.95, 0.7), Vector3(1, 1.4, 1), Basis(), 6)
	cb.build(r, Toon.vertex_color(0.008), "Lustre")
	var g: Node3D = null
	if i == 2 or i == 3:
		g = Node3D.new()
		g.name = "Gate"
		r.add_child(g)
		var gb := Builder.new()
		for k in 5:
			gb.box(Vector3(0.12, 2.6, 0.12), Vector3(7.3, 1.3, -0.8 + k * 0.4), Color(0.6, 0.5, 0.3), true)
		gb.box(Vector3(0.14, 0.14, 2.0), Vector3(7.3, 1.3, 0), Color(0.6, 0.5, 0.3), false)
		gb.build(g, Toon.vertex_color(0.01), "Bars")
	gates.append(g)
	var names := ["HALL D'HONNEUR", "GALERIE DES PORTRAITS", "SALLE DE BAL", "COULOIR DES PORTES", "BIBLIOTHÈQUE"]
	_label(r, names[i], Vector3(-7.1, 4.8, -2.8), PI * 0.5, 0.011, Color(0.25, 0.18, 0.1))


func _corridors() -> void:
	var b := Builder.new()
	for i in 4:
		var cx: float = X0 + DX * i + DX * 0.5
		b.box(Vector3(3.0, 0.4, 2.0), Vector3(cx, Y - 0.2, 0), Color(0.55, 0.4, 0.35), true)
		b.box(Vector3(3.0, 0.2, 2.0), Vector3(cx, Y + 3.0, 0), Color(0.55, 0.4, 0.35), true)
		for sz in [-1.0, 1.0]:
			b.box(Vector3(3.0, 3.0, 0.2), Vector3(cx, Y + 1.5, sz * 1.0), Color(0.9, 0.82, 0.7), true)
	b.build(self, Toon.vertex_color(0.01), "Corridors")


func _open_gate(i: int) -> void:
	if i >= gates.size():
		return
	var g = gates[i]
	if g != null and is_instance_valid(g):
		Fx.puff(v.world, g.global_position + Vector3(0, 1.2, 0), Color(1.0, 0.9, 0.6))
		g.queue_free()
	gates[i] = null


func _solve(i: int) -> void:
	_open_gate(i)
	Save.story["m_room"] = maxi(solved(), i + 1)
	Save.save_game()
	Fx.text(v.world, ro(i) + Vector3(6.0, 2.5, 0), "PASSAGE OUVERT", Color(1.0, 0.95, 0.6), 1.0, 2.5)
	Bells.play(v.world, "bell", 392.0, ro(i) + Vector3(6.0, 2.0, 0), 0.0)


func _frame(b: Builder, x: float, y: float, w: float, h: float, z: float, col: Color) -> void:
	b.box(Vector3(w + 0.3, h + 0.3, 0.12), Vector3(x, y, z), GOLD.darkened(0.25), false)
	b.box(Vector3(w, h, 0.14), Vector3(x, y, z + 0.03), col, false)


# --- Salle 1 : Hall d'honneur ---------------------------------------------------------------------

func _r1(r: Node3D) -> void:
	var b := Builder.new()
	b.box(Vector3(3.0, 0.03, 8.0), Vector3(0, 0.02, 0), Color(0.75, 0.15, 0.2), false)
	for sx in [-1.0, 1.0]:
		for k in 3:
			b.cylinder(0.3, 0.3, 6.0, Vector3(sx * 5.8, 3.0, -3.8 + k * 3.4), Color(0.98, 0.95, 0.88), Basis(), 12)
	# grand portrait de famille, fond
	_frame(b, 0.0, 3.4, 4.0, 2.2, -4.78, Color(0.35, 0.5, 0.65))
	b.build(r, Toon.vertex_color(0.01), "Decor")
	_label(r, "BAL DES VERSIONS OFFICIELLES", Vector3(0, 4.9, -4.6), 0.0, 0.0085, Color(0.4, 0.15, 0.2))
	var plaque := _label(r, "(château fermé depuis l'An 17 — ouvert ce soir)", Vector3(0, 0.95, -4.6), 0.0, 0.0035, Color(0.2, 0.15, 0.1))
	plaque.visible = true
	bas = _person("basile", Characters.BASILE_PLUME, 0, Vector3(0.0, 0.05, -2.8), 0.0)
	guests["jules"] = _person("jules", Characters.JULES, 0, Vector3(-3.0, 0.05, -1.0), 0.6)
	guests["jules2"] = _person("jules2", Characters.JULES_JEUNE, 0, Vector3(3.5, 0.05, -0.5), -0.6)
	_hot(0, Vector3(-6.0, 1.2, 3.0), "Sortir du château", func(): exit(), func(): return true, 1.8)
	_hot(0, Vector3(0, 1.6, -4.0), "Lire l'écriteau", func():
		_flag("m_d5")
		Fx.text(v.world, ro(0) + Vector3(0, 2.6, -3.8), "« Château fermé depuis l'An 17. Ouvert ce soir. »", Color(1.0, 0.95, 0.7), 0.8, 3.5)
		_pico("An 17, fermé. Note-le : la date, pas l'écriteau."), func(): return true, 1.8)
	_hot(0, Vector3(0.0, 2.0, -2.8), "Parler à Basile", _talk_basile, func(): return _s("m_intro") and not _scene_on, 1.8)


func _talk_basile() -> void:
	var s := solved()
	if not _s("m_classify_done"):
		bas.chibi.say(["Questions ? À la fin du bal. Je réponds toujours à la fin.", "Dansez, observez, comparez. Je ne cache rien... enfin, rien d'important. Rien de ce que vous trouveriez.", "Ce château garde tout. C'est sa qualité. C'est aussi son principal défaut."][randi() % 3], 5.0)
	elif s < 4:
		bas.chibi.say("Vous avez l'œil. Armand avait ce regard. Suivez-le : les portes parlent plus que les invités.", 5.0)
	else:
		bas.chibi.say("Les mots sont rares, ici. Allez à la bibliothèque. Je vous y attends.", 5.0)


# --- Salle 2 : Galerie des portraits ---------------------------------------------------------------------

func _r2(r: Node3D) -> void:
	var b := Builder.new()
	var xs := [-5.6, -2.8, 0.0, 2.8, 5.6]
	var faces := [Color(1.0, 0.82, 0.7), Color(0.98, 0.8, 0.68), Color(0.95, 0.75, 0.6), Color(1.0, 0.86, 0.76), Color(0.9, 0.78, 0.7)]
	var bgs := [Color(0.3, 0.4, 0.55), Color(0.35, 0.5, 0.4), Color(0.55, 0.4, 0.35), Color(0.6, 0.55, 0.3), Color(0.45, 0.4, 0.55)]
	for k in 5:
		var x: float = xs[k]
		_frame(b, x, 2.7, 1.6, 2.2, -4.78, bgs[k])
		b.sphere(0.4, Vector3(x, 3.0, -4.66), faces[k], Vector3(0.9, 1.0, 0.45), Basis(), 10)
		b.capsule(0.45, 1.0, Vector3(x, 2.1, -4.68), Color(0.2, 0.2, 0.3) if k != 3 else Color(0.95, 0.85, 0.5), Basis(), Vector3(1.0, 1.0, 0.4))
	# le portrait vexé (n° 5) tourne le dos : un visage de profil, la bouche en bas
	b.box(Vector3(0.22, 0.05, 0.02), Vector3(5.6, 2.85, -4.56), Color(0.4, 0.1, 0.1), false)
	b.box(Vector3(5.0, 0.12, 0.6), Vector3(0, 0.06, -3.2), Color(0.5, 0.15, 0.2), false)
	b.build(r, Toon.vertex_color(0.01), "Portraits")
	_label(r, "Basile & Armand", Vector3(-5.6, 1.35, -4.6), 0.0, 0.0028, Color(1, 0.95, 0.8))
	_label(r, "Jules Pivoine", Vector3(-2.8, 1.35, -4.6), 0.0, 0.0028, Color(1, 0.95, 0.8))
	_label(r, "Pétronille", Vector3(0.0, 1.35, -4.6), 0.0, 0.0028, Color(1, 0.95, 0.8))
	_label(r, "Lina Plume", Vector3(2.8, 1.35, -4.6), 0.0, 0.0028, Color(1, 0.95, 0.8))
	_label(r, "???", Vector3(5.6, 1.35, -4.6), 0.0, 0.0028, Color(1, 0.95, 0.8))
	_hot(1, Vector3(-5.6, 1.7, -3.6), "Lire la plaque", func():
		_flag("m_d1")
		_plaque("« Basile Plume et Armand Chardon, fondateurs du Grand Registre. An 1. »")
		_pico("Deux hommes, un livre, sourires de gens qui ne savent pas encore."), func(): return true)
	_hot(1, Vector3(-2.8, 1.7, -3.6), "Lire la plaque", func():
		_flag("m_p_jules")
		_plaque("« Jules Pivoine, majordome. Un second exemplaire, plus jeune, a été retiré du service. »")
		_pico("« Retiré du service ». Dans cette maison, on retire les gens comme des chaises."), func(): return true)
	_hot(1, Vector3(0.0, 1.7, -3.6), "Lire la plaque", func():
		_flag("m_p_petra")
		_plaque("« Pétronille Mauve, trente ans (version de l'An 3). Non retenue : trop curieuse. »")
		_pico("Non retenue ! Pétronille a donc eu une autre elle. Plus jeune, plus bavarde."), func(): return true)
	_hot(1, Vector3(2.8, 1.7, -3.6), "Lire la plaque", func():
		_flag("m_d2")
		_plaque("« Lina Plume, née l'An 8. A dessiné l'île en entier l'An 14, sans lever le crayon. »")
		_pico("Lina... C'est le nom sur la lettre aux Hautes-Miettes. L. Plume."), func(): return true)
	_hot(1, Vector3(5.6, 1.7, -3.6), "Consoler le portrait vexé", _comfort_portrait, func(): return true, 2.2)


func _plaque(t: String) -> void:
	Fx.text(v.world, player.global_position + Vector3(0, 2.2, 0), t, Color(1.0, 0.95, 0.7), 0.7, 4.5)


func _comfort_portrait() -> void:
	if _s("portrait_ok"):
		Fx.text(v.world, ro(1) + Vector3(5.6, 3.4, -4.0), "(Il sourit un peu. De dos.)", Color(1.0, 0.9, 0.8), 0.7, 2.5)
		return
	_flag("portrait_ok")
	Save.shells += 6
	Save.save_game()
	Fx.text(v.world, ro(1) + Vector3(5.6, 3.5, -4.0), "« Le peintre ne vous a pas voulu laid : il n'avait que du vert. »", Color(1.0, 0.95, 0.7), 0.7, 4.0)
	_later(1.5, func(): Fx.text(v.world, ro(1) + Vector3(5.6, 3.2, -4.0), "Le portrait se retourne. +6 coquillages", Color(1.0, 0.9, 0.4), 0.8, 3.0))
	_pico("Un portrait consolé. Cela ne figure dans aucune enquête, mais je me sens meilleur.")


# --- Salle 3 : Salle de bal -----------------------------------------------------------------------------

func _r3(r: Node3D) -> void:
	var b := Builder.new()
	# damier de bal
	for i in 6:
		for j in 4:
			if (i + j) % 2 == 0:
				b.box(Vector3(2.4, 0.02, 2.4), Vector3(-6.0 + i * 2.4 + 1.2, 0.01, -3.6 + j * 2.4 + 1.2), Color(0.6, 0.65, 0.85), false)
	# scène
	b.box(Vector3(5.0, 0.6, 2.2), Vector3(0, 0.3, -3.7), Color(0.55, 0.35, 0.3), true)
	b.box(Vector3(5.4, 0.12, 0.3), Vector3(0, 0.66, -2.5), Color(0.8, 0.15, 0.25), false)
	# buffet (les vrais invités mangent...)
	b.box(Vector3(2.4, 0.9, 0.9), Vector3(6.2, 0.45, -3.0), Color(0.95, 0.9, 0.8), true)
	b.sphere(0.2, Vector3(5.7, 1.05, -3.0), Color(0.9, 0.3, 0.3), Vector3.ONE, Basis(), 8)
	b.sphere(0.2, Vector3(6.2, 1.05, -3.0), Color(0.95, 0.8, 0.3), Vector3(1, 0.7, 1), Basis(), 8)
	b.sphere(0.2, Vector3(6.7, 1.05, -3.0), Color(0.5, 0.8, 0.4), Vector3.ONE, Basis(), 8)
	# miroir
	b.box(Vector3(3.4, 3.4, 0.12), Vector3(-2.0, 2.7, 4.78), GOLD.darkened(0.25), false)
	b.box(Vector3(3.0, 3.0, 0.14), Vector3(-2.0, 2.7, 4.76), Color(0.75, 0.88, 0.98), false)
	# pupitre / carnet de bal
	b.cylinder(0.12, 0.2, 1.1, Vector3(5.5, 0.55, 3.0), Color(0.5, 0.35, 0.25), Basis(), 8)
	b.box(Vector3(0.6, 0.06, 0.45), Vector3(5.5, 1.12, 3.0), Color(0.95, 0.92, 0.8), false, Basis(Vector3.RIGHT, -0.4))
	b.build(r, Toon.vertex_color(0.01), "Bal")
	_mirror_lbl = _label(r, "", Vector3(-2.0, 2.7, 4.6), PI, 0.004, Color(0.2, 0.3, 0.5))
	# les six invités
	for id in ["jules", "jules2", "colonel", "perle", "archet", "petra"]:
		var gp: Array = GUEST_POS[id]
		var def: Dictionary = {"colonel": Characters.COLONEL, "perle": Characters.PERLE, "archet": Characters.ARCHET, "petra": Characters.PETRA}.get(id, {})
		if def.is_empty():
			continue
		guests[id] = _person(id, def, gp[0], gp[1], gp[2])
	# Jules et son double sont présentés au Hall, puis rejoignent le bal
	for id in ["jules", "jules2", "colonel", "perle", "archet", "petra"]:
		var local: Vector3 = GUEST_POS[id][1]
		var gname: String = GUESTS[id]["name"]
		var pos := local + Vector3(0, 2.05, 0)
		_hot(2, pos, "Parler à " + gname, _talk.bind(id), func(): return _s("m_intro") and not _scene_on, 2.4)
		for k in 3:
			var labels := ["Vrai invité", "Souvenir", "Version abandonnée"]
			var kinds := ["real", "mem", "ver"]
			_hot(2, local + Vector3(-1.9 + k * 1.9, 2.75, 0), labels[k], _accuse.bind(id, kinds[k]), func(): return _s("m_classify") and not resolved.has(id), 1.9)
	_hot(2, Vector3(-2.0, 1.6, 3.7), "Regarder dans le miroir", _mirror, func(): return true)
	_hot(2, Vector3(5.5, 1.7, 2.2), "Lire le carnet de bal", _carnet, func(): return true)
	_hot(2, Vector3(5.5, 2.3, 2.2), "Remplir le plan de table", _start_classify, func(): return _s("m_carnet") and _s("m_mirror") and talked.size() >= 4 and not _s("m_classify"), 2.4)
	_hot(2, Vector3(6.2, 1.8, -2.0), "Observer le buffet", func():
		_flag("m_buffet")
		Fx.text(v.world, ro(2) + Vector3(6.2, 2.4, -2.5), "Des tartelettes. Les assiettes de Jules et du Colonel sont vides. Les autres ? Pleines. Intactes.", Color(1.0, 0.95, 0.7), 0.7, 5.0)
		_pico("Personne d'autre n'a touché à rien. Un souvenir n'a pas faim, non ?"), func(): return true, 2.0)
	_hot(2, Vector3(-6.0, 1.2, 3.0), "Sortir du château", func(): exit(), func(): return true, 1.8)


func _talk(id: String) -> void:
	talked[id] = true
	var n := int(talk_n.get(id, 0))
	talk_n[id] = n + 1
	var lines: Array = GUESTS[id]["lines"]
	var g: Talker = guests[id]
	g.chibi.say(lines[mini(n, lines.size() - 1)], 6.0)
	if id == "archet":
		_violin_i = 0
	if talked.size() == 4 and not said.has("talked4"):
		said["talked4"] = true
		_pico("Quatre conversations. Tu as de quoi compléter le plan de table, si tu as regardé le carnet et le miroir.")


func _mirror() -> void:
	_flag("m_mirror")
	_mirror_lbl.text = "Dans le reflet :\nJules\nle Colonel\n(et personne d'autre)"
	Fx.text(v.world, ro(2) + Vector3(-2.0, 3.8, 3.5), "Dans le miroir : deux invités. Seulement deux.", Color(0.8, 0.95, 1.0), 0.8, 4.0)
	_pico("Les vrais invités ont un reflet. Les autres... ont une histoire, pas de reflet.")


func _carnet() -> void:
	_flag("m_carnet")
	Fx.text(v.world, ro(2) + Vector3(5.5, 2.8, 2.6), "Invités : J. Pivoine, Col. Boutonnière. En marge, à la craie : « Mlle Perle, M. Archet : à répéter chaque soir. »  « Pétra et Jules (Jeune) : à garder à distance de leurs originaux. »", Color(1.0, 0.95, 0.75), 0.6, 8.0)
	_pico("À répéter chaque soir = des souvenirs qui rejouent. À garder à distance = des versions qui se vexent.")


func _start_classify() -> void:
	_flag("m_classify")
	_say_ele("Très bien. Pour chacun : vrai invité (il a un reflet et il mange), souvenir (il répète la même chose), ou version abandonnée (il se contredit, il se vexe).")
	_pico("Un bouton en haut de chaque invité. Je n'ai aucune pression. Aucune.")


func _accuse(id: String, kind: String) -> void:
	var truth: String = GUESTS[id]["truth"]
	var g: Talker = guests[id]
	if kind == truth:
		resolved[id] = kind
		var tag: String = {"real": "✔ Vrai invité", "mem": "✔ Souvenir", "ver": "✔ Version abandonnée"}[kind]
		Fx.text(v.world, g.global_position + Vector3(0, 2.8, 0), tag, Color(0.7, 1.0, 0.75), 0.9, 3.0)
		Bells.play(v.world, "ding", 0.0, g.global_position + Vector3(0, 1.5, 0), -4.0)
		if resolved.size() >= 6:
			_classified()
	else:
		wrong_n += 1
		g.chibi.say(["Comment osez-vous !", "Je suis profondément vexé(e).", "Vous vous trompez, et avec élégance, en plus.", "Je note votre nom. Au crayon."][wrong_n % 4], 3.0)
		Bells.play(v.world, "boing", 0.0, g.global_position + Vector3(0, 1.5, 0), -6.0)


func _classified() -> void:
	_flag("m_classify_done")
	_solve(2)
	_seq([
		["e", "Deux vrais, deux souvenirs, deux versions abandonnées. Un château plein d'invités qui ne sont pas là, tout ça pour un seul homme."],
		["p", "Basile n'a pas jeté ses brouillons : il les a invités au bal. C'est triste ou c'est romantique ? Je n'ai pas encore décidé."],
		["e", "Il y a une porte de service qui vient de s'ouvrir. Allons écouter derrière les portes : c'est là que les maisons disent la vérité."],
	], func(): pass)


# --- Salle 4 : Couloir des portes -------------------------------------------------------------------------

func _r4(r: Node3D) -> void:
	var b := Builder.new()
	var xs := [-4.5, 0.0, 4.5]
	var cols := [Color(0.4, 0.28, 0.2), Color(0.35, 0.3, 0.45), Color(0.8, 0.7, 0.85)]
	for k in 3:
		var x: float = xs[k]
		b.box(Vector3(1.6, 2.8, 0.2), Vector3(x, 1.4, -4.75), GOLD.darkened(0.3), false)
		b.box(Vector3(1.3, 2.6, 0.24), Vector3(x, 1.3, -4.72), cols[k], false)
		b.sphere(0.07, Vector3(x + 0.45, 1.3, -4.55), GOLD, Vector3.ONE, Basis(), 6)
	b.cylinder(0.3, 0.3, 0.03, Vector3(0, 0.02, 0), Color(0.55, 0.15, 0.2), Basis(), 14)
	# étagère avec un livre rouge
	b.box(Vector3(0.8, 3.0, 1.6), Vector3(6.9, 1.5, -2.6), Color(0.45, 0.3, 0.2), true)
	b.box(Vector3(0.12, 0.45, 0.3), Vector3(6.45, 1.7, -2.6), Color(0.85, 0.15, 0.2), false)
	b.build(r, Toon.vertex_color(0.01), "Portes")
	_label(r, "SALON DE LECTURE (n° 1)", Vector3(-4.5, 3.2, -4.55), 0.0, 0.004, Color(1, 0.95, 0.8))
	_label(r, "CABINET DU CONSERVATEUR", Vector3(0.0, 3.2, -4.55), 0.0, 0.004, Color(1, 0.95, 0.8))
	_label(r, "CHAMBRE FERMÉE (ne pas déranger)", Vector3(4.5, 3.2, -4.55), 0.0, 0.004, Color(0.3, 0.2, 0.3))
	_hot(3, Vector3(-4.5, 1.7, -3.7), "Écouter à la porte", _door_a, func(): return not _s("m_door_a"))
	_hot(3, Vector3(0.0, 1.7, -3.7), "Écouter à la porte", _door_b, func(): return not _s("m_door_b"))
	_hot(3, Vector3(4.5, 1.7, -3.7), "Écouter à la porte", _door_c, func(): return not _s("m_door_c"))
	_hot(3, Vector3(6.0, 1.8, -2.6), "Tirer le livre rouge", _book, func(): return _s("m_door_a") and _s("m_door_b") and _s("m_door_c") and solved() < 4, 2.2)
	_hot(3, Vector3(-6.0, 1.2, 3.0), "Sortir du château", func(): exit(), func(): return true, 1.8)


func _door_a() -> void:
	_flag("m_door_a")
	_flag("m_d4")
	_seq([
		["t", "Derrière la porte : Basile et Jules, à voix basse."],
		["b", "Jules, les versions se vexent, les souvenirs répètent, les vrais mangent. Ne les mélangez plus jamais, je vous prie."],
		["j", "Monsieur, ça fait vingt-sept ans que je les range. Depuis le matin de la Séparation, An 16, rien n'a bougé. Surtout pas vous."],
		["b", "Pas un mot au Colonel. Il a trop bonne mémoire pour un homme poli."],
	], func(): _pico("Le matin de la Séparation, An 16. J'ai noté. Je note sans comprendre, c'est ma spécialité."))


func _door_b() -> void:
	_flag("m_door_b")
	_flag("m_d3")
	_seq([
		["t", "Derrière la porte : le Colonel Boutonnière, tout seul, qui parle au mur."],
		["t", "« Armand, tu es parti le soir même, An 16, avec un sac plein de pages. Tu n'as dit au revoir à personne. »"],
		["t", "« Il te cherche encore, Basile, tu sais. Il ne l'avouera jamais. »"],
	], func(): _pico("Armand parti le soir même, An 16. Et le Colonel parle à des murs. Il a raison : ils écoutent mieux."))


func _door_c() -> void:
	_flag("m_door_c")
	_seq([
		["t", "Derrière la porte : une berceuse, à peine audible. Une voix d'enfant."],
		["t", "« Papa, regarde, j'ai dessiné l'île ! Elle a un phare qui regarde la mer... »"],
		["t", "Une autre voix, très douce : « C'est magnifique, ma chérie. Il regarde la mer. Exactement. » (Il l'a déjà dit mille fois.)"],
		["e", "Une enfant. Dans la chambre du fond. Basile y vient chaque soir. Il faut voir de quelle chambre il s'agit."],
	], func(): _pico("Le phare qui regarde la mer... Le phare de Port-Biscornu regarde la terre. Quelqu'un a dû se tromper de dessin."))


func _book() -> void:
	_flag("m_book")
	_solve(3)
	Fx.puff(v.world, ro(3) + Vector3(6.4, 1.7, -2.6), Color(1.0, 0.85, 0.7))
	_say_ele("Un passage derrière l'étagère. Une bibliothèque entière. Pico, ne touche à rien, sauf si ça brille.")


# --- Salle 5 : Bibliothèque et Chambre de Lina ---------------------------------------------------------------

func _r5(r: Node3D) -> void:
	var b := Builder.new()
	for sx in [-1.0, 1.0]:
		for k in 4:
			b.box(Vector3(0.7, 4.8, 2.0), Vector3(sx * 6.9, 2.4, -3.6 + k * 2.4), Color(0.4, 0.28, 0.2), true)
			for j in 5:
				b.box(Vector3(0.1, 0.5, 0.25 + 0.05 * ((j + k) % 3)), Vector3(sx * 6.55, 0.8 + j * 0.85, -3.6 + k * 2.4), RAINBOW[(j + k) % 7], false)
	b.box(Vector3(10.0, 0.12, 1.4), Vector3(0, 0.95, 1.4), Color(0.5, 0.33, 0.22), true)
	for sx in [-4.4, 4.4]:
		b.box(Vector3(0.2, 0.9, 1.2), Vector3(sx, 0.45, 1.4), Color(0.4, 0.28, 0.2), false)
	# l'alcôve de la chambre de Lina (derrière le panneau)
	b.box(Vector3(5.0, 0.4, 6.0), Vector3(0, -0.2, -8.2), Color(0.95, 0.88, 0.78), true)
	b.box(Vector3(5.0, 0.2, 6.0), Vector3(0, 4.0, -8.2), Color(0.8, 0.75, 0.7), true)
	b.box(Vector3(0.2, 4.0, 6.0), Vector3(-2.4, 2.0, -8.2), Color(0.95, 0.75, 0.8), true)
	b.box(Vector3(0.2, 4.0, 6.0), Vector3(2.4, 2.0, -8.2), Color(0.95, 0.75, 0.8), true)
	b.box(Vector3(5.0, 4.0, 0.2), Vector3(0, 2.0, -11.1), Color(0.97, 0.82, 0.85), true)
	b.build(r, Toon.vertex_color(0.01), "Biblio")
	# panneau mobile
	_panel = Node3D.new()
	_panel.name = "Panneau"
	r.add_child(_panel)
	var pb := Builder.new()
	pb.box(Vector3(3.0, 3.0, 0.3), Vector3(0, 1.5, -5.0), Color(0.4, 0.28, 0.2), true)
	for j in 4:
		pb.box(Vector3(2.4, 0.5, 0.2), Vector3(0, 0.5 + j * 0.7, -4.8), RAINBOW[j * 2 % 7], false)
	pb.build(_panel, Toon.vertex_color(0.01), "Etagere")
	# décor de la chambre : dessins aux murs, lit minuscule, crayons
	var cb := Builder.new()
	cb.box(Vector3(1.6, 0.4, 0.9), Vector3(-1.4, 0.2, -10.4), Color(0.95, 0.7, 0.75), false)
	cb.box(Vector3(1.4, 0.15, 0.7), Vector3(-1.4, 0.45, -10.4), Color(1.0, 0.95, 0.9), false)
	for k in 5:
		_frame(cb, -1.8 + k * 0.9, 2.4 + (k % 2) * 0.4, 0.6, 0.5, -11.0, RAINBOW[k])
	for k in 6:
		cb.box(Vector3(0.05, 0.05, 0.3), Vector3(0.6 + k * 0.15, 0.03, -8.8), RAINBOW[k], false, Basis(Vector3.UP, k * 0.5))
	cb.build(r, Toon.vertex_color(0.01), "Chambre")
	_label(r, "CHAMBRE DE LINA", Vector3(0, 3.4, -10.95), 0.0, 0.007, Color(0.6, 0.25, 0.35))
	var llt := OmniLight3D.new()
	llt.omni_range = 7.0
	llt.light_energy = 1.0
	llt.light_color = Color(1.0, 0.9, 0.8)
	r.add_child(llt)
	llt.position = Vector3(0, 3.0, -8.2)
	lina = _person("lina", Characters.LINA, 4, Vector3(0.0, 0.05, -8.8), PI)
	# le puzzle : six cartes
	_tl_label = _label(r, "Dans l'ordre :\n(rien encore)", Vector3(0, 3.8, -4.6), 0.0, 0.006, Color(1.0, 0.95, 0.75))
	for k in 6:
		var ev: int = EVENT_SHUFFLE[k]
		var x := -4.4 + k * 1.76
		var lb := _label(r, EVENTS[ev], Vector3(x, 1.25, 1.45), 0.0, 0.0022, Color(0.15, 0.1, 0.05))
		lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lb.width = 560.0
		_card_lbls.append(lb)
		var cb2 := Builder.new()
		cb2.box(Vector3(1.4, 0.04, 0.9), Vector3(x, 1.03, 1.4), Color(0.97, 0.94, 0.82), false)
		cb2.build(r, Toon.vertex_color(0.006), "Carte%d" % k)
		_hot(4, Vector3(x, 1.9, 1.4), "Placer cette carte", _card.bind(ev, k), func(): return _s("m_book") and not _s("m_time"), 1.7)
	_hot(4, Vector3(-6.0, 1.2, 3.0), "Sortir du château", func(): exit(), func(): return true, 1.8)


const RAINBOW := [Color(1.0, 0.4, 0.4), Color(1.0, 0.65, 0.3), Color(1.0, 0.9, 0.35), Color(0.5, 0.85, 0.4), Color(0.4, 0.8, 0.95), Color(0.5, 0.5, 1.0), Color(0.85, 0.5, 0.95)]


func _card(ev: int, k: int) -> void:
	if ev == _tl_progress:
		_tl_progress += 1
		_card_lbls[k].modulate = Color(0.1, 0.5, 0.2)
		Bells.play(v.world, "marimba", 261.63 * pow(1.1225, _tl_progress), ro(4) + Vector3(0, 1.4, 1.4), -2.0)
		var txt := "Dans l'ordre :\n"
		for n in _tl_progress:
			txt += "%d. %s\n" % [n + 1, EVENTS[n]]
		_tl_label.text = txt
		if _tl_progress >= 6:
			_timeline_done()
	else:
		var missing := ""
		if not _s("m_d1") or not _s("m_d2"):
			missing = " Il te manque des plaques de la galerie."
		elif not _s("m_d3") or not _s("m_d4"):
			missing = " Il te manque ce qu'on entend derrière les portes."
		elif not _s("m_d5"):
			missing = " Il te manque l'écriteau du hall."
		_tl_progress = 0
		for lb in _card_lbls:
			lb.modulate = Color(0.15, 0.1, 0.05)
		_tl_label.text = "Dans l'ordre :\n(rien encore)"
		Bells.play(v.world, "boing", 0.0, ro(4) + Vector3(0, 1.4, 1.4), -4.0)
		_pico("Ça ne colle pas : on recommence. An 1, An 8, An 14, An 16 matin, An 16 soir, An 17." + missing)


func _timeline_done() -> void:
	_flag("m_time")
	_solve(4)
	Fx.puff(v.world, ro(4) + Vector3(0, 1.2, -4.8), Color(1.0, 0.9, 0.7))
	_later(0.5, func():
		_panel.queue_free()
		_panel = null
		_seq([
			["e", "Les années se tiennent. Le Registre a été fondé, Lina est née, elle a dessiné l'île, puis la Séparation, puis mon père parti, puis le château fermé. Elle n'apparaît plus après l'An 16."],
			["p", "Le panneau coulisse. Il y a de la lumière derrière. Et une petite voix qui chante."],
		], func(): pass))


# --- La Chambre de Lina : la scène ---------------------------------------------------------------

func _lina_scene() -> void:
	_scene_on = true
	bas.global_position = ro(4) + Vector3(1.5, 0.05, -6.2)
	bas.rest_yaw = PI
	bas.chibi.rotation.y = PI
	Fx.puff(v.world, bas.global_position + Vector3(0, 1.2, 0), Color(1.0, 0.9, 0.7))
	_seq([
		["l", "Papa ! Regarde, j'ai dessiné l'île ! Elle a un phare qui regarde la mer."],
		["b", "Il regarde la mer. Exactement, ma chérie. C'est magnifique."],
		["l", "Papa ! Regarde, j'ai dessiné l'île ! Elle a un phare qui regarde la mer."],
		["b", "Elle me dit cette phrase depuis vingt-sept ans. Je viens l'écouter tous les soirs. Je lui réponds la même chose. C'est le plus beau dialogue de ma vie... et le plus vide."],
		["e", "Elle ne grandit pas."],
		["b", "Elle ne s'efface pas non plus. Le matin de la Séparation, l'An 16, Lina était dans la salle du Registre. Quand les pages se sont séparées, elle a... Je n'ai pas pu la retenir. J'ai pu retenir son souvenir."],
		["p", "Une version conservée. Un souvenir qui répète. Elle n'est pas morte dans le Registre : elle est rangée dedans."],
		["b", "Si l'île redevient libre, ce livre ne la retiendra plus. Elle partira, comme tout le monde part. Je n'ai jamais voulu enfermer l'île, Éléonore. J'ai voulu ne pas enterrer ma fille."],
		["e", "Mon père a rattrapé les pages pour que personne ne perde ce qu'il aime. Pas pour que plus rien ne change."],
		["b", "Alors il est parti aussi. Il n'a pas dit au revoir. Je ne lui ai pas laissé le temps, je crois."],
		["l", "Papa ! Regarde, j'ai dessiné l'île ! Elle a un phare qui regarde la mer."],
		["b", "Revenez quand vous voudrez. Les portes sont ouvertes. Je ne vous retiens pas : ça, au moins, je sais le faire."],
	], _end_chapter)


func _end_chapter() -> void:
	_scene_on = false
	if _s("ch6_done"):
		return
	Save.story["ch6_done"] = true
	Save.story["lina_met"] = true
	Save.shells += 80
	Save.save_game()
	Fx.text(v.world, ro(4) + Vector3(0, 3.8, -6.0), "CHAPITRE 6 TERMINÉ", Color(1.0, 0.95, 0.5), 1.6, 6.0)
	Fx.text(v.world, ro(4) + Vector3(0, 3.0, -6.0), "+80 coquillages", Color(1.0, 0.9, 0.5), 0.8, 4.0)
	_later(4.5, func(): Fx.text(v.world, ro(4) + Vector3(0, 3.4, -6.0), "À suivre : tout ce qui mérite d'être oublié...", Color(0.9, 0.95, 1.0), 0.7, 6.0))


# --- Entrée et sortie --------------------------------------------------------------------------------

func event(ev: String, _node) -> void:
	if ev == "m_go":
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
	for i in 5:
		if i < solved():
			_open_gate(i)
	if _s("m_time") and _panel != null:
		_panel.queue_free()
		_panel = null
	if _s("m_classify_done"):
		for id in ["jules", "jules2"]:
			guests[id].reparent(get_child(2))
			guests[id].position = GUEST_POS[id][1]
		for id in ["colonel", "perle", "archet", "petra"]:
			resolved[id] = GUESTS[id]["truth"]
		resolved["jules"] = "real"
		resolved["jules2"] = "ver"
	elif _s("m_intro"):
		for id in ["jules", "jules2"]:
			guests[id].reparent(get_child(2))
			guests[id].position = GUEST_POS[id][1]
	var s := mini(solved(), 4)
	var start := 0 if not _s("m_intro") else s
	player.global_position = ro(start) + Vector3(-6.0, 0.15, 0)
	player._vy = 0.0
	player._face_yaw(-PI * 0.5)
	player._place_origin(true, 0.0)
	last_room = -1
	var tw: Tween = v.maquette._fade_to(1.0, 0.0, 1.2)
	tw.tween_callback(_unbusy)
	Fx.text(v.world, ro(start) + Vector3(-3.0, 3.0, 0), "LE CHÂTEAU DES VERSIONS OFFICIELLES", Color(1.0, 0.95, 0.7), 1.2, 3.5)


func _unbusy() -> void:
	busy = false
	if not _s("m_intro"):
		_intro()


func exit() -> void:
	if busy:
		return
	busy = true
	var tw: Tween = v.maquette._fade_to(0.0, 1.0, 1.0)
	tw.tween_callback(_exit_now)


func _exit_now() -> void:
	active = false
	visible = false
	v.y.place_eleonore()
	player.global_position = _ret
	player._vy = 0.0
	player._face_yaw(PI)
	player._place_origin(true, 0.0)
	var tw2: Tween = v.maquette._fade_to(1.0, 0.0, 1.2)
	tw2.tween_callback(_unbusy_exit)


func _unbusy_exit() -> void:
	busy = false


func _intro() -> void:
	ele.global_position = ro(0) + Vector3(-4.8, 0.05, 2.5)
	_seq([
		["j", "Annonçons : le Joueur, Mademoiselle Chardon, et un petit être en papier. Le bal des Versions Officielles est ouvert."],
		["j2", "Je l'aurais annoncé avec plus de panache. Et dans le bon ordre alphabétique."],
		["j", "Vous n'êtes pas invité à parler, jeune homme."],
		["j2", "Je suis aussi invité que vous. Et j'ai deux fois moins de rides."],
		["b", "Bienvenue au château. Je m'appelle Basile Plume. Je ne vous ai pas fait venir pour vous combattre : je vous ai fait venir pour vous montrer que j'ai raison, doucement."],
		["b", "Ce soir, mon château est à vous. Dansez, regardez, parlez. Posez toutes vos questions à la fin du bal. Je ne cache rien... enfin, rien de ce que vous ne trouveriez pas."],
		["e", "Il est poli. C'est ce qui m'inquiète."],
		["p", "Moi je suis très détendu. Regardez mon sourire. Il est en papier, il ne dit rien."],
	], _intro_end)


func _intro_end() -> void:
	_flag("m_intro")
	_flag("v6_started")
	for id in ["jules", "jules2"]:
		guests[id].reparent(get_child(2))
		guests[id].position = GUEST_POS[id][1]
	_say_ele("Une règle : trois sortes d'invités. Les vrais (reflet, appétit), les souvenirs (ils répètent), les versions abandonnées (elles se contredisent). Commençons par la galerie.")
	Save.save_game()


# --- Boucle --------------------------------------------------------------------------------------------

func _on_room(i: int) -> void:
	if said.has(i):
		return
	said[i] = true
	if not _s("m_intro"):
		return
	var lines := [
		"Le hall. Tout y est propre. Même les marches s'essuient les pieds.",
		"Cinq portraits. Cherchons les plaques : les dates comptent. Surtout celles qu'on n'aime pas.",
		"La salle de bal. Six invités, un miroir, un carnet. Parlez à chacun, regardez le miroir, et lisez le carnet de bal.",
		"Les portes parlent. Écoutons-les toutes. Ensuite, un livre rouge, comme dans tous les mauvais romans.",
		"La bibliothèque. Six cartes, six événements. Remettons les années dans l'ordre.",
	]
	_later(1.2, func(): _say_ele(lines[i]))
	if ele:
		ele.global_position = ro(i) + Vector3(-4.8, 0.05, 2.5)
		ele.chibi.rotation.y = 0.0


func _physics_process(delta: float) -> void:
	if not active or player == null:
		return
	# Le violoniste (un souvenir) rejoue toujours la même phrase
	if talked.has("archet") or cur() == 2:
		_violin_t -= delta
		if _violin_t <= 0.0 and cur() == 2:
			var tune := [329.63, 392.0, 440.0, 392.0, 329.63, 293.66, 329.63]
			Bells.play(v.world, "pluck", tune[_violin_i % tune.size()], ro(2) + Vector3(0, 1.4, -3.7), -8.0)
			_violin_i += 1
			_violin_t = 0.5 if _violin_i % 7 != 0 else 2.5
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
	if c == 4 and _s("m_time") and not _s("ch6_done") and not _scene_on and pp.z < ro(4).z - 5.6:
		_lina_scene()
