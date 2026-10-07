extends RefCounted
## Port-Biscornu, v7 : l'enquête du « mardi disparu ».
## Boulangerie, atelier, chez Pétronille, maison abandonnée (Éléonore),
## Gérard sur le ponton, Marguerite et sa peinture, boutons d'indices.
## Les boutons (« hotspots ») apparaissent quand on est près et que la
## condition est remplie ; ils se visent comme les menus (rayon + gâchette).

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Island := preload("res://scripts/island.gd")
const Fx := preload("res://scripts/fx.gd")
const Save := preload("res://scripts/save.gd")
const Inv := preload("res://scripts/inventory_items.gd")
const Props := preload("res://scripts/props.gd")
const Characters := preload("res://scripts/characters.gd")
const Talker := preload("res://scripts/talker.gd")
const ChoiceButton := preload("res://scripts/choice_button.gd")
const VB := preload("res://scripts/village_build.gd")

const H := Island.VILLAGE_H
const INK := Color(0.13, 0.08, 0.17)

const BAKERY := {"pos": Vector2(-9.0, -44.0), "yaw": 0.0, "w": 5.0, "d": 5.0, "h": 3.2}
const WORKSHOP := {"pos": Vector2(10.5, -60.0), "yaw": 0.0, "w": 5.0, "d": 4.0, "h": 3.0}
const PETRO := {"pos": Vector2(-18.5, -58.5), "yaw": PI * 0.5, "w": 5.0, "d": 4.6, "h": 3.0}
const RUIN := {"pos": Vector2(18.5, -58.5), "yaw": -PI * 0.5, "w": 5.0, "d": 4.6, "h": 3.0}
const CLUES := ["c_baker", "c_fisher", "c_house", "c_inn", "c_light", "c_petro"]

var v                      # le village
var hot: Array = []
var barricade: StaticBody3D
var trail: Node3D
var piece_b_node: Node3D


func build() -> void:
	_bakery()
	_workshop()
	_petronille()
	_ruin()
	_pier_and_paint()
	_inn_ledger()
	_lighthouse()
	refresh_trail()


# --- Aides --------------------------------------------------------------------------------------

func tuesday() -> bool:
	return Save.story.get("tuesday", false)


func clue_count() -> int:
	var n := 0
	for k in CLUES:
		if Save.story.get(k, false):
			n += 1
	return n


func hotspot(parent: Node3D, pos: Vector3, text: String, cb: Callable, cond: Callable, width := 1.7, dist := 3.2) -> void:
	var bt := ChoiceButton.new()
	parent.add_child(bt)
	bt.position = pos
	bt.setup(text, cb, width, Color(0.8, 0.95, 1.0))
	bt.visible = false
	bt.collision_layer = 0
	hot.append({"btn": bt, "cond": cond, "dist": dist})


func update() -> void:
	if v.player == null:
		return
	var cam: Vector3 = v.player.camera.global_position
	for h in hot:
		var bt = h["btn"]
		var on: bool = bt.global_position.distance_to(cam) < float(h["dist"]) and h["cond"].call()
		if on != bt.visible:
			bt.visible = on
			bt.collision_layer = 16 if on else 0
		if on:
			var to: Vector3 = cam - bt.global_position
			to.y = 0.0
			if to.length() > 0.1:
				bt.global_rotation.y = atan2(to.x, to.z)


func _fwd_pos(dist := 1.6) -> Vector3:
	var f: Vector3 = -v.player.camera.global_basis.z
	f.y = 0.0
	f = f.normalized() if f.length() > 0.01 else Vector3.FORWARD
	return v.player.camera.global_position + f * dist


func clue(key: String, title: String, detail: String, pico_line: String) -> void:
	if Save.story.get(key, false):
		return
	Save.story[key] = true
	Save.save_game()
	var p := _fwd_pos(1.6)
	Fx.text(v.world, p + Vector3(0, 0.75, 0), "INDICE : " + title, Color(1.0, 0.92, 0.4), 0.7, 4.0)
	v.get_tree().create_timer(0.9).timeout.connect(func():
		Fx.text(v.world, p + Vector3(0, -0.15, 0), detail, Color(0.9, 0.95, 1.0), 0.5, 4.5))
	var n := clue_count()
	v.get_tree().create_timer(2.2).timeout.connect(func():
		v._pico(pico_line)
		if n == 6:
			v._pico("Six indices ! Toutes les pistes pointent vers l'horloge de la mairie. Et il nous manque encore des morceaux de roue.")
		elif n == 3:
			v._pico("Trois indices. Le mardi n'a pas été oublié : il a été RANGÉ. Par quelqu'un.")) 


func give(id: String, flag: String, text: String) -> void:
	Save.story[flag] = true
	Save.add_item(id)
	Save.save_game()
	Fx.text(v.world, _fwd_pos(1.4) + Vector3(0, 0.2, 0), "→ Sac : " + Inv.item_name(id), Color(1.0, 0.95, 0.7), 0.7, 2.2)
	v._pico(text)


func _shell(info: Dictionary, nm: String, wall: Color, roof: Color, floor_col: Color) -> Array:
	var s: Array = VB.shell(v, nm, info["pos"], info["yaw"], info["w"], info["d"], info["h"], wall, roof, floor_col, 1.5)
	return s


func _npc(parent: Node3D, id: String, data: Dictionary, pos: Vector3, yaw: float, dist := 3.2) -> Talker:
	var t := Talker.new()
	t.name = id.capitalize()
	parent.add_child(t)
	t.position = pos
	t.setup(v, v.player, data)
	t.rest_yaw = yaw
	v.speakers.append({"id": id, "node": t, "menu": null, "state": "closed", "idle": 0.0, "mode": "main", "dist": dist})
	return t


func _loaf(b: Builder, p: Vector3, a: float) -> void:
	b.sphere(0.13, p, Color(0.85, 0.6, 0.3).lerp(Color(0.7, 0.45, 0.22), fmod(a * 3.1, 1.0)), Vector3(1.5, 0.75, 0.85), Basis(Vector3.UP, a), 8)


# --- Boulangerie de Basile ------------------------------------------------------------------

func _bakery() -> void:
	var d: float = BAKERY["d"]
	var s: Array = _shell(BAKERY, "Boulangerie", Color(1.0, 0.82, 0.58), Color(0.78, 0.4, 0.25), Color(0.85, 0.75, 0.6))
	var n: Node3D = s[0]
	var b: Builder = s[1]
	v.nodes["boulangerie"] = n
	b.box(Vector3(3.2, 1.0, 0.6), Vector3(0, 0.5, 0.4), VB.WOOD.darkened(0.1), true)
	b.box(Vector3(3.4, 0.07, 0.8), Vector3(0, 1.03, 0.4), VB.WOOD.lightened(0.12), false)
	# Vingt-sept pains sur trois étagères
	var k := 0
	for sh in [0.8, 1.4, 2.0]:
		b.box(Vector3(4.6, 0.05, 0.5), Vector3(0, sh, -d * 0.5 + 0.45), VB.WOOD.darkened(0.2), false)
		for i in 9:
			_loaf(b, Vector3(-2.0 + i * 0.5, sh + 0.13, -d * 0.5 + 0.45), 0.3 * k)
			k += 1
	# Registre sur une petite table + four
	VB.table(b, Vector3(1.7, 0, -0.9), 0.4)
	b.box(Vector3(0.36, 0.05, 0.26), Vector3(1.7, 0.83, -0.9), Color(0.75, 0.2, 0.25), false, Basis(Vector3.UP, 0.4))
	b.box(Vector3(1.2, 1.3, 0.8), Vector3(-1.9, 0.65, -0.5), Color(0.5, 0.45, 0.45), true)
	b.box(Vector3(0.7, 0.45, 0.1), Vector3(-1.9, 0.7, -0.08), Color(0.2, 0.1, 0.1), false)
	b.build(n, Toon.vertex_color(0.01), "Mesh")
	VB.label(n, "BOULANGERIE", Vector3(0, 2.85, d * 0.5 + 0.12), 0.0045, Color(0.5, 0.25, 0.15), 56, 0.0, 6)
	VB.label(n, "Pain frais d'hier, de demain et d'aujourd'hui", Vector3(0, 2.55, d * 0.5 + 0.12), 0.0018, Color(0.5, 0.25, 0.15), 40, 0.0, 0)
	_npc(n, "basile", Characters.BASILE, Vector3(0, 0.03, -0.55), PI)
	hotspot(n, Vector3(1.7, 1.5, -0.6), "Lire le registre des fournées", func():
		clue("c_baker", "27 FOURNÉES", "LUNDI : 12 pains  ·  MARDI : 27 pains (jamais cuits)  ·  MERCREDI : 12",
			"Vingt-sept pains inscrits pour un jour que personne n'a vécu. Soit Basile est un génie, soit quelqu'un lui a dicté.")
		, func(): return tuesday() and not Save.story.get("c_baker", false))
	hotspot(n, Vector3(0, 2.55, -d * 0.5 + 1.1), "Fouiller les pains", func():
		give("roue_a", "got_a", "Un morceau de roue orange dans le pain ! C'est la première fois qu'un pain me regarde dans les yeux.")
		, func(): return tuesday() and not Save.story.get("got_a", false), 1.4)


# --- L'atelier du port ---------------------------------------------------------------------------

func _workshop() -> void:
	var d: float = WORKSHOP["d"]
	var s: Array = _shell(WORKSHOP, "Atelier", Color(0.78, 0.65, 0.48), Color(0.4, 0.5, 0.6), Color(0.6, 0.5, 0.4))
	var n: Node3D = s[0]
	var b: Builder = s[1]
	v.nodes["atelier"] = n
	b.box(Vector3(3.6, 0.9, 0.8), Vector3(0, 0.45, -d * 0.5 + 0.7), VB.WOOD.darkened(0.1), true)
	b.box(Vector3(3.8, 0.07, 1.0), Vector3(0, 0.92, -d * 0.5 + 0.7), VB.WOOD.lightened(0.1), false)
	for i in 5:
		b.cylinder(0.22 + 0.04 * (i % 3), 0.22 + 0.04 * (i % 3), 0.06, Vector3(-1.5 + i * 0.35, 1.0 + 0.03 * i, -d * 0.5 + 0.45), Color(0.6, 0.6, 0.68).darkened(0.08 * i), Basis(), 12)
	for i in 4:
		VB.crate(b, Vector3(1.8, 0.0, 0.2 + i * 0.1), Vector3(0.5, 0.4, 0.5), Color(0.72, 0.55, 0.36), 0.3 * i)
	b.build(n, Toon.vertex_color(0.01), "Mesh")
	VB.label(n, "ATELIER DU PORT", Vector3(0, 2.75, d * 0.5 + 0.12), 0.004, Color(0.2, 0.25, 0.3), 56, 0.0, 6)
	VB.label(n, "Fermé pour inventaire.\nL'inventaire est introuvable.", Vector3(0, 1.5, -d * 0.5 + 0.12), 0.002, Color(0.25, 0.2, 0.2), 40, 0.0, 0)
	piece_b_node = Node3D.new()
	n.add_child(piece_b_node)
	piece_b_node.position = Vector3(0.8, 1.0, -d * 0.5 + 0.55)
	var pb := Builder.new()
	Props.paint(pb, "roue_b", Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3.ZERO))
	pb.build(piece_b_node, Toon.vertex_color(0.006), "PieceB")
	piece_b_node.visible = not Save.story.get("got_b", false)
	hotspot(n, Vector3(0.8, 1.75, -d * 0.5 + 1.2), "Prendre la pièce bleue", func():
		piece_b_node.visible = false
		give("roue_b", "got_b", "Une pièce de roue bleue sur l'établi. Quelqu'un la réparait. Mardi. Évidemment.")
		, func(): return tuesday() and not Save.story.get("got_b", false), 1.5)


# --- Chez Pétronille -------------------------------------------------------------------------------

func _petronille() -> void:
	var d: float = PETRO["d"]
	var s: Array = _shell(PETRO, "ChezPetronille", Color(1.0, 0.72, 0.8), Color(0.4, 0.65, 0.45), Color(0.78, 0.55, 0.5))
	var n: Node3D = s[0]
	var b: Builder = s[1]
	v.nodes["petronille"] = n
	VB.table(b, Vector3(0.0, 0, -0.2), 0.6, Color(0.95, 0.85, 0.7))
	b.sphere(0.14, Vector3(0.0, 0.98, -0.2), Color(0.95, 0.9, 0.95), Vector3(1.0, 0.85, 1.0), Basis(), 8)
	b.box(Vector3(1.0, 0.9, 0.9), Vector3(-1.6, 0.45, -1.4), Color(0.7, 0.35, 0.5), true)
	b.box(Vector3(1.0, 0.9, 0.2), Vector3(-1.6, 1.1, -1.85), Color(0.62, 0.3, 0.45), false)
	VB.plant(b, Vector3(1.8, 0, -1.6))
	VB.plant(b, Vector3(-1.9, 0, 1.6))
	for i in 4:
		b.box(Vector3(0.7, 0.5, 0.05), Vector3(-1.2 + i * 0.8, 2.0, -d * 0.5 + 0.15), Color(0.95, 0.9, 0.8), false)
	b.build(n, Toon.vertex_color(0.01), "Mesh")
	VB.label(n, "CHEZ PÉTRONILLE", Vector3(0, 2.7, d * 0.5 + 0.12), 0.0038, Color(0.35, 0.2, 0.3), 56, 0.0, 6)
	VB.label(n, "« Hier »    « Demain »    « Plus tard »    « Peut-être »", Vector3(0, 1.55, -d * 0.5 + 0.12), 0.0014, Color(0.3, 0.2, 0.25), 40, 0.0, 0)
	_npc(n, "petronille", Characters.PETRONILLE, Vector3(0.9, 0.03, -0.9), PI)


# --- La maison abandonnée d'Éléonore -----------------------------------------------------------

func _ruin() -> void:
	var d: float = RUIN["d"]
	var s: Array = _shell(RUIN, "MaisonAbandonnee", Color(0.66, 0.63, 0.62), Color(0.3, 0.27, 0.3), Color(0.5, 0.43, 0.38))
	var n: Node3D = s[0]
	var b: Builder = s[1]
	v.nodes["abandonnee"] = n
	b.box(Vector3(2.2, 0.8, 1.0), Vector3(-1.0, 0.4, -1.6), VB.WOOD.darkened(0.2), true)
	for i in 6:
		b.cylinder(0.12 + 0.03 * (i % 3), 0.12 + 0.03 * (i % 3), 0.05, Vector3(-1.8 + i * 0.35, 0.85, -1.6), Color(0.85, 0.75, 0.35).darkened(0.05 * i), Basis(Vector3.RIGHT, PI * 0.5), 10)
	VB.crate(b, Vector3(1.8, 0, -1.8), Vector3(0.7, 0.6, 0.7), Color(0.55, 0.45, 0.35), 0.4)
	VB.crate(b, Vector3(1.9, 0.6, -1.7), Vector3(0.5, 0.4, 0.5), Color(0.5, 0.4, 0.3), 0.9)
	for i in 3:
		b.box(Vector3(0.9, 0.7, 0.03), Vector3(-1.4 + i * 1.3, 1.9, -d * 0.5 + 0.15), Color(0.9, 0.85, 0.7), false)
	b.build(n, Toon.vertex_color(0.01), "Mesh")
	var cards := ["CARTE DU CIEL\n(mardi, 21 h)", "PLAN DE L'HORLOGE", "CARTE DU PHARE"]
	for i in 3:
		VB.label(n, cards[i], Vector3(-1.4 + i * 1.3, 1.9, -d * 0.5 + 0.18), 0.0016, Color(0.3, 0.2, 0.2), 40, 0.0, 0)
	VB.label(n, "NE PAS ENTRER.\n(Sauf si vous avez une bonne raison.)", Vector3(0, 2.7, d * 0.5 + 0.12), 0.0026, Color(0.9, 0.85, 0.8), 44, 0.0, 6)
	_npc(n, "eleonore", Characters.ELEONORE, Vector3(1.0, 0.03, -0.5), PI)
	# Barricade devant la porte tant qu'Éléonore n'est pas « connue »
	if not Save.story.get("eleonore_known", false):
		barricade = StaticBody3D.new()
		barricade.name = "Barricade"
		n.add_child(barricade)
		barricade.position = Vector3(0, 1.2, d * 0.5 - 0.1)
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(1.8, 2.4, 0.5)
		cs.shape = sh
		barricade.add_child(cs)
		var bb := Builder.new()
		for k in 4:
			bb.box(Vector3(1.8, 0.2, 0.08), Vector3(0, -0.9 + k * 0.6, 0.12), Color(0.5, 0.36, 0.25), false, Basis(Vector3.FORWARD, 0.18 - k * 0.12))
		bb.build(barricade, Toon.vertex_color(0.008), "Boards")


func open_barricade() -> void:
	if barricade and is_instance_valid(barricade):
		Fx.puff(v.world, barricade.global_position, Color(0.8, 0.7, 0.6))
		barricade.queue_free()
		barricade = null


# --- Le ponton, Gérard, Marguerite et la peinture bleue ---------------------------------------------

func _pier_and_paint() -> void:
	var g := _npc(v, "gerard", Characters.GERARD, Vector3(-7.5, 0.58, -71.6), 0.0)
	var b := Builder.new()
	b.cylinder(0.14, 0.12, 0.28, Vector3(-6.6, 0.7, -71.3), Color(0.5, 0.6, 0.8), Basis(), 8)
	b.box(Vector3(1.1, 0.06, 0.34), Vector3(-6.6, 0.6, -68.6), Color(0.88, 0.8, 0.65), false)   # planche neuve
	b.build(v, Toon.vertex_color(0.008), "PierProps")
	hotspot(v, Vector3(-7.0, 1.4, -68.9), "Soulever la planche neuve", func():
		Save.add_item("papier_bleu")
		Save.save_game()
		Fx.text(v.world, Vector3(-6.6, 1.2, -68.6), "→ Sac : Morceau de papier bleu", Color(1.0, 0.95, 0.7), 0.7, 2.2)
		clue("c_fisher", "LA PLANCHE NEUVE", "Dessous : un papier bleu plié, tampon « MARDI ».", "Un papier bleu sous une planche trop propre. Il y a quelqu'un qui cache bien, mais mal.")
		, func(): return tuesday() and not Save.story.get("c_fisher", false), 1.7)
	# Marguerite et sa maison bleue
	var mh := Island.height(11.8, -41.0)
	_npc(v, "marguerite", Characters.MARGUERITE, Vector3(11.8, mh + 0.02, -41.0), PI)
	hotspot(v, Vector3(6.3, H + 1.0, -41.0), "Examiner le pinceau", func():
		clue("c_house", "LA TRAÎNÉE BLEUE", "Le pinceau est sec. Pourtant, une traînée bleue part vers le phare.", "Un pinceau sec, une peinture fraîche. Et un chemin bleu... qui va au phare.")
		refresh_trail()
		, func(): return tuesday() and not Save.story.get("c_house", false), 1.5)
	trail = Node3D.new()
	trail.name = "TraineeBleue"
	v.add_child(trail)
	var tb := Builder.new()
	var pts := [Vector2(9.0, -41.2), Vector2(12.5, -44.5), Vector2(15.5, -48.0), Vector2(18.5, -51.0), Vector2(21.0, -53.5), Vector2(23.0, -55.0)]
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var c: Vector2 = pts[i + 1]
		var steps := int(a.distance_to(c) / 0.6)
		for k in steps:
			var p: Vector2 = a.lerp(c, float(k) / float(steps))
			var y := Island.height(p.x, p.y) + 0.03
			tb.box(Vector3(0.5, 0.02, 0.3), Vector3(p.x + rng.randf_range(-0.2, 0.2), y, p.y + rng.randf_range(-0.2, 0.2)), Color(0.3, 0.55, 1.0), false, Basis(Vector3.UP, rng.randf() * PI))
	tb.build(trail, Toon.vertex_color(0.004), "Paint")


func refresh_trail() -> void:
	if trail:
		trail.visible = Save.story.get("c_house", false)


# --- Le livre de comptes de l'auberge -------------------------------------------------------------

func _inn_ledger() -> void:
	var inn: Node3D = v.nodes["auberge"]
	hotspot(inn, Vector3(-2.9, 1.85, 1.5), "Lire le livre de comptes", func():
		Save.story["ledger_seen"] = true
		Save.save_game()
		Fx.text(v.world, _fwd_pos(1.6) + Vector3(0, 0.3, 0), "Chambre 7 : E. CHARDON — mardi. Payée.", Color(1.0, 0.92, 0.5), 0.8, 4.0)
		v._pico("« E. Chardon ». Et la chambre 7 « n'existe pas ». Demande à Malo : il est temps qu'il parle.")
		, func(): return tuesday() and not Save.story.get("ledger_seen", false), 1.7)


# --- Le cadenas du phare ----------------------------------------------------------------------------

func _lighthouse() -> void:
	var lh: Node3D = v.nodes["phare"]
	var dir := Vector3(-0.6, 0, 0.8).normalized()
	var p := Vector3(0, 1.2, 0) + dir * 3.3
	hotspot(lh, p, "Glisser le papier bleu", func():
		Save.add_item("papier_bleu", -1)
		clue("c_light", "L'HEURE DU PHARE", "Le papier : un horaire. « 21 h — la lumière a changé de côté ». Tampon : MARDI.", "Un horaire de phare. Quelqu'un a regardé la lumière tourner dans le mauvais sens, un mardi.")
		, func(): return tuesday() and Save.count("papier_bleu") > 0 and not Save.story.get("c_light", false), 1.6)
	hotspot(lh, p + Vector3(0, -0.3, 0), "Examiner le cadenas", func():
		Fx.text(v.world, _fwd_pos(1.6), "Une fente. Pour un papier. Bleu, de préférence.", Color(1.0, 0.9, 0.7), 0.6, 3.0)
		, func(): return tuesday() and Save.count("papier_bleu") == 0 and not Save.story.get("c_light", false), 1.6)
