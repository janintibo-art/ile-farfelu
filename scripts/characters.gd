extends RefCounted
## Les trois habitants de l'île. Persos originaux, style chibi.

const LIST := [
	{
		"name": "Kenji",
		"skin": Color(1.0, 0.86, 0.74),
		"hair": Color(1.0, 0.55, 0.12),
		"hair_style": "spiky",
		"eye": Color(0.18, 0.62, 0.28),
		"shirt": Color(0.2, 0.45, 0.95),
		"pants": Color(0.16, 0.16, 0.32),
		"shoes": Color(0.92, 0.22, 0.2),
		"accent": Color(0.25, 0.85, 0.35),
		"lines": [
			"Un jour, je serai le roi des cocotiers !",
			"Mon bandeau me donne +10 en style.",
			"J'ai combattu un ananas. L'ananas a gagné.",
			"Tu veux voir mon attaque spéciale ? Moi aussi, je l'ai pas encore.",
		],
	},
	{
		"name": "Mochi",
		"skin": Color(1.0, 0.9, 0.82),
		"hair": Color(1.0, 0.55, 0.75),
		"hair_style": "buns",
		"eye": Color(0.62, 0.3, 0.85),
		"shirt": Color(1.0, 0.85, 0.3),
		"pants": Color(1.0, 0.85, 0.3),
		"shoes": Color(0.95, 0.45, 0.6),
		"accent": Color(1.0, 0.7, 0.8),
		"lines": [
			"Nyan ! Qui a mangé mon onigiri ?!",
			"Je ne suis PAS un chat. Je suis une princesse à oreilles.",
			"Le canard géant me regarde bizarrement...",
			"Gratte-moi derrière l'oreille et je t'offre un poisson.",
		],
	},
	{
		"name": "Taro",
		"skin": Color(0.95, 0.8, 0.66),
		"hair": Color(0.25, 0.35, 0.8),
		"hair_style": "messy",
		"eye": Color(0.25, 0.55, 1.0),
		"shirt": Color(0.58, 0.35, 0.8),
		"pants": Color(0.3, 0.3, 0.35),
		"shoes": Color(0.95, 0.95, 0.95),
		"accent": Color(0.15, 0.13, 0.2),
		"lines": [
			"D'après mes calculs... on est perdus.",
			"J'ai lu 400 mangas. Je suis donc expert en tout.",
			"Mes lunettes voient à travers les murs. Enfin, presque.",
			"73 % de chances qu'une noix de coco te tombe dessus.",
		],
	},
]

## La vendeuse (pas jouable : elle tient la boutique !)
const VENDOR := {
	"name": "Yuki",
	"skin": Color(1.0, 0.88, 0.78),
	"hair": Color(0.35, 0.85, 0.75),
	"hair_style": "ponytail",
	"eye": Color(0.9, 0.55, 0.15),
	"shirt": Color(1.0, 0.55, 0.65),
	"pants": Color(1.0, 0.88, 0.8),
	"shoes": Color(0.55, 0.35, 0.8),
	"accent": Color(1.0, 0.35, 0.5),
	"lines": [],
}

## Le punk qui garde l'entrée du donjon
const PUNK := {
	"name": "Riku",
	"skin": Color(0.98, 0.84, 0.72),
	"hair": Color(0.95, 0.2, 0.7),
	"hair_style": "mohawk",
	"eye": Color(0.2, 0.85, 0.85),
	"shirt": Color(0.16, 0.14, 0.2),
	"pants": Color(0.55, 0.12, 0.2),
	"shoes": Color(0.1, 0.1, 0.12),
	"accent": Color(0.95, 0.85, 0.3),
	"lines": [],
}

## Pierre a perdu son slip en se baignant (il porte une serviette)
const PIERRE := {
	"name": "Pierre",
	"skin": Color(1.0, 0.8, 0.68),
	"hair": Color(0.45, 0.28, 0.15),
	"hair_style": "wet",
	"eye": Color(0.35, 0.55, 0.3),
	"shirt": Color(1.0, 0.8, 0.68),
	"pants": Color(1.0, 0.8, 0.68),
	"shoes": Color(0.3, 0.75, 0.95),
	"accent": Color(0.3, 0.6, 1.0),
	"towel": true,
	"lines": [],
}

## Luc-Ael, le pêcheur tranquille
const LUCAEL := {
	"name": "Luc-Ael",
	"skin": Color(0.85, 0.64, 0.48),
	"hair": Color(0.92, 0.92, 0.95),
	"hair_style": "fisher",
	"eye": Color(0.3, 0.45, 0.8),
	"shirt": Color(0.95, 0.75, 0.25),
	"pants": Color(0.3, 0.4, 0.6),
	"shoes": Color(0.25, 0.5, 0.3),
	"accent": Color(0.3, 0.55, 0.35),
	"lines": [],
}

## Habitants de Port-Biscornu
const MALO := {
	"name": "Malo",
	"skin": Color(1.0, 0.78, 0.66),
	"hair": Color(0.8, 0.78, 0.8),
	"hair_style": "innkeeper",
	"eye": Color(0.45, 0.3, 0.18),
	"shirt": Color(0.9, 0.55, 0.35),
	"pants": Color(0.35, 0.28, 0.3),
	"shoes": Color(0.3, 0.2, 0.15),
	"accent": Color(0.35, 0.5, 0.85),
	"lines": [],
}

const BARNABE := {
	"name": "Barnabé",
	"skin": Color(0.9, 0.7, 0.55),
	"hair": Color(0.95, 0.5, 0.2),
	"hair_style": "merchant",
	"eye": Color(0.2, 0.55, 0.45),
	"shirt": Color(0.4, 0.75, 0.55),
	"pants": Color(0.55, 0.4, 0.6),
	"shoes": Color(0.95, 0.75, 0.2),
	"accent": Color(0.85, 0.65, 0.3),
	"lines": [],
}

const NINA := {
	"name": "Nina",
	"skin": Color(1.0, 0.86, 0.74),
	"hair": Color(0.25, 0.15, 0.12),
	"hair_style": "kid",
	"eye": Color(0.25, 0.7, 0.55),
	"shirt": Color(1.0, 0.95, 0.85),
	"pants": Color(0.95, 0.95, 0.95),
	"shoes": Color(0.95, 0.35, 0.4),
	"accent": Color(0.95, 0.45, 0.55),
	"scale": 0.78,
	"lines": [],
}

const THEODORE := {
	"name": "Théodore",
	"skin": Color(1.0, 0.82, 0.7),
	"hair": Color(0.7, 0.7, 0.75),
	"hair_style": "mayor",
	"eye": Color(0.3, 0.4, 0.7),
	"shirt": Color(0.25, 0.3, 0.55),
	"pants": Color(0.22, 0.2, 0.28),
	"shoes": Color(0.15, 0.12, 0.15),
	"accent": Color(0.9, 0.8, 0.5),
	"lines": [],
}

## Les gens de la rue des Traverses et du port
const BASILE := {
	"name": "Basile",
	"skin": Color(1.0, 0.84, 0.72),
	"hair": Color(0.95, 0.9, 0.8),
	"hair_style": "innkeeper",
	"eye": Color(0.35, 0.3, 0.2),
	"shirt": Color(0.98, 0.96, 0.92),
	"pants": Color(0.55, 0.45, 0.4),
	"shoes": Color(0.45, 0.32, 0.25),
	"accent": Color(0.95, 0.85, 0.6),
	"lines": [],
}

const GERARD := {
	"name": "Gérard",
	"skin": Color(0.88, 0.66, 0.5),
	"hair": Color(0.55, 0.55, 0.6),
	"hair_style": "fisher",
	"eye": Color(0.25, 0.4, 0.55),
	"shirt": Color(0.3, 0.45, 0.7),
	"pants": Color(0.35, 0.35, 0.28),
	"shoes": Color(0.2, 0.2, 0.22),
	"accent": Color(0.85, 0.55, 0.25),
	"lines": [],
}

const MARGUERITE := {
	"name": "Marguerite",
	"skin": Color(1.0, 0.82, 0.7),
	"hair": Color(0.45, 0.3, 0.2),
	"hair_style": "buns",
	"eye": Color(0.3, 0.5, 0.35),
	"shirt": Color(0.95, 0.8, 0.85),
	"pants": Color(0.6, 0.75, 0.95),
	"shoes": Color(0.55, 0.4, 0.3),
	"accent": Color(0.5, 0.75, 1.0),
	"lines": [],
}

const PETRONILLE := {
	"name": "Pétronille",
	"skin": Color(0.98, 0.82, 0.72),
	"hair": Color(0.85, 0.85, 0.9),
	"hair_style": "ponytail",
	"eye": Color(0.5, 0.35, 0.65),
	"shirt": Color(0.6, 0.4, 0.7),
	"pants": Color(0.45, 0.3, 0.55),
	"shoes": Color(0.9, 0.7, 0.4),
	"accent": Color(0.85, 0.6, 0.3),
	"lines": [],
}

const ELEONORE := {
	"name": "Éléonore",
	"skin": Color(1.0, 0.86, 0.74),
	"hair": Color(0.45, 0.15, 0.25),
	"hair_style": "messy",
	"eye": Color(0.2, 0.55, 0.6),
	"shirt": Color(0.25, 0.5, 0.55),
	"pants": Color(0.3, 0.25, 0.3),
	"shoes": Color(0.55, 0.35, 0.25),
	"accent": Color(0.9, 0.8, 0.5),
	"lines": [],
}

const SWAP_REACTIONS := [
	"Hé ! Rends-moi mon corps !",
	"Pourquoi j'ai envie de ronronner ?!",
	"Où sont passées mes lunettes ?!",
	"Encore un échange de corps ? Sérieux ?!",
	"J'ai des jambes toutes neuves !",
]

const BONK_REACTIONS := [
	"AÏE !",
	"Qui a lancé ça ?!",
	"Ma tête n'est pas un panier !",
	"Je vais le dire au canard !",
]


## Virevolte (chapitre 2)
const ODILE := {
	"name": "Odile Aubépine",
	"skin": Color(1.0, 0.84, 0.72),
	"hair": Color(0.85, 0.9, 0.85),
	"hair_style": "buns",
	"eye": Color(0.3, 0.5, 0.3),
	"shirt": Color(0.4, 0.7, 0.45),
	"pants": Color(0.35, 0.3, 0.28),
	"shoes": Color(0.4, 0.3, 0.22),
	"accent": Color(0.6, 0.9, 0.6),
	"lines": [],
}

const GASPARD := {
	"name": "Gaspard Ronceval",
	"skin": Color(0.9, 0.7, 0.55),
	"hair": Color(0.55, 0.2, 0.15),
	"hair_style": "mayor",
	"eye": Color(0.4, 0.25, 0.2),
	"shirt": Color(0.8, 0.3, 0.3),
	"pants": Color(0.3, 0.25, 0.3),
	"shoes": Color(0.3, 0.2, 0.18),
	"accent": Color(0.95, 0.5, 0.45),
	"lines": [],
}

const ANSELME := {
	"name": "Maître Anselme",
	"skin": Color(0.95, 0.8, 0.68),
	"hair": Color(0.3, 0.25, 0.4),
	"hair_style": "merchant",
	"eye": Color(0.35, 0.25, 0.5),
	"shirt": Color(0.5, 0.35, 0.65),
	"pants": Color(0.25, 0.22, 0.3),
	"shoes": Color(0.2, 0.18, 0.22),
	"accent": Color(0.75, 0.6, 0.95),
	"lines": [],
}

const MIRETTE := {
	"name": "Mirette",
	"skin": Color(1.0, 0.86, 0.74),
	"hair": Color(0.2, 0.4, 0.3),
	"hair_style": "kid",
	"eye": Color(0.25, 0.45, 0.35),
	"shirt": Color(0.95, 0.85, 0.4),
	"pants": Color(0.35, 0.45, 0.6),
	"shoes": Color(0.5, 0.35, 0.25),
	"accent": Color(0.95, 0.9, 0.5),
	"lines": [],
}
