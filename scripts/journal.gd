extends RefCounted
## Le carnet d'enquête : se remplit tout seul selon les drapeaux de l'histoire.
## Trois onglets : indices, personnes, objets. Chaque ligne tient sur un bouton.

const Save := preload("res://scripts/save.gd")

const TABS := ["clues", "people", "objects", "quests"]
const TAB_NAMES := {"clues": "INDICES", "people": "PERSONNES", "objects": "OBJETS", "quests": "QUÊTES"}


static func _f(k: String) -> bool:
	return Save.story.get(k, false)


static func lines(tab: String) -> Array:
	var out: Array = []
	match tab:
		"clues":
			out.append("Le MARDI a disparu. Personne ne s'en souvient.")
			var n := 0
			for k in ["c_baker", "c_fisher", "c_house", "c_inn", "c_petro", "c_light"]:
				if _f(k):
					n += 1
			out.append("Indices : %d / 6" % n)
			if _f("c_baker"):
				out.append("Boulangerie : 27 fournées notées mardi.")
				out.append("   ...jamais cuites. Qui les a écrites ?")
			if _f("c_fisher"):
				out.append("Ponton : planche neuve + papier bleu (« MARDI »).")
			if _f("c_house"):
				out.append("Maison bleue : traînée de peinture vers le phare.")
			if _f("c_inn"):
				out.append("Auberge : « E. Chardon » a loué la chambre 7.")
				out.append("   ...la chambre 7 « n'existe pas ».")
			if _f("c_petro"):
				out.append("Pétronille : « On n'a pas perdu mardi. On l'a rangé. »")
			if _f("c_light"):
				out.append("Phare : le papier bleu donne l'heure : 21 h.")
			if n >= 3:
				out.append("Conclusion : le mardi a été RANGÉ, pas oublié.")
			if n >= 6:
				out.append("Toutes les pistes mènent à l'horloge de la mairie.")
			if _f("mardi"):
				out.append("RÉSOLU : l'horloge repart. Mardi est revenu.")
			if _f("v2_started"):
				out.append("")
				out.append("VIREVOLTE : un pont, deux familles, deux actes.")
				if _f("doc_a"):
					out.append("Acte Aubépine (1203) : écriture penchée, encre violette.")
				if _f("doc_b"):
					out.append("Acte Ronceval (1204) : même écriture, même encre.")
				if _f("same_hand"):
					out.append("   ...les deux actes sont de la MÊME MAIN.")
				if _f("plaque"):
					out.append("Plaque sous le pont : « Bâti par tous, pour tous. »")
				if _f("greffe_blank"):
					out.append("Greffe : actes du pont vierges, déjà tamponnés.")
				if _f("pont_ok"):
					out.append("RÉSOLU : le pont est à tout le monde.")
				if _f("tr_key"):
					out.append("Maison de Travers : clé géante prise.")
				if _f("mot_juste"):
					out.append("Le Mot Juste : fragment du Registre obtenu.")
					out.append("Anselme : payé par « quelqu'un du Château » pour faire")
					out.append("   répéter que le Grand Cartographe n'existe pas.")
				if _f("ch2_done"):
					out.append("RÉSOLU : la forêt ne ment plus sur le père d'Éléonore.")
			if _f("v3_started"):
				out.append("")
				out.append("BRUMELUNE : des souvenirs ont changé de propriétaire.")
				if _f("b_g_mer"):
					out.append("Bulle bleue (voile, orage) : le boulanger la portait.")
				if _f("b_g_cap"):
					out.append("Bulle violette (étoiles, cap) : la chèvre la portait.")
				if _f("b_g_chev"):
					out.append("Bulle verte (trois chevreaux) : le marin la portait.")
				if _f("b_g_four"):
					out.append("Bulle chaude (levain, pâte) : oubliée dans un four.")
				if _f("b_g_vie"):
					out.append("Bulle dorée (Aristide, la tasse de plus) : Léo la portait.")
				if _f("b_voice_a"):
					out.append("Voix : « Garde-moi une place à table, Hortense. »")
				if _f("b_voice_b"):
					out.append("Voix : « Conserver. Tout conserver. » (Basile)")
				if _f("b_voice_c"):
					out.append("Voix : « Pico... ne leur dis rien. » (?)")
				if _f("b_tide"):
					out.append("Marée basse : la trappe de l'Archive est ouverte.")
				if _f("ar_key"):
					out.append("Archive : bulle-clé prise (ni trop bas, ni trop haut).")
				if _f("ch3_done"):
					out.append("Basile Plume : veut arrêter le phénomène « définitivement ».")
					out.append("   Il était ami avec le Grand Cartographe.")
				match str(Save.story.get("b_hortense", "")):
					"give":
						out.append("Hortense a récupéré toute sa mémoire d'Aristide.")
					"keep":
						out.append("Léo a gardé la mémoire d'Aristide. Hortense, la paix.")
					"share":
						out.append("Hortense et Léo se partagent la mémoire d'Aristide.")
		"people":
			var any := false
			var rows := [
				["malo_met", "Malo (auberge) : sait des choses sur la 7."],
				["mayor_met", "Théodore Patatras (maire) : cherche son registre."],
				["basile_met", "Basile (boulanger) : pétrit, ne regarde pas."],
				["gerard_met", "Gérard (pêcheur) : a trouvé une planche neuve."],
				["marguerite_met", "Marguerite : peint la maison en bleu."],
				["petro_met", "Pétronille : parle en énigmes, sert du thé."],
				["eleonore_met", "Éléonore Chardon : horlogère, cachée."],
				["odile_met", "Odile Aubépine : le pont est à elle (acte 1203)."],
				["gaspard_met", "Gaspard Ronceval : le pont est à lui (acte 1204)."],
				["mirette_met", "Mirette : a un lézard qui fut un dragon."],
				["anselme_met", "Maître Anselme : notaire des deux familles."],
				["honore_met", "Honoré Levain (Brumelune) : boulanger, se croit marin."],
				["ouessant_met", "Marin Ouessant : se croit éleveur de chèvres."],
				["hortense_met", "Hortense : met toujours deux tasses."],
				["leo_met", "Léo : pleure pour un monsieur qu'il n'a pas connu."],
			]
			for r in rows:
				if _f(r[0]) or (r[0] == "malo_met" and _f("inn_met")):
					out.append(r[1])
					any = true
			if not any:
				out.append("(Personne pour l'instant.)")
		"quests":
			var any3 := false
			var qs := [
				["phare_done", "Le Phare de l'Envers : terminé. Page 1 obtenue."],
				["door_open", "La porte sans maison : ouverte (sur rien)."],
				["door_seen", "La porte sans maison : trouver sa maison."],
				["fish_solved", "Le poisson rancunier : conflit résolu."],
				["fish_seen", "Le poisson rancunier : parler à Gérard."],
				["plank_given", "La planche : donnée à Gérard."],
				["plank_kept", "La planche : Pico la garde."],
				["key_asked", "La clé inconnue : Barnabé la veut. Pourquoi ?"],
				["photo2", "Chambre 7 : photo du héros devant le château."],
				["ch1_done", "CHAPITRE 1 TERMINÉ."],
				["v2_started", "Virevolte : démêler l'affaire du pont."],
				["pont_ok", "Le pont de Virevolte : réconcilié. Maison de Travers ouverte."],
				["mot_juste", "La Maison de Travers : Mot Juste obtenu."],
				["ch2_done", "CHAPITRE 2 TERMINÉ."],
				["v3_started", "Brumelune : rendre les bulles de souvenir à leurs propriétaires."],
				["b_cycle", "Brumelune : boulanger, marin et chèvre ont retrouvé leurs souvenirs."],
				["ch3_done", "CHAPITRE 3 TERMINÉ."],
				["b_done", "Brumelune : Hortense et Léo ont décidé. La trappe de l'Archive s'éveille."],
			]
			for q in qs:
				if _f(q[0]):
					if (q[0] == "door_seen" and _f("door_open")) or (q[0] == "fish_seen" and _f("fish_solved")):
						continue
					out.append(q[1])
					any3 = true
			if not any3:
				out.append("(Aucune quête secondaire pour l'instant.)")
		_:
			var any2 := false
			var objs := [
				["got_a", "Morceau de roue orange (boulangerie)."],
				["got_b", "Morceau de roue bleue (atelier)."],
				["c_petro", "Morceau de roue verte (Pétronille)."],
				["wheel_built", "Roue du mardi : assemblée à la mairie."],
				["got_axe", "Pièce centrale (Éléonore)."],
				["mot_juste", "Le Mot Juste (fragment du Registre)."],
				["ledger_seen", "Livre de comptes de l'auberge."],
			]
			for o in objs:
				if _f(o[0]):
					out.append(o[1])
					any2 = true
			if not any2:
				out.append("(Rien d'utile pour l'instant.)")
	return out
