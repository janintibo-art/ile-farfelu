extends RefCounted
## Chapitre 5, première partie : LES HAUTES-MIETTES, « l'homme qui volait du temps ».
## Village de montagne (zone y = 1100) construit autour d'une horloge astronomique géante.
## Toutes les 36 secondes, la place rejoue la même scène de cinq minutes (boucle locale) :
## chaque répétition laisse voir un détail différent. Le joueur note les trois détails,
## accorde les quatre cadrans sur l'heure du conseil, puis le temps s'arrête une seconde
## devant le voleur de minutes (le Receveur du Château). Au sommet : l'Observatoire Brisé.

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Fx := preload("res://scripts/fx.gd")
const Save := preload("res://scripts/save.gd")
const Characters := preload("res://scripts/characters.gd")
const VB := preload("res://scripts/village_build.gd")
const Island := preload("res://scripts/island.gd")
const Bells := preload("res://scripts/bells.gd")
const Talker := preload("res://scripts/talker.gd")

const P := Vector3(0.0, 1100.0, 0.0)
const STONE := Color(0.7, 0.68, 0.7)
const WOODC := Color(0.55, 0.38, 0.28)
const SNOW := Color(0.93, 0.96, 1.0)

const LOOP := 36.0
const CL_POS := [Vector3(-17.0, 0.0, 2.0), Vector3(17.0, 0.0, 4.0), Vector3(-17.0, 0.0, 26.0), Vector3(17.0, 0.0, 28.0)]
const CL_START := [7, 11, 1, 6]
const CL_GOAL := 3
const FACE := Vector3(0.0, 9.0, -10.3)

const DETAILS := [
	["« À Mlle L. Plume, poste restante, Hautes-Miettes. Ne pas la faire attendre. »", "la lettre"],
	["Étiquette du pot : « CONSERVÉ — 14h02 à 14h07 — destination : Château »", "le pot"],
	["Badge : « H. SABLIER, Receveur des Minutes — Château des Versions Officielles »", "le badge"],
]

var v
var root: Node3D
var hands_h: Node3D
var hands_m: Node3D
var facteur: Talker
var receveur: Talker
var jar: MeshInstance3D
var orb: MeshInstance3D
var letter: MeshInstance3D
var clocks: Array = []
var _busy := false
var _ret := Vector3.ZERO
var _t0 := 0.0
var _last_lt := 0.0
var _loop_n := 0
var _last_min := -1
var _detail_on := false
var _detail_shown := false
var _frozen := false
var _talking := false


func build() -> void:
	Save.story["at_h"] = false
	root = Node3D.new()
	root.name = "HautesMiettes"
	v.add_child(root)
	root.position = P
	root.visible = false
	_ground()
	_tower()
	_chalets()
	_trees()
	_clocks()
	_actors()
	_people()
	_hotspots()


func _s(k: String) -> bool:
	return Save.story.get(k, false)


func _later(t: float, c: Callable) -> void:
	v.get_tree().create_timer(t).timeout.connect(c)


func active() -> bool:
	return root != null and root.visible


func _now() -> float:
	return float(Time.get_ticks_msec()) / 1000.0


func _clues() -> int:
	var n := 0
	for k in 3:
		if _s("h_d%d" % k):
			n += 1
	return n


func _synced() -> bool:
	for i in 4:
		if _hour(i) != CL_GOAL:
			return false
	return true


func _hour(i: int) -> int:
	return int(Save.story.get("h_cl%d" % i, CL_START[i]))


# --- Décor -------------------------------------------------------------------------------------

func _ground() -> void:
	var sea := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(600.0, 600.0)
	sea.mesh = pm
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.85, 0.92, 1.0)
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sea.material_override = sm
	root.add_child(sea)
	sea.position = Vector3(0, -40.0, 0)
	var b := Builder.new()
	b.box(Vector3(64.0, 1.0, 88.0), Vector3(0, -0.5, -2.0), SNOW, true)
	b.cylinder(32.0, 20.0, 38.0, Vector3(0, -20.0, -2.0), Color(0.55, 0.55, 0.6), Basis(), 12)
	b.box(Vector3(3.0, 0.04, 78.0), Vector3(0, 0.02, 0.0), Color(0.75, 0.7, 0.65), false)
	b.box(Vector3(18.0, 0.04, 14.0), Vector3(0, 0.02, 11.0), Color(0.8, 0.76, 0.7), false)
	for sx in [-1, 1]:
		b.collider(Vector3(2.0, 10.0, 92.0), Vector3(sx * 33.0, 4.0, -2.0))
	b.collider(Vector3(66.0, 10.0, 2.0), Vector3(0, 4.0, -46.0))
	b.collider(Vector3(66.0, 10.0, 2.0), Vector3(0, 4.0, 42.0))
	b.build(root, Toon.vertex_color(0.006), "Plateau")
	for pz in [38.0]:
		VB.label(root, "HAUTES-MIETTES", Vector3(0, 3.4, pz), 0.0085, Color(0.2, 0.2, 0.35), 56, 0.0, 10)
		VB.label(root, "altitude : 1 412 m — heure : à peu près", Vector3(0, 2.7, pz), 0.0032, Color(0.2, 0.2, 0.35), 44, 0.0, 6)
		VB.label(root, "(pas de retard toléré ; pas d'avance non plus)", Vector3(0, 2.2, pz), 0.0022, Color(0.2, 0.2, 0.35), 40, 0.0, 6)
	var pb := Builder.new()
	for sx in [-1.6, 1.6]:
		pb.cylinder(0.1, 0.12, 3.6, Vector3(sx, 1.8, 38.0), WOODC.darkened(0.2), Basis(), 6)
	pb.box(Vector3(3.6, 0.2, 0.2), Vector3(0, 3.7, 38.0), WOODC, false)
	pb.build(root, Toon.vertex_color(0.006), "Portique")


func _tower() -> void:
	var b := Builder.new()
	b.box(Vector3(8.0, 14.0, 7.0), Vector3(0, 7.0, -14.0), STONE, true)
	b.box(Vector3(8.6, 0.6, 7.6), Vector3(0, 14.2, -14.0), STONE.darkened(0.12), false)
	b.prism(Vector3(9.0, 3.5, 8.0), Vector3(0, 16.2, -14.0), Color(0.3, 0.4, 0.6), Basis())
	b.cylinder(2.9, 2.9, 0.25, Vector3(0, 9.0, -10.4), Color(0.97, 0.95, 0.88), Basis(Vector3.RIGHT, PI * 0.5), 24)
	b.torus(2.85, 3.15, Vector3(0, 9.0, -10.3), Color(0.8, 0.65, 0.25), Basis(Vector3.RIGHT, PI * 0.5))
	for k in 12:
		var a := float(k) * TAU / 12.0
		b.box(Vector3(0.14, 0.4, 0.1), Vector3(sin(a) * 2.5, 9.0 + cos(a) * 2.5, -10.22), Color(0.2, 0.2, 0.3), false, Basis(Vector3.BACK, -a))
	# Anneaux d'astrolabe au sommet
	b.torus(1.6, 1.75, Vector3(0, 19.4, -14.0), Color(0.85, 0.7, 0.3), Basis(Vector3.RIGHT, 0.5))
	b.torus(1.0, 1.12, Vector3(0, 19.4, -14.0), Color(0.85, 0.7, 0.3), Basis(Vector3.BACK, 0.6))
	b.sphere(0.45, Vector3(0, 19.4, -14.0), Color(1.0, 0.85, 0.3), Vector3.ONE, Basis(), 10)
	b.box(Vector3(1.4, 2.4, 0.15), Vector3(0, 1.2, -10.45), Color(0.35, 0.25, 0.25), false)
	b.build(root, Toon.vertex_color(0.008), "Tour")
	VB.label(root, "CONSEIL MUNICIPAL : 3 HEURES PILE", Vector3(0, 5.4, -10.4), 0.0055, Color(1, 0.97, 0.85), 52, 0.0, 10)
	VB.label(root, "(ou jamais, selon l'humeur de l'horloge)", Vector3(0, 4.7, -10.4), 0.0028, Color(1, 0.97, 0.85), 44, 0.0, 6)
	hands_h = Node3D.new()
	hands_m = Node3D.new()
	root.add_child(hands_h)
	root.add_child(hands_m)
	hands_h.position = FACE + Vector3(0, 0, 0.0)
	hands_m.position = FACE + Vector3(0, 0, 0.1)
	var hb := Builder.new()
	hb.box(Vector3(0.22, 1.7, 0.08), Vector3(0, 0.85, 0), Color(0.15, 0.15, 0.25), false)
	hb.build(hands_h, Toon.vertex_color(0.0), "Heure")
	var mb := Builder.new()
	mb.box(Vector3(0.14, 2.5, 0.08), Vector3(0, 1.25, 0), Color(0.15, 0.15, 0.25), false)
	mb.build(hands_m, Toon.vertex_color(0.0), "Minute")


func _hut(pos: Vector3, yaw: float, w: float, d: float, h: float, wall: Color, roof: Color, title: String, sub: String) -> void:
	var n := Node3D.new()
	n.name = title.substr(0, 8).replace(" ", "")
	root.add_child(n)
	n.position = pos
	n.rotation.y = yaw
	var b := Builder.new()
	b.box(Vector3(w, h, d), Vector3(0, h * 0.5, 0), wall, true)
	b.prism(Vector3(w + 0.8, 1.6, d + 0.8), Vector3(0, h + 0.8, 0), roof, Basis())
	b.box(Vector3(1.0, 1.9, 0.12), Vector3(0, 0.95, d * 0.5 + 0.02), Color(0.4, 0.3, 0.3), false)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(0.7, 0.7, 0.1), Vector3(sx * w * 0.32, h * 0.6, d * 0.5 + 0.02), Color(1.0, 0.95, 0.7), false)
	b.build(n, Toon.vertex_color(0.008), "Mesh")
	VB.label(n, title, Vector3(0, h + 0.2, d * 0.5 + 0.12), 0.0036, Color(1, 0.97, 0.85), 52, 0.0, 10)
	VB.label(n, sub, Vector3(0, h - 0.4, d * 0.5 + 0.12), 0.0019, Color(1, 0.97, 0.85), 44, 0.0, 6)


func _chalets() -> void:
	_hut(Vector3(-13.0, 0, 14.0), PI * 0.5, 5.0, 4.6, 3.0, Color(0.95, 0.85, 0.65), Color(0.6, 0.35, 0.3), "MAIRIE", "Ouverte de 9h00 à 9h00 et une seconde")
	_hut(Vector3(13.0, 0, 14.0), -PI * 0.5, 5.0, 4.6, 3.0, Color(0.85, 0.9, 0.95), Color(0.35, 0.45, 0.6), "HORLOGERIE DU QUART", "On répare tout, sauf les retards")
	_hut(Vector3(-13.0, 0, -2.0), PI * 0.5, 5.0, 4.6, 2.8, Color(0.9, 0.8, 0.9), Color(0.5, 0.35, 0.55), "PÂTISSERIE DE 16H", "Fermée à 16h01 pour cause de goûter")
	_hut(Vector3(13.0, 0, -2.0), -PI * 0.5, 5.0, 4.6, 2.8, Color(0.85, 0.92, 0.8), Color(0.4, 0.55, 0.4), "SALLE DES RÉUNIONS", "Interminables, mais à l'heure")


func _trees() -> void:
	var b := Builder.new()
	for p in [Vector3(-26.0, 0.0, 10.0), Vector3(26.0, 0.0, 12.0), Vector3(-27.0, 0.0, -14.0), Vector3(27.0, 0.0, -16.0), Vector3(-24.0, 0.0, 34.0), Vector3(25.0, 0.0, 34.0), Vector3(-9.0, 0.0, 34.0), Vector3(10.0, 0.0, 33.0), Vector3(-22.0, 0.0, -30.0), Vector3(22.0, 0.0, -32.0)]:
		b.cylinder(0.25, 0.3, 1.2, p + Vector3(0, 0.6, 0), WOODC.darkened(0.2), Basis(), 6)
		b.cylinder(0.02, 1.8, 3.4, p + Vector3(0, 2.9, 0), Color(0.25, 0.5, 0.4), Basis(), 8)
		b.cylinder(0.02, 1.3, 2.4, p + Vector3(0, 4.6, 0), Color(0.3, 0.55, 0.45), Basis(), 8)
		b.cylinder(0.02, 1.2, 0.7, p + Vector3(0, 5.1, 0), Color(0.95, 0.97, 1.0), Basis(), 8)
	b.build(root, Toon.vertex_color(0.006), "Pins")


func _clocks() -> void:
	for i in 4:
		var p: Vector3 = CL_POS[i]
		var b := Builder.new()
		b.cylinder(0.1, 0.12, 2.8, p + Vector3(0, 1.4, 0), WOODC.darkened(0.2), Basis(), 6)
		b.cylinder(0.7, 0.7, 0.14, p + Vector3(0, 3.1, 0), Color(0.97, 0.95, 0.88), Basis(Vector3.RIGHT, PI * 0.5), 18)
		b.torus(0.66, 0.78, p + Vector3(0, 3.1, 0.02), Color(0.8, 0.65, 0.25), Basis(Vector3.RIGHT, PI * 0.5))
		b.box(Vector3(0.06, 0.56, 0.04), p + Vector3(0, 3.1 + 0.28, 0.13), Color(0.25, 0.25, 0.35), false)
		b.build(root, Toon.vertex_color(0.0), "Cadran%d" % i)
		var hh := Node3D.new()
		root.add_child(hh)
		hh.position = p + Vector3(0, 3.1, 0.1)
		var hb := Builder.new()
		hb.box(Vector3(0.09, 0.42, 0.04), Vector3(0, 0.21, 0), Color(0.15, 0.15, 0.25), false)
		hb.build(hh, Toon.vertex_color(0.0), "H")
		var lb: Label3D = VB.label(root, "", p + Vector3(0, 2.2, 0.15), 0.006, Color(1, 0.95, 0.7), 52, 0.0, 10)
		clocks.append({"hour": hh, "lbl": lb})
		_refresh_clock(i)


func _refresh_clock(i: int) -> void:
	var h := _hour(i)
	clocks[i]["hour"].rotation.z = -float(h) * TAU / 12.0
	clocks[i]["lbl"].text = "%02d:00" % h


func _actors() -> void:
	facteur = Talker.new()
	facteur.name = "Facteur"
	root.add_child(facteur)
	facteur.setup(v, v.player, Characters.FACTEUR)
	facteur.moving = true
	facteur.visible = false
	receveur = Talker.new()
	receveur.name = "Receveur"
	root.add_child(receveur)
	receveur.setup(v, v.player, Characters.RECEVEUR)
	receveur.moving = true
	receveur.visible = false
	jar = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.1
	cm.bottom_radius = 0.1
	cm.height = 0.24
	jar.mesh = cm
	var jm := StandardMaterial3D.new()
	jm.albedo_color = Color(0.7, 0.9, 1.0, 0.6)
	jm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	jm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	jar.material_override = jm
	receveur.add_child(jar)
	jar.position = Vector3(0.3, 0.75, -0.18)
	jar.visible = false
	orb = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.22
	sm.height = 0.44
	orb.mesh = sm
	orb.material_override = Toon.unlit(Color(1.0, 0.9, 0.4))
	root.add_child(orb)
	orb.visible = false
	letter = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.4, 0.04, 0.28)
	letter.mesh = bm
	letter.material_override = Toon.unlit(Color(0.98, 0.95, 0.85))
	root.add_child(letter)
	letter.position = Vector3(-3.6, 0.06, 11.4)
	letter.visible = false


func _people() -> void:
	v.x._npc(root, "minuit", Characters.MINUIT, Vector3(-8.5, 0.03, 17.0), 0.0)
	v.x._npc(root, "quart", Characters.QUART, Vector3(8.5, 0.03, 17.5), 0.0)
	v.x._npc(root, "zephyr", Characters.ZEPHYR, Vector3(14.5, 0.03, 22.0), PI * 0.5)


func _hotspots() -> void:
	v.x.hotspot(root, Vector3(0, 1.3, 37.0), "Retourner à Port-Biscornu", func(): leave(), func(): return active() and not _busy, 2.0, 4.0)
	for i in 4:
		var p: Vector3 = CL_POS[i]
		v.x.hotspot(root, p + Vector3(0, 1.3, 0.9), "Avancer l'heure d'un cran", _bump.bind(i), func(): return active(), 2.0, 3.0)
	v.x.hotspot(root, Vector3(0, 1.8, 9.0), "Noter ce détail", _note, func(): return active() and _detail_on and not _s("h_d%d" % (_loop_n % 3)), 1.7, 10.0)
	v.x.hotspot(root, Vector3(4.0, 2.3, 11.5), "Parler au Receveur", _confront, func(): return active() and _frozen and not _s("h_done") and not _talking, 2.0, 5.0)
	v.x.hotspot(root, Vector3(0, 2.4, -9.8), "Monter à l'Observatoire", _ascend, func(): return active() and _s("h_done"), 2.0, 3.5)


# --- Voyage ---------------------------------------------------------------------------------------

func travel() -> void:
	if _busy:
		return
	_busy = true
	if v.player.global_position.y < 100.0:
		_ret = v.player.global_position
	else:
		_ret = Vector3(4.2, Island.height(4.2, -39.5) + 0.2, -39.5)
	var tw: Tween = v.maquette._fade_to(0.0, 1.0, 0.9)
	tw.tween_callback(_travel_now)


func _travel_now() -> void:
	for r in [v.b.root, v.z.root, v.bel.root]:
		if r != null:
			r.visible = false
	Save.story["at_v"] = false
	Save.story["at_b"] = false
	Save.story["at_k"] = false
	root.visible = true
	Save.story["at_h"] = true
	Save.story["v5_started"] = true
	Save.save_game()
	var ele: Dictionary = v._speaker("eleonore")
	if not ele.is_empty():
		var node = ele["node"]
		if node.get_parent() != root:
			node.get_parent().remove_child(node)
			root.add_child(node)
		node.position = Vector3(1.8, 0.03, 34.5)
		node.rest_yaw = 0.0
	v.player.global_position = P + Vector3(0, 0.1, 36.0)
	v.player._vy = 0.0
	v.player._face_yaw(0.0)
	v.player._place_origin(true, 0.0)
	_t0 = _now()
	_last_lt = 0.0
	_frozen = _s("h_frozen") and not _s("h_done")
	var tw2: Tween = v.maquette._fade_to(1.0, 0.0, 1.0)
	tw2.tween_callback(_arrived)


func _arrived() -> void:
	_busy = false
	Fx.text(v.world, P + Vector3(0, 3.0, 32.0), "CHAPITRE 5", Color(1.0, 0.95, 0.5), 1.5, 5.0)
	_later(1.2, func(): Fx.text(v.world, P + Vector3(0, 2.2, 32.0), "L'HOMME QUI VOLAIT DU TEMPS", Color(0.8, 0.9, 1.0), 0.8, 5.0))
	_later(3.0, func(): v._pico("Un village entièrement construit autour d'une horloge. Si la ponctualité était un climat, ici ce serait la tempête."))


func leave() -> void:
	if _busy:
		return
	_busy = true
	var tw: Tween = v.maquette._fade_to(0.0, 1.0, 0.9)
	tw.tween_callback(_leave_now)


func _leave_now() -> void:
	root.visible = false
	Save.story["at_h"] = false
	Save.save_game()
	v.y.place_eleonore()
	v.player.global_position = _ret
	v.player._vy = 0.0
	v.player._place_origin(true, 0.0)
	var tw2: Tween = v.maquette._fade_to(1.0, 0.0, 0.9)
	tw2.tween_callback(_unbusy)


func _unbusy() -> void:
	_busy = false


# --- Cadrans, détails, Receveur -------------------------------------------------------------------

func _bump(i: int) -> void:
	var h := _hour(i) % 12 + 1
	Save.story["h_cl%d" % i] = h
	Save.save_game()
	_refresh_clock(i)
	Bells.play(v.world, "tick", 0.0, P + CL_POS[i] + Vector3(0, 3.0, 0), 2.0)
	if _synced() and not _s("h_sync"):
		Save.story["h_sync"] = true
		Save.save_game()
		for k in 3:
			_later(0.6 + k * 1.1, Bells.play.bind(v.world, "bell", 130.8, P + Vector3(0, 9.0, -10.0), 4.0))
		Fx.text(v.world, P + Vector3(0, 6.5, 0.0), "LES QUATRE CADRANS S'ACCORDENT : TROIS HEURES PILE", Color(1.0, 0.95, 0.5), 0.9, 6.0)
		_later(4.0, func(): v._pico("Les quatre cadrans d'accord. C'est la première fois qu'un village unanime ne se dispute pas pour un pont."))


func _note() -> void:
	var k := _loop_n % 3
	Save.story["h_d%d" % k] = true
	Save.save_game()
	Bells.play(v.world, "tick", 0.0, v.player.global_position, 0.0)
	var n := _clues()
	Fx.text(v.world, v.player.global_position + Vector3(0, 2.4, 0) - v.player.global_basis.z * 1.6, "DÉTAIL NOTÉ : %s (%d/3)" % [DETAILS[k][1], n], Color(0.7, 1.0, 0.75), 0.7, 3.5)
	if n >= 3:
		_later(2.0, func(): v._pico("Une lettre pour L. Plume, un pot de minutes, un badge du Château. Trois détails, un seul coupable. Il ne reste qu'à l'attraper... quand le temps voudra bien s'arrêter."))


func _can_catch() -> bool:
	return _clues() >= 3 and _s("h_sync")


func _freeze() -> void:
	_frozen = true
	Save.story["h_frozen"] = true
	Save.save_game()
	Fx.text(v.world, P + Vector3(2.0, 4.4, 11.0), "LE TEMPS S'ARRÊTE", Color(0.8, 0.95, 1.0), 1.1, 5.0)
	_later(1.5, func(): v._pico("Plus de boucle. Il est resté coincé avec son pot. Allons lui parler avant que les secondes ne reprennent."))


func _confront() -> void:
	_talking = true
	var lines := [
		["r", "Chut ! ...Oh. Le temps est suspendu. C'est très impoli, ça."],
		["e", "Hubert Sablier, Receveur des Minutes. Vous remplissez des pots avec les cinq minutes de quatorze heures."],
		["r", "Cinq minutes par tour, pour le Château. Ordre de Monsieur Basile : « Rapportez-moi tout le temps qu'on ne vous réclame pas. »"],
		["p", "Du temps en pot... Pour en faire quoi ?"],
		["r", "Je ne pose pas de questions, je pose des pots. Il dit seulement que c'est pour quelqu'un qui n'en a plus assez."],
		["e", "...Quelqu'un qui n'en a plus assez."],
		["r", "Je peux arrêter ma tournée. Mais la boucle, ce n'est pas moi : là-haut, à l'Observatoire, quelque chose rembobine tout seul. Je ramasse juste les miettes."],
		["r", "Tenez, la clé des Rouages. Le haut de la tour. Soyez à l'heure : c'est le seul conseil que je sais donner."],
	]
	var t := 0.6
	for l in lines:
		_later(t, _line.bind(l[0], l[1]))
		t += 2.5 + String(l[1]).length() * 0.055 + 0.7
	_later(t, _confront_end)


func _line(who: String, text: String) -> void:
	match who:
		"r":
			receveur.chibi.say(text, 2.5 + text.length() * 0.055)
		"e":
			var ele: Dictionary = v._speaker("eleonore")
			if not ele.is_empty():
				ele["node"].chibi.say(text, 2.5 + text.length() * 0.055)
		_:
			v._pico(text)


func _confront_end() -> void:
	_talking = false
	Save.story["h_done"] = true
	Save.story["h_key"] = true
	Save.shells += 30
	Save.save_game()
	_frozen = false
	receveur.visible = false
	jar.visible = false
	orb.visible = false
	Fx.puff(v.world, P + Vector3(4.0, 1.5, 12.5), Color(0.8, 0.85, 1.0))
	Fx.text(v.world, P + Vector3(0, 4.5, 8.0), "CLÉ DES ROUAGES  ·  +30 coquillages", Color(1.0, 0.9, 0.5), 0.9, 5.0)
	_later(3.0, func(): v._pico("La boucle est finie ici, mais pas là-haut. La porte de la tour, au pied de l'horloge, devrait nous laisser passer."))


func _ascend() -> void:
	Fx.text(v.world, P + Vector3(0, 3.0, -9.5), "Les rouages grincent : l'Observatoire n'est pas encore remonté.", Color(0.85, 0.95, 1.0), 0.6, 5.0)
	if not _s("h_door_said"):
		Save.story["h_door_said"] = true
		_later(1.2, func(): v._pico("Là-haut, quelqu'un a brisé l'horloge d'origine. On y monte à la prochaine séance, avec de la patience et des clés."))


# --- Événements des dialogues ----------------------------------------------------------------------

func event(ev: String, _node) -> void:
	match ev:
		"h_go":
			travel()
		"h_back":
			leave()


# --- Boucle -----------------------------------------------------------------------------------------

func _hide_all() -> void:
	facteur.visible = false
	receveur.visible = false
	jar.visible = false
	orb.visible = false
	letter.visible = false


func _on_reset() -> void:
	_loop_n += 1
	_detail_on = false
	_detail_shown = false
	_last_min = -1
	Save.story["h_loops"] = int(Save.story.get("h_loops", 0)) + 1
	Bells.play(v.world, "metal", 0.0, P + Vector3(0, 9.0, -10.0), -2.0)
	Fx.text(v.world, P + Vector3(0, 12.5, -9.0), "tic-tic-TOC  (la pendule revient en arrière)", Color(0.85, 0.95, 1.0), 0.7, 3.5)


func _pose(lt: float) -> void:
	var minute := lt / LOOP * 5.0
	hands_m.rotation.z = -minute * TAU / 60.0
	hands_h.rotation.z = -(2.0 + minute / 60.0) * TAU / 12.0
	if int(minute) != _last_min:
		_last_min = int(minute)
		Bells.play(v.world, "tick", 0.0, P + Vector3(0, 9.0, -10.0), -4.0)
	# Facteur : traverse la place
	if lt < 30.0:
		facteur.visible = true
		facteur.position = Vector3(-18.0 + 36.0 * lt / 30.0, 0.03, 11.0)
		facteur.chibi.rotation.y = -PI * 0.5
		facteur.chibi.walk = 1.0
	else:
		facteur.visible = false
	letter.visible = lt >= 12.0 and lt < LOOP - 0.2
	# Receveur
	if lt >= 14.0 and lt < 34.0:
		receveur.visible = true
		if lt < 20.0:
			receveur.position = Vector3(lerpf(20.0, 4.0, (lt - 14.0) / 6.0), 0.03, 12.5)
			receveur.chibi.rotation.y = PI * 0.5
			receveur.chibi.walk = 1.0
		elif lt < 28.0:
			receveur.position = Vector3(4.0, 0.03, 12.5)
			receveur.chibi.rotation.y = 0.15
			receveur.chibi.walk = 0.0
		else:
			receveur.position = Vector3(lerpf(4.0, 20.0, (lt - 28.0) / 6.0), 0.03, 12.5)
			receveur.chibi.rotation.y = -PI * 0.5
			receveur.chibi.walk = 1.0
		jar.visible = lt >= 20.0
	else:
		receveur.visible = false
		jar.visible = false
	# La minute s'envole de l'horloge vers le pot
	if lt >= 22.0 and lt < 26.0:
		var s := (lt - 22.0) / 4.0
		var from := FACE
		var to: Vector3 = receveur.position + Vector3(0.3, 0.95, 0.0)
		orb.position = from.lerp(to, s) + Vector3(0, sin(s * PI) * 1.5, 0)
		orb.visible = true
	else:
		orb.visible = false
	# Détail du tour (différent à chaque répétition)
	if lt >= 26.0 and lt < 34.0:
		_detail_on = true
		if not _detail_shown:
			_detail_shown = true
			_show_detail()
			if _can_catch():
				_freeze()
	elif lt >= 34.0:
		_detail_on = false


func _show_detail() -> void:
	var k := _loop_n % 3
	var at := Vector3(-3.6, 1.2, 11.4)
	if k == 1:
		at = receveur.position + Vector3(0, 1.7, 0)
	elif k == 2:
		at = receveur.position + Vector3(0, 2.2, 0)
	Fx.text(v.world, P + at, DETAILS[k][0], Color(1.0, 0.97, 0.85), 0.5, 7.0)


func update() -> void:
	if not active() or v.player == null:
		return
	if _frozen:
		_detail_shown = true
		_pose(27.0)
		_detail_on = false
		orb.visible = true
		orb.position = receveur.position + Vector3(0.3, 0.95, 0.0)
		return
	if _s("h_done"):
		_hide_all()
		_pose_hands_only()
		return
	var lt := fmod(_now() - _t0, LOOP)
	if lt < _last_lt:
		_on_reset()
	_last_lt = lt
	_pose(lt)


func _pose_hands_only() -> void:
	hands_m.rotation.z = -TAU * 0.0
	hands_h.rotation.z = -3.0 * TAU / 12.0
