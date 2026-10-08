extends RefCounted
## Tout ce qui peut aller dans l'inventaire.
## type : "fish" (poisson), "junk" (bric-à-brac pêché), "quest" (objet de
## quête), "food" (se mange), "object" (objet à sortir et lancer).
## kind = objet physique qui apparaît quand on le sort (voir props.gd).

const ITEMS := {
	"photo": {"name": "Photographie mystérieuse", "type": "story", "kind": "photo", "sell": 0},
	"cle": {"name": "Petite clé en cuivre", "type": "story", "kind": "cle", "sell": 0},
	"cuillere": {"name": "Cuillère", "type": "story", "kind": "cuillere", "sell": 0},
	"chaussette": {"name": "Chaussette rouge", "type": "story", "kind": "chaussette", "sell": 0},
	"planche": {"name": "Planche (très importante selon Pico)", "type": "story", "kind": "planche", "sell": 0},
	"carnet": {"name": "Carnet d'enquête", "type": "story", "kind": "carnet", "sell": 0},
	"cle_chambre": {"name": "Clé de la chambre 4", "type": "story", "kind": "cle_chambre", "sell": 0},
	"poignee": {"name": "Poignée de porte (sans porte)", "type": "story", "kind": "poignee", "sell": 0},
	"bouton": {"name": "Un bouton (de quoi ?)", "type": "story", "kind": "bouton", "sell": 0},
	"corde": {"name": "Morceau de corde", "type": "story", "kind": "corde", "sell": 0},
	"miroir": {"name": "Miroir fêlé", "type": "story", "kind": "miroir", "sell": 0},
	"cle_vide": {"name": "Clé sans serrure", "type": "story", "kind": "cle_vide", "sell": 0},
	"papier_bleu": {"name": "Morceau de papier bleu", "type": "story", "kind": "papier_bleu", "sell": 0},
	"axe": {"name": "Pièce centrale de l'horloge", "type": "story", "kind": "axe", "sell": 0},
	"roue_a": {"name": "Morceau de roue (orange)", "type": "story", "kind": "roue_a", "sell": 0},
	"roue_b": {"name": "Morceau de roue (bleue)", "type": "story", "kind": "roue_b", "sell": 0},
	"roue_c": {"name": "Morceau de roue (verte)", "type": "story", "kind": "roue_c", "sell": 0},
	"roue_mardi": {"name": "Roue du mardi", "type": "story", "kind": "roue_mardi", "sell": 0},
	"mot_juste": {"name": "Le Mot Juste (fragment du Registre)", "type": "story", "kind": "mot_juste", "sell": 0},
	"slip": {"name": "Slip de Pierre", "type": "quest", "kind": "slip", "sell": 0},
	"sardine": {"name": "Sardine", "type": "fish", "kind": "sardine", "sell": 2},
	"arcenciel": {"name": "Poisson arc-en-ciel", "type": "fish", "kind": "arcenciel", "sell": 6},
	"dore": {"name": "Poisson doré", "type": "fish", "kind": "dore", "sell": 25},
	"botte": {"name": "Vieille botte", "type": "junk", "kind": "botte", "sell": 1},
	"algue": {"name": "Algue gluante", "type": "junk", "kind": "algue", "sell": 0},
	"glace": {"name": "Glace arc-en-ciel", "type": "food", "kind": "glace", "sell": 1},
	"ramen": {"name": "Ramen ultra piquant", "type": "food", "kind": "ramen", "sell": 2},
	"bonbon": {"name": "Bonbon à l'hélium", "type": "food", "kind": "bonbon", "sell": 1},
	"chicken": {"name": "Poulet en caoutchouc", "type": "object", "kind": "chicken", "sell": 1},
	"canard": {"name": "Mini canard", "type": "object", "kind": "canard", "sell": 1},
	"ball": {"name": "Ballon de plage", "type": "object", "kind": "ball", "sell": 2},
	"coconut": {"name": "Noix de coco", "type": "object", "kind": "coconut", "sell": 1},
	"onigiri": {"name": "Onigiri", "type": "object", "kind": "onigiri", "sell": 2},
}

## Ordre d'affichage dans l'inventaire
const ORDER := ["photo", "cle", "cuillere", "chaussette", "planche", "carnet", "cle_chambre", "poignee", "bouton", "corde", "miroir", "cle_vide", "papier_bleu", "roue_a", "roue_b", "roue_c", "roue_mardi", "axe", "mot_juste", "slip", "dore", "arcenciel", "sardine", "botte", "algue", "glace", "ramen", "bonbon", "onigiri", "coconut", "chicken", "canard", "ball"]


## L'id d'inventaire d'un objet physique (même nom que son "kind").
static func id_for_kind(kind: String) -> String:
	for id in ITEMS:
		if ITEMS[id]["kind"] == kind:
			return id
	return ""


static func item_name(id: String) -> String:
	return ITEMS.get(id, {}).get("name", id)
