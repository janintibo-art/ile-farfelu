extends Node3D
## PROLOGUE — La Plage des Bagages Perdus.
## Réveil sur la plage, bateau échoué, objets étranges un peu partout.
## 1. Soulever la planche qui coince la valise, ouvrir la valise
##    (cuillère, chaussette rouge, photo, petite clé en cuivre).
## 2. Retourner la photo : « Bienvenue à nouveau. »
## 3. Retirer le bouchon de la bouteille : Pico sort.
## 4. Réparer le pont avec trois planches. La quatrième ? Pico la garde.

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Island := preload("res://scripts/island.gd")
const Fx := preload("res://scripts/fx.gd")
const Save := preload("res://scripts/save.gd")
const Props := preload("res://scripts/props.gd")

const PLANK_W := 0.45
const N_PLANKS := 18
const MISSING := [8, 9, 10]
const STORY_ITEMS := ["photo", "cle", "cuillere", "chaussette"]

var world: Node3D
var player
var pico
var suitcase: StaticBody3D
var suitcase_lid: Node3D
var suitcase_plank: RigidBody3D
var _plank_home := Vector3.ZERO
var bottle: Node3D
var cork: RigidBody3D
var _cork_home := Vector3.ZERO
var bridge_wall: CollisionShape3D
var deck_shape: CollisionShape3D
var deck_y := 2.0
var slots: Array = []        # [Transform3D, rempli ?]
var loose_planks: Array = []
var _t := 0.0
var _hint_cd := 0.0
var _fade: MeshInstance3D
var _photo_spin := 0.0
var _photo_front_seen := false


func B(x: float, z: float, up := 0.0) -> Vector3:
	return Island.ground(Island.BEACH.x + x, Island.BEACH.y + z) + Vector3(0, up, 0)


## Où le joueur commence quand le pont n'est pas encore réparé.
static func start_position() -> Vector3:
	return Island.ground(Island.BEACH.x, Island.BEACH.y + 1.5) + Vector3(0, 0.1, 0)


func build(p_world: Node3D, p_player, p_pico) -> void:
	world = p_world
	player = p_player
	pico = p_pico
	_beach_decor()
	_suitcase()
	_bottle()
	_bridge()
	_signs()


# --- Décor de la plage --------------------------------------------------------------

func _beach_decor() -> void:
	var b := Builder.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	# Le bateau échoué, couché sur le flanc, derrière le joueur
	var hull := Color(0.62, 0.38, 0.25)
	var bp := B(4.5, 5.0, 0.2)
	var tilt := Basis(Vector3.UP, 0.5) * Basis(Vector3.FORWARD, 0.35)
	b.sphere(1.0, bp + Vector3(0, 0.3, 0), hull, Vector3(1.3, 0.7, 3.2), tilt, 16)
	b.box(Vector3(2.3, 0.15, 5.6), bp + tilt * Vector3(0, 0.95, 0), Color(0.75, 0.55, 0.36), false, tilt)
	b.box(Vector3(2.62, 0.18, 6.1), bp + tilt * Vector3(0, 0.75, 0), Color(0.9, 0.9, 0.85), false, tilt)
	b.cylinder(0.08, 0.1, 3.2, bp + tilt * Vector3(0, 2.3, -0.5), Color(0.5, 0.33, 0.2), tilt * Basis(Vector3.RIGHT, 0.25), 8)
	b.prism(Vector3(0.05, 1.6, 1.4), bp + tilt * Vector3(0.06, 2.6, -0.1), Color(0.95, 0.92, 0.85), tilt * Basis(Vector3.RIGHT, 0.25))
	b.collider(Vector3(2.4, 1.6, 6.0), bp + Vector3(0, 0.6, 0), Basis(Vector3.UP, 0.5))
	b.box(Vector3(0.3, 0.03, 1.4), B(2.0, 3.0, 0.03), Color(0.65, 0.45, 0.28), false, Basis(Vector3.UP, 1.1))
	# Des valises un peu partout
	var case_cols := [Color(0.35, 0.55, 0.85), Color(0.85, 0.35, 0.35), Color(0.4, 0.7, 0.45), Color(0.9, 0.75, 0.3), Color(0.6, 0.4, 0.75)]
	for k in 7:
		var p := B(rng.randf_range(-9.0, 9.0), rng.randf_range(-6.0, 6.5), 0.15)
		if p.distance_to(B(0, 1.5)) < 2.0 or p.distance_to(B(1.3, -1.6)) < 1.5 or p.distance_to(B(-3.5, -2.5)) < 1.5:
			continue
		var col: Color = case_cols[k % case_cols.size()]
		var r := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.FORWARD, rng.randf_range(-0.2, 0.2))
		b.box(Vector3(0.6, 0.22, 0.42), p, col, true, r)
		b.box(Vector3(0.18, 0.04, 0.04), p + r * Vector3(0, 0.13, 0.0), Color(0.2, 0.2, 0.2), false, r)
		b.box(Vector3(0.61, 0.03, 0.43), p + r * Vector3(0, 0.0, 0.0), col.darkened(0.3), false, r)
	# Chaises
	for k in 2:
		var p := B(-6.5 + k * 13.0, 2.5 - k * 4.0, 0.0)
		var r := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.FORWARD, 0.25 * k)
		var wood := Color(0.75, 0.5, 0.3)
		b.box(Vector3(0.45, 0.05, 0.45), p + r * Vector3(0, 0.45, 0), wood, false, r)
		b.box(Vector3(0.45, 0.5, 0.05), p + r * Vector3(0, 0.72, 0.2), wood, false, r)
		for c in [Vector2(-0.19, -0.19), Vector2(0.19, -0.19), Vector2(-0.19, 0.19), Vector2(0.19, 0.19)]:
			b.box(Vector3(0.04, 0.45, 0.04), p + r * Vector3(c.x, 0.22, c.y), wood.darkened(0.2), false, r)
	# Chaussures dépareillées
	for k in 4:
		var p := B(rng.randf_range(-7.0, 7.0), rng.randf_range(-4.0, 4.0), 0.05)
		var sc: Color = [Color(0.3, 0.2, 0.15), Color(0.9, 0.3, 0.3), Color(0.95, 0.95, 0.95), Color(0.3, 0.5, 0.9)][k]
		b.sphere(0.08, p, sc, Vector3(0.8, 0.6, 1.5), Basis(Vector3.UP, rng.randf() * TAU), 8)
	# Une théière, posée bien droite, comme si de rien n'était
	var tp := B(-1.8, 2.8, 0.0)
	b.sphere(0.13, tp + Vector3(0, 0.12, 0), Color(0.95, 0.95, 0.98), Vector3(1.0, 0.85, 1.0), Basis(), 12)
	b.cylinder(0.02, 0.03, 0.14, tp + Vector3(0.14, 0.16, 0), Color(0.95, 0.95, 0.98), Basis(Vector3.FORWARD, -0.9), 6)
	b.torus(0.06, 0.08, tp + Vector3(-0.13, 0.14, 0), Color(0.95, 0.95, 0.98), Basis(Vector3.RIGHT, PI / 2.0))
	b.sphere(0.03, tp + Vector3(0, 0.25, 0), Color(0.3, 0.5, 0.9))
	b.cylinder(0.11, 0.11, 0.01, tp + Vector3(0, 0.18, 0), Color(0.3, 0.5, 0.9), Basis(), 12)
	# Un tableau, planté dans le sable
	var fp := B(6.5, -3.0, 0.0)
	var fr := Basis(Vector3.UP, -0.6) * Basis(Vector3.RIGHT, -0.15)
	b.box(Vector3(0.9, 0.7, 0.06), fp + fr * Vector3(0, 0.45, 0), Color(0.85, 0.65, 0.2), false, fr)
	b.box(Vector3(0.78, 0.58, 0.07), fp + fr * Vector3(0, 0.45, 0), Color(0.45, 0.65, 0.9), false, fr)
	b.box(Vector3(0.78, 0.2, 0.075), fp + fr * Vector3(0, 0.26, 0), Color(0.4, 0.75, 0.4), false, fr)
	b.sphere(0.07, fp + fr * Vector3(0.2, 0.6, 0.04), Color(1.0, 0.85, 0.3), Vector3(1, 1, 0.3), fr)
	# Une roue de charrette
	var wp := B(-8.0, -1.0, 0.0)
	var wr := Basis(Vector3.UP, 0.8) * Basis(Vector3.FORWARD, 1.3)
	b.torus(0.4, 0.5, wp + Vector3(0, 0.1, 0), Color(0.55, 0.38, 0.22), wr)
	for k in 6:
		b.box(Vector3(0.04, 0.85, 0.04), wp + Vector3(0, 0.1, 0), Color(0.6, 0.42, 0.25), false, wr * Basis(Vector3.UP, k * PI / 6.0) * Basis(Vector3.RIGHT, PI / 2.0))
	# Un parapluie ouvert, planté dans le sable
	var up := B(-5.0, 4.5, 0.0)
	var ur := Basis(Vector3.FORWARD, 0.2)
	b.cylinder(0.015, 0.015, 1.5, up + ur * Vector3(0, 0.75, 0), Color(0.25, 0.25, 0.3), ur, 6)
	for k in 8:
		var c: Color = Color(0.95, 0.35, 0.45) if k % 2 == 0 else Color.WHITE
		b.prism(Vector3(0.62, 0.38, 0.04), up + ur * (Vector3(0, 1.42, 0) + Basis(Vector3.UP, k * TAU / 8.0) * Vector3(0, 0, 0.3)), c, ur * Basis(Vector3.UP, k * TAU / 8.0) * Basis(Vector3.RIGHT, -1.1))
	# Une porte sans maison, debout, toute seule
	var dp := B(-7.5, -5.0, 0.0)
	var dr := Basis(Vector3.UP, 0.4)
	b.box(Vector3(1.2, 0.12, 0.2), dp + dr * Vector3(0, 2.15, 0), Color(0.95, 0.95, 0.9), true, dr)
	for sx in [-0.55, 0.55]:
		b.box(Vector3(0.1, 2.2, 0.2), dp + dr * Vector3(sx, 1.1, 0), Color(0.95, 0.95, 0.9), true, dr)
	b.box(Vector3(1.0, 2.05, 0.06), dp + dr * Vector3(0, 1.03, 0.02), Color(0.35, 0.6, 0.55), false, dr)
	b.sphere(0.04, dp + dr * Vector3(0.35, 1.0, 0.08), Color(1.0, 0.82, 0.3))
	b.box(Vector3(0.2, 0.08, 0.02), dp + dr * Vector3(0, 1.75, 0.06), Color(1.0, 0.82, 0.3), false, dr)
	# Des feuilles de papier écrites, tombées de la tempête
	for k in 26:
		var p := B(rng.randf_range(-11.0, 11.0), rng.randf_range(-9.0, 8.0), 0.012)
		b.box(Vector3(0.21, 0.004, 0.29), p, Color(0.97, 0.96, 0.9), false, Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(-0.08, 0.08)))
		b.box(Vector3(0.14, 0.005, 0.01), p + Vector3(0, 0.001, 0.03), Color(0.35, 0.35, 0.5), false, Basis(Vector3.UP, rng.randf() * TAU))
	b.build(self, Toon.vertex_color(0.008), "BeachDecor")


# --- La valise ------------------------------------------------------------------------

class Suitcase extends StaticBody3D:
	var owner_node

	func set_hover(on: bool) -> void:
		scale = Vector3.ONE * (1.05 if on else 1.0)

	func press() -> void:
		owner_node.on_suitcase_pressed()


func _suitcase() -> void:
	var sp := B(1.3, -1.6, 0.0)
	suitcase = Suitcase.new()
	suitcase.owner_node = self
	suitcase.collision_layer = 1 | 16
	add_child(suitcase)
	suitcase.global_position = sp
	suitcase.rotation.y = 0.3
	var b := Builder.new()
	var leather := Color(0.55, 0.3, 0.2)
	b.box(Vector3(0.8, 0.26, 0.55), Vector3(0, 0.13, 0), leather, false)
	for x in [-0.25, 0.25]:
		b.box(Vector3(0.05, 0.27, 0.56), Vector3(x, 0.13, 0), Color(0.35, 0.2, 0.12), false)
	b.box(Vector3(0.74, 0.02, 0.49), Vector3(0, 0.27, 0), Color(0.85, 0.75, 0.6), false)
	b.box(Vector3(0.12, 0.08, 0.04), Vector3(0, 0.2, -0.29), Color(0.9, 0.75, 0.3), false)
	b.build(suitcase, Toon.vertex_color(0.008), "CaseBody")
	suitcase_lid = Node3D.new()
	suitcase_lid.position = Vector3(0, 0.27, 0.275)
	suitcase.add_child(suitcase_lid)
	var lb := Builder.new()
	lb.box(Vector3(0.8, 0.08, 0.55), Vector3(0, 0.04, -0.275), leather.lightened(0.05), false)
	lb.box(Vector3(0.22, 0.03, 0.05), Vector3(0, 0.09, -0.275), Color(0.25, 0.15, 0.1), false)
	lb.build(suitcase_lid, Toon.vertex_color(0.008), "CaseLid")
	# Petite étiquette
	var tag := Label3D.new()
	tag.text = "Ne pas ouvrir avant\nd'être arrivé."
	tag.font_size = 32
	tag.pixel_size = 0.0012
	tag.modulate = Color(0.2, 0.15, 0.3)
	tag.outline_size = 0
	tag.position = Vector3(0, 0.15, -0.282)
	tag.rotation.y = PI
	tag.double_sided = false
	suitcase.add_child(tag)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.8, 0.36, 0.55)
	cs.shape = sh
	cs.position.y = 0.18
	suitcase.add_child(cs)

	if Save.story.get("suitcase", false):
		suitcase_lid.rotation.x = 1.9
		for id in STORY_ITEMS:
			if Save.count(id) == 0:
				_spawn_story_item(id)
		return
	# La planche du bateau qui coince la valise
	if not Save.story.get("plank_off", false):
		_plank_home = sp + Vector3(0.0, 0.42, 0.0)
		suitcase_plank = Props.make(world, "planche", _plank_home)
		suitcase_plank.rotation = Vector3(0.0, 0.3 + 0.6, 0.15)
		suitcase_plank.no_reset = false


func on_suitcase_pressed() -> void:
	if Save.story.get("suitcase", false):
		return
	if not Save.story.get("plank_off", false):
		Fx.text(world, suitcase.global_position + Vector3(0, 0.8, 0), "Coincée sous la planche !", Color(1, 1, 1), 0.45, 1.2)
		return
	Save.story["suitcase"] = true
	Save.save_game()
	var tw := suitcase_lid.create_tween()
	tw.tween_property(suitcase_lid, "rotation:x", 1.9, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Fx.puff(world, suitcase.global_position + Vector3(0, 0.4, 0), Color(1.0, 0.95, 0.85))
	Fx.text(world, suitcase.global_position + Vector3(0, 1.0, 0), "Une cuillère, une chaussette rouge,\nune photo... et une petite clé.", Color(1.0, 0.92, 0.7), 0.5, 3.0)
	for id in STORY_ITEMS:
		_spawn_story_item(id)
	if pico.active:
		pico.say("Une valise qui n'est pas à toi. On l'ouvre quand même. J'aime bien ta façon de penser.")


func _spawn_story_item(id: String) -> void:
	var k := STORY_ITEMS.find(id)
	var p := suitcase.to_global(Vector3(-0.24 + k * 0.16, 0.42, 0.0))
	var rb := Props.make(world, id, p)
	rb.story_id = id
	rb.home = p
	if id == "photo":
		rb.rotation.x = -PI / 2.0


# --- La bouteille de Pico -----------------------------------------------------------

func _bottle() -> void:
	if Save.story.get("pico", false):
		pico.global_position = start_position() + Vector3(0.9, 0, 0.3)
		pico.active = true
		return
	bottle = Node3D.new()
	bottle.name = "Bottle"
	add_child(bottle)
	bottle.global_position = B(-3.5, -2.5, 0.12)
	bottle.rotation.y = 0.9
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.5, 0.85, 0.65, 0.35)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	var b := Builder.new()
	b.sphere(0.13, Vector3.ZERO, Color.WHITE, Vector3(1.0, 1.0, 1.9), Basis(), 16)
	b.cylinder(0.04, 0.05, 0.14, Vector3(0, 0, -0.3), Color.WHITE, Basis(Vector3.RIGHT, PI / 2.0), 10)
	var mi := b.build(bottle, glass, "Glass")
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Pico, tout serré à l'intérieur
	pico.reparent(bottle, false)
	pico.position = Vector3(0, -0.07, 0.02)
	pico.scale = Vector3.ONE * 0.42
	pico.rotation = Vector3(0, PI, 0)
	_cork_home = bottle.to_global(Vector3(0, 0, -0.38))
	cork = Props.make(world, "bouchon", _cork_home)
	cork.freeze = true
	cork.radius = 0.06
	cork.grab_text = "POP ?"
	cork.global_rotation = bottle.global_rotation + Vector3(PI / 2.0, 0, 0)


func _free_pico() -> void:
	Save.story["pico"] = true
	Save.save_game()
	var pos := bottle.global_position + Vector3(0, 0.05, 0)
	pico.reparent(world, false)
	pico.global_position = pos
	pico.rotation = Vector3.ZERO
	pico.pop_out()
	Fx.text(world, pos + Vector3(0, 0.7, 0), "POP !", Color(1.0, 0.85, 0.3), 1.0)
	Fx.puff(world, pos + Vector3(0, 0.2, 0), Color(1.0, 1.0, 0.95))
	bottle.rotation.z = 0.0
	# Il regarde la bouteille, puis le bouchon, puis toi...
	pico.say("...", 1.6)
	var tw := create_tween()
	tw.tween_interval(1.8)
	tw.tween_callback(func(): pico.say("Je préfère qu'on ne cherche pas à comprendre."))
	tw.tween_interval(4.5)
	tw.tween_callback(func(): pico.say("Moi c'est Pico. Je viens avec toi. Enfin, si tu vas dans une direction sans danger."))


# --- Le pont cassé ------------------------------------------------------------------

func _bridge() -> void:
	var cz := Island.creek_z(Island.BRIDGE_X)
	var z0 := cz - N_PLANKS * PLANK_W * 0.5 + PLANK_W * 0.5
	deck_y = maxf(Island.height(Island.BRIDGE_X, cz - 4.1), Island.height(Island.BRIDGE_X, cz + 4.1)) + 0.06
	var x := Island.BRIDGE_X
	var b := Builder.new()
	var wood := Color(0.62, 0.42, 0.26)
	# Poutres et poteaux
	for sx in [-0.72, 0.72]:
		b.box(Vector3(0.14, 0.18, N_PLANKS * PLANK_W + 0.4), Vector3(x + sx, deck_y - 0.12, cz), wood.darkened(0.25))
		for k in 3:
			var pz := cz - 2.6 + k * 2.6
			b.cylinder(0.08, 0.1, deck_y + 1.2, Vector3(x + sx, (deck_y - 1.2) * 0.5, pz), wood.darkened(0.35), Basis(), 8)
		b.box(Vector3(0.06, 0.06, N_PLANKS * PLANK_W), Vector3(x + sx, deck_y + 0.62, cz), wood, false)
		for k in 5:
			b.box(Vector3(0.06, 0.62, 0.06), Vector3(x + sx, deck_y + 0.31, cz - 3.6 + k * 1.8), wood.darkened(0.15), false)
		b.collider(Vector3(0.1, 1.2, N_PLANKS * PLANK_W), Vector3(x + sx, deck_y + 0.5, cz))
	var placed := int(Save.story.get("planks", 0))
	if Save.story.get("bridge", false):
		placed = 3
	for i in N_PLANKS:
		var z := z0 + i * PLANK_W
		var xf := Transform3D(Basis(Vector3.UP, 0.0), Vector3(x, deck_y, z))
		if i in MISSING:
			var filled := MISSING.find(i) < placed
			slots.append([xf, filled])
			if filled:
				Props.paint(b, "planche", xf)
			else:
				# Contour fantôme : là où une planche manque
				b.box(Vector3(1.4, 0.01, 0.06), Vector3(x, deck_y - 0.02, z - 0.18), Color(1.0, 0.9, 0.5), false)
				b.box(Vector3(1.4, 0.01, 0.06), Vector3(x, deck_y - 0.02, z + 0.18), Color(1.0, 0.9, 0.5), false)
			continue
		Props.paint(b, "planche", xf)
	b.build(self, Toon.vertex_color(0.01), "Bridge")

	# Le tablier (on peut marcher dessus une fois réparé) et le mur invisible
	var body := StaticBody3D.new()
	body.name = "CreekBlock"
	add_child(body)
	deck_shape = CollisionShape3D.new()
	var ds := BoxShape3D.new()
	ds.size = Vector3(1.4, 0.12, N_PLANKS * PLANK_W + 0.6)
	deck_shape.shape = ds
	deck_shape.position = Vector3(x, deck_y - 0.06, cz)
	deck_shape.disabled = false   # le tablier est toujours solide : on ne tombe plus à l'eau
	body.add_child(deck_shape)
	if not Save.story.get("bridge", false):
		var xx := -80.0
		while xx < 80.0:
			var w := 4.0
			var cx := xx + w * 0.5
			if absf(cx - x) < 2.0:
				xx += w
				continue
			_wall(body, cx, w)
			xx += w
		bridge_wall = CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(4.0, 8.0, 0.6)
		bridge_wall.shape = bs
		bridge_wall.position = Vector3(x, 2.0, cz)
		body.add_child(bridge_wall)
		# Les planches à replacer, sur la rive de la plage
		var spots := [Vector2(-2.6, 4.9), Vector2(2.9, 5.6), Vector2(-4.5, 7.5), Vector2(4.2, 7.0)]
		for k in 4 - placed:
			var sp: Vector2 = spots[k]
			var p := Island.ground(x + sp.x, cz + sp.y) + Vector3(0, 0.12, 0)
			var rb := Props.make(world, "planche", p)
			rb.rotation.y = 0.4 + k * 0.9
			rb.add_to_group("bridge_plank")
			loose_planks.append(rb)


func _wall(body: StaticBody3D, cx: float, w: float) -> void:
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(w + 0.2, 8.0, 0.6)
	cs.shape = bs
	cs.position = Vector3(cx, 2.0, Island.creek_z(cx))
	cs.rotation.y = -atan(0.07 * 2.5 * cos(cx * 0.07))
	body.add_child(cs)


func _signs() -> void:
	var t := Label3D.new()
	t.text = "PLAGE DES\nBAGAGES PERDUS"
	t.font_size = 72
	t.outline_size = 18
	t.modulate = Color(1.0, 0.88, 0.45)
	t.outline_modulate = Color(0.13, 0.08, 0.17)
	t.pixel_size = 0.004
	t.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	add_child(t)
	t.global_position = B(0.0, -8.5, 2.2)
	var b := Builder.new()
	b.box(Vector3(0.12, 2.0, 0.12), B(0.0, -8.5, 1.0), Color(0.55, 0.38, 0.22), true)
	var cz := Island.creek_z(Island.BRIDGE_X)
	var sp := Island.ground(Island.BRIDGE_X + 2.0, cz - 5.0)
	b.box(Vector3(0.12, 2.2, 0.12), sp + Vector3(0, 1.1, 0), Color(0.55, 0.38, 0.22), true)
	b.prism(Vector3(1.4, 0.4, 0.06), sp + Vector3(0, 1.95, 0), Color(0.85, 0.65, 0.4), Basis(Vector3.FORWARD, -PI / 2.0))
	b.build(self, Toon.vertex_color(0.01), "Posts")
	var s2 := Label3D.new()
	s2.text = "PORT-BISCORNU ↑\n(enfin, normalement)"
	s2.font_size = 48
	s2.outline_size = 12
	s2.modulate = Color(1.0, 0.95, 0.85)
	s2.outline_modulate = Color(0.13, 0.08, 0.17)
	s2.pixel_size = 0.0035
	s2.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	add_child(s2)
	s2.global_position = sp + Vector3(0, 2.6, 0)


# --- Réveil ---------------------------------------------------------------------------

## Écran noir, on entend la mer, puis on ouvre les yeux.
func wake_up() -> void:
	_fade = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.4
	sm.height = 0.8
	sm.radial_segments = 16
	sm.rings = 8
	_fade.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0, 0, 0, 1)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.no_depth_test = true
	mat.render_priority = 100
	_fade.material_override = mat
	player.camera.add_child(_fade)
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_method(func(a: float): mat.albedo_color = Color(0, 0, 0, a), 1.0, 0.0, 3.0)
	tw.tween_callback(_fade.queue_free)
	tw.tween_callback(func():
		Save.story["woke"] = true
		Save.save_game()
		Fx.text(world, player._front(2.2) + Vector3(0, 0.5, 0), "Où suis-je ?", Color(1, 1, 1), 0.8, 2.5))


# --- Boucle -----------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_t += delta
	_hint_cd = maxf(_hint_cd - delta, 0.0)
	# La bouteille gigote toute seule
	if bottle and not Save.story.get("pico", false):
		bottle.rotation.z = sin(_t * 7.0) * 0.18 * (0.5 + 0.5 * sin(_t * 0.9))
		if cork and is_instance_valid(cork) and cork.global_position.distance_to(_cork_home) > 0.22:
			_free_pico()
	# La planche sur la valise
	if suitcase_plank and is_instance_valid(suitcase_plank) and not Save.story.get("plank_off", false):
		if suitcase_plank.global_position.distance_to(_plank_home) > 0.6:
			Save.story["plank_off"] = true
			Save.save_game()
			suitcase_plank.add_to_group("bridge_plank")
			loose_planks.append(suitcase_plank)
			Fx.text(world, suitcase.global_position + Vector3(0, 0.9, 0), "La valise est libre !", Color(1.0, 0.92, 0.6), 0.6, 1.5)
	_check_photo(delta)
	_check_planks()
	_check_zone()


func _check_photo(delta: float) -> void:
	if Save.story.get("photo_seen", false):
		return
	for n in get_tree().get_nodes_in_group("grab"):
		if n.get("kind") != "photo" or not n.freeze:
			continue
		var held_desk: bool = player._held_desktop == n
		if not (n.has_meta("held_by") or held_desk):
			continue
		if held_desk:
			# Sur PC : la photo se tient droite devant la caméra et tourne doucement
			_photo_spin += delta * 1.6
			n.global_basis = Basis(Vector3.UP, player.camera.global_rotation.y + _photo_spin)
		var to_cam: Vector3 = (player.camera.global_position - n.global_position).normalized()
		var front: Vector3 = n.global_basis.z
		if not _photo_front_seen and front.dot(to_cam) > 0.5:
			_photo_front_seen = true
			Fx.text(world, n.global_position + Vector3(0, 0.35, 0), "Port-Biscornu... des inconnus devant une auberge.\nEt toi, au milieu.", Color(1.0, 0.92, 0.75), 0.4, 3.5)
		elif front.dot(to_cam) < -0.5:
			Save.story["photo_seen"] = true
			Save.save_game()
			Fx.text(world, n.global_position + Vector3(0, 0.4, 0), "« BIENVENUE À NOUVEAU. »", Color(0.85, 0.75, 1.0), 0.8, 3.5)
			if pico.active:
				pico.say("« À nouveau » ? Tu es déjà venu ici, toi ?")
			return


func _check_planks() -> void:
	if Save.story.get("bridge", false):
		return
	for rb in loose_planks.duplicate():
		if not is_instance_valid(rb):
			loose_planks.erase(rb)
			continue
		for s in slots:
			if s[1]:
				continue
			var xf: Transform3D = s[0]
			if rb.global_position.distance_to(xf.origin) < 0.8:
				player.release_item(rb)
				rb.freeze = true
				rb.remove_from_group("grab")
				rb.remove_from_group("bridge_plank")
				rb.global_transform = xf
				s[1] = true
				loose_planks.erase(rb)
				Save.story["planks"] = int(Save.story.get("planks", 0)) + 1
				Save.save_game()
				Fx.text(world, xf.origin + Vector3(0, 0.6, 0), "CLAC !", Color(1.0, 0.9, 0.4), 0.8, 0.8)
				if Save.story["planks"] >= 3:
					_bridge_done()
				break


func _bridge_done() -> void:
	Save.story["bridge"] = true
	if bridge_wall:
		bridge_wall.disabled = true
	deck_shape.disabled = false
	Fx.text(world, slots[1][0].origin + Vector3(0, 1.2, 0), "Le pont est réparé !", Color(0.7, 1.0, 0.7), 1.0, 2.0)
	# La quatrième planche : Pico insiste pour la garder
	for rb in loose_planks:
		if is_instance_valid(rb):
			player.release_item(rb)
			Fx.puff(world, rb.global_position, Color(1.0, 0.95, 0.85))
			rb.queue_free()
			Save.add_item("planche")
			Save.story["kept_plank"] = true
	loose_planks.clear()
	Save.save_game()
	if pico.active:
		pico.say("Attends ! On garde celle-là. On ne sait jamais. Ça pourrait être une planche importante.")
		var tw := create_tween()
		tw.tween_interval(5.0)
		tw.tween_callback(func(): pico.say("Je l'ai mise dans le sac. Ne me remercie pas."))


func _check_zone() -> void:
	var p: Vector3 = player.global_position
	if player.in_dungeon:
		return
	var dz := p.z - Island.creek_z(p.x)
	if not Save.story.get("bridge", false) and absf(dz) < 1.6 and _hint_cd <= 0.0:
		_hint_cd = 12.0
		if pico.active:
			pico.say("Tu comptes traverser à la nage ? Moi en tout cas non. Il faudrait réparer le pont.")
		else:
			Fx.text(world, player._front(1.6), "Le pont est cassé. Il manque des planches...", Color(1, 1, 1), 0.5, 1.8)
	if Save.story.get("bridge", false) and not Save.story.get("castle_seen", false) and dz < -6.0:
		Save.story["castle_seen"] = true
		Save.save_game()
		Fx.text(world, player._front(3.0) + Vector3(0, 1.2, 0), "Au loin, sur la montagne :\nle Château des Versions Officielles.", Color(0.8, 0.8, 1.0), 0.8, 4.0)
		if pico.active:
			pico.say("Un château. Fermé, évidemment. Tous les châteaux intéressants sont fermés.")
