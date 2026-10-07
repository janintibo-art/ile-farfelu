extends RefCounted
## La "mini IA" des habitants de Port-Biscornu : Malo (l'aubergiste), Barnabé
## (marchand d'objets probablement utiles), Nina (petite fille) et Théodore
## Patatras (le maire). Tout est hors ligne : humeur, mémoire sauvegardée,
## phrases qui évitent de se répéter, réponses qui dépendent de l'avancée de
## l'histoire (enregistrement, calendrier, photo dans le sac...).
##
## respond() renvoie un dictionnaire :
##   text   : ce que dit le perso
##   flag   : { clé: valeur } à écrire dans Save.story
##   give   : id d'objet donné (va dans le sac)
##   buy    : [id, prix] (Barnabé)
##   event  : mot-clé pour le village (effets spéciaux)

const Save := preload("res://scripts/save.gd")

const SHOP_GOODS := [
	["poignee", "Poignée de porte", 4],
	["bouton", "Un bouton", 2],
	["corde", "Morceau de corde", 3],
	["miroir", "Miroir fêlé", 5],
	["cle_vide", "Clé sans serrure", 6],
]

var recent: Array = []


func v() -> Dictionary:
	if Save.village.is_empty():
		Save.village = Save.default_village()
	return Save.village


func s() -> Dictionary:
	return Save.story


func mood(who: String) -> float:
	return float(v()["mood"].get(who, 0.0))


func add_mood(who: String, d: float) -> void:
	v()["mood"][who] = clampf(mood(who) + d, -1.0, 1.0)


func talks(who: String) -> int:
	return int(v()["talks"].get(who, 0))


func _count_talk(who: String) -> void:
	v()["talks"][who] = talks(who) + 1


func _pick(arr: Array) -> String:
	return arr[randi() % arr.size()]


func _say(options: Array) -> String:
	var fresh: Array = options.filter(func(o): return not recent.has(o))
	var choice: String = _pick(fresh) if fresh.size() > 0 else _pick(options)
	recent.append(choice)
	if recent.size() > 20:
		recent.pop_front()
	return choice


func _met(who: String, name: String) -> bool:
	var met: Dictionary = v()["met"]
	var key := who + "_" + name
	var first: bool = not met.has(key)
	met[key] = true
	return first


# ---------------------------------------------------------------------------
# API commune
# ---------------------------------------------------------------------------

func greet(who: String, name: String) -> Dictionary:
	_count_talk(who)
	match who:
		"malo":
			return _malo_greet(name)
		"barnabe":
			return _barnabe_greet(name)
		"nina":
			return _nina_greet(name)
		_:
			return _mayor_greet(name)


func options(who: String) -> Array:
	match who:
		"malo":
			return _malo_options()
		"barnabe":
			return _barnabe_options()
		"nina":
			return _nina_options()
		_:
			return _mayor_options()


func respond(who: String, intent: String) -> Dictionary:
	match who:
		"malo":
			return _malo_respond(intent)
		"barnabe":
			return _barnabe_respond(intent)
		"nina":
			return _nina_respond(intent)
		_:
			return _mayor_respond(intent)


func idle(who: String) -> String:
	match who:
		"malo":
			return _say([
				"Je nettoie ce verre depuis tout à l'heure. Il est propre. Je continue par principe.",
				"Si quelqu'un vous demande, je n'ai rien vu mardi. Ni lundi. Ni jamais.",
				"Un verre vide, c'est un verre qui attend. Un verre plein, c'est un verre qui s'inquiète.",
				"Je n'écoute pas les conversations. Je les entends, c'est différent.",
			])
		"barnabe":
			return _say([
				"Promotion du jour : tout est au même prix. Sauf ce qui est à un autre prix.",
				"Un bouton, ça ne sert à rien. Mais le jour où ça sert, vous serez content de l'avoir.",
				"Je n'ai pas de reçu. J'ai des souvenirs. Et ils sont très approximatifs.",
				"Ah, un client ! Non, un courant d'air. Bon.",
			])
		"nina":
			return _say([
				"Tu savais que les mouettes ne comptent que jusqu'à deux ? Après, c'est « beaucoup ».",
				"Les adultes oublient tout. Moi aussi, mais exprès.",
				"Je cherche quelque chose. Je ne sais pas quoi. Je saurai en le trouvant.",
				"Demain, il va faire beau. Enfin, il a fait beau. Un des deux.",
			])
		_:
			return _say([
				"Où ai-je posé ce registre... Il était vert. Ou bleu. En tout cas, il existait.",
				"Je vais faire une pause. Dès que j'aurai fini tout le reste. Donc jamais.",
				"Trois guichets pour soixante-trois habitants. Ou soixante-deux. On recompte demain.",
				"Un maire, c'est quelqu'un qui cherche des choses à la place des autres.",
			])


func bonked(who: String) -> String:
	add_mood(who, -0.15)
	match who:
		"malo":
			return _say(["Les projectiles, c'est à la porte. Il y a un vestiaire pour ça.", "Ça, c'est pour le verre que j'ai cassé tout à l'heure ?", "Aïe. Je note. Dans le livre de comptes."])
		"barnabe":
			return _say(["Hé ! Casser, c'est payant !", "Ça compte comme un achat ?", "Objet probablement lancé. Probablement sur moi."])
		"nina":
			return _say(["Hihi ! Encore !", "Tu vises mal. Moi aussi, c'est plus drôle.", "Ouille ! Je le dirai à demain !"])
		_:
			return _say(["Un incident officiel ! Il faudra un formulaire !", "Dans la mairie ?! Il y a un règlement. Quelque part.", "Aïe ! Je vais devoir le consigner. Si je retrouve le registre."])


# ---------------------------------------------------------------------------
# MALO
# ---------------------------------------------------------------------------

func _malo_greet(name: String) -> Dictionary:
	if not s().get("inn_met", false):
		return {"text": "...  Vous êtes en avance.", "event": "malo_glass", "flag": {"inn_met": true}}
	if s().get("tuesday", false) and not s().get("asked7", false) and randf() < 0.5:
		return {"text": _say(["Ah, %s. Encore une question ? Je sens que c'est une question." % name, "Vous avez cette tête de quelqu'un qui va dire « mardi ».", "Un verre ? Pour oublier ? Je dis ça au hasard."])}
	if s().get("registered", false) and not s().get("room_key", false):
		return {"text": _say(["Vous revoilà. Et enregistré, en plus ! La chambre est à vous.", "Ah, avec le papier de la mairie ! Je peux enfin vous louer une chambre sans faute professionnelle."])}
	if s().get("room_key", false):
		return {"text": _say(["Bienvenue chez vous. Enfin, chez moi. Mais avec votre clé.", "%s ! La chambre 4 vous attend. Elle a un peu bougé, mais elle est là." % name, "Un verre ? Il est propre. Je l'ai frotté trois fois."])}
	return {"text": _say(["Bonjour %s. Vous avez rempli le formulaire ? Non ? Alors mairie." % name, "Le formulaire d'arrivée, c'est sur la place. Ça ne se remplit pas tout seul."])}


func _malo_options() -> Array:
	var out: Array = []
	out.append(["early", "En avance pour quoi ?"])
	if s().get("room_key", false):
		out.append(["room_again", "Où est ma chambre, déjà ?"])
	else:
		out.append(["room", "Je voudrais une chambre."])
	out.append(["inn", "Pourquoi « Le Dernier Verre » ?"])
	if s().get("photo_seen", false) or Save.count("photo") > 0:
		out.append(["photo", "Vous reconnaissez quelqu'un là-dessus ?"])
	if s().get("tuesday", false):
		out.append(["seven", "Et la chambre 7 ?"])
	out.append(["nothing", "Rien, je regardais."])
	return out


func _malo_respond(intent: String) -> Dictionary:
	match intent:
		"early":
			add_mood("malo", -0.05)
			return {"text": _say(["Rien. Absolument rien. D'ailleurs je n'ai rien dit.", "En avance ? Pour le verre ! Pour... l'heure de l'apéro. Voilà."])}
		"room":
			if s().get("room_key", false):
				return {"text": "Vous en avez déjà une. Je ne vais pas vous en louer deux, je ne suis pas un monstre."}
			if not s().get("registered", false):
				return {"text": _say([
					"Une chambre ? Bien sûr ! Mais d'abord, allez vous inscrire à la mairie. Ici, même les personnes perdues doivent remplir le formulaire d'arrivée.",
					"Avec plaisir. Après la mairie. C'est la règle. Je ne l'ai pas inventée. Enfin, pas toute seule.",
				]), "event": "hint_hall"}
			add_mood("malo", 0.3)
			return {"text": "Chambre 4. Pas la 7, elle est... occupée. Enfin, elle l'était. Enfin, elle l'est peut-être. Tenez, la clé !", "give": "cle_chambre", "flag": {"room_key": true}, "event": "room_key"}
		"room_again":
			return {"text": _say(["Chambre 4, au fond du couloir. La porte qui ne grince pas.", "La 4. Entre la 3 et la 5. C'est mathématique."])}
		"inn":
			add_mood("malo", 0.05)
			return {"text": _say([
				"« Dernier Verre » : c'est le dernier avant que la nuit tombe. Ou avant que je ferme. Ou avant la fin du monde, mais la pancarte est jolie.",
				"Mon grand-père a voulu l'appeler « Le Premier Verre ». Il n'a jamais fini de le payer.",
			])}
		"photo":
			if Save.count("photo") > 0 or s().get("photo_seen", false):
				add_mood("malo", -0.1)
				return {"text": _say(["Cette... photo ? Elle est floue. Très floue. Je ne vois personne. Je vais nettoyer un verre.", "Je ne reconnais rien. À part mon auberge, évidemment. Elle est très reconnaissable, mon auberge."])}
			return {"text": "Quelle photo ?"}
		"seven":
			add_mood("malo", -0.2)
			return {"text": _say(["Chambre 7 ? Il n'y a pas de chambre 7. Il y en a... huit. Mais pas de 7. C'est compliqué.", "La 7 est en travaux. En permanence. Je n'en dirai pas plus aujourd'hui."]), "flag": {"asked7": true}}
		_:
			return {"text": _say(["Regardez, regardez. Ça ne coûte rien. Sauf si vous cassez.", "Prenez votre temps. Le temps, ici, on en a... un peu moins que prévu."])}


# ---------------------------------------------------------------------------
# BARNABÉ
# ---------------------------------------------------------------------------

func _barnabe_greet(name: String) -> Dictionary:
	if not s().get("barnabe_met", false):
		return {"text": "Barnabé ! Objets PROBABLEMENT utiles ! Entrez, regardez, ne touchez pas — sauf si vous achetez.", "flag": {"barnabe_met": true}}
	return {"text": _say([
		"Ah, %s ! Mon client préféré. Je dis ça à tout le monde, mais là c'est vrai." % name,
		"Du neuf ! Enfin, du vieux, mais déplacé. Ça fait neuf.",
		"Un bouton, une poignée... Vous construisez quoi ? Une porte ? Je n'ai pas la porte. Quelqu'un l'a sur la plage.",
	])}


func _barnabe_options() -> Array:
	var out: Array = []
	out.append(["goods", "Voir la marchandise"])
	out.append(["useful", "C'est vraiment utile, tout ça ?"])
	out.append(["lockless", "Une clé sans serrure ?!"])
	if s().get("tuesday", false):
		out.append(["tuesday", "Vous avez travaillé mardi ?"])
	return out


func _barnabe_respond(intent: String) -> Dictionary:
	match intent:
		"useful":
			add_mood("barnabe", 0.05)
			return {"text": _say(["Probablement. C'est écrit sur la porte. Je n'ai pas dit « certainement ».", "Rien n'est inutile. Ça dépend juste de quand on en a besoin. Et on n'a jamais besoin de la même chose deux fois.", "Utile, c'est un point de vue. Le mien est commercial."])}
		"lockless":
			return {"text": _say(["Elle ouvre sûrement quelque chose. Un jour. Quelque part. C'est le principe d'une clé.", "Je l'ai trouvée dans un tiroir. Le tiroir, lui, n'avait pas de serrure. Ça m'a troublé."])}
		"tuesday":
			add_mood("barnabe", -0.05)
			return {"text": _say(["Mardi ? Je n'ouvre jamais le mardi. Pourtant j'ai de la caisse en trop. C'est gênant, ça.", "Mardi, mardi... Mon stock s'est déplacé tout seul. Mais ça arrive."]), "flag": {"barnabe_tuesday": true}}
		_:
			return {"text": "Voilà ce que j'ai !"}


## Réponse d'achat (l'achat lui-même est géré par le village).
func buy_line(id: String, ok: bool, price: int) -> String:
	if not ok:
		return _say(["Il manque quelques coquillages. Je fais crédit, mais seulement à ceux qui ne reviennent jamais.", "Pas assez ! Mais je note : vous me devez %d. Je perdrai la note." % price])
	v()["bought"][id] = int(v()["bought"].get(id, 0)) + 1
	add_mood("barnabe", 0.1)
	var again: bool = int(v()["bought"][id]) > 1
	match id:
		"poignee":
			return "Une poignée de porte ! Sans porte, certes. Mais regardez comme elle est jolie." if not again else "Encore une poignée ? Vous collectionnez les portes ?"
		"bouton":
			return "Un bouton ! De chemise, de manteau, d'ascenseur... on verra." if not again else "Un deuxième bouton. Un début de chemise."
		"corde":
			return "Un bout de corde ! Il y a toujours un moment où on en cherche." if not again else "De la corde, encore. Vous voulez ficeler le village ?"
		"miroir":
			return "Un miroir fêlé. Il vous renvoie une image un peu coupée. Mais sincère." if not again else "Un autre miroir. Vous avez peur de vous oublier ?"
		_:
			return "La clé sans serrure ! Ne me demandez pas ce qu'elle ouvre. Je l'ai demandé à la clé. Elle n'a pas répondu." if not again else "Une deuxième clé sans serrure. À ce stade, c'est une collection."


# ---------------------------------------------------------------------------
# NINA
# ---------------------------------------------------------------------------

func _nina_greet(name: String) -> Dictionary:
	if not s().get("nina_met", false):
		return {"text": "T'es le nouveau ?"}
	return {"text": _say([
		"Tu reviens ! C'est pas encore demain ?",
		"Salut %s ! Tu as retrouvé ce que tu cherchais ? Moi non plus." % name,
		"Chut. Je compte les mouettes. J'en suis à beaucoup.",
	])}


func _nina_options() -> Array:
	var out: Array = []
	if not s().get("nina_met", false):
		out.append(["yes", "Oui, je viens d'arriver."])
		out.append(["lost", "Non, je suis juste perdu."])
		out.append(["where", "Tu m'as déjà vu ?"])
	else:
		out.append(["tuesday", "Tu te souviens de mardi ?"])
		out.append(["gulls", "Tu comptes vraiment des mouettes ?"])
		out.append(["secret", "Tu connais un secret ?"])
	return out


func _nina_respond(intent: String) -> Dictionary:
	match intent:
		"yes", "lost":
			add_mood("nina", 0.1)
			return {"text": "Pourtant je crois t'avoir déjà vu."}
		"where":
			add_mood("nina", 0.15)
			return {"text": "Je sais plus. C'était peut-être demain.", "flag": {"nina_met": true}, "event": "nina_leave"}
		"tuesday":
			return {"text": _say(["Mardi ? C'était un jour bleu. Avec du blanc dedans. Après, plus rien.", "Je crois que les adultes l'ont perdu. Ils perdent beaucoup de choses, c'est pour ça qu'ils ont des poches.", "Mardi, c'est le jour de la semaine préféré de personne. C'est triste. Il doit être vexé."])}
		"gulls":
			return {"text": _say(["Oui. Elles ne comptent que jusqu'à deux. Après c'est « beaucoup ». Ça me suffit.", "Je les compte, elles s'envolent, et ça fait zéro. Je trouve ça plus honnête."])}
		"secret":
			add_mood("nina", 0.1)
			return {"text": _say(["Le phare n'est pas fermé. Il est... timide.", "La mairie a trois guichets. Le troisième est un secret. Il est caché dans le mot « fermé ».", "Le chat de Barnabé est un coussin. Mais n'en parle pas au coussin."])}
		_:
			return {"text": "Hihi."}


# ---------------------------------------------------------------------------
# THÉODORE PATATRAS, LE MAIRE
# ---------------------------------------------------------------------------

func _mayor_greet(name: String) -> Dictionary:
	if not s().get("mayor_met", false):
		return {"text": "Ah ! Un nouvel arrivant ! Parfait ! Enfin, parfait... Avez-vous vu mon registre ? Non ? Bien sûr que non.", "flag": {"mayor_met": true}}
	if s().get("calendar_seen", false) and not s().get("tuesday", false):
		return {"text": _say(["Ah, %s... Vous avez l'air d'avoir vu mon calendrier. Je préfère ne pas en parler." % name, "Mon calendrier ? Il est parfaitement normal. Parfaitement. Nous sommes mercredi."])}
	if not s().get("registered", false):
		return {"text": _say(["%s ! Vous venez vous enregistrer ? Parfait. Où est le registre ? Question suivante." % name, "Bonjour, bonjour ! Le formulaire d'arrivée ? Il y a une procédure. Je la cherche."])}
	return {"text": _say(["Bonjour %s. Tout se passe bien ? Dites oui, c'est plus simple." % name, "Ah, vous ! Si vous croisez un registre vert... ou bleu... prévenez-moi.", "Le village va bien. Il a soixante-deux habitants. Trois, si on compte les mouettes. On recompte demain."])}


func _mayor_options() -> Array:
	var out: Array = []
	if not s().get("registered", false):
		out.append(["register", "Je viens m'enregistrer."])
	out.append(["day", "Quel jour sommes-nous ?"])
	out.append(["counters", "C'est quoi tous ces guichets ?"])
	if s().get("mayor_met", false) and not s().get("desk_ok", false):
		out.append(["desk", "Je peux regarder votre bureau ?"])
	if s().get("calendar_seen", false) and not s().get("tuesday", false):
		out.append(["tuesday_missing", "Il manque le mardi dans votre calendrier !"])
	elif s().get("tuesday", false):
		out.append(["tuesday_again", "Parlez-moi de mardi."])
	return out


func _mayor_respond(intent: String) -> Dictionary:
	match intent:
		"register":
			add_mood("mayor", 0.15)
			return {"text": "Le registre des nouveaux arrivants... il était là. Il est toujours là. Sauf aujourd'hui. Bon ! J'improvise : voilà, vous êtes officiellement arrivé. Provisoirement. Sur le dos d'un menu.", "flag": {"registered": true}, "event": "registered"}
		"day":
			return {"text": _say(["Mercredi, évidemment ! Pourquoi cette question ? Elle est normale, la question ?", "Mercredi. Et ne me demandez pas hier. Hier, c'est... lundi. Lundi, voilà.", "Mercredi ! Je l'ai écrit sur mon calendrier. Enfin, il y en a un."])}
		"counters":
			return {"text": _say([
				"Guichet 1 : objets perdus. Guichet 2 : objets trouvés. Guichet 3 : objets qu'on n'est pas certain d'avoir perdus. Il est fermé. Employé introuvable.",
				"Le guichet 3 est le plus demandé. Dommage qu'il n'ait jamais ouvert. On cherche l'employé. Il est quelque part. Probablement dans le guichet 1.",
			])}
		"desk":
			add_mood("mayor", 0.1)
			return {"text": "Mon bureau ? Faites donc ! Si vous trouvez le registre, il est à vous. Enfin, à la mairie. Enfin, à moi.", "flag": {"desk_ok": true}, "event": "desk_ok"}
		"tuesday_missing":
			add_mood("mayor", -0.1)
			return {"text": "Le mardi ? Quel mardi ? C'est normal. Nous sommes mercredi. ... C'est normal, n'est-ce pas ? Tenez, prenez ce carnet. Il se remplit tout seul. Enfin, c'est ce que prétend le fournisseur.", "give": "carnet", "flag": {"tuesday": true}, "event": "tuesday_quest"}
		"tuesday_again":
			return {"text": _say([
				"Je n'ai rien contre le mardi. Simplement, je ne l'ai pas vu. Ça arrive à tout le monde.",
				"Demandez à ceux qui travaillent. Le boulanger, le pêcheur, Malo, madame Pétronille. Moi, je n'ai que des formulaires.",
				"Si vous trouvez quelque chose, ne me le dites pas trop vite. J'ai déjà beaucoup de choses à ne pas comprendre.",
			])}
		_:
			return {"text": "Hm ?"}
