extends XRController3D
## Une main VR : moufle chibi aux couleurs du perso, attraper/lancer avec
## le grip, et rayon de visée pour l'échange de corps (gâchette).

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Sword := preload("res://scripts/sword.gd")
const Rod := preload("res://scripts/rod.gd")
const Save := preload("res://scripts/save.gd")

var player
var is_left := false
var mitten: Node3D
var beam: MeshInstance3D
var held: RigidBody3D
var hold_offset := Transform3D.IDENTITY
var target
var counter: Label3D
var sword_node: Node3D
var sword_out := false
var tool_kind := ""        # "sword" ou "rod" : ce que le grip fait sortir
var _tip_last := Vector3.ZERO
var _hit_cd := {}

var _grip := false
var _trig := false
var _hist: Array[Vector3] = []
var _last := Vector3.ZERO


func setup(p_player: Node3D, left: bool) -> void:
	player = p_player
	is_left = left
	tracker = &"left_hand" if left else &"right_hand"
	pose = &"aim"
	mitten = Node3D.new()
	add_child(mitten)
	beam = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.006
	cm.bottom_radius = 0.006
	cm.height = 1.0
	cm.radial_segments = 6
	cm.rings = 1
	beam.mesh = cm
	beam.material_override = Toon.unlit(Color(1.0, 0.9, 0.3))
	beam.visible = false
	add_child(beam)
	if left:
		# Compteur de coquillages sur le poignet gauche
		counter = Label3D.new()
		counter.font_size = 32
		counter.pixel_size = 0.0012
		counter.outline_size = 8
		counter.outline_modulate = Color(0.13, 0.08, 0.17)
		counter.modulate = Color(1.0, 0.82, 0.86)
		counter.position = Vector3(0, 0.045, 0.14)
		counter.rotation.x = -1.1
		add_child(counter)


func set_counter(txt: String) -> void:
	if counter:
		counter.text = txt
		counter.visible = mitten.visible


func set_colors(skin: Color, sleeve: Color) -> void:
	for c in mitten.get_children():
		mitten.remove_child(c)
		c.queue_free()
	var sx := -1.0 if is_left else 1.0
	var b := Builder.new()
	b.sphere(1.0, Vector3(0, -0.02, 0.05), skin, Vector3(0.048, 0.036, 0.064))
	b.sphere(1.0, Vector3(-sx * 0.042, 0.0, 0.03), skin, Vector3(0.02, 0.02, 0.036), Basis(Vector3.UP, -sx * 0.5), 8)
	b.cylinder(0.042, 0.046, 0.07, Vector3(0, -0.02, 0.13), sleeve, Basis(Vector3.RIGHT, PI / 2.0), 10)
	b.build(mitten, Toon.vertex_color(0.006), "Mitten")


func _process(delta: float) -> void:
	var active: bool = player != null and player.vr and get_is_active()
	mitten.visible = active
	if not active:
		beam.visible = false
		return

	var p := global_position
	_hist.push_back((p - _last) / maxf(delta, 0.001))
	if _hist.size() > 5:
		_hist.pop_front()
	_last = p

	var g := get_float("grip")
	if not _grip and g > 0.7:
		_grip = true
		_grab()
		if held == null and player.tool_kind() != "":
			_draw_sword(true)
	elif _grip and g < 0.35:
		_grip = false
		_release()
		_draw_sword(false)
	if sword_out and tool_kind == "sword":
		_sword_hits(delta)
	elif sword_out and tool_kind == "rod":
		_rod_update(delta)
	if held:
		held.global_transform = global_transform * hold_offset
		# Manger : on porte la nourriture à la bouche
		if held.get("is_food") and held.global_position.distance_to(player.camera.global_position) < 0.25:
			var food := held
			drop()
			trigger_haptic_pulse("haptic", 0.0, 0.6, 0.15, 0.0)
			player.eat(food)

	_update_aim()


func _grab() -> void:
	var best: RigidBody3D = null
	var best_d := 0.2
	for n in get_tree().get_nodes_in_group("grab"):
		var rb := n as RigidBody3D
		if rb == null:
			continue
		var d := rb.global_position.distance_to(global_position) - float(rb.get("radius"))
		if d < best_d:
			best_d = d
			best = rb
	if best == null:
		return
	# Si l'autre main tient déjà l'objet, on le lui prend
	if best.has_meta("held_by"):
		var other = best.get_meta("held_by")
		if other != self and is_instance_valid(other):
			other.drop()
	held = best
	held.freeze = true
	held.set_meta("held_by", self)
	hold_offset = global_transform.affine_inverse() * held.global_transform
	mitten.scale = Vector3(1.0, 0.8, 0.9)
	trigger_haptic_pulse("haptic", 0.0, 0.5, 0.08, 0.0)
	if held.has_method("on_grab"):
		held.on_grab()


func drop() -> void:
	if held:
		held.remove_meta("held_by")
		held = null
	mitten.scale = Vector3.ONE


func _release() -> void:
	if held == null:
		return
	var v := Vector3.ZERO
	for h in _hist:
		v += h
	if _hist.size() > 0:
		v /= _hist.size()
	var rb := held
	drop()
	rb.freeze = false
	rb.linear_velocity = v * 1.4
	rb.angular_velocity = Vector3(randf_range(-4, 4), randf_range(-4, 4), randf_range(-4, 4))
	if rb.has_method("on_release"):
		rb.on_release()


func _set_hover(o, on: bool) -> void:
	if o == null or not is_instance_valid(o):
		return
	if o.has_method("set_hover"):
		o.set_hover(on)
	elif o.get("chibi") != null:
		o.chibi.set_targeted(on)


## Rayon de visée : vers un perso (échange de corps) ou un bouton du magasin.
func _update_aim() -> void:
	var obj = null
	var hit_pos := Vector3.ZERO
	if held == null:
		var from := global_position
		var to := from - global_basis.z * 12.0
		var q := PhysicsRayQueryParameters3D.create(from, to, 1 | 4 | 16)
		q.exclude = [player.get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		if not hit.is_empty():
			var c = hit["collider"]
			if c.has_method("press") or c.has_method("set_char"):
				obj = c
				hit_pos = hit["position"]
	if target != null and not is_instance_valid(target):
		target = null
	if obj != target:
		_set_hover(target, false)
		target = obj
		if obj:
			_set_hover(obj, true)
			trigger_haptic_pulse("haptic", 0.0, 0.2, 0.04, 0.0)
	beam.visible = obj != null
	if obj:
		var dist := global_position.distance_to(hit_pos)
		beam.transform = Transform3D(Basis(Vector3.RIGHT, -PI / 2.0) * Basis.from_scale(Vector3(1, dist, 1)), Vector3(0, 0, -dist * 0.5))

	var t := get_float("trigger") > 0.7
	if t and not _trig and obj == null and sword_out and tool_kind == "rod":
		player.fishing.action(sword_node.to_global(Rod.TIP), -global_basis.z)
		trigger_haptic_pulse("haptic", 0.0, 0.3, 0.05, 0.0)
	if t and not _trig and obj:
		if obj.has_method("press"):
			obj.press()
			trigger_haptic_pulse("haptic", 0.0, 0.4, 0.06, 0.0)
		else:
			player.swap_with(obj, true)
			trigger_haptic_pulse("haptic", 0.0, 0.8, 0.2, 0.0)
	_trig = t


# --- Épée ------------------------------------------------------------------------

func refresh_sword() -> void:
	if sword_node:
		sword_node.queue_free()
		sword_node = null
	tool_kind = player.tool_kind()
	if tool_kind == "":
		sword_out = false
		return
	sword_node = Node3D.new()
	sword_node.name = "Tool"
	add_child(sword_node)
	var b := Builder.new()
	if tool_kind == "rod":
		Rod.add(b)
	else:
		Sword.add(b, Save.sword)
	b.build(sword_node, Toon.vertex_color(0.006), "ToolMesh")
	# Lame vers l'avant, un peu relevée (pose "aim" : -Z = devant)
	sword_node.transform = Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-60.0)), Vector3(0, -0.02, 0.05))
	sword_node.visible = sword_out


func _draw_sword(on: bool) -> void:
	if on and sword_node == null:
		refresh_sword()
	sword_out = on and sword_node != null
	if sword_node:
		sword_node.visible = sword_out
	if not sword_out and tool_kind == "rod" and player.fishing and player.fishing.busy():
		player.fishing.cancel()
	if sword_out:
		_tip_last = sword_node.to_global(Vector3(0, 0.9, 0))
		trigger_haptic_pulse("haptic", 0.0, 0.3, 0.05, 0.0)


## Un coup compte si la lame bouge assez vite et passe près d'un monstre.
func _sword_hits(delta: float) -> void:
	var base := sword_node.to_global(Vector3(0, 0.12, 0))
	var tip := sword_node.to_global(Vector3(0, 0.95, 0))
	var speed := tip.distance_to(_tip_last) / maxf(delta, 0.001)
	_tip_last = tip
	var now := Time.get_ticks_msec()
	if speed < 1.6:
		return
	for m in get_tree().get_nodes_in_group("monster"):
		if m.dead:
			continue
		var id: int = m.get_instance_id()
		if now - int(_hit_cd.get(id, 0)) < 350:
			continue
		var c: Vector3 = m.center()
		var seg := tip - base
		var t := clampf((c - base).dot(seg) / seg.length_squared(), 0.0, 1.0)
		if c.distance_to(base + seg * t) < float(m.radius) + 0.12:
			_hit_cd[id] = now
			var dmg: int = Sword.DAMAGE[Save.sword] + (1 if speed > 5.0 else 0)
			m.hit(dmg, player.global_position)
			trigger_haptic_pulse("haptic", 0.0, 1.0, 0.12, 0.0)


## Canne en main : le fil suit le bout de la canne, et un coup sec vers le
## haut ferre le poisson.
func _rod_update(delta: float) -> void:
	var tip := sword_node.to_global(Rod.TIP)
	var vy := (tip.y - _tip_last.y) / maxf(delta, 0.001)
	_tip_last = tip
	if player.fishing:
		player.fishing.tip = tip
		if vy > 2.2:
			player.fishing.jerk()
