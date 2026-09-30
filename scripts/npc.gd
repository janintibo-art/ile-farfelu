extends CharacterBody3D
## Un habitant de l'île : se balade, se tourne vers toi quand tu approches,
## lance des répliques, et râle quand on lui jette un truc dessus.

const Chibi := preload("res://scripts/chibi.gd")
const Characters := preload("res://scripts/characters.gd")
const Island := preload("res://scripts/island.gd")
const Fx := preload("res://scripts/fx.gd")

var chibi
var char_id := 0
var home := Vector3.ZERO
var player: Node3D

var _target := Vector3.ZERO
var _wait := 1.0
var _talk := 3.0
var _vy := 0.0
var _was_near := false


func setup(p_player: Node3D, id: int) -> void:
	player = p_player
	home = global_position
	_target = home
	collision_layer = 4
	collision_mask = 1 | 4 | 8
	floor_snap_length = 0.3
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.28
	cap.height = 1.3
	cs.shape = cap
	cs.position.y = 0.65
	add_child(cs)
	chibi = Chibi.new()
	add_child(chibi)
	set_char(id)
	_talk = randf_range(2.0, 6.0)


func set_char(id: int) -> void:
	char_id = id
	chibi.setup(Characters.LIST[id])


func say_random() -> void:
	var lines: Array = Characters.LIST[char_id]["lines"]
	chibi.say(lines[randi() % lines.size()])


func bonk(from: Vector3) -> void:
	Fx.text(get_parent(), global_position + Vector3(0, 1.5, 0), "BONK !", Color(1.0, 0.5, 0.3), 1.0)
	chibi.say(Characters.BONK_REACTIONS[randi() % Characters.BONK_REACTIONS.size()], 2.5)
	chibi.pop()
	_vy = 3.0
	var away := global_position - from
	away.y = 0.0
	if away.length() > 0.01:
		chibi.rotation.y = atan2(away.x, away.z)


func _physics_process(delta: float) -> void:
	if player == null:
		return
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	var near := to_player.length() < 3.2
	var dir := Vector3.ZERO

	if near:
		_face(to_player, delta)
		if not _was_near:
			_talk = 0.4
	else:
		_wait -= delta
		if _wait <= 0.0:
			var d := _target - global_position
			d.y = 0.0
			if d.length() < 0.4 or is_on_wall():
				_wait = randf_range(1.5, 4.5)
				_pick_target()
			else:
				dir = d.normalized()
	_was_near = near

	_talk -= delta
	if _talk <= 0.0:
		_talk = randf_range(6.0, 11.0) if near else randf_range(12.0, 20.0)
		say_random()

	if is_on_floor():
		_vy = maxf(_vy, -0.5)
	else:
		_vy -= 9.8 * delta
	var speed := 1.3 if global_position.y > -0.15 else 0.7
	velocity = Vector3(dir.x * speed, _vy, dir.z * speed)
	move_and_slide()
	_vy = velocity.y

	chibi.walk = lerpf(chibi.walk, dir.length(), clampf(delta * 6.0, 0.0, 1.0))
	chibi.panic = global_position.y < -0.15
	if dir.length() > 0.1:
		_face(dir, delta)
	if global_position.y < -12.0:
		global_position = home + Vector3(0, 1, 0)


func _face(dir: Vector3, delta: float) -> void:
	var yaw := atan2(-dir.x, -dir.z)
	chibi.rotation.y = lerp_angle(chibi.rotation.y, yaw, clampf(delta * 7.0, 0.0, 1.0))


func _pick_target() -> void:
	for i in 8:
		var t := home + Vector3(randf_range(-7.0, 7.0), 0.0, randf_range(-7.0, 7.0))
		if Island.height(t.x, t.z) > 0.6:
			_target = t
			return
	_target = home
