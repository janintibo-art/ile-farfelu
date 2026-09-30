extends RefCounted
## Objets à attraper : ballon de plage, noix de coco, onigiris, et un poulet
## en caoutchouc (indispensable).

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Grabbable := preload("res://scripts/grabbable.gd")
const Island := preload("res://scripts/island.gd")

const INK := Color(0.13, 0.08, 0.17)


static func spawn_all(world: Node3D, house: Node3D, palms: Array) -> void:
	var s := Island.SPAWN
	make(world, "ball", Island.ground(s.x + 2.5, s.y - 2.0) + Vector3(0, 0.5, 0))
	var n := 0
	for p in palms:
		if n >= 7:
			break
		var q: Vector3 = p
		make(world, "coconut", Island.ground(q.x + 0.7, q.z + 0.4) + Vector3(0, 0.3, 0))
		n += 1
	for k in 3:
		make(world, "onigiri", house.to_global(Vector3(-2.85 + k * 0.25, 0.9, -1.6 + (k % 2) * 0.15)))
	make(world, "chicken", house.to_global(Vector3(-2.55, 0.62, 1.2)))
	make(world, "chicken", Island.ground(s.x - 2.0, s.y - 1.0) + Vector3(0, 0.4, 0))


static func make(world: Node3D, kind: String, pos: Vector3) -> RigidBody3D:
	var rb := Grabbable.new()
	rb.name = kind.capitalize()
	rb.kind = kind
	rb.home = pos
	var b := Builder.new()
	var shape: Shape3D
	match kind:
		"ball":
			var cols := [Color(1, 0.3, 0.3), Color(1, 1, 1), Color(0.3, 0.55, 1.0), Color(1, 0.9, 0.2), Color(1, 1, 1), Color(0.4, 0.85, 0.4)]
			var m := SphereMesh.new()
			m.radius = 0.35
			m.height = 0.7
			m.radial_segments = 24
			m.rings = 12
			b.add_painted(m, Transform3D(), func(v: Vector3) -> Color:
				if absf(v.y) > 0.3:
					return Color(1, 1, 1)
				var sector := int(floor((atan2(v.z, v.x) + PI) / (TAU / 6.0))) % 6
				return cols[sector])
			var sh := SphereShape3D.new()
			sh.radius = 0.35
			shape = sh
			rb.radius = 0.35
			rb.mass = 0.3
			var pm := PhysicsMaterial.new()
			pm.bounce = 0.75
			pm.friction = 0.6
			rb.physics_material_override = pm
		"coconut":
			b.sphere(0.12, Vector3.ZERO, Color(0.45, 0.28, 0.14), Vector3(1.0, 1.1, 1.0))
			for k in 3:
				b.sphere(0.018, Vector3(-0.03 + k * 0.03, 0.1, -0.06 + (k % 2) * 0.02), Color(0.2, 0.12, 0.06), Vector3.ONE, Basis(), 6)
			var sh := SphereShape3D.new()
			sh.radius = 0.12
			shape = sh
			rb.radius = 0.12
			rb.mass = 0.6
		"onigiri":
			b.prism(Vector3(0.16, 0.15, 0.07), Vector3(0, 0.0, 0), Color(1, 1, 1))
			b.box(Vector3(0.09, 0.07, 0.075), Vector3(0, -0.04, 0), Color(0.12, 0.18, 0.14))
			b.sphere(0.012, Vector3(-0.03, 0.02, -0.036), INK, Vector3.ONE, Basis(), 6)
			b.sphere(0.012, Vector3(0.03, 0.02, -0.036), INK, Vector3.ONE, Basis(), 6)
			var sh := BoxShape3D.new()
			sh.size = Vector3(0.16, 0.15, 0.08)
			shape = sh
			rb.radius = 0.09
			rb.mass = 0.15
		"chicken":
			var y := Color(1.0, 0.85, 0.2)
			b.sphere(0.12, Vector3(0, 0, 0.02), y, Vector3(1.0, 0.8, 1.4))
			b.capsule(0.04, 0.2, Vector3(0, 0.1, -0.13), y, Basis(Vector3.RIGHT, 0.3))
			b.sphere(0.06, Vector3(0, 0.2, -0.17), y)
			b.prism(Vector3(0.05, 0.06, 0.03), Vector3(0, 0.27, -0.17), Color(0.95, 0.2, 0.2))
			b.cylinder(0.0, 0.025, 0.06, Vector3(0, 0.19, -0.24), Color(1.0, 0.5, 0.1), Basis(Vector3.RIGHT, -PI / 2.0), 6)
			for sx in [-1.0, 1.0]:
				b.sphere(0.012, Vector3(sx * 0.03, 0.22, -0.215), INK, Vector3.ONE, Basis(), 6)
			var sh := BoxShape3D.new()
			sh.size = Vector3(0.2, 0.2, 0.34)
			shape = sh
			rb.radius = 0.14
			rb.mass = 0.2
			rb.grab_text = "COUIC !"
			var pm := PhysicsMaterial.new()
			pm.bounce = 0.5
			rb.physics_material_override = pm
	b.build(rb, Toon.vertex_color(0.008), "Mesh")
	var cs := CollisionShape3D.new()
	cs.shape = shape
	rb.add_child(cs)
	world.add_child(rb)
	rb.global_position = pos
	return rb
