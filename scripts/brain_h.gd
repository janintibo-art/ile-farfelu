extends RefCounted
## Les habitants des Hautes-Miettes (chapitre 5) : Gaspard Minuit (le maire), Madame Quart
## (l'horlogère) et Petit Zéphyr (le seul qui soit toujours en retard, donc épargné).
## Le flag h_loops compte les boucles que le village a déjà vécues.

const IDS := ["minuit", "quart", "zephyr"]


static func greet(who: String, name: String, s: Dictionary, say: Callable) -> Dictionary:
	var done: bool = s.get("h_done", false)
	var loops: int = int(s.get("h_loops", 0))
	match who:
		"minuit":
			if done:
				return {"text": say.call(["Plus de boucle. Plus de minutes volées. Je suis presque déçu : j'avais préparé trois discours.", "%s ! Il est %s. Exactement. Je me méfie." % [name, "trois heures pile"]]), "flag": {"minuit_met": true}}
			if loops >= 3:
				return {"text": say.call(["Vous êtes déjà venu me parler il y a cinq minutes. Et il y a cinq minutes de ça. Enfin, plus tard. Ça dépend du cadran.", "Encore vous ! Mais en avance, cette fois. Je ne sais pas si c'est un compliment."]), "flag": {"minuit_met": true}}
			return {"text": say.call(["Gaspard Minuit, maire des Hautes-Miettes. Quelqu'un vole des minutes. Et j'aimerais beaucoup qu'il commence par les réunions municipales.", "Bonjour %s. Vous êtes à l'heure. C'est suspect, ici." % name]), "flag": {"minuit_met": true}}
		"quart":
			if done:
				return {"text": say.call(["Mon atelier est enfin en phase avec le monde. Il me manque un quart d'heure, mais je le retrouverai.", "Bonjour %s. Les cadrans sont d'accord. C'est la première fois depuis l'invention des cadrans." % name]), "flag": {"quart_met": true}}
			return {"text": say.call(["Madame Quart, horlogère. Je répare tout, sauf les retards, qui sont une affaire personnelle.", "%s ! Vous venez pour l'heure exacte ? Il y a quatre cadrans sur la place. Ils ne se parlent plus." % name]), "flag": {"quart_met": true}}
		"zephyr":
			return {"text": say.call(["Salut. Je suis en retard. Je suis toujours en retard. C'est pour ça que je vois tout : j'arrive après.", "%s ! T'as raté le début. Moi aussi. On est quittes." % name]), "flag": {"zephyr_met": true}}
	return {"text": "..."}


static func options(who: String, s: Dictionary) -> Array:
	var out: Array = []
	var done: bool = s.get("h_done", false)
	match who:
		"minuit":
			out.append(["steal", "Quelqu'un vole des minutes ?"])
			if not s.get("h_sync", false):
				out.append(["clocks", "Ces quatre cadrans qui ne se parlent plus ?"])
			out.append(["council", "Les réunions, c'est à quelle heure ?"])
			if done:
				out.append(["after", "Et maintenant ?"])
		"quart":
			out.append(["loop", "Le temps revient en arrière ?"])
			if not s.get("h_sync", false):
				out.append(["fix", "Comment accorder les cadrans ?"])
		"zephyr":
			out.append(["late", "Pourquoi êtes-vous toujours en retard ?"])
			if _clue_count(s) < 3 and not done:
				out.append(["watch", "Que se passe-t-il sur la place ?"])
	return out


static func _clue_count(s: Dictionary) -> int:
	var n := 0
	for k in 3:
		if s.get("h_d%d" % k, false):
			n += 1
	return n


static func respond(who: String, intent: String, s: Dictionary, say: Callable) -> Dictionary:
	match who + ":" + intent:
		"minuit:steal":
			return {"text": say.call(["Chaque jour, vers quatorze heures, la place rejoue cinq minutes, puis le monde reprend comme si de rien n'était. Moi, je vieillis moins vite, ça m'inquiète à peine.", "Il paraît qu'un homme en gris passe sur la place. Je ne l'ai jamais vu. J'étais en réunion."])}
		"minuit:clocks":
			return {"text": "Les quatre cadrans de la place devraient indiquer la même heure : celle du conseil. Madame Quart dit que sans accord, le temps ne sait plus où se mettre. Moi je dis que c'est le vent."}
		"minuit:council":
			return {"text": "Trois heures. Pile. C'est écrit sur la tour. Je les ai en horreur, ces réunions. Mais je les préside avec une grande exactitude."}
		"minuit:after":
			return {"text": "Hubert Sablier est reparti avec ses pots vides. Le Château, lui, attend sûrement un rapport. Allez donc voir l'Observatoire : c'est là-haut que tout rembobine."}
		"quart:loop":
			return {"text": "Oui. Cinq minutes, toujours les mêmes. Pas de panne, pas de réparation possible : le mécanisme principal est là-haut, à l'Observatoire. Ici, on ne fait que le regarder se tromper."}
		"quart:fix":
			return {"text": "Chaque cadran a un petit cran sous son aiguille. Une pression, une heure. Réglez-les tous sur l'heure du conseil : trois heures. Sinon le temps hésite, et une journée hésitante, ça fait des boucles."}
		"zephyr:late":
			return {"text": "Un retard, c'est une avance à l'envers. Les boucles ne m'attrapent pas : je suis toujours cinq minutes derrière, donc avant qu'elles commencent."}
		"zephyr:watch":
			return {"text": "Regarde bien la place quand la grande pendule se remet à zéro. À chaque tour, il y a un truc différent. Moi je ne note pas, j'ai pas le temps. Si tu vois un détail, il y a un endroit pour le noter, au milieu."}
	return {"text": "Hm ?"}


static func idle(who: String, s: Dictionary, say: Callable) -> String:
	match who:
		"minuit":
			return say.call(["À quelle heure est la prochaine réunion ? Dans cinq minutes. Encore.", "Je suis à l'heure. C'est tout ce que je sais faire."])
		"quart":
			return say.call(["Tic. Tac. Pas tout à fait ensemble.", "Un cadran qui avance, c'est un cadran qui a peur."])
		"zephyr":
			return say.call(["Je suis presque à l'heure. Presque. C'est mon style.", "Attends-moi, j'arrive. Bientôt."])
	return "..."
