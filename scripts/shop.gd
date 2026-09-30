extends Node3D
## La Boutique Kawaii : bâtiment, étagères, Yuki la vendeuse, et le menu de
## choix flottant. Le "cerveau" de Yuki est dans vendor_brain.gd.

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Island := preload("res://scripts/island.gd")
const Fx := preload("res://scripts/fx.gd")
const Save := preload("res://scripts/save.gd")
const Items := preload("res://scripts/shop_items.gd")
const Hats := preload("res://scripts/hats.gd")
const Props := preload("res://scripts/props.gd")
const Characters := preload("res://scripts/characters.gd")
const Brain := preload("res://scripts/vendor_brain.gd")
const Vendor := preload("res://scripts/vendor.gd")
const ChoiceButton := preload("res://scripts/choice_button.gd")

const FL := 0.03
const WH := 3.0
const T := 0.2
const PER_PAGE := 3

var world: Node3D
var player
var brain := Brain.new()
var vendor
var menu_root: Node3D
var header: Label3D
var buttons: Array = []
var state := "closed"
var page := 0
var _idle := 0.0
var _save_t := 0.0


func build(p_world: Node3D, p_player) -> void:
	world = p_world
	player = p_player
	var d := Island.shop_dir()
	position = Vector3(Island.SHOP_POS.x, Island.SHOP_H, Island.SHOP_POS.y)
	rotation.y = atan2(d.x, d.y)

	var b := Builder.new()
	_building(b)
	_furniture(b)
	b.build(self, Toon.vertex_color(), "Shop")
	var deco := Builder.new()
	_displays(deco)
	deco.build(self, Toon.vertex_color(0.006), "Displays")
	_signs()
	_lights()

	vendor = Vendor.new()
	vendor.name = "Yuki"
	add_child(vendor)
	vendor.position = Vector3(0, FL + 0.35, -1.75)
	vendor.setup(self, player)

	menu_root = Node3D.new()
	menu_root.name = "Menu"
	add_child(menu_root)
	menu_root.position = Vector3(1.55, FL + 1.5, 0.2)
	header = Label3D.new()
	header.font_size = 36
	header.pixel_size = 0.0024
	header.outline_size = 10
	header.outline_modulate = Color(0.13, 0.08, 0.17)
	header.modulate = Color(1.0, 0.9, 0.5)
	header.position = Vector3(0, 0.34, 0)
	header.visible = false
	menu_root.add_child(header)


# --- Construction -----------------------------------------------------------

func _building(b: Builder) -> void:
	var mint := Color(0.72, 0.93, 0.86)
	var pink := Color(1.0, 0.62, 0.72)
	b.box(Vector3(7.8, 1.2, 6.8), Vector3(0, FL - 0.7, 0), Color(0.72, 0.66, 0.64))
	b.box(Vector3(7.4, 0.2, 6.4), Vector3(0, FL - 0.1, 0), Color(0.96, 0.82, 0.66))
	# Damier au sol
	for i in 6:
		for j in 5:
			if (i + j) % 2 == 0:
				b.box(Vector3(1.1, 0.012, 1.1), Vector3(-2.75 + i * 1.1, FL + 0.006, -2.4 + j * 1.1), Color(1.0, 0.9, 0.8), false)
	b.box(Vector3(7.4, WH, T), Vector3(0, FL + WH * 0.5, -3.1), mint)
	for sx in [-1.0, 1.0]:
		var x: float = sx * 3.6
		b.box(Vector3(T, WH, 2.2), Vector3(x, FL + WH * 0.5, -2.0), mint)
		b.box(Vector3(T, WH, 2.0), Vector3(x, FL + WH * 0.5, 2.0), mint)
		b.box(Vector3(T, 1.1, 2.0), Vector3(x, FL + 0.55, 0.0), mint)
		b.box(Vector3(T, WH - 2.2, 2.0), Vector3(x, FL + 2.2 + (WH - 2.2) * 0.5, 0.0), mint)
		b.box(Vector3(0.35, WH, 0.35), Vector3(sx * 3.45, FL + WH * 0.5, 3.05), pink)
	b.box(Vector3(7.4, 0.5, 0.25), Vector3(0, FL + WH - 0.25, 3.05), pink)
	b.box(Vector3(8.0, 0.25, 7.0), Vector3(0, FL + WH + 0.12, 0), pink)
	b.box(Vector3(7.4, 0.08, 6.4), Vector3(0, FL + WH - 0.04, 0), Color(1, 0.97, 0.95), false)
	# Auvent rayé
	for k in 8:
		var col := pink if k % 2 == 0 else Color.WHITE
		b.box(Vector3(1.0, 0.05, 1.4), Vector3(-3.5 + k * 1.0, FL + 2.72, 3.75), col, false, Basis(Vector3.RIGHT, 0.35))
	# Petit toit en forme de gâteau
	b.cylinder(1.4, 1.6, 0.5, Vector3(0, FL + WH + 0.5, -1.0), Color(1.0, 0.95, 0.9), Basis(), 16)
	b.sphere(0.35, Vector3(0, FL + WH + 0.95, -1.0), Color(0.95, 0.2, 0.3))
	b.box(Vector3(2.2, 0.06, 1.4), Vector3(0, FL - 0.03, 3.9), Color(0.85, 0.65, 0.5))


func _furniture(b: Builder) -> void:
	var pink := Color(1.0, 0.62, 0.72)
	# Comptoir
	b.box(Vector3(3.6, 0.95, 0.7), Vector3(0, FL + 0.475, -0.7), pink)
	b.box(Vector3(3.8, 0.06, 0.82), Vector3(0, FL + 0.98, -0.7), Color(0.72, 0.5, 0.32))
	for k in 5:
		b.sphere(0.09, Vector3(-1.4 + k * 0.7, FL + 0.55, -0.34), Color(1, 1, 1), Vector3(1, 1, 0.3))
	# Tabouret-estrade de Yuki
	b.box(Vector3(1.4, 0.35, 1.1), Vector3(0, FL + 0.175, -1.75), Color(0.72, 0.5, 0.32))
	# Caisse enregistreuse
	b.box(Vector3(0.42, 0.26, 0.32), Vector3(-1.2, FL + 1.14, -0.8), Color(0.6, 0.85, 1.0), false)
	b.box(Vector3(0.36, 0.12, 0.08), Vector3(-1.2, FL + 1.3, -0.9), Color(0.2, 0.25, 0.3), false, Basis(Vector3.RIGHT, -0.5))
	# Bocal de coquillages
	b.cylinder(0.11, 0.11, 0.24, Vector3(-0.6, FL + 1.13, -0.75), Color(0.85, 0.95, 1.0), Basis(), 12)
	for k in 4:
		b.sphere(0.05, Vector3(-0.6 + (k % 2) * 0.05 - 0.025, FL + 1.06 + k * 0.035, -0.75), Color(1.0, 0.72, 0.75), Vector3(1, 0.5, 1), Basis(), 8)
	# Chat porte-bonheur qui fait coucou
	var w := Color(1, 1, 1)
	b.sphere(0.13, Vector3(1.3, FL + 1.13, -0.8), w, Vector3(1, 1.1, 0.9))
	b.sphere(0.11, Vector3(1.3, FL + 1.34, -0.8), w)
	b.capsule(0.035, 0.16, Vector3(1.41, FL + 1.38, -0.8), w, Basis(Vector3.FORWARD, -0.3))
	for sx in [-1.0, 1.0]:
		b.prism(Vector3(0.06, 0.07, 0.03), Vector3(1.3 + sx * 0.06, FL + 1.45, -0.8), w, Basis(Vector3.FORWARD, -sx * 0.3))
		b.sphere(0.013, Vector3(1.3 + sx * 0.04, FL + 1.35, -0.9), Color(0.13, 0.08, 0.17), Vector3.ONE, Basis(), 6)
	b.sphere(0.03, Vector3(1.3, FL + 1.1, -0.92), Color(1.0, 0.8, 0.2), Vector3(1, 1, 0.4))
	# Étagères du fond
	for y in [0.85, 1.6, 2.35]:
		b.box(Vector3(6.8, 0.06, 0.5), Vector3(0, FL + y, -2.75), Color(0.72, 0.5, 0.32))
	for x in [-3.3, -1.1, 1.1, 3.3]:
		b.box(Vector3(0.06, 2.4, 0.5), Vector3(x, FL + 1.2, -2.75), Color(0.6, 0.4, 0.26), false)
	# Tonneau et caisse sur les côtés
	b.cylinder(0.4, 0.35, 0.8, Vector3(2.8, FL + 0.4, 1.8), Color(0.6, 0.4, 0.26), Basis(), 14)
	b.box(Vector3(0.9, 0.5, 0.7), Vector3(-2.8, FL + 0.25, 1.8), Color(0.8, 0.6, 0.4))


func _displays(b: Builder) -> void:
	var hats := ["paille", "casquette", "lapin", "sorcier", "couronne"]
	for k in hats.size():
		Hats.add(b, hats[k], Vector3(-2.6 + k * 1.3, FL + 2.39, -2.75), 0.75)
	var foods := ["glace", "ramen", "bonbon", "glace", "ramen", "bonbon"]
	for k in foods.size():
		var y := 1.75 if foods[k] == "glace" else 1.68
		Props.paint(b, foods[k], Transform3D(Basis(), Vector3(-2.8 + k * 1.1, FL + y, -2.7)))
	var objs := ["chicken", "canard", "chicken", "canard", "chicken"]
	for k in objs.size():
		Props.paint(b, objs[k], Transform3D(Basis(Vector3.UP, PI), Vector3(-2.6 + k * 1.3, FL + 0.98, -2.7)))
	for k in 3:
		Props.paint(b, "ball", Transform3D(Basis().scaled(Vector3.ONE * 0.5), Vector3(2.8 + (k - 1) * 0.2, FL + 0.95 + (k % 2) * 0.1, 1.8 + (k % 2) * 0.12)))
	for k in 3:
		Props.paint(b, "chicken", Transform3D(Basis(Vector3.UP, k * 1.2), Vector3(-2.95 + k * 0.25, FL + 0.6, 1.8)))


func _signs() -> void:
	var ink := Color(0.13, 0.08, 0.17)
	var title := Label3D.new()
	title.text = "BOUTIQUE KAWAII"
	title.font_size = 96
	title.outline_size = 24
	title.modulate = Color(1.0, 0.45, 0.65)
	title.outline_modulate = Color.WHITE
	title.pixel_size = 0.0045
	title.position = Vector3(0, FL + 3.55, 3.2)
	add_child(title)
	var sub := Label3D.new()
	sub.text = "Chez Yuki - on accepte les coquillages"
	sub.font_size = 40
	sub.outline_size = 10
	sub.outline_modulate = ink
	sub.pixel_size = 0.0035
	sub.position = Vector3(0, FL + 3.2, 3.2)
	add_child(sub)
	var promo := Label3D.new()
	promo.text = "PROMO : le canard géant\nn'est PAS à vendre"
	promo.font_size = 40
	promo.outline_size = 10
	promo.modulate = Color(1.0, 0.85, 0.3)
	promo.outline_modulate = ink
	promo.pixel_size = 0.003
	promo.position = Vector3(-3.48, FL + 1.8, -2.0)
	promo.rotation.y = PI / 2.0
	add_child(promo)


func _lights() -> void:
	var l := OmniLight3D.new()
	l.position = Vector3(0, FL + 2.6, -0.5)
	l.light_color = Color(1.0, 0.88, 0.9)
	l.light_energy = 1.3
	l.omni_range = 7.0
	add_child(l)


# --- Dialogue ---------------------------------------------------------------

func ctx() -> Dictionary:
	var name: String = Characters.LIST[player.char_id]["name"]
	var npcs: Array = []
	for n in player.npcs:
		npcs.append({"name": Characters.LIST[n.char_id]["name"], "where": _where(n.global_position)})
	return {
		"char_name": name,
		"hat": Save.hats.get(name, ""),
		"shells": Save.shells,
		"holding": player.held_kind(),
		"npcs": npcs,
	}


func _where(p: Vector3) -> String:
	var p2 := Vector2(p.x, p.z)
	if p.y < -0.1:
		return "dans l'eau, en panique"
	if p2.distance_to(Island.HOUSE_POS) < 9.0:
		return "près de la maison"
	if p2.distance_to(Island.SHOP_POS) < 10.0:
		return "juste devant ma boutique"
	if p2.distance_to(Island.SPAWN) < 8.0:
		return "près du grand panneau"
	return "dans les hautes herbes"


func say(text: String) -> void:
	vendor.chibi.say(text, 2.5 + text.length() * 0.06)


func _player_inside() -> bool:
	var lp: Vector3 = to_local(player.global_position)
	return absf(lp.x) < 3.6 and lp.z > -0.4 and lp.z < 3.8 and lp.y > -1.0 and lp.y < 2.5


func _physics_process(delta: float) -> void:
	if player == null:
		return
	brain.tick(delta)
	vendor.chibi.panic = brain.mood() < -0.3
	var inside := _player_inside()
	if inside and state == "closed":
		_open()
	elif not inside and state != "closed":
		_close()
	if state != "closed":
		_idle += delta
		if _idle > 20.0:
			_idle = 0.0
			say(brain.idle(ctx()))
		# Le menu se tourne vers le joueur
		var to: Vector3 = player.camera.global_position - menu_root.global_position
		to.y = 0.0
		if to.length() > 0.1:
			menu_root.global_rotation.y = atan2(to.x, to.z)
		_update_header()
	_save_t += delta
	if _save_t > 30.0:
		_save_t = 0.0
		Save.save_game()


func _open() -> void:
	state = "main"
	_idle = 0.0
	say(brain.greet(ctx()))
	show_main()


func _close() -> void:
	state = "closed"
	say(brain.farewell(ctx()))
	_clear()
	header.visible = false
	Save.save_game()


func _clear() -> void:
	for bt in buttons:
		bt.queue_free()
	buttons.clear()


func _update_header() -> void:
	var m: float = brain.mood()
	var humeur := "ravie" if m > 0.5 else ("contente" if m > 0.1 else ("bof" if m > -0.3 else "FÂCHÉE"))
	var txt := "Coquillages : %d   ·   Humeur de Yuki : %s" % [Save.shells, humeur]
	if brain.discount:
		txt += "\nRéduc -30 % sur le prochain achat !"
	header.text = txt
	header.visible = true


func _add_button(text: String, cb: Callable, col := ChoiceButton.BASE) -> void:
	var bt := ChoiceButton.new()
	menu_root.add_child(bt)
	bt.setup(text, cb, 1.3, col)
	bt.position = Vector3(0, 0.12 - buttons.size() * 0.21, 0)
	buttons.append(bt)


func show_main() -> void:
	_clear()
	for o in brain.options(ctx()):
		_add_button(o[1], _choose.bind(o[0]))


func show_catalog() -> void:
	_clear()
	var c := ctx()
	var start := page * PER_PAGE
	for i in range(start, mini(start + PER_PAGE, Items.ITEMS.size())):
		var it: Dictionary = Items.ITEMS[i]
		var label := "%s - %d coquillages" % [it["name"], brain.price_of(it)]
		if it["type"] == "hat" and c["hat"] == it["id"]:
			label = "%s (sur ta tête)" % it["name"]
		_add_button(label, _buy.bind(it["id"]), Color(0.85, 0.95, 1.0))
	_add_button("Autres articles >", _next_page, Color(1.0, 0.9, 0.95))
	_add_button("< Retour", _back, Color(0.9, 0.9, 0.9))


func _next_page() -> void:
	page = (page + 1) % int(ceil(Items.ITEMS.size() / float(PER_PAGE)))
	show_catalog()


func _back() -> void:
	state = "main"
	show_main()


## Pour le mode PC : touches 1 à 5.
func choose(index: int) -> void:
	if state == "closed" or index < 0 or index >= buttons.size():
		return
	buttons[index].press()


func _choose(intent: String) -> void:
	_idle = 0.0
	if intent == "catalog":
		state = "catalog"
		page = 0
		say(brain._say(["Regarde, tout est sur les étagères ! Choisis dans la liste.", "Voilà ma sélection du jour !", "Que des articles de qualité... ou presque."]))
		show_catalog()
		return
	var r: Dictionary = brain.respond(intent, ctx())
	if r.has("sell"):
		var rb = player.held_item()
		if rb:
			player.release_item(rb)
			Fx.puff(world, rb.global_position)
			rb.send_home()
			Save.shells += int(r["sell"])
			Fx.text(world, menu_root.global_position + Vector3(0, 0.6, 0), "+%d coquillages" % int(r["sell"]), Color(1.0, 0.75, 0.8), 0.6)
	if r.get("remove_hat", false):
		Save.hats.erase(ctx()["char_name"])
		player.avatar.refresh_hat()
		Fx.puff(world, player.global_position + Vector3(0, 1.2, 0))
	say(r["text"])
	Save.save_game()
	show_main()


func _buy(id: String) -> void:
	_idle = 0.0
	var it := Items.by_id(id)
	var r: Dictionary = brain.try_buy(it, ctx())
	say(r["text"])
	if r.has("buy"):
		Save.shells -= int(r["price"])
		Save.shells += int(r.get("gift", 0))
		_deliver(it)
		Save.save_game()
	show_catalog()


func _deliver(it: Dictionary) -> void:
	match it["type"]:
		"hat":
			Save.hats[ctx()["char_name"]] = it["id"]
			player.avatar.refresh_hat()
			Fx.puff(world, player.global_position + Vector3(0, 1.3, 0), Color(1.0, 0.85, 0.95))
			Fx.text(world, player.global_position + Vector3(0, 1.9, 0), "TADAA !", Color(1.0, 0.85, 0.25), 0.9)
			if not player.third_person:
				Fx.text(world, menu_root.global_position + Vector3(0, 0.75, 0), "(vue 3e personne avec B pour l'admirer)", Color(1, 1, 1), 0.35, 2.0)
		_:
			var spot := to_global(Vector3(randf_range(-0.5, 0.5), FL + 1.2, -0.5))
			Props.make(world, it["kind"], spot)
			Fx.puff(world, spot, Color(1.0, 0.9, 0.95))
			Fx.text(world, spot + Vector3(0, 0.4, 0), "Sur le comptoir !", Color(1.0, 0.9, 0.5), 0.5)


func on_vendor_bonked() -> void:
	Fx.text(world, vendor.global_position + Vector3(0, 1.9, 0), "BONK !", Color(1.0, 0.5, 0.3), 1.0)
	vendor.chibi.pop()
	say(brain.bonked())
	Save.save_game()
	if state == "main":
		show_main()
	elif state == "catalog":
		show_catalog()
