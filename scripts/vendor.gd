extends CharacterBody3D
## Yuki, la vendeuse. Elle reste derrière son comptoir (sur son tabouret),
## regarde le joueur, et prévient la boutique quand on lui jette un truc.

const Chibi := preload("res://scripts/chibi.gd")
const Characters := preload("res://scripts/characters.gd")

var chibi
var shop
var player: Node3D


func setup(p_shop, p_player: Node3D) -> void:
	shop = p_shop
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
	chibi.setup(Characters.VENDOR)
	chibi.set_bubble_style(0.0024, 760.0, 1.75)


func bonk(from: Vector3) -> void:
	if shop:
		shop.on_vendor_bonked()


func _physics_process(delta: float) -> void:
	if player == null:
		return
	var to := player.global_position - global_position
	to.y = 0.0
	if to.length() < 9.0 and to.length() > 0.1:
		var yaw := atan2(-to.x, -to.z) - global_rotation.y
		chibi.rotation.y = lerp_angle(chibi.rotation.y, yaw, clampf(delta * 5.0, 0.0, 1.0))
	else:
		chibi.rotation.y = lerp_angle(chibi.rotation.y, PI, clampf(delta * 2.0, 0.0, 1.0))
