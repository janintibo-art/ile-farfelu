extends Node3D
## Un perso chibi (grosse tête, petit corps) construit en formes simples,
## avec contour noir, grands yeux anime, clignements, marche et bulle de
## dialogue. Regarde vers -Z.

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")

const HEAD_C := Vector3(0.0, 0.29, 0.0)   # centre de la tête, relatif au cou
const OUTLINE := 0.011

var def: Dictionary = {}
var walk := 0.0      # 0 = immobile, 1 = marche franche (réglé par le propriétaire)
var panic := false   # affiche la goutte de sueur

var body_root: Node3D
var head: Node3D
var eyes: Node3D
var arm_l: Node3D
var arm_r: Node3D
var leg_l: Node3D
var leg_r: Node3D
var sweat: Node3D
var ring: MeshInstance3D
var bubble: Label3D

var _phase := 0.0
var _t := 0.0
var _blink := 2.0
var _bubble_left := 0.0


func setup(d: Dictionary) -> void:
	def = d
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func say(txt: String, duration := 3.5) -> void:
	if bubble == null:
		return
	bubble.text = txt
	bubble.visible = true
	_bubble_left = duration


func set_targeted(on: bool) -> void:
	if ring:
		ring.visible = on


func pop() -> void:
	scale = Vector3(1.3, 0.7, 1.3)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ONE, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


# ---------------------------------------------------------------------------

func _build() -> void:
	var mat := Toon.vertex_color(OUTLINE)
	body_root = Node3D.new()
	body_root.name = "Body"
	add_child(body_root)

	# Jambes
	leg_l = _leg(-0.09, mat)
	leg_r = _leg(0.09, mat)

	# Torse (+ jupe, queue ou poche selon le perso)
	var tb := Builder.new()
	tb.capsule(0.17, 0.44, Vector3(0, 0.56, 0), def["shirt"], Basis(), Vector3(1.0, 1.0, 0.85))
	tb.cylinder(0.05, 0.06, 0.08, Vector3(0, 0.74, 0), def["skin"])
	match def["hair_style"]:
		"buns":
			tb.cylinder(0.15, 0.27, 0.22, Vector3(0, 0.44, 0), def["shirt"].darkened(0.08))
			tb.capsule(0.035, 0.28, Vector3(0, 0.46, 0.2), def["hair"], Basis(Vector3.RIGHT, 0.9))
			tb.capsule(0.035, 0.22, Vector3(0, 0.62, 0.3), def["hair"], Basis(Vector3.RIGHT, -0.3))
			tb.sphere(0.045, Vector3(0, 0.74, 0.3), def["accent"])
		"messy":
			tb.box(Vector3(0.2, 0.09, 0.03), Vector3(0, 0.5, -0.155), def["shirt"].darkened(0.15), false)
			tb.sphere(0.13, Vector3(0, 0.73, 0.12), def["shirt"].darkened(0.1), Vector3(1.2, 0.7, 0.8))
		_:
			tb.cylinder(0.175, 0.175, 0.05, Vector3(0, 0.42, 0), Color(0.35, 0.22, 0.12))
			tb.box(Vector3(0.06, 0.05, 0.02), Vector3(0, 0.42, -0.155), Color(1.0, 0.85, 0.2), false)
	tb.build(body_root, mat, "Torso")

	# Bras
	arm_l = _arm(-1.0, mat)
	arm_r = _arm(1.0, mat)

	# Tête
	head = Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 0.72, 0)
	body_root.add_child(head)
	var hb := Builder.new()
	hb.sphere(0.3, HEAD_C, def["skin"], Vector3(1.05, 1.0, 1.0), Basis(), 18)
	_face(hb)
	_hair(hb)
	hb.build(head, mat, "HeadMesh")

	# Yeux (à part, pour pouvoir cligner)
	eyes = Node3D.new()
	eyes.name = "Eyes"
	eyes.position = HEAD_C
	head.add_child(eyes)
	var eb := Builder.new()
	for sx in [-1.0, 1.0]:
		var c := Vector3(sx * 0.105, -0.02, 0.0)
		var tilt := Basis(Vector3.UP, -sx * 0.33)
		eb.sphere(1.0, c + Vector3(0, 0, -0.272), def["eye"], Vector3(0.078, 0.105, 0.035), tilt)
		eb.sphere(1.0, c + Vector3(0, -0.01, -0.288), Color(0.08, 0.05, 0.12), Vector3(0.042, 0.064, 0.022), tilt)
		eb.sphere(1.0, c + Vector3(sx * -0.022, 0.038, -0.302), Color.WHITE, Vector3(0.026, 0.03, 0.012), tilt, 8)
		eb.sphere(1.0, c + Vector3(sx * 0.024, -0.04, -0.3), Color.WHITE, Vector3(0.013, 0.015, 0.01), tilt, 8)
		eb.box(Vector3(0.16, 0.022, 0.03), c + Vector3(0, 0.098, -0.268), Color(0.13, 0.08, 0.17), false, Basis(Vector3.FORWARD, sx * 0.12) * tilt)
	eb.build(eyes, Toon.vertex_color(), "EyesMesh")

	# Goutte de sueur (panique dans l'eau)
	sweat = Node3D.new()
	sweat.position = HEAD_C + Vector3(0.31, 0.12, -0.08)
	sweat.visible = false
	head.add_child(sweat)
	var sb := Builder.new()
	sb.sphere(0.045, Vector3.ZERO, Color(0.6, 0.85, 1.0))
	sb.spike(0.042, 0.08, Vector3(0, 0.055, 0), Vector3.UP, Color(0.6, 0.85, 1.0))
	sb.build(sweat, Toon.vertex_color(0.006), "Sweat")

	# Anneau de sélection sous les pieds
	ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.38
	tm.outer_radius = 0.46
	ring.mesh = tm
	ring.material_override = Toon.unlit(Color(1.0, 0.9, 0.25))
	ring.position = Vector3(0, 0.03, 0)
	ring.scale = Vector3(1, 0.3, 1)
	ring.visible = false
	add_child(ring)

	# Bulle de dialogue
	bubble = Label3D.new()
	bubble.position = Vector3(0, 1.62, 0)
	bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bubble.font_size = 64
	bubble.outline_size = 20
	bubble.outline_modulate = Color(0.13, 0.08, 0.17)
	bubble.pixel_size = 0.0032
	bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.width = 520.0
	bubble.visible = false
	add_child(bubble)


func _leg(x: float, mat: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(x, 0.38, 0)
	body_root.add_child(pivot)
	var b := Builder.new()
	b.capsule(0.075, 0.34, Vector3(0, -0.16, 0), def["pants"])
	b.sphere(0.08, Vector3(0, -0.33, -0.03), def["shoes"], Vector3(1.0, 0.72, 1.4))
	b.build(pivot, mat, "Leg")
	return pivot


func _arm(sx: float, mat: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(sx * 0.2, 0.68, 0)
	pivot.rotation.z = sx * 0.28
	body_root.add_child(pivot)
	var b := Builder.new()
	b.capsule(0.055, 0.28, Vector3(0, -0.12, 0), def["shirt"])
	b.sphere(0.065, Vector3(0, -0.29, 0), def["skin"])
	b.build(pivot, mat, "Arm")
	return pivot


func _face(b: Builder) -> void:
	var c := HEAD_C
	var ink := Color(0.13, 0.08, 0.17)
	# Joues roses
	for sx in [-1.0, 1.0]:
		b.sphere(1.0, c + Vector3(sx * 0.17, -0.085, -0.228), Color(1.0, 0.58, 0.62), Vector3(0.055, 0.028, 0.02), Basis(Vector3.UP, -sx * 0.6), 8)
	# Grande bouche ouverte qui rigole
	b.sphere(1.0, c + Vector3(0, -0.145, -0.262), Color(0.55, 0.12, 0.18), Vector3(0.07, 0.042, 0.02), Basis(), 10)
	b.sphere(1.0, c + Vector3(0, -0.16, -0.27), Color(1.0, 0.5, 0.55), Vector3(0.04, 0.02, 0.012), Basis(), 8)
	# Sourcils
	for sx in [-1.0, 1.0]:
		b.box(Vector3(0.09, 0.018, 0.02), c + Vector3(sx * 0.105, 0.13, -0.262), def["hair"].darkened(0.35), false, Basis(Vector3.FORWARD, -sx * 0.18) * Basis(Vector3.UP, -sx * 0.33))
	if def["hair_style"] == "messy":
		# Grosses lunettes rondes
		for sx in [-1.0, 1.0]:
			b.torus(0.07, 0.086, c + Vector3(sx * 0.105, -0.02, -0.318), ink, Basis(Vector3.UP, -sx * 0.33) * Basis(Vector3.RIGHT, PI / 2.0))
			b.box(Vector3(0.012, 0.012, 0.2), c + Vector3(sx * 0.2, 0.0, -0.21), ink, false)
		b.box(Vector3(0.06, 0.012, 0.012), c + Vector3(0, -0.005, -0.325), ink, false)
	elif def["hair_style"] == "spiky":
		# Bandeau de ninja du dimanche
		b.torus(0.285, 0.325, c + Vector3(0, 0.13, 0.0), def["accent"], Basis(Vector3.RIGHT, -0.12) * Basis.from_scale(Vector3(1.05, 1.0, 1.0)))
		b.box(Vector3(0.05, 0.05, 0.05), c + Vector3(0, 0.12, 0.31), def["accent"].darkened(0.1), false)
		b.box(Vector3(0.045, 0.2, 0.012), c + Vector3(-0.05, 0.03, 0.34), def["accent"], false, Basis(Vector3.FORWARD, 0.4) * Basis(Vector3.RIGHT, 0.5))
		b.box(Vector3(0.045, 0.22, 0.012), c + Vector3(0.06, 0.02, 0.35), def["accent"], false, Basis(Vector3.FORWARD, -0.3) * Basis(Vector3.RIGHT, 0.6))


func _hair(b: Builder) -> void:
	var c := HEAD_C
	var col: Color = def["hair"]
	# Calotte qui couvre le haut et l'arrière du crâne
	b.sphere(0.315, c + Vector3(0, 0.06, 0.05), col, Vector3(1.06, 1.0, 1.0), Basis(), 16)
	# Mèches sur le front
	for x in [-0.16, -0.06, 0.05, 0.15]:
		b.sphere(1.0, c + Vector3(x, 0.19, -0.228), col, Vector3(0.075, 0.1, 0.045), Basis(Vector3.FORWARD, x * 1.5) * Basis(Vector3.RIGHT, -0.5), 8)
	match def["hair_style"]:
		"spiky":
			var dirs := [
				Vector3(0, 1, 0.25), Vector3(0.5, 0.9, 0.35), Vector3(-0.5, 0.9, 0.35),
				Vector3(0.85, 0.5, 0.45), Vector3(-0.85, 0.5, 0.45), Vector3(0.35, 0.55, 0.95),
				Vector3(-0.35, 0.55, 0.95), Vector3(0, 0.3, 1.0), Vector3(0.25, 1.0, -0.25),
				Vector3(-0.3, 0.95, -0.15), Vector3(0.6, 0.2, 0.8), Vector3(-0.6, 0.2, 0.8),
			]
			for d in dirs:
				var n: Vector3 = d.normalized()
				b.spike(0.1, 0.28, c + Vector3(0, 0.05, 0.05) + n * 0.29, n, col)
		"buns":
			for sx in [-1.0, 1.0]:
				b.sphere(0.12, c + Vector3(sx * 0.2, 0.28, 0.06), col)
				b.capsule(0.06, 0.36, c + Vector3(sx * 0.27, -0.1, 0.03), col, Basis(Vector3.FORWARD, sx * 0.12))
				# Oreilles de chat
				var ear := Basis(Vector3.FORWARD, -sx * 0.4)
				b.prism(Vector3(0.17, 0.2, 0.07), c + Vector3(sx * 0.14, 0.36, 0.0), col, ear)
				b.prism(Vector3(0.09, 0.11, 0.02), c + Vector3(sx * 0.14, 0.345, -0.035), Color(1.0, 0.75, 0.82), ear)
			b.sphere(0.05, c + Vector3(0.12, 0.3, -0.14), def["accent"])
		"messy":
			var bumps := [
				Vector3(0.18, 0.25, 0.1), Vector3(-0.2, 0.22, 0.12), Vector3(0.05, 0.33, 0.05),
				Vector3(-0.08, 0.3, -0.1), Vector3(0.25, 0.08, 0.15), Vector3(-0.26, 0.05, 0.14),
				Vector3(0.1, 0.18, 0.28), Vector3(-0.12, 0.15, 0.28), Vector3(0.0, 0.0, 0.33),
			]
			for p in bumps:
				b.sphere(0.11, c + p, col, Vector3.ONE, Basis(), 10)
			# Épi rebelle ("ahoge")
			b.spike(0.03, 0.2, c + Vector3(0.02, 0.44, 0.0), Vector3(0.3, 1.0, -0.2), col)
			b.spike(0.022, 0.14, c + Vector3(0.07, 0.55, -0.03), Vector3(1.0, 0.4, -0.1), col)


# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	if body_root == null:
		return
	_t += delta
	_phase += delta * (3.0 + 9.0 * walk)
	var s := sin(_phase)
	leg_l.rotation.x = s * 0.75 * walk
	leg_r.rotation.x = -s * 0.75 * walk
	arm_l.rotation.x = -s * 0.9 * walk
	arm_r.rotation.x = s * 0.9 * walk
	body_root.position.y = absf(s) * 0.06 * walk
	body_root.scale.y = 1.0 + sin(_t * 2.3) * 0.018 * (1.0 - walk)
	head.rotation.z = sin(_t * 1.3) * 0.07 * (1.0 - walk)
	head.rotation.x = sin(_t * 0.9) * 0.04

	# Clignement
	_blink -= delta
	if _blink < 0.0:
		eyes.scale.y = 0.1
		if _blink < -0.12:
			eyes.scale.y = 1.0
			_blink = randf_range(1.5, 4.5)

	sweat.visible = panic
	if panic:
		sweat.position.y = HEAD_C.y + 0.12 + absf(sin(_t * 6.0)) * 0.04

	if ring.visible:
		ring.rotation.y += delta * 2.5

	if _bubble_left > 0.0:
		_bubble_left -= delta
		if _bubble_left <= 0.0:
			bubble.visible = false
