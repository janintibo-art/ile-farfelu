extends RefCounted
## Objets à attraper : ballon de plage, noix de coco, onigiris, poulet en
## caoutchouc, et tout ce qu'on achète à la boutique.

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Grabbable := preload("res://scripts/grabbable.gd")
const Island := preload("res://scripts/island.gd")

const INK := Color(0.13, 0.08, 0.17)
const FOODS := ["glace", "ramen", "bonbon"]


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


## Dessine l'objet dans un Builder (sert aussi pour les étagères du magasin).
static func paint(b: Builder, kind: String, xf := Transform3D()) -> void:
	var o := xf.origin
	var bs := xf.basis
	match kind:
		"ball":
			var cols := [Color(1, 0.3, 0.3), Color(1, 1, 1), Color(0.3, 0.55, 1.0), Color(1, 0.9, 0.2), Color(1, 1, 1), Color(0.4, 0.85, 0.4)]
			var m := SphereMesh.new()
			m.radius = 0.35
			m.height = 0.7
			m.radial_segments = 24
			m.rings = 12
			b.add_painted(m, xf, func(v: Vector3) -> Color:
				if absf(v.y) > 0.3:
					return Color(1, 1, 1)
				var sector := int(floor((atan2(v.z, v.x) + PI) / (TAU / 6.0))) % 6
				return cols[sector])
		"coconut":
			b.sphere(0.12, o, Color(0.45, 0.28, 0.14), Vector3(1.0, 1.1, 1.0), bs)
			for k in 3:
				b.sphere(0.018, o + bs * Vector3(-0.03 + k * 0.03, 0.1, -0.06 + (k % 2) * 0.02), Color(0.2, 0.12, 0.06), Vector3.ONE, bs, 6)
		"onigiri":
			b.prism(Vector3(0.16, 0.15, 0.07), o, Color(1, 1, 1), bs)
			b.box(Vector3(0.09, 0.07, 0.075), o + bs * Vector3(0, -0.04, 0), Color(0.12, 0.18, 0.14), false, bs)
			b.sphere(0.012, o + bs * Vector3(-0.03, 0.02, -0.036), INK, Vector3.ONE, bs, 6)
			b.sphere(0.012, o + bs * Vector3(0.03, 0.02, -0.036), INK, Vector3.ONE, bs, 6)
		"chicken":
			var y := Color(1.0, 0.85, 0.2)
			b.sphere(0.12, o + bs * Vector3(0, 0, 0.02), y, Vector3(1.0, 0.8, 1.4), bs)
			b.capsule(0.04, 0.2, o + bs * Vector3(0, 0.1, -0.13), y, bs * Basis(Vector3.RIGHT, 0.3))
			b.sphere(0.06, o + bs * Vector3(0, 0.2, -0.17), y, Vector3.ONE, bs)
			b.prism(Vector3(0.05, 0.06, 0.03), o + bs * Vector3(0, 0.27, -0.17), Color(0.95, 0.2, 0.2), bs)
			b.cylinder(0.0, 0.025, 0.06, o + bs * Vector3(0, 0.19, -0.24), Color(1.0, 0.5, 0.1), bs * Basis(Vector3.RIGHT, -PI / 2.0), 6)
			for sx in [-1.0, 1.0]:
				b.sphere(0.012, o + bs * Vector3(sx * 0.03, 0.22, -0.215), INK, Vector3.ONE, bs, 6)
		"canard":
			var y := Color(1.0, 0.85, 0.15)
			b.sphere(0.1, o, y, Vector3(1.0, 0.75, 1.3), bs)
			b.sphere(0.065, o + bs * Vector3(0, 0.1, -0.08), y, Vector3.ONE, bs)
			b.sphere(0.04, o + bs * Vector3(0, 0.09, -0.15), Color(1.0, 0.5, 0.1), Vector3(1.0, 0.4, 1.0), bs, 8)
			for sx in [-1.0, 1.0]:
				b.sphere(0.012, o + bs * Vector3(sx * 0.03, 0.13, -0.13), INK, Vector3.ONE, bs, 6)
		"glace":
			b.cylinder(0.055, 0.0, 0.16, o + bs * Vector3(0, -0.06, 0), Color(0.85, 0.6, 0.3), bs, 10)
			b.sphere(0.06, o + bs * Vector3(0, 0.04, 0), Color(1.0, 0.6, 0.75), Vector3.ONE, bs, 10)
			b.sphere(0.055, o + bs * Vector3(0, 0.11, 0), Color(0.6, 0.85, 1.0), Vector3.ONE, bs, 10)
			b.sphere(0.05, o + bs * Vector3(0, 0.17, 0), Color(0.7, 1.0, 0.6), Vector3.ONE, bs, 10)
			b.sphere(0.018, o + bs * Vector3(0, 0.225, 0), Color(0.95, 0.15, 0.25), Vector3.ONE, bs, 6)
		"ramen":
			b.cylinder(0.12, 0.07, 0.09, o, Color(0.95, 0.3, 0.3), bs, 14)
			b.cylinder(0.11, 0.11, 0.01, o + bs * Vector3(0, 0.04, 0), Color(1.0, 0.85, 0.5), bs, 14)
			b.sphere(0.03, o + bs * Vector3(0.04, 0.05, 0.02), Color.WHITE, Vector3(1, 0.5, 1.3), bs, 8)
			b.sphere(0.015, o + bs * Vector3(0.04, 0.06, 0.02), Color(1.0, 0.75, 0.1), Vector3(1, 0.5, 1), bs, 6)
			b.box(Vector3(0.07, 0.07, 0.005), o + bs * Vector3(-0.05, 0.06, 0.05), Color(0.12, 0.2, 0.12), false, bs * Basis(Vector3.RIGHT, -0.4))
			b.box(Vector3(0.012, 0.012, 0.3), o + bs * Vector3(0.02, 0.07, -0.02), Color(0.8, 0.6, 0.35), false, bs * Basis(Vector3.UP, 0.4))
		"bonbon":
			b.sphere(0.07, o, Color(1.0, 0.5, 0.8), Vector3.ONE, bs, 12)
			b.torus(0.05, 0.072, o, Color.WHITE, bs * Basis(Vector3.FORWARD, 0.5))
			for sx in [-1.0, 1.0]:
				b.prism(Vector3(0.08, 0.06, 0.03), o + bs * Vector3(sx * 0.095, 0, 0), Color(1.0, 0.85, 0.3), bs * Basis(Vector3.FORWARD, sx * PI / 2.0))


static func make(world: Node3D, kind: String, pos: Vector3) -> RigidBody3D:
	var rb := Grabbable.new()
	rb.name = kind.capitalize()
	rb.kind = kind
	rb.home = pos
	rb.is_food = kind in FOODS
	var b := Builder.new()
	paint(b, kind)
	var shape: Shape3D
	match kind:
		"ball":
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
			var sh := SphereShape3D.new()
			sh.radius = 0.12
			shape = sh
			rb.radius = 0.12
			rb.mass = 0.6
		"onigiri":
			var sh := BoxShape3D.new()
			sh.size = Vector3(0.16, 0.15, 0.08)
			shape = sh
			rb.radius = 0.09
			rb.mass = 0.15
		"chicken":
			var sh := BoxShape3D.new()
			sh.size = Vector3(0.2, 0.2, 0.34)
			shape = sh
			rb.radius = 0.14
			rb.mass = 0.2
			rb.grab_text = "COUIC !"
			var pm := PhysicsMaterial.new()
			pm.bounce = 0.5
			rb.physics_material_override = pm
		"canard":
			var sh := SphereShape3D.new()
			sh.radius = 0.11
			shape = sh
			rb.radius = 0.11
			rb.mass = 0.1
			rb.grab_text = "COIN !"
		"glace":
			var sh := BoxShape3D.new()
			sh.size = Vector3(0.12, 0.3, 0.12)
			shape = sh
			rb.radius = 0.1
			rb.mass = 0.1
		"ramen":
			var sh := CylinderShape3D.new()
			sh.radius = 0.12
			sh.height = 0.1
			shape = sh
			rb.radius = 0.12
			rb.mass = 0.3
		_:
			var sh := SphereShape3D.new()
			sh.radius = 0.08
			shape = sh
			rb.radius = 0.08
			rb.mass = 0.05
	b.build(rb, Toon.vertex_color(0.008), "Mesh")
	var cs := CollisionShape3D.new()
	cs.shape = shape
	rb.add_child(cs)
	world.add_child(rb)
	rb.global_position = pos
	return rb
