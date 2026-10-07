extends RefCounted
## La "mini IA" de Pierre (qui a perdu son slip) et de Luc-Ael (le pêcheur).
## Même principe que Yuki et Riku : tout hors ligne, humeur, mémoire
## sauvegardée (quête, prises, bottes pêchées...), phrases qui évitent de se
## répéter et qui dépendent de la situation.

const Save := preload("res://scripts/save.gd")
const Inv := preload("res://scripts/inventory_items.gd")

var recent: Array = []


func q() -> Dictionary:
	if Save.quest.is_empty():
		Save.quest = Save.default_quest()
	return Save.quest


func m() -> Dictionary:
	if Save.shore.is_empty():
		Save.shore = Save.default_shore()
	return Save.shore


func _add_mood(who: String, d: float) -> void:
	var k := who + "_mood"
	m()[k] = clampf(float(m()[k]) + d, -1.0, 1.0)


func mood(who: String) -> float:
	return float(m()[who + "_mood"])


func _pick(arr: Array) -> String:
	return arr[randi() % arr.size()]


func _say(options: Array) -> String:
	var fresh: Array = options.filter(func(o): return not recent.has(o))
	var choice: String = _pick(fresh) if fresh.size() > 0 else _pick(options)
	recent.append(choice)
	if recent.size() > 16:
		recent.pop_front()
	return choice


func fish_count() -> int:
	var n := 0
	for id in Save.inventory:
		if Inv.ITEMS.get(id, {}).get("type", "") == "fish":
			n += Save.count(id)
	return n


# --- Pierre -----------------------------------------------------------------------

func pierre_greet(name: String) -> String:
	var met: Dictionary = m()["met_pierre"]
	m()["pierre_talks"] = int(m()["pierre_talks"]) + 1
	var state: String = q()["pierre"]
	if state == "none":
		if not met.has(name):
			met[name] = true
			return _say(["P-pssst ! %s ! Ne regarde pas ! Enfin si, regarde, mais pas en dessous de la serviette !" % name])
		return _say(["C'est encore moi, le gars à la serviette. La situation n'a pas évolué.", "Tu es revenu ! Tu as changé d'avis ? Tu vas m'aider ?"])
	if state == "active" or state == "found":
		if Save.count("slip") > 0:
			return _say(["C'est... C'EST MON SLIP ?! Je le reconnais aux petits coeurs !", "Attends, je sens une présence... Celle de mon slip !"])
		var tries := int(q()["tries"])
		if tries == 0:
			return _say(["Alors ? Tu as vu Luc-Ael ? Il a une canne à pêche, lui.", "Le slip ne va pas se repêcher tout seul...", "Tu sais, je peux tenir encore longtemps. La serviette est solide."])
		if int(q()["boots"]) > 0:
			return _say(["J'ai vu que tu as pêché une botte. Ce n'est pas mon slip, mais c'est un début.", "Toujours pas de slip ? La mer est pleine de surprises. Et de bottes."])
		return _say(["Tu as déjà lancé %d fois... Mon slip est timide." % tries, "Le vent tourne. Je le sens. Le slip est proche.", "Continue ! Ma dignité compte sur toi !"])
	# Quête terminée
	return _say(["Mon sauveur ! Tu veux voir mon slip ? Non ? Tant pis, il est très beau.", "Je me baigne plus jamais. Enfin, si. Mais avec une ceinture.", "Salut %s ! Je suis un homme libre, maintenant." % name])


func pierre_options() -> Array:
	var state: String = q()["pierre"]
	var out: Array = []
	if Save.count("slip") > 0:
		out.append(["give_slip", "Voilà ton slip !"])
	if state == "none":
		out.append(["accept", "Je vais retrouver ton slip !"])
		out.append(["how", "Mais qu'est-ce qui s'est passé ?"])
		out.append(["laugh", "HAHAHA !"])
		out.append(["refuse", "Débrouille-toi."])
	elif state == "done":
		out.append(["thanks_again", "Alors, ce slip ?"])
		out.append(["how", "Raconte encore l'histoire !"])
	else:
		out.append(["where", "Il est tombé où, exactement ?"])
		out.append(["how", "Mais qu'est-ce qui s'est passé ?"])
		out.append(["color", "Il ressemble à quoi, ce slip ?"])
	return out


func pierre_respond(intent: String) -> Dictionary:
	match intent:
		"accept":
			q()["pierre"] = "active"
			_add_mood("pierre", 0.4)
			return {"text": "MERCI ! Il est quelque part dans l'eau, au bout du ponton. Demande sa canne à Luc-Ael !", "quest_started": true}
		"how":
			return {"text": _say([
				"J'ai plongé pour attraper un poisson doré. J'ai raté le poisson. Et j'ai perdu le slip.",
				"Une vague géante. Enfin, moyenne. Bon, une petite vague. Mais elle était très motivée.",
				"Le canard géant m'a regardé. J'ai paniqué. Le slip, lui, est parti.",
			])}
		"laugh":
			_add_mood("pierre", -0.3)
			return {"text": _say(["C'est pas drôle ! Bon... un peu. Mais aide-moi quand même !", "Ris, ris. Un jour, ça t'arrivera aussi."])}
		"refuse":
			_add_mood("pierre", -0.4)
			return {"text": _say(["Sans coeur ! Je vais rester en serviette pour toujours !", "D'accord... je vais vivre ici, maintenant. Avec les crabes."])}
		"where":
			return {"text": _say(["Par là, dans l'eau, pas loin du ponton. Lance la ligne vers le large !", "Quelque part entre ici et l'horizon. C'est précis, non ?"])}
		"color":
			return {"text": _say(["Rouge, avec des petits coeurs roses. Un cadeau de ma grand-mère.", "Rouge. Élastique blanc. Coeurs. Très élégant. Très moi."])}
		"thanks_again":
			return {"text": _say(["Il va très bien. Il a séché au soleil. On est de nouveau inséparables.", "Je l'ai lavé trois fois. Il sent la mer quand même."])}
		"give_slip":
			Save.add_item("slip", -1)
			q()["pierre"] = "done"
			_add_mood("pierre", 1.0)
			return {"text": "MON SLIP ! MON BEAU SLIP ! Tiens, 15 coquillages. Et... ne regarde pas, je me change !", "reward": 15, "done": true}
	return {"text": "Hein ?"}


func pierre_bonked() -> String:
	_add_mood("pierre", -0.2)
	return _say(["AÏE ! Attention, la serviette a failli tomber !", "Pas sur moi ! Je suis déjà en situation délicate !", "Tu veux me faire perdre la serviette aussi ?!"])


func pierre_idle() -> String:
	if q()["pierre"] == "done":
		return _say(["*admire son slip*", "Il fait beau. J'ai un slip. La vie est belle."])
	return _say(["*resserre sa serviette*", "Il fait frais, quand même, sans slip.", "Si quelqu'un passe, je suis un rocher."])


# --- Luc-Ael ----------------------------------------------------------------------

func luc_greet(name: String) -> String:
	var met: Dictionary = m()["met_luc"]
	m()["luc_talks"] = int(m()["luc_talks"]) + 1
	if not met.has(name):
		met[name] = true
		return _say(["Salut, moi c'est Luc-Ael. Chut... ça mord peut-être. Ou pas. Sûrement pas.", "Bonjour %s. Tu tombes bien, je parlais à un poisson. Il ne répondait pas." % name])
	if int(q()["boots"]) >= 3:
		return _say(["Ah, le collectionneur de bottes ! Tu en as pêché %d. Il te manque plus que le pied." % int(q()["boots"])])
	if int(q()["golden"]) > 0:
		return _say(["Tu as pêché un poisson doré, toi. Je t'ai à l'oeil, petit génie."])
	if q()["rod"] == "lent":
		return _say(["Alors, ma canne te plaît ? Elle s'appelle Josiane.", "Ça mord ? Moi non plus.", "Patience et longueur de ligne, comme disait mon grand-père."])
	return _say(["Salut %s. La mer est calme, les poissons sont bêtes. Journée parfaite." % name, "Yo %s. Tu veux entendre ma blague de poisson ? Non ? Elle est trop longue de toute façon." % name])


func luc_options() -> Array:
	var out: Array = []
	var rod: String = q()["rod"]
	if rod == "none":
		out.append(["lend", "Tu me prêtes ta canne ?"])
	out.append(["howto", "Comment on pêche ?"])
	if fish_count() > 0:
		out.append(["sell", "Tu m'achètes mes poissons ?"])
	out.append(["bite", "Ça mord ?"])
	out.append(["joke", "Raconte-moi une blague"])
	if rod == "owned":
		out.append(["record", "C'est quoi ton record ?"])
	return out


func luc_respond(intent: String, is_vr: bool) -> Dictionary:
	match intent:
		"lend":
			q()["rod"] = "lent"
			_add_mood("luc", 0.1)
			var extra := " Si tu repêches le slip de Pierre, elle est à toi." if q()["pierre"] != "done" else ""
			return {"text": "Tiens, je te prête Josiane, ma canne préférée. Prends-en soin." + extra, "lend": true}
		"howto":
			if is_vr:
				return {"text": "Grip pour sortir la canne. Gâchette pour lancer vers l'eau. Quand le bouchon plonge et que ça vibre : gâchette, ou tire la canne d'un coup sec vers le haut !"}
			return {"text": "Touche G pour sortir la canne, clic pour lancer vers l'eau. Quand le bouchon plonge : clic tout de suite !"}
		"bite":
			return {"text": _say(["Depuis ce matin, j'ai eu une touche. C'était mon pied.", "Ça mord toujours quand je regarde ailleurs.", "Les poissons sont en réunion. Reviens dans cinq minutes."])}
		"joke":
			return {"text": _say([
				"Pourquoi les poissons vivent dans l'eau salée ? Parce que le poivre les fait éternuer.",
				"Qu'est-ce qu'un poisson sans oeil ? Un pssson.",
				"Tu sais ce que dit un poisson qui se cogne ? Rien. Il fait des bulles.",
			])}
		"record":
			return {"text": _say(["Mon record ? Un poisson doré de trois kilos. Enfin, trois cents grammes. Mais il était très doré.", "Une botte de pluie avec un crabe dedans. Deux prises en une."])}
		"sell":
			var total := 0
			for id in Save.inventory.keys():
				var it: Dictionary = Inv.ITEMS.get(id, {})
				if it.get("type", "") == "fish":
					total += int(it["sell"]) * Save.count(id)
					Save.inventory.erase(id)
			return {"text": _say(["Marché conclu ! %d coquillages pour ta pêche du jour." % total, "Je te les prends. %d coquillages. Ils finiront en brochettes." % total]), "gain": total}
	return {"text": "Hein ?"}


func luc_bonked() -> String:
	_add_mood("luc", -0.1)
	return _say(["Hé ! Tu vas faire fuir les poissons !", "Ouille. Bon, au moins ça m'a réveillé.", "C'était un poisson volant ? Ah non. Dommage."])


func luc_idle() -> String:
	return _say(["*bâille*", "Blub. Oh pardon, je m'entraînais à parler poisson.", "Le secret de la pêche ? Ne rien faire. Je suis très fort."])


## Commentaire de Luc-Ael après une prise (s'il est à côté).
func luc_on_catch(id: String) -> String:
	match id:
		"slip":
			return "LE SLIP ! Incroyable ! Garde la canne, tu l'as bien méritée !"
		"botte":
			return _say(["Une botte ! Il en manque une pour la paire.", "Magnifique botte. Taille 42, je dirais."])
		"dore":
			return "UN POISSON DORÉ ?! Ça fait vingt ans que j'en cherche un !"
		"algue":
			return _say(["Une algue. Bah, ça se mange. Enfin, je crois.", "Belle algue. Très... gluante."])
		"arcenciel":
			return _say(["Oh, un arc-en-ciel ! Il est tout content d'être pêché."])
	return _say(["Pas mal !", "Joli coup de poignet.", "Celui-là, il a pas eu de chance."])
