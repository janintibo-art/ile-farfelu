extends Node3D
## Le coin pêche : un ponton, Luc-Ael le pêcheur et Pierre (sans slip).
## Quête : Pierre a perdu son slip ; Luc-Ael prête sa canne ; si on repêche
## le slip, on gagne la canne ; en le rendant à Pierre, 15 coquillages.

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Island := preload("res://scripts/island.gd")
const Fx := preload("res://scripts/fx.gd")
const Save := preload("res://scripts/save.gd")
const Characters := preload("res://scripts/characters.gd")
const Brain := preload("res://scripts/shore_brain.gd")
const Talker := preload("res://scripts/talker.gd")
const TalkMenu := preload("res://scripts/talk_menu.gd")
const Rod := preload("res://scripts/rod.gd")

const PIER_LEN := 9.0
const TALK_DIST := 2.8

var world: Node3D
var player
var brain := Brain.new()
var pierre
var luc
var menu_p
var menu_l
var state_p := "closed"
var state_l := "closed"
var deck_y := 0.5
var _idle_p := 0.0
var _idle_l := 0.0


func build(p_world: Node3D, p_player) -> void:
	world = p_world
	player = p_player
	var base := Island.pier_base()
	var d := Island.pier_dir()
	deck_y = maxf(Island.height(base.x, base.y), 0.35) + 0.04
	position = Vector3(base.x, 0.0, base.y)
	# Axe local -Z = vers le large
	rotation.y = atan2(-d.x, -d.y)

	var b := Builder.new()
	var wood := Color(0.72, 0.52, 0.34)
	var n := int(PIER_LEN / 0.5)
	for k in n + 4:
		var z := 2.0 - k * 0.5
		b.box(Vector3(2.0, 0.1, 0.46), Vector3(0, deck_y - 0.05, z), wood if k % 2 == 0 else wood.darkened(0.08), false)
	b.collider(Vector3(2.0, 0.1, PIER_LEN + 2.0), Vector3(0, deck_y - 0.05, 2.0 - (PIER_LEN + 2.0) * 0.5 + 0.25))
	for k in 5:
		var z := 1.0 - k * 2.4
		for sx in [-1.0, 1.0]:
			b.cylinder(0.09, 0.1, 3.0, Vector3(sx * 1.0, deck_y - 1.4, z), wood.darkened(0.25), Basis(), 8)
			if k > 0:
				b.box(Vector3(0.08, 0.7, 0.08), Vector3(sx * 0.98, deck_y + 0.35, z), wood.darkened(0.15), false)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(0.06, 0.06, PIER_LEN - 1.0), Vector3(sx * 0.98, deck_y + 0.68, -PIER_LEN * 0.5 + 0.4), wood.lightened(0.05), false)
		b.collider(Vector3(0.1, 1.0, PIER_LEN - 1.0), Vector3(sx * 1.0, deck_y + 0.5, -PIER_LEN * 0.5 + 0.4))
	# Seau de Luc-Ael et bouée
	var lb := Vector3(0.55, deck_y, -PIER_LEN + 1.2)
	b.cylinder(0.16, 0.13, 0.28, lb + Vector3(0.35, 0.14, 0.2), Color(0.3, 0.55, 0.9), Basis(), 12)
	b.torus(0.12, 0.2, Vector3(-0.99, deck_y + 0.45, -3.0), Color(1.0, 0.35, 0.35), Basis(Vector3.FORWARD, PI / 2.0))
	b.build(self, Toon.vertex_color(0.01), "Pier")

	var sign := Label3D.new()
	sign.text = "PONTON DE LUC-AEL\nPêche autorisée. Baignade déconseillée."
	sign.font_size = 44
	sign.outline_size = 12
	sign.modulate = Color(1.0, 0.9, 0.5)
	sign.outline_modulate = Color(0.13, 0.08, 0.17)
	sign.pixel_size = 0.0035
	sign.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sign.position = Vector3(1.4, deck_y + 1.6, 1.8)
	add_child(sign)

	# Luc-Ael au bout du ponton, avec sa propre canne
	luc = Talker.new()
	luc.name = "LucAel"
	add_child(luc)
	luc.position = lb
	luc.setup(self, player, Characters.LUCAEL)
	luc.rest_yaw = 0.0
	_give_prop_rod(luc)

	# Pierre sur le sable, à côté du ponton
	pierre = Talker.new()
	pierre.name = "Pierre"
	add_child(pierre)
	var pp := Vector3(-3.2, 0.0, 2.6)
	var gp := to_global(pp)
	pp.y = Island.height(gp.x, gp.z) + 0.02
	pierre.position = pp
	pierre.setup(self, player, _pierre_def())
	pierre.rest_yaw = PI

	menu_p = TalkMenu.new()
	add_child(menu_p)
	menu_p.position = pp + Vector3(1.3, 1.35, 0.9)
	menu_l = TalkMenu.new()
	add_child(menu_l)
	menu_l.position = lb + Vector3(-1.6, 1.35, 0.8)


func _pierre_def() -> Dictionary:
	var d: Dictionary = Characters.PIERRE.duplicate()
	d["towel"] = Save.quest.get("pierre", "none") != "done"
	return d


func _give_prop_rod(t) -> void:
	if Save.quest.get("rod", "none") != "none":
		return
	var holder := Node3D.new()
	holder.name = "PropRod"
	t.chibi.arm_r.add_child(holder)
	holder.position = Vector3(0, -0.29, 0)
	holder.rotation = Vector3(-1.2, 0, 0)
	var b := Builder.new()
	Rod.add(b)
	b.build(holder, Toon.vertex_color(0.006), "RodMesh")


func _remove_prop_rod() -> void:
	var h = luc.chibi.arm_r.get_node_or_null("PropRod")
	if h:
		h.queue_free()


func _name() -> String:
	return Characters.LIST[player.char_id]["name"]


func _say(t, text: String) -> void:
	t.chibi.say(text, 2.5 + text.length() * 0.06)


# --- Boucle -------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if player == null or player.in_dungeon:
		return
	var near_p: bool = player.global_position.distance_to(pierre.global_position) < TALK_DIST
	var near_l: bool = player.global_position.distance_to(luc.global_position) < TALK_DIST
	if near_p and state_p == "closed":
		state_p = "main"
		_idle_p = 0.0
		_say(pierre, brain.pierre_greet(_name()))
		_show_p()
	elif not near_p and state_p != "closed":
		state_p = "closed"
		menu_p.clear()
		Save.save_game()
	if near_l and state_l == "closed":
		state_l = "main"
		_idle_l = 0.0
		_say(luc, brain.luc_greet(_name()))
		_show_l()
	elif not near_l and state_l != "closed":
		state_l = "closed"
		menu_l.clear()
		Save.save_game()
	var cam: Vector3 = player.camera.global_position
	if state_p != "closed":
		menu_p.face(cam)
		_idle_p += delta
		if _idle_p > 18.0:
			_idle_p = 0.0
			_say(pierre, brain.pierre_idle())
	if state_l != "closed":
		menu_l.face(cam)
		_idle_l += delta
		if _idle_l > 22.0:
			_idle_l = 0.0
			_say(luc, brain.luc_idle())
	# Pierre grelotte tant qu'il n'a pas son slip
	pierre.chibi.panic = Save.quest.get("pierre", "none") != "done"


func _show_p() -> void:
	var opts: Array = []
	for o in brain.pierre_options():
		opts.append([o[1], _choose_p.bind(o[0])])
	menu_p.show_options(opts)


func _show_l() -> void:
	var opts: Array = []
	for o in brain.luc_options():
		opts.append([o[1], _choose_l.bind(o[0])])
	menu_l.show_options(opts)


## Mode PC : touches 1 à 6 pour le menu ouvert le plus proche.
func choose(index: int) -> bool:
	if state_l != "closed" and (state_p == "closed" or player.global_position.distance_to(luc.global_position) < player.global_position.distance_to(pierre.global_position)):
		menu_l.choose(index)
		return true
	if state_p != "closed":
		menu_p.choose(index)
		return true
	return false


func is_open() -> bool:
	return state_p != "closed" or state_l != "closed"


func _choose_p(intent: String) -> void:
	_idle_p = 0.0
	var r: Dictionary = brain.pierre_respond(intent)
	_say(pierre, r["text"])
	if r.get("quest_started", false):
		Fx.text(world, pierre.global_position + Vector3(0, 2.2, 0), "Nouvelle quête : le slip de Pierre", Color(0.7, 0.9, 1.0), 0.8, 2.5)
	if r.get("done", false):
		Save.shells += int(r.get("reward", 0))
		Fx.puff(world, pierre.global_position + Vector3(0, 0.6, 0), Color(1.0, 0.8, 0.85))
		pierre.chibi.setup(_pierre_def())
		pierre.chibi.set_bubble_style(0.0024, 760.0, 1.75)
		_say(pierre, r["text"])
		pierre.chibi.pop()
		Fx.text(world, pierre.global_position + Vector3(0, 2.2, 0), "QUÊTE RÉUSSIE !  +%d coquillages" % int(r.get("reward", 0)), Color(1.0, 0.85, 0.25), 1.2, 2.5)
	Save.save_game()
	_show_p()


func _choose_l(intent: String) -> void:
	_idle_l = 0.0
	var r: Dictionary = brain.luc_respond(intent, player.vr)
	_say(luc, r["text"])
	if r.get("lend", false):
		_remove_prop_rod()
		Save.equipped = "rod"
		player.refresh_sword()
		Fx.puff(world, player.global_position + Vector3(0, 1.2, 0), Color(0.8, 0.9, 1.0))
		Fx.text(world, player.global_position + Vector3(0, 2.0, 0), "CANNE À PÊCHE (prêtée)", Color(0.6, 0.85, 1.0), 1.0, 2.0)
		var hint := "Grip pour sortir la canne, gâchette pour lancer" if player.vr else "G pour sortir la canne, clic pour lancer"
		Fx.text(world, menu_l.global_position + Vector3(0, 0.8, 0), hint, Color(1, 1, 1), 0.45, 3.0)
	if r.has("gain"):
		Save.shells += int(r["gain"])
		Fx.text(world, luc.global_position + Vector3(0, 2.1, 0), "+%d coquillages" % int(r["gain"]), Color(1.0, 0.75, 0.85), 0.8)
	Save.save_game()
	_show_l()


func on_bonked(t) -> void:
	Fx.text(world, t.global_position + Vector3(0, 1.9, 0), "BONK !", Color(1.0, 0.5, 0.3), 1.0)
	t.chibi.pop()
	_say(t, brain.pierre_bonked() if t == pierre else brain.luc_bonked())


## Appelé par la pêche après chaque prise.
func on_catch(id: String) -> void:
	if id == "slip":
		Save.quest["rod"] = "owned"
		Save.quest["pierre"] = "found"
		Fx.text(world, player.global_position + Vector3(0, 2.4, 0), "LA CANNE EST À TOI !", Color(0.6, 0.85, 1.0), 1.1, 2.5)
	if player.global_position.distance_to(luc.global_position) < 14.0:
		_say(luc, brain.luc_on_catch(id))
	if id == "slip" and player.global_position.distance_to(pierre.global_position) < 18.0:
		_say(pierre, "C'EST MON SLIP ?! Apporte-le-moi, vite !")
	if state_p != "closed":
		_show_p()
	if state_l != "closed":
		_show_l()
