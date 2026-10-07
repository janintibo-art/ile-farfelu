extends Node3D
## L'inventaire : un panneau qui s'ouvre devant soi (bouton menu de la
## manette gauche, ou touche I sur PC). On vise une ligne + gâchette :
## - canne / épée : l'équiper (elle sort avec le grip ou la touche G)
## - nourriture : la manger
## - poissons et objets : les sortir dans la main (pour les lancer, les vendre...)
## Et « Ranger ce que je tiens » met l'objet tenu dans le sac.

const TalkMenu := preload("res://scripts/talk_menu.gd")
const Save := preload("res://scripts/save.gd")
const Inv := preload("res://scripts/inventory_items.gd")
const Sword := preload("res://scripts/sword.gd")
const Props := preload("res://scripts/props.gd")
const Items := preload("res://scripts/shop_items.gd")
const Fx := preload("res://scripts/fx.gd")
const Journal := preload("res://scripts/journal.gd")

const PER_PAGE := 5

var player
var menu
var is_open := false
var page := 0
var view := "bag"
var tab := "clues"


func setup(p_player) -> void:
	player = p_player
	menu = TalkMenu.new()
	add_child(menu)
	menu.scale = Vector3.ONE * 0.8
	visible = false


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open() -> void:
	is_open = true
	visible = true
	page = 0
	view = "bag"
	var cam: Vector3 = player.camera.global_position
	var f: Vector3 = -player.camera.global_basis.z
	f.y = 0.0
	f = f.normalized() if f.length() > 0.01 else Vector3.FORWARD
	global_position = cam + f * 1.25 + Vector3(0, -0.1, 0)
	menu.face(cam)
	refresh()


func close() -> void:
	is_open = false
	visible = false
	menu.clear()


func choose(index: int) -> void:
	if is_open:
		menu.choose(index)


## Les lignes de l'inventaire : [texte, action, argument]
func entries() -> Array:
	var out: Array = []
	var held: String = player.held_kind()
	var held_id := Inv.id_for_kind(held)
	if held_id != "" and held_id != "slip":
		out.append(["Ranger : " + Inv.item_name(held_id), "store", held_id])
	var rod: String = Save.quest.get("rod", "none")
	if rod != "none":
		var t := "Canne à pêche" + (" (prêtée)" if rod == "lent" else "")
		out.append([t + ("  [équipée]" if Save.equipped == "rod" else ""), "equip", "rod"])
	if Save.sword > 0:
		out.append([Sword.NAMES[Save.sword] + ("  [équipée]" if Save.equipped != "rod" else ""), "equip", "sword"])
	if Save.count("carnet") > 0:
		out.append(["Ouvrir le carnet d'enquête", "journal", ""])
	for id in Inv.ORDER:
		var n := Save.count(id)
		if id == "carnet":
			continue
		if n > 0:
			out.append(["%s  x%d" % [Inv.item_name(id), n], "use", id])
	return out


func refresh() -> void:
	if not is_open:
		return
	if view == "journal":
		_refresh_journal()
		return
	var all := entries()
	var pages := maxi(1, int(ceil(all.size() / float(PER_PAGE))))
	page = clampi(page, 0, pages - 1)
	var opts: Array = []
	for i in range(page * PER_PAGE, mini((page + 1) * PER_PAGE, all.size())):
		var e: Array = all[i]
		var col := Color(1.0, 0.96, 0.88)
		match e[1]:
			"equip":
				col = Color(0.85, 0.95, 1.0)
			"store":
				col = Color(0.9, 1.0, 0.85)
		opts.append([e[0], _do.bind(e[1], e[2]), col])
	if all.is_empty():
		opts.append(["(Ton sac est vide)", func(): pass, Color(0.9, 0.9, 0.9)])
	if pages > 1:
		opts.append(["Page suivante (%d/%d) >" % [page + 1, pages], _next, Color(1.0, 0.9, 0.95)])
	opts.append(["Fermer le sac", close, Color(0.9, 0.9, 0.9)])
	menu.show_options(opts)
	menu.set_header("SAC   ·   Coquillages : %d" % Save.shells)


func _refresh_journal() -> void:
	var all: Array = Journal.lines(tab)
	var per := 4
	var pages := maxi(1, int(ceil(all.size() / float(per))))
	page = clampi(page, 0, pages - 1)
	var opts: Array = []
	for i in range(page * per, mini((page + 1) * per, all.size())):
		opts.append([all[i], func(): pass, Color(1.0, 0.97, 0.85)])
	if pages > 1:
		opts.append(["Page suivante (%d/%d) >" % [page + 1, pages], _jnext, Color(1.0, 0.9, 0.95)])
	var nxt: String = Journal.TABS[(Journal.TABS.find(tab) + 1) % Journal.TABS.size()]
	opts.append(["Onglet : " + Journal.TAB_NAMES[nxt] + " >", _jtab.bind(nxt), Color(0.85, 0.95, 1.0)])
	opts.append(["Fermer le carnet", _jclose, Color(0.9, 0.9, 0.9)])
	menu.show_options(opts)
	menu.set_header("CARNET D'ENQUÊTE  ·  " + Journal.TAB_NAMES[tab])


func _jnext() -> void:
	page += 1
	if page >= maxi(1, int(ceil(Journal.lines(tab).size() / 4.0))):
		page = 0
	refresh()


func _jtab(t: String) -> void:
	tab = t
	page = 0
	refresh()


func _jclose() -> void:
	view = "bag"
	page = 0
	refresh()


func _next() -> void:
	page += 1
	var pages := maxi(1, int(ceil(entries().size() / float(PER_PAGE))))
	if page >= pages:
		page = 0
	refresh()


func _do(action: String, id: String) -> void:
	match action:
		"journal":
			view = "journal"
			tab = "clues"
			page = 0
			refresh()
			return
		"store":
			var rb = player.held_item()
			if rb and Inv.id_for_kind(str(rb.get("kind"))) == id:
				player.release_item(rb)
				rb.queue_free()
				Save.add_item(id)
				Fx.text(player.world, global_position + Vector3(0, 0.5, 0), "Rangé !", Color(0.8, 1.0, 0.7), 0.4, 0.8)
		"equip":
			Save.equipped = id
			player.refresh_sword()
			Fx.text(player.world, global_position + Vector3(0, 0.5, 0), "Équipé ! (grip pour la sortir)" if player.vr else "Équipé ! (touche G pour la sortir)", Color(0.7, 0.9, 1.0), 0.4, 1.2)
		"use":
			var it: Dictionary = Inv.ITEMS.get(id, {})
			match it.get("type", ""):
				"quest":
					Fx.text(player.world, global_position + Vector3(0, 0.5, 0), "Le slip de Pierre. Rapporte-le-lui !", Color(1.0, 0.7, 0.8), 0.4, 1.5)
				"food":
					Save.add_item(id, -1)
					var effect := Items.food_effect(it["kind"])
					Fx.text(player.world, player._front(1.2) + Vector3(0, 0.2, 0), "MIAM !", Color(1.0, 0.8, 0.3), 0.8)
					if effect != "":
						player.apply_effect(effect)
				_:
					Save.add_item(id, -1)
					var pos: Vector3 = player.camera.global_position + (-player.camera.global_basis.z) * 0.6 + Vector3(0, -0.2, 0)
					var rb := Props.make(player.world, it["kind"], pos)
					if it.get("type", "") == "story":
						rb.story_id = id
					rb.home = player.global_position + Vector3(0, 0.5, 0)
					player.hold_new(rb)
	Save.save_game()
	refresh()


func _process(_delta: float) -> void:
	if is_open and player and player.camera.global_position.distance_to(global_position) > 3.5:
		close()
