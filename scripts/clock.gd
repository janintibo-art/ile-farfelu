extends RefCounted
## L'horloge de la semaine, dans la mairie : table d'assemblage (trois morceaux
## de roue -> roue du mardi), emplacement du mardi, pièce centrale, puis le
## souvenir des Mains du Dehors (la maquette).

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Fx := preload("res://scripts/fx.gd")
const Save := preload("res://scripts/save.gd")
const Props := preload("res://scripts/props.gd")

var v
var hall: Node3D
var maquette
var wheel: Node3D
var hub: Node3D
var bz := -3.78
var _starting := false

const WX := -3.5
const WY := 2.9
const AX := 2.0
const TABLE := Vector3(1.2, 0.0, -2.2)


func setup(p_village, p_hall: Node3D) -> void:
	v = p_village
	hall = p_hall
	var tb := Builder.new()
	tb.cylinder(0.55, 0.55, 0.07, TABLE + Vector3(0, 0.78, 0), Color(0.55, 0.4, 0.28), Basis(), 14)
	tb.cylinder(0.08, 0.1, 0.78, TABLE + Vector3(0, 0.39, 0), Color(0.4, 0.28, 0.2), Basis(), 8)
	tb.cylinder(0.3, 0.3, 0.05, TABLE + Vector3(0, 0.03, 0), Color(0.4, 0.28, 0.2), Basis(), 10)
	tb.build(hall, Toon.vertex_color(0.01), "AssemblyTable")
	_label(hall, "ÉTABLI DE L'HORLOGER", TABLE + Vector3(0, 1.15, 0.3))
	v.x.hotspot(hall, TABLE + Vector3(0, 1.45, 0.5), "Assembler la roue du mardi", _assemble, _can_assemble, 1.7)
	v.x.hotspot(hall, TABLE + Vector3(0, 1.45, 0.5), "Il faut trois morceaux de roue", _noop, _missing, 1.7)
	v.x.hotspot(hall, Vector3(WX, 1.9, bz + 0.8), "Poser la roue du mardi", _place_wheel, _can_wheel, 1.6, 4.5)
	v.x.hotspot(hall, Vector3(AX, 1.9, bz + 0.8), "Poser la pièce centrale", _place_axe, _can_axe, 1.7, 4.5)
	v.x.hotspot(hall, Vector3(-0.8, 1.9, bz + 0.8), "Remonter l'horloge", _start, _can_start, 1.6, 5.0)
	_rebuild()


func _noop() -> void:
	pass


func _has3() -> bool:
	return Save.count("roue_a") > 0 and Save.count("roue_b") > 0 and Save.count("roue_c") > 0


func _can_assemble() -> bool:
	return not Save.story.get("wheel_built", false) and _has3()


func _missing() -> bool:
	return v.x.tuesday() and not Save.story.get("wheel_built", false) and not _has3()


func _can_wheel() -> bool:
	return Save.count("roue_mardi") > 0 and not Save.story.get("wheel_placed", false)


func _can_axe() -> bool:
	return Save.count("axe") > 0 and not Save.story.get("axe_placed", false)


func _can_start() -> bool:
	return Save.story.get("wheel_placed", false) and Save.story.get("axe_placed", false) and not Save.story.get("mardi", false) and not _starting


func _label(parent: Node3D, text: String, pos: Vector3) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = 40
	l.pixel_size = 0.0018
	l.outline_size = 6
	l.outline_modulate = Color(0.13, 0.08, 0.17)
	l.modulate = Color(1.0, 0.92, 0.7)
	parent.add_child(l)
	l.position = pos


func update() -> void:
	if Save.story.get("mardi", false):
		if wheel:
			wheel.rotation.z -= 0.012
		if hub:
			hub.rotation.z += 0.012


func _rebuild() -> void:
	if Save.story.get("wheel_placed", false) and wheel == null:
		_make_wheel()
	if Save.story.get("axe_placed", false) and hub == null:
		_make_hub()


func _make_wheel() -> void:
	wheel = Node3D.new()
	wheel.name = "RoueMardi"
	hall.add_child(wheel)
	wheel.position = Vector3(WX, WY, bz + 0.22)
	var b := Builder.new()
	var col := Color(0.55, 0.78, 1.0)
	b.cylinder(0.44, 0.44, 0.1, Vector3.ZERO, col, Basis(Vector3.RIGHT, PI * 0.5), 16)
	for a in 12:
		var ang := a * TAU / 12.0
		b.box(Vector3(0.12, 0.12, 0.1), Vector3(cos(ang) * 0.47, sin(ang) * 0.47, 0), col.darkened(0.15), false, Basis(Vector3.BACK, ang))
	b.cylinder(0.12, 0.12, 0.14, Vector3(0, 0, 0.02), Color(0.85, 0.8, 0.5), Basis(Vector3.RIGHT, PI * 0.5), 8)
	b.build(wheel, Toon.vertex_color(0.006), "Mesh")


func _make_hub() -> void:
	hub = Node3D.new()
	hub.name = "PieceCentrale"
	hall.add_child(hub)
	hub.position = Vector3(AX, WY, bz + 0.26)
	var b := Builder.new()
	var gold := Color(1.0, 0.82, 0.3)
	b.cylinder(0.14, 0.14, 0.12, Vector3.ZERO, gold, Basis(Vector3.RIGHT, PI * 0.5), 10)
	b.box(Vector3(0.9, 0.1, 0.08), Vector3.ZERO, gold, false)
	b.box(Vector3(0.1, 0.9, 0.08), Vector3.ZERO, gold, false)
	b.build(hub, Toon.vertex_color(0.006), "Mesh")


func _assemble() -> void:
	var pieces := ["roue_a", "roue_b", "roue_c"]
	for id in pieces:
		Save.add_item(id, -1)
	var root := Node3D.new()
	hall.add_child(root)
	root.position = TABLE + Vector3(0, 0.95, 0)
	for i in 3:
		var n := Node3D.new()
		root.add_child(n)
		var b := Builder.new()
		Props.paint(b, pieces[i], Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3.ZERO))
		b.build(n, Toon.vertex_color(0.006), "P")
		var ang := i * TAU / 3.0 + 0.4
		n.position = Vector3(cos(ang), 0.5, sin(ang)) * 0.7
		var tw: Tween = v.create_tween()
		tw.tween_property(n, "position", Vector3.ZERO, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	v.get_tree().create_timer(1.0).timeout.connect(_assembled.bind(root))


func _assembled(root: Node3D) -> void:
	Fx.puff(v.world, root.global_position, Color(1.0, 0.95, 0.6))
	Fx.text(v.world, root.global_position + Vector3(0, 0.6, 0), "CLIC !", Color(1.0, 0.9, 0.4), 1.0, 1.4)
	root.queue_free()
	Save.story["wheel_built"] = true
	Save.add_item("roue_mardi")
	Save.save_game()
	v._pico("Une roue complète ! Elle a une petite étiquette : « MAR ». C'est très clair pour une énigme.")


func _place_wheel() -> void:
	Save.add_item("roue_mardi", -1)
	Save.story["wheel_placed"] = true
	Save.save_game()
	_make_wheel()
	Fx.text(v.world, hall.to_global(Vector3(WX, WY + 0.8, bz + 0.5)), "CLAC !", Color(1.0, 0.9, 0.4), 1.0, 1.2)
	v._pico("La roue du mardi est à sa place. Elle ne tourne pas : il lui manque quelque chose au milieu.")
	_check()


func _place_axe() -> void:
	Save.add_item("axe", -1)
	Save.story["axe_placed"] = true
	Save.save_game()
	_make_hub()
	Fx.text(v.world, hall.to_global(Vector3(AX, WY + 0.8, bz + 0.5)), "CLAC !", Color(1.0, 0.9, 0.4), 1.0, 1.2)
	_check()


func _check() -> void:
	if Save.story.get("wheel_placed", false) and Save.story.get("axe_placed", false) and not Save.story.get("mardi", false):
		v._pico("Tout est en place. Il ne reste plus qu'à remonter l'horloge. Je suis très calme. Mes oreilles non.")


func _start() -> void:
	if _starting:
		return
	_starting = true
	maquette.start(_done)


func _done() -> void:
	_starting = false
