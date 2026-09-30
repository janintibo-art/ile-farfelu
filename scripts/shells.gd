extends Node3D
## Les coquillages (la monnaie de l'île) éparpillés sur les plages.
## On les ramasse en marchant dessus. Ils repoussent au bout de 2 minutes.
## Tous dessinés en une seule fois (MultiMesh) pour le Quest 2.

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Island := preload("res://scripts/island.gd")
const Fx := preload("res://scripts/fx.gd")
const Save := preload("res://scripts/save.gd")

const COUNT := 45
const RESPAWN := 120.0

var player: Node3D
var _mm: MultiMesh
var _pos: Array[Vector3] = []
var _timer: Array[float] = []   # 0 = présent, > 0 = temps avant réapparition
var _t := 0.0


func build(p_player: Node3D) -> void:
	player = p_player
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var tries := 0
	while _pos.size() < COUNT and tries < 4000:
		tries += 1
		var a := rng.randf() * TAU
		var r := rng.randf_range(30.0, 68.0)
		var x := cos(a) * r
		var z := sin(a) * r
		var h := Island.height(x, z)
		if h < 0.08 or h > 0.9:
			continue
		_pos.append(Vector3(x, h + 0.05, z))
		_timer.append(0.0)

	var b := Builder.new()
	var pink := Color(1.0, 0.72, 0.75)
	b.sphere(0.13, Vector3(0, 0.03, 0), pink, Vector3(1.0, 0.35, 1.1))
	for k in 5:
		var a := -0.8 + k * 0.4
		b.box(Vector3(0.02, 0.03, 0.14), Vector3(sin(a) * 0.05, 0.065, cos(a) * 0.05 - 0.02), Color(1.0, 0.92, 0.9), false, Basis(Vector3.UP, a))
	b.sphere(0.05, Vector3(0, 0.03, 0.12), pink.darkened(0.1), Vector3(1.2, 0.6, 0.8))

	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.mesh = b.commit()
	_mm.instance_count = _pos.size()
	for i in _pos.size():
		_mm.set_instance_transform(i, _xf(i, true))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "ShellMesh"
	mmi.multimesh = _mm
	mmi.material_override = Toon.vertex_color(0.012)
	add_child(mmi)


func _xf(i: int, visible_now: bool) -> Transform3D:
	if not visible_now:
		return Transform3D(Basis().scaled(Vector3.ONE * 0.001), _pos[i] - Vector3(0, 5, 0))
	var rot := Basis(Vector3.UP, i * 1.7)
	return Transform3D(rot.scaled(Vector3.ONE * 1.4), _pos[i])


func _physics_process(delta: float) -> void:
	if player == null or _mm == null:
		return
	_t += delta
	var pp := player.global_position
	for i in _pos.size():
		if _timer[i] > 0.0:
			_timer[i] -= delta
			if _timer[i] <= 0.0:
				_timer[i] = 0.0
				_mm.set_instance_transform(i, _xf(i, true))
			continue
		var d := _pos[i] - pp
		if absf(d.y) < 1.6 and Vector2(d.x, d.z).length() < 0.9:
			_timer[i] = RESPAWN
			_mm.set_instance_transform(i, _xf(i, false))
			Save.shells += 1
			Save.save_game()
			Fx.text(get_parent(), _pos[i] + Vector3(0, 0.9, 0), "+1 coquillage", Color(1.0, 0.75, 0.8), 0.5, 0.7)
			if player.has_method("on_shell"):
				player.on_shell()
