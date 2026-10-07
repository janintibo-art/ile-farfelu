extends RefCounted
## Port-Biscornu, v8 : l'après-donjon et les quêtes secondaires du chapitre 1.
## - Éléonore s'installe à l'auberge, Basile se souvient de ses vingt-sept pains
## - ma chambre (4) et la chambre 7 (la deuxième photographie), très haut dans le ciel
## - fin du chapitre 1 (la silhouette sur la photo, la lumière du château)
## - la porte sans maison, le poisson rancunier, la planche, la clé inconnue

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Island := preload("res://scripts/island.gd")
const Fx := preload("res://scripts/fx.gd")
const Save := preload("res://scripts/save.gd")
const VB := preload("res://scripts/village_build.gd")

const H := Island.VILLAGE_H
const C4 := Vector3(40.0, 400.0, 0.0)
const C7 := Vector3(40.0, 400.0, 30.0)
const DOOR := Vector3(16.0, 0.0, -42.0)

var v
var door_node: Node3D
var door_panel: Node3D
var cell4: Node3D
var cell7: Node3D
var photo2_prop: Node3D
var castle_light: MeshInstance3D
var silhouette: Node3D
var _ret := Vector3.ZERO
var _busy := false


func build() -> void:
	_door()
	_shack()
	_cells()
	_door_hotspots()
	place_eleonore()


func _s(k: String) -> bool:
	return Save.story.get(k, false)


func _later(t: float, c: Callable) -> void:
	v.get_tree().create_timer(t).timeout.connect(c)


# --- Éléonore à l'auberge -------------------------------------------------------------------

func place_eleonore() -> void:
	if not _s("ele_inn"):
		return
	var sp: Dictionary = v._speaker("eleonore")
	if sp.is_empty():
		return
	var node = sp["node"]
	var inn: Node3D = v.nodes["auberge"]
	if node.get_parent() != inn:
		node.get_parent().remove_child(node)
		inn.add_child(node)
	node.position = Vector3(0.3, 0.03, 1.4)
	node.rest_yaw = PI


func after_phare() -> void:
	if not _s("ele_inn"):
		Save.story["ele_inn"] = true
		Save.save_game()
		place_eleonore()
	refresh_door()
	v.get_tree().create_timer(2.0).timeout.connect(func():
		v._pico("Le mardi est revenu dans les souvenirs. Dans le village, ça va faire des histoires. Éléonore s'installe à l'auberge. Tu as une chambre, et la 7 est libre."))


# --- La porte sans maison ----------------------------------------------------------------------

func _door() -> void:
	door_node = Node3D.new()
	door_node.name = "PorteSansMaison"
	v.add_child(door_node)
	door_node.position = Vector3(DOOR.x, H, DOOR.z)
	var b := Builder.new()
	b.box(Vector3(0.18, 2.5, 0.2), Vector3(-0.7, 1.25, 0), Color(0.45, 0.3, 0.25), true)
	b.box(Vector3(0.18, 2.5, 0.2), Vector3(0.7, 1.25, 0), Color(0.45, 0.3, 0.25), true)
	b.box(Vector3(1.6, 0.18, 0.2), Vector3(0, 2.5, 0), Color(0.45, 0.3, 0.25), true)
	b.build(door_node, Toon.vertex_color(0.01), "Frame")
	door_panel = Node3D.new()
	door_node.add_child(door_panel)
	door_panel.position = Vector3(-0.6, 0, 0)
	var pb := Builder.new()
	pb.box(Vector3(1.2, 2.4, 0.08), Vector3(0.6, 1.2, 0), Color(0.55, 0.78, 0.9), false)
	pb.box(Vector3(0.8, 1.0, 0.1), Vector3(0.6, 1.5, 0), Color(0.5, 0.7, 0.85), false)
	pb.build(door_panel, Toon.vertex_color(0.01), "Panel")
	VB.label(door_node, "LA PORTE\n(il n'y a pas de maison)", Vector3(0, 2.95, 0.12), 0.0028, Color(1.0, 0.95, 0.75), 44, 0.0, 8)
	if _s("door_open"):
		door_panel.rotation.y = -1.5
	refresh_door()


func refresh_door() -> void:
	door_node.visible = _s("phare_done")


func _door_hotspots() -> void:
	v.x.hotspot(door_node, Vector3(0, 1.1, 1.0), "Examiner la porte", _look_door,
		func(): return _s("phare_done") and not _s("door_open") and Save.count("poignee") == 0, 1.5)
	v.x.hotspot(door_node, Vector3(0, 1.1, 1.0), "Poser la poignée", _open_door,
		func(): return _s("phare_done") and not _s("door_open") and Save.count("poignee") > 0, 1.5)


func _look_door() -> void:
	Fx.text(v.world, door_node.global_position + Vector3(0, 1.6, 0.8), "La porte de la plage. Pas de poignée.", Color(1.0, 0.95, 0.7), 0.6, 3.0)
	v._pico("Une porte debout, toute seule. Elle n'appartient à aucune maison. Il lui manque une poignée : Barnabé en vend.")
	Save.story["door_seen"] = true
	Save.save_game()


func _open_door() -> void:
	Save.add_item("poignee", -1)
	Save.story["door_open"] = true
	Save.save_game()
	var tw: Tween = v.create_tween()
	tw.tween_property(door_panel, "rotation:y", -1.5, 0.8)
	Fx.text(v.world, door_node.global_position + Vector3(0, 1.6, 0.8), "Elle s'ouvre... sur la même place. Vue de derrière.", Color(1.0, 0.95, 0.7), 0.6, 4.0)
	v._pico("Derrière, il y a le même village. Mais à l'envers. Je note, et je refuse de m'en occuper avant le prochain chapitre.")


# --- La cabane de Gérard, le nid du poisson -----------------------------------------------------

func _shack() -> void:
	var b := Builder.new()
	b.box(Vector3(1.8, 1.4, 1.5), Vector3(-7.5, 1.3, -75.5), Color(0.78, 0.6, 0.4), true)
	b.prism(Vector3(2.2, 0.6, 1.8), Vector3(-7.5, 2.3, -75.5), Color(0.4, 0.5, 0.6), Basis())
	b.box(Vector3(0.5, 0.9, 0.05), Vector3(-7.5, 1.0, -74.72), Color(0.5, 0.35, 0.25), false)
	b.build(v, Toon.vertex_color(0.01), "CabaneGerard")
	VB.label(v, "CABANE DE GÉRARD\n(ne pas déranger le poisson)", Vector3(-7.5, 2.8, -74.5), 0.0022, Color(1.0, 0.95, 0.75), 44, 0.0, 8)
	v.x.hotspot(v, Vector3(-6.2, 1.0, -74.0), "Regarder sous le ponton", _look_fish,
		func(): return _s("gerard_met") and _s("tuesday") and not _s("fish_seen"), 1.7)


func _look_fish() -> void:
	Save.story["fish_seen"] = true
	Save.save_game()
	Fx.text(v.world, Vector3(-6.2, 1.2, -73.0), "Un nid de poisson, juste sous la cabane. Le poisson le garde.", Color(0.8, 0.95, 1.0), 0.6, 4.0)
	v._pico("Gérard a construit sa cabane sur le nid du poisson. Le poisson ne vole pas ses appâts : il défend ses œufs. Parle à Gérard.")


# --- Ma chambre (4) et la chambre 7 ---------------------------------------------------------------------

func _cell(c: Vector3, nm: String, wall: Color) -> Node3D:
	var n := Node3D.new()
	n.name = nm
	v.add_child(n)
	n.position = c
	var b := Builder.new()
	b.box(Vector3(7, 0.3, 5), Vector3(0, -0.15, 0), Color(0.62, 0.5, 0.4), true)
	b.box(Vector3(7, 0.2, 5), Vector3(0, 3.1, 0), wall.darkened(0.2), true)
	b.box(Vector3(7, 3, 0.2), Vector3(0, 1.5, -2.5), wall, true)
	b.box(Vector3(7, 3, 0.2), Vector3(0, 1.5, 2.5), wall, true)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(0.2, 3, 5), Vector3(sx * 3.5, 1.5, 0), wall, true)
	b.box(Vector3(2.0, 0.45, 1.1), Vector3(-2.3, 0.22, -1.7), Color(0.55, 0.38, 0.3), true)
	b.box(Vector3(1.9, 0.2, 1.0), Vector3(-2.3, 0.55, -1.7), Color(0.85, 0.8, 0.9), false)
	b.build(n, Toon.vertex_color(0.01), "Mesh")
	var lt := OmniLight3D.new()
	lt.omni_range = 9.0
	lt.light_energy = 1.3
	n.add_child(lt)
	lt.position = Vector3(0, 2.6, 0)
	return n


func _cells() -> void:
	cell4 = _cell(C4, "Chambre4", Color(0.95, 0.88, 0.78))
	cell7 = _cell(C7, "Chambre7", Color(0.62, 0.62, 0.72))
	cell4.visible = false
	cell7.visible = false
	# Chambre 4 : table, photo, tiroir, fenêtre
	var b := Builder.new()
	b.box(Vector3(1.8, 0.8, 0.9), Vector3(2.0, 0.4, -1.8), Color(0.5, 0.36, 0.28), true)
	b.box(Vector3(0.55, 0.28, 0.5), Vector3(2.6, 0.94, -1.8), Color(0.45, 0.32, 0.25), false)
	b.box(Vector3(2.0, 1.5, 0.1), Vector3(0, 1.8, -2.38), Color(0.3, 0.25, 0.3), false)
	b.box(Vector3(1.8, 1.3, 0.12), Vector3(0, 1.8, -2.34), Color(0.06, 0.07, 0.2), false)
	for k in 14:
		b.sphere(0.03, Vector3(-0.8 + (k * 37 % 17) * 0.1, 1.3 + (k * 53 % 9) * 0.1, -2.27), Color(1.0, 0.98, 0.7), Vector3.ONE, Basis(), 4)
	b.build(cell4, Toon.vertex_color(0.01), "Deco")
	castle_light = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.12, 0.12, 0.05)
	castle_light.mesh = bm
	castle_light.material_override = Toon.unlit(Color(1.0, 0.9, 0.4))
	cell4.add_child(castle_light)
	castle_light.position = Vector3(0.6, 2.2, -2.26)
	castle_light.visible = false
	photo2_prop = Node3D.new()
	cell4.add_child(photo2_prop)
	photo2_prop.position = Vector3(1.8, 0.86, -1.7)
	var pb := Builder.new()
	pb.box(Vector3(0.3, 0.02, 0.22), Vector3.ZERO, Color(0.95, 0.92, 0.82), false, Basis(Vector3.UP, 0.3))
	pb.build(photo2_prop, Toon.vertex_color(0.005), "Photo")
	silhouette = Node3D.new()
	cell4.add_child(silhouette)
	silhouette.position = Vector3(1.8, 1.05, -1.7)
	var sb := Builder.new()
	sb.capsule(0.05, 0.22, Vector3.ZERO, Color(0.05, 0.03, 0.08), Basis())
	sb.build(silhouette, Toon.vertex_color(0.003), "Shape")
	silhouette.visible = false
	VB.label(cell4, "CHAMBRE 4", Vector3(0, 2.8, 2.38), 0.006, Color(0.3, 0.2, 0.2), 52, PI, 0)
	# Chambre 7 : sous le lit
	VB.label(cell7, "CHAMBRE 7\n(depuis mardi)", Vector3(0, 2.8, 2.38), 0.005, Color(0.9, 0.9, 1.0), 52, PI, 0)
	var b7 := Builder.new()
	b7.box(Vector3(0.5, 0.45, 0.4), Vector3(2.3, 0.22, -1.8), Color(0.45, 0.4, 0.5), true)
	b7.build(cell7, Toon.vertex_color(0.01), "Deco")
	# Boutons
	v.x.hotspot(cell4, Vector3(0, 1.5, 1.9), "Sortir de la chambre", func(): _leave(), func(): return cell4.visible and not _busy, 1.6, 5.0)
	v.x.hotspot(cell4, Vector3(-1.0, 1.5, 0.2), "Dormir", _sleep, func(): return _s("phare_done") and not _s("ch1_done") and cell4.visible and not _busy, 1.3, 5.0)
	v.x.hotspot(cell7, Vector3(0, 1.5, 1.9), "Sortir de la chambre", func(): _leave(), func(): return cell7.visible and not _busy, 1.6, 5.0)
	v.x.hotspot(cell7, Vector3(-2.3, 1.2, -0.4), "Regarder sous le lit", _under_bed, func(): return cell7.visible and not _s("photo2"), 1.6, 5.0)
	# Les portes de l'auberge
	var inn: Node3D = v.nodes["auberge"]
	v.x.hotspot(inn, Vector3(0.4, 1.7, -3.6), "Entrer dans ma chambre", func(): _enter_cell(cell4, C4), func(): return _s("room_key") and not _busy, 1.7, 3.6)
	v.x.hotspot(inn, Vector3(3.25, 1.7, -3.6), "Entrer dans la chambre 7", func(): _enter_cell(cell7, C7), func(): return _s("phare_done") and not _busy, 1.8, 3.6)


func _enter_cell(cell: Node3D, c: Vector3) -> void:
	if _busy:
		return
	_busy = true
	_ret = v.player.global_position
	var tw: Tween = v.maquette._fade_to(0.0, 1.0, 0.8)
	tw.tween_callback(func():
		cell.visible = true
		v.player.global_position = c + Vector3(0, 0.1, 1.2)
		v.player._vy = 0.0
		v.player._face_yaw(0.0)
		v.player._place_origin(true, 0.0)
		var tw2: Tween = v.maquette._fade_to(1.0, 0.0, 0.8)
		tw2.tween_callback(func(): _busy = false))


func _leave() -> void:
	if _busy:
		return
	_busy = true
	var tw: Tween = v.maquette._fade_to(0.0, 1.0, 0.8)
	tw.tween_callback(func():
		cell4.visible = false
		cell7.visible = false
		var inn: Node3D = v.nodes["auberge"]
		v.player.global_position = inn.to_global(Vector3(0.8, 0.2, -2.6))
		v.player._vy = 0.0
		v.player._face_yaw(PI)
		v.player._place_origin(true, 0.0)
		var tw2: Tween = v.maquette._fade_to(1.0, 0.0, 0.8)
		tw2.tween_callback(func(): _busy = false))


func _under_bed() -> void:
	Save.story["photo2"] = true
	Save.save_game()
	Fx.text(v.world, cell7.global_position + Vector3(-2.3, 1.4, -0.4), "Une deuxième photographie !", Color(1.0, 0.95, 0.6), 1.0, 3.0)
	_later(1.5, func(): Fx.text(v.world, cell7.global_position + Vector3(-2.3, 1.1, -0.4), "Toi. Devant le Château des Versions Officielles.", Color(0.9, 0.95, 1.0), 0.6, 4.5))
	v._pico("C'est toi, devant le château. Tu n'as jamais été au château. Enfin, il me semble. Je commence à ne plus être sûr de rien, c'est nouveau.")


# --- Fin du chapitre 1 --------------------------------------------------------------------------------------

func _sleep() -> void:
	if not _s("photo2"):
		v._pico("Pas encore. Il reste la chambre 7 : Éléonore y a dormi mardi. Et il y a sûrement quelque chose sous le lit.")
		return
	_busy = true
	var base := cell4.global_position
	Fx.text(v.world, base + Vector3(-0.5, 2.0, 0.5), "Pico s'endort dans son tiroir.", Color(0.9, 0.9, 1.0), 0.8, 3.5)
	_later(3.5, func(): Fx.text(v.world, base + Vector3(1.8, 1.6, -1.4), "La photographie est posée sur la table.", Color(1.0, 0.95, 0.75), 0.7, 3.5))
	_later(7.0, func():
		silhouette.visible = true
		Fx.text(v.world, base + Vector3(1.8, 1.6, -1.4), "...une silhouette derrière toi, sur la photo.", Color(1.0, 0.7, 0.7), 0.7, 3.0))
	_later(9.5, func(): silhouette.visible = false)
	_later(11.0, func():
		castle_light.visible = true
		Fx.text(v.world, base + Vector3(0.6, 2.4, -1.5), "Très loin dans la montagne, une lumière s'allume au château.", Color(1.0, 0.92, 0.5), 0.7, 5.0))
	_later(17.0, func():
		Save.story["ch1_done"] = true
		Save.save_game()
		Fx.text(v.world, base + Vector3(0, 2.4, 0.5), "CHAPITRE 1 TERMINÉ", Color(1.0, 0.95, 0.5), 1.6, 6.0)
		_busy = false)
	_later(19.0, func(): Fx.text(v.world, base + Vector3(0, 1.6, 0.5), "À suivre : le chemin vers Virevolte s'ouvre...", Color(0.9, 0.95, 1.0), 0.7, 6.0))
