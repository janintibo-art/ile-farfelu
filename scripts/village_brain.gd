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
	if who in EXTRA:
		return _x_greet(who, name)
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
	if who in EXTRA:
		return _x_options(who)
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
	if who in EXTRA:
		return _x_respond(who, intent)
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
	if who in EXTRA:
		return _x_idle(who)
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
	if who in EXTRA:
		return _x_bonked(who)
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
	if s().get("ledger_seen", false) and not s().get("eleonore_known", false):
		out.append(["who7", "Le livre de comptes dit « E. Chardon » pour la 7."])
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
		"who7":
			add_mood("malo", 0.1)
			return {"text": "...Vous avez lu le livre. Bon. Éléonore Chardon, horlogère. Elle a loué la 7 mardi, puis elle s'est cachée dans la maison abandonnée, côté est du village. Ne dites pas que c'est moi. Dites que c'est le livre.", "flag": {"eleonore_known": true, "c_inn": true}, "event": "eleonore_known"}
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
	if Save.count("cle") > 0:
		if s().get("key_asked", false):
			out.append(["key_sell", "D'accord, je vous la vends (200)"])
			out.append(["key_no", "Non, je la garde."])
		else:
			out.append(["key", "J'ai une petite clé en cuivre... Ça vous dit ?"])
	if s().get("tuesday", false):
		out.append(["tuesday", "Vous avez travaillé mardi ?"])
	return out


func _barnabe_respond(intent: String) -> Dictionary:
	match intent:
		"key":
			return {"text": "Une petite clé en cuivre ?! Je... vous en donne deux cents coquillages. Tout de suite. Ne posez pas de questions.", "flag": {"key_asked": true}}
		"key_sell":
			return {"text": "Marché con... Non. Non, attendez. Gardez-la. Je ne peux pas. Gardez-la bien, surtout. Et ne la montrez à personne.", "flag": {"key_refused": true}, "event": "key_back"}
		"key_no":
			return {"text": "Bien. Très bien. C'est mieux comme ça. Je dis ça, je dis rien. Je ne dis jamais rien. C'est mon problème."}
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
	if s().get("mardi", false) and not s().get("mayor_mardi", false):
		return {"text": "Mardi ?! Il est REVENU ! Il y a eu un marché, des pains, tout ! ... Et j'ai retrouvé mon registre. Il était dans mon chapeau. Je n'ai pas de chapeau.", "flag": {"mayor_mardi": true}}
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


# ---------------------------------------------------------------------------
# Les autres habitants : Basile, Gérard, Marguerite, Pétronille, Éléonore
# ---------------------------------------------------------------------------

const EXTRA := ["basile", "gerard", "marguerite", "petronille", "eleonore", "odile", "gaspard", "anselme", "mirette"]


func _x_greet(who: String, name: String) -> Dictionary:
	var tue: bool = s().get("tuesday", false)
	match who:
		"basile":
			if s().get("phare_done", false):
				return {"text": _say(["Alors j'ai fait vingt-sept pains sans aucune raison ? ... Comme tous les mardis, dit mon assistant. Ah oui. Quel assistant ?", "Bonjour %s ! Vingt-sept pains, mardi. Je m'en souviens, maintenant. J'ai aussi retrouvé mon assistant. Il était dans le four." % name]), "flag": {"basile_met": true}}
			return {"text": _say(["Bonjour %s ! Pain du jour, pain d'hier, pain de demain. Je ne garantis pas l'ordre." % name, "Chaud, le pain ! Enfin, il l'était. Il le sera. Il l'a été." , "Ah, un client ! Ou un courant d'air affamé."]), "flag": {"basile_met": true}}
		"gerard":
			return {"text": _say(["Chut. Ils mordent à l'aube, les poissons. Et à midi aussi. Mais ils mordent mal.", "Salut %s. Le poisson d'hier m'en veut encore." % name, "Pas un bruit... bon, un petit bruit."]), "flag": {"gerard_met": true}}
		"marguerite":
			return {"text": _say(["Bonjour ! Vous trouvez pas que cette maison est trop bleue ? Moi non plus.", "%s ! Tenez-vous bien, la peinture sèche quand elle veut." % name]), "flag": {"marguerite_met": true}}
		"odile":
			if s().get("pont_ok", false):
				return {"text": _say(["Un pont pour tout le monde. Gaspard m'a serré la main. J'ai vérifié après : j'ai encore tous mes doigts.", "Je n'ai plus de procès. Je ne sais plus quoi faire de mes dimanches."]), "flag": {"odile_met": true}}
			return {"text": _say(["Halte ! Ce pont est à la famille Aubépine depuis 1203. J'ai l'acte. Il est signé, et même tamponné.", "Encore vous ? Si vous venez pour le pont, il est à nous. Si vous venez pour autre chose, il est à nous aussi.", "Bonjour %s. Le pont est à nous. Je précise, au cas où vous auriez un doute." % name]), "flag": {"odile_met": true}}
		"gaspard":
			if s().get("pont_ok", false):
				return {"text": _say(["Odile m'a offert une brioche. Elle est empoisonnée, forcément. Je la mange quand même.", "Quarante-trois ans de procès, et on se tutoie. La vie est étrange."]), "flag": {"gaspard_met": true}}
			return {"text": _say(["Passez votre chemin ! Ce pont est aux Ronceval depuis 1204. J'ai l'acte, et il est très authentique.", "Ah, un témoin ! Dites bien aux Aubépine que le pont est à nous.", "%s ! Vous tombez bien : le pont est à nous. Vous pouvez le répéter, ça aide." % name]), "flag": {"gaspard_met": true}}
		"mirette":
			return {"text": _say(["Chut. Les grands se disputent fort pour que ça devienne vrai. Moi je pense que le pont s'en fiche.", "Tu cherches la vérité ? Elle est sous le pont. Elle est un peu humide."]), "flag": {"mirette_met": true}}
		"anselme":
			if s().get("pont_ok", false):
				return {"text": _say(["Un pont à tout le monde. Quelle époque. Heureusement, il y a toujours le puits.", "Je suis très content pour tout le monde. Voyez comme mon sourire est calme."]), "flag": {"anselme_met": true}}
			return {"text": _say(["Maître Anselme Plume-d'Oie, notaire. J'établis tous les actes de Virevolte. Les deux familles sont mes clientes. Les deux ont raison. C'est mon métier.", "Bonjour %s. Un acte ? Un testament ? Un mensonge notarié ? Je fais tout, avec beaucoup de tact." % name]), "flag": {"anselme_met": true}}
		"petronille":
			if not tue:
				return {"text": "Entre, mon petit. Ne marche pas sur hier, il est fragile.", "flag": {"petro_met": true}}
			return {"text": _say(["Ah. Tu cherches ce qu'on a rangé, toi. Assieds-toi, ou reste debout, le fauteuil s'en fiche.", "Le thé est prêt depuis mardi. Il n'a pas refroidi."]), "flag": {"petro_met": true}}
		_:
			if s().get("at_v", false):
				return {"text": _say(["Virevolte. Ici, ne croyez pas ce qu'on vous dit trois fois : c'est comme ça que ça devient vrai.", "Deux familles, un pont, deux actes. Quand deux vérités se contredisent, cherchez le menteur qui y gagne.", "Je n'ai jamais aimé les forêts polies. Elles ont toujours quelque chose à cacher."]), "flag": {"eleonore_met": true}}
			if s().get("phare_done", false):
				return {"text": _say(["Je suis à l'auberge, provisoirement. Malo me fait payer la chambre 7 au tarif « mardi ». Je ne comprends pas, mais je paie.", "Alors, %s ? La Première Page ne se lit pas encore. Mais le symbole, lui, je le reconnais. On en reparlera." % name]), "flag": {"eleonore_met": true}}
			if not s().get("eleonore_story", false):
				return {"text": "Vous m'avez trouvée. Ça devait arriver. Par chance, j'avais un plan. Par malchance, il est resté dans mon sac. Asseyez-vous.", "flag": {"eleonore_met": true}}
			return {"text": _say(["Alors, cette roue ? L'horloge n'attend pas. Enfin, elle attend depuis mardi.", "Courage. Les Mains du Dehors rangent mal : il suffit de remettre dans l'ordre."]), "flag": {"eleonore_met": true}}


func _x_options(who: String) -> Array:
	var out: Array = []
	var tue: bool = s().get("tuesday", false)
	match who:
		"basile":
			if tue:
				out.append(["mardi", "Que faisiez-vous mardi ?"])
			if s().get("c_baker", false) and not s().get("got_a", false):
				out.append(["round", "Vous avez perdu un truc rond ?"])
			out.append(["bread", "Un conseil de pain ?"])
		"gerard":
			if tue:
				out.append(["mardi", "Vous avez pêché mardi ?"])
			out.append(["fish", "Ça mord ?"])
			if s().get("fish_seen", false) and not s().get("fish_solved", false):
				out.append(["fish2", "Votre cabane est sur son nid, Gérard."])
			if Save.count("planche") > 0 and not s().get("plank_decided", false):
				if s().get("plank_offer", false):
					out.append(["plank_give", "Prenez-la, la planche."])
					out.append(["plank_keep", "Finalement, je la garde."])
				else:
					out.append(["plank", "J'ai une planche. Ça vous intéresse ?"])
		"marguerite":
			if tue:
				out.append(["mardi", "Et mardi, vous peigniez ?"])
			out.append(["blue", "Pourquoi cette couleur ?"])
		"odile":
			if not s().get("doc_a", false):
				out.append(["doc", "Montrez-moi votre acte."])
			out.append(["ronceval", "Et les Ronceval ?"])
			out.append(["forest", "Cette forêt est étrange."])
		"gaspard":
			if not s().get("doc_b", false):
				out.append(["doc", "Montrez-moi votre acte."])
			out.append(["aubepine", "Et les Aubépine ?"])
			out.append(["forest", "Cette forêt est étrange."])
		"mirette":
			out.append(["bridge", "Que sais-tu du pont ?"])
			out.append(["lies", "Les mensonges deviennent vrais ?"])
		"anselme":
			if s().get("doc_a", false) and s().get("doc_b", false):
				out.append(["both", "Vous avez écrit les deux actes ?"])
			out.append(["conflict", "Que pensez-vous du conflit ?"])
			out.append(["forest", "Cette forêt ment, non ?"])
		"petronille":
			if tue:
				out.append(["mardi", "Le mardi n'a pas disparu ?"])
				if not s().get("c_petro", false):
					out.append(["wheel", "Vous avez quelque chose qui tourne ?"])
			out.append(["tea", "Du thé ?"])
		_:
			if s().get("at_v", false):
				if s().get("doc_a", false) and s().get("doc_b", false) and not s().get("same_hand", false):
					out.append(["compare", "Regardez les deux actes."])
				if s().get("same_hand", false) and not s().get("pont_ok", false):
					out.append(["next", "Que fait-on maintenant ?"])
				out.append(["liar", "Cette forêt ment vraiment ?"])
				return out
			if s().get("ch1_done", false):
				out.append(["go", "Partons pour Virevolte."])
			if not s().get("eleonore_story", false):
				out.append(["story", "Qui êtes-vous, vraiment ?"])
			else:
				out.append(["hands", "Les Mains du Dehors, c'est quoi ?"])
				out.append(["sun", "Un conseil pour la maquette ?"])
	return out


func _x_respond(who: String, intent: String) -> Dictionary:
	match who + ":" + intent:
		"basile:mardi":
			return {"text": "Mardi ? J'ai pétri. Je me souviens des mains. Les miennes. Enfin, il y en avait d'autres. Mon registre est dans l'arrière-boutique : il dit vingt-sept fournées. Je n'ose plus le relire."}
		"basile:round":
			return {"text": "Un truc rond, tiède, avec des dents ? Il est parmi les pains. Cherchez-le. Je l'ai pris pour une miche ambitieuse."}
		"basile:bread":
			return {"text": _say(["Le pain croustillant se mérite. Le pain mou se pardonne.", "Mangez-le chaud. Ou froid. Ou jamais, c'est un pain de décoration."])}
		"gerard:mardi":
			return {"text": "Mardi, j'ai pêché une planche. Neuve. Sous la jetée, elle me regardait. Soulevez-la : j'ai pas osé."}
		"gerard:fish2":
			add_mood("gerard", 0.3)
			return {"text": "Sur son nid ?! Mais c'est pour ça qu'il me poursuit ! Je déplace ma cabane sur le quai, demain. Tenez, pour le conseil : quinze coquillages. Le poisson ne sera pas capturé. Moi non plus.", "flag": {"fish_solved": true}, "event": "shells15"}
		"gerard:plank":
			return {"text": "Une planche ?! Droite, sans nœud, presque honnête ! Je vous en donne dix coquillages. Mon menuisier en a besoin. Enfin, j'en ai un. Il s'appelle... peu importe.", "flag": {"plank_offer": true}}
		"gerard:plank_give":
			return {"text": "Vous êtes un ange. Un ange sans planche, maintenant, mais un ange.", "flag": {"plank_decided": true, "plank_given": true}, "event": "plank_give"}
		"gerard:plank_keep":
			return {"text": "Ah. Bon. Tant pis. C'est un grand renoncement. Mais je comprends.", "flag": {"plank_decided": true, "plank_kept": true}, "event": "plank_keep"}
		"gerard:fish":
			return {"text": _say(["Ça mord. Pas le poisson. Les moustiques.", "Le poisson rancunier, il revient toujours. Je le reconnais à son regard."])}
		"marguerite:mardi":
			return {"text": "Mardi, je peignais en bleu. Ensuite il y a eu cette traînée bleue qui file jusqu'au phare. Je n'ai rien fait ! Mon pinceau est contre le mur, regardez la peinture."}
		"marguerite:blue":
			return {"text": _say(["Le bleu, c'est la couleur de ce qu'on n'a pas encore décidé.", "Elle devait être jaune. Elle a choisi toute seule."])}
		"petronille:mardi":
			return {"text": _say(["Le mardi ? On l'a rangé. Le plus dur, c'est de se souvenir où.", "Quand on perd un jour, mon petit, on ne le cherche pas. On cherche ce qu'il a emporté."])}
		"petronille:wheel":
			add_mood("petronille", 0.2)
			return {"text": "Tiens, cette chose verte qui tourne. Elle était dans mon sucrier. Elle sert à quelque chose. À quoi, on te le dira... plus tard. Peut-être hier.", "give": "roue_c", "flag": {"c_petro": true}, "event": "got_piece"}
		"petronille:tea":
			return {"text": _say(["Il est parfait. Il n'a ni goût ni chaleur. C'est ma spécialité.", "Un thé, c'est du temps qu'on boit."])}
		"odile:doc":
			return {"text": "« Le pont appartient aux Aubépine, qui l'ont bâti en 1203, ainsi que la rivière en dessous. » Regardez cette belle écriture penchée. Et cette encre violette : de la bonne famille.", "flag": {"doc_a": true}, "event": "z_doc_a"}
		"odile:ronceval":
			return {"text": _say(["Les Ronceval ? Des menteurs. Charmants, mais menteurs. Gaspard m'a dit bonjour hier, avec l'air sincère. Ça cachait quelque chose.", "Gaspard dit que le pont est à lui. Il le dit si souvent que je commence à le croire. C'est dangereux."])}
		"odile:forest":
			return {"text": "Ici, un mensonge répété trois fois devient vrai. Mon grand-père a dit qu'il avait une barbe. Il en a une depuis. On lui reproche de ne pas l'avoir eue avant."}
		"gaspard:doc":
			return {"text": "« Le pont appartient aux Ronceval, qui l'ont bâti en 1204, ainsi que le ciel au-dessus. » Un an plus récent, donc mieux conservé. L'écriture ? Penchée. L'encre ? Violette. Rien de suspect.", "flag": {"doc_b": true}, "event": "z_doc_b"}
		"gaspard:aubepine":
			return {"text": _say(["Les Aubépine ? Ils disent que le pont est à eux depuis 1203. Ridicule : en 1203, il n'y avait pas de pont. Il y avait... une idée de pont.", "Odile est charmante. Elle me rappelle pourquoi je ne me marierai jamais."])}
		"gaspard:forest":
			return {"text": "Ne dites jamais « il va pleuvoir » trois fois de suite. L'an dernier, Odile l'a fait. Il a plu des poissons. On les a mangés, par politesse."}
		"mirette:bridge":
			return {"text": "Il y a une plaque dessous. Personne ne la lit : elle est trop polie. Va regarder sous le pont. Moi je n'ose pas, les adultes ont dit que ça portait malheur de dire la vérité à voix haute.", "flag": {"mirette_hint": true}, "event": "z_mirette"}
		"mirette:lies":
			return {"text": "Oui ! Hier j'ai dit trois fois « j'ai un dragon ». Maintenant j'ai un lézard. C'est un début. Il me regarde de travers."}
		"anselme:both":
			return {"text": "Rédigé ? Moi ? Je n'écris pas, je consigne. L'encre n'est pas de moi, elle est de la tradition. Ma main est juste... très fidèle à la tradition.", "flag": {"anselme_asked": true}, "event": "z_anselme"}
		"anselme:conflict":
			return {"text": "Un bon conflit fait vivre un village. Et un notaire. Je ne prends pas parti : je prends les deux."}
		"anselme:forest":
			return {"text": "La forêt ne ment pas, elle répète. Si on dit une chose avec assez d'élégance, elle la rend vraie. Je suis en faveur de l'élégance."}
		"eleonore:go":
			return {"text": "Virevolte, la forêt qui ment poliment. Allons-y. Si un arbre vous dit qu'il est à gauche, il est à droite. Et ne promettez rien trois fois.", "flag": {"v2_started": true}, "event": "z_go"}
		"eleonore:compare":
			return {"text": "Montrez... Même écriture penchée. Même encre violette. Deux familles qui se détestent, avec le même scribe. Quelqu'un fabrique leurs certitudes.", "flag": {"same_hand": true}, "event": "z_same_hand"}
		"eleonore:next":
			return {"text": "Les actes ont la même main. Et la plaque dit « Bâti par tous ». Réunissez les deux familles sur le pont : la vérité, dite devant tout le monde, vaut bien trois mensonges."}
		"eleonore:liar":
			return {"text": "Elle ne ment pas. Elle exauce. C'est pire : quelqu'un lui souffle quoi répéter. Je veux savoir qui."}
		"eleonore:story":
			add_mood("eleonore", 0.3)
			return {"text": "Éléonore Chardon, horlogère. Mardi, j'ai réparé l'horloge de la mairie. Puis des mains sont sorties du cadran et m'ont dit « Pas touche ». Alors je me suis cachée. Tenez : l'axe central. Sans lui, la roue du mardi tourne dans le vide.", "give": "axe", "flag": {"eleonore_story": true, "got_axe": true}, "event": "got_axe"}
		"eleonore:hands":
			return {"text": "Les Mains du Dehors rangent les histoires pour qu'on ne s'en serve pas. Sur l'horloge, elles vous montreront ce qu'elles ont rangé. Ce sont des souvenirs, pas des vérités."}
		"eleonore:sun":
			return {"text": "Dans la maquette, quatre souvenirs de la même journée. Regardez le soleil ou la lune : il ne ment pas, lui. Du matin vers la nuit, de gauche à droite."}
	return {"text": "Hm ?"}


func _x_idle(who: String) -> String:
	match who:
		"odile":
			return _say(["Le pont est à nous. Je le dis pour qu'il le sache.", "Si je le répète trois fois, ça devient vrai. Le pont est à nous. Le pont est à nous. Le pont..."])
		"gaspard":
			return _say(["Ce pont est à nous. J'ai l'acte. Je l'ai relu. Il dit pareil.", "Un jour, ce pont sera à nous. Il l'est déjà, mais un jour aussi."])
		"mirette":
			return _say(["Chut, les arbres écoutent.", "Je compte les mensonges. J'en suis à beaucoup."])
		"anselme":
			return _say(["Un acte bien tamponné, c'est la moitié d'une vérité.", "Je vous le dis en toute franchise. C'est-à-dire sans frais."])
		"basile":
			return _say(["Une baguette, c'est un pain qui a de l'ambition.", "Si vous entendez du pain qui chante, c'est normal."])
		"gerard":
			return _say(["Le silence, c'est le meilleur appât.", "Je ne dors pas : je surveille le poisson."])
		"marguerite":
			return _say(["Encore un coup de pinceau et c'est fini. Ou pas.", "La peinture, ça sèche. Parfois dans le mauvais ordre."])
		"petronille":
			return _say(["Le temps passe. Il passe devant, puis derrière.", "Un petit biscuit ? Il est de lundi."])
	return _say(["Tic. Tac. Tac. Tic. Ce n'est pas la bonne cadence.", "Je réparerais bien le monde, mais je n'ai pas les outils."])


func _x_bonked(who: String) -> String:
	return _say(["Ouille ! Je le note dans mon carnet à reproches.", "Hé ! C'était pas prévu un mardi !", "BONK ! Voilà un bruit qu'on n'oublie pas."])
