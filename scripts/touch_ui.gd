extends Control
## Commandes tactiles pour la version téléphone : joystick à gauche, glisser à droite pour
## regarder, un gros bouton ACTION (même rôle que le clic de la souris) et quelques boutons.
## Le viseur (+) au centre désigne ce qu'on touche : boutons, objets, personnages.

var player
var stick_id := -1
var stick_origin := Vector2.ZERO
var stick_pos := Vector2.ZERO
var look_id := -1
var look_t := 0.0
var look_moved := 0.0
var btn_down := {}   # id doigt -> nom du bouton
var held := {}       # nom -> vrai tant que le doigt reste appuyé
var move := Vector2.ZERO
var u := 1.0


func setup(p) -> void:
	player = p
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_PAUSABLE


func _buttons() -> Dictionary:
	var s := get_viewport_rect().size
	u = s.y / 720.0
	var r := 44.0 * u
	var out := {}
	out["ACTION"] = [Vector2(s.x - 110.0 * u, s.y - 120.0 * u), 66.0 * u]
	out["SAUT"] = [Vector2(s.x - 250.0 * u, s.y - 70.0 * u), r]
	out["VUE"] = [Vector2(s.x - 70.0 * u, s.y - 270.0 * u), r * 0.8]
	out["PERSO"] = [Vector2(s.x - 160.0 * u, s.y - 290.0 * u), r * 0.8]
	out["SAC"] = [Vector2(s.x - 70.0 * u, s.y - 360.0 * u), r * 0.8]
	out["E"] = [Vector2(s.x - 160.0 * u, s.y - 380.0 * u), r * 0.7]
	out["F"] = [Vector2(s.x - 250.0 * u, s.y - 380.0 * u), r * 0.7]
	out["R"] = [Vector2(s.x - 250.0 * u, s.y - 290.0 * u), r * 0.7]
	out["G"] = [Vector2(s.x - 340.0 * u, s.y - 380.0 * u), r * 0.7]
	return out


func _button_at(pos: Vector2) -> String:
	var bs := _buttons()
	for k in bs:
		if pos.distance_to(bs[k][0]) <= float(bs[k][1]) * 1.15:
			return k
	return ""


func _input(event: InputEvent) -> void:
	if player == null or get_tree().paused:
		return
	var s := get_viewport_rect().size
	if event is InputEventScreenTouch:
		var pos: Vector2 = event.position
		if event.pressed:
			var b := _button_at(pos)
			if b != "":
				btn_down[event.index] = b
				held[b] = true
				_fire(b)
			elif pos.x < s.x * 0.4 and pos.y > s.y * 0.35 and stick_id < 0:
				stick_id = event.index
				stick_origin = pos
				stick_pos = pos
			elif look_id < 0:
				look_id = event.index
				look_t = 0.0
				look_moved = 0.0
		else:
			if btn_down.has(event.index):
				held.erase(btn_down[event.index])
				btn_down.erase(event.index)
			if event.index == stick_id:
				stick_id = -1
				move = Vector2.ZERO
			if event.index == look_id:
				look_id = -1
				if look_t < 0.25 and look_moved < 18.0 * u:
					_fire("ACTION")
		queue_redraw()
	elif event is InputEventScreenDrag:
		if event.index == stick_id:
			stick_pos = event.position
			var d := (stick_pos - stick_origin) / (70.0 * u)
			move = Vector2(d.x, -d.y).limit_length(1.0)
			if move.length() < 0.12:
				move = Vector2.ZERO
		elif event.index == look_id:
			look_moved += event.relative.length()
			player.touch_look(event.relative)
		queue_redraw()


func _process(delta: float) -> void:
	if look_id >= 0:
		look_t += delta
	player.touch_move = move
	player.touch_jump = held.has("SAUT")


func _fire(name: String) -> void:
	match name:
		"ACTION":
			player.primary_action()
		"VUE":
			player.toggle_view()
		"PERSO":
			player.cycle_character()
		"SAC":
			if player.inventory:
				player.inventory.toggle()
		"E":
			player._desktop_swap()
		"F":
			player.emote()
		"R":
			player.touch_eat()
		"G":
			player._toggle_desk_sword()


func _draw() -> void:
	var f := ThemeDB.fallback_font
	var s := get_viewport_rect().size
	u = s.y / 720.0
	# Joystick
	var base := Vector2(130.0 * u, s.y - 130.0 * u)
	var knob := base
	if stick_id >= 0:
		base = stick_origin
		knob = base + (stick_pos - stick_origin).limit_length(70.0 * u)
	draw_circle(base, 70.0 * u, Color(1, 1, 1, 0.12))
	draw_arc(base, 70.0 * u, 0.0, TAU, 32, Color(1, 1, 1, 0.45), 3.0)
	draw_circle(knob, 30.0 * u, Color(1, 1, 1, 0.4))
	# Boutons
	var bs := _buttons()
	for k in bs:
		var c: Vector2 = bs[k][0]
		var r: float = bs[k][1]
		var col := Color(1.0, 0.8, 0.9, 0.5) if k == "ACTION" else Color(0.8, 0.9, 1.0, 0.35)
		if held.has(k):
			col.a = 0.8
		draw_circle(c, r, col)
		draw_arc(c, r, 0.0, TAU, 32, Color(1, 1, 1, 0.6), 2.5)
		var label: String = {"ACTION": "ACTION", "SAUT": "SAUT", "VUE": "VUE", "PERSO": "PERSO", "SAC": "SAC", "E": "ÉCHANGE", "F": "RÉPLIQUE", "R": "MANGER", "G": "OUTIL"}[k]
		var fs := int(18.0 * u) if k == "ACTION" else int(13.0 * u)
		var sz := f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		draw_string(f, c + Vector2(-sz.x * 0.5, fs * 0.35), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.1, 0.05, 0.2, 0.95))
