extends RefCounted
## Décor de l'île : palmiers, rochers, fleurs, buissons, nuages, panneaux
## et un canard en plastique géant. Presque tout est fusionné en un seul
## maillage pour rester fluide sur le Quest 2.

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Island := preload("res://scripts/island.gd")
const Spinner := preload("res://scripts/spinner.gd")

const INK := Color(0.13, 0.08, 0.17)


static func palm_mesh() -> ArrayMesh:
	var b := Builder.new()
	var pos := Vector3.ZERO
	var tilt := 0.0
	for i in 7:
		var col := Color(0.62, 0.42, 0.25) if i % 2 == 0 else Color(0.52, 0.34, 0.2)
		var basis := Basis(Vector3.FORWARD, -tilt)
		var seg_h := 0.7
		b.cylinder(0.15 - i * 0.012, 0.17 - i * 0.012, seg_h, pos + basis.y * seg_h * 0.5, col, basis, 8)
		pos += basis.y * seg_h * 0.92
		tilt += 0.045
	var top := pos
	for k in 8:
		var a := k * TAU / 8.0 + 0.2
		var leaf_basis := Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, -0.3 - (k % 2) * 0.25)
		var dir := leaf_basis * Vector3(0, 0, -1)
		var col := Color(0.25, 0.7, 0.3) if k % 2 == 0 else Color(0.35, 0.82, 0.35)
		b.sphere(1.0, top + dir * 1.05 + Vector3(0, 0.05, 0), col, Vector3(0.32, 0.05, 1.2), leaf_basis, 8)
	for k in 3:
		var a := k * TAU / 3.0
		b.sphere(0.13, top + Vector3(cos(a) * 0.17, -0.18, sin(a) * 0.17), Color(0.45, 0.3, 0.15), Vector3.ONE, Basis(), 8)
	return b.commit()


## Construit tout le décor et renvoie la position des palmiers (pour poser
## des noix de coco au pied).
static func build(world: Node3D, player: Node3D) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var b := Builder.new()
	var pb := Builder.new()
	var palms: Array = []
	var palm := palm_mesh()
	var solid := StaticBody3D.new()
	solid.name = "DecorCollision"
	world.add_child(solid)

	# Palmiers : sur la plage et dans la prairie, pas sur la maison ni le chemin
	var tries := 0
	while palms.size() < 22 and tries < 600:
		tries += 1
		var x := rng.randf_range(-60.0, 60.0)
		var z := rng.randf_range(-60.0, 60.0)
		var h := Island.height(x, z)
		if h < 0.35 or h > 4.5 or Island.in_village(x, z, 8.0) or Island.is_path(x, z):
			continue
		var p2 := Vector2(x, z)
		if p2.distance_to(Island.HOUSE_POS) < 10.0 or p2.distance_to(Island.SPAWN) < 5.0 or p2.distance_to(Island.SHOP_POS) < 9.0:
			continue
		if Island._seg_dist(p2, Island.PATH_FORK, Island.shop_front()) < 2.5:
			continue
		if p2.distance_to(Island.pier_base()) < 11.0:
			continue
		if p2.distance_to(Island.GATE_POS) < 9.0 or Island._seg_dist(p2, Island.SPAWN, Island.gate_front()) < 2.5:
			continue
		if absf(x) < 3.0 and z > Island.HOUSE_POS.y and z < Island.SPAWN.y + 2.0:
			continue
		var ok := true
		for q in palms:
			if Vector2(q.x, q.z).distance_to(p2) < 5.5:
				ok = false
				break
		if not ok:
			continue
		var s := rng.randf_range(0.85, 1.25)
		var outward := atan2(z, -x)   # le tronc penche vers la mer
		var basis := Basis(Vector3.UP, outward + rng.randf_range(-0.6, 0.6)).scaled(Vector3.ONE * s)
		var base := Vector3(x, h - 0.1, z)
		pb.add_mesh(palm, Transform3D(basis, base))
		palms.append(base)
		var cs := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = 0.2 * s
		cyl.height = 3.5 * s
		cs.shape = cyl
		cs.position = base + Vector3(0, 1.75 * s, 0)
		solid.add_child(cs)

	# Rochers
	for k in 26:
		var x := rng.randf_range(-58.0, 58.0)
		var z := rng.randf_range(-58.0, 58.0)
		var h := Island.height(x, z)
		if h < -0.6 or Island.in_village(x, z, 8.0) or Vector2(x, z).distance_to(Island.HOUSE_POS) < 9.0 or Vector2(x, z).distance_to(Island.SPAWN) < 4.0 or Vector2(x, z).distance_to(Island.SHOP_POS) < 8.0 or Vector2(x, z).distance_to(Island.GATE_POS) < 8.0 or Vector2(x, z).distance_to(Island.pier_base()) < 10.0:
			continue
		var sc := Vector3(rng.randf_range(0.6, 1.8), rng.randf_range(0.4, 1.1), rng.randf_range(0.6, 1.8))
		var grey := Color(0.66, 0.62, 0.6).darkened(rng.randf_range(0.0, 0.2))
		b.sphere(1.0, Vector3(x, h, z), grey, sc, Basis(Vector3.UP, rng.randf() * TAU), 7)
		if sc.x > 1.0:
			var rcs := CollisionShape3D.new()
			var sph := SphereShape3D.new()
			sph.radius = minf(sc.x, sc.z) * 0.9
			rcs.shape = sph
			rcs.position = Vector3(x, h, z)
			solid.add_child(rcs)

	# Fleurs et buissons dans l'herbe
	var petals := [Color(1.0, 0.45, 0.6), Color(1.0, 0.9, 0.3), Color(1, 1, 1), Color(0.6, 0.55, 1.0), Color(1.0, 0.6, 0.3)]
	var flowers := 0
	tries = 0
	while flowers < 90 and tries < 900:
		tries += 1
		var x := rng.randf_range(-45.0, 45.0)
		var z := rng.randf_range(-45.0, 45.0)
		var h := Island.height(x, z)
		if h < 1.3 or Island.in_village(x, z, 4.0) or Vector2(x, z).distance_to(Island.HOUSE_POS) < 7.0 or Vector2(x, z).distance_to(Island.SHOP_POS) < 6.0 or Vector2(x, z).distance_to(Island.GATE_POS) < 6.0:
			continue
		if absf(x) < 2.0 and z > Island.HOUSE_POS.y and z < Island.SPAWN.y + 1.0:
			continue
		flowers += 1
		if flowers % 6 == 0:
			for j in 3:
				b.sphere(0.45, Vector3(x + j * 0.35 - 0.35, h + 0.25, z + (j % 2) * 0.3), Color(0.3, 0.68, 0.3).lightened(j * 0.06), Vector3(1, 0.8, 1), Basis(), 8)
		else:
			b.cylinder(0.015, 0.015, 0.3, Vector3(x, h + 0.15, z), Color(0.3, 0.6, 0.25), Basis(), 5)
			b.sphere(0.07, Vector3(x, h + 0.32, z), petals[flowers % petals.size()], Vector3(1, 0.6, 1), Basis(), 8)
			b.sphere(0.03, Vector3(x, h + 0.35, z), Color(1.0, 0.85, 0.2), Vector3.ONE, Basis(), 6)

	_welcome_sign(b, world)
	b.build(world, Toon.vertex_color(), "Decor")
	if not pb.empty:
		pb.build(world, Toon.vertex_color(0.035), "Palms")
	_clouds(world, rng)
	_duck(world, player)
	return palms


static func _welcome_sign(b: Builder, world: Node3D) -> void:
	var base := Island.ground(3.2, Island.SPAWN.y - 3.0)
	var wood := Color(0.72, 0.5, 0.3)
	b.box(Vector3(0.14, 2.2, 0.14), base + Vector3(-1.0, 1.1, 0), wood.darkened(0.2))
	b.box(Vector3(0.14, 2.2, 0.14), base + Vector3(1.0, 1.1, 0), wood.darkened(0.2))
	b.box(Vector3(2.6, 1.0, 0.1), base + Vector3(0, 1.75, 0), wood)
	b.box(Vector3(2.9, 0.85, 0.1), base + Vector3(0, 0.62, 0.0), wood.lightened(0.1), false)

	var title := Label3D.new()
	title.text = "ÎLE FARFELUE"
	title.font_size = 96
	title.outline_size = 22
	title.modulate = Color(1.0, 0.85, 0.25)
	title.outline_modulate = INK
	title.pixel_size = 0.0045
	title.position = base + Vector3(0, 1.85, 0.06)
	world.add_child(title)

	var sub := Label3D.new()
	sub.text = "Population : 3 (et un canard)"
	sub.font_size = 40
	sub.outline_size = 10
	sub.outline_modulate = INK
	sub.pixel_size = 0.004
	sub.position = base + Vector3(0, 1.45, 0.06)
	world.add_child(sub)

	var help := Label3D.new()
	help.text = "Grip : attraper / lancer\nViser un perso + gâchette : ÉCHANGE DE CORPS\nX : changer de perso   B : vue 1re / 3e personne\nA : sauter   Y : réplique   Joystick droit : tourner\nRamasse les coquillages de la plage : la Boutique Kawaii est à droite !\nLe Donjon des Boulettes est à gauche. Parle à Riku pour avoir une épée.\nSac : bouton menu (manette gauche). Pierre a un souci sur la plage..."
	help.font_size = 36
	help.outline_size = 10
	help.outline_modulate = INK
	help.pixel_size = 0.0026
	help.position = base + Vector3(0, 0.6, 0.06)
	world.add_child(help)


static func _clouds(world: Node3D, rng: RandomNumberGenerator) -> void:
	var holder := Spinner.new()
	holder.name = "Clouds"
	holder.spin = 0.01
	world.add_child(holder)
	var b := Builder.new()
	for k in 12:
		var a := k * TAU / 12.0 + rng.randf_range(-0.2, 0.2)
		var d := rng.randf_range(90.0, 150.0)
		var c := Vector3(cos(a) * d, rng.randf_range(32.0, 48.0), sin(a) * d)
		for j in 5:
			var off := Vector3(rng.randf_range(-6, 6), rng.randf_range(-1, 2), rng.randf_range(-3, 3))
			b.sphere(rng.randf_range(4.0, 7.0), c + off, Color(1, 1, 1), Vector3(1.0, 0.7, 1.0), Basis(), 10)
	var mi := b.build(holder, Toon.vertex_color(), "CloudMesh")
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func _duck(world: Node3D, player: Node3D) -> void:
	var duck := Spinner.new()
	duck.name = "GiantDuck"
	duck.position = Vector3(38.0, 0.2, 50.0)
	duck.rotation.y = -2.4
	duck.bob = 0.25
	duck.bob_speed = 1.3
	duck.talk_text = "COIN !"
	duck.talk_radius = 40.0
	duck.player = player
	world.add_child(duck)
	var b := Builder.new()
	var yellow := Color(1.0, 0.85, 0.15)
	b.sphere(2.2, Vector3(0, 0.8, 0), yellow, Vector3(1.0, 0.7, 1.35))
	b.sphere(0.9, Vector3(0, 1.4, 2.2), yellow, Vector3(1.0, 0.6, 0.8))
	b.sphere(1.45, Vector3(0, 3.0, -1.4), yellow)
	b.sphere(1.0, Vector3(0, 2.8, -2.8), Color(1.0, 0.5, 0.1), Vector3(0.8, 0.32, 0.9))
	for sx in [-1.0, 1.0]:
		b.sphere(0.32, Vector3(sx * 0.62, 3.35, -2.5), Color.WHITE, Vector3(1, 1.2, 0.5))
		b.sphere(0.18, Vector3(sx * 0.66, 3.35, -2.66), INK, Vector3(1, 1.3, 0.5))
		b.sphere(0.07, Vector3(sx * 0.6, 3.45, -2.76), Color.WHITE)
		b.sphere(0.9, Vector3(sx * 2.0, 1.1, 0.2), yellow.darkened(0.05), Vector3(0.35, 0.6, 1.0))
	b.build(duck, Toon.vertex_color(0.04), "Duck")
