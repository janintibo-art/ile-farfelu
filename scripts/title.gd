extends Node3D
## Écran d'accueil : logo + choix de la partie (3 sauvegardes).
## Visée à la manette (VR) ou à la souris / touches 1-3 (PC).

signal chosen(slot: int)

const Toon := preload("res://scripts/toon.gd")
const Fx := preload("res://scripts/fx.gd")
const Save := preload("res://scripts/save.gd")
const ChoiceButton := preload("res://scripts/choice_button.gd")

var vr := false
var cam: Camera3D
var _t := 0.0
var _logo: Node3D
var _buttons: Array = []          # tous les boutons (pour le survol)
var _slot_btn := {}
var _del_btn := {}
var _armed := -1                  # partie dont l'effacement attend confirmation
var _armed_t := 0.0
var _hover = null
var _ctrl: Array = []             # [{node, beam, trig, hover}]
var _done := false
var _info: Label3D


func build(p_vr: bool) -> void:
	vr = p_vr
	if vr:
		var o := XROrigin3D.new()
		add_child(o)
		var c := XRCamera3D.new()
		o.add_child(c)
		cam = c
		for side in [&"left_hand", &"right_hand"]:
			var h := XRController3D.new()
			h.tracker = side
			h.pose = &"aim"
			o.add_child(h)
			var beam := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.005
			cm.bottom_radius = 0.005
			cm.height = 1.0
			cm.radial_segments = 6
			cm.rings = 1
			beam.mesh = cm
			beam.material_override = Toon.unlit(Color(1.0, 0.9, 0.3))
			beam.visible = false
			h.add_child(beam)
			_ctrl.append({"node": h, "beam": beam, "trig": false, "hover": null})
	else:
		cam = Camera3D.new()
		add_child(cam)
		cam.current = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	cam.position = Vector3(0, 1.6, 0)
	_scenery()
	_logo_build()
	_menu_build()


func _scenery() -> void:
	var sea := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 300.0
	cyl.bottom_radius = 300.0
	cyl.height = 0.1
	cyl.radial_segments = 24
	cyl.rings = 1
	sea.mesh = cyl
	sea.material_override = Toon.flat(Color(0.25, 0.62, 0.85))
	sea.position = Vector3(0, -0.05, 0)
	add_child(sea)
	# Petite île avec un palmier, au loin
	var sand := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 16
	sm.rings = 8
	sand.mesh = sm
	sand.material_override = Toon.flat(Color(0.96, 0.86, 0.55))
	sand.scale = Vector3(7.0, 1.2, 5.0)
	sand.position = Vector3(5.0, 0.0, -18.0)
	add_child(sand)
	var trunk := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 0.18
	tm.bottom_radius = 0.28
	tm.height = 4.5
	tm.radial_segments = 8
	tm.rings = 1
	trunk.mesh = tm
	trunk.material_override = Toon.flat(Color(0.6, 0.4, 0.25))
	trunk.position = Vector3(5.0, 3.2, -18.0)
	trunk.rotation.z = 0.12
	add_child(trunk)
	for i in 5:
		var leaf := MeshInstance3D.new()
		var lm := SphereMesh.new()
		lm.radius = 1.0
		lm.height = 2.0
		lm.radial_segments = 10
		lm.rings = 5
		leaf.mesh = lm
		leaf.material_override = Toon.flat(Color(0.3, 0.75, 0.35))
		var a := TAU * float(i) / 5.0
		leaf.scale = Vector3(1.9, 0.25, 0.6)
		leaf.position = Vector3(5.4 + cos(a) * 1.4, 5.5, -18.0 + sin(a) * 1.4)
		leaf.rotation.y = -a
		add_child(leaf)
	for k in 3:
		var cloud := MeshInstance3D.new()
		var cm := SphereMesh.new()
		cm.radius = 1.0
		cm.height = 2.0
		cm.radial_segments = 12
		cm.rings = 6
		cloud.mesh = cm
		cloud.material_override = Toon.unlit(Color(1, 1, 1))
		cloud.scale = Vector3(5.0 + k, 1.2, 2.0)
		cloud.position = Vector3(-14.0 + k * 13.0, 11.0 + k * 1.5, -30.0)
		add_child(cloud)


func _logo_build() -> void:
	_logo = Node3D.new()
	_logo.position = Vector3(0, 3.35, -4.5)
	add_child(_logo)
	var l1 := Label3D.new()
	l1.text = "ÎLE FARFELUE"
	l1.font_size = 128
	l1.pixel_size = 0.0085
	l1.outline_size = 48
	l1.modulate = Color(1.0, 0.85, 0.25)
	l1.outline_modulate = Fx.INK
	l1.shaded = false
	_logo.add_child(l1)
	var l2 := Label3D.new()
	l2.text = "Un monde ouvert tout de travers"
	l2.font_size = 64
	l2.pixel_size = 0.0085
	l2.outline_size = 24
	l2.modulate = Color(1.0, 0.95, 0.9)
	l2.outline_modulate = Fx.INK
	l2.shaded = false
	l2.position = Vector3(0, -0.95, 0)
	_logo.add_child(l2)


func _menu_build() -> void:
	for n in range(1, Save.SLOTS + 1):
		_make_slot(n)
	var q := ChoiceButton.new()
	add_child(q)
	q.setup("Quitter", func(): get_tree().quit(), 0.8, Color(0.9, 0.75, 0.8))
	q.position = Vector3(-1.0, 0.82, -2.4)
	_buttons.append(q)
	_info = Label3D.new()
	_info.font_size = 40
	_info.pixel_size = 0.0022
	_info.outline_size = 12
	_info.modulate = Color(1, 1, 1)
	_info.outline_modulate = Fx.INK
	_info.shaded = false
	_info.position = Vector3(0.35, 0.82, -2.4)
	_info.text = "Visez avec la manette · gâchette pour choisir" if vr else "Clic ou touches 1 / 2 / 3"
	add_child(_info)


func _make_slot(n: int) -> void:
	if _slot_btn.has(n) and is_instance_valid(_slot_btn[n]):
		_buttons.erase(_slot_btn[n])
		_slot_btn[n].queue_free()
	if _del_btn.has(n) and is_instance_valid(_del_btn[n]):
		_buttons.erase(_del_btn[n])
		_del_btn[n].queue_free()
	_del_btn.erase(n)
	var y := 1.5 - float(n - 1) * 0.24
	var d := Save.peek(n)
	var txt := "Partie %d — Nouvelle aventure" % n
	if not d.is_empty():
		txt = "Partie %d — %s · %d coquillages" % [n, d["chap"], d["shells"]]
	var b := ChoiceButton.new()
	add_child(b)
	b.setup(txt, func(): _pick(n), 2.1, Color(1.0, 0.96, 0.88) if d.is_empty() else Color(0.9, 1.0, 0.9))
	b.position = Vector3(-0.2, y, -2.4)
	_slot_btn[n] = b
	_buttons.append(b)
	if not d.is_empty():
		var x := ChoiceButton.new()
		add_child(x)
		x.setup("Effacer", func(): _erase(n), 0.55, Color(1.0, 0.8, 0.8))
		x.position = Vector3(1.2, y, -2.4)
		_del_btn[n] = x
		_buttons.append(x)


func _erase(n: int) -> void:
	if _armed == n:
		Save.delete_slot(n)
		_armed = -1
		_hover = null
		_make_slot(n)
		return
	_armed = n
	_armed_t = 3.0
	var b: ChoiceButton = _del_btn[n]
	b.label.text = "Sûr ?"


func _pick(n: int) -> void:
	if _done:
		return
	_done = true
	chosen.emit(n)


func _process(delta: float) -> void:
	_t += delta
	if _logo:
		_logo.rotation.z = sin(_t * 1.3) * 0.04
		_logo.position.y = 3.35 + sin(_t * 1.8) * 0.06
	if _armed >= 0:
		_armed_t -= delta
		if _armed_t <= 0.0:
			var a := _armed
			_armed = -1
			if _del_btn.has(a) and is_instance_valid(_del_btn[a]):
				_del_btn[a].label.text = "Effacer"
	if _done:
		return
	if vr:
		for c in _ctrl:
			_vr_aim(c)
	else:
		var m := get_viewport().get_mouse_position()
		_set_hover(_ray(cam.project_ray_origin(m), cam.project_ray_normal(m), 40.0))


func _ray(from: Vector3, dir: Vector3, length: float):
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * length, 16)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return null
	return hit["collider"]


func _set_hover(t) -> void:
	if t == _hover:
		return
	if _hover != null and is_instance_valid(_hover):
		_hover.set_hover(false)
	_hover = t
	if t != null:
		t.set_hover(true)


func _vr_aim(c: Dictionary) -> void:
	var h: XRController3D = c["node"]
	if not h.get_is_active():
		c["beam"].visible = false
		return
	var from := h.global_position
	var dir := -h.global_basis.z
	var obj = _ray(from, dir, 10.0)
	if obj != c["hover"]:
		if c["hover"] != null and is_instance_valid(c["hover"]):
			c["hover"].set_hover(false)
		c["hover"] = obj
		if obj != null:
			obj.set_hover(true)
			h.trigger_haptic_pulse("haptic", 0.0, 0.2, 0.04, 0.0)
	var beam: MeshInstance3D = c["beam"]
	beam.visible = true
	var dist := 3.0
	if obj != null:
		dist = from.distance_to(obj.global_position)
	beam.transform = Transform3D(Basis(Vector3.RIGHT, -PI / 2.0) * Basis.from_scale(Vector3(1, dist, 1)), Vector3(0, 0, -dist * 0.5))
	var t := h.get_float("trigger") > 0.7
	if t and not c["trig"] and obj != null and obj.has_method("press"):
		h.trigger_haptic_pulse("haptic", 0.0, 0.4, 0.06, 0.0)
		obj.press()
	c["trig"] = t


func _input(event: InputEvent) -> void:
	if vr or _done:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _hover != null and is_instance_valid(_hover) and _hover.has_method("press"):
			_hover.press()
	elif event is InputEventKey and event.pressed and not event.echo:
		var n: int = event.keycode - KEY_0
		if n >= 1 and n <= Save.SLOTS:
			_pick(n)
