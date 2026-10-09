extends RefCounted
## Les habitants de Brumelune (chapitre 3) : Honoré le boulanger, Marin Ouessant,
## Hortense et Léo. Leurs réponses dépendent des bulles de souvenir tenues par le joueur
## (flag b_hold) et de ce qui a déjà été rendu (flags b_g_* pris, b_d_* rendus).

const IDS := ["honore", "ouessant", "hortense", "leo"]


static func greet(who: String, name: String, s: Dictionary, say: Callable) -> Dictionary:
	match who:
		"honore":
			if s.get("b_d_four", false):
				return {"text": say.call(["Du pain ! Je fais du pain ! Je ne sais plus ramer, mais je ne sais plus pourquoi je voudrais.", "Bonjour %s ! La pâte lève. Moi aussi, un peu." % name]), "flag": {"honore_met": true}}
			return {"text": say.call(["Bonjour... %s ? Je suis boulanger. Ou capitaine. Je tiens la baguette comme on tient une barre." % name, "Chut. J'entends la mer dans le four. Ce n'est pas normal. Mais ça sent bon."]), "flag": {"honore_met": true}}
		"ouessant":
			if s.get("b_d_mer", false) and s.get("b_d_cap", false):
				return {"text": say.call(["Ahoy %s ! Je suis marin. Pas de chèvre. Juste une, qui me regarde bizarrement." % name, "La mer me parle de nouveau. Elle dit « enfin »."]), "flag": {"ouessant_met": true}}
			return {"text": say.call(["Bonjour %s. Je suis éleveur de chèvres. Trois. Elles s'appellent... non, je ne sais plus. Mais je les aime." % name, "Je ne sais plus naviguer, et je n'ai jamais eu de bateau. Celui-ci est à sec, par prudence."]), "flag": {"ouessant_met": true}}
		"hortense":
			match str(s.get("b_hortense", "")):
				"give":
					return {"text": say.call(["Aristide... Il chantait faux, et il me manque. C'est merveilleux de manquer de quelqu'un. J'avais oublié ce que c'était.", "Entrez, %s. Il y a deux tasses. Les deux sont à quelqu'un." % name]), "flag": {"hortense_met": true}}
				"keep":
					return {"text": say.call(["Léo garde mon Aristide, et moi je garde ma paix. Je mets une seule tasse. Elle est vide, mais bien rangée.", "Bonjour %s. Tout va bien. J'ai l'impression que quelque chose va bien, ailleurs, sans moi." % name]), "flag": {"hortense_met": true}}
				"share":
					return {"text": say.call(["J'ai gardé la table, la chanson, le prénom. Le reste, c'est à Léo, qui en prend soin. On se partage Aristide, comme du pain.", "Bonjour %s. Il chantait faux. Je le sais, maintenant. Un petit morceau, mais le bon." % name]), "flag": {"hortense_met": true}}
			return {"text": say.call(["Bonjour, mon petit. Deux tasses sur la table, toujours. Je ne sais pas pourquoi. L'une est pour moi. L'autre... il fait froid de ce côté.", "Entrez %s. Je cherche quelque chose depuis des années. Je ne sais pas quoi, mais je le cherche proprement." % name]), "flag": {"hortense_met": true}}
		"leo":
			match str(s.get("b_hortense", "")):
				"give":
					return {"text": say.call(["Je n'ai plus le chagrin d'un autre. Mais il me manque un peu... c'est idiot.", "%s ! Elle l'a retrouvé. Moi, je suis juste... léger. Trop léger." % name]), "flag": {"leo_met": true}}
				"keep":
					return {"text": say.call(["Je garde. Quelqu'un doit se souvenir de lui. Je ferai de mon mieux pour ne pas pleurer dans ses soupes.", "Bonjour %s. J'ai un vieux monsieur dans la tête. Il est gentil. On s'entend bien." % name]), "flag": {"leo_met": true}}
				"share":
					return {"text": say.call(["Je garde le plus gros, elle garde le plus doux. Je crois qu'Aristide aurait fait pareil.", "%s ! Il a une voix fausse, ce monsieur. Elle me fait rire, maintenant." % name]), "flag": {"leo_met": true}}
			return {"text": say.call(["Je me suis réveillé avec le chagrin d'un autre. Je connais le prénom d'une vieille dame que je n'ai jamais saluée.", "Bonjour %s. Je pleure depuis hier, et je ne sais pas qui est mort. Il paraît que c'est pratique, pour la discrétion." % name]), "flag": {"leo_met": true}}
	return {"text": "..."}


static func options(who: String, s: Dictionary) -> Array:
	var out: Array = []
	var hold := str(s.get("b_hold", ""))
	match who:
		"honore":
			if not s.get("b_g_mer", false):
				out.append(["orb", "Cette bulle bleue, sur votre tête ?"])
			if hold != "":
				out.append(["give", "Cette bulle est à vous ?"])
			out.append(["sailor", "Vous avez vraiment été marin ?"])
			out.append(["fog", "La brume parle ?"])
		"ouessant":
			if not s.get("b_g_chev", false):
				out.append(["orb", "Cette bulle verte, près de vous ?"])
			if hold != "":
				out.append(["give", "Cette bulle est à vous ?"])
			if s.get("b_done", false) and s.get("b_d_mer", false) and not s.get("b_tide", false):
				out.append(["tide", "La trappe attend la marée basse."])
			out.append(["goats", "Vos trois chèvres ?"])
			out.append(["boat", "Pourquoi ce bateau est-il à sec ?"])
		"hortense":
			if hold == "vie":
				out.append(["vie_give", "Voici votre bulle, Madame. Toute."])
				out.append(["vie_keep", "Je la rends à Léo. Vous êtes bien comme ça."])
				if s.get("b_voice_a", false):
					out.append(["vie_share", "Une part : la table, la chanson. Le reste à Léo."])
			elif hold != "":
				out.append(["give", "Cette bulle est à vous ?"])
			if str(s.get("b_hortense", "")) == "":
				out.append(["cups", "Pourquoi deux tasses ?"])
				out.append(["husband", "Vous avez été mariée ?"])
			else:
				out.append(["after", "Comment allez-vous ?"])
		"leo":
			if not s.get("b_g_vie", false) and str(s.get("b_hortense", "")) == "":
				out.append(["orb", "Cette bulle dorée, qui pèse sur vous ?"])
			if hold != "" and hold != "vie":
				out.append(["give", "Cette bulle est à vous ?"])
			out.append(["cry", "Vous pleurez ?"])
			if str(s.get("b_hortense", "")) != "":
				out.append(["after", "Et maintenant ?"])
	return out


static func respond(who: String, intent: String, s: Dictionary, say: Callable) -> Dictionary:
	var hold := str(s.get("b_hold", ""))
	match who + ":" + intent:
		"honore:orb":
			if hold != "":
				return {"text": "Vous tenez déjà une bulle. Rendez-la d'abord, mon petit : on n'a que deux mains, et le pain en demande une."}
			return {"text": "Cette bulle ? Elle sent le sel. Je ne sais pas ramer, mais je me souviens du roulis. Prenez-la : je me sens tout léger, soudain. Et très envie de farine.", "event": "b_take_mer"}
		"honore:give":
			if hold == "four":
				return {"text": "Ma pâte ! Mon levain ! Quatre heures du matin ! Oh... oui. Voilà ce que je faisais ici. Merci, %s : je vous offre une miche. Elle est virtuelle, mais très croustillante." % "mon ami", "event": "b_ok_four"}
			return {"text": "Non, ça sent la mer, ou la chèvre. Rendez-la à son propriétaire. Moi, ma bulle sent le pain.", "event": "b_wrong"}
		"honore:sailor":
			return {"text": say.call(["Marin ? Je suis boulanger ! ...Enfin, il me semble. Mais ma main gauche sait faire un nœud de chaise.", "Hier j'ai pétri un cap. Aujourd'hui je ne sais plus à quoi je pensais."])}
		"honore:fog":
			return {"text": "La brume garde les voix. Parfois on y entend une conversation d'il y a dix ans. Parfois celle qu'on aura demain. Moi, j'y entends un bruit de four."}
		"ouessant:orb":
			if hold != "":
				return {"text": "Vous en tenez déjà une. Je les compte, moi : elles se multiplient la nuit."}
			return {"text": "Cette bulle verte ? Ce sont mes chèvres ! Trois ! Mimosa, Tonnerre... Pâque... non. Je ne les ai jamais eues. Mais je les aime ! Prenez-la, je ne sais plus si c'est un cadeau ou une plainte.", "event": "b_take_chev"}
		"ouessant:give":
			if hold == "mer":
				return {"text": "LA MER ! Je sens le sel, la voile, l'orage ! ... Je suis marin ! Tout me revient, sauf le bateau. Il est dehors, à sec. Je me suis juste trompé de sol.", "event": "b_ok_mer"}
			if hold == "cap":
				return {"text": "Le nord-nord-est ! La Grande Ourse ! Oui, c'est à moi, ça. Qui avait ça ? ...La chèvre ? Évidemment : elle regarde toujours les étoiles. Je comprends tout.", "event": "b_ok_cap"}
			return {"text": "Hmm. Non. Je ne reconnais pas cette bulle. Elle n'a pas le roulis.", "event": "b_wrong"}
		"ouessant:tide":
			return {"text": "La marée basse ? Je la sens dans mes genoux. Ce soir, la lune tire l'eau vers le large. Allez ouvrir votre trappe : elle se laissera faire. Et prenez une bougie : l'Archive n'aime pas qu'on lise dans le noir.", "flag": {"b_tide": true}}
		"ouessant:goats":
			return {"text": say.call(["Trois chèvres. Ou une. Une qui vaut trois, je dirais. Elle me regarde fixement. Elle sait quelque chose.", "Je ne les ai jamais eues... mais je sais comment elles aiment qu'on leur parle du temps."])}
		"ouessant:boat":
			return {"text": "Il est à sec parce que la marée l'a oublié. Elle a eu un trou. Comme moi. On se comprend, lui et moi."}
		"hortense:give":
			return {"text": "Cette bulle n'est pas à moi, mon petit. Je le sens : la mienne est plus lourde et plus tiède.", "event": "b_wrong"}
		"hortense:vie_give":
			return {"text": "Oh. Aristide. Il chantait faux en pétrissant... et il y a eu cette tasse de plus, tous les soirs, jusqu'au jour où... Oui. Je me souviens de tout. Même de la fin. Merci, mon petit. Ça fait mal. C'est que ça comptait.", "event": "b_hort_give"}
		"hortense:vie_keep":
			return {"text": "Rendez-la à Léo. Il pleure pour un homme qu'il n'a pas connu, mais il pleure bien. Moi, je suis tranquille. Je mets une tasse. Une seule. Elle est vide, mais bien rangée.", "event": "b_hort_keep"}
		"hortense:vie_share":
			return {"text": "...La table. La chanson. Son prénom. Oui. Je garde ça. Je ne veux pas le reste, ça ne tient pas dans une vieille poitrine. Léo gardera la suite. Il en prendra soin. N'est-ce pas, Léo ?", "event": "b_hort_share"}
		"hortense:cups":
			return {"text": "Je les mets toutes les deux. Je ne sais pas pourquoi. Je ne bois que dans une. L'autre refroidit, mais proprement."}
		"hortense:husband":
			return {"text": "Mariée ? Non. Enfin... non. Il me semble qu'on m'a gardé une place à table, un jour. Ça me revient comme un parfum qui n'est plus dans la pièce."}
		"hortense:after":
			match str(s.get("b_hortense", "")):
				"give":
					return {"text": "Je pleure. Je souris. Je mets deux tasses, et il y en a une qui chante faux. C'est parfait."}
				"keep":
					return {"text": "Très bien. Léo vient parfois prendre le thé. Il me raconte un monsieur que je n'ai pas connu. Il le raconte bien."}
				_:
					return {"text": "J'ai gardé le prénom, la table, la chanson. C'est peu, mais c'est à moi, et ça se pose sur une étagère."}
		"leo:orb":
			if hold != "":
				return {"text": "Vous tenez déjà une bulle. Rendez-la d'abord. Celle-ci ne sera pas plus légère demain."}
			return {"text": "Cette bulle dorée ? Elle est à un monsieur que je n'ai jamais vu. Il aimait une dame... elle habite là-bas, à côté. Elle ne le sait plus. Moi je le sais tout, et je ne sais pas quoi en faire. Tenez : si vous savez, décidez. Mais décidez doucement.", "event": "b_take_vie"}
		"leo:give":
			return {"text": "Non, ce n'est pas la mienne. La mienne est dorée, et trop lourde pour moi.", "event": "b_wrong"}
		"leo:cry":
			return {"text": say.call(["Un peu. Je n'ai pas de raison. J'ai seulement la mémoire de quelqu'un d'autre.", "Je pleure pour un monsieur très poli que je ne connais pas. Il est mort, paraît-il. Je suis désolé pour lui, c'est tout."])}
		"leo:after":
			match str(s.get("b_hortense", "")):
				"give":
					return {"text": "Je me sens vide, mais pas triste. C'est bizarre : j'avais fini par m'attacher à ce chagrin."}
				"keep":
					return {"text": "Je garde. Ça pèse, mais je n'ai pas à le porter tout seul : Hortense, de temps en temps, me demande des nouvelles de quelqu'un dont elle ignore le nom."}
				_:
					return {"text": "On se le partage. Elle prend le doux, je prends le reste. On a l'air de deux voisins qui se prêtent une casserole."}
	return {"text": "Hm ?"}


static func idle(who: String, s: Dictionary, say: Callable) -> String:
	match who:
		"honore":
			return say.call(["Une baguette, c'est une rame pour les gens qui n'ont pas de bateau.", "Je sens la mer dans la pâte. C'est bizarre. C'est salé."])
		"ouessant":
			return say.call(["Le bateau est à sec. Moi aussi, parfois.", "Une chèvre me regarde depuis ce matin. Je commence à me sentir jugé."])
		"hortense":
			return say.call(["Une tasse de plus. Pour qui ? Pour le courant d'air.", "Il me semble que j'ai oublié quelque chose de très grand. Comme un meuble."])
		"leo":
			return say.call(["Je pleure pour un monsieur. Il était très bien, apparemment.", "J'ai de la peine, et je ne sais même pas à qui la rendre."])
	return "..."
