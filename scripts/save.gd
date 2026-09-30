extends RefCounted
## Sauvegarde de la partie (coquillages, chapeaux, souvenirs de Yuki).
## Fichier dans le stockage privé de l'appli : il survit à la fermeture du jeu.

const PATH := "user://ile_farfelue.cfg"

static var shells := 5
static var hats := {}      # nom du perso -> id du chapeau qu'il porte
static var vendor := {}    # mémoire de Yuki


static func default_vendor() -> Dictionary:
	return {"mood": 0.2, "affinity": 10.0, "talks": 0, "bought": {}, "met": {}, "secrets": 0}


static func load_game() -> void:
	vendor = default_vendor()
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	shells = int(cf.get_value("jeu", "coquillages", 5))
	hats = cf.get_value("jeu", "chapeaux", {})
	var v: Dictionary = cf.get_value("yuki", "memoire", {})
	for k in v:
		vendor[k] = v[k]


static func save_game() -> void:
	var cf := ConfigFile.new()
	cf.set_value("jeu", "coquillages", shells)
	cf.set_value("jeu", "chapeaux", hats)
	cf.set_value("yuki", "memoire", vendor)
	cf.save(PATH)
