extends RefCounted
## Chapitre 2, première partie : VIREVOLTE, « la forêt qui mentait poliment ».
## Une zone à part, très haut dans le ciel (y = 500), où l'on se rend avec Éléonore.
## Deux familles se disputent le même pont, chacune avec un acte « authentique ».
## Dans cette forêt, un mensonge répété assez longtemps devient vrai.

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Fx := preload("res://scripts/fx.gd")
const Save := preload("res://scripts/save.gd")
const Characters := preload("res://scripts/characters.gd")
const VB := preload("res://scripts/village_build.gd")

const P := Vector3(0.0, 500.0, 0.0)
const GREFFE := Vector3(14.0, 0.0, -14.0)
const GREEN := Color(0.45, 0.85, 0.5)
const RED := Color(0.9, 0.4, 0.38)
const WOODC := Color(0.62, 0.42, 0.26)

var v
var root: Node3D
var bridge_mat: ShaderMaterial
var bridge_labels: Array = []
var lie_signs: Array = []      # [{label, texts, i, near}]
var _busy := false
var _ret := Vector3.ZERO


func build() -> void:
	Save.story["at_v"] = false
	root = Node3D.new()
	root.name = "Virevolte"
	v.add_child(root)
	root.position = P
	root.visible = false
	_ground()
	_forest()
	_bridge()
	_houses()
	_signs()
	_people()
	_hotspots()
	_travers()


func _s(k: String) -> bool:
	return Save.story.get(k, false)


func _later(t: float, c: Callable) -> void:
	v.get_tree().create_timer(t).timeout.connect(c)


func active() -> bool:
	return root != null and root.visible


# --- Décor -------------------------------------------------------------------------------------

func _ground() -> void:
	var b := Builder.new()
	b.cylinder(95.0, 95.0, 0.5, Vector3(0, -0.25, 0), Color(0.45, 0.78, 0.4), Basis(), 28)
	b.collider(Vector3(170.0, 1.0, 170.0), Vector3(0, -0.5, 0))
	# Le chemin
	b.box(Vector3(2.6, 0.03, 90.0), Vector3(0, 0.02, -5.0), Color(0.88, 0.78, 0.55), false)
	# Le ruisseau (impossible à traverser ailleurs que par le pont)
	b.box(Vector3(170.0, 0.05, 4.0), Vector3(0, 0.03, 0), Color(0.35, 0.65, 0.95), false)
	b.collider(Vector3(73.1, 3.0, 4.4), Vector3(-38.45, 1.5, 0))
	b.collider(Vector3(73.1, 3.0, 4.4), Vector3(38.45, 1.5, 0))
	# Fleurs de la place
	for k in 24:
		var a := float(k) * 2.4
		b.sphere(0.12, Vector3(sin(a) * (6.0 + k % 5) + (k % 3 - 1) * 6.0, 0.1, 18.0 + cos(a) * 6.0), [Color(1, 0.8, 0.9), Color(1, 0.95, 0.5), Color(0.8, 0.85, 1)][k % 3], Vector3.ONE, Basis(), 5)
	b.build(root, Toon.vertex_color(0.0), "Sol")


func _forest() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var b := Builder.new()
	var n := 0
	var tries := 0
	while n < 150 and tries < 900:
		tries += 1
		var x := rng.randf_range(-70.0, 70.0)
		var z := rng.randf_range(-70.0, 60.0)
		if absf(x) < 4.5 and z < 42.0 and z > -48.0:
			continue
		if absf(x) < 27.0 and z > 3.0 and z < 40.0:
			continue
		if absf(x) < 22.0 and z < -3.0 and z > -27.0:
			continue
		if absf(x) < 12.0 and z < -43.0 and z > -66.0:
			continue
		if absf(z) < 3.2:
			continue
		var s := rng.randf_range(0.8, 1.5)
		var h := 2.6 * s
		var col := Color(0.25, 0.6, 0.3).lerp(Color(0.4, 0.75, 0.35), rng.randf())
		b.cylinder(0.18 * s, 0.26 * s, h, Vector3(x, h * 0.5, z), Color(0.5, 0.34, 0.22), Basis(), 6)
		b.sphere(1.2 * s, Vector3(x, h + 0.5 * s, z), col, Vector3(1.0, 1.2, 1.0), Basis(), 7)
		b.sphere(0.9 * s, Vector3(x + 0.3 * s, h + 1.5 * s, z - 0.2 * s), col.lightened(0.1), Vector3.ONE, Basis(), 6)
		b.collider(Vector3(0.6, 3.0, 0.6), Vector3(x, 1.5, z))
		n += 1
	b.build(root, Toon.vertex_color(0.0), "Forêt")


func _bridge() -> void:
	bridge_mat = Toon.flat(WOODC).duplicate()
	var deck := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2.4, 0.16, 8.4)
	deck.mesh = bm
	deck.material_override = bridge_mat
	root.add_child(deck)
	deck.position = Vector3(0, 0.0, 0)
	for sx in [-1.25, 1.25]:
		var rail := MeshInstance3D.new()
		var rm := BoxMesh.new()
		rm.size = Vector3(0.12, 0.12, 8.4)
		rail.mesh = rm
		rail.material_override = bridge_mat
		root.add_child(rail)
		rail.position = Vector3(sx, 0.95, 0)
		for k in 5:
			var post := MeshInstance3D.new()
			var pm := BoxMesh.new()
			pm.size = Vector3(0.12, 0.95, 0.12)
			post.mesh = pm
			post.material_override = bridge_mat
			root.add_child(post)
			post.position = Vector3(sx, 0.48, -4.0 + k * 2.0)
	var cb := Builder.new()
	cb.collider(Vector3(2.4, 0.16, 8.4), Vector3(0, 0.0, 0))
	cb.collider(Vector3(0.12, 1.4, 8.4), Vector3(-1.25, 0.7, 0))
	cb.collider(Vector3(0.12, 1.4, 8.4), Vector3(1.25, 0.7, 0))
	cb.build(root, Toon.flat(WOODC), "PontCollision")
	# Les panneaux du pont : ils changent selon celui qui les lit
	bridge_labels.append(VB.label(root, "PONT", Vector3(2.2, 1.7, 5.2), 0.006, Color(1, 0.95, 0.8), 56, 0.0, 10))
	bridge_labels.append(VB.label(root, "PONT", Vector3(-2.2, 1.7, -5.2), 0.006, Color(1, 0.95, 0.8), 56, PI, 10))
	_refresh_bridge(0.0)


func _refresh_bridge(side: float) -> void:
	var col := WOODC
	var txt := "PONT DE VIREVOLTE\n(à tous)"
	if not _s("pont_ok"):
		var t := clampf(side / 4.0, -1.0, 1.0)
		var claim := 0.0
		if _s("doc_a") or _s("odile_met"):
			claim = -1.0
		if _s("doc_b") or _s("gaspard_met"):
			claim = 1.0 if claim == 0.0 else claim
		if t < -0.2:
			col = WOODC.lerp(GREEN, 0.7)
			txt = "PONT AUBÉPINE\n(depuis 1203)"
		elif t > 0.2:
			col = WOODC.lerp(RED, 0.7)
			txt = "PONT RONCEVAL\n(depuis 1204)"
		else:
			col = WOODC
			txt = "PONT\n(de qui, déjà ?)"
	bridge_mat.set_shader_parameter("albedo", col)
	for l in bridge_labels:
		l.text = txt


func _house(pos: Vector3, yaw: float, w: float, d: float, h: float, wall: Color, roof: Color, title: String, sub: String) -> Node3D:
	var n := Node3D.new()
	n.name = title.replace(" ", "")
	root.add_child(n)
	n.position = pos
	n.rotation.y = yaw
	var b := Builder.new()
	b.box(Vector3(w, h, d), Vector3(0, h * 0.5, 0), wall, true)
	b.prism(Vector3(w + 0.7, 1.3, d + 0.7), Vector3(0, h + 0.65, 0), roof, Basis())
	b.box(Vector3(1.0, 1.9, 0.12), Vector3(0, 0.95, d * 0.5 + 0.02), Color(0.45, 0.3, 0.2), false)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(0.8, 0.8, 0.1), Vector3(sx * w * 0.32, h * 0.6, d * 0.5 + 0.02), Color(0.7, 0.9, 1.0), false)
	b.build(n, Toon.vertex_color(0.008), "Mesh")
	VB.label(n, title, Vector3(0, h + 0.2, d * 0.5 + 0.12), 0.0042, Color(1, 0.97, 0.85), 52, 0.0, 10)
	VB.label(n, sub, Vector3(0, h - 0.35, d * 0.5 + 0.12), 0.002, Color(1, 0.97, 0.85), 44, 0.0, 6)
	return n


func _houses() -> void:
	# Maison Aubépine à l'ouest, maison Ronceval à l'est, face à face
	_house(Vector3(-17.0, 0, 15.0), -PI * 0.5, 6.0, 5.0, 3.2, Color(0.75, 0.92, 0.75), Color(0.3, 0.6, 0.4), "AUBÉPINE", "Propriétaires du pont (acte à l'appui)")
	_house(Vector3(17.0, 0, 15.0), PI * 0.5, 6.0, 5.0, 3.2, Color(0.95, 0.75, 0.72), Color(0.7, 0.3, 0.3), "RONCEVAL", "Propriétaires du pont (acte aussi)")
	# Greffe de Maître Anselme, côté nord
	var g := _house(GREFFE, -PI * 0.5 + 0.3, 5.0, 4.4, 3.0, Color(0.82, 0.74, 0.92), Color(0.4, 0.3, 0.55), "GREFFE", "Actes en tout genre (et en tout sens)")
	var ib := Builder.new()
	ib.sphere(0.5, Vector3(0, 4.7, 0), Color(0.3, 0.15, 0.5), Vector3(1.0, 1.1, 1.0), Basis(), 10)
	ib.cylinder(0.18, 0.18, 0.4, Vector3(0, 5.3, 0), Color(0.3, 0.15, 0.5), Basis(), 8)
	ib.build(g, Toon.vertex_color(0.01), "Encrier")


func _signs() -> void:
	# Les panneaux « polis » de la forêt : chacun change d'avis quand on s'approche
	var defs := [
		[Vector3(1.9, 0, 30.0), ["VIREVOLTE\n2 km", "VIREVOLTE\n200 m", "VIREVOLTE\n(vous y êtes)"]],
		[Vector3(-2.0, 0, 38.0), ["FORÊT TRÈS CALME\n(rien n'a menti ici)", "FORÊT TRÈS CALME\n(presque rien)", "FORÊT TRÈS CALME\n(chut)"]],
		[Vector3(2.0, 0, -22.0), ["PONT SOLIDE\n(promis)", "PONT SOLIDE\n(juré)", "PONT SOLIDE\n(trois fois, c'est vrai)"]],
	]
	for d in defs:
		var n := Node3D.new()
		root.add_child(n)
		n.position = d[0]
		var b := Builder.new()
		b.box(Vector3(0.12, 1.7, 0.12), Vector3(0, 0.85, 0), WOODC.darkened(0.2), true)
		b.box(Vector3(1.7, 0.9, 0.1), Vector3(0, 1.7, 0), Color(0.88, 0.8, 0.6), false)
		b.build(n, Toon.vertex_color(0.008), "Panneau")
		var l := VB.label(n, d[1][0], Vector3(0, 1.7, 0.07), 0.0034, Color(0.3, 0.2, 0.15), 40, 0.0, 0)
		l.double_sided = true
		lie_signs.append({"label": l, "texts": d[1], "i": 0, "near": false, "node": n})


func _travers() -> void:
	# La Maison de Travers, au fond de la forêt (le donjon du chapitre, à suivre)
	var n := Node3D.new()
	n.name = "MaisonDeTravers"
	root.add_child(n)
	n.position = Vector3(0, 0, -56)
	var b := Builder.new()
	var cols := [Color(0.9, 0.7, 0.6), Color(0.7, 0.8, 0.95), Color(0.95, 0.9, 0.6)]
	for k in 3:
		var s := Basis(Vector3.UP, 0.25 * (k - 1)) * Basis(Vector3.BACK, 0.12 * (1 - k))
		b.box(Vector3(7.0 - k, 3.4, 6.0 - k), Vector3(0.5 * (k - 1), 1.7 + k * 3.2, 0), cols[k], true, s)
	b.prism(Vector3(7.0, 2.4, 6.0), Vector3(-0.8, 10.8, 0), Color(0.55, 0.3, 0.35), Basis(Vector3.BACK, -0.22))
	b.box(Vector3(1.2, 2.2, 0.15), Vector3(0, 1.1, 3.1), Color(0.4, 0.25, 0.2), false)
	b.build(n, Toon.vertex_color(0.01), "Maison")
	VB.label(n, "MAISON DE TRAVERS", Vector3(0, 4.2, 3.4), 0.006, Color(1, 0.95, 0.8), 56, 0.0, 10)
	VB.label(n, "(entrée : de travers)", Vector3(0, 3.6, 3.4), 0.003, Color(1, 0.95, 0.8), 44, 0.0, 6)
	v.x.hotspot(n, Vector3(0, 1.3, 4.2), "Frapper à la porte", _knock, func(): return _s("pont_ok"), 1.6, 5.0)


# --- Les gens -------------------------------------------------------------------------------------

func _people() -> void:
	v.x._npc(root, "odile", Characters.ODILE, Vector3(-3.4, 0.03, 8.0), -PI * 0.5)
	v.x._npc(root, "gaspard", Characters.GASPARD, Vector3(3.4, 0.03, 8.0), PI * 0.5)
	v.x._npc(root, "mirette", Characters.MIRETTE, Vector3(4.0, 0.03, -9.0), PI)
	v.x._npc(root, "anselme", Characters.ANSELME, GREFFE + Vector3(-2.2, 0.03, 4.6), 0.0)


func _hotspots() -> void:
	v.x.hotspot(root, Vector3(1.3, 1.3, 5.2), "Regarder sous le pont", _under_bridge, func(): return not _s("plaque"), 1.8, 4.5)
	v.x.hotspot(root, Vector3(0, 1.3, 6.0), "Réunir les deux familles", _reunite, func(): return _s("plaque") and _s("same_hand") and not _s("pont_ok"), 1.9, 5.5)
	v.x.hotspot(root, GREFFE + Vector3(0.3, 1.5, 4.6), "Fouiller le greffe", _greffe, func(): return _s("doc_a") and _s("doc_b") and not _s("greffe_blank"), 1.6, 3.5)
	v.x.hotspot(root, Vector3(0, 1.3, 36.0), "Retourner à Port-Biscornu", func(): _leave(), func(): return active() and not _busy, 2.0, 4.0)


# --- Voyage ---------------------------------------------------------------------------------------

func travel() -> void:
	if _busy:
		return
	_busy = true
	_ret = v.player.global_position
	var tw: Tween = v.maquette._fade_to(0.0, 1.0, 0.9)
	tw.tween_callback(func():
		root.visible = true
		Save.story["at_v"] = true
		Save.story["v2_started"] = true
		Save.save_game()
		var ele: Dictionary = v._speaker("eleonore")
		if not ele.is_empty():
			var node = ele["node"]
			if node.get_parent() != root:
				node.get_parent().remove_child(node)
				root.add_child(node)
			node.position = Vector3(1.8, 0.03, 29.0)
			node.rest_yaw = 0.0
		v.player.global_position = P + Vector3(0, 0.1, 31.0)
		v.player._vy = 0.0
		v.player._face_yaw(0.0)
		v.player._place_origin(true, 0.0)
		var tw2: Tween = v.maquette._fade_to(1.0, 0.0, 1.0)
		tw2.tween_callback(func():
			_busy = false
			Fx.text(v.world, P + Vector3(0, 2.8, 27.0), "CHAPITRE 2", Color(1.0, 0.95, 0.5), 1.5, 5.0)
			_later(1.2, func(): Fx.text(v.world, P + Vector3(0, 2.0, 27.0), "LA FORÊT QUI MENTAIT POLIMENT", Color(0.8, 1.0, 0.8), 0.9, 5.0))
			_later(3.0, func(): v._pico("Virevolte. Les arbres ont l'air sincères. C'est ce qui m'inquiète. Va voir les deux familles, près du pont."))))


func _leave() -> void:
	if _busy:
		return
	_busy = true
	var tw: Tween = v.maquette._fade_to(0.0, 1.0, 0.9)
	tw.tween_callback(func():
		root.visible = false
		Save.story["at_v"] = false
		Save.save_game()
		v.y.place_eleonore()
		v.player.global_position = _ret
		v.player._vy = 0.0
		v.player._place_origin(true, 0.0)
		var tw2: Tween = v.maquette._fade_to(1.0, 0.0, 0.9)
		tw2.tween_callback(func(): _busy = false))


# --- Événements des dialogues et indices --------------------------------------------------------------------

func event(ev: String, node) -> void:
	match ev:
		"z_go":
			travel()
		"z_doc_a":
			_clue_fx(node, "L'ACTE AUBÉPINE", "1203 · écriture penchée · encre violette")
			v._pico("Un acte de 1203, signé « Les Aubépine ». L'encre est encore humide. Après huit cents ans, c'est soit un exploit, soit un mensonge.")
		"z_doc_b":
			_clue_fx(node, "L'ACTE RONCEVAL", "1204 · écriture penchée · encre violette")
			v._pico("1204. Un an après, mais avec la même belle écriture penchée. Je ne dis rien. Je regarde juste très fort.")
		"z_same_hand":
			_clue_fx(node, "MÊME MAIN, MÊME ENCRE", "Les deux actes ont été écrits par la même personne")
			v._pico("Deux familles qui se détestent, et un seul scribe. Je commence à aimer ce village.")
		"z_mirette":
			v._pico("Une plaque sous le pont. Les enfants regardent toujours là où les adultes ne regardent pas.")
		"z_anselme":
			v._pico("« L'encre n'est pas de moi. » C'est exactement ce que dirait quelqu'un dont l'encre est violette.")


func _clue_fx(node, title: String, detail: String) -> void:
	var p: Vector3 = node.global_position + Vector3(0, 2.3, 0)
	Fx.text(v.world, p + Vector3(0, 0.3, 0), "INDICE : " + title, Color(1.0, 0.92, 0.4), 0.7, 4.0)
	_later(0.9, func(): Fx.text(v.world, p - Vector3(0, 0.1, 0), detail, Color(0.9, 0.95, 1.0), 0.5, 4.5))


func _under_bridge() -> void:
	Save.story["plaque"] = true
	Save.save_game()
	var p: Vector3 = P + Vector3(1.3, 1.0, 5.2)
	Fx.text(v.world, p + Vector3(0, 0.8, 0), "INDICE : LA PLAQUE", Color(1.0, 0.92, 0.4), 0.7, 4.0)
	_later(1.0, func(): Fx.text(v.world, p + Vector3(0, 0.0, 0), "« Bâti par tous, pour tous. Merci de ne pas en faire un procès. »", Color(0.9, 0.95, 1.0), 0.5, 5.5))
	v._pico("Une plaque, sous le pont, couverte de mousse polie. « Bâti par tous, pour tous. » Aucun des deux actes ne parle de ça.")


func _greffe() -> void:
	Save.story["greffe_blank"] = true
	Save.save_game()
	var p: Vector3 = P + GREFFE + Vector3(0.3, 1.8, 4.6)
	Fx.text(v.world, p + Vector3(0, 0.8, 0), "INDICE : LE TIROIR", Color(1.0, 0.92, 0.4), 0.7, 4.0)
	_later(1.0, func(): Fx.text(v.world, p, "Des actes du pont déjà tamponnés, nom laissé en blanc. Un encrier violet.", Color(0.9, 0.95, 1.0), 0.5, 5.5))
	v._pico("Des actes de propriété vierges, avec le tampon déjà posé. Il suffit d'écrire le nom du client. Ou de l'adversaire du client.")


func _say_at(id: String, text: String) -> void:
	var sp: Dictionary = v._speaker(id)
	if not sp.is_empty():
		sp["node"].chibi.say(text, 2.5 + text.length() * 0.055)


func _reunite() -> void:
	if _s("pont_ok") or _busy:
		return
	_busy = true
	_say_at("odile", "Tout le monde ?! Mais alors... l'acte de 1203...")
	_later(3.2, func(): _say_at("gaspard", "Et le mien, de 1204... avec la même belle écriture penchée ?"))
	_later(6.5, func(): _say_at("odile", "Gaspard... on s'est disputés huit cents ans pour rien."))
	_later(9.5, func(): _say_at("gaspard", "Seulement quarante-trois ans, Odile. Mais c'était intense."))
	_later(12.0, func():
		Save.story["pont_ok"] = true
		Save.shells += 20 + (10 if _s("greffe_blank") else 0)
		Save.save_game()
		_refresh_bridge(0.0)
		Fx.text(v.world, P + Vector3(0, 2.4, 3.0), "LE PONT EST À TOUT LE MONDE", Color(0.7, 1.0, 0.7), 1.2, 5.0)
		Fx.text(v.world, P + Vector3(0, 1.4, 3.0), "+20 coquillages", Color(1.0, 0.9, 0.5), 0.8, 3.0)
		Fx.puff(v.world, P + Vector3(0, 0.8, 0), Color(1.0, 0.95, 0.8))
		_busy = false)
	_later(15.0, func(): v._pico("Un pont réparé uniquement par la politesse. C'est la forêt qui doit être furieuse."))
	_later(19.0, func(): _say_at("anselme", "Un pont à tout le monde ?... Quelle tristesse. Il me reste le puits."))
	_later(23.0, func():
		Fx.text(v.world, P + Vector3(0, 3.0, -30.0), "Au fond de la forêt, une maison penche... de travers.", Color(1.0, 0.95, 0.7), 0.8, 6.0)
		v._pico("La Maison de Travers, tout au nord. Éléonore dit qu'il y a un morceau du Registre à l'intérieur. Et que la maison a un caractère."))


func _knock() -> void:
	Fx.text(v.world, P + Vector3(0, 3.0, -52.0), "TOC TOC (la porte répond : « Entrez... ou sortez. »)", Color(1.0, 0.95, 0.7), 0.7, 5.0)
	_later(1.5, func(): v._pico("La maison est fermée aujourd'hui. Elle rouvrira au prochain chapitre. Elle a dit « bientôt », mais de travers."))


# --- Boucle -----------------------------------------------------------------------------------------

func update() -> void:
	if not active() or v.player == null:
		return
	var pp: Vector3 = v.player.global_position - P
	_refresh_bridge(pp.x if absf(pp.z) < 14.0 and absf(pp.x) < 14.0 else 0.0)
	for s in lie_signs:
		var d := Vector2(pp.x, pp.z).distance_to(Vector2(s["node"].position.x, s["node"].position.z))
		var near: bool = d < 6.0
		if near and not s["near"]:
			s["i"] = (int(s["i"]) + 1) % s["texts"].size()
			s["label"].text = s["texts"][s["i"]]
		s["near"] = near
