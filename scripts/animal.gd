extends Node3D
## Un animal rigolo de l'île (v34) : se promène, fuit ou vient voir le joueur,
## fait son cri, saute de joie quand on lui parle. Le dessin est fait ailleurs (friends.gd).

const Island := preload("res://scripts/island.gd")
const Fx := preload("res://scripts/fx.gd")
const Bells := preload("res://scripts/bells.gd")

var kind := ""
var voice := ""              # son du cri (voir bells.gd)
var voice_pitch := 1.0
var home := Vector3.ZERO
var radius := 3.0
var speed := 1.0
var flee := 0.0              # distance à laquelle il s'enfuit
var curious := false         # vient voir le joueur (et donne des coups de tête !)
var follows := false         # suit le joueur
var sleeping := false
var sidestep := false        # marche de côté (crabe)
var hopper := false          # avance par petits bonds (grenouille)
var min_h := 0.7
var max_h := 99.0
var avoid: Array = []        # [Vector3(x, z, rayon)] zones à éviter
var player: Node3D
var world: Node3D
var body: Node3D
var talk_color := Color(1.0, 0.95, 0.6)
var y_off := 0.0

var _target := Vector2.ZERO
var _has_target := false
var _wait := 0.5
var _t := 0.0
var _hop := 0.0
var _hop_v := 0.0
var _moving := false
var _bump_t := 0.0
var _zzz := 2.0
var _cry_cd := 0.0
var _yaw := 0.0
var _flying := 0.0           # mouette : temps de vol restant
var _fly_from := Vector3.ZERO
var _fly_to := Vector3.ZERO
var _fly_total := 1.0


func _ready() -> void:
	_t = randf() * 10.0
	_yaw = rotation.y
	_snap()


func _snap() -> void:
	global_position.y = Island.height(global_position.x, global_position.z) + _hop + y_off


func _free_spot(p: Vector2) -> bool:
	var h := Island.height(p.x, p.y)
	if h < min_h or h > max_h:
		return false
	for a in avoid:
		if p.distance_to(Vector2(a.x, a.y)) < a.z:
			return false
	return true


func _pick_target() -> void:
	for k in 8:
		var a := randf() * TAU
		var d := randf_range(0.5, 1.0) * radius
		var p := Vector2(home.x + cos(a) * d, home.z + sin(a) * d)
		if sidestep:
			p = Vector2(home.x + randf_range(-1.0, 1.0) * radius, global_position.z)
		if _free_spot(p):
			_target = p
			_has_target = true
			return
	_has_target = false


## Réaction : petit saut + cri
func react(text := "", sound := true) -> void:
	_hop_v = 3.2
	if sound:
		cry()
	if text != "":
		Fx.text(world, global_position + Vector3(0, 1.1, 0), text, talk_color, 0.9, 1.6)


func cry(vol := -2.0) -> void:
	if voice == "" or _cry_cd > 0.0:
		return
	_cry_cd = 0.5
	var p := Bells.play(world, voice, 0.0, global_position + Vector3(0, 0.4, 0), vol)
	p.pitch_scale = voice_pitch * randf_range(0.92, 1.1)


## S'envoler et se poser ailleurs (mouette)
func fly_to(dest: Vector3, secs := 1.6) -> void:
	_fly_from = global_position
	_fly_to = dest
	_fly_total = secs
	_flying = secs


func _process(delta: float) -> void:
	if player == null or world == null:
		return
	var pp := player.global_position
	if pp.y > 60.0 or absf(pp.x - global_position.x) > 70.0 or absf(pp.z - global_position.z) > 70.0:
		return
	_t += delta
	_cry_cd -= delta
	var me := global_position
	var to_p := Vector2(pp.x - me.x, pp.z - me.z)
	var dist := to_p.length()

	# Petit saut (gravité simplifiée)
	if _hop > 0.0 or _hop_v > 0.0:
		_hop_v -= 11.0 * delta
		_hop = maxf(_hop + _hop_v * delta, 0.0)
		if _hop == 0.0 and _hop_v < 0.0:
			_hop_v = 0.0

	if _flying > 0.0:
		_flying -= delta
		var u := 1.0 - maxf(_flying, 0.0) / _fly_total
		var pos := _fly_from.lerp(_fly_to, u)
		pos.y += sin(u * PI) * 5.0
		global_position = pos
		var d := _fly_to - _fly_from
		_yaw = atan2(-d.x, -d.z)
		rotation.y = lerp_angle(rotation.y, _yaw, clampf(delta * 8.0, 0.0, 1.0))
		if body:
			body.rotation.z = sin(_t * 18.0) * 0.25
		if _flying <= 0.0:
			home = Vector3(_fly_to.x, 0, _fly_to.z)
			if body:
				body.rotation.z = 0.0
		return

	if sleeping:
		_zzz -= delta
		if _zzz <= 0.0 and dist < 12.0:
			_zzz = 3.5
			Fx.text(world, me + Vector3(0.1, 0.8, 0), "Zzz", Color(0.8, 0.85, 1.0), 0.8, 2.0)
		_snap()
		return

	var dir := Vector2.ZERO
	var spd := speed
	if flee > 0.0 and dist < flee:
		dir = -to_p.normalized()
		spd = speed * 2.6
		_has_target = false
		_wait = 0.4
	elif curious and dist < 11.0 and dist > 1.3:
		dir = to_p.normalized()
		spd = speed * 1.9
		_has_target = false
	elif follows and dist < 9.0 and dist > 2.0:
		dir = to_p.normalized()
		spd = speed * 1.6
		_has_target = false
	else:
		if _wait > 0.0:
			_wait -= delta
		elif not _has_target:
			_pick_target()
			if not _has_target:
				_wait = 2.0
		else:
			var dt := _target - Vector2(me.x, me.z)
			if dt.length() < 0.15:
				_has_target = false
				_wait = randf_range(1.0, 4.0)
			else:
				dir = dt.normalized()

	# Coup de tête (chèvre) quand on reste collé à elle
	if curious and dist < 1.4:
		_bump_t += delta
		if _bump_t > 1.1:
			_bump_t = 0.0
			if "_knock" in player:
				var kd := to_p.normalized()
				player._knock += Vector3(kd.x, 0.0, kd.y) * 7.0
			react("BÊÊÊ !")
	else:
		_bump_t = 0.0

	_moving = dir != Vector2.ZERO
	if _moving:
		var step := dir * spd * delta
		var np := Vector2(me.x, me.z) + step
		if _free_spot(np):
			global_position.x = np.x
			global_position.z = np.y
		else:
			_has_target = false
			_wait = 0.3
		if not sidestep:
			_yaw = atan2(-dir.x, -dir.y)
		else:
			_yaw = atan2(-to_p.x, -to_p.y) if dist < 12.0 else _yaw
	elif dist < 7.0 and not sidestep:
		_yaw = atan2(-to_p.x, -to_p.y)
	rotation.y = lerp_angle(rotation.y, _yaw, clampf(delta * 7.0, 0.0, 1.0))

	# Rebond de marche
	if body:
		if _moving:
			if hopper:
				body.position.y = absf(sin(_t * 7.0)) * 0.16
			else:
				body.position.y = absf(sin(_t * 9.0 * (0.6 + spd * 0.4))) * 0.05
				body.rotation.z = sin(_t * 9.0 * (0.6 + spd * 0.4)) * 0.08
		else:
			body.position.y = lerpf(body.position.y, 0.0, clampf(delta * 10.0, 0.0, 1.0))
			body.rotation.z = lerpf(body.rotation.z, 0.0, clampf(delta * 10.0, 0.0, 1.0))
	_snap()
