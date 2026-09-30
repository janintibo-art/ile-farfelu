extends XRController3D
## Une main VR : moufle chibi aux couleurs du perso, attraper/lancer avec
## le grip, et rayon de visée pour l'échange de corps (gâchette).

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")

var player
var is_left := false
var mitten: Node3D
var beam: MeshInstance3D
var held: RigidBody3D
var hold_offset := Transform3D.IDENTITY
var target

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
	elif _grip and g < 0.35:
		_grip = false
		_release()
	if held:
		held.global_transform = global_transform * hold_offset

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


func _update_aim() -> void:
	var npc = null
	var hit_pos := Vector3.ZERO
	if held == null:
		var from := global_position
		var to := from - global_basis.z * 12.0
		var q := PhysicsRayQueryParameters3D.create(from, to, 1 | 4)
		q.exclude = [player.get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		if not hit.is_empty() and hit["collider"].has_method("set_char"):
			npc = hit["collider"]
			hit_pos = hit["position"]
	if npc != target:
		if target and is_instance_valid(target):
			target.chibi.set_targeted(false)
		target = npc
		if npc:
			npc.chibi.set_targeted(true)
			trigger_haptic_pulse("haptic", 0.0, 0.2, 0.04, 0.0)
	beam.visible = npc != null
	if npc:
		var dist := global_position.distance_to(hit_pos)
		beam.transform = Transform3D(Basis(Vector3.RIGHT, -PI / 2.0) * Basis.from_scale(Vector3(1, dist, 1)), Vector3(0, 0, -dist * 0.5))

	var t := get_float("trigger") > 0.7
	if t and not _trig and npc:
		player.swap_with(npc, true)
		trigger_haptic_pulse("haptic", 0.0, 0.8, 0.2, 0.0)
	_trig = t
