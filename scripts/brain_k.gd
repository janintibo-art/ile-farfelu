extends RefCounted
## Les habitants de Belloche (chapitre 4) : Petit Tam (tambours), Maître Sifflot (oiseaux, flûtes)
## et Dame Carillon (cloches). Tant que k_done n'est pas posé, ils n'ont plus de voix : ils miment,
## et Pico « traduit ». Ensuite, ils parlent.

const IDS := ["tam", "sifflot", "carillon"]


static func greet(who: String, name: String, s: Dictionary, say: Callable) -> Dictionary:
	var done: bool = s.get("k_done", false)
	match who:
		"tam":
			if done:
				return {"text": say.call(["BOUM ! Je parle ! Je tape ! Je peux faire les deux en même temps !", "%s ! Tu as entendu mes tambours ? Ils font du bruit exprès !" % name]), "flag": {"tam_met": true}}
			return {"text": say.call(["*Il ouvre la bouche. Rien n'en sort. Il tape sur ses genoux, très vexé.*", "*Il te montre ses baguettes, puis le ciel, puis ses oreilles. Pico : « Il dit qu'il avait un rythme, hier. »*"]), "flag": {"tam_met": true}}
		"sifflot":
			if done:
				return {"text": say.call(["Ah, la voix revient en bas des escaliers ! %s, vous avez les oreilles propres, vous. Entrez, que je vous siffle un merci." % name, "Je sifflote, donc je suis. Enfin, je sifflotais déjà avant. Mais là, ça s'entend."]), "flag": {"sifflot_met": true}}
			return {"text": say.call(["*Il pince les lèvres et souffle. Un filet d'air, rien de plus. Il hausse les épaules, désolé.*", "*Il mime un oiseau, puis l'envole de sa main vers les arbres. Pico : « Il a perdu un oiseau. Un petit. Jaune. »*"]), "flag": {"sifflot_met": true}}
		"carillon":
			if done:
				return {"text": say.call(["Mes cloches ! Toutes ! Elles sonnent en retard, mais elles sonnent.", "Bonjour %s. Je suis Dame Carillon. J'ai quarante ans de métier et un seul regret : ne pas avoir parlé plus tôt." % name]), "flag": {"carillon_met": true}}
			return {"text": say.call(["*Elle ouvre une main vers le clocher, puis fait le geste de tirer une corde. Pico : « Elle dit que la Grosse Cloche est muette depuis hier. »*", "*Elle montre cinq cloches colorées, chante sans bruit, et lève cinq doigts.*"]), "flag": {"carillon_met": true}}
	return {"text": "..."}


static func options(who: String, s: Dictionary) -> Array:
	var out: Array = []
	var done: bool = s.get("k_done", false)
	match who:
		"tam":
			if not s.get("k_drum", false):
				out.append(["drum", "Vous voulez que je joue ?"])
			out.append(["who", "Qui vous a volé la voix ?"])
			if done:
				out.append(["after", "Et maintenant ?"])
		"sifflot":
			if not s.get("k_bird", false):
				out.append(["bird", "Un oiseau perdu ?"])
			out.append(["flute", "Vous faites des flûtes ?"])
			if done:
				out.append(["after", "Et maintenant ?"])
		"carillon":
			if not s.get("k_bell", false):
				out.append(["bells", "Ces cinq cloches ?"])
			out.append(["tower", "Pourquoi la Grosse Cloche ne sonne plus ?"])
			if done:
				out.append(["door", "La porte sous le clocher ?"])
	return out


static func respond(who: String, intent: String, s: Dictionary, say: Callable) -> Dictionary:
	var done: bool = s.get("k_done", false)
	match who + ":" + intent:
		"tam:drum":
			return {"text": "*Il montre trois tambours : bois, métal, pierre. Il en tape quelques-uns, puis te tend les baguettes. Pico : « Il dit : écoute-moi, puis refais pareil. Le gros bouton ‹ Écouter Tam › est près de lui. »*"}
		"tam:who":
			if done:
				return {"text": "Un pot ! Un pot avec une étiquette ! Il disait « Conservé ». Et soudain plus rien ne faisait de bruit. Je n'ai jamais aimé qu'on range mon rythme."}
			return {"text": "*Il montre un pot d'argile, mime de la fermer à clé, puis hausse les épaules. Pico : « Quelqu'un a mis le son en conserve. »*"}
		"tam:after":
			return {"text": say.call(["Je peux faire bruit à volonté. Je commence par en faire beaucoup.", "Sous le clocher, il y a une porte qui n'a jamais ouvert. Même mes tambours n'y arrivent pas. Elle attend peut-être une voix plus fausse."])}
		"sifflot:bird":
			return {"text": "*Il agite les mains comme des ailes, puis se tient l'oreille. Pico : « Il dit : écoutez le vent. L'oiseau chante de l'arbre où il se cache. Regardez dans le bon. »*"}
		"sifflot:flute":
			if done:
				return {"text": "Des flûtes en roseau, en os, en bois de cloche. Toutes accordées, enfin. Sauf une, que je garde pour les visiteurs qui chantent faux."}
			return {"text": "*Il te montre des flûtes sur le mur. Il en porte une à la bouche. Rien. Il fait un signe de fermeture éclair sur ses lèvres.*"}
		"sifflot:after":
			return {"text": "Mon petit oiseau jaune s'appelle Ding. Il a fait un bruit si joli en revenant que j'ai pleuré dans ma flûte. Elle a mal pris."}
		"carillon:bells":
			return {"text": "*Elle écoute l'air avec ses mains, puis tape cinq doigts, un par cloche. Pico : « Il y a un air à rejouer. Le gros bouton ‹ Écouter l’air › est au-dessus du support. Rouge, orange, verte, bleue, violette : de gauche à droite. »*"}
		"carillon:tower":
			if done:
				return {"text": "Elle attendait trois sons rendus. Un rythme, un oiseau, un air. C'est tout le village qui s'était mis en pot. Je dois remercier quelqu'un. Vous, peut-être. Ou la Grosse Cloche."}
			return {"text": "*Elle montre trois choses : une baguette, une plume, une note. Puis le clocher. Pico : « Il faut d'abord rendre ces trois sons au village. Ensuite la corde. »*"}
		"carillon:door":
			if s.get("ch4_done", false):
				return {"text": "Elle s'est ouverte ? Sur une fausse note ? ...Voilà pourquoi nos ancêtres ne l'ont jamais ouverte : ils étaient tous justes. Quelle tristesse. Quelle chance, aussi."}
			return {"text": "La Cathédrale des Échos. Elle est sous nos pieds depuis des siècles. Chaque salle répète ce qu'on lui chante, et aucune ne s'est jamais laissé ouvrir au bout. Il faudrait une mélodie... qu'on n'a pas encore inventée."}
	return {"text": "Hm ?"}


static func idle(who: String, s: Dictionary, say: Callable) -> String:
	var done: bool = s.get("k_done", false)
	match who:
		"tam":
			if done:
				return say.call(["Boum. Boum. Boum-boum-boum.", "Je tape fort parce que je peux."])
			return say.call(["*tape sur ses genoux, très doucement*", "*soupire en rythme*"])
		"sifflot":
			if done:
				return say.call(["Fiu-fiu-fiu. Ça marche. Fiu.", "Un oiseau jaune, trois notes, pas de pot. Quelle belle journée."])
			return say.call(["*souffle dans une flûte. Un filet d'air.*", "*regarde les arbres avec espoir*"])
		"carillon":
			if done:
				return say.call(["Ding. Dong. Ding. J'adore ce métier.", "Il faudra que quelqu'un tende l'oreille, sous le clocher."])
			return say.call(["*chante sans bruit, les yeux fermés*", "*touche une cloche. Le battant bouge. Aucun son.*"])
	return "..."
