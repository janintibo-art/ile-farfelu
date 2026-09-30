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
