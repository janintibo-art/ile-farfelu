extends RefCounted
## Sauvegarde de la partie (coquillages, chapeaux, souvenirs de Yuki et Riku,
## épée, exploits au donjon). Fichier dans le stockage privé de l'appli.

const PATH := "user://ile_farfelue.cfg"

static var shells := 5
static var hats := {}      # nom du perso -> id du chapeau qu'il porte
static var vendor := {}    # mémoire de Yuki
static var punk := {}      # mémoire de Riku
static var sword := 0      # 0 = pas d'épée, 1 = Rock'n'Roll, 2 = électrique, 3 = de feu
static var dungeon := {}   # exploits au donjon


static func default_vendor() -> Dictionary:
	return {"mood": 0.2, "affinity": 10.0, "talks": 0, "bought": {}, "met": {}, "secrets": 0}


static func default_punk() -> Dictionary:
	return {"mood": 0.1, "respect": 10.0, "talks": 0, "met": {}, "test_done": false, "secrets": 0, "last_seen_kills": 0}


static func default_dungeon() -> Dictionary:
	return {"kills": 0, "deaths": 0, "chests": 0, "boss_kills": 0}


static func _merge(base: Dictionary, loaded) -> Dictionary:
	if loaded is Dictionary:
		for k in loaded:
			base[k] = loaded[k]
	return base


static func load_game() -> void:
	vendor = default_vendor()
	punk = default_punk()
	dungeon = default_dungeon()
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	shells = int(cf.get_value("jeu", "coquillages", 5))
	hats = cf.get_value("jeu", "chapeaux", {})
	sword = int(cf.get_value("jeu", "epee", 0))
	vendor = _merge(default_vendor(), cf.get_value("yuki", "memoire", {}))
	punk = _merge(default_punk(), cf.get_value("riku", "memoire", {}))
	dungeon = _merge(default_dungeon(), cf.get_value("donjon", "exploits", {}))


static func save_game() -> void:
	var cf := ConfigFile.new()
	cf.set_value("jeu", "coquillages", shells)
	cf.set_value("jeu", "chapeaux", hats)
	cf.set_value("jeu", "epee", sword)
	cf.set_value("yuki", "memoire", vendor)
	cf.set_value("riku", "memoire", punk)
	cf.set_value("donjon", "exploits", dungeon)
	cf.save(PATH)
