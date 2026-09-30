extends CharacterBody3D
## Monstre du donjon (mignon mais grognon).
## types : "slime" (saute), "champi" (marche), "bat" (vole), "boss" (Roi Gloubi).

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Fx := preload("res://scripts/fx.gd")
const Save := preload("res://scripts/save.gd")

const STATS := {
	"slime": {"hp": 2, "speed": 1.6, "radius": 0.35, "shells": [1, 2], "color": Color(0.45, 0.9, 0.45)},
	"champi": {"hp": 3, "speed": 1.3, "radius": 0.35, "shells": [1, 3], "color": Color(0.95, 0.3, 0.3)},
	"bat": {"hp": 1, "speed": 2.6, "radius": 0.3, "shells": [1, 2], "color": Color(0.55, 0.35, 0.8)},
	"boss": {"hp": 12, "speed": 1.4, "radius": 0.95, "shells": [10, 15], "color": Color(0.5, 0.95, 0.6)},
}
const CRIES := {
	"slime": ["Blob !", "Gloubi !", "Splotch !"],
	"champi": ["Grmbl !", "Dégage !", "Mes spores !"],
	"bat": ["Kiii !", "Crouic !", "Zzz... hein ?!"],
	"boss": ["JE SUIS LE ROI !", "GLOUBI GLOUBA !", "Tu vas finir en gelée !"],
}

var type := "slime"
var hp := 2
var radius := 0.35
var speed := 1.5
var home := Vector3.ZERO
var player
var dungeon
var dead := false

var body: Node3D
var wing_l: Node3D
var wing_r: Node3D
var _t := 0.0
var _vy := 0.0
var _attack_cd := 0.0
var _hit_cd := 0.0
var _knock := Vector3.ZERO
var _cry_cd := 0.0
var _split_done := false


func setup(p_type: String, p_player, p_dungeon) -> void:
	type = p_type
	player = p_player
	dungeon = p_dungeon
	home = global_position
	var st: Dictionary = STATS[type]
	hp = st["hp"]
	radius = st["radius"]
	speed = st["speed"]
	add_to_group("monster")
	collision_layer = 32
	collision_mask = 1 | 32
	floor_snap_length = 0.3
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = radius
	cs.shape = sh
	cs.position.y = 1.4 if type == "bat" else radius
	add_child(cs)
	body = Node3D.new()
	add_child(body)
	_build(st["color"])
	_t = randf() * 10.0
	_cry_cd = randf_range(2.0, 6.0)


func _build(col: Color) -> void:
	var b := Builder.new()
	var ink := Color(0.13, 0.08, 0.17)
	match type:
		"slime", "boss":
			var s := 2.7 if type == "boss" else 1.0
			b.sphere(0.35 * s, Vector3(0, 0.3 * s, 0), col, Vector3(1.0, 0.85, 1.0), Basis(), 16)
			b.sphere(0.08 * s, Vector3(-0.14, 0.5, -0.2) * s, Color(1, 1, 1), Vector3(1, 0.6, 0.5))
			for sx in [-1.0, 1.0]:
				b.sphere(0.05 * s, Vector3(sx * 0.1, 0.36, -0.3) * s, ink, Vector3(0.8, 1.3, 0.5))
				b.sphere(0.015 * s, Vector3(sx * 0.1 - 0.012, 0.39, -0.325) * s, Color.WHITE)
			b.sphere(0.05 * s, Vector3(0, 0.22, -0.31) * s, Color(0.4, 0.1, 0.2), Vector3(1.2, 0.6, 0.4))
			if type == "boss":
				var gold := Color(1.0, 0.82, 0.2)
				b.cylinder(0.3, 0.3, 0.18, Vector3(0, 1.55, 0), gold, Basis(), 14)
				for k in 5:
					var a := k * TAU / 5.0
					b.spike(0.07, 0.2, Vector3(cos(a) * 0.26, 1.74, sin(a) * 0.26), Vector3.UP, gold)
				for sx in [-1.0, 1.0]:
					b.box(Vector3(0.22, 0.05, 0.04), Vector3(sx * 0.27, 1.22, -0.8), ink, false, Basis(Vector3.FORWARD, sx * 0.35))
		"champi":
			b.cylinder(0.14, 0.17, 0.35, Vector3(0, 0.25, 0), Color(1.0, 0.95, 0.85), Basis(), 12)
			b.sphere(0.33, Vector3(0, 0.5, 0), col, Vector3(1.0, 0.6, 1.0), Basis(), 16)
			for k in 6:
				var a := k * TAU / 6.0
				b.sphere(0.055, Vector3(cos(a) * 0.22, 0.6, sin(a) * 0.22), Color.WHITE, Vector3(1, 0.5, 1))
			b.sphere(0.06, Vector3(0, 0.72, 0), Color.WHITE, Vector3(1, 0.5, 1))
			for sx in [-1.0, 1.0]:
				b.sphere(0.035, Vector3(sx * 0.06, 0.3, -0.15), ink, Vector3(0.8, 1.2, 0.5))
				b.box(Vector3(0.07, 0.015, 0.02), Vector3(sx * 0.065, 0.36, -0.155), ink, false, Basis(Vector3.FORWARD, sx * 0.5))
				b.sphere(0.06, Vector3(sx * 0.08, 0.04, -0.02), Color(0.5, 0.3, 0.2), Vector3(1, 0.6, 1.3))
			b.box(Vector3(0.06, 0.012, 0.02), Vector3(0, 0.22, -0.16), ink, false)
		"bat":
			b.sphere(0.2, Vector3.ZERO, col, Vector3(1.0, 0.95, 0.9))
			for sx in [-1.0, 1.0]:
				b.prism(Vector3(0.08, 0.12, 0.03), Vector3(sx * 0.1, 0.2, 0), col, Basis(Vector3.FORWARD, -sx * 0.3))
				b.sphere(0.05, Vector3(sx * 0.07, 0.04, -0.17), Color(1, 0.9, 0.3), Vector3(1, 1, 0.5))
				b.sphere(0.022, Vector3(sx * 0.07, 0.04, -0.2), ink)
				b.spike(0.012, 0.04, Vector3(sx * 0.03, -0.08, -0.17), Vector3.DOWN, Color.WHITE)
	b.build(body, Toon.vertex_color(0.012 * (2.0 if type == "boss" else 1.0)), "MonsterMesh")
	if type == "bat":
		body.position.y = 1.4
		wing_l = _wing(-1.0, col)
		wing_r = _wing(1.0, col)


func _wing(sx: float, col: Color) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(sx * 0.15, 0.02, 0)
	body.add_child(pivot)
	var b := Builder.new()
	for k in 3:
		b.prism(Vector3(0.18, 0.2, 0.02), Vector3(sx * (0.1 + k * 0.1), -0.03 - k * 0.02, 0), col.darkened(0.15), Basis(Vector3.RIGHT, PI / 2.0) * Basis(Vector3.FORWARD, PI))
	b.build(pivot, Toon.vertex_color(0.008), "Wing")
	return pivot


## Centre du monstre (pour savoir si l'épée le touche).
func center() -> Vector3:
	return global_position + Vector3(0, 1.4 if type == "bat" else radius, 0)


func hit(dmg: int, from: Vector3) -> void:
	if dead or _hit_cd > 0.0:
		return
	_hit_cd = 0.35
	hp -= dmg
	var away := global_position - from
	away.y = 0.0
	_knock = away.normalized() * (2.0 if type == "boss" else 5.0)
	_vy = 2.5 if type != "boss" else 1.0
	body.scale = Vector3(1.3, 0.7, 1.3)
	Fx.text(get_parent(), global_position + Vector3(0, radius * 2.0 + 0.5, 0), ["PAF !", "BAM !", "SHLAK !", "POW !"][randi() % 4], Color(1.0, 0.9, 0.3), 0.9 if type != "boss" else 1.4, 0.6)
	if hp <= 0:
		_die()
	elif type == "boss" and not _split_done and hp <= 6:
		_split_done = true
		Fx.text(get_parent(), global_position + Vector3(0, 3.0, 0), "GLOUBI SE DIVISE !", Color(0.6, 1.0, 0.6), 1.2, 1.5)
		if dungeon:
			dungeon.spawn_monster("slime", global_position + Vector3(1.4, 0.3, 0))
			dungeon.spawn_monster("slime", global_position + Vector3(-1.4, 0.3, 0))


func _die() -> void:
	dead = true
	var st: Dictionary = STATS[type]
	var gain := randi_range(st["shells"][0], st["shells"][1])
	Save.shells += gain
	Save.dungeon["kills"] = int(Save.dungeon["kills"]) + 1
	Fx.puff(get_parent(), global_position + Vector3(0, radius, 0), Color(1, 1, 1))
	Fx.text(get_parent(), global_position + Vector3(0, radius * 2.0 + 0.3, 0), "K.O. !  +%d coquillage%s" % [gain, "s" if gain > 1 else ""], Color(1.0, 0.75, 0.85), 0.8 if type != "boss" else 1.6, 1.2)
	if type == "boss":
		Save.dungeon["boss_kills"] = int(Save.dungeon["boss_kills"]) + 1
		Fx.text(get_parent(), global_position + Vector3(0, 3.5, 0), "VICTOIRE !", Color(1.0, 0.85, 0.2), 2.5, 2.5)
		if dungeon:
			dungeon.on_boss_dead()
	Save.save_game()
	queue_free()


func _physics_process(delta: float) -> void:
	if dead or player == null or not player.in_dungeon:
		return
	_t += delta
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	_hit_cd = maxf(_hit_cd - delta, 0.0)
	body.scale = body.scale.lerp(Vector3.ONE, clampf(delta * 8.0, 0.0, 1.0))

	var to: Vector3 = player.global_position - global_position
	var flat := Vector3(to.x, 0, to.z)
	var dist := flat.length()
	var chase := dist < (12.0 if type == "boss" else 8.0) and absf(to.y) < 3.0
	var dir := Vector3.ZERO
	if chase:
		dir = flat.normalized()
	elif Vector3(home.x - global_position.x, 0, home.z - global_position.z).length() > 1.0:
		dir = Vector3(home.x - global_position.x, 0, home.z - global_position.z).normalized() * 0.5

	var spd := speed
	match type:
		"slime", "boss":
			# Avance par petits bonds
			if is_on_floor():
				if chase and fmod(_t, 1.1 if type == "boss" else 0.8) < delta:
					_vy = 3.5 if type == "boss" else 3.0
					body.scale = Vector3(1.25, 0.75, 1.25)
				spd = speed * 0.2
			else:
				body.scale = body.scale.lerp(Vector3(0.9, 1.15, 0.9), clampf(delta * 6.0, 0.0, 1.0))
		"bat":
			wing_l.rotation.z = sin(_t * 18.0) * 0.7
			wing_r.rotation.z = -sin(_t * 18.0) * 0.7
			body.position.y = 1.4 + sin(_t * 3.0) * 0.2
			dir += Vector3(-dir.z, 0, dir.x) * sin(_t * 2.0) * 0.6
		"champi":
			body.rotation.z = sin(_t * 9.0) * 0.12 * dir.length()

	if type == "bat":
		_vy = 0.0
	elif is_on_floor():
		_vy = maxf(_vy, -0.5)
	else:
		_vy -= 9.8 * delta
	velocity = dir * spd + _knock
	velocity.y = _vy
	move_and_slide()
	_vy = velocity.y
	_knock = _knock.lerp(Vector3.ZERO, clampf(delta * 6.0, 0.0, 1.0))
	if flat.length() > 0.1 and chase:
		var yaw := atan2(-flat.x, -flat.z)
		body.rotation.y = lerp_angle(body.rotation.y, yaw, clampf(delta * 8.0, 0.0, 1.0))

	# Attaque au contact
	var reach := radius + 0.45
	var dy: float = to.y - (1.2 if type == "bat" else 0.0)
	if dist < reach and absf(dy) < 1.4 and _attack_cd <= 0.0:
		_attack_cd = 1.2
		player.hurt(1, global_position)

	_cry_cd -= delta
	if chase and _cry_cd <= 0.0:
		_cry_cd = randf_range(4.0, 8.0)
		var cries: Array = CRIES[type]
		Fx.text(get_parent(), global_position + Vector3(0, radius * 2.0 + (1.6 if type == "bat" else 0.4), 0), cries[randi() % cries.size()], Color(1, 1, 1), 0.55 if type != "boss" else 1.2, 1.0)
