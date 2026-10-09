extends RefCounted
## Chapitre 3, première partie : BRUMELUNE, « les souvenirs qui n'étaient pas à nous ».
## Village sur pilotis dans le marais des Murmures (zone y = 700). La brume garde les voix.
## Des habitants se sont échangé des souvenirs : ils flottent en « bulles » au-dessus d'eux.
## Il faut les rendre à leur propriétaire, puis décider quoi faire du plus lourd d'entre eux.

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Fx := preload("res://scripts/fx.gd")
const Save := preload("res://scripts/save.gd")
const Characters := preload("res://scripts/characters.gd")
const VB := preload("res://scripts/village_build.gd")
const Island := preload("res://scripts/island.gd")

const P := Vector3(0.0, 700.0, 0.0)
const WOODC := Color(0.55, 0.4, 0.3)

## id : [propriétaire, couleur, texte entendu dans la bulle]
const ORBS := {
	"mer": ["ouessant", Color(0.45, 0.7, 1.0), "« ... hisser la grand-voile avant l'orage. Le sel sur les lèvres, le roulis qui berce. »"],
	"cap": ["ouessant", Color(0.6, 0.55, 1.0), "« ... cap au nord-nord-est, la Grande Ourse à bâbord. Ne jamais se fier à la boussole du voisin. »"],
	"chev": ["capitaine", Color(0.55, 0.95, 0.55), "« ... trois chevreaux au pré : Mimosa, Tonnerre et Pâquerette. Le plus petit mange les rideaux. »"],
	"four": ["honore", Color(1.0, 0.75, 0.4), "« ... quatre heures du matin, le levain qui respire, la pâte qu'on réveille doucement. »"],
	"vie": ["hortense", Color(1.0, 0.85, 0.3), "« ... Aristide, qui chantait faux en pétrissant ; une tasse de plus sur la table, tous les soirs. »"],
}

var v
var root: Node3D
var orbs := {}
var goat: Node3D
var _busy := false
var _ret := Vector3.ZERO
var _t := 0.0


func build() -> void:
	Save.story["at_b"] = false
	root = Node3D.new()
	root.name = "Brumelune"
	v.add_child(root)
	root.position = P
	root.visible = false
	_ground()
	_walks()
	_houses()
	_archive_dome()
	_fog()
	_people()
	_orbs()
	_goat()
	_hotspots()
	_sync_orbs()


func _s(k: String) -> bool:
	return Save.story.get(k, false)


func _hold() -> String:
	return str(Save.story.get("b_hold", ""))


func _later(t: float, c: Callable) -> void:
	v.get_tree().create_timer(t).timeout.connect(c)


func active() -> bool:
	return root != null and root.visible


# --- Décor -------------------------------------------------------------------------------------

func _ground() -> void:
	var wm := StandardMaterial3D.new()
	wm.albedo_color = Color(0.22, 0.45, 0.5, 0.9)
	wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var water := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(200.0, 200.0)
	water.mesh = pm
	water.material_override = wm
	root.add_child(water)
	water.position = Vector3(0, -0.3, 0)
	var b := Builder.new()
	b.collider(Vector3(170.0, 1.0, 170.0), Vector3(0, -1.0, 0))
	for sx in [-1, 1]:
		b.collider(Vector3(2.0, 8.0, 100.0), Vector3(sx * 45.0, 3.0, -5.0))
	b.collider(Vector3(100.0, 8.0, 2.0), Vector3(0, 3.0, -52.0))
	b.collider(Vector3(100.0, 8.0, 2.0), Vector3(0, 3.0, 44.0))
	b.build(root, Toon.flat(WOODC), "Bords")
	# Roseaux
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var rb := Builder.new()
	for k in 90:
		var x := rng.randf_range(-40.0, 40.0)
		var z := rng.randf_range(-45.0, 40.0)
		if absf(x) < 14.0 and z > -30.0 and z < 38.0:
			continue
		var h := rng.randf_range(1.2, 2.4)
		rb.cylinder(0.04, 0.05, h, Vector3(x, h * 0.5 - 0.3, z), Color(0.5, 0.65, 0.35), Basis(Vector3.RIGHT, rng.randf_range(-0.12, 0.12)), 4)
		rb.sphere(0.1, Vector3(x, h - 0.25, z), Color(0.55, 0.38, 0.25), Vector3(1.0, 2.0, 1.0), Basis(), 5)
	rb.build(root, Toon.vertex_color(0.0), "Roseaux")


func _walks() -> void:
	var b := Builder.new()
	# Ponton principal et branches
	_deck(b, Vector3(0, 0, 4.0), Vector3(3.2, 0.2, 66.0))
	_deck(b, Vector3(0, 0, 0.0), Vector3(12.0, 0.2, 12.0))
	_deck(b, Vector3(-5.5, 0, 10.0), Vector3(10.0, 0.2, 3.0))
	_deck(b, Vector3(5.5, 0, 10.0), Vector3(10.0, 0.2, 3.0))
	_deck(b, Vector3(-5.5, 0, -8.0), Vector3(10.0, 0.2, 3.0))
	_deck(b, Vector3(5.5, 0, -8.0), Vector3(10.0, 0.2, 3.0))
	_deck(b, Vector3(5.5, 0, 5.5), Vector3(7.0, 0.2, 3.0))
	_deck(b, Vector3(0, 0, -25.0), Vector3(7.0, 0.2, 6.0))
	_deck(b, Vector3(0, 0, 33.0), Vector3(6.0, 0.2, 6.0))
	_deck(b, Vector3(4.5, 0, 22.0), Vector3(6.0, 0.2, 3.0))
	_deck(b, Vector3(-4.5, 0, -16.0), Vector3(6.0, 0.2, 3.0))
	_deck(b, Vector3(3.5, 0, -20.0), Vector3(5.0, 0.2, 3.0))
	# Lanterne centrale
	b.cylinder(0.08, 0.1, 3.4, Vector3(0, 1.7, 0), WOODC.darkened(0.2), Basis(), 6)
	b.sphere(0.28, Vector3(0, 3.5, 0), Color(1.0, 0.9, 0.55), Vector3.ONE, Basis(), 8)
	# Lanternes le long du ponton
	for k in 8:
		var z := 28.0 - k * 7.0
		var side := -1.0 if k % 2 == 0 else 1.0
		b.cylinder(0.05, 0.06, 2.2, Vector3(side * 1.7, 1.1, z), WOODC.darkened(0.25), Basis(), 5)
		b.sphere(0.16, Vector3(side * 1.7, 2.3, z), Color(1.0, 0.88, 0.5), Vector3.ONE, Basis(), 6)
	# Trappe de l'Archive
	b.box(Vector3(2.0, 0.06, 2.0), Vector3(0, 0.12, -25.0), Color(0.3, 0.25, 0.3), false)
	b.box(Vector3(0.5, 0.05, 0.1), Vector3(0, 0.17, -24.2), Color(0.85, 0.75, 0.4), false)
	# Banc
	b.box(Vector3(1.6, 0.12, 0.4), Vector3(-3.4, 0.5, 0.5), WOODC, false)
	b.box(Vector3(0.12, 0.45, 0.35), Vector3(-4.1, 0.25, 0.5), WOODC, false)
	b.box(Vector3(0.12, 0.45, 0.35), Vector3(-2.7, 0.25, 0.5), WOODC, false)
	b.build(root, Toon.vertex_color(0.006), "Pontons")
	VB.label(root, "BRUMELUNE", Vector3(0, 2.7, 35.8), 0.0075, Color(1, 0.95, 0.8), 56, 0.0, 10)
	VB.label(root, "population : variable", Vector3(0, 2.1, 35.8), 0.003, Color(1, 0.95, 0.8), 44, 0.0, 6)
	VB.label(root, "(ne pas confondre avec brume, lune, ni Brumelune)", Vector3(0, 1.7, 35.8), 0.0022, Color(1, 0.95, 0.8), 40, 0.0, 6)


func _deck(b: Builder, c: Vector3, size: Vector3) -> void:
	b.box(size, c + Vector3(0, -0.05, 0), WOODC, true)
	# Pilotis aux quatre coins
	for sx in [-0.45, 0.45]:
		for sz in [-0.45, 0.45]:
			if size.z > 40.0 and sz == 0.45:
				continue
			b.cylinder(0.14, 0.14, 1.2, c + Vector3(sx * size.x, -0.8, sz * size.z), WOODC.darkened(0.3), Basis(), 5)
	if size.z > 40.0:
		for k in 8:
			var z := c.z - size.z * 0.5 + 4.0 + k * 8.0
			for sx in [-1.4, 1.4]:
				b.cylinder(0.12, 0.12, 1.2, Vector3(sx, -0.8, z), WOODC.darkened(0.3), Basis(), 5)


func _hut(pos: Vector3, yaw: float, w: float, d: float, h: float, wall: Color, roof: Color, title: String, sub: String) -> Node3D:
	var n := Node3D.new()
	n.name = title.replace(" ", "")
	root.add_child(n)
	n.position = pos
	n.rotation.y = yaw
	var b := Builder.new()
	b.box(Vector3(w, h, d), Vector3(0, h * 0.5, 0), wall, true)
	b.prism(Vector3(w + 0.7, 1.4, d + 0.7), Vector3(0, h + 0.7, 0), roof, Basis())
	b.box(Vector3(1.0, 1.9, 0.12), Vector3(0, 0.95, d * 0.5 + 0.02), Color(0.4, 0.3, 0.3), false)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(0.7, 0.7, 0.1), Vector3(sx * w * 0.32, h * 0.6, d * 0.5 + 0.02), Color(1.0, 0.95, 0.7), false)
	b.build(n, Toon.vertex_color(0.008), "Mesh")
	VB.label(n, title, Vector3(0, h + 0.2, d * 0.5 + 0.12), 0.0038, Color(1, 0.97, 0.85), 52, 0.0, 10)
	VB.label(n, sub, Vector3(0, h - 0.4, d * 0.5 + 0.12), 0.0019, Color(1, 0.97, 0.85), 44, 0.0, 6)
	return n


func _houses() -> void:
	# Les maisons regardent le ponton : à l'ouest vers +x, à l'est vers -x
	_hut(Vector3(-11.5, 0, 10.0), PI * 0.5, 5.0, 4.4, 3.0, Color(1.0, 0.85, 0.62), Color(0.75, 0.4, 0.3), "BOULANGERIE DU LEVAIN", "Pain, brume et souvenirs (variable)")
	var nav := _hut(Vector3(11.5, 0, 10.0), -PI * 0.5, 5.0, 4.4, 2.6, Color(0.7, 0.85, 0.95), Color(0.3, 0.45, 0.65), "LE PETIT NAVIRE", "Navigation à sec")
	var hb := Builder.new()
	hb.box(Vector3(5.6, 0.6, 5.0), Vector3(0, 0.0, 0), Color(0.35, 0.3, 0.4), false)
	hb.cylinder(0.05, 0.05, 3.4, Vector3(1.8, 4.0, 0), WOODC, Basis(), 5)
	hb.build(nav, Toon.vertex_color(0.01), "Coque")
	_hut(Vector3(-11.5, 0, -8.0), PI * 0.5, 5.0, 4.4, 3.0, Color(0.95, 0.88, 0.95), Color(0.55, 0.4, 0.6), "CHEZ HORTENSE", "Deux tasses, toujours")
	_hut(Vector3(11.5, 0, -8.0), -PI * 0.5, 4.2, 3.6, 2.6, Color(0.85, 0.92, 0.82), Color(0.4, 0.55, 0.4), "L'ABRI DE LÉO", "Fermé pour cause de chagrin d'un autre")
	# Four à pain, dehors
	var ob := Builder.new()
	ob.sphere(0.9, Vector3(-8.0, 0.55, 13.2), Color(0.8, 0.5, 0.35), Vector3(1.0, 0.8, 1.0), Basis(), 10)
	ob.box(Vector3(0.5, 0.45, 0.2), Vector3(-8.0, 0.3, 12.3), Color(0.2, 0.1, 0.1), false)
	ob.build(root, Toon.vertex_color(0.01), "Four")


func _archive_dome() -> void:
	# L'Archive Engloutie : seul le dôme dépasse de l'eau, au nord
	var b := Builder.new()
	b.sphere(11.0, Vector3(0, -0.5, -50.0), Color(0.6, 0.62, 0.78), Vector3(1.0, 0.7, 1.0), Basis(), 14)
	b.cylinder(0.2, 0.4, 5.0, Vector3(0, 7.0, -50.0), Color(0.6, 0.62, 0.78), Basis(), 6)
	for k in 8:
		var a := float(k) * TAU / 8.0
		b.sphere(0.45, Vector3(sin(a) * 9.0, 2.0 + (k % 2) * 1.5, -50.0 + cos(a) * 7.5), Color(1.0, 0.95, 0.6), Vector3.ONE, Basis(), 6)
	b.build(root, Toon.vertex_color(0.0), "Archive")
	VB.label(root, "L'ARCHIVE ENGLOUTIE", Vector3(0, 9.0, -38.0), 0.012, Color(0.85, 0.9, 1.0), 56, 0.0, 10)


func _fog() -> void:
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.9, 0.95, 1.0, 0.16)
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.cull_mode = BaseMaterial3D.CULL_DISABLED
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for k in 26:
		var m := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = rng.randf_range(4.0, 7.0)
		sm.height = sm.radius * 0.7
		m.mesh = sm
		m.material_override = fm
		root.add_child(m)
		var x := rng.randf_range(-40.0, 40.0)
		var z := rng.randf_range(-45.0, 38.0)
		m.position = Vector3(x, 0.4, z)
	# Voix : petits halos qui flottent aux points d'écoute
	for p in [Vector3(4.5, 1.7, 22.0), Vector3(-4.5, 1.7, -16.0), Vector3(3.5, 1.7, -20.0)]:
		var o := Builder.new()
		o.sphere(0.2, p, Color(0.8, 0.95, 1.0), Vector3(1.0, 1.4, 1.0), Basis(), 8)
		o.build(root, Toon.unlit(Color(0.8, 0.95, 1.0)), "Voix")


# --- Les gens ---------------------------------------------------------------------------------------

func _people() -> void:
	v.x._npc(root, "honore", Characters.HONORE, Vector3(-7.6, 0.03, 10.0), PI * 0.5)
	v.x._npc(root, "ouessant", Characters.OUESSANT, Vector3(7.6, 0.03, 10.0), -PI * 0.5)
	v.x._npc(root, "hortense", Characters.HORTENSE, Vector3(-7.6, 0.03, -8.0), PI * 0.5)
	v.x._npc(root, "leo", Characters.LEO, Vector3(7.6, 0.03, -8.0), -PI * 0.5)


func _goat() -> void:
	goat = Node3D.new()
	goat.name = "Capitaine"
	root.add_child(goat)
	goat.position = Vector3(7.5, 0.05, 5.5)
	goat.rotation.y = -PI * 0.5
	var b := Builder.new()
	var wh := Color(0.93, 0.9, 0.85)
	b.box(Vector3(0.9, 0.5, 0.45), Vector3(0, 0.62, 0), wh, false)
	for sx in [-0.32, 0.32]:
		for sz in [-0.15, 0.15]:
			b.cylinder(0.05, 0.05, 0.45, Vector3(sx, 0.22, sz), Color(0.35, 0.3, 0.3), Basis(), 5)
	b.sphere(0.22, Vector3(0.55, 0.88, 0), wh, Vector3(1.2, 1.0, 0.9), Basis(), 8)
	b.cylinder(0.02, 0.05, 0.25, Vector3(0.55, 1.12, 0.1), Color(0.5, 0.45, 0.4), Basis(Vector3.BACK, -0.3), 4)
	b.cylinder(0.02, 0.05, 0.25, Vector3(0.55, 1.12, -0.1), Color(0.5, 0.45, 0.4), Basis(Vector3.BACK, -0.3), 4)
	b.sphere(0.06, Vector3(0.7, 0.72, 0), Color(0.93, 0.9, 0.85), Vector3(0.6, 2.0, 0.6), Basis(), 5)
	b.prism(Vector3(0.5, 0.2, 0.4), Vector3(0.52, 1.18, 0), Color(0.2, 0.25, 0.4), Basis(Vector3.UP, PI * 0.5))
	b.build(goat, Toon.vertex_color(0.01), "Chevre")


func _orbs() -> void:
	var pos := {
		"mer": Vector3(-7.6, 2.2, 10.0),
		"cap": Vector3(7.5, 1.7, 5.5),
		"chev": Vector3(7.6, 2.2, 10.0),
		"four": Vector3(-8.0, 1.5, 13.2),
		"vie": Vector3(7.6, 2.2, -8.0),
	}
	for id in ORBS:
		var o := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.2 if id != "vie" else 0.3
		sm.height = sm.radius * 2.0
		o.mesh = sm
		var m := StandardMaterial3D.new()
		var c: Color = ORBS[id][1]
		m.albedo_color = Color(c.r, c.g, c.b, 0.7)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		o.material_override = m
		root.add_child(o)
		o.position = pos[id]
		orbs[id] = {"node": o, "base": pos[id]}


func _hotspots() -> void:
	v.x.hotspot(root, Vector3(0, 1.3, 35.0), "Retourner à Port-Biscornu", func(): leave(), func(): return active() and not _busy, 2.0, 4.0)
	v.x.hotspot(root, Vector3(-8.0, 1.5, 13.0), "Regarder dans le four", _oven, func(): return not _s("b_g_four") and _hold() == "", 1.7, 3.0)
	v.x.hotspot(root, Vector3(6.2, 1.5, 6.5), "Parler à la chèvre", _goat_talk, func(): return active(), 1.5, 3.0)
	v.x.hotspot(root, Vector3(6.2, 1.1, 6.6), "Prendre la bulle de la chèvre", _goat_take, func(): return not _s("b_g_cap") and _hold() == "", 1.9, 3.0)
	v.x.hotspot(root, Vector3(6.2, 0.7, 6.7), "Offrir la bulle à la chèvre", _goat_give, func(): return _hold() != "", 1.8, 3.0)
	v.x.hotspot(root, Vector3(1.9, 1.4, 1.0), "Réécouter ma bulle", _replay, func(): return _hold() != "", 1.5, 6.0)
	var spots := [["a", Vector3(4.5, 1.5, 22.0)], ["b", Vector3(-4.5, 1.5, -16.0)], ["c", Vector3(3.5, 1.5, -20.0)]]
	for sp in spots:
		var k: String = sp[0]
		v.x.hotspot(root, sp[1], "Écouter la brume", _voice.bind(k), func(): return not _s("b_voice_" + k), 1.7, 3.0)
	v.x.hotspot(root, Vector3(0, 1.2, -23.6), "Ouvrir la trappe de l'Archive", _hatch, func(): return _s("b_done"), 2.2, 3.2)


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
	if v.z.root != null:
		v.z.root.visible = false
	Save.story["at_v"] = false
	root.visible = true
	Save.story["at_b"] = true
	Save.story["v3_started"] = true
	Save.save_game()
	var ele: Dictionary = v._speaker("eleonore")
	if not ele.is_empty():
		var node = ele["node"]
		if node.get_parent() != root:
			node.get_parent().remove_child(node)
			root.add_child(node)
		node.position = Vector3(1.8, 0.03, 31.0)
		node.rest_yaw = 0.0
	v.player.global_position = P + Vector3(0, 0.1, 33.0)
	v.player._vy = 0.0
	v.player._face_yaw(0.0)
	v.player._place_origin(true, 0.0)
	var tw2: Tween = v.maquette._fade_to(1.0, 0.0, 1.0)
	tw2.tween_callback(_arrived)


func _arrived() -> void:
	_busy = false
	Fx.text(v.world, P + Vector3(0, 2.8, 29.0), "CHAPITRE 3", Color(1.0, 0.95, 0.5), 1.5, 5.0)
	_later(1.2, func(): Fx.text(v.world, P + Vector3(0, 2.0, 29.0), "LES SOUVENIRS QUI N'ÉTAIENT PAS À NOUS", Color(0.8, 0.95, 1.0), 0.8, 5.0))
	_later(3.0, func(): v._pico("Brumelune. Ça sent l'eau, le pain et les conversations de l'an dernier. Les bulles colorées au-dessus des gens... ce sont des souvenirs, non ?"))


func leave() -> void:
	if _busy:
		return
	_busy = true
	var tw: Tween = v.maquette._fade_to(0.0, 1.0, 0.9)
	tw.tween_callback(_leave_now)


func _leave_now() -> void:
	root.visible = false
	Save.story["at_b"] = false
	Save.save_game()
	v.y.place_eleonore()
	v.player.global_position = _ret
	v.player._vy = 0.0
	v.player._place_origin(true, 0.0)
	var tw2: Tween = v.maquette._fade_to(1.0, 0.0, 0.9)
	tw2.tween_callback(_unbusy)


func _unbusy() -> void:
	_busy = false


# --- Bulles de souvenir -----------------------------------------------------------------------------

func _take(id: String, where: Vector3) -> void:
	Save.story["b_hold"] = id
	Save.story["b_g_" + id] = true
	Save.save_game()
	_sync_orbs()
	var c: Color = ORBS[id][1]
	Fx.text(v.world, P + where + Vector3(0, 0.6, 0), "BULLE DE SOUVENIR", c.lightened(0.3), 0.7, 3.0)
	_later(0.8, func(): Fx.text(v.world, P + where, ORBS[id][2], Color(0.95, 0.97, 1.0), 0.5, 7.0))


func _replay() -> void:
	var h := _hold()
	if h == "":
		return
	Fx.text(v.world, v.player.global_position + Vector3(0, 2.0, 0) - v.player.global_basis.z * 1.5, ORBS[h][2], Color(0.95, 0.97, 1.0), 0.5, 7.0)


func _oven() -> void:
	_take("four", Vector3(-8.0, 1.5, 13.2))
	v._pico("Un souvenir tout chaud, oublié dans le four. Il sent la farine. Il a l'air d'appartenir à quelqu'un qui a les mains blanches.")


func _goat_talk() -> void:
	var lines := ["Mê. (Cap au nord-nord-est.)", "Mê. (Vous êtes à bâbord de votre propre ombre.)", "Mêêê. (On n'avance pas contre le courant des ragots.)"]
	_say_goat(lines[randi() % lines.size()])


func _say_goat(t: String) -> void:
	Fx.text(v.world, goat.global_position + Vector3(0, 1.9, 0), t, Color(1.0, 0.98, 0.9), 0.6, 4.0)


func _goat_take() -> void:
	_take("cap", Vector3(7.5, 1.7, 5.5))
	_say_goat("Mê... (Je ne sais plus lire les étoiles. Je le regrette un peu.)")
	v._pico("Une chèvre qui lisait les étoiles. Je n'ai rien contre les chèvres. Mais là, j'ai envie de lui demander la route.")


func _goat_give() -> void:
	var h := _hold()
	if h == "chev":
		_deliver("chev", goat.global_position + Vector3(0, 1.4, 0))
		_say_goat("MÊÊÊ ! (Mimosa ! Tonnerre ! Pâquerette !)")
		v._pico("Elle a trois chevreaux. Je n'en reviens pas. Je croyais que la chèvre était dans la navigation.")
	else:
		_say_goat("Mê. (Pas à moi. Ça sent la mer, ou le pain. Je préfère l'herbe.)")


## Appelé par les dialogues : une bulle est offerte au bon propriétaire.
func _deliver(id: String, at: Vector3) -> void:
	Save.story["b_d_" + id] = true
	Save.story["b_hold"] = ""
	Fx.puff(v.world, at, ORBS[id][1])
	Save.save_game()
	_sync_orbs()
	_check_cycle()


func _check_cycle() -> void:
	if _s("b_cycle"):
		return
	for id in ["mer", "cap", "chev", "four"]:
		if not _s("b_d_" + id):
			return
	Save.story["b_cycle"] = true
	Save.shells += 15
	Save.save_game()
	_later(1.5, func():
		Fx.text(v.world, v.player.global_position + Vector3(0, 2.6, 0), "TOUT LE MONDE A RETROUVÉ SES SOUVENIRS", Color(0.7, 1.0, 0.75), 0.8, 5.0)
		Fx.text(v.world, v.player.global_position + Vector3(0, 2.0, 0), "+15 coquillages", Color(1.0, 0.9, 0.5), 0.7, 3.0)
		v._pico("Le boulanger pétrit, le marin navigue, la chèvre est mère. Ça ne règle pas tout. Mais il reste la bulle dorée... et celle-là, ça ne se règle pas avec un rendez-vous."))
	_check_done()


func _check_done() -> void:
	if _s("b_done"):
		return
	if _s("b_cycle") and str(Save.story.get("b_hortense", "")) != "":
		Save.story["b_done"] = true
		Save.save_game()
		_later(5.0, func():
			Fx.text(v.world, P + Vector3(0, 3.0, -22.0), "Au bout du ponton, la trappe de l'Archive brille doucement.", Color(0.85, 0.95, 1.0), 0.7, 6.0)
			v._pico("La trappe, au nord. Elle réagit aux souvenirs rendus. Je crois qu'elle a faim d'histoires."))


func _sync_orbs() -> void:
	for id in orbs:
		var vis := not _s("b_g_" + id) and not _s("b_d_" + id)
		if id == "vie":
			var ch := str(Save.story.get("b_hortense", ""))
			vis = (not _s("b_g_vie")) or ch == "keep" or ch == "share"
		orbs[id]["node"].visible = vis
		var sc := 1.0
		if id == "vie" and str(Save.story.get("b_hortense", "")) == "share":
			sc = 0.55
		orbs[id]["node"].scale = Vector3.ONE * sc


# --- Événements des dialogues ----------------------------------------------------------------------

func event(ev: String, node) -> void:
	var at: Vector3 = node.global_position + Vector3(0, 2.2, 0)
	match ev:
		"b_go":
			travel()
		"b_back":
			leave()
		"b_take_mer":
			_take("mer", Vector3(-7.6, 2.2, 10.0))
			v._pico("Un souvenir de marin dans la tête d'un boulanger. Ça explique les baguettes en forme de rames.")
		"b_take_chev":
			_take("chev", Vector3(7.6, 2.2, 10.0))
			v._pico("Trois chevreaux... Un marin qui se souvient de chevreaux, ce n'est pas un marin. C'est un témoin.")
		"b_take_vie":
			_take("vie", Vector3(7.6, 2.2, -8.0))
			v._pico("Celle-ci pèse. Elle est tiède comme un manteau qu'on garde par habitude. Je crois qu'elle ne nous appartient pas.")
		"b_ok_four":
			_deliver("four", at)
		"b_ok_mer":
			_deliver("mer", at)
		"b_ok_cap":
			_deliver("cap", at)
		"b_hort_give":
			_hortense("give", at)
		"b_hort_keep":
			_hortense("keep", at)
		"b_hort_share":
			_hortense("share", at)
		"b_wrong":
			Fx.text(v.world, at, "Ce n'est pas la bonne bulle", Color(1.0, 0.8, 0.7), 0.6, 2.5)


func _hortense(choice: String, at: Vector3) -> void:
	Save.story["b_hortense"] = choice
	Save.story["b_d_vie"] = true
	Save.story["b_hold"] = ""
	var gain := 10
	match choice:
		"give":
			Fx.text(v.world, at + Vector3(0, 0.3, 0), "UN SOUVENIR REVIENT. ET LE CHAGRIN AVEC.", Color(1.0, 0.9, 0.5), 0.8, 5.0)
		"keep":
			Fx.text(v.world, at + Vector3(0, 0.3, 0), "LÉO GARDE LA BULLE. HORTENSE GARDE SA PAIX.", Color(0.8, 0.9, 1.0), 0.8, 5.0)
		"share":
			gain = 20
			Fx.text(v.world, at + Vector3(0, 0.3, 0), "UN MORCEAU POUR ELLE, LE RESTE POUR LUI", Color(0.8, 1.0, 0.8), 0.8, 5.0)
	Fx.puff(v.world, at, Color(1.0, 0.85, 0.3))
	Save.shells += gain
	Save.save_game()
	_sync_orbs()
	_later(4.0, func(): v._pico("Il n'y avait pas de bonne réponse. Il y avait une réponse qui leur ressemble. J'espère que c'était la leur."))
	_check_done()


func _voice(k: String) -> void:
	Save.story["b_voice_" + k] = true
	Save.save_game()
	var p: Vector3 = P + Vector3(4.5, 2.4, 22.0)
	var lines := ["", ""]
	var pico := ""
	match k:
		"a":
			p = P + Vector3(4.5, 2.4, 22.0)
			lines = ["(une voix d'homme, très ancienne)", "« Garde-moi une place à table, Hortense. Même si tu m'oublies. Surtout si tu m'oublies. »"]
			pico = "La brume garde les voix. Celle-ci a l'air d'avoir attendu longtemps quelqu'un qui passe."
		"b":
			p = P + Vector3(-4.5, 2.4, -16.0)
			lines = ["(deux voix, calmes, polies)", "« Conserver. Tout conserver. Plus personne ne doit rien perdre. » — « Basile... un souvenir qu'on ne peut plus changer, ce n'est plus un souvenir. »"]
			pico = "Basile ? Pas le boulanger. Un autre. Très poli, très sûr de lui. Et quelqu'un lui répond en le tutoyant. Je note."
		"c":
			p = P + Vector3(3.5, 2.4, -20.0)
			lines = ["(une voix d'homme, une voix de Pico ?)", "« Pico... ne leur dis rien avant qu'ils soient prêts. » — « Je ne dis jamais rien. » — « C'est ce que je te reproche. »"]
			pico = "Je n'ai jamais entendu ça. Je le dis tout de suite, pour qu'on le sache : je n'ai jamais entendu ça."
	Fx.text(v.world, p + Vector3(0, 0.5, 0), lines[0], Color(0.8, 0.95, 1.0), 0.55, 4.0)
	_later(1.0, func(): Fx.text(v.world, p, lines[1], Color(1.0, 0.97, 0.85), 0.5, 8.0))
	_later(4.5, func(): v._pico(pico))


func _hatch() -> void:
	Save.story["b_hatch"] = true
	Save.save_game()
	if _s("b_tide"):
		v.ar.enter()
		return
	var p: Vector3 = P + Vector3(0, 1.8, -23.6)
	Fx.text(v.world, p, "L'ARCHIVE ENGLOUTIE", Color(0.85, 0.95, 1.0), 1.0, 5.0)
	_later(1.2, func(): Fx.text(v.world, p - Vector3(0, 0.5, 0), "La trappe ne s'ouvre qu'à marée basse.", Color(1.0, 0.95, 0.8), 0.6, 5.0))
	v._pico("Marée basse. Un marin, ça lit les marées. Demandons à Ouessant, maintenant qu'il se souvient de la mer.")


# --- Boucle -----------------------------------------------------------------------------------------

func update() -> void:
	if not active() or v.player == null:
		return
	_t += 0.016
	for id in orbs:
		var o: Node3D = orbs[id]["node"]
		if o.visible:
			o.position = orbs[id]["base"] + Vector3(0, sin(_t * 1.6 + float(id.length())) * 0.12, 0)
