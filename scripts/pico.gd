extends Node3D
## Pico : petite créature en papier plié (un peu renard, un peu lapin).
## Il suit le joueur en sautillant, et commente. Courageux tant qu'il ne se
## passe rien, et toujours là pour donner le conseil... juste après.

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Save := preload("res://scripts/save.gd")
const Island := preload("res://scripts/island.gd")

const PAPER := Color(0.97, 0.95, 0.88)
const FOLD := Color(0.82, 0.84, 0.9)
const INK := Color(0.13, 0.08, 0.17)

var player
var active := false        # false tant qu'il est dans sa bouteille
var body: Node3D
var ear_l: Node3D
var ear_r: Node3D
var tail: Node3D
var bubble: Label3D
var _t := 0.0
var _talk_cd := 30.0
var _bubble_left := 0.0
var _hop := 0.0
var _recent: Array = []
var _was_in_dungeon := false
var _was_wet := false
var zone := ""            # où on est : inn, hall, shop, square, village, ou vide


func build(p_player) -> void:
	player = p_player
	body = Node3D.new()
	add_child(body)
	var b := Builder.new()
	# Corps : deux prismes de papier plié
	b.prism(Vector3(0.26, 0.2, 0.3), Vector3(0, 0.14, 0.02), PAPER, Basis(Vector3.RIGHT, PI / 2.0) * Basis(Vector3.FORWARD, PI))
	b.box(Vector3(0.2, 0.12, 0.26), Vector3(0, 0.1, 0.03), PAPER, false)
	b.box(Vector3(0.005, 0.12, 0.26), Vector3(0, 0.16, 0.03), FOLD, false)
	# Tête : un museau de renard en papier
	b.box(Vector3(0.22, 0.18, 0.18), Vector3(0, 0.3, -0.1), PAPER, false)
	b.prism(Vector3(0.22, 0.1, 0.12), Vector3(0, 0.25, -0.24), PAPER, Basis(Vector3.RIGHT, -PI / 2.0))
	b.sphere(0.018, Vector3(0, 0.27, -0.31), INK, Vector3.ONE, Basis(), 6)
	for sx in [-1.0, 1.0]:
		b.sphere(0.022, Vector3(sx * 0.055, 0.33, -0.19), INK, Vector3(0.8, 1.2, 0.4), Basis(), 6)
		b.sphere(0.008, Vector3(sx * 0.055 - 0.006, 0.34, -0.2), Color.WHITE, Vector3.ONE, Basis(), 4)
		b.sphere(0.02, Vector3(sx * 0.085, 0.29, -0.19), Color(1.0, 0.65, 0.65), Vector3(1, 0.6, 0.3), Basis(), 6)
		# Pattes
		b.box(Vector3(0.05, 0.06, 0.05), Vector3(sx * 0.07, 0.03, -0.06), PAPER, false)
		b.box(Vector3(0.05, 0.06, 0.05), Vector3(sx * 0.07, 0.03, 0.12), PAPER, false)
	# Petites lignes d'écriture sur le flanc (c'est du papier écrit !)
	for k in 4:
		b.box(Vector3(0.002, 0.006, 0.14 - k * 0.02), Vector3(0.101, 0.07 + k * 0.022, 0.04), Color(0.4, 0.4, 0.55), false)
		b.box(Vector3(0.002, 0.006, 0.14 - k * 0.02), Vector3(-0.101, 0.07 + k * 0.022, 0.04), Color(0.4, 0.4, 0.55), false)
	b.build(body, Toon.vertex_color(0.006), "PicoBody")
	ear_l = _ear(-1.0)
	ear_r = _ear(1.0)
	tail = Node3D.new()
	tail.position = Vector3(0, 0.16, 0.17)
	body.add_child(tail)
	var tb := Builder.new()
	tb.prism(Vector3(0.12, 0.26, 0.04), Vector3(0, 0.12, 0.04), PAPER, Basis(Vector3.RIGHT, 0.8))
	tb.prism(Vector3(0.06, 0.1, 0.042), Vector3(0, 0.22, 0.13), Color(1.0, 0.6, 0.3), Basis(Vector3.RIGHT, 0.8))
	tb.build(tail, Toon.vertex_color(0.006), "Tail")

	bubble = Label3D.new()
	bubble.position = Vector3(0, 0.75, 0)
	bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bubble.font_size = 56
	bubble.outline_size = 18
	bubble.modulate = Color(0.85, 0.92, 1.0)
	bubble.outline_modulate = INK
	bubble.pixel_size = 0.0022
	bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.width = 700.0
	bubble.visible = false
	add_child(bubble)


func _ear(sx: float) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(sx * 0.07, 0.38, -0.08)
	body.add_child(pivot)
	var b := Builder.new()
	b.prism(Vector3(0.08, 0.26, 0.03), Vector3(0, 0.13, 0), PAPER, Basis(Vector3.FORWARD, -sx * 0.15))
	b.prism(Vector3(0.04, 0.16, 0.032), Vector3(0, 0.11, -0.005), Color(1.0, 0.78, 0.8), Basis(Vector3.FORWARD, -sx * 0.15))
	b.build(pivot, Toon.vertex_color(0.005), "Ear")
	return pivot


func say(text: String, duration := 0.0) -> void:
	bubble.text = text
	bubble.visible = true
	_bubble_left = duration if duration > 0.0 else 2.5 + text.length() * 0.06
	_hop = 1.0
	_talk_cd = maxf(_talk_cd, 25.0)


## Sort de la bouteille !
func pop_out() -> void:
	active = true
	scale = Vector3.ONE * 0.05
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ONE * 1.15, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector3.ONE, 0.2)
	_hop = 1.5


func _pick(arr: Array) -> String:
	var fresh: Array = arr.filter(func(o): return not _recent.has(o))
	var c: String = fresh[randi() % fresh.size()] if fresh.size() > 0 else arr[randi() % arr.size()]
	_recent.append(c)
	if _recent.size() > 12:
		_recent.pop_front()
	return c


## Petite remarque selon l'endroit et la situation.
func _idle_line() -> String:
	if player.in_dungeon:
		return _pick(["Je surveille nos arrières. De très loin.", "Si un slime approche, je fais semblant d'être une serviette.", "Je suis courageux. Simplement, pas maintenant."])
	var p: Vector3 = player.global_position
	var zl := _zone_line()
	if zl != "":
		return zl
	if p.y < -0.1:
		return _pick(["Je ne sais pas nager. Enfin, je crois. Je n'ai jamais essayé.", "Le papier et l'eau, ce n'est pas une grande histoire d'amour."])
	if not Save.story.get("bridge", false):
		return _pick(["La route est par là. Enfin, elle était là.", "Ce pont a l'air cassé. Je dis ça, je dis rien.", "Des planches, un trou... Il y a peut-être un rapport."])
	var lines := [
		"Tu as remarqué ? Le château est toujours fermé. Comme tous les châteaux intéressants.",
		"Je me demande ce qu'ouvre cette petite clé.",
		"Si on me cherche, je suis très discret. Personne ne me voit jamais.",
		"Cette photo... tu es sûr de ne pas être déjà venu ici ?",
		"J'ai une théorie. Je ne la connais pas encore, mais elle est excellente.",
	]
	if Save.count("planche") > 0:
		lines.append("La planche est en sécurité. On ne sait jamais.")
	if player.char_id != 0:
		lines.append("Tu as une drôle de tête aujourd'hui. Je préfère ne pas commenter.")
	return _pick(lines)


## Remarques propres aux lieux de Port-Biscornu.
func _zone_line() -> String:
	match zone:
		"inn":
			return _pick(["Cette auberge a des oreilles. Surtout le comptoir.", "J'aime bien les auberges. On y dit des choses qu'on n'a pas dites.", "La porte 7 est plus sombre que les autres. Je la regarde sans la regarder.", "Il y a une photo au mur. Elle ressemble à celle de ta valise. Je dis ça en passant."])
		"hall":
			return _pick(["Trois guichets, personne derrière. C'est de l'efficacité, ça.", "L'horloge a une roue en moins. Ce n'est pas juste une horloge, je le sens.", "Si on me demande un formulaire, je ne suis pas là."])
		"shop":
			return _pick(["Je suis sûr qu'ils vendent aussi des choses utiles. Au fond. Tout au fond.", "Cette clé sans serrure me regarde. Je la regarde aussi."])
		"bakery":
			return _pick(["Vingt-sept pains. Je les ai comptés trois fois. Ils étaient vingt-sept à chaque fois.", "Un pain, ça ne ment pas. Mais ça peut cacher des choses."])
		"workshop":
			return _pick(["Tous ces engrenages... on dirait un puzzle pour géants.", "Fermé pour inventaire. Tu veux que je te dise ? Ils ont perdu l'inventaire."])
		"petro":
			return _pick(["Cette dame sait quelque chose. Elle le sait trop calmement.", "Un thé qui ne refroidit pas. Je n'aime pas ça. J'adore ça."])
		"ruin":
			return _pick(["Quelqu'un vit ici. Il y a trop de cartes pour une maison abandonnée.", "Chuchote. Je ne sais pas pourquoi, mais chuchote."])
		"square", "village":
			if Save.story.get("tuesday", false):
				return _pick(["Tout le monde dit « mercredi ». Personne ne dit « mardi ». Voilà ce qui est étrange.", "Les étals sont rangés. Un marché qui a eu lieu sans qu'on s'en souvienne, c'est un beau tour.", "On commence par qui ? Le boulanger ? Le pêcheur ? Malo ?"])
			return _pick(["Ce village a une drôle d'ambiance. Comme un jour de trop. Ou de moins.", "Regarde le phare. Il est énorme. Et fermé. Et énorme.", "J'ai l'impression que tout le monde sourit un peu trop tard."])
	return ""


func on_swap() -> void:
	if active:
		say(_pick(["Tu as changé de tête. Je préfère ne pas commenter.", "Ah. C'est toujours toi, là-dedans ?", "Je vais faire comme si c'était normal."]))


func _process(delta: float) -> void:
	_t += delta
	if not active or player == null:
		if body:
			body.rotation.z = sin(_t * 9.0) * 0.08
		return
	# Il suit le joueur, à sa droite, un peu en arrière
	var cam: Node3D = player.camera
	var right: Vector3 = cam.global_basis.x
	right.y = 0.0
	right = right.normalized() if right.length() > 0.01 else Vector3.RIGHT
	var back: Vector3 = cam.global_basis.z
	back.y = 0.0
	back = back.normalized() if back.length() > 0.01 else Vector3.BACK
	var target: Vector3 = player.global_position + right * 0.9 + back * 0.4
	if not player.in_dungeon:
		var gh := Island.height(target.x, target.z)
		target.y = maxf(gh, player.global_position.y - 0.5) if absf(gh - player.global_position.y) < 1.5 else player.global_position.y
	else:
		target.y = player.global_position.y
	var to := target - global_position
	if to.length() > 15.0 or player.in_dungeon != _was_in_dungeon:
		global_position = target
		_was_in_dungeon = player.in_dungeon
	else:
		var flat := Vector3(to.x, 0, to.z)
		var speed := clampf(flat.length() * 3.0, 0.0, 6.0)
		if flat.length() > 0.15:
			global_position += flat.normalized() * minf(speed * delta, flat.length())
			_hop = maxf(_hop, 0.6)
			rotation.y = lerp_angle(rotation.y, atan2(-flat.x, -flat.z), clampf(delta * 8.0, 0.0, 1.0))
		else:
			var tp: Vector3 = player.camera.global_position - global_position
			rotation.y = lerp_angle(rotation.y, atan2(-tp.x, -tp.z), clampf(delta * 4.0, 0.0, 1.0))
		global_position.y = lerpf(global_position.y, target.y, clampf(delta * 10.0, 0.0, 1.0))
	# Petits bonds, oreilles et queue qui bougent
	_hop = maxf(_hop - delta * 1.5, 0.0)
	body.position.y = absf(sin(_t * 11.0)) * 0.12 * minf(_hop, 1.0)
	ear_l.rotation.x = sin(_t * 3.0) * 0.15 - _hop * 0.3
	ear_r.rotation.x = sin(_t * 3.0 + 0.6) * 0.15 - _hop * 0.3
	tail.rotation.y = sin(_t * 5.0) * 0.4

	var wet: bool = player.global_position.y < -0.1
	if wet and not _was_wet:
		say("Hé ! Tu vas me mouiller ! Je suis en PAPIER !")
	_was_wet = wet

	if _bubble_left > 0.0:
		_bubble_left -= delta
		if _bubble_left <= 0.0:
			bubble.visible = false
	_talk_cd -= delta
	if _talk_cd <= 0.0:
		_talk_cd = randf_range(45.0, 80.0)
		say(_idle_line())
