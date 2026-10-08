extends CharacterBody3D
## Le joueur. En VR : casque + deux mains. Sans casque (PC) : clavier/souris.
## Deux vues : 1re personne (tu ES le perso) et 3e personne (tu vois ton
## chibi et tu le diriges). Échange de corps avec les autres persos.

const Chibi := preload("res://scripts/chibi.gd")
const Characters := preload("res://scripts/characters.gd")
const Hand := preload("res://scripts/hand.gd")
const Fx := preload("res://scripts/fx.gd")
const Island := preload("res://scripts/island.gd")
const Save := preload("res://scripts/save.gd")
const Items := preload("res://scripts/shop_items.gd")
const Sword := preload("res://scripts/sword.gd")
const Builder := preload("res://scripts/builder.gd")
const Toon := preload("res://scripts/toon.gd")
const Rod := preload("res://scripts/rod.gd")
const Fishing := preload("res://scripts/fishing.gd")
const InventoryPanel := preload("res://scripts/inventory_panel.gd")

const SPEED := 3.0
const JUMP := 4.2
const GRAVITY := 9.8
const DESKTOP_EYE := 1.2

var vr := false
var world: Node3D
var origin: XROrigin3D
var camera: XRCamera3D
var left
var right
var avatar
var char_id := 0
var third_person := false
var _tp_back := Vector3.ZERO
var npcs: Array = []
var shop
var gate
var dungeon
var main
var shore
var village
var pico
var fishing
var inventory

# Donjon et combat
const MAX_HEARTS := 5
var hearts := MAX_HEARTS
var in_dungeon := false
var _invuln := 0.0
var _knock := Vector3.ZERO
var _desk_sword: Node3D
var _desk_sword_out := false
var _swinging := false

# Effets de nourriture (secondes restantes)
var effects := {}
var _counter_t := 0.0
var _desk_target

var _vy := 0.0
var _in_water := false
var _snap_ready := true
var _prev := {}
var _held_desktop: RigidBody3D
var _spawn := Vector3.ZERO
var _hud: Label
var _hud_counter: Label


func setup(p_world: Node3D, p_vr: bool) -> void:
	world = p_world
	vr = p_vr
	_spawn = global_position
	collision_layer = 8
	collision_mask = 1 | 4 | 32
	floor_snap_length = 0.35
	floor_max_angle = deg_to_rad(50.0)
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.25
	cap.height = 1.2
	cs.shape = cap
	cs.position.y = 0.6
	add_child(cs)

	avatar = Chibi.new()
	add_child(avatar)

	origin = XROrigin3D.new()
	origin.name = "XROrigin"
	world.add_child(origin)
	origin.global_transform = global_transform
	camera = XRCamera3D.new()
	camera.near = 0.05
	camera.far = 500.0
	origin.add_child(camera)
	left = Hand.new()
	left.name = "LeftHand"
	origin.add_child(left)
	left.setup(self, true)
	right = Hand.new()
	right.name = "RightHand"
	origin.add_child(right)
	right.setup(self, false)

	if not vr:
		camera.position = Vector3(0, DESKTOP_EYE, 0)
		camera.current = true
		_make_hud()

	set_character(0)
	_place_origin(true, 0.0)


func set_character(id: int) -> void:
	char_id = id
	var def: Dictionary = Characters.LIST[id]
	avatar.setup(def)
	left.set_colors(def["skin"], def["shirt"])
	right.set_colors(def["skin"], def["shirt"])
	_update_view()


func toggle_view() -> void:
	third_person = not third_person
	_update_view()
	_place_origin(true, 0.0)
	Fx.text(world, _front(1.6), "Vue 3e personne" if third_person else "Vue 1re personne", Color(0.7, 0.9, 1.0), 0.45, 0.9)


func _update_view() -> void:
	avatar.visible = third_person


## Échange de corps avec un habitant. teleport = on prend aussi sa place.
func swap_with(npc, teleport: bool) -> void:
	var my_id := char_id
	var their_id: int = npc.char_id
	var my_pos := global_position
	var their_pos: Vector3 = npc.global_position
	Fx.puff(world, my_pos + Vector3(0, 0.7, 0))
	Fx.puff(world, their_pos + Vector3(0, 0.7, 0))
	if teleport:
		npc.global_position = my_pos
		global_position = their_pos
		_vy = 0.0
	npc.set_char(my_id)
	set_character(their_id)
	_place_origin(true, 0.0)
	Fx.text(world, their_pos + Vector3(0, 1.7, 0) if teleport else my_pos + Vector3(0, 1.7, 0), "POUF !", Color(1.0, 0.85, 0.25), 1.2)
	npc.chibi.say(Characters.SWAP_REACTIONS[randi() % Characters.SWAP_REACTIONS.size()], 3.0)
	npc.chibi.pop()
	avatar.pop()
	if pico:
		pico.on_swap()
	var name_txt: String = Characters.LIST[their_id]["name"]
	Fx.text(world, _front(1.8) + Vector3(0, 0.3, 0), "Tu es " + name_txt + " !", Color(1, 1, 1), 0.6, 1.4)


func cycle_character() -> void:
	var next := (char_id + 1) % Characters.LIST.size()
	for n in npcs:
		if n.char_id == next:
			swap_with(n, false)
			return


func emote() -> void:
	var lines: Array = Characters.LIST[char_id]["lines"]
	var l: String = lines[randi() % lines.size()]
	if third_person:
		avatar.say(l)
	else:
		Fx.text(world, _front(1.4) + Vector3(0, 0.1, 0), l, Color(1, 1, 1), 0.35, 2.5)


func _front(dist: float) -> Vector3:
	var f := -camera.global_basis.z
	f.y = 0.0
	if f.length() < 0.01:
		f = Vector3.FORWARD
	return camera.global_position + f.normalized() * dist


# ---------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if origin == null:
		return
	var input := _move_input()
	var fwd := -camera.global_basis.z
	fwd.y = 0.0
	fwd = fwd.normalized() if fwd.length() > 0.01 else Vector3.FORWARD
	var side := camera.global_basis.x
	side.y = 0.0
	side = side.normalized() if side.length() > 0.01 else Vector3.RIGHT
	var speed_mult := 1.9 if effects.has("speed") else 1.0
	var move := (side * input.x + fwd * input.y) * SPEED * speed_mult * (0.55 if _in_water else 1.0)
	var grav := GRAVITY * (0.22 if effects.has("helium") else 1.0)
	var jump := JUMP * (1.5 if effects.has("helium") else 1.0)

	if is_on_floor():
		_vy = maxf(_vy, -0.5)
		if _jump_pressed():
			_vy = jump
			if third_person:
				avatar.pop()
	else:
		_vy -= grav * delta

	# En 1re personne, les pas réels dans la pièce déplacent aussi le corps
	var phys := Vector3.ZERO
	if vr and not third_person:
		phys = camera.global_position - global_position
		phys.y = 0.0
		if phys.length() > 1.5:
			phys = Vector3.ZERO
	_invuln = maxf(_invuln - delta, 0.0)
	velocity = Vector3(move.x + phys.x / delta + _knock.x, _vy, move.z + phys.z / delta + _knock.z)
	_knock = _knock.lerp(Vector3.ZERO, clampf(delta * 6.0, 0.0, 1.0))
	move_and_slide()
	_vy = velocity.y

	# Animation du chibi
	var speed_ratio := Vector2(move.x, move.z).length() / SPEED
	_tick_effects(delta)
	avatar.walk = lerpf(avatar.walk, clampf(speed_ratio, 0.0, 1.0), clampf(delta * 8.0, 0.0, 1.0))
	if move.length() > 0.1:
		avatar.rotation.y = lerp_angle(avatar.rotation.y, atan2(-move.x, -move.z), clampf(delta * 10.0, 0.0, 1.0))

	# Eau
	var wet := global_position.y < -0.15
	if wet and not _in_water:
		Fx.text(world, global_position + Vector3(0, 1.2, 0), "PLOUF !", Color(0.5, 0.85, 1.0), 1.0)
		Fx.puff(world, global_position + Vector3(0, 0.2, 0), Color(0.75, 0.92, 1.0))
	_in_water = wet
	avatar.panic = wet or effects.has("speed")

	# On ne part pas à la nage jusqu'au continent
	var flat := Vector2(global_position.x, global_position.z)
	if flat.length() > 74.0:
		flat = flat.normalized() * 74.0
		global_position.x = flat.x
		global_position.z = flat.y
	if global_position.y < -15.0:
		global_position = _spawn
		_vy = 0.0

	_place_origin(false, delta)
	_turning(delta)
	_buttons()
	if _held_desktop:
		var f := -camera.global_basis.z
		_held_desktop.global_position = camera.global_position + f * 0.9 - camera.global_basis.y * 0.25
	if not vr:
		_desktop_hover()
		if fishing and _desk_sword and _desk_sword_out and tool_kind() == "rod":
			fishing.tip = _desk_sword.to_global(Rod.TIP)
	_counter_t -= delta
	if _counter_t <= 0.0:
		_counter_t = 0.3
		_update_counter()


func _place_origin(instant: bool, delta: float) -> void:
	if third_person:
		if instant or _tp_back == Vector3.ZERO:
			# On se place derrière le perso dans la direction où l'on REGARDE (pas celle de la pièce)
			var back := camera.global_basis.z
			back.y = 0.0
			_tp_back = back.normalized() if back.length() > 0.01 else Vector3.BACK
		var back := _tp_back
		var cam_off := camera.global_position - origin.global_position
		cam_off.y = 0.0
		var target := global_position + back * 2.8 + Vector3(0, 0.9, 0) - cam_off
		if instant:
			origin.global_position = target
		else:
			origin.global_position = origin.global_position.lerp(target, clampf(delta * 6.0, 0.0, 1.0))
	else:
		var off := global_position - camera.global_position
		off.y = 0.0
		origin.global_position += off
		origin.global_position.y = global_position.y
		if not vr:
			origin.global_position.y = global_position.y


func _rotate_origin(angle: float) -> void:
	var pivot := global_position if third_person else camera.global_position
	if third_person:
		_tp_back = _tp_back.rotated(Vector3.UP, angle)
	var t := origin.global_transform
	t.origin -= pivot
	t = Transform3D(Basis(Vector3.UP, angle), Vector3.ZERO) * t
	t.origin += pivot
	origin.global_transform = t


func _turning(delta: float) -> void:
	if not vr:
		return
	# Clic du stick droit : bascule entre rotation douce et rotation par à-coups
	if _edge("turnmode", right.is_button_pressed("primary_click")):
		Save.story["snap_turn"] = not Save.story.get("snap_turn", false)
		Save.save_game()
		Fx.text(world, _front(1.6), "Rotation par à-coups" if Save.story["snap_turn"] else "Rotation douce", Color(0.8, 0.95, 1.0), 0.45, 1.2)
	var x: float = right.get_vector2("primary").x
	if Save.story.get("snap_turn", false):
		if _snap_ready and absf(x) > 0.7:
			_snap_ready = false
			_rotate_origin(-signf(x) * deg_to_rad(45.0))
		elif absf(x) < 0.3:
			_snap_ready = true
	elif absf(x) > 0.2:
		_rotate_origin(-x * deg_to_rad(110.0) * delta)


# --- Entrées ----------------------------------------------------------------

func _move_input() -> Vector2:
	var v := Vector2.ZERO
	if vr:
		var s: Vector2 = left.get_vector2("primary")
		if s.length() > 0.15:
			v = s
	else:
		if _key(KEY_W) or _key(KEY_Z) or _key(KEY_UP):
			v.y += 1.0
		if _key(KEY_S) or _key(KEY_DOWN):
			v.y -= 1.0
		if _key(KEY_A) or _key(KEY_Q) or _key(KEY_LEFT):
			v.x -= 1.0
		if _key(KEY_D) or _key(KEY_RIGHT):
			v.x += 1.0
	return v.limit_length(1.0)


func _key(k: Key) -> bool:
	return Input.is_physical_key_pressed(k) or Input.is_key_pressed(k)


func _edge(id: String, now: bool) -> bool:
	var was: bool = _prev.get(id, false)
	_prev[id] = now
	return now and not was


func _jump_pressed() -> bool:
	if vr:
		return _edge("jump", right.is_button_pressed("ax_button"))
	return _edge("jump", _key(KEY_SPACE))


func _buttons() -> void:
	if not vr:
		return
	if _edge("view", right.is_button_pressed("by_button")):
		toggle_view()
	if _edge("cycle", left.is_button_pressed("ax_button")):
		cycle_character()
	if _edge("emote", left.is_button_pressed("by_button")):
		emote()
	if _edge("bag", left.is_button_pressed("menu_button") or left.is_button_pressed("primary_click")):
		if inventory:
			inventory.toggle()


func _unhandled_input(event: InputEvent) -> void:
	if vr:
		return
	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if _desk_target and is_instance_valid(_desk_target):
				_desk_target.press()
			elif _desk_sword_out and tool_kind() == "rod":
				fishing.action(_desk_sword.to_global(Rod.TIP), -camera.global_basis.z)
			elif _desk_sword_out:
				_desk_swing()
			else:
				_desktop_grab()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_rotate_origin(-event.relative.x * 0.003)
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * 0.003, -1.3, 1.3)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ESCAPE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			KEY_V:
				toggle_view()
			KEY_C, KEY_TAB:
				cycle_character()
			KEY_E:
				_desktop_swap()
			KEY_F:
				emote()
			KEY_H:
				if _hud:
					_hud.visible = not _hud.visible
			KEY_R:
				if _held_desktop and _held_desktop.get("is_food"):
					var rb := _held_desktop
					_held_desktop = null
					eat(rb)
			KEY_I:
				if inventory:
					inventory.toggle()
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7:
				if inventory and inventory.is_open:
					inventory.choose(event.physical_keycode - KEY_1)
				elif shop and shop.state != "closed":
					shop.choose(event.physical_keycode - KEY_1)
				elif gate and gate.state != "closed":
					gate.choose(event.physical_keycode - KEY_1)
				elif shore and shore.is_open():
					shore.choose(event.physical_keycode - KEY_1)
				elif village and village.is_open():
					village.choose(event.physical_keycode - KEY_1)
			KEY_G:
				_toggle_desk_sword()


func _desktop_grab() -> void:
	if _held_desktop:
		var rb := _held_desktop
		_held_desktop = null
		rb.freeze = false
		rb.linear_velocity = -camera.global_basis.z * 9.0 + Vector3.UP * 2.0
		if rb.has_method("on_release"):
			rb.on_release()
		return
	var best: RigidBody3D = null
	var best_d := 2.8
	var f := -camera.global_basis.z
	for n in get_tree().get_nodes_in_group("grab"):
		var rb := n as RigidBody3D
		var to := rb.global_position - camera.global_position
		if to.length() < best_d and to.normalized().dot(f) > 0.6:
			best_d = to.length()
			best = rb
	if best:
		_held_desktop = best
		best.freeze = true
		if best.has_method("on_grab"):
			best.on_grab()


func _desktop_swap() -> void:
	var from := camera.global_position
	var q := PhysicsRayQueryParameters3D.create(from, from - camera.global_basis.z * 14.0, 1 | 4 | 16)
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return
	var c = hit["collider"]
	if c.has_method("press"):
		c.press()
	elif c.has_method("set_char"):
		swap_with(c, true)


func _make_hud() -> void:
	var layer := CanvasLayer.new()
	world.add_child(layer)
	_hud = Label.new()
	_hud.text = "Pas de casque détecté : mode PC\nZQSD / WASD : bouger · Souris : regarder (clic pour la capturer)\nEspace : sauter · V : vue 1re/3e · C : changer de perso\nE : échange de corps avec le perso visé · Clic : attraper / lancer\nF : réplique · R : manger ce qu'on tient · 1 à 6 : choisir dans un menu\nG : sortir l'épée ou la canne (clic pour frapper / lancer) · I : sac · H : cacher l'aide · Échap : libérer la souris"
	_hud.position = Vector2(16, 12)
	_hud.add_theme_color_override("font_color", Color(1, 1, 1))
	_hud.add_theme_color_override("font_outline_color", Color(0.13, 0.08, 0.17))
	_hud.add_theme_constant_override("outline_size", 6)
	_hud.add_theme_font_size_override("font_size", 18)
	layer.add_child(_hud)
	_hud_counter = Label.new()
	_hud_counter.position = Vector2(16, 175)
	_hud_counter.add_theme_color_override("font_color", Color(1.0, 0.8, 0.85))
	_hud_counter.add_theme_color_override("font_outline_color", Color(0.13, 0.08, 0.17))
	_hud_counter.add_theme_constant_override("outline_size", 6)
	_hud_counter.add_theme_font_size_override("font_size", 22)
	layer.add_child(_hud_counter)
	var cross := Label.new()
	cross.text = "+"
	cross.add_theme_font_size_override("font_size", 28)
	cross.set_anchors_preset(Control.PRESET_CENTER)
	cross.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(cross)


# --- Boutique, objets tenus, nourriture ---------------------------------------

func held_item() -> RigidBody3D:
	if right and right.held:
		return right.held
	if left and left.held:
		return left.held
	return _held_desktop


func held_kind() -> String:
	var rb := held_item()
	if rb == null:
		return ""
	return str(rb.get("kind"))


func release_item(rb: RigidBody3D) -> void:
	if right.held == rb:
		right.drop()
	if left.held == rb:
		left.drop()
	if _held_desktop == rb:
		_held_desktop = null
	rb.freeze = false


func on_shell() -> void:
	if vr:
		left.trigger_haptic_pulse("haptic", 0.0, 0.3, 0.05, 0.0)


func eat(rb: RigidBody3D) -> void:
	var kind := str(rb.get("kind"))
	var effect := Items.food_effect(kind)
	Fx.text(world, _front(1.2) + Vector3(0, 0.2, 0), "MIAM !", Color(1.0, 0.8, 0.3), 0.8)
	rb.queue_free()
	if effect != "":
		apply_effect(effect)


func apply_effect(effect: String) -> void:
	effects[effect] = 30.0
	match effect:
		"big_head":
			avatar.big_head = true
			Fx.text(world, _front(1.6) + Vector3(0, 0.4, 0), "GROSSE TÊTE !", Color(1.0, 0.6, 0.9), 0.9, 1.5)
		"speed":
			Fx.text(world, _front(1.6) + Vector3(0, 0.4, 0), "CHAUUUD !", Color(1.0, 0.4, 0.2), 1.0, 1.5)
		"helium":
			Fx.text(world, _front(1.6) + Vector3(0, 0.4, 0), "Voix de souris ! Saute !", Color(0.7, 0.9, 1.0), 0.8, 1.5)


func _tick_effects(delta: float) -> void:
	for k in effects.keys():
		effects[k] -= delta
		if effects[k] <= 0.0:
			effects.erase(k)
			if k == "big_head":
				avatar.big_head = false
			Fx.text(world, _front(1.6), "Effet terminé", Color(1, 1, 1), 0.4, 1.0)


func _update_counter() -> void:
	var txt := "Coquillages : %d" % Save.shells
	if in_dungeon or hearts < MAX_HEARTS:
		txt += "\nVie : %d / %d" % [hearts, MAX_HEARTS]
	for k in effects:
		txt += "\n%s : %ds" % [{"big_head": "Grosse tête", "speed": "Turbo", "helium": "Hélium"}.get(k, k), int(effects[k])]
	if vr:
		left.set_counter(txt)
	elif _hud_counter:
		_hud_counter.text = txt


func _desktop_hover() -> void:
	var from := camera.global_position
	var q := PhysicsRayQueryParameters3D.create(from, from - camera.global_basis.z * 6.0, 1 | 16)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var t = null
	if not hit.is_empty() and hit["collider"].has_method("press"):
		t = hit["collider"]
	if t != _desk_target:
		if _desk_target and is_instance_valid(_desk_target):
			_desk_target.set_hover(false)
		_desk_target = t
		if t:
			t.set_hover(true)


# --- Donjon, épée, combat -------------------------------------------------------

func has_sword() -> bool:
	return Save.sword > 0


## Reconstruit l'épée (dans les mains VR et pour le mode PC).
func refresh_sword() -> void:
	left.refresh_sword()
	right.refresh_sword()
	if _desk_sword:
		_desk_sword.queue_free()
		_desk_sword = null
	if not vr and tool_kind() != "":
		_desk_sword = Node3D.new()
		camera.add_child(_desk_sword)
		var b := Builder.new()
		if tool_kind() == "rod":
			Rod.add(b)
		else:
			Sword.add(b, Save.sword)
		b.build(_desk_sword, Toon.vertex_color(0.006), "Tool")
		_desk_sword.position = Vector3(0.32, -0.32, -0.55)
		_desk_sword.rotation = Vector3(-0.5, 0.0, -0.35)
		_desk_sword.visible = _desk_sword_out
	if fishing and tool_kind() != "rod":
		fishing.cancel()


## Ce que le grip (ou G) fait sortir : "sword", "rod" ou "".
func tool_kind() -> String:
	var has_rod: bool = Save.quest.get("rod", "none") != "none"
	if Save.equipped == "rod" and has_rod:
		return "rod"
	if Save.sword > 0:
		return "sword"
	if has_rod:
		return "rod"
	return ""


## Met un objet (sorti du sac) directement dans la main.
func hold_new(rb: RigidBody3D) -> void:
	if vr:
		right.drop()
		right.held = rb
		rb.freeze = true
		rb.set_meta("held_by", right)
		rb.global_position = right.global_position
		right.hold_offset = right.global_transform.affine_inverse() * rb.global_transform
	else:
		_held_desktop = rb
		rb.freeze = true


## Ça mord ! Les manettes vibrent.
func fishing_bite() -> void:
	if vr:
		for h in [left, right]:
			if h.sword_out and h.tool_kind == "rod":
				h.trigger_haptic_pulse("haptic", 0.0, 1.0, 0.4, 0.0)


func _toggle_desk_sword() -> void:
	if tool_kind() == "":
		Fx.text(world, _front(1.4), "Rien à sortir ! Va voir Riku ou Luc-Ael.", Color(1, 0.7, 0.7), 0.5, 1.2)
		return
	_desk_sword_out = not _desk_sword_out
	if _desk_sword == null:
		refresh_sword()
	_desk_sword.visible = _desk_sword_out
	if not _desk_sword_out and fishing:
		fishing.cancel()


func _desk_swing() -> void:
	if _swinging or _desk_sword == null:
		return
	_swinging = true
	var tw := create_tween()
	tw.tween_property(_desk_sword, "rotation", Vector3(-1.4, 0.4, 0.9), 0.12)
	tw.tween_callback(_desk_hit)
	tw.tween_property(_desk_sword, "rotation", Vector3(-0.5, 0.0, -0.35), 0.18)
	tw.tween_callback(func(): _swinging = false)


func _desk_hit() -> void:
	var f := -camera.global_basis.z
	for m in get_tree().get_nodes_in_group("monster"):
		var to: Vector3 = m.center() - camera.global_position
		var reach: float = 2.3 + m.radius
		if to.length() < reach and to.normalized().dot(f) > 0.45:
			m.hit(Sword.DAMAGE[Save.sword], global_position)


func hurt(dmg: int, from: Vector3) -> void:
	if _invuln > 0.0 or not in_dungeon:
		return
	_invuln = 1.0
	hearts -= dmg
	var away := global_position - from
	away.y = 0.0
	_knock = away.normalized() * 6.0
	_vy = 2.5
	Fx.text(world, _front(1.0) + Vector3(0, 0.1, 0), "AÏE ! -%d" % dmg, Color(1.0, 0.35, 0.35), 0.8, 0.8)
	if vr:
		left.trigger_haptic_pulse("haptic", 0.0, 1.0, 0.25, 0.0)
		right.trigger_haptic_pulse("haptic", 0.0, 1.0, 0.25, 0.0)
	avatar.pop()
	if hearts <= 0:
		Save.dungeon["deaths"] = int(Save.dungeon["deaths"]) + 1
		Save.save_game()
		exit_dungeon(true)


func enter_dungeon() -> void:
	if dungeon == null:
		return
	in_dungeon = true
	hearts = MAX_HEARTS
	if fishing:
		fishing.cancel()
	if inventory and inventory.is_open:
		inventory.close()
	Fx.puff(world, global_position + Vector3(0, 1.0, 0), Color(0.6, 1.0, 0.7))
	global_position = dungeon.start_position()
	_vy = 0.0
	_face_yaw(0.0)
	_place_origin(true, 0.0)
	dungeon.on_enter()
	if main:
		main.set_dungeon_mood(true)
	Fx.text(world, _front(2.2) + Vector3(0, 0.5, 0), "DONJON DES BOULETTES", Color(0.6, 1.0, 0.6), 1.2, 2.5)


func exit_dungeon(ko: bool) -> void:
	in_dungeon = false
	hearts = MAX_HEARTS
	effects.erase("speed")
	if gate:
		global_position = gate.exit_position()
		_face_yaw(gate.global_rotation.y + PI)
	_vy = 0.0
	_place_origin(true, 0.0)
	if main:
		main.set_dungeon_mood(false)
	if ko:
		Fx.text(world, _front(2.0) + Vector3(0, 0.6, 0), "K.O. !", Color(1.0, 0.4, 0.4), 1.6, 2.0)
		if gate:
			gate.on_player_ko()
	else:
		Fx.text(world, _front(2.0) + Vector3(0, 0.6, 0), "Retour à l'air libre !", Color(1.0, 0.9, 0.5), 0.8, 1.5)
	Save.save_game()


## Tourne la vue pour regarder dans la direction yaw (0 = vers -Z).
func _face_yaw(yaw: float) -> void:
	var f := -camera.global_basis.z
	f.y = 0.0
	if f.length() < 0.01:
		return
	var cur := atan2(-f.x, -f.z)
	_rotate_origin(yaw - cur)
	avatar.rotation.y = yaw
