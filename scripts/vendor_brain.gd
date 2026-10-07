extends RefCounted
## La "mini IA" de Yuki, la vendeuse. Tout tourne dans le casque, hors ligne.
##
## Comment elle "réfléchit" :
## - Humeur (-1 fâchée ... +1 ravie) qui revient doucement vers la normale.
## - Affection pour le joueur (0..100) qui monte avec les compliments et les
##   achats, baisse quand on lui jette des trucs ou qu'on radote.
## - Mémoire (sauvegardée) : qui elle a déjà rencontré, ce qu'on a acheté,
##   combien de fois on a parlé, les secrets déjà racontés.
## - Mémoire courte : dernier perso qui lui a parlé (elle remarque les
##   échanges de corps !), phrases déjà dites (elle évite de se répéter),
##   compliments ou marchandages à la chaîne.
## - Elle regarde le contexte : ce que tu tiens en main, ton chapeau, tes
##   coquillages, où sont les autres habitants.
## Chaque réponse est choisie parmi des modèles de phrases selon cet état,
## puis "habillée" selon son humeur.

const Save := preload("res://scripts/save.gd")
const Items := preload("res://scripts/shop_items.gd")
const Characters := preload("res://scripts/characters.gd")

var recent: Array = []
var discount := false
var _compliments := 0
var _haggles := 0
var _last_char := ""
var _last_talk_ms := -1000000
var _compliment_idx := 0

const COMPLIMENTS := [
	"Ta boutique est trop mignonne !",
	"J'adore ta coiffure !",
	"Tu es la meilleure vendeuse de l'île !",
	"Ta fleur dans les cheveux est super jolie !",
	"Tes prix sont très raisonnables.",
]

const CHAR_QUIPS := {
	"Kenji": [
		"Pas de combat contre les ananas dans ma boutique, Kenji.",
		"Kenji ! Ton bandeau est de travers. Comme d'habitude.",
		"Toujours en route pour devenir roi des cocotiers ?",
	],
	"Mochi": [
		"Mochi ! Pas touche aux poissons en vitrine.",
		"Mochi, tu as encore les oreilles qui frétillent. Tu as faim ?",
		"Tiens, ma princesse à oreilles préférée !",
	],
	"Taro": [
		"Taro... tu as encore calculé tes chances d'avoir une réduc ?",
		"Tes lunettes sont pleines de sable, Taro.",
		"Alors Taro, combien de mangas depuis hier ?",
	],
}

const HAT_NAMES := {
	"paille": "ton chapeau de paille", "casquette": "ta casquette", "lapin": "tes oreilles de lapin",
	"sorcier": "ton chapeau de sorcier", "couronne": "ta couronne",
}


# --- État -------------------------------------------------------------------

func mem() -> Dictionary:
	if Save.vendor.is_empty():
		Save.vendor = Save.default_vendor()
	return Save.vendor


func mood() -> float:
	return float(mem()["mood"])


func affinity() -> float:
	return float(mem()["affinity"])


func _add_mood(d: float) -> void:
	mem()["mood"] = clampf(mood() + d, -1.0, 1.0)


func _add_affinity(d: float) -> void:
	mem()["affinity"] = clampf(affinity() + d, 0.0, 100.0)


## Appelé chaque image : l'humeur revient doucement vers "de bonne humeur".
func tick(delta: float) -> void:
	var m := mood()
	var target := 0.15 + affinity() / 400.0
	mem()["mood"] = move_toward(m, target, delta * 0.012)


func price_of(item: Dictionary) -> int:
	var p := float(item["price"])
	if mood() < -0.3:
		p *= 1.5
	elif affinity() >= 70.0:
		p *= 0.9
	if discount:
		p *= 0.7
	return maxi(1, int(round(p)))


func buy_price(kind: String) -> int:
	var p := float(Items.SELL_PRICES.get(kind, 1))
	if mood() > 0.5:
		p += 1.0
	if mood() < -0.3:
		p = maxf(p - 1.0, 0.0)
	return int(p)


# --- Fabrication des phrases -------------------------------------------------

func _pick(arr: Array) -> String:
	return arr[randi() % arr.size()]


## Choisit une phrase pas dite récemment, puis l'habille selon l'humeur.
func _say(options: Array) -> String:
	var choice: String = options[0]
	var fresh: Array = options.filter(func(o): return not recent.has(o))
	if fresh.size() > 0:
		choice = _pick(fresh)
	else:
		choice = _pick(options)
	recent.append(choice)
	if recent.size() > 14:
		recent.pop_front()
	var m := mood()
	if m > 0.55 and randf() < 0.45:
		choice += _pick([" Hihi !", " ~", " Trop bien !", " Yatta !"])
	elif m < -0.3 and randf() < 0.55:
		choice = _pick(["Hmpf. ", "Tss... ", "Grr. ", "... "]) + choice
	return choice


# --- Réactions ----------------------------------------------------------------

## ctx : char_name, hat, shells, holding (kind ou ""), npcs (Array de
## {name, where}), bonked_recently.
func greet(ctx: Dictionary) -> String:
	var name: String = ctx["char_name"]
	var met: Dictionary = mem()["met"]
	var now := Time.get_ticks_msec()
	var lines: Array = []
	mem()["talks"] = int(mem()["talks"]) + 1

	if _last_char != "" and _last_char != name and now - _last_talk_ms < 120000:
		lines = [
			"Attends... Il y a deux minutes, tu étais %s. Encore un échange de corps ?!" % _last_char,
			"Tu as le corps de %s mais le regard de %s... C'est flippant." % [name, _last_char],
			"Hé, %s, c'est toi là-dedans ? Je reconnais ta façon de marcher." % _last_char,
		]
		_add_mood(0.05)
	elif not met.has(name):
		met[name] = true
		lines = [
			"Bienvenue à la Boutique Kawaii ! Moi c'est Yuki. Et toi, tu dois être %s ?" % name,
			"Oh, un nouveau client ! %s, c'est ça ? Moi c'est Yuki, la reine du commerce !" % name,
		]
	elif mood() < -0.3:
		lines = [
			"Ah. C'est toi. Tu viens encore me jeter des trucs ?",
			"Les gens qui jettent des objets sur la vendeuse payent plus cher. C'est la règle.",
			"Je te surveille, %s." % name,
		]
	else:
		lines = [
			"Re-bonjour %s ! Qu'est-ce qui te ferait plaisir ?" % name,
			"Oh, %s ! J'ai rangé les étagères rien que pour toi." % name,
			"Coucou %s ! Les coquillages, c'est de l'or ici, tu sais." % name,
		]
		lines.append_array(CHAR_QUIPS.get(name, []))
		if affinity() > 60.0:
			lines.append("%s ! Mon client préféré ! Enfin, ne le dis pas aux autres." % name)
	var hat: String = ctx.get("hat", "")
	if hat != "" and randf() < 0.4 and mood() > -0.3:
		lines = ["Oh, %s te va super bien ! C'est moi qui te l'ai vendu, hein ?" % HAT_NAMES.get(hat, "ton chapeau")]
	_last_char = name
	_last_talk_ms = now
	return _say(lines)


func farewell(ctx: Dictionary) -> String:
	_compliments = 0
	_haggles = 0
	if mood() < -0.3:
		return _say(["C'est ça, file.", "Et ne reviens pas avec un ballon.", "Bon débarras. Enfin... à plus."])
	if affinity() > 60.0:
		return _say(["Reviens vite, %s !" % ctx["char_name"], "Déjà ?! Bon, à tout à l'heure !", "Tu vas me manquer ! Un peu."])
	return _say(["À bientôt !", "Merci de ta visite !", "Bonne balade, et attention au canard.", "Reviens avec plein de coquillages !"])


## Les choix proposés au joueur, selon la situation.
func options(ctx: Dictionary) -> Array:
	var out: Array = [["catalog", "Montre-moi tes articles"]]
	var holding: String = ctx.get("holding", "")
	if holding != "":
		out.append(["sell", "Je te vends %s ?" % Items.KIND_NAMES.get(holding, "ça")])
	if mood() < -0.2:
		out.append(["apologize", "Pardon pour tout à l'heure..."])
	if ctx.get("hat", "") != "":
		out.append(["remove_hat", "Enlève-moi ce chapeau"])
	var extra: Array = [
		["gossip", "Quoi de neuf sur l'île ?"],
		["compliment", COMPLIMENTS[_compliment_idx % COMPLIMENTS.size()]],
		["about", "Parle-moi de toi"],
	]
	if not discount:
		extra.append(["haggle", "Tu me fais une réduc ?"])
	extra.shuffle()
	for e in extra:
		if out.size() >= 5:
			break
		out.append(e)
	return out


func respond(intent: String, ctx: Dictionary) -> Dictionary:
	if intent != "compliment":
		_compliments = 0
	if intent != "haggle":
		_haggles = 0
	match intent:
		"compliment":
			return _compliment()
		"haggle":
			return _haggle()
		"gossip":
			return {"text": _gossip(ctx)}
		"about":
			return {"text": _about()}
		"apologize":
			_add_mood(0.55)
			_add_affinity(3.0)
			return {"text": _say(["Bon... ça va pour cette fois.", "Excuses acceptées. Mais je garde un oeil sur toi.", "D'accord, d'accord. On fait la paix ?"])}
		"remove_hat":
			return {"text": _say(["Et hop, rangé ! Tu redeviens banal.", "Voilà. Ta tête respire.", "Enlevé ! Mais il t'allait bien..."]), "remove_hat": true}
		"sell":
			return _sell(ctx)
	return {"text": "Hein ?"}


func _compliment() -> Dictionary:
	_compliments += 1
	_compliment_idx += 1
	if _compliments > 2:
		_add_mood(-0.12)
		return {"text": _say(["Tu radotes, là.", "Trois compliments d'affilée ? Tu veux une réduc, avoue.", "Ça devient suspect, tous ces compliments..."])}
	_add_mood(0.25)
	_add_affinity(6.0)
	if affinity() > 60.0:
		return {"text": _say(["Arrête, je vais rougir ! ... Trop tard.", "Toi, tu sais parler aux vendeuses.", "Oh... merci. Vraiment."])}
	return {"text": _say(["Hihi, merci !", "Ah bon ? C'est gentil !", "Tu dis ça à toutes les vendeuses ?", "Je savais bien que j'avais du goût."])}


func _haggle() -> Dictionary:
	_haggles += 1
	if _haggles > 2:
		_add_mood(-0.2)
		return {"text": _say(["Encore ?! Non, non et non !", "Tu vas finir par me ruiner avec tes questions !", "La réponse est toujours NON."])}
	var chance := 0.15 + affinity() / 200.0 + mood() * 0.2
	if randf() < chance:
		discount = true
		_add_mood(-0.05)
		return {"text": _say(["Bon... -30 % sur ton prochain achat. Mais c'est bien parce que c'est toi.", "D'accord ! Réduc spéciale, mais chut !", "Rhaa, tu m'as eue. -30 % sur le prochain article."])}
	return {"text": _say(["Une réduc ? Ici ? Ha ha ha. Non.", "Fais-moi d'abord un compliment, on verra.", "Les réducs, c'est pour les clients fidèles.", "Si je fais des réducs, le canard va me gronder."])}


func _gossip(ctx: Dictionary) -> String:
	var lines: Array = [
		"Le canard géant a encore bougé cette nuit. Je te jure.",
		"Il paraît qu'il y a des coquillages dorés quelque part. Enfin, c'est Taro qui le dit.",
		"Quelqu'un a mangé tous les onigiris de la maison. Tout le monde accuse Mochi.",
		"La porte de la maison grince tellement que les mouettes ont déménagé.",
		"Riku, le punk, garde un donjon plein de slimes. Il vient m'acheter des oreilles de lapin en cachette.",
	]
	for n in ctx.get("npcs", []):
		lines.append("J'ai vu %s traîner %s. Mission secrète, sans doute." % [n["name"], n["where"]])
	var shells: int = ctx.get("shells", 0)
	if shells > 25:
		lines.append("Tout le monde dit que tu as %d coquillages. Tu as pillé la plage ?" % shells)
	elif shells == 0:
		lines.append("Si tu n'as plus de coquillages, regarde sur la plage. Ils brillent au soleil.")
	var bought: Dictionary = mem()["bought"]
	if bought.size() > 0:
		var ids := bought.keys()
		var it := Items.by_id(ids[randi() % ids.size()])
		if not it.is_empty():
			lines.append("Depuis que tu as acheté %s, j'en ai vendu trois autres. Tu lances la mode !" % String(it["name"]).to_lower())
	return _say(lines)


func _about() -> String:
	var secrets := int(mem()["secrets"])
	if affinity() >= 50.0 and secrets == 0:
		mem()["secrets"] = 1
		return _say(["Tu veux un secret ? Le canard géant... c'est moi qui l'ai gonflé. Ne le dis à personne."])
	if affinity() >= 80.0 and secrets == 1:
		mem()["secrets"] = 2
		return _say(["Deuxième secret : je n'aime pas les coquillages. Je les revends au canard."])
	return _say([
		"Mon rêve ? Ouvrir une boutique sur la lune. Les clients seraient plus légers.",
		"Je collectionne les coquillages. C'est pour ça que j'accepte que ça comme monnaie.",
		"J'ai peur d'une seule chose : le canard géant. Il me fixe.",
		"Avant, je vendais des parapluies. Sur une île où il ne pleut jamais. Grosse erreur.",
		"Je tiens cette boutique depuis trois jours. Ou trois ans. Le temps passe bizarrement ici.",
	])


func _sell(ctx: Dictionary) -> Dictionary:
	var kind: String = ctx.get("holding", "")
	if kind == "":
		return {"text": _say(["Tu ne tiens rien, là. Tu veux me vendre du vent ?"])}
	if int(Items.SELL_PRICES.get(kind, 1)) == 0:
		return {"text": _say(["Une algue gluante ? Beurk. Garde-la, merci.", "Je vends des trucs kawaii, pas des trucs gluants."])}
	var price := buy_price(kind)
	if price <= 0:
		return {"text": _say(["Vu comment tu me traites, je ne t'achète rien du tout."])}
	var what: String = Items.KIND_NAMES.get(kind, "ça")
	return {"text": _say([
		"%s ? Allez, je te le prends pour %d coquillage%s." % [what.left(1).to_upper() + what.substr(1), price, "s" if price > 1 else ""],
		"Marché conclu : %d coquillage%s. Il ira dans ma vitrine." % [price, "s" if price > 1 else ""],
	]), "sell": price}


## Tentative d'achat. Renvoie text + éventuellement "buy" (l'article).
func try_buy(item: Dictionary, ctx: Dictionary) -> Dictionary:
	var price := price_of(item)
	if item["type"] == "hat" and ctx.get("hat", "") == item["id"]:
		return {"text": _say(["Tu l'as déjà sur la tête, gros malin !", "Regarde en haut. Si, si, plus haut. Tu le portes déjà."])}
	if int(ctx.get("shells", 0)) < price:
		_add_mood(-0.03)
		return {"text": _say([
			"Il te manque %d coquillage%s. Va voir sur la plage !" % [price - int(ctx["shells"]), "s" if price - int(ctx["shells"]) > 1 else ""],
			"Pas assez de coquillages... Je ne fais pas crédit !",
			"Hmm, ta bourse de coquillages est bien légère.",
		])}
	var bought: Dictionary = mem()["bought"]
	bought[item["id"]] = int(bought.get(item["id"], 0)) + 1
	var total := 0
	for k in bought:
		total += int(bought[k])
	discount = false
	_add_affinity(4.0)
	_add_mood(0.15)
	var text := _say([
		"Excellent choix ! %s" % item["pitch"],
		"Vendu ! %s" % item["pitch"],
		"%s pour %d coquillages. %s" % [item["name"], price, item["pitch"]],
	])
	var res := {"text": text, "buy": item, "price": price}
	if total % 5 == 0:
		res["gift"] = 2
		res["text"] = text + " Et comme tu es un client fidèle : 2 coquillages cadeaux !"
	return res


## On lui a lancé un objet dessus.
func bonked() -> String:
	_add_mood(-0.6)
	_add_affinity(-8.0)
	discount = false
	return _say([
		"AÏE ! On ne jette RIEN sur la vendeuse !",
		"Tu sais quoi ? Les prix viennent d'augmenter.",
		"Ça, c'est +50 % sur tout. Pour toi seulement.",
		"Mais ça va pas ?! Je vais le dire au canard !",
	])


## Petite phrase quand le joueur reste planté sans rien choisir.
func idle(ctx: Dictionary) -> String:
	var lines: Array = ["Tu comptes rester planté là ?", "Prends ton temps, hein. Je ne suis pas pressée. Enfin, un peu.", "Tu cherches quelque chose en particulier ?"]
	var holding: String = ctx.get("holding", "")
	if holding != "":
		lines.append("C'est %s que tu tiens là ? Je pourrais te le racheter." % Items.KIND_NAMES.get(holding, "quoi"))
	if int(ctx.get("shells", 0)) >= 12:
		lines.append("Avec tous ces coquillages, tu pourrais t'offrir la couronne royale...")
	return _say(lines)
