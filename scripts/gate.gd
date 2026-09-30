extends Node3D
## L'entrée du Donjon des Boulettes, sur l'île, gardée par Riku le punk.
## Parler à Riku (menu de choix) ; il donne l'épée après son "test de punk".
## Entrer dans le portail sous l'arche = téléportation dans le donjon.

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Island := preload("res://scripts/island.gd")
const Fx := preload("res://scripts/fx.gd")
const Save := preload("res://scripts/save.gd")
const Sword := preload("res://scripts/sword.gd")
const Characters := preload("res://scripts/characters.gd")
const Brain := preload("res://scripts/punk_brain.gd")
const Punk := preload("res://scripts/punk.gd")
const TalkMenu := preload("res://scripts/talk_menu.gd")

var world: Node3D
var player
var brain := Brain.new()
var punk
var menu
var ring: MeshInstance3D
var state := "closed"
var _idle := 0.0
var _block_cd := 0.0
var _ko := false


func build(p_world: Node3D, p_player) -> void:
	world = p_world
	player = p_player
	var d := Island.gate_dir()
	position = Vector3(Island.GATE_POS.x, Island.GATE_H, Island.GATE_POS.y)
	rotation.y = atan2(d.x, d.y)

	var b := Builder.new()
	var stone := Color(0.6, 0.56, 0.66)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(0.9, 3.6, 0.9), Vector3(sx * 1.65, 1.8, 0), stone)
		b.box(Vector3(1.1, 0.3, 1.1), Vector3(sx * 1.65, 0.15, 0), stone.darkened(0.2))
	b.box(Vector3(4.4, 0.8, 1.1), Vector3(0, 3.95, 0), stone.lightened(0.05))
	# Tête de slime géante sculptée au-dessus de l'arche
	b.sphere(0.75, Vector3(0, 4.6, 0.1), Color(0.45, 0.9, 0.45), Vector3(1.2, 0.8, 0.8))
	for sx in [-1.0, 1.0]:
		b.sphere(0.12, Vector3(sx * 0.28, 4.7, -0.45), Color(0.13, 0.08, 0.17), Vector3(0.8, 1.3, 0.5))
	b.sphere(0.1, Vector3(0, 4.45, -0.52), Color(0.4, 0.1, 0.2), Vector3(1.5, 0.6, 0.4))
	# Colline de rochers derrière, comme si l'escalier descendait sous terre
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for k in 9:
		var p := Vector3(rng.randf_range(-3.0, 3.0), rng.randf_range(0.5, 2.5), rng.randf_range(-3.5, -1.2))
		b.sphere(rng.randf_range(1.0, 1.8), p, Color(0.55, 0.52, 0.5).darkened(rng.randf() * 0.2), Vector3(1.0, 0.8, 1.0), Basis(), 8)
	b.collider(Vector3(7.0, 4.0, 3.0), Vector3(0, 2.0, -2.6))
	# Escalier qui s'enfonce
	for k in 4:
		b.box(Vector3(2.3, 0.15, 0.4), Vector3(0, -0.05 - k * 0.12, -0.2 - k * 0.35), Color(0.45, 0.42, 0.5), false)
	b.build(self, Toon.vertex_color(0.02), "Gate")

	var portal := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(2.4, 3.1, 0.05)
	portal.mesh = pm
	portal.material_override = Toon.unlit(Color(0.2, 0.08, 0.3))
	portal.position = Vector3(0, 1.6, 0.15)
	add_child(portal)
	ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.95
	tm.outer_radius = 1.1
	ring.mesh = tm
	ring.material_override = Toon.unlit(Color(0.5, 1.0, 0.7))
	ring.position = Vector3(0, 1.6, 0.25)
	ring.rotation.x = PI / 2.0
	add_child(ring)

	var title := Label3D.new()
	title.text = "DONJON DES BOULETTES"
	title.font_size = 80
	title.outline_size = 20
	title.modulate = Color(0.6, 1.0, 0.6)
	title.outline_modulate = Color(0.13, 0.08, 0.17)
	title.pixel_size = 0.004
	title.position = Vector3(0, 3.95, 0.57)
	add_child(title)

	punk = Punk.new()
	punk.name = "Riku"
	add_child(punk)
	punk.position = Vector3(2.9, 0.02, 1.3)
	punk.setup(self, player)

	menu = TalkMenu.new()
	menu.name = "PunkMenu"
	add_child(menu)
	menu.position = Vector3(4.3, 1.45, 1.9)


## Où le joueur réapparaît en sortant du donjon.
func exit_position() -> Vector3:
	return to_global(Vector3(0, 0.3, 3.2))


func ctx() -> Dictionary:
	var name: String = Characters.LIST[player.char_id]["name"]
	return {"char_name": name, "hat": Save.hats.get(name, "")}


func say(text: String) -> void:
	punk.chibi.say(text, 2.5 + text.length() * 0.06)


func _physics_process(delta: float) -> void:
	if player == null or player.in_dungeon:
		return
	brain.tick(delta)
	ring.rotation.y += delta * 1.5
	_block_cd = maxf(_block_cd - delta, 0.0)
	var lp: Vector3 = to_local(player.global_position)

	# Portail
	if absf(lp.x) < 1.1 and lp.z > -0.3 and lp.z < 0.7 and absf(lp.y) < 2.0:
		if Save.sword > 0:
			state = "closed"
			menu.clear()
			menu.set_header("")
			player.enter_dungeon()
			return
		elif _block_cd <= 0.0:
			_block_cd = 1.5
			say(brain.no_sword_line())
			player.global_position = to_global(Vector3(lp.x, 0.3, 2.0))
			Fx.text(world, to_global(Vector3(0, 2.0, 1.0)), "BONG !", Color(0.8, 0.6, 1.0), 1.0)

	# Discussion avec Riku
	var near: bool = player.global_position.distance_to(punk.global_position) < 3.3
	if near and state == "closed":
		state = "main"
		_idle = 0.0
		if _ko:
			_ko = false
		else:
			say(brain.greet(ctx()))
		_show_main()
	elif not near and state != "closed":
		state = "closed"
		say(brain.farewell())
		menu.clear()
		menu.set_header("")
		Save.save_game()
	if state != "closed":
		menu.face(player.camera.global_position)
		menu.set_header("Respect de Riku : %d / 100%s" % [int(brain.respect()), "" if Save.sword == 0 else "   ·   " + Sword.NAMES[Save.sword]])
		_idle += delta
		if _idle > 22.0:
			_idle = 0.0
			say(brain.idle())


func _show_main() -> void:
	var opts: Array = []
	for o in brain.options(ctx()):
		opts.append([o[1], _choose.bind(o[0])])
	menu.show_options(opts)


func choose(index: int) -> void:
	if state != "closed":
		menu.choose(index)


func _choose(intent: String) -> void:
	_idle = 0.0
	var r: Dictionary = brain.respond(intent, ctx())
	say(r["text"])
	if r.get("test", false):
		state = "test"
		var opts: Array = []
		for a in brain.test_answers():
			opts.append([a[1], _choose.bind(a[0]), Color(1.0, 0.85, 0.95)])
		menu.show_options(opts)
		return
	if r.get("give_sword", false):
		Save.sword = maxi(Save.sword, 1)
		player.refresh_sword()
		Fx.puff(world, player.global_position + Vector3(0, 1.2, 0), Color(1.0, 0.85, 0.95))
		Fx.text(world, player.global_position + Vector3(0, 2.0, 0), "ÉPÉE ROCK'N'ROLL !", Color(1.0, 0.5, 0.8), 1.2, 2.0)
		var hint := "Grip dans le vide pour dégainer" if player.vr else "Touche G pour dégainer, clic pour frapper"
		Fx.text(world, menu.global_position + Vector3(0, 0.8, 0), hint, Color(1, 1, 1), 0.45, 3.0)
	if r.has("upgrade"):
		Save.shells -= int(r["upgrade"])
		Save.sword = maxi(Save.sword, 2)
		player.refresh_sword()
		Fx.text(world, player.global_position + Vector3(0, 2.0, 0), "ÉPÉE ÉLECTRIQUE ! Bzzzt !", Color(1.0, 0.95, 0.3), 1.2, 2.0)
	if r.get("check", false):
		punk.chibi.arm_r_offset = -2.4
		punk.chibi.pop()
		Fx.text(world, punk.global_position + Vector3(0, 1.9, 0), "CHECK !", Color(1.0, 0.85, 0.3), 1.0)
	state = "main"
	Save.save_game()
	_show_main()


func on_punk_bonked() -> void:
	Fx.text(world, punk.global_position + Vector3(0, 1.9, 0), "BONK !", Color(1.0, 0.5, 0.3), 1.0)
	punk.chibi.pop()
	say(brain.bonked())


func on_player_ko() -> void:
	_ko = true
	say(brain.ko_line())
