extends Node3D
## Port-Biscornu : le port, la place centrale, l'auberge du Dernier Verre,
## la mairie, la boutique de Barnabé, le phare et les maisons de la rue des
## Traverses. Les habitants parlent avec leur "mini IA" (village_brain.gd).
##
## Fil de l'histoire dans ce chapitre :
##  1. Malo laisse tomber son verre (« Vous êtes en avance ») puis demande
##     d'aller s'enregistrer à la mairie.
##  2. Le maire n'a plus son registre : il enregistre le joueur au dos d'un menu.
##  3. Avec sa permission, on fouille son bureau : le calendrier saute de
##     LUNDI à MERCREDI. Il donne le carnet d'enquête.
##  4. Malo donne la clé de la chambre 4. Nina, Barnabé... et un village où
##     tout le monde est un peu en retard sur ses souvenirs.

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Island := preload("res://scripts/island.gd")
const Fx := preload("res://scripts/fx.gd")
const Save := preload("res://scripts/save.gd")
const Inv := preload("res://scripts/inventory_items.gd")
const Props := preload("res://scripts/props.gd")
const Characters := preload("res://scripts/characters.gd")
const Talker := preload("res://scripts/talker.gd")
const TalkMenu := preload("res://scripts/talk_menu.gd")
const ChoiceButton := preload("res://scripts/choice_button.gd")
const Brain := preload("res://scripts/village_brain.gd")
const VB := preload("res://scripts/village_build.gd")
const VX := preload("res://scripts/village_x.gd")
const Clock := preload("res://scripts/clock.gd")
const Maquette := preload("res://scripts/maquette.gd")
const Phare := preload("res://scripts/phare.gd")
const VY := preload("res://scripts/village_y.gd")
const VZ := preload("res://scripts/village_z.gd")
const TR := preload("res://scripts/travers.gd")

const INK := Color(0.13, 0.08, 0.17)
const H := Island.VILLAGE_H
const TALK_DIST := 2.9

# Emplacements des bâtiments : centre (x, z), orientation, largeur, profondeur
const INN := {"pos": Vector2(-15.0, -50.0), "yaw": PI * 0.5, "w": 10.0, "d": 9.0, "h": 3.4}
const HALL := {"pos": Vector2(0.0, -58.0), "yaw": 0.0, "w": 13.0, "d": 8.0, "h": 4.3}
const SHOP := {"pos": Vector2(13.5, -48.5), "yaw": -PI * 0.5, "w": 6.0, "d": 5.5, "h": 3.0}
const LIGHTHOUSE := Vector2(25.0, -57.0)
const SQUARE := Vector2(0.0, -49.5)
const ENTRANCE := Vector2(0.0, -39.5)

var world: Node3D
var player
var brain := Brain.new()
var speakers: Array = []
var nodes: Dictionary = {}        # nom du bâtiment -> Node3D
var nina
var calendar_btn
var calendar_node: Node3D
var zone := ""
var x
var clock
var maquette
var phare
var y
var z
var tr
var _nina_wp := 0
var _nina_wait := 0.0
var _nina_speed := 1.0
var _nina_away := false
var _glass: MeshInstance3D


func build(p_world: Node3D, p_player) -> void:
	world = p_world
	player = p_player
	_outdoors()
	_inn()
	_hall()
	_shop()
	_houses()
	var lh := VB.lighthouse(world, LIGHTHOUSE)
	nodes["phare"] = lh
	x = VX.new()
	x.v = self
	x.build()
	z = VZ.new()
	z.v = self
	z.build()
	clock = Clock.new()
	clock.setup(self, nodes["mairie"])
	maquette = Maquette.new()
	maquette.name = "Maquette"
	add_child(maquette)
	maquette.setup(self, player)
	clock.maquette = maquette
	phare = Phare.new()
	phare.name = "Phare"
	add_child(phare)
	phare.setup(self, player)
	tr = TR.new()
	tr.name = "Travers"
	add_child(tr)
	tr.setup(self, player)
	_make_speakers()
	y = VY.new()
	y.v = self
	y.build()
	refresh_calendar()


# --- Extérieur : place, port, panneaux ---------------------------------------------

func _outdoors() -> void:
	var b := Builder.new()
	VB.fountain(b, Vector3(SQUARE.x, H, SQUARE.y))
	# Étals du marché : déjà rangés (le marché « spécial mardi » est fini)
	var stripes := [Color(0.95, 0.4, 0.4), Color(0.35, 0.65, 0.95), Color(0.98, 0.8, 0.25), Color(0.5, 0.8, 0.45)]
	var sp := [Vector3(-4.6, 0, -46.3), Vector3(4.6, 0, -46.3), Vector3(-6.8, 0, -51.5), Vector3(6.8, 0, -51.5)]
	for i in 4:
		var p: Vector3 = sp[i]
		VB.stall(b, Vector3(p.x, H, p.z), 0.0 if i < 2 else PI, stripes[i])
	# Le quai (avec deux brèches pour les pontons) et les deux pontons
	var qz := -64.9
	for seg in [[-21.0, -9.5], [-5.5, 6.0], [10.0, 22.0]]:
		var cx: float = (seg[0] + seg[1]) * 0.5
		var ln: float = seg[1] - seg[0]
		b.box(Vector3(ln, 1.0, 0.9), Vector3(cx, H - 0.2, qz), VB.STONE, true)
		b.box(Vector3(ln, 0.12, 1.1), Vector3(cx, H + 0.34, qz), VB.STONE.lightened(0.12), false)
	for px in [-7.5, 8.0]:
		_pier(b, px, qz)
	# Bateaux amarrés
	VB.boat(b, Vector3(-11.3, -0.05, -72.3), 0.1, Color(0.35, 0.6, 0.85), Color(1, 0.95, 0.85))
	VB.boat(b, Vector3(-3.0, -0.05, -73.5), -0.08, Color(0.95, 0.5, 0.35), Color(0.95, 0.85, 0.4))
	VB.boat(b, Vector3(13.5, -0.05, -73.0), 0.05, Color(0.45, 0.75, 0.5), Color(1.0, 0.9, 0.9))
	# Caisses et barils sur le quai
	VB.crate(b, Vector3(-17.0, H + 0.1, -64.0), Vector3(0.8, 0.6, 0.7), Color(0.78, 0.58, 0.36), 0.3)
	VB.crate(b, Vector3(-16.0, H + 0.1, -63.6), Vector3(0.6, 0.5, 0.6), Color(0.72, 0.52, 0.32), -0.2)
	VB.crate(b, Vector3(19.0, H + 0.1, -64.0), Vector3(0.9, 0.7, 0.7), Color(0.8, 0.6, 0.38), 0.1)
	# Lanternes autour de la place
	for lp in [Vector2(-3.5, -44.5), Vector2(3.5, -44.5), Vector2(-9.0, -56.0), Vector2(9.0, -56.0), Vector2(0.0, -42.0)]:
		b.cylinder(0.05, 0.07, 2.8, Vector3(lp.x, H + 1.4, lp.y), VB.DARK_WOOD, Basis(), 6)
		b.box(Vector3(0.3, 0.38, 0.3), Vector3(lp.x, H + 2.9, lp.y), Color(1.0, 0.93, 0.62), false)
		b.box(Vector3(0.38, 0.06, 0.38), Vector3(lp.x, H + 3.12, lp.y), VB.DARK_WOOD, false)
	# Poteau de l'affiche du marché
	b.cylinder(0.06, 0.06, 2.4, Vector3(-1.8, H + 1.2, -45.5), VB.DARK_WOOD, Basis(), 6)
	b.box(Vector3(1.0, 0.7, 0.05), Vector3(-1.8, H + 1.9, -45.5), Color(1.0, 0.98, 0.85), false)
	b.build(self, Toon.vertex_color(0.01), "Plaza")
	VB.label(self, "MARCHÉ SPÉCIAL\nMARDI MATIN", Vector3(-1.8, H + 1.9, -45.44), 0.0026, Color(0.5, 0.2, 0.2), 40, 0.0, 0)
	VB.label(self, "LE PORT", Vector3(0.0, H + 1.3, -64.5), 0.006, Color(1.0, 0.95, 0.7), 60, 0.0, 14)
	_entrance_sign()


func _pier(b: Builder, x: float, qz: float) -> void:
	var len := 10.0
	for k in int(len / 0.55):
		var z := qz - 1.8 - k * 0.55
		b.box(Vector3(2.0, 0.1, 0.5), Vector3(x, 0.52, z), VB.WOOD if k % 2 == 0 else VB.WOOD.darkened(0.08), false)
	b.collider(Vector3(2.0, 0.1, len + 0.6), Vector3(x, 0.52, qz - 1.8 - len * 0.5 + 0.3))
	for k in 5:
		var z := qz - 2.6 - k * 2.2
		for sx in [-1.0, 1.0]:
			b.cylinder(0.09, 0.1, 3.2, Vector3(x + sx * 1.0, -0.3, z), VB.DARK_WOOD, Basis(), 8)


func _entrance_sign() -> void:
	var n := Node3D.new()
	n.name = "PanneauEntree"
	add_child(n)
	var p := Vector3(4.2, Island.height(4.2, ENTRANCE.y), ENTRANCE.y)
	n.position = p
	n.rotation.y = -0.2
	var b := Builder.new()
	for sx in [-1.0, 1.0]:
		b.box(Vector3(0.18, 3.6, 0.18), Vector3(sx * 1.7, 1.8, 0), VB.DARK_WOOD, false)
	b.box(Vector3(3.8, 2.2, 0.14), Vector3(0, 2.3, 0), Color(0.95, 0.88, 0.7), true)
	b.box(Vector3(3.95, 0.14, 0.2), Vector3(0, 3.45, 0), VB.DARK_WOOD, false)
	b.box(Vector3(3.95, 0.14, 0.2), Vector3(0, 1.17, 0), VB.DARK_WOOD, false)
	b.build(n, Toon.vertex_color(0.01), "Sign")
	VB.label(n, "PORT-BISCORNU", Vector3(0, 3.0, 0.09), 0.0062, Color(0.2, 0.3, 0.55), 56, 0.0, 0)
	VB.label(n, "Population : 63", Vector3(-0.5, 2.35, 0.09), 0.0034, Color(0.25, 0.2, 0.2), 48, 0.0, 0)
	VB.label(n, "62", Vector3(-0.45, 2.0, 0.09), 0.0034, Color(0.25, 0.2, 0.2), 48, 0.0, 0)
	VB.label(n, "64", Vector3(0.1, 1.72, 0.09), 0.0034, Color(0.25, 0.2, 0.2), 48, 0.0, 0)
	VB.label(n, "On recomptera demain.", Vector3(0.1, 1.42, 0.09), 0.0034, Color(0.6, 0.2, 0.2), 48, 0.0, 0)
	nodes["panneau"] = n


# --- Maisons de la rue des Traverses (pas visitables) --------------------------------

func _houses() -> void:
	nodes["maison_bleue"] = VB.house(self, "MaisonBleue", Vector2(9.0, -44.0), 0.0, 5.0, 5.0, 3.2, Color(0.55, 0.75, 1.0), Color(0.25, 0.3, 0.6), "")


# --- L'auberge du Dernier Verre ---------------------------------------------------------

func _inn() -> void:
	var w: float = INN["w"]
	var d: float = INN["d"]
	var h: float = INN["h"]
	var s: Array = VB.shell(self, "Auberge", INN["pos"], INN["yaw"], w, d, h, Color(0.96, 0.78, 0.5), Color(0.7, 0.25, 0.28), Color(0.72, 0.52, 0.34), 1.6)
	var n: Node3D = s[0]
	var b: Builder = s[1]
	nodes["auberge"] = n
	var wood := VB.WOOD
	# Comptoir le long du mur de gauche, étagères de bouteilles derrière
	b.box(Vector3(0.8, 1.1, 5.2), Vector3(-3.5, 0.55, -0.4), wood.darkened(0.1), true)
	b.box(Vector3(1.05, 0.08, 5.4), Vector3(-3.5, 1.12, -0.4), wood.lightened(0.1), false)
	for sh in [1.3, 1.85, 2.4]:
		b.box(Vector3(0.4, 0.06, 5.2), Vector3(-4.68, sh, -0.4), wood.darkened(0.2), false)
		for k in 9:
			var col: Color = [Color(0.35, 0.8, 0.5), Color(0.95, 0.6, 0.25), Color(0.5, 0.55, 0.95), Color(0.9, 0.35, 0.45)][(k + int(sh * 3.0)) % 4]
			VB.bottle(b, Vector3(-4.68, sh + 0.03, -2.8 + k * 0.58), col)
	b.box(Vector3(0.95, 0.28, 5.4), Vector3(-4.4, 0.14, -0.4), VB.WOOD.darkened(0.3), true)   # caillebotis pour que Malo dépasse du comptoir
	for k in 5:
		VB.stool(b, Vector3(-2.7, 0, -2.4 + k * 1.15))
	for k in 3:
		VB.mug(b, Vector3(-3.4, 1.16, -2.0 + k * 1.3))
	# Le livre de comptes (important plus tard)
	b.box(Vector3(0.42, 0.06, 0.3), Vector3(-3.55, 1.19, 1.5), Color(0.75, 0.2, 0.25), false, Basis(Vector3.UP, 0.3))
	b.box(Vector3(0.38, 0.05, 0.26), Vector3(-3.55, 1.215, 1.5), Color(0.97, 0.94, 0.85), false, Basis(Vector3.UP, 0.3))
	# Tables et tabourets
	var tp := [Vector3(1.2, 0, 2.2), Vector3(3.2, 0, 0.4), Vector3(-0.8, 0, 0.6)]
	for p in tp:
		VB.table(b, p, 0.55)
		VB.mug(b, p + Vector3(0.15, 0.82, 0.1))
		VB.mug(b, p + Vector3(-0.2, 0.82, -0.15), Color(0.6, 0.8, 0.95))
		for k in 3:
			var a := k * TAU / 3.0 + 0.5
			VB.stool(b, p + Vector3(cos(a) * 0.95, 0, sin(a) * 0.95), [Color(0.85, 0.4, 0.35), Color(0.4, 0.65, 0.85), Color(0.9, 0.75, 0.3)][k])
	# Cheminée sur le mur de droite
	b.box(Vector3(0.7, 2.4, 2.6), Vector3(4.55, 1.2, -1.2), VB.STONE, false)
	b.box(Vector3(0.5, 1.3, 1.5), Vector3(4.45, 0.7, -1.2), Color(0.1, 0.07, 0.07), false)
	b.box(Vector3(0.9, 0.12, 3.0), Vector3(4.5, 1.65, -1.2), wood.darkened(0.2), false)
	for k in 4:
		b.spike(0.12, 0.5, Vector3(4.4, 0.18, -1.7 + k * 0.33), Vector3(0.1, 1.0, 0.0), [Color(1.0, 0.55, 0.15), Color(1.0, 0.85, 0.25)][k % 2])
	b.box(Vector3(0.3, 0.12, 0.9), Vector3(4.3, 0.1, -1.2), Color(0.45, 0.28, 0.18), false)
	# Tapis et lustre
	b.box(Vector3(2.6, 0.02, 3.6), Vector3(0.9, 0.06, 0.4), Color(0.75, 0.3, 0.35), false)
	b.torus(0.8, 1.0, Vector3(0.5, h - 0.5, 0.5), Color(0.75, 0.55, 0.25), Basis())
	for k in 5:
		var a := k * TAU / 5.0
		b.sphere(0.1, Vector3(0.5 + cos(a) * 0.9, h - 0.4, 0.5 + sin(a) * 0.9), Color(1.0, 0.92, 0.5), Vector3.ONE, Basis(), 6)
	# Les huit portes de chambres, au fond
	var dz := -d * 0.5 + VB.WALL_T
	for k in 8:
		var x := -2.45 + k * 0.95
		var col := Color(0.55, 0.38, 0.28)
		if k == 6:
			col = Color(0.35, 0.25, 0.3)   # la 7, un peu trop sombre
		b.box(Vector3(0.78, 2.05, 0.08), Vector3(x, 1.03, dz + 0.04), col, false)
		b.box(Vector3(0.1, 0.1, 0.05), Vector3(x + 0.26, 1.0, dz + 0.1), Color(0.95, 0.8, 0.3), false)
		b.box(Vector3(0.3, 0.2, 0.05), Vector3(x, 2.25, dz + 0.06), Color(0.95, 0.9, 0.75) if k != 3 else Color(0.95, 0.78, 0.25), false)
	# Petit bout de papier bleu qui dépasse sous la porte 7 (plus tard...)
	b.box(Vector3(0.14, 0.01, 0.1), Vector3(-2.45 + 6 * 0.95 + 0.1, 0.045, dz + 0.16), Color(0.35, 0.55, 1.0), false, Basis(Vector3.UP, 0.4))
	# Enseigne et décor
	b.box(Vector3(3.6, 0.8, 0.1), Vector3(0, 2.95, d * 0.5 + 0.08), Color(0.45, 0.28, 0.2), false)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(0.08, 0.5, 0.08), Vector3(sx * 1.7, 3.35, d * 0.5 + 0.08), VB.DARK_WOOD, false)
	b.cylinder(0.2, 0.2, 0.3, Vector3(2.2, 2.6, d * 0.5 + 0.2), Color(0.95, 0.85, 0.5), Basis(), 10)
	_inn_photo(b, w)
	VB.plant(b, Vector3(-4.3, 0, 3.8))
	VB.plant(b, Vector3(4.3, 0, 3.8))
	b.build(n, Toon.vertex_color(0.01), "Mesh")
	VB.label(n, "AUBERGE DU\nDERNIER VERRE", Vector3(0, 2.95, d * 0.5 + 0.15), 0.0032, Color(1.0, 0.92, 0.6), 56, 0.0, 12)
	for k in 8:
		VB.label(n, str(k + 1), Vector3(-2.45 + k * 0.95, 2.25, dz + 0.1), 0.0034, Color(0.25, 0.15, 0.2), 48, 0.0, 0)
	VB.label(n, "NE PAS DÉRANGER\n(depuis mardi)", Vector3(-2.45 + 6 * 0.95, 1.55, dz + 0.09), 0.0022, Color(0.9, 0.85, 0.7), 36, 0.0, 6)
	VB.label(n, "CHAMBRES", Vector3(1.0, 2.75, dz + 0.1), 0.004, Color(1.0, 0.92, 0.6), 48, 0.0, 8)
	# Malo derrière le comptoir
	var malo := Talker.new()
	malo.name = "Malo"
	n.add_child(malo)
	malo.position = Vector3(-4.4, 0.31, -0.6)
	malo.setup(self, player, Characters.MALO)
	malo.rest_yaw = -PI * 0.5
	speakers.append({"id": "malo", "node": malo, "menu": null, "state": "closed", "idle": 0.0, "mode": "main", "dist": 3.4})


## Le cadre de la photo de l'auberge : les mêmes gens que sur la photo de la valise.
func _inn_photo(b: Builder, w: float) -> void:
	var x := w * 0.5 - VB.WALL_T - 0.03
	b.box(Vector3(0.06, 1.0, 1.5), Vector3(x, 1.75, 2.0), VB.DARK_WOOD, false)
	b.box(Vector3(0.05, 0.86, 1.36), Vector3(x - 0.012, 1.75, 2.0), Color(0.86, 0.74, 0.55), false)
	for k in 5:
		var z := 2.0 - 0.5 + k * 0.25
		var c := Color(0.35, 0.25, 0.18) if k != 2 else Color(0.95, 0.4, 0.15)
		b.box(Vector3(0.03, 0.34, 0.1), Vector3(x - 0.04, 1.62, z), c, false)
		b.sphere(0.06, Vector3(x - 0.04, 1.88, z), c, Vector3(0.4, 1.0, 1.0), Basis(), 6)


# --- La mairie ----------------------------------------------------------------------------------

func _hall() -> void:
	var w: float = HALL["w"]
	var d: float = HALL["d"]
	var h: float = HALL["h"]
	var s: Array = VB.shell(self, "Mairie", HALL["pos"], HALL["yaw"], w, d, h, Color(0.97, 0.93, 0.82), Color(0.28, 0.62, 0.66), Color(0.88, 0.82, 0.7), 2.0)
	var n: Node3D = s[0]
	var b: Builder = s[1]
	nodes["mairie"] = n
	# Façade : colonnes, fronton, marches
	for sx in [-1.0, 1.0]:
		for k in 2:
			b.cylinder(0.22, 0.25, h, Vector3(sx * (2.6 + k * 1.6), h * 0.5, d * 0.5 + 0.5), Color(0.98, 0.96, 0.92), Basis(), 10)
	b.box(Vector3(w, 0.3, 1.2), Vector3(0, h + 0.1, d * 0.5 + 0.5), Color(0.9, 0.85, 0.72), false)
	b.prism(Vector3(8.0, 1.6, 0.5), Vector3(0, h + 1.1, d * 0.5 + 0.9), Color(0.95, 0.9, 0.78), Basis())
	b.cylinder(0.7, 0.7, 0.1, Vector3(0, h + 1.0, d * 0.5 + 1.2), Color.WHITE, Basis(Vector3.RIGHT, PI * 0.5), 18)
	b.box(Vector3(0.05, 0.5, 0.06), Vector3(0.0, h + 1.15, d * 0.5 + 1.28), INK, false, Basis(Vector3.FORWARD, 0.2))
	b.box(Vector3(0.05, 0.35, 0.06), Vector3(0.0, h + 1.0, d * 0.5 + 1.28), INK, false, Basis(Vector3.FORWARD, -1.3))
	for k in 3:
		b.box(Vector3(5.0 - k * 0.6, 0.14, 0.7), Vector3(0, 0.06 - k * 0.0, d * 0.5 + 0.9 + k * 0.0), Color(0.82, 0.78, 0.7), false)
	VB.flag(b, Vector3(-w * 0.5 - 0.3, h + 0.3, d * 0.5 - 0.2), 2.6)
	VB.flag(b, Vector3(w * 0.5 + 0.3, h + 0.3, d * 0.5 - 0.2), 2.6)
	# Les guichets (comptoir à gauche)
	b.box(Vector3(5.6, 1.1, 0.7), Vector3(-3.25, 0.55, -0.4), VB.WOOD.darkened(0.1), true)
	b.box(Vector3(5.8, 0.08, 0.9), Vector3(-3.25, 1.12, -0.4), VB.WOOD.lightened(0.1), false)
	var gx := [-5.1, -3.25, -1.4]
	for i in 3:
		var x: float = gx[i]
		b.box(Vector3(1.5, 1.2, 0.1), Vector3(x, 1.8, -0.75), Color(0.35, 0.3, 0.4), false)
		b.box(Vector3(1.2, 0.9, 0.12), Vector3(x, 1.8, -0.75), Color(0.75, 0.9, 1.0), false)
		for k in 5:
			b.box(Vector3(0.03, 0.9, 0.14), Vector3(x - 0.5 + k * 0.25, 1.8, -0.75), Color(0.3, 0.28, 0.32), false)
		b.cylinder(0.07, 0.07, 0.03, Vector3(x + 0.55, 1.18, -0.1), Color(0.95, 0.8, 0.3), Basis(), 8)
	# Le guichet 3 est fermé : volet baissé
	b.box(Vector3(1.4, 1.1, 0.14), Vector3(-1.4, 1.8, -0.64), Color(0.82, 0.35, 0.33), false)
	b.box(Vector3(1.0, 0.3, 0.16), Vector3(-1.4, 1.8, -0.62), Color(0.95, 0.9, 0.75), false)
	# L'horloge de la semaine : sept roues, celle du mardi manque
	var wy := 2.9
	var day_cols := [Color(0.95, 0.6, 0.35), Color(0.2, 0.2, 0.25), Color(0.4, 0.75, 0.55), Color(0.55, 0.65, 0.95), Color(0.95, 0.85, 0.35), Color(0.85, 0.5, 0.8), Color(0.95, 0.45, 0.45)]
	var bz := -d * 0.5 + VB.WALL_T
	b.box(Vector3(7.8, 1.5, 0.12), Vector3(-1.5, wy, bz + 0.06), VB.DARK_WOOD, false)
	b.box(Vector3(7.6, 1.3, 0.14), Vector3(-1.5, wy, bz + 0.08), Color(0.28, 0.24, 0.3), false)
	for k in 7:
		var x := -4.5 + k * 1.0
		if k == 1:
			# Emplacement vide : trois petits ergots et une roue en creux
			b.cylinder(0.36, 0.36, 0.04, Vector3(x, wy, bz + 0.16), Color(0.12, 0.1, 0.14), Basis(Vector3.RIGHT, PI * 0.5), 14)
			for a in 3:
				var ang := a * TAU / 3.0
				b.cylinder(0.03, 0.03, 0.1, Vector3(x + cos(ang) * 0.22, wy + sin(ang) * 0.22, bz + 0.2), Color(0.8, 0.7, 0.3), Basis(Vector3.RIGHT, PI * 0.5), 6)
			continue
		var cc: Color = day_cols[k]
		b.cylinder(0.44, 0.44, 0.1, Vector3(x, wy, bz + 0.2), cc, Basis(Vector3.RIGHT, PI * 0.5), 16)
		for a in 10:
			var ang := a * TAU / 10.0 + (0.15 if k % 2 == 0 else 0.0)
			b.box(Vector3(0.12, 0.12, 0.1), Vector3(x + cos(ang) * 0.47, wy + sin(ang) * 0.47, bz + 0.2), cc.darkened(0.15), false, Basis(Vector3.BACK, ang))
		b.cylinder(0.12, 0.12, 0.14, Vector3(x, wy, bz + 0.22), Color(0.85, 0.8, 0.5), Basis(Vector3.RIGHT, PI * 0.5), 8)
	# Bureau du maire (à droite) et son calendrier
	b.box(Vector3(2.6, 0.78, 1.1), Vector3(4.0, 0.4, -2.7), VB.WOOD.darkened(0.05), true)
	b.box(Vector3(2.8, 0.07, 1.25), Vector3(4.0, 0.8, -2.7), VB.WOOD.lightened(0.12), false)
	b.box(Vector3(3.0, 0.3, 1.3), Vector3(4.0, 0.15, -3.5), VB.WOOD.darkened(0.3), true)   # estrade du maire
	b.box(Vector3(0.7, 1.0, 0.5), Vector3(4.0, 0.8, -4.0), Color(0.35, 0.28, 0.4), false)
	for k in 6:
		b.box(Vector3(0.28, 0.02 + k * 0.01, 0.2), Vector3(3.1 + (k % 3) * 0.02, 0.85 + k * 0.01, -2.4), Color(0.97, 0.95, 0.88), false, Basis(Vector3.UP, 0.15 * k))
	b.box(Vector3(0.12, 0.5, 0.14), Vector3(5.4, 0.25, -3.5), Color(0.2, 0.2, 0.2), false)
	b.cylinder(0.03, 0.03, 0.2, Vector3(4.5, 0.95, -2.5), Color(0.2, 0.2, 0.3), Basis(Vector3.RIGHT, 1.2), 6)
	# Étagère de dossiers, distributeur de tickets, bancs, plantes
	b.box(Vector3(2.0, 2.4, 0.5), Vector3(5.6, 1.2, -1.0 + 1.8), Color(0.55, 0.4, 0.3), false, Basis(Vector3.UP, PI * 0.5))
	for k in 14:
		b.box(Vector3(0.12, 0.34, 0.3), Vector3(5.3, 0.55 + (k % 4) * 0.55, 0.0 + float(k / 4) * 0.42), [Color(0.35, 0.55, 0.85), Color(0.9, 0.4, 0.4), Color(0.45, 0.75, 0.5), Color(0.95, 0.8, 0.3)][k % 4], false)
	b.box(Vector3(0.45, 1.4, 0.35), Vector3(-5.9, 0.7, 3.2), Color(0.85, 0.3, 0.3), false)
	b.box(Vector3(0.3, 0.3, 0.05), Vector3(-5.9, 1.2, 3.0), Color(0.95, 0.95, 0.9), false)
	b.box(Vector3(2.2, 0.1, 0.5), Vector3(-3.3, 0.45, 3.3), VB.WOOD, false)
	b.box(Vector3(2.2, 0.6, 0.08), Vector3(-3.3, 0.75, 3.55), VB.WOOD, false)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(0.08, 0.45, 0.4), Vector3(-3.3 + sx * 1.0, 0.22, 3.3), VB.DARK_WOOD, false)
	VB.plant(b, Vector3(-6.0, 0, -3.5))
	VB.plant(b, Vector3(1.8, 0, 3.4))
	VB.flag(b, Vector3(-1.6, 0, 3.7), 2.6)
	b.build(n, Toon.vertex_color(0.01), "Mesh")
	VB.label(n, "MAIRIE", Vector3(0, h + 1.9, d * 0.5 + 1.3), 0.008, Color(0.25, 0.4, 0.45), 64, 0.0, 0)
	VB.label(n, "MAIRIE DE PORT-BISCORNU", Vector3(0, h - 0.4, d * 0.5 + 0.6), 0.0035, Color(0.3, 0.3, 0.4), 52, 0.0, 0)
	var names := ["GUICHET 1\nObjets perdus", "GUICHET 2\nObjets trouvés", "GUICHET 3\nObjets qu'on n'est pas\ncertain d'avoir perdus"]
	for i in 3:
		VB.label(n, names[i], Vector3(gx[i], 2.85, -0.34), 0.0028, Color(1.0, 0.95, 0.75), 44, 0.0, 8)
	VB.label(n, "FERMÉ\nEmployé introuvable", Vector3(-1.4, 1.85, -0.5), 0.0022, Color(1.0, 1.0, 1.0), 40, 0.0, 6)
	VB.label(n, "L'HORLOGE DE LA SEMAINE\nNe pas toucher. Elle le saura.", Vector3(-1.5, 1.85, bz + 0.35), 0.0026, Color(0.95, 0.9, 0.7), 42, 0.0, 6)
	var days := ["LUN", "MAR", "MER", "JEU", "VEN", "SAM", "DIM"]
	for k in 7:
		VB.label(n, days[k] if k != 1 else "MAR ?", Vector3(-4.5 + k * 1.0, wy - 0.62, bz + 0.3), 0.0024, Color(1, 1, 0.9) if k != 1 else Color(1.0, 0.7, 0.7), 40, 0.0, 6)
	VB.label(n, "Votre numéro : 63\nNuméro en cours : 12", Vector3(-5.9, 1.55, 3.3), 0.0016, Color(0.2, 0.2, 0.25), 40, 0.0, 0)
	VB.label(n, "BUREAU DU MAIRE\nThéodore Patatras", Vector3(4.0, 2.4, -4.0 + 0.2), 0.003, Color(0.95, 0.85, 0.6), 48, 0.0, 8)
	VB.label(n, "FORMULAIRES\nD'ARRIVÉE", Vector3(5.28, 2.65, 0.8), 0.0026, Color(1.0, 0.95, 0.75), 40, -PI * 0.5, 6)
	# Le maire derrière son bureau
	var mayor := Talker.new()
	mayor.name = "Theodore"
	n.add_child(mayor)
	mayor.position = Vector3(4.0, 0.33, -3.65)
	mayor.setup(self, player, Characters.THEODORE)
	mayor.rest_yaw = PI
	speakers.append({"id": "mayor", "node": mayor, "menu": null, "state": "closed", "idle": 0.0, "mode": "main", "dist": 3.6})
	# Le calendrier sur le bureau + bouton pour l'examiner
	calendar_node = Node3D.new()
	calendar_node.name = "Calendrier"
	n.add_child(calendar_node)
	calendar_node.position = Vector3(3.1, 0.84, -2.55)
	var cb := Builder.new()
	cb.box(Vector3(0.34, 0.26, 0.04), Vector3(0, 0.15, 0), Color(0.95, 0.95, 0.9), false, Basis(Vector3.RIGHT, -0.4))
	cb.box(Vector3(0.36, 0.06, 0.05), Vector3(0, 0.27, -0.03), Color(0.85, 0.3, 0.3), false, Basis(Vector3.RIGHT, -0.4))
	cb.build(calendar_node, Toon.vertex_color(0.006), "CalMesh")
	calendar_btn = ChoiceButton.new()
	n.add_child(calendar_btn)
	calendar_btn.position = Vector3(3.1, 1.55, -1.9)
	calendar_btn.setup("Examiner le calendrier", _look_calendar, 1.5, Color(0.85, 0.95, 1.0))


# --- La boutique de Barnabé ------------------------------------------------------------------

func _shop() -> void:
	var w: float = SHOP["w"]
	var d: float = SHOP["d"]
	var h: float = SHOP["h"]
	var s: Array = VB.shell(self, "Barnabe", SHOP["pos"], SHOP["yaw"], w, d, h, Color(0.62, 0.88, 0.76), Color(0.62, 0.42, 0.82), Color(0.8, 0.66, 0.5), 1.5)
	var n: Node3D = s[0]
	var b: Builder = s[1]
	nodes["barnabe"] = n
	# Comptoir et étagères
	b.box(Vector3(3.6, 1.0, 0.7), Vector3(0, 0.5, -0.2), VB.WOOD.darkened(0.1), true)
	b.box(Vector3(3.8, 0.08, 0.9), Vector3(0, 1.02, -0.2), VB.WOOD.lightened(0.1), false)
	var goods := ["poignee", "bouton", "corde", "miroir", "cle_vide"]
	for sh in [1.0, 1.6, 2.2]:
		b.box(Vector3(5.6, 0.06, 0.4), Vector3(0, sh, -d * 0.5 + 0.4), VB.WOOD.darkened(0.2), false)
	for k in 5:
		var x := -2.2 + k * 1.1
		var kind: String = goods[k]
		for row in 3:
			Props.paint(b, kind, Transform3D(Basis(Vector3.UP, 0.4 * float(row)), Vector3(x + (row - 1) * 0.15, 1.1 + row * 0.6 + 0.1, -d * 0.5 + 0.45)))
	for k in 6:
		VB.crate(b, Vector3(-2.6 + float(k % 3) * 0.6, 0.0, -2.0 + float(k / 3) * 0.5), Vector3(0.5, 0.4 + 0.1 * (k % 2), 0.4), Color(0.8, 0.62, 0.4), 0.2 * k)
	for k in 4:
		Props.paint(b, "chicken", Transform3D(Basis(Vector3.UP, 1.0 * k), Vector3(2.4, 0.15 + k * 0.2, -1.0)))
	# Sur le comptoir : une cloche et une caisse enregistreuse bancale
	b.box(Vector3(0.5, 0.35, 0.4), Vector3(1.2, 1.24, -0.2), Color(0.85, 0.75, 0.3), false, Basis(Vector3.FORWARD, 0.12))
	b.cylinder(0.08, 0.1, 0.07, Vector3(-1.2, 1.1, -0.05), Color(0.95, 0.8, 0.3), Basis(), 8)
	# Toit en auvent rayé au-dessus de la porte
	for k in 6:
		var c := Color(0.95, 0.4, 0.4) if k % 2 == 0 else Color.WHITE
		b.box(Vector3(0.45, 0.06, 1.0), Vector3(-1.1 + k * 0.45, 2.75 - 0.02 * absf(k - 2.5), d * 0.5 + 0.5), c, false, Basis(Vector3.RIGHT, 0.18))
	b.box(Vector3(2.4, 0.5, 0.08), Vector3(0, 2.9, d * 0.5 + 0.06), Color(0.45, 0.3, 0.22), false)
	# Table dehors avec des trucs
	VB.table(b, Vector3(2.2, 0, d * 0.5 + 1.0), 0.5)
	Props.paint(b, "miroir", Transform3D(Basis(Vector3.RIGHT, -1.2), Vector3(2.2, 0.85, d * 0.5 + 1.0)))
	b.build(n, Toon.vertex_color(0.01), "Mesh")
	VB.label(n, "BARNABÉ", Vector3(0, 3.0, d * 0.5 + 0.12), 0.0045, Color(1.0, 0.92, 0.7), 56, 0.0, 12)
	VB.label(n, "Objets probablement utiles", Vector3(0, 2.72, d * 0.5 + 0.12), 0.0021, Color(1.0, 0.92, 0.7), 40, 0.0, 6)
	var prices := ["Poignée : 4", "Bouton : 2", "Corde : 3", "Miroir : 5", "Clé : 6"]
	for k in 5:
		VB.label(n, prices[k], Vector3(-2.2 + k * 1.1, 0.9, -d * 0.5 + 0.7), 0.0016, Color(0.2, 0.2, 0.3), 36, 0.0, 0)
	VB.label(n, "On ne rend pas la monnaie.\nOn ne rend pas non plus la marchandise.", Vector3(0, 2.6, -d * 0.5 + 0.3), 0.0022, Color(0.3, 0.2, 0.3), 40, 0.0, 0)
	var barn := Talker.new()
	barn.name = "BarnabeNpc"
	n.add_child(barn)
	barn.position = Vector3(0, 0.03, -1.15)
	barn.setup(self, player, Characters.BARNABE)
	barn.rest_yaw = PI
	speakers.append({"id": "barnabe", "node": barn, "menu": null, "state": "closed", "idle": 0.0, "mode": "main", "dist": 3.4})


# --- Nina et les menus ------------------------------------------------------------------------------

const NINA_WAYPOINTS := [Vector2(-3.8, -47.0), Vector2(4.0, -47.5), Vector2(5.5, -51.5), Vector2(-5.0, -52.0), Vector2(0.0, -45.0), Vector2(-9.0, -48.5)]


func _make_speakers() -> void:
	nina = Talker.new()
	nina.name = "Nina"
	add_child(nina)
	var np: Vector2 = NINA_WAYPOINTS[0]
	nina.position = Vector3(np.x, H, np.y)
	nina.setup(self, player, Characters.NINA)
	nina.moving = true
	speakers.append({"id": "nina", "node": nina, "menu": null, "state": "closed", "idle": 0.0, "mode": "main", "dist": 3.0})
	for sp in speakers:
		var m := TalkMenu.new()
		add_child(m)
		sp["menu"] = m


func after_phare() -> void:
	y.after_phare()


func refresh_calendar() -> void:
	if calendar_btn == null:
		return
	var on: bool = Save.story.get("desk_ok", false) and not Save.story.get("calendar_seen", false)
	calendar_btn.visible = on
	calendar_btn.collision_layer = 16 if on else 0


func _look_calendar() -> void:
	if Save.story.get("calendar_seen", false):
		return
	Save.story["calendar_seen"] = true
	Save.save_game()
	refresh_calendar()
	var p: Vector3 = calendar_node.global_position + Vector3(0, 1.0, 0)
	Fx.text(world, p, "LUNDI", Color(0.8, 0.9, 1.0), 0.9, 1.4)
	get_tree().create_timer(1.1).timeout.connect(func():
		Fx.text(world, p + Vector3(0, -0.2, 0), "...MERCREDI.", Color(1.0, 0.8, 0.8), 0.9, 2.0))
	get_tree().create_timer(2.6).timeout.connect(func():
		Fx.text(world, p + Vector3(0, 0.3, 0), "Il manque une page. Un mardi ?", Color(1.0, 0.95, 0.6), 0.6, 3.0)
		_pico("Lundi... mercredi. Hmm. Je ne suis pas expert en calendriers, mais il y a un trou. Un trou en forme de mardi.")
		var mayor = _speaker("mayor")["node"]
		mayor.chibi.say("C'est normal. Nous sommes mercredi.", 3.0))


# --- Boucle -------------------------------------------------------------------------------------------------

func _speaker(id: String) -> Dictionary:
	for sp in speakers:
		if sp["id"] == id:
			return sp
	return {}


func _name() -> String:
	return Characters.LIST[player.char_id]["name"]


func _say(node, text: String) -> void:
	node.chibi.say(text, 2.5 + text.length() * 0.055)


func _pico(text: String) -> void:
	if player.pico and player.pico.active:
		player.pico.say(text)


func _once(key: String, text: String) -> void:
	var said: Dictionary = Save.story.get("said", {})
	if said.has(key):
		return
	said[key] = true
	Save.story["said"] = said
	_pico(text)


func _zone_of(p: Vector3) -> String:
	for z in [["inn", "auberge", INN], ["hall", "mairie", HALL], ["shop", "barnabe", SHOP], ["bakery", "boulangerie", VX.BAKERY], ["workshop", "atelier", VX.WORKSHOP], ["petro", "petronille", VX.PETRO], ["ruin", "abandonnee", VX.RUIN]]:
		var n: Node3D = nodes[z[1]]
		var lp: Vector3 = n.to_local(p)
		var info: Dictionary = z[2]
		if absf(lp.x) < float(info["w"]) * 0.5 + 0.2 and absf(lp.z) < float(info["d"]) * 0.5 + 0.2 and p.y < H + 3.0 and p.y > H - 1.0:
			return z[0]
	if Vector2(p.x, p.z).distance_to(SQUARE) < 10.0:
		return "square"
	if Island.village_d(p.x, p.z) < 1.1:
		return "village"
	return ""


func _physics_process(delta: float) -> void:
	if player == null or player.in_dungeon:
		return
	var pp: Vector3 = player.global_position
	_update_zone(pp)
	_update_nina(delta)
	x.update()
	z.update()
	clock.update()
	var cam: Vector3 = player.camera.global_position
	for sp in speakers:
		var node = sp["node"]
		var near: bool = pp.distance_to(node.global_position) < float(sp["dist"]) and absf(pp.y - node.global_position.y) < 2.5
		if near and sp["state"] == "closed":
			sp["state"] = "open"
			sp["idle"] = 0.0
			sp["mode"] = "main"
			_place_menu(sp)
			_apply(sp, brain.greet(sp["id"], _name()))
			_show(sp)
		elif not near and sp["state"] != "closed":
			sp["state"] = "closed"
			sp["menu"].clear()
			sp["menu"].set_header("")
			Save.save_game()
		if sp["state"] != "closed":
			sp["menu"].face(cam)
			sp["idle"] += delta
			if sp["idle"] > 20.0:
				sp["idle"] = 0.0
				_say(node, brain.idle(sp["id"]))


func _update_zone(pp: Vector3) -> void:
	var z := _zone_of(pp)
	if z == zone:
		return
	var old := zone
	zone = z
	if player.pico:
		player.pico.zone = z
	if z != "" and old == "":
		if not Save.story.get("village_seen", false):
			Save.story["village_seen"] = true
			Save.save_game()
			Fx.text(world, player._front(3.0) + Vector3(0, 1.4, 0), "PORT-BISCORNU", Color(1.0, 0.9, 0.5), 1.4, 3.5)
			_pico("Port-Biscornu... Ce nom me dit quelque chose. Enfin non. Je fais semblant, c'est plus poli.")
	match z:
		"inn":
			_once("inn", "Ça sent la soupe, le bois ciré et un secret. Surtout le secret.")
		"hall":
			_once("hall", "Trois guichets pour un si petit village. Je vais attendre ici, très calme.")
		"bakery":
			_once("bakery", "Ça sent le pain. Et le registre des fournées, mais surtout le pain.")
		"workshop":
			_once("workshop", "Un atelier fermé pour inventaire. Je n'ai jamais vu autant d'engrenages en vacances.")
		"petro":
			_once("petro", "Ça sent le thé et le temps qui passe. Beaucoup de temps.")
		"ruin":
			_once("ruin", "Une maison abandonnée habitée. C'est le genre de phrase que je ne devrais pas dire à voix haute.")
		"shop":
			_once("shop", "Ce monsieur vend des objets que même les objets ne comprennent pas.")


func _place_menu(sp: Dictionary) -> void:
	# Le menu flotte devant le joueur, un peu sur le côté pour ne pas cacher le perso
	var node = sp["node"]
	var to: Vector3 = node.global_position - player.global_position
	to.y = 0.0
	to = to.normalized() if to.length() > 0.05 else Vector3.FORWARD
	var side := to.cross(Vector3.UP).normalized()
	sp["menu"].global_position = player.global_position + to * 0.95 + side * 0.6 + Vector3(0, 1.3, 0)


func _show(sp: Dictionary) -> void:
	var m = sp["menu"]
	var opts: Array = []
	if sp["mode"] == "goods":
		for g in brain.SHOP_GOODS:
			opts.append(["%s  (%d)" % [g[1], g[2]], _buy.bind(sp, g[0], g[2])])
		opts.append(["< Retour", _back.bind(sp), Color(0.9, 0.9, 0.9)])
		m.show_options(opts)
		m.set_header("BARNABÉ  ·  Coquillages : %d" % Save.shells)
		return
	for o in brain.options(sp["id"]):
		opts.append([o[1], _choose.bind(sp, o[0])])
	m.show_options(opts)
	m.set_header(_title_of(sp["id"]))


func _title_of(id: String) -> String:
	match id:
		"malo":
			return "MALO"
		"barnabe":
			return "BARNABÉ"
		"nina":
			return "NINA"
		"basile":
			return "BASILE"
		"gerard":
			return "GÉRARD"
		"marguerite":
			return "MARGUERITE"
		"petronille":
			return "MADAME PÉTRONILLE"
		"eleonore":
			return "ÉLÉONORE CHARDON"
		"odile":
			return "ODILE AUBÉPINE"
		"gaspard":
			return "GASPARD RONCEVAL"
		"anselme":
			return "MAÎTRE ANSELME"
		"mirette":
			return "MIRETTE"
	return "THÉODORE PATATRAS"


func _back(sp: Dictionary) -> void:
	sp["mode"] = "main"
	_show(sp)


func _choose(sp: Dictionary, intent: String) -> void:
	sp["idle"] = 0.0
	if intent == "goods":
		sp["mode"] = "goods"
		_say(sp["node"], "Voilà ce que j'ai ! Tout est probablement utile.")
		_show(sp)
		return
	var r: Dictionary = brain.respond(sp["id"], intent)
	_apply(sp, r)
	Save.save_game()
	_show(sp)


func _buy(sp: Dictionary, id: String, price: int) -> void:
	sp["idle"] = 0.0
	var ok: bool = Save.shells >= price
	_say(sp["node"], brain.buy_line(id, ok, price))
	if ok:
		Save.shells -= price
		Save.add_item(id)
		Fx.text(world, sp["node"].global_position + Vector3(0, 2.0, 0), "→ Sac : " + Inv.item_name(id), Color(1.0, 0.95, 0.7), 0.6, 1.8)
		Fx.puff(world, sp["node"].global_position + Vector3(0, 0.9, 0), Color(1.0, 0.9, 0.7))
		if id == "poignee":
			_pico("Une poignée de porte. On connaît une porte qui n'a pas de maison. Je dis ça, je dis rien.")
	Save.save_game()
	_show(sp)


## Applique le résultat d'une réplique : texte, drapeaux, objet donné, effets.
func _apply(sp: Dictionary, r: Dictionary) -> void:
	_say(sp["node"], str(r.get("text", "")))
	var flags: Dictionary = r.get("flag", {})
	for k in flags:
		Save.story[k] = flags[k]
	if r.has("give"):
		Save.add_item(str(r["give"]))
		Fx.text(world, sp["node"].global_position + Vector3(0, 2.1, 0), "→ Sac : " + Inv.item_name(str(r["give"])), Color(1.0, 0.95, 0.7), 0.7, 2.0)
	var ev: String = str(r.get("event", ""))
	var node = sp["node"]
	if ev.begins_with("z_"):
		z.event(ev, node)
	match ev:
		"malo_glass":
			_drop_glass(node)
			_pico("Il a laissé tomber son verre. Il t'a dit « en avance ». Je ne dis pas que c'est suspect, mais je le pense très fort.")
		"hint_hall":
			_pico("La mairie, sur la place. Le grand bâtiment avec trop de colonnes.")
		"room_key":
			Fx.text(world, node.global_position + Vector3(0, 2.5, 0), "CHAMBRE 4 : OK", Color(0.7, 1.0, 0.75), 1.0, 2.0)
			_pico("La chambre 4, entre la 3 et la 5. La 7 a l'air de ne pas aimer le monde.")
		"registered":
			Fx.text(world, node.global_position + Vector3(0, 2.5, 0), "ENREGISTRÉ(E) ! (provisoirement)", Color(1.0, 0.9, 0.5), 1.1, 2.5)
			_pico("Enregistré au dos d'un menu. C'est très officiel. Surtout l'odeur de soupe.")
		"desk_ok":
			refresh_calendar()
			_pico("On peut fouiller le bureau ! Légalement ! Je n'ai jamais été aussi excité.")
		"tuesday_quest":
			Fx.text(world, node.global_position + Vector3(0, 2.7, 0), "NOUVELLE QUÊTE : LE MARDI QUI AVAIT DISPARU", Color(0.7, 0.9, 1.0), 1.2, 4.0)
			Fx.puff(world, player.global_position + Vector3(0, 1.2, 0), Color(0.8, 0.9, 1.0))
			_pico("Un jour qui disparaît. C'est un vol ou une négligence ? Dans les deux cas, on enquête.")
		"eleonore_known":
			x.open_barricade()
			Fx.text(world, node.global_position + Vector3(0, 2.5, 0), "INDICE : ÉLÉONORE CHARDON", Color(1.0, 0.92, 0.4), 1.0, 3.0)
			_pico("La maison abandonnée, côté est. Les planches à la porte ont l'air d'avoir changé d'avis.")
		"got_piece":
			Fx.puff(world, node.global_position + Vector3(0, 1.0, 0), Color(0.6, 1.0, 0.7))
			_pico("Un morceau de roue verte. Si on en trouve deux autres, on pourra les assembler à la mairie.")
		"got_axe":
			Fx.puff(world, node.global_position + Vector3(0, 1.0, 0), Color(1.0, 0.9, 0.4))
			_pico("L'axe de l'horloge ! Direction la mairie, avec la roue.")
		"shells15":
			Save.shells += 15
			Fx.text(world, node.global_position + Vector3(0, 2.3, 0), "+15 coquillages", Color(1.0, 0.9, 0.5), 0.9, 2.0)
			_pico("Un conflit résolu sans capturer personne. Je crois que c'est la meilleure fin de pêche.")
		"plank_give":
			Save.add_item("planche", -1)
			Save.shells += 10
			Fx.text(world, node.global_position + Vector3(0, 2.3, 0), "+10 coquillages", Color(1.0, 0.9, 0.5), 0.9, 2.0)
			_pico("Tu as donné la planche. Elle était très importante, pourtant. Enfin, je crois que c'est ce que j'avais dit.")
		"plank_keep":
			Fx.text(world, node.global_position + Vector3(0, 2.3, 0), "Pico garde la planche", Color(0.9, 0.95, 1.0), 0.8, 2.0)
			_pico("Je la garde ! Elle est très importante. Je ne sais plus pourquoi. Je sais seulement qu'elle servira plus tard.")
		"key_back":
			_pico("Il a eu peur de sa propre offre. Une clé que Barnabé veut mais ne peut pas prendre. Je la garde au chaud.")
		"nina_leave":
			_nina_away = true
			_nina_wait = 0.0
			_nina_speed = 3.2
			_nina_wp = 5
			var sp2 := _speaker("nina")
			sp2["state"] = "closed"
			sp2["menu"].clear()
			sp2["menu"].set_header("")
			_pico("Elle t'a déjà vu ? Où ça ? Quand ? Je commence à avoir trop de questions pour un seul renard.")
	refresh_calendar()


func _drop_glass(malo) -> void:
	var g := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.06
	cm.bottom_radius = 0.045
	cm.height = 0.14
	g.mesh = cm
	g.material_override = Toon.flat(Color(0.8, 0.95, 1.0))
	world.add_child(g)
	var start: Vector3 = malo.global_position + Vector3(0.0, 1.1, 0.0)
	g.global_position = start
	var floor_y: float = malo.global_position.y + 0.07
	var tw := create_tween()
	tw.tween_property(g, "global_position:y", floor_y, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		Fx.text(world, g.global_position + Vector3(0, 0.6, 0), "CLING !", Color(0.8, 0.95, 1.0), 1.0, 1.2)
		Fx.puff(world, g.global_position, Color(0.85, 0.95, 1.0))
		g.queue_free())
	malo.chibi.pop()


func _update_nina(delta: float) -> void:
	var sp := _speaker("nina")
	if sp.is_empty():
		return
	var pp: Vector3 = player.global_position
	var near: bool = pp.distance_to(nina.global_position) < 4.5
	var target: Vector2 = NINA_WAYPOINTS[_nina_wp]
	var cur := Vector2(nina.global_position.x, nina.global_position.z)
	var to := target - cur
	var stop: bool = (near and not _nina_away) or sp["state"] != "closed"
	var dir := Vector3.ZERO
	if stop:
		var tp: Vector3 = pp - nina.global_position
		tp.y = 0.0
		if tp.length() > 0.1:
			nina.chibi.rotation.y = lerp_angle(nina.chibi.rotation.y, atan2(-tp.x, -tp.z) - nina.global_rotation.y, clampf(delta * 5.0, 0.0, 1.0))
	elif _nina_wait > 0.0:
		_nina_wait -= delta
	elif to.length() < 0.4:
		_nina_wait = randf_range(1.5, 4.0)
		_nina_wp = (_nina_wp + 1 + randi() % 3) % NINA_WAYPOINTS.size()
		if _nina_away and _nina_wp != 5:
			_nina_away = false
			_nina_speed = 1.0
	else:
		var d2 := to.normalized()
		dir = Vector3(d2.x, 0, d2.y)
	var spd := _nina_speed
	var nx: float = nina.global_position.x + dir.x * spd * delta
	var nz: float = nina.global_position.z + dir.z * spd * delta
	nina.global_position = Vector3(nx, Island.height(nx, nz) + 0.02, nz)
	nina.chibi.walk = lerpf(nina.chibi.walk, 1.0 if dir.length() > 0.1 else 0.0, clampf(delta * 6.0, 0.0, 1.0))
	if dir.length() > 0.1:
		nina.chibi.rotation.y = lerp_angle(nina.chibi.rotation.y, atan2(-dir.x, -dir.z), clampf(delta * 8.0, 0.0, 1.0))


## Mode PC : touches 1 à 6 pour le menu ouvert le plus proche.
func choose(index: int) -> bool:
	var best := {}
	var bd := 1e9
	for sp in speakers:
		if sp["state"] != "closed":
			var dd: float = player.global_position.distance_to(sp["node"].global_position)
			if dd < bd:
				bd = dd
				best = sp
	if best.is_empty():
		return false
	best["menu"].choose(index)
	return true


func is_open() -> bool:
	for sp in speakers:
		if sp["state"] != "closed":
			return true
	return false


func on_bonked(t) -> void:
	Fx.text(world, t.global_position + Vector3(0, 1.9, 0), "BONK !", Color(1.0, 0.5, 0.3), 1.0)
	t.chibi.pop()
	for sp in speakers:
		if sp["node"] == t:
			_say(t, brain.bonked(sp["id"]))
