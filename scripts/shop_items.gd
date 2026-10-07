extends RefCounted
## Catalogue de la Boutique Kawaii.
## type : "hat" (se pose sur la tête), "food" (à manger, effet 30 s),
## "object" (objet à attraper). kind = objet physique qui apparaît au comptoir.

const ITEMS := [
	{"id": "paille", "name": "Chapeau de paille", "price": 6, "type": "hat",
		"pitch": "Parfait pour faire la sieste sous un cocotier."},
	{"id": "casquette", "name": "Casquette cool", "price": 5, "type": "hat",
		"pitch": "Avec ça, tu gagnes +20 en coolitude. Minimum."},
	{"id": "lapin", "name": "Oreilles de lapin", "price": 8, "type": "hat",
		"pitch": "Elles bougent pas, mais on y croit très fort."},
	{"id": "sorcier", "name": "Chapeau de sorcier", "price": 10, "type": "hat",
		"pitch": "Magie non garantie. Style garanti."},
	{"id": "couronne", "name": "Couronne royale", "price": 12, "type": "hat",
		"pitch": "Pour le futur roi des cocotiers. Ou reine."},
	{"id": "glace", "name": "Glace arc-en-ciel", "price": 3, "type": "food", "kind": "glace", "effect": "big_head",
		"pitch": "Attention, elle fait gonfler la tête. Littéralement."},
	{"id": "ramen", "name": "Ramen ultra piquant", "price": 4, "type": "food", "kind": "ramen", "effect": "speed",
		"pitch": "Tu vas courir comme jamais. Surtout vers l'eau."},
	{"id": "bonbon", "name": "Bonbon à l'hélium", "price": 3, "type": "food", "kind": "bonbon", "effect": "helium",
		"pitch": "Tu vas sauter jusqu'aux nuages. Presque."},
	{"id": "poulet", "name": "Poulet en caoutchouc", "price": 2, "type": "object", "kind": "chicken",
		"pitch": "Il fait COUIC. C'est tout. C'est parfait."},
	{"id": "ballon", "name": "Ballon de plage", "price": 3, "type": "object", "kind": "ball",
		"pitch": "Rebondit sur tout, surtout sur Kenji."},
	{"id": "canard", "name": "Mini canard", "price": 2, "type": "object", "kind": "canard",
		"pitch": "Le cousin du canard géant. Il est moins bizarre."},
]

## Prix de rachat quand on revend un objet à Yuki.
const SELL_PRICES := {"coconut": 1, "onigiri": 2, "chicken": 1, "ball": 2, "canard": 1, "glace": 1, "ramen": 2, "bonbon": 1,
	"sardine": 2, "arcenciel": 5, "dore": 20, "botte": 1, "algue": 0}

const KIND_NAMES := {
	"coconut": "une noix de coco", "onigiri": "un onigiri", "chicken": "un poulet en caoutchouc",
	"ball": "un ballon", "canard": "un mini canard", "glace": "une glace", "ramen": "un ramen", "bonbon": "un bonbon",
	"sardine": "une sardine", "arcenciel": "un poisson arc-en-ciel", "dore": "un poisson doré", "botte": "une vieille botte", "algue": "une algue gluante",
}


static func by_id(id: String) -> Dictionary:
	for it in ITEMS:
		if it["id"] == id:
			return it
	return {}


static func food_effect(kind: String) -> String:
	for it in ITEMS:
		if it.get("kind", "") == kind and it["type"] == "food":
			return it["effect"]
	return ""
