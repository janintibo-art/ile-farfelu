extends RefCounted
## La "mini IA" de Riku, le punk qui garde le Donjon des Boulettes.
## Même principe que Yuki (tout hors ligne), mais avec son caractère :
## - Respect (0..100) au lieu d'affection : il respecte l'audace, les
##   monstres vaincus, et... qu'on lui jette des trucs dessus (très punk).
## - Humeur qui revient vers la normale.
## - Mémoire sauvegardée : qui il a rencontré, le "test de punk", monstres
##   tués, K.O., coffres, boss.
## - Il commente ce qui s'est passé au donjon depuis ta dernière visite.

const Save := preload("res://scripts/save.gd")
const Sword := preload("res://scripts/sword.gd")

const ELEC_PRICE := 25

var recent: Array = []
var _last_char := ""
var _last_talk_ms := -1000000
var _insults := 0


func mem() -> Dictionary:
	if Save.punk.is_empty():
		Save.punk = Save.default_punk()
	return Save.punk


func mood() -> float:
	return float(mem()["mood"])


func respect() -> float:
	return float(mem()["respect"])


func _add_mood(d: float) -> void:
	mem()["mood"] = clampf(mood() + d, -1.0, 1.0)


func _add_respect(d: float) -> void:
	mem()["respect"] = clampf(respect() + d, 0.0, 100.0)


func tick(delta: float) -> void:
	mem()["mood"] = move_toward(mood(), 0.1 + respect() / 500.0, delta * 0.01)


func _pick(arr: Array) -> String:
	return arr[randi() % arr.size()]


func _say(options: Array) -> String:
	var fresh: Array = options.filter(func(o): return not recent.has(o))
	var choice: String = _pick(fresh) if fresh.size() > 0 else _pick(options)
	recent.append(choice)
	if recent.size() > 14:
		recent.pop_front()
	var m := mood()
	if m > 0.5 and randf() < 0.45:
		choice += _pick([" Yeah !", " Rock'n'roll !", " Trop stylé."])
	elif m < -0.3 and randf() < 0.5:
		choice = _pick(["Pff. ", "Ouais ouais. ", "Tch. "]) + choice
	return choice


func greet(ctx: Dictionary) -> String:
	var name: String = ctx["char_name"]
	var met: Dictionary = mem()["met"]
	var now := Time.get_ticks_msec()
	mem()["talks"] = int(mem()["talks"]) + 1
	var lines: Array = []
	var kills := int(Save.dungeon["kills"])
	var new_kills := kills - int(mem()["last_seen_kills"])
	mem()["last_seen_kills"] = kills

	if _last_char != "" and _last_char != name and now - _last_talk_ms < 120000:
		lines = [
			"Attends... t'étais pas %s y'a deux minutes ? Les échanges de corps, c'est trop punk." % _last_char,
			"Nouveau corps, même attitude. J'aime ça, %s. Ou %s. Bref." % [name, _last_char],
		]
		_add_respect(2.0)
	elif not met.has(name):
		met[name] = true
		if Save.sword == 0:
			lines = ["Yo, %s. Moi c'est Riku. Personne n'entre dans le Donjon des Boulettes sans épée." % name,
				"Stop ! Riku, gardien du donjon. Sans arme, les slimes vont te gober tout cru."]
		else:
			lines = ["Yo, %s. T'as la tête de quelqu'un qui a déjà une épée. Respect." % name]
	elif new_kills >= 5:
		lines = ["%d monstres depuis la dernière fois ?! T'es une machine." % new_kills,
			"J'ai entendu les slimes pleurer. %d de moins. Rock'n'roll." % new_kills]
		_add_respect(5.0)
	elif mood() < -0.3:
		lines = ["Toi. Encore.", "J'ai pas oublié ce que t'as dit sur le punk."]
	else:
		lines = ["Yo %s ! Prêt à botter des boulettes ?" % name, "Salut %s. Le donjon t'attend. Et il a faim." % name,
			"Hey %s. Tu veux un conseil ? Frappe fort, frappe vite." % name]
	var hat: String = ctx.get("hat", "")
	if hat == "couronne" and randf() < 0.5:
		lines = ["Une couronne ? Sérieux ? C'est tout sauf punk, ça. ... Mais elle brille bien."]
	elif hat == "lapin" and randf() < 0.5:
		lines = ["Des oreilles de lapin. Tu sais quoi ? J'assume de te trouver stylé."]
	_last_char = name
	_last_talk_ms = now
	return _say(lines)


func farewell() -> String:
	if Save.sword == 0:
		return _say(["Reviens quand tu veux ton épée.", "Le donjon, c'est pas pour les touristes."])
	return _say(["Fais pas de bêtises. Enfin, fais-en des bonnes.", "Va, et reviens avec du butin !", "Rock'n'roll, %s." % _last_char])


func options(ctx: Dictionary) -> Array:
	var out: Array = []
	if Save.sword == 0:
		out.append(["ask_sword", "Donne-moi une épée !"])
	out.append(["lore", "C'est quoi ce donjon ?"])
	if Save.sword > 0:
		out.append(["tips", "T'as des conseils ?"])
	if Save.sword == 1 and respect() >= 35.0:
		out.append(["upgrade", "Ton épée électrique, elle coûte combien ?"])
	var extra: Array = [
		["check", "On se fait un check ?"],
		["compliment", "Ta crête est magnifique."],
		["about", "Pourquoi t'es punk ?"],
		["insult", "Le punk, c'est démodé."],
	]
	extra.shuffle()
	for e in extra:
		if out.size() >= 5:
			break
		out.append(e)
	return out


## Le "test de punk" avant de donner l'épée.
func test_question() -> String:
	return "Test de punk ! Qu'est-ce qu'on fait des règles ?"


func test_answers() -> Array:
	var a := [
		["rules_break", "On les enfreint !"],
		["rules_plane", "On en fait des avions en papier."],
		["rules_read", "On les lit en entier, avec les notes."],
	]
	a.shuffle()
	return a


func respond(intent: String, ctx: Dictionary) -> Dictionary:
	if intent != "insult":
		_insults = 0
	match intent:
		"ask_sword":
			if mem()["test_done"]:
				return {"text": "OK, OK. Tiens.", "give_sword": true}
			return {"text": _say([test_question()]), "test": true}
		"rules_break":
			mem()["test_done"] = true
			_add_respect(10.0)
			return {"text": "YEAH ! La bonne réponse ! Tiens, l'Épée Rock'n'Roll. Elle est à toi.", "give_sword": true}
		"rules_plane":
			mem()["test_done"] = true
			_add_respect(15.0)
			_add_mood(0.3)
			return {"text": "Des avions en papier... C'est encore plus punk que ma réponse. Tiens, prends l'épée !", "give_sword": true}
		"rules_read":
			mem()["test_done"] = true
			_add_respect(-3.0)
			return {"text": "... Avec les notes ?! T'es Taro, c'est ça ? Bon. Prends l'épée quand même, t'en auras besoin.", "give_sword": true}
		"lore":
			return {"text": _say([
				"Le Donjon des Boulettes. Des slimes, des champignons grognons, des chauves-souris ronchons. Et le Roi Gloubi au fond.",
				"Y'a des coffres partout. Le coffre doré ne s'ouvre qu'après avoir battu le Roi Gloubi.",
				"Avant c'était une cave à fromages. Puis les slimes sont arrivés. Personne sait d'où.",
			])}
		"tips":
			return {"text": _tip()}
		"upgrade":
			if Save.shells < ELEC_PRICE:
				return {"text": _say(["%d coquillages. T'en as %d. Reviens plus riche." % [ELEC_PRICE, Save.shells]])}
			return {"text": _say(["%d coquillages et elle est à toi. Deal ! Bzzzt !" % ELEC_PRICE]), "upgrade": ELEC_PRICE}
		"check":
			_add_respect(3.0)
			_add_mood(0.2)
			return {"text": _say(["CHECK ! Pouah, t'as de la poigne.", "Check ! On est potes maintenant. Enfin, presque.", "Poing contre poing. Respect."]), "check": true}
		"compliment":
			_add_mood(0.2)
			_add_respect(2.0)
			return {"text": _say(["Je sais. Une heure de gel chaque matin.", "Merci. Elle est rose parce que j'ai perdu un pari.", "Touche pas, par contre."])}
		"about":
			if respect() >= 50.0 and int(mem()["secrets"]) == 0:
				mem()["secrets"] = 1
				return {"text": "Secret : en vrai, j'adore les chapeaux de Yuki. J'ai des oreilles de lapin chez moi. Dis-le à personne."}
			return {"text": _say([
				"Parce que le monde a besoin de bruit. Et de crêtes.",
				"J'ai monté un groupe : Les Noix de Coco Hurlantes. On a un fan. C'est le canard.",
				"Le punk, c'est dire non. Sauf aux onigiris. Aux onigiris, on dit oui.",
			])}
		"insult":
			_insults += 1
			_add_mood(-0.3)
			_add_respect(-4.0 if _insults > 1 else 1.0)
			if _insults > 1:
				return {"text": _say(["Deux fois ? Là tu me vexes vraiment.", "OK. Je boude. Laisse-moi."])}
			return {"text": _say(["Démodé ?! ... T'as du cran de me dire ça en face. J'aime ça. Un peu.", "Répète ça et je te chante ma chanson de 14 minutes."])}
	return {"text": "Hein ?"}


func _tip() -> String:
	var lines: Array = [
		"Les chauves-souris volent haut : vise la tête.",
		"Les slimes sautent quand ils attaquent. Recule, puis frappe.",
		"Frappe vite ! Une épée qui bouge pas, ça fait rien.",
	]
	if int(Save.dungeon["boss_kills"]) == 0:
		lines.append("Le Roi Gloubi se divise quand il a mal. Garde du souffle pour les petits.")
		lines.append("Le Roi Gloubi est au nord-est. Suis les torches.")
	else:
		lines.append("T'as battu le Roi Gloubi. Il revient à chaque visite, il est rancunier.")
	if int(Save.dungeon["deaths"]) > 2:
		lines.append("T'es tombé K.O. %d fois. Mange un ramen avant d'y aller, ça rend rapide." % int(Save.dungeon["deaths"]))
	return _say(lines)


func bonked() -> String:
	_add_respect(3.0)
	_add_mood(0.1)
	return _say(["HA ! Me jeter un truc dessus ? Ça c'est punk !", "Aïe. ... Respect.", "Bien visé. Tu devrais être dans mon groupe."])


func ko_line() -> String:
	return _say([
		"Te voilà ! Tu t'es fait laminer par une boulette ?",
		"K.O. ? Relève-toi. Les punks tombent, mais se relèvent.",
		"J'ai vu voler un truc hors du donjon. C'était toi.",
	])


func no_sword_line() -> String:
	return _say(["Hé hé hé ! Pas sans épée !", "Stop ! Viens me parler d'abord.", "T'es pas armé. Les slimes vont te dévorer."])


func idle() -> String:
	return _say(["Tu comptes y aller ou tu fais du tourisme ?", "*joue de la guitare invisible*", "Le donjon va pas se nettoyer tout seul."])


func chest_line() -> String:
	return _say(["T'as trouvé des coffres ? J'espère que t'as partagé. Non ? Normal.", "Les coffres, ça se remplit tout seuls. Magie punk."])
