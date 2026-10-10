extends RefCounted
## v34 : « L'île vivante » — des animaux et des personnages rigolos, et des objets
## avec lesquels on peut jouer (champignons trampolines, xylophone à pas, bouton interdit,
## puits à vœux, cloche, boîte aux lettres…). Rien ici n'est nécessaire à l'histoire.

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Island := preload("res://scripts/island.gd")
const Fx := preload("res://scripts/fx.gd")
const Save := preload("res://scripts/save.gd")
const Bells := preload("res://scripts/bells.gd")
const Animal := preload("res://scripts/animal.gd")
const Talker := preload("res://scripts/talker.gd")
const Characters := preload("res://scripts/characters.gd")
const VB := preload("res://scripts/village_build.gd")

const INK := Color(0.13, 0.08, 0.17)
const OL := 0.012
## Zones où les animaux ne vont pas (maison, boutique, colline, donjon, village)
const AVOID := [Vector3(0.0, -12.0, 6.5), Vector3(20.0, 1.0, 6.5), Vector3(-26.0, 4.0, 10.0), Vector3(-17.0, 19.0, 5.0), Vector3(0.0, -52.0, 3.0)]
const NOTES := [261.63, 293.66, 329.63, 392.0, 440.0, 523.25, 587.33]
const RAINBOW := [Color(1.0, 0.4, 0.4), Color(1.0, 0.65, 0.3), Color(1.0, 0.9, 0.35), Color(0.5, 0.85, 0.4), Color(0.4, 0.8, 0.95), Color(0.5, 0.5, 1.0), Color(0.85, 0.5, 0.95)]

var v
var animals: Array = []
var folk: Array = []
var _cd := {}
var _mush: Array = []      # [Node3D, Vector3 pos, float top, MeshInstance3D]
var _bar_state: Array = []
var _bars: Array = []      # [Vector3 centre, Node3D, int note]
var _statue: Talker
var _statue_t := 0.0
var _statue_next := 1.0
var _bounce_cd := 0.0
var _gull: Animal
var _cat: Animal
var _cat_wake := 0.0
var _counters := {}


func build() -> void:
	_animals()
	_folks()
	_mushrooms()
	_xylophone()
	_red_button()
	_bell_post()
	_well()
	_mailbox()


# --- Petites aides -------------------------------------------------------------------------

func _cool(key: String, secs: float) -> bool:
	var now := Time.get_ticks_msec()
	if now < int(_cd.get(key, 0)):
		return false
	_cd[key] = now + int(secs * 1000.0)
	return true


func _count(key: String) -> int:
	_counters[key] = int(_counters.get(key, 0)) + 1
	return int(_counters[key])


func _later(t: float, c: Callable) -> void:
	v.get_tree().create_timer(t).timeout.connect(c)


func _pp() -> Vector3:
	return v.player.global_position


func _text(pos: Vector3, txt: String, col := Color(1.0, 0.95, 0.6), size := 0.9, life := 2.4) -> void:
	Fx.text(v.world, pos, txt, col, size, life)


func _gain(n: int, pos: Vector3) -> void:
	Save.shells += n
	Save.save_game()
	_text(pos, "+%d coquillage%s" % [n, "s" if n > 1 else ""], Color(1.0, 0.85, 0.3), 1.0, 2.0)


func _hs(parent: Node3D, pos: Vector3, text: String, cb: Callable, cond := Callable(), dist := 2.8) -> void:
	if not cond.is_valid():
		cond = func(): return true
	v.x.hotspot(parent, pos, text, cb, cond, 2.0, dist)


func _eyes(b: Builder, y: float, z: float, gap: float, r: float) -> void:
	for sx in [-1.0, 1.0]:
		b.sphere(r, Vector3(sx * gap, y, z), Color.WHITE, Vector3(1, 1.15, 0.6), Basis(), 8)
		b.sphere(r * 0.55, Vector3(sx * gap, y, z - r * 0.4), INK, Vector3(1, 1.2, 0.5), Basis(), 6)


func _legs(b: Builder, xs: Array, zs: Array, h: float, col: Color, r := 0.035) -> void:
	for x in xs:
		for z in zs:
			b.cylinder(r, r, h, Vector3(x, h * 0.5, z), col, Basis(), 6)


## Fabrique un animal : nœud + corps dessiné + réglages
func _make(kind: String, pos: Vector2, radius: float, painter: Callable, voice := "", pitch := 1.0) -> Animal:
	var a := Animal.new()
	a.name = kind.capitalize()
	a.kind = kind
	a.voice = voice
	a.voice_pitch = pitch
	a.radius = radius
	a.avoid = AVOID
	a.player = v.player
	a.world = v.world
	v.add_child(a)
	a.home = Vector3(pos.x, 0.0, pos.y)
	a.global_position = Vector3(pos.x, Island.height(pos.x, pos.y), pos.y)
	a.body = Node3D.new()
	a.body.name = "Body"
	a.add_child(a.body)
	var b := Builder.new()
	painter.call(b)
	b.build(a.body, Toon.vertex_color(OL), "Mesh")
	animals.append(a)
	return a


# --- Dessins des animaux (le museau regarde vers -Z) ----------------------------------------

func _paint_crab(b: Builder) -> void:
	var red := Color(0.95, 0.4, 0.3)
	b.sphere(0.17, Vector3(0, 0.12, 0), red, Vector3(1.2, 0.55, 0.9), Basis(), 10)
	for sx in [-1.0, 1.0]:
		b.cylinder(0.012, 0.012, 0.1, Vector3(sx * 0.07, 0.25, -0.1), red, Basis(), 5)
		b.sphere(0.045, Vector3(sx * 0.07, 0.31, -0.11), Color.WHITE, Vector3.ONE, Basis(), 8)
		b.sphere(0.024, Vector3(sx * 0.07, 0.31, -0.145), INK, Vector3.ONE, Basis(), 6)
		b.cylinder(0.02, 0.02, 0.16, Vector3(sx * 0.2, 0.2, -0.13), red, Basis(Vector3(0, 0, 1), sx * 0.5), 6)
		b.sphere(0.075, Vector3(sx * 0.27, 0.3, -0.2), red.lightened(0.1), Vector3(1.0, 0.8, 1.3), Basis(), 8)
		for k in 3:
			b.cylinder(0.01, 0.01, 0.16, Vector3(sx * 0.2, 0.06, 0.02 + k * 0.07), red.darkened(0.2), Basis(Vector3(0, 0, 1), sx * 1.0), 5)


func _paint_goat(b: Builder) -> void:
	var cream := Color(0.96, 0.93, 0.85)
	var side := Basis(Vector3.RIGHT, PI * 0.5)
	b.capsule(0.22, 0.85, Vector3(0, 0.55, 0), cream, side)
	b.sphere(0.17, Vector3(0, 0.82, -0.5), cream, Vector3(0.9, 1.0, 1.15), Basis(), 10)
	b.sphere(0.07, Vector3(0, 0.74, -0.66), Color(0.9, 0.8, 0.75), Vector3(1, 0.8, 1), Basis(), 8)
	_eyes(b, 0.88, -0.62, 0.09, 0.035)
	for sx in [-1.0, 1.0]:
		b.spike(0.035, 0.22, Vector3(sx * 0.09, 1.04, -0.45), Vector3(sx * 0.4, 1.0, 0.7), Color(0.85, 0.78, 0.6))
		b.sphere(0.06, Vector3(sx * 0.18, 0.84, -0.47), cream.darkened(0.08), Vector3(1.4, 0.5, 0.8), Basis(), 6)
	b.spike(0.03, 0.12, Vector3(0, 0.66, -0.64), Vector3(0, -1, 0), Color(0.9, 0.88, 0.8))
	b.sphere(0.06, Vector3(0, 0.62, 0.48), cream, Vector3.ONE, Basis(), 6)
	_legs(b, [-0.12, 0.12], [-0.3, 0.3], 0.35, Color(0.4, 0.34, 0.3), 0.045)


func _paint_chicken(b: Builder, col := Color(1, 1, 1), big := false) -> void:
	var s := 1.25 if big else 1.0
	b.sphere(0.2 * s, Vector3(0, 0.3 * s, 0.03), col, Vector3(1, 0.95, 1.2), Basis(), 10)
	b.sphere(0.1 * s, Vector3(0, 0.55 * s, -0.17 * s), col, Vector3.ONE, Basis(), 8)
	b.box(Vector3(0.03, 0.07 * s, 0.1 * s), Vector3(0, 0.66 * s, -0.17 * s), Color(0.9, 0.2, 0.2), false)
	b.prism(Vector3(0.07, 0.06, 0.09), Vector3(0, 0.53 * s, -0.3 * s), Color(1.0, 0.75, 0.2), Basis(Vector3.RIGHT, -PI * 0.5))
	b.sphere(0.03, Vector3(0, 0.45 * s, -0.27 * s), Color(0.9, 0.2, 0.2), Vector3(0.6, 1.2, 0.6), Basis(), 6)
	for sx in [-1.0, 1.0]:
		b.sphere(0.018, Vector3(sx * 0.07 * s, 0.58 * s, -0.24 * s), INK, Vector3.ONE, Basis(), 6)
		b.sphere(0.09 * s, Vector3(sx * 0.17 * s, 0.3 * s, 0.05), col.darkened(0.06), Vector3(0.4, 0.9, 1.1), Basis(), 8)
	var tail := Color(0.3, 0.6, 0.9) if big else col.darkened(0.05)
	for k in 3:
		b.spike(0.05 * s, 0.25 * s, Vector3((k - 1) * 0.05, 0.42 * s, 0.24 * s), Vector3((k - 1) * 0.3, 1.0, 1.2), tail)
	b.cylinder(0.012, 0.012, 0.15 * s, Vector3(-0.06, 0.07 * s, 0), Color(1.0, 0.75, 0.2), Basis(), 5)
	b.cylinder(0.012, 0.012, 0.15 * s, Vector3(0.06, 0.07 * s, 0), Color(1.0, 0.75, 0.2), Basis(), 5)


func _paint_chick(b: Builder) -> void:
	var y := Color(1.0, 0.88, 0.3)
	b.sphere(0.1, Vector3(0, 0.12, 0), y, Vector3.ONE, Basis(), 8)
	b.sphere(0.065, Vector3(0, 0.23, -0.05), y, Vector3.ONE, Basis(), 8)
	b.prism(Vector3(0.04, 0.04, 0.05), Vector3(0, 0.22, -0.11), Color(1.0, 0.6, 0.2), Basis(Vector3.RIGHT, -PI * 0.5))
	for sx in [-1.0, 1.0]:
		b.sphere(0.012, Vector3(sx * 0.03, 0.25, -0.1), INK, Vector3.ONE, Basis(), 5)


func _paint_pig(b: Builder) -> void:
	var pink := Color(1.0, 0.72, 0.78)
	b.capsule(0.24, 0.8, Vector3(0, 0.4, 0), pink, Basis(Vector3.RIGHT, PI * 0.5))
	b.sphere(0.18, Vector3(0, 0.47, -0.5), pink, Vector3(1.0, 0.95, 0.9), Basis(), 10)
	b.cylinder(0.08, 0.08, 0.06, Vector3(0, 0.42, -0.66), Color(1.0, 0.58, 0.66), Basis(Vector3.RIGHT, PI * 0.5), 8)
	for sx in [-1.0, 1.0]:
		b.sphere(0.012, Vector3(sx * 0.03, 0.42, -0.695), INK, Vector3.ONE, Basis(), 5)
		b.prism(Vector3(0.1, 0.12, 0.03), Vector3(sx * 0.12, 0.64, -0.46), Color(1.0, 0.62, 0.7), Basis(Vector3(0, 0, 1), sx * 0.5))
	_eyes(b, 0.54, -0.62, 0.09, 0.03)
	b.torus(0.012, 0.045, Vector3(0, 0.5, 0.46), pink.darkened(0.1), Basis(Vector3.RIGHT, PI * 0.5))
	_legs(b, [-0.12, 0.12], [-0.28, 0.28], 0.2, Color(1.0, 0.6, 0.68), 0.05)


func _paint_snail(b: Builder) -> void:
	var cream := Color(0.95, 0.88, 0.7)
	b.capsule(0.05, 0.3, Vector3(0, 0.05, 0), cream, Basis(Vector3.RIGHT, PI * 0.5))
	b.sphere(0.04, Vector3(0, 0.1, -0.15), cream, Vector3.ONE, Basis(), 8)
	for sx in [-1.0, 1.0]:
		b.cylinder(0.006, 0.006, 0.09, Vector3(sx * 0.02, 0.17, -0.16), cream, Basis(), 4)
		b.sphere(0.014, Vector3(sx * 0.02, 0.225, -0.16), INK, Vector3.ONE, Basis(), 5)
	b.sphere(0.1, Vector3(0, 0.15, 0.05), Color(0.7, 0.45, 0.3), Vector3(0.6, 1.0, 1.0), Basis(), 10)
	b.torus(0.012, 0.055, Vector3(0.035, 0.15, 0.05), Color(0.85, 0.6, 0.4), Basis(Vector3(0, 0, 1), PI * 0.5))


func _paint_frog(b: Builder) -> void:
	var g := Color(0.35, 0.78, 0.35)
	b.sphere(0.13, Vector3(0, 0.1, 0), g, Vector3(1.1, 0.75, 1.2), Basis(), 10)
	for sx in [-1.0, 1.0]:
		b.sphere(0.05, Vector3(sx * 0.07, 0.22, -0.07), g.lightened(0.1), Vector3.ONE, Basis(), 8)
		b.sphere(0.03, Vector3(sx * 0.07, 0.235, -0.105), Color.WHITE, Vector3.ONE, Basis(), 6)
		b.sphere(0.016, Vector3(sx * 0.07, 0.235, -0.13), INK, Vector3.ONE, Basis(), 5)
		b.sphere(0.06, Vector3(sx * 0.12, 0.05, 0.1), g.darkened(0.1), Vector3(0.6, 0.5, 1.3), Basis(), 6)
		b.sphere(0.04, Vector3(sx * 0.1, 0.03, -0.09), g.darkened(0.1), Vector3(1, 0.5, 1.2), Basis(), 6)
	b.box(Vector3(0.12, 0.012, 0.01), Vector3(0, 0.1, -0.15), Color(0.8, 0.3, 0.3), false)


func _paint_gull(b: Builder) -> void:
	var w := Color(0.97, 0.97, 1.0)
	b.sphere(0.17, Vector3(0, 0.3, 0), w, Vector3(0.9, 0.9, 1.4), Basis(), 10)
	b.sphere(0.1, Vector3(0, 0.5, -0.17), w, Vector3.ONE, Basis(), 8)
	b.prism(Vector3(0.07, 0.15, 0.05), Vector3(0, 0.48, -0.31), Color(1.0, 0.65, 0.2), Basis(Vector3.RIGHT, -PI * 0.5))
	for sx in [-1.0, 1.0]:
		b.sphere(0.022, Vector3(sx * 0.055, 0.54, -0.24), INK, Vector3.ONE, Basis(), 6)
		b.box(Vector3(0.05, 0.012, 0.012), Vector3(sx * 0.055, 0.575, -0.255), INK, false, Basis(Vector3(0, 0, 1), sx * -0.4))
		b.sphere(0.12, Vector3(sx * 0.17, 0.32, 0.05), Color(0.7, 0.74, 0.82), Vector3(0.25, 0.8, 1.5), Basis(), 8)
	b.prism(Vector3(0.14, 0.04, 0.2), Vector3(0, 0.3, 0.3), w.darkened(0.05), Basis())
	_legs(b, [-0.05, 0.05], [0.0], 0.14, Color(1.0, 0.6, 0.2), 0.012)


func _paint_cat(b: Builder) -> void:
	var o := Color(1.0, 0.7, 0.35)
	var st := Color(0.85, 0.5, 0.2)
	# assis, enroulé
	b.sphere(0.24, Vector3(0, 0.2, 0), o, Vector3(1.0, 0.8, 1.15), Basis(), 12)
	b.sphere(0.15, Vector3(0, 0.38, -0.2), o, Vector3.ONE, Basis(), 10)
	for sx in [-1.0, 1.0]:
		b.prism(Vector3(0.09, 0.11, 0.04), Vector3(sx * 0.09, 0.53, -0.2), o, Basis(Vector3(0, 0, 1), sx * -0.15))
		b.box(Vector3(0.05, 0.015, 0.012), Vector3(sx * 0.06, 0.4, -0.34), INK, false)
		b.box(Vector3(0.012, 0.1, 0.02), Vector3(sx * 0.15, 0.22, -0.06), st, false)
	b.sphere(0.022, Vector3(0, 0.36, -0.345), Color(1.0, 0.5, 0.55), Vector3.ONE, Basis(), 6)
	for k in 3:
		b.box(Vector3(0.2, 0.02, 0.025), Vector3(0, 0.3 + k * 0.05, 0.1 - k * 0.04), st, false)
	b.torus(0.03, 0.2, Vector3(0.14, 0.08, 0.2), o, Basis(Vector3.RIGHT, PI * 0.5))


# --- Les animaux ---------------------------------------------------------------------------

func _animals() -> void:
	var crab_lines := ["PINCE-SANS-RIRE !", "Je marche droit. C'est le monde qui est de travers.", "Clic clac !", "Chaque pas de côté est un pas en avant."]
	for cp in [Vector2(9.0, 45.5), Vector2(-9.0, 44.5)]:
		var c := _make("crabe", cp, 4.0, _paint_crab, "tick", 0.7)
		c.sidestep = true
		c.flee = 3.0
		c.speed = 0.9
		c.min_h = 0.2
		c.max_h = 1.3
		c.talk_color = Color(1.0, 0.6, 0.5)
		_hs(c, Vector3(0, 0.75, 0), "Saluer le crabe", func():
			c.react(crab_lines[randi() % crab_lines.size()])
			if _cool("crab", 45.0) and randf() < 0.5:
				_later(0.8, func(): _gain(1, c.global_position + Vector3(0, 0.9, 0)))
			, Callable(), 2.4)

	var goat := _make("chevre", Vector2(-19.0, -16.0), 5.0, _paint_goat, "baa", 1.0)
	goat.curious = true
	goat.speed = 0.9
	goat.talk_color = Color(1.0, 0.95, 0.85)
	var goat_lines := ["BÊÊÊ !", "Elle mange ton chapeau... puis le recrache.", "Elle te regarde comme si tu devais de l'argent.", "Bêêê-ni soit celui qui me gratte."]
	_hs(goat, Vector3(0, 1.5, 0), "Caresser Bouboule", func():
		goat.react(goat_lines[randi() % goat_lines.size()])
		, Callable(), 2.8)

	# Poulailler en liberté, au sud du village
	var coq := _make("coq", Vector2(-7.0, -32.0), 2.5, _paint_chicken.bind(Color(1.0, 0.92, 0.85), true), "cluck", 0.8)
	coq.speed = 0.7
	var thoughts := ["Qui de l'œuf ou de moi ? (Moi.)", "Je cot, donc je suis.", "Traverser la route ? Pour aller où ? Pour quoi faire ?", "Chaque graine est un choix de vie.", "Le vrai grain, c'est celui qu'on a en nous.", "J'ai pondu une idée. Elle est tombée.", "Le ver de terre aussi a ses rêves."]
	_hs(coq, Vector3(0, 1.1, 0), "Écouter Gérard le coq", func():
		var l: String = thoughts[randi() % thoughts.size()]
		coq.react("")
		_text(coq.global_position + Vector3(0, 1.4, 0), l, Color(1.0, 0.95, 0.75), 0.8, 4.0)
		, Callable(), 2.6)
	for k in 2:
		var h := _make("poule", Vector2(-9.0 + k * 4.5, -30.0 - k), 2.5, _paint_chicken.bind(Color(0.96, 0.78, 0.55) if k == 0 else Color(1, 1, 1), false), "cluck", 1.1)
		h.speed = 0.6
		_hs(h, Vector3(0, 0.95, 0), "Écouter la poule", func():
			h.react("")
			_text(h.global_position + Vector3(0, 1.2, 0), thoughts[randi() % thoughts.size()], Color(1.0, 0.95, 0.75), 0.8, 4.0)
			, Callable(), 2.4)
	for k in 3:
		var c := _make("poussin", Vector2(-8.0 + k * 1.3, -29.0), 2.0, _paint_chick, "squeak", 1.5)
		c.follows = true
		c.speed = 0.8

	var pig := _make("cochon", Vector2(-11.0, 6.0), 4.0, _paint_pig, "oink", 1.0)
	pig.speed = 0.8
	pig.talk_color = Color(1.0, 0.8, 0.85)
	_hs(pig, Vector3(0, 1.1, 0), "Faire renifler Truffette", func():
		pig.react("")
		if not _cool("pig", 60.0):
			_text(pig.global_position + Vector3(0, 1.1, 0), "Zzz... elle a déjà fouillé. Reviens plus tard.", pig.talk_color, 0.8, 2.6)
			return
		Fx.puff(v.world, pig.global_position + Vector3(0, 0.2, -0.6), Color(0.55, 0.4, 0.28))
		var r := randf()
		_later(1.0, func():
			if r < 0.5:
				_text(pig.global_position + Vector3(0, 1.1, 0), "Elle a trouvé quelque chose !", pig.talk_color, 0.9, 2.0)
				_gain(2, pig.global_position + Vector3(0, 1.7, 0))
			elif r < 0.8:
				_text(pig.global_position + Vector3(0, 1.1, 0), "UNE BOTTE ! Avec un coquillage dedans.", pig.talk_color, 0.9, 3.0)
				_gain(1, pig.global_position + Vector3(0, 1.9, 0))
			else:
				_text(pig.global_position + Vector3(0, 1.1, 0), "Une truffe ! ... Elle l'a mangée.", pig.talk_color, 0.9, 3.0)
		)
		, Callable(), 2.8)

	var snail := _make("escargot", Vector2(6.0, 11.0), 1.2, _paint_snail)
	snail.speed = 0.07
	snail.talk_color = Color(1.0, 0.9, 0.7)
	_hs(snail, Vector3(0, 0.6, 0), "Encourager Turbo", func():
		snail.react("")
		_text(snail.global_position + Vector3(0, 0.7, 0), ["...jé...suis...rapi...de...", "...att...ends...moi...", "...c'est...pas...une...course..."][randi() % 3], snail.talk_color, 0.7, 5.0)
		, Callable(), 2.2)

	for fx in [-13.0, 13.0]:
		var fp := Vector2(fx, Island.creek_z(fx) - 3.6)
		var f := _make("grenouille", fp, 2.5, _paint_frog, "croak", 1.5)
		f.hopper = true
		f.flee = 2.8
		f.speed = 1.2
		f.min_h = 0.3
		f.talk_color = Color(0.7, 1.0, 0.6)
		_hs(f, Vector3(0, 0.6, 0), "Embrasser la grenouille", func():
			f.react("")
			Fx.puff(v.world, f.global_position + Vector3(0, 0.3, 0), Color(1.0, 0.7, 0.9))
			var n := _count("frog")
			var l := ["...rien. Elle est juste très gênée.", "Elle est devenue... encore plus grenouille.", "Elle te demande de ne le dire à personne.", "Ce n'était pas un prince. C'était Bernard."]
			_text(f.global_position + Vector3(0, 0.8, 0), l[n % l.size()], f.talk_color, 0.8, 3.0)
			, Callable(), 2.2)

	_gull = _make("mouette", Vector2(10.0, 42.0), 1.0, _paint_gull, "bird", 1.0)
	_gull.min_h = 0.3
	_gull.speed = 0.5
	_gull.talk_color = Color(0.95, 0.95, 1.0)
	_hs(_gull, Vector3(0, 0.95, 0), "Parler à la mouette", _gull_steals, func(): return _gull._flying <= 0.0, 2.6)

	_cat = _make("chat", Vector2(-3.8, -7.8), 0.5, _paint_cat, "meow", 1.0)
	_cat.sleeping = true
	_cat.talk_color = Color(1.0, 0.85, 0.6)
	_hs(_cat, Vector3(0, 0.85, 0), "Gratter Sir Miaoulot", func():
		var wake_lines := ["Mrrrr... (il fait semblant de dormir)", "Ronron niveau 9000.", "Il te regarde. Il juge.", "Il a daigné lever une oreille."]
		_cat.react(wake_lines[randi() % wake_lines.size()])
		_cat.sleeping = false
		_cat_wake = 7.0
		, Callable(), 2.4)


func _gull_steals() -> void:
	var g := _gull
	g.cry(0.0)
	if Save.shells < 1:
		_text(g.global_position + Vector3(0, 1.0, 0), "Tu n'as rien à voler. Elle te plaint.", g.talk_color, 0.8, 2.6)
		return
	Save.shells -= 1
	Save.save_game()
	_text(g.global_position + Vector3(0, 1.0, 0), "VOLÉ !  (-1 coquillage)", Color(1.0, 0.5, 0.4), 1.0, 2.2)
	var spots := [Vector3(10, 0, 42), Vector3(-12, 0, 43), Vector3(14, 0, 37), Vector3(-5, 0, 47), Vector3(2, 0, 49)]
	var dest: Vector3 = spots[randi() % spots.size()]
	g.fly_to(Vector3(dest.x, Island.height(dest.x, dest.z), dest.z), 1.8)
	_later(6.0, func():
		_text(_pp() + Vector3(0, 1.8, 0), "La mouette rapporte des intérêts !", g.talk_color, 0.9, 2.5)
		_gain(2, _pp() + Vector3(0, 2.3, 0)))


# --- Personnages rigolos --------------------------------------------------------------------

func _folk(id: String, def: Dictionary, pos: Vector2, yaw: float, lines: Array, ask: String, extra := 0.0) -> Talker:
	var t := Talker.new()
	t.name = id
	v.add_child(t)
	t.position = Vector3(pos.x, Island.height(pos.x, pos.y) + extra + 0.02, pos.y)
	t.setup(v, v.player, def)
	t.rest_yaw = yaw
	folk.append(t)
	_hs(t, Vector3(0, 2.05, 0), ask, func():
		var n := _count("folk_" + id)
		t.chibi.say(lines[(n - 1) % lines.size()], 5.0)
		, Callable(), 3.0)
	return t


func _folks() -> void:
	_folk("brigitte", Characters.BRIGITTE, Vector2(-6.0, -24.0), 0.6, [
		"Je fais du tai-chi depuis 1974. Je n'ai toujours pas battu mon ombre.",
		"À mon âge, on ne court plus : on ESQUIVE.",
		"Les jeunes disent « ninja ». Moi je dis « mamie qui sait où sont les clés ».",
		"Une fois, j'ai arrêté une flèche avec mon tricot. Il y avait des mailles.",
		"Le secret ? Respirer, sourire, et cacher des biscuits partout.",
	], "Parler à Brigitte")
	_folk("moustache", Characters.MOUSTACHE, Vector2(-5.0, 34.0), PI, [
		"Capitaine Moustache. J'ai perdu mon bateau. Il était juste là. Enfin... il était LÀ-BAS.",
		"Mon bateau était grand, bleu et mouillé. Si vous voyez un truc sec, c'est pas lui.",
		"On m'a dit qu'il avait coulé. Je réponds qu'il a juste pris de la profondeur.",
		"Ma moustache a plus d'expérience que moi. Elle a déjà vu trois tempêtes.",
		"Ah ! Vous avez vu mon bateau ? Non ? Dommage. Moi non plus.",
	], "Parler au Capitaine")

	# Le Marchand de Rien
	var vp := Vector2(-6.0, 15.0)
	var vy := Island.height(vp.x, vp.y)
	var kb := Builder.new()
	kb.box(Vector3(1.6, 0.9, 0.6), Vector3(0, 0.45, 0.8), Color(0.72, 0.5, 0.3), true)
	kb.box(Vector3(1.8, 0.08, 0.8), Vector3(0, 0.94, 0.8), Color(0.85, 0.65, 0.4), false)
	kb.box(Vector3(0.08, 2.1, 0.08), Vector3(-0.85, 1.05, 0.5), Color(0.5, 0.35, 0.22), false)
	kb.box(Vector3(0.08, 2.1, 0.08), Vector3(0.85, 1.05, 0.5), Color(0.5, 0.35, 0.22), false)
	kb.prism(Vector3(2.1, 0.5, 1.2), Vector3(0, 2.3, 0.7), Color(0.45, 0.7, 0.85))
	var kn := Node3D.new()
	kn.name = "MarchandDeRien"
	v.add_child(kn)
	kn.position = Vector3(vp.x, vy, vp.y)
	kb.build(kn, Toon.vertex_color(0.01), "Kiosque")
	VB.label(kn, "RIEN\nvendu ici", Vector3(0, 1.55, 1.13), 0.004, Color(1.0, 0.95, 0.8), 48)
	var rien := _folk("rien", Characters.RIEN, vp, PI, [
		"Bienvenue ! Aujourd'hui, le rien est en promotion. Comme hier. Et demain.",
		"Mon rien est bio, local et sans emballage. Enfin, sans rien du tout.",
		"Je ne vends pas du vide. Je vends de la POSSIBILITÉ.",
	], "Parler au Marchand")
	rien.position += Vector3(0, 0, 0.0)
	_hs(kn, Vector3(0, 1.45, 0.4), "Acheter du rien (1 coquillage)", _buy_nothing, func(): return Save.shells >= 1, 3.0)

	# Édouard, la statue vivante (il ne bouge que quand on ne le regarde pas)
	var pp := Vector2(5.0, -24.0)
	var py := Island.height(pp.x, pp.y)
	var pb := Builder.new()
	pb.box(Vector3(1.0, 0.7, 1.0), Vector3(0, 0.35, 0), Color(0.78, 0.76, 0.8), true)
	pb.box(Vector3(1.2, 0.1, 1.2), Vector3(0, 0.72, 0), Color(0.85, 0.83, 0.86), false)
	var pn := Node3D.new()
	pn.name = "SocleEdouard"
	v.add_child(pn)
	pn.position = Vector3(pp.x, py, pp.y)
	pb.build(pn, Toon.vertex_color(0.01), "Socle")
	VB.label(pn, "ÉDOUARD\n« Ne pas bouger »", Vector3(0, 0.38, 0.52), 0.003, Color(0.2, 0.18, 0.22), 40)
	_statue = _folk("edouard", Characters.EDOUARD, pp, 0.0, [], "Chatouiller le nez d'Édouard", 0.78)
	_statue.moving = true
	_statue.chibi.rotation.y = 0.0
	# le hotspot de _folk est remplacé par un comportement particulier
	v.x.hot.pop_back()
	_hs(_statue, Vector3(0, 2.05, 0), "Chatouiller le nez d'Édouard", _tickle_statue, Callable(), 3.0)


func _buy_nothing() -> void:
	Save.shells -= 1
	var n: int = Save.story.get("rien_n", 0) + 1
	Save.story["rien_n"] = n
	Bells.play(v.world, "coin", 0.0, _pp() + Vector3(0, 1.2, 0), -6.0)
	var at := _pp() + Vector3(0, 2.0, 0)
	var lines := {
		1: "Voici : RIEN. Il est tout neuf.",
		2: "Rien, exemplaire n°2. Ta collection avance.",
		3: "Tu possèdes 3 riens. Ça commence à faire quelque chose. Enfin non.",
		4: "Un 4e rien ! Attention, tu vas finir par avoir presque rien.",
	}
	if n == 5 and not Save.story.get("rien_gift", false):
		Save.story["rien_gift"] = true
		_text(at, "Tu es mon meilleur client ! Voici un vrai cadeau.", Color(1.0, 0.95, 0.7), 0.9, 3.0)
		_later(1.2, func(): _gain(12, at + Vector3(0, 0.6, 0)))
	elif lines.has(n):
		_text(at, lines[n], Color(1.0, 0.95, 0.7), 0.9, 3.0)
	else:
		_text(at, ["Encore du rien. Toujours aussi neuf.", "Rien de neuf. C'est le but.", "Merci ! Reviens quand tu n'auras plus rien."][n % 3], Color(1.0, 0.95, 0.7), 0.9, 3.0)
	Save.save_game()


func _tickle_statue() -> void:
	var n := _count("tickle")
	var s := _statue
	if n % 5 == 0:
		s.chibi.say("A... A... ATCHOUM !", 2.5)
		Fx.puff(v.world, s.global_position + Vector3(0, 1.6, 0), Color(1, 1, 1))
		Bells.play(v.world, "squeak", 0.0, s.global_position + Vector3(0, 1.5, 0), 0.0).pitch_scale = 0.6
		s.chibi.pop()
		if _cool("statue", 90.0):
			_later(0.8, func(): _gain(2, s.global_position + Vector3(0, 2.3, 0)))
	else:
		s.chibi.say(["(Édouard ne bouge pas. Une larme coule.)", "(Édouard retient son souffle. Il devient un peu rouge.)", "(Édouard tient bon. Il est fier de lui.)", "(Il louche. Mais très légèrement.)"][n % 4], 3.5)


# --- Objets à manipuler --------------------------------------------------------------------

func _mushrooms() -> void:
	for mp in [Vector2(14.0, -22.0), Vector2(17.0, -18.0), Vector2(11.0, -26.0)]:
		var y := Island.height(mp.x, mp.y)
		var n := Node3D.new()
		n.name = "Champignon"
		v.add_child(n)
		n.position = Vector3(mp.x, y, mp.y)
		var sb := Builder.new()
		sb.cylinder(0.28, 0.35, 0.8, Vector3(0, 0.4, 0), Color(0.97, 0.92, 0.82), Basis(), 10)
		sb.build(n, Toon.vertex_color(OL), "Pied")
		var cb := Builder.new()
		cb.sphere(1.0, Vector3(0, 0.8, 0), Color(0.92, 0.25, 0.3), Vector3(1.0, 0.5, 1.0), Basis(), 14)
		for k in 6:
			var a := k * TAU / 6.0 + 0.4
			cb.sphere(0.13, Vector3(cos(a) * 0.62, 1.17, sin(a) * 0.62), Color(1, 0.97, 0.9), Vector3(1, 0.5, 1), Basis(), 6)
		cb.sphere(0.15, Vector3(0, 1.3, 0), Color(1, 0.97, 0.9), Vector3(1, 0.4, 1), Basis(), 6)
		cb.collider(Vector3(1.7, 0.3, 1.7), Vector3(0, 1.15, 0))
		var cap := cb.build(n, Toon.vertex_color(OL), "Chapeau")
		_mush.append([n, n.position, y + 1.3, cap])


func _xylophone() -> void:
	var c := Vector2(-16.0, -28.0)
	var y := Island.height(c.x, c.y)
	var root := Node3D.new()
	root.name = "Xylophone"
	v.add_child(root)
	root.position = Vector3(c.x, y, c.y)
	var rb := Builder.new()
	rb.box(Vector3(5.6, 0.07, 0.07), Vector3(0, 0.05, -0.55), Color(0.55, 0.38, 0.25), false)
	rb.box(Vector3(5.6, 0.07, 0.07), Vector3(0, 0.05, 0.55), Color(0.55, 0.38, 0.25), false)
	rb.build(root, Toon.vertex_color(0.008), "Rails")
	VB.label(root, "♪ XYLOPHONE ♪\nmarche dessus !", Vector3(0, 1.0, -1.1), 0.004, Color(1.0, 0.9, 0.5), 48, PI)
	for i in 7:
		var bn := Node3D.new()
		bn.name = "Barre%d" % i
		root.add_child(bn)
		bn.position = Vector3((i - 3) * 0.78, 0.0, 0)
		var bb := Builder.new()
		var ln := 1.9 - i * 0.12
		bb.box(Vector3(0.62, 0.1, ln), Vector3(0, 0.13, 0), RAINBOW[i], false)
		bb.build(bn, Toon.vertex_color(0.008), "Barre")
		_bars.append([Vector3(c.x + (i - 3) * 0.78, y, c.y), bn, i, ln])
		_bar_state.append(false)


func _red_button() -> void:
	var p := Vector2(10.0, -14.0)
	var y := Island.height(p.x, p.y)
	var n := Node3D.new()
	n.name = "BoutonRouge"
	v.add_child(n)
	n.position = Vector3(p.x, y, p.y)
	var b := Builder.new()
	b.cylinder(0.3, 0.38, 0.9, Vector3(0, 0.45, 0), Color(0.55, 0.55, 0.62), Basis(), 12)
	b.cylinder(0.26, 0.26, 0.06, Vector3(0, 0.93, 0), Color(0.9, 0.85, 0.2), Basis(), 12)
	b.build(n, Toon.vertex_color(0.01), "Socle")
	var bb := Builder.new()
	bb.cylinder(0.2, 0.22, 0.16, Vector3(0, 1.04, 0), Color(0.95, 0.12, 0.15), Basis(), 12)
	var knob := bb.build(n, Toon.vertex_color(0.01), "Bouton")
	VB.label(n, "NE PAS\nAPPUYER", Vector3(0, 0.55, 0.42), 0.0035, Color(1.0, 0.9, 0.3), 48)
	var msgs := ["Rien ne s'est passé. Enfin... presque.", "Quelque part, une poule a éternué.", "Tu n'aurais pas dû. Mais c'est drôle.", "Le bouton a dit « aïe ».", "Un canard s'est senti observé.", "Le bouton est vexé. Il boude.", "Tu veux vraiment savoir ? Non.", "Encore ?! Bon d'accord...", "Plus qu'un... peut-être."]
	_hs(n, Vector3(0, 1.7, 0), "Appuyer sur le bouton", func():
		var k := _count("bouton")
		Bells.play(v.world, "boing", 0.0, n.global_position + Vector3(0, 1.0, 0), -2.0)
		var tw := knob.create_tween()
		tw.tween_property(knob, "position:y", -0.1, 0.07)
		tw.tween_property(knob, "position:y", 0.0, 0.2)
		for j in 3:
			_later(j * 0.1, func(): Fx.puff(v.world, n.global_position + Vector3(randf_range(-0.6, 0.6), 1.4, randf_range(-0.6, 0.6)), RAINBOW[randi() % 7]))
		_ripple(n.global_position, 14.0, "?!")
		if k >= 10:
			_counters["bouton"] = 0
			_text(n.global_position + Vector3(0, 2.4, 0), "BOUM ! Confettis ! Récompense de persévérance (ou de bêtise).", Color(1.0, 0.9, 0.4), 1.0, 3.5)
			Bells.play(v.world, "sparkle", 0.0, n.global_position + Vector3(0, 1.5, 0), 0.0)
			for j in 8:
				_later(0.15 * j, func(): Fx.puff(v.world, n.global_position + Vector3(randf_range(-2, 2), randf_range(1.0, 3.0), randf_range(-2, 2)), RAINBOW[j % 7]))
			if not Save.story.get("bouton_ok", false):
				Save.story["bouton_ok"] = true
				_later(1.0, func(): _gain(6, n.global_position + Vector3(0, 3.0, 0)))
		else:
			_text(n.global_position + Vector3(0, 2.0, 0), msgs[(k - 1) % msgs.size()], Color(1.0, 0.95, 0.7), 0.85, 3.0)
		, Callable(), 2.6)


func _bell_post() -> void:
	var p := Vector2(-4.0, -35.5)
	var y := Island.height(p.x, p.y)
	var n := Node3D.new()
	n.name = "CloucheDuBerger"
	v.add_child(n)
	n.position = Vector3(p.x, y, p.y)
	var b := Builder.new()
	b.box(Vector3(0.14, 2.2, 0.14), Vector3(-0.5, 1.1, 0), Color(0.55, 0.38, 0.25), false)
	b.box(Vector3(0.14, 2.2, 0.14), Vector3(0.5, 1.1, 0), Color(0.55, 0.38, 0.25), false)
	b.box(Vector3(1.2, 0.12, 0.14), Vector3(0, 2.2, 0), Color(0.6, 0.42, 0.28), false)
	b.build(n, Toon.vertex_color(0.01), "Portique")
	var bb := Builder.new()
	bb.cylinder(0.08, 0.3, 0.45, Vector3(0, 0, 0), Color(1.0, 0.82, 0.25), Basis(), 12)
	bb.sphere(0.08, Vector3(0, -0.25, 0), Color(0.7, 0.5, 0.15), Vector3.ONE, Basis(), 8)
	var bell := Node3D.new()
	bell.position = Vector3(0, 1.9, 0)
	n.add_child(bell)
	bb.build(bell, Toon.vertex_color(0.01), "Cloche")
	_hs(n, Vector3(0, 1.1, 0.5), "Sonner la cloche", func():
		Bells.play(v.world, "bell", 392.0, n.global_position + Vector3(0, 2.0, 0), 2.0)
		_text(n.global_position + Vector3(0, 2.8, 0), "DING DONG !", Color(1.0, 0.85, 0.3), 1.2, 1.8)
		var tw := bell.create_tween()
		tw.tween_property(bell, "rotation:z", 0.5, 0.1)
		tw.tween_property(bell, "rotation:z", -0.4, 0.2)
		tw.tween_property(bell, "rotation:z", 0.2, 0.2)
		tw.tween_property(bell, "rotation:z", 0.0, 0.2)
		_ripple(n.global_position, 40.0, "!!")
		, Callable(), 2.8)


func _well() -> void:
	var p := Vector2(-9.0, -3.0)
	var y := Island.height(p.x, p.y)
	var n := Node3D.new()
	n.name = "PuitsAVoeux"
	v.add_child(n)
	n.position = Vector3(p.x, y, p.y)
	var b := Builder.new()
	b.cylinder(0.75, 0.8, 0.8, Vector3(0, 0.4, 0), Color(0.72, 0.7, 0.75), Basis(), 14)
	b.cylinder(0.6, 0.6, 0.04, Vector3(0, 0.78, 0), Color(0.25, 0.5, 0.9), Basis(), 14)
	b.box(Vector3(0.1, 1.6, 0.1), Vector3(-0.75, 1.6, 0), Color(0.55, 0.38, 0.25), false)
	b.box(Vector3(0.1, 1.6, 0.1), Vector3(0.75, 1.6, 0), Color(0.55, 0.38, 0.25), false)
	b.prism(Vector3(2.0, 0.7, 1.4), Vector3(0, 2.7, 0), Color(0.85, 0.35, 0.4))
	b.build(n, Toon.vertex_color(0.01), "Puits")
	VB.label(n, "PUITS À VŒUX\n(1 coquillage)", Vector3(0, 0.45, 0.83), 0.003, Color(0.15, 0.12, 0.2), 40)
	_hs(n, Vector3(0, 1.6, 0.9), "Faire un vœu (1 coquillage)", func():
		Save.shells -= 1
		Bells.play(v.world, "drip", 0.0, n.global_position + Vector3(0, 0.8, 0), -2.0)
		var at := n.global_position + Vector3(0, 2.0, 0)
		var r := randi() % 6
		_later(0.9, func():
			match r:
				0:
					_text(at, "Vœu exaucé ! Le puits te rend la monnaie.", Color(1.0, 0.9, 0.5), 0.9, 2.5)
					_gain(3, at + Vector3(0, 0.6, 0))
				1:
					_text(at, "Tu te sens léger... TRÈS léger.", Color(0.7, 0.9, 1.0), 0.9, 2.2)
					v.player.apply_effect("helium")
				2:
					_text(at, "Le puits t'a donné des jambes de lapin !", Color(1.0, 0.6, 0.4), 0.9, 2.2)
					v.player.apply_effect("speed")
				3:
					_text(at, "Vœu exaucé : tu as ENFIN la grosse tête.", Color(1.0, 0.7, 0.9), 0.9, 2.4)
					v.player.apply_effect("big_head")
				4:
					_text(at, "Le puits répond : « Noté. »", Color(0.9, 0.9, 1.0), 0.9, 2.2)
				_:
					_text(at, "Écho : « ...coquillage... quillage... illage... »", Color(0.9, 0.9, 1.0), 0.9, 3.0)
		)
		, func(): return Save.shells >= 1, 3.0)


func _mailbox() -> void:
	var p := Vector2(3.6, -7.4)
	var y := Island.height(p.x, p.y)
	var n := Node3D.new()
	n.name = "BoiteAuxLettres"
	v.add_child(n)
	n.position = Vector3(p.x, y, p.y)
	var b := Builder.new()
	b.box(Vector3(0.1, 1.0, 0.1), Vector3(0, 0.5, 0), Color(0.5, 0.35, 0.22), false)
	b.box(Vector3(0.5, 0.35, 0.8), Vector3(0, 1.15, 0), Color(0.3, 0.55, 0.9), false)
	b.sphere(0.25, Vector3(0, 1.32, 0), Color(0.3, 0.55, 0.9), Vector3(1.0, 0.6, 1.6), Basis(), 10)
	b.box(Vector3(0.04, 0.3, 0.04), Vector3(0.3, 1.3, 0.1), Color(0.95, 0.3, 0.3), false)
	b.box(Vector3(0.14, 0.04, 0.02), Vector3(0, 1.15, 0.41), Color(1, 1, 1), false)
	b.build(n, Toon.vertex_color(0.01), "Boite")
	var mail := ["Une lettre pour toi ! Elle dit : « Bravo, tu as ouvert la boîte. »", "Facture : 3 000 coquillages pour avoir oublié de te plaindre.", "Une carte postale de nulle part : « Il fait beau, ici. »", "Un seul mot : « Derrière toi ». (Il n'y a rien derrière toi.)", "Publicité : « Achetez du rien ! » Ça te rappelle quelqu'un.", "La boîte te répond en chuchotant : « Mon facteur me manque. »", "Une plume. Une seule. Aucune explication."]
	_hs(n, Vector3(0, 1.9, 0.3), "Ouvrir la boîte aux lettres", func():
		_text(n.global_position + Vector3(0, 2.2, 0), mail[randi() % mail.size()], Color(1.0, 0.95, 0.75), 0.8, 4.0)
		Bells.play(v.world, "click", 0.0, n.global_position + Vector3(0, 1.2, 0), -2.0)
		, Callable(), 2.6)


## Tous les animaux alentour sursautent
func _ripple(pos: Vector3, radius: float, text: String) -> void:
	for a in animals:
		var d: float = a.global_position.distance_to(pos)
		if d < radius and a != _cat:
			_later(randf() * 0.5 + d * 0.01, a.react.bind(text if randf() < 0.3 else ""))


# --- À chaque image -------------------------------------------------------------------------

func update(delta: float) -> void:
	if v.player == null:
		return
	var pp := _pp()
	if pp.y > 60.0:
		return
	_bounce_cd -= delta
	# Champignons trampolines
	if _bounce_cd <= 0.0 and v.player.is_on_floor():
		for m in _mush:
			var mp: Vector3 = m[1]
			if Vector2(pp.x - mp.x, pp.z - mp.z).length() < 1.1 and absf(pp.y - float(m[2])) < 0.35:
				v.player._vy = 9.6
				_bounce_cd = 0.3
				Bells.play(v.world, "boing", 0.0, mp + Vector3(0, 1.2, 0), 0.0).pitch_scale = randf_range(0.9, 1.25)
				var cap: Node3D = m[3]
				var tw := cap.create_tween()
				tw.tween_property(cap, "scale", Vector3(1.12, 0.55, 1.12), 0.07)
				tw.tween_property(cap, "scale", Vector3(0.94, 1.15, 0.94), 0.12)
				tw.tween_property(cap, "scale", Vector3.ONE, 0.15)
				_text(mp + Vector3(0, 2.2, 0), "BOING !", Color(1.0, 0.6, 0.6), 0.9, 1.0)
				break
	# Xylophone : chaque barre sonne quand on marche dessus
	for i in _bars.size():
		var bc: Vector3 = _bars[i][0]
		var ln: float = _bars[i][3]
		var on: bool = absf(pp.x - bc.x) < 0.38 and absf(pp.z - bc.z) < ln * 0.5 and pp.y < bc.y + 0.5
		if on and not _bar_state[i]:
			var bn: Node3D = _bars[i][1]
			Bells.play(v.world, "marimba", NOTES[i], bc + Vector3(0, 0.3, 0), 0.0)
			_text(bc + Vector3(0, 0.9, 0), "♪", RAINBOW[i], 1.0, 0.9)
			var tw := bn.create_tween()
			tw.tween_property(bn, "position:y", -0.06, 0.05)
			tw.tween_property(bn, "position:y", 0.0, 0.12)
		_bar_state[i] = on
	# La mouette s'envole quand on s'approche
	if _gull and _gull._flying <= 0.0:
		var gd := Vector2(pp.x - _gull.global_position.x, pp.z - _gull.global_position.z).length()
		if gd < 4.5:
			_gull.cry(0.0)
			var spots := [Vector3(10, 0, 42), Vector3(-12, 0, 43), Vector3(14, 0, 37), Vector3(-5, 0, 47), Vector3(2, 0, 49)]
			for k in 6:
				var dest: Vector3 = spots[randi() % spots.size()]
				if Vector2(dest.x - pp.x, dest.z - pp.z).length() > 9.0:
					_gull.fly_to(Vector3(dest.x, Island.height(dest.x, dest.z), dest.z), 1.5)
					break
	# Le chat se rendort
	if _cat and not _cat.sleeping:
		_cat_wake -= delta
		if _cat_wake <= 0.0:
			_cat.sleeping = true
	# Édouard ne bouge que quand on ne le regarde pas
	if _statue:
		var cam: Camera3D = v.player.camera
		var to := _statue.global_position + Vector3(0, 1.0, 0) - cam.global_position
		var watched := to.length() < 30.0 and (-cam.global_basis.z).dot(to.normalized()) > 0.55
		if watched:
			_statue_t = 0.0
		else:
			_statue_t += delta
			if _statue_t > _statue_next:
				_statue_t = 0.0
				_statue_next = randf_range(1.0, 2.5)
				_statue.chibi.rotation.y = randf_range(-PI, PI)
