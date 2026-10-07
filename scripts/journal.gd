extends RefCounted
## Le carnet d'enquête : se remplit tout seul selon les drapeaux de l'histoire.
## Trois onglets : indices, personnes, objets. Chaque ligne tient sur un bouton.

const Save := preload("res://scripts/save.gd")

const TABS := ["clues", "people", "objects"]
const TAB_NAMES := {"clues": "INDICES", "people": "PERSONNES", "objects": "OBJETS"}


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
			]
			for r in rows:
				if _f(r[0]) or (r[0] == "malo_met" and _f("inn_met")):
					out.append(r[1])
					any = true
			if not any:
				out.append("(Personne pour l'instant.)")
		_:
			var any2 := false
			var objs := [
				["got_a", "Morceau de roue orange (boulangerie)."],
				["got_b", "Morceau de roue bleue (atelier)."],
				["c_petro", "Morceau de roue verte (Pétronille)."],
				["wheel_built", "Roue du mardi : assemblée à la mairie."],
				["got_axe", "Pièce centrale (Éléonore)."],
				["ledger_seen", "Livre de comptes de l'auberge."],
			]
			for o in objs:
				if _f(o[0]):
					out.append(o[1])
					any2 = true
			if not any2:
				out.append("(Rien d'utile pour l'instant.)")
	return out
