extends CharacterBody3D
## Riku, le punk. Il reste devant le donjon, suit le joueur du regard, et
## trouve ça "très punk" quand on lui jette un objet dessus.

const Chibi := preload("res://scripts/chibi.gd")
const Characters := preload("res://scripts/characters.gd")

var chibi
var gate
var player: Node3D
var _t := 0.0


func setup(p_gate, p_player: Node3D) -> void:
	gate = p_gate
	player = p_player
	collision_layer = 4
	collision_mask = 0
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.28
	cap.height = 1.3
	cs.shape = cap
	cs.position.y = 0.65
	add_child(cs)
	chibi = Chibi.new()
	add_child(chibi)
	chibi.setup(Characters.PUNK)
	chibi.set_bubble_style(0.0024, 760.0, 1.75)


func bonk(from: Vector3) -> void:
	if gate:
		gate.on_punk_bonked()


func _physics_process(delta: float) -> void:
	_t += delta
	if player == null:
		return
	var to := player.global_position - global_position
	to.y = 0.0
	if to.length() < 10.0 and to.length() > 0.1:
		chibi.arm_r_offset = lerpf(chibi.arm_r_offset, 0.0, clampf(delta * 4.0, 0.0, 1.0))
		var yaw := atan2(-to.x, -to.z) - global_rotation.y
		chibi.rotation.y = lerp_angle(chibi.rotation.y, yaw, clampf(delta * 5.0, 0.0, 1.0))
	else:
		# Air guitar quand personne ne regarde
		chibi.arm_r_offset = sin(_t * 12.0) * 0.5 - 0.6
		chibi.rotation.y = lerp_angle(chibi.rotation.y, PI, clampf(delta * 2.0, 0.0, 1.0))
