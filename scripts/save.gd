extends RefCounted
## Sauvegarde de la partie (coquillages, chapeaux, souvenirs de Yuki et Riku,
## épée, exploits au donjon). Fichier dans le stockage privé de l'appli.

const PATH := "user://ile_farfelue.cfg"   # partie 1 (ancienne sauvegarde conservée)
const SLOTS := 3

static var slot := 1
static var active := false   # tant qu'aucune partie n'est choisie, on n'écrit rien

static var shells := 5
static var hats := {}      # nom du perso -> id du chapeau qu'il porte
static var vendor := {}    # mémoire de Yuki
static var punk := {}      # mémoire de Riku
static var sword := 0      # 0 = pas d'épée, 1 = Rock'n'Roll, 2 = électrique, 3 = de feu
static var dungeon := {}   # exploits au donjon
static var inventory := {} # id de l'objet -> nombre
static var equipped := ""  # outil sorti avec le grip : "sword", "rod" ou ""
static var quest := {}     # quête du slip de Pierre + pêche
static var shore := {}     # mémoire de Pierre et Luc-Ael
static var story := {}     # l'histoire principale (prologue, chapitres...)
static var village := {}   # mémoire des habitants de Port-Biscornu


static func path_of(n: int) -> String:
	return PATH if n <= 1 else "user://ile_farfelue_%d.cfg" % n


## Résumé d'une partie pour le menu ({} si elle n'existe pas).
static func peek(n: int) -> Dictionary:
	var cf := ConfigFile.new()
	if cf.load(path_of(n)) != OK:
		return {}
	var st: Dictionary = cf.get_value("histoire", "etat", {})
	var chap := "Prologue"
	if st.get("ch1_done", false):
		chap = "Chapitre 1 terminé"
	elif st.get("phare_done", false):
		chap = "Sortie du phare"
	elif st.get("mardi", false):
		chap = "Le mardi est revenu"
	elif st.get("village_seen", false):
		chap = "Port-Biscornu"
	elif st.get("woke", false):
		chap = "La plage"
	return {"chap": chap, "shells": int(cf.get_value("jeu", "coquillages", 5))}


static func delete_slot(n: int) -> void:
	var p := path_of(n)
	if FileAccess.file_exists(p):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


static func default_vendor() -> Dictionary:
	return {"mood": 0.2, "affinity": 10.0, "talks": 0, "bought": {}, "met": {}, "secrets": 0}


static func default_punk() -> Dictionary:
	return {"mood": 0.1, "respect": 10.0, "talks": 0, "met": {}, "test_done": false, "secrets": 0, "last_seen_kills": 0}


static func default_dungeon() -> Dictionary:
	return {"kills": 0, "deaths": 0, "chests": 0, "boss_kills": 0}


static func default_quest() -> Dictionary:
	# pierre : none / active / found / done ; rod : none / lent / owned
	return {"pierre": "none", "rod": "none", "tries": 0, "catches": 0, "boots": 0, "golden": 0}


static func default_shore() -> Dictionary:
	return {"pierre_mood": 0.0, "luc_mood": 0.3, "met_pierre": {}, "met_luc": {}, "pierre_talks": 0, "luc_talks": 0}


static func default_story() -> Dictionary:
	return {"woke": false, "plank_off": false, "suitcase": false, "photo_seen": false, "pico": false,
		"planks": 0, "bridge": false, "kept_plank": false, "castle_seen": false,
		"village_seen": false, "inn_met": false, "mayor_met": false, "registered": false, "room_key": false,
		"desk_ok": false, "calendar_seen": false, "tuesday": false, "nina_met": false, "barnabe_met": false,
		"sign_read": false,
		"c_baker": false, "c_fisher": false, "c_house": false, "c_inn": false, "c_light": false, "c_petro": false,
		"ledger_seen": false, "who7": false, "eleonore_known": false, "eleonore_met": false, "eleonore_story": false,
		"got_axe": false, "wheel_built": false, "wheel_placed": false, "axe_placed": false, "mardi": false,
		"gerard_met": false, "marguerite_met": false, "basile_met": false, "petro_met": false, "fails": 0}


static func default_village() -> Dictionary:
	return {"mood": {"malo": 0.1, "barnabe": 0.3, "nina": 0.5, "mayor": 0.2}, "talks": {}, "met": {}, "bought": {}}


static func add_item(id: String, n := 1) -> void:
	inventory[id] = int(inventory.get(id, 0)) + n
	if int(inventory[id]) <= 0:
		inventory.erase(id)


static func count(id: String) -> int:
	return int(inventory.get(id, 0))


static func _merge(base: Dictionary, loaded) -> Dictionary:
	if loaded is Dictionary:
		for k in loaded:
			base[k] = loaded[k]
	return base


static func load_game() -> void:
	vendor = default_vendor()
	punk = default_punk()
	dungeon = default_dungeon()
	quest = default_quest()
	shore = default_shore()
	story = default_story()
	village = default_village()
	inventory = {}
	shells = 5
	hats = {}
	sword = 0
	equipped = ""
	active = true
	var cf := ConfigFile.new()
	if cf.load(path_of(slot)) != OK:
		return
	shells = int(cf.get_value("jeu", "coquillages", 5))
	hats = cf.get_value("jeu", "chapeaux", {})
	sword = int(cf.get_value("jeu", "epee", 0))
	vendor = _merge(default_vendor(), cf.get_value("yuki", "memoire", {}))
	punk = _merge(default_punk(), cf.get_value("riku", "memoire", {}))
	dungeon = _merge(default_dungeon(), cf.get_value("donjon", "exploits", {}))
	quest = _merge(default_quest(), cf.get_value("quete", "slip", {}))
	shore = _merge(default_shore(), cf.get_value("plage", "memoire", {}))
	story = _merge(default_story(), cf.get_value("histoire", "etat", {}))
	village = _merge(default_village(), cf.get_value("ville", "memoire", {}))
	inventory = cf.get_value("jeu", "inventaire", {})
	equipped = str(cf.get_value("jeu", "equipe", ""))


static func save_game() -> void:
	if not active:
		return
	var cf := ConfigFile.new()
	cf.set_value("jeu", "coquillages", shells)
	cf.set_value("jeu", "chapeaux", hats)
	cf.set_value("jeu", "epee", sword)
	cf.set_value("yuki", "memoire", vendor)
	cf.set_value("riku", "memoire", punk)
	cf.set_value("donjon", "exploits", dungeon)
	cf.set_value("quete", "slip", quest)
	cf.set_value("plage", "memoire", shore)
	cf.set_value("histoire", "etat", story)
	cf.set_value("ville", "memoire", village)
	cf.set_value("jeu", "inventaire", inventory)
	cf.set_value("jeu", "equipe", equipped)
	cf.save(path_of(slot))
