extends RigidBody3D
## Objet qu'on peut attraper avec la main (grip) et lancer.
## Flotte dans l'eau, et fait "BONK !" sur la tête des persos.

const Fx := preload("res://scripts/fx.gd")

var kind := ""
var home := Vector3.ZERO
var radius := 0.12
var grab_text := ""          # onomatopée quand on l'attrape (le poulet fait COUIC)
var _reset := false
var _cooldown := 0.0


func _ready() -> void:
	add_to_group("grab")
	collision_layer = 2
	collision_mask = 1 | 2 | 4
	contact_monitor = true
	max_contacts_reported = 2
	continuous_cd = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	body_entered.connect(_on_body_entered)


func on_grab() -> void:
	if grab_text != "":
		Fx.text(get_parent(), global_position + Vector3(0, 0.35, 0), grab_text, Color(1.0, 0.95, 0.4), 0.6, 0.8)


func _on_body_entered(body: Node) -> void:
	if _cooldown > 0.0 or freeze:
		return
	var speed := linear_velocity.length()
	if speed > 2.2 and body.has_method("bonk"):
		_cooldown = 0.6
		body.bonk(global_position)
	elif kind == "ball" and speed > 3.5:
		_cooldown = 0.5
		Fx.text(get_parent(), global_position + Vector3(0, 0.5, 0), "BOING !", Color(1.0, 0.6, 0.9), 0.7, 0.7)


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if freeze:
		return
	# Flotte dans la mer
	var depth := -global_position.y
	if depth > -radius:
		var k := clampf((depth + radius) / (radius * 2.0), 0.0, 1.0)
		apply_central_force(Vector3.UP * mass * 9.8 * 1.6 * k)
		linear_damp = 1.5
	else:
		linear_damp = 0.05
	if global_position.y < -8.0 or Vector2(global_position.x, global_position.z).length() > 110.0:
		_reset = true


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if _reset:
		_reset = false
		state.transform = Transform3D(Basis(), home)
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO
