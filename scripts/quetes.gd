extends RefCounted
## v37 : deux petites quêtes d'habitants sur l'île principale, et l'épilogue qui change selon la fin
## choisie dans le Grand Registre (Basile et Lina reviennent sur la place du village).
##  - « La lettre jamais envoyée » : une lettre vieille de 40 ans au fond de la boîte aux lettres.
##  - « Le jardinier invisible » : qui arrose ce jardin abandonné ?
## Les deux comptent comme « petites histoires » pour la troisième fin.

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Island := preload("res://scripts/island.gd")
const Fx := preload("res://scripts/fx.gd")
const Save := preload("res://scripts/save.gd")
const Bells := preload("res://scripts/bells.gd")
const Talker := preload("res://scripts/talker.gd")
const Characters := preload("res://scripts/characters.gd")
const VB := preload("res://scripts/village_build.gd")

const MAILBOX := Vector2(3.6, -7.4)
const GARDEN := Vector2(10.5, -24.0)

var v
var _epi: Array = []
var _garden: Node3D
var _wait_on := false


func build() -> void:
	_letter()
	_garden_build()
	_place_lovers()
	epilogue()


func _s(k: String) -> bool:
	return Save.story.get(k, false)


func _later(t: float, c: Callable) -> void:
	v.get_tree().create_timer(t).timeout.connect(c)


func _text(pos: Vector3, txt: String, col := Color(1.0, 0.95, 0.75), size := 0.8, life := 4.0) -> void:
	Fx.text(v.world, pos, txt, col, size, life)


func _gain(n: int, pos: Vector3) -> void:
	Save.shells += n
	Save.save_game()
	_text(pos, "+%d coquillages" % n, Color(1.0, 0.85, 0.3), 1.0, 2.5)


func _folk_named(id: String) -> Talker:
	for t in v.fr.folk:
		if t.name == id:
			return t
	return null


# --- La lettre jamais envoyée -------------------------------------------------------------------

func _letter() -> void:
	var at := Vector3(MAILBOX.x, Island.height(MAILBOX.x, MAILBOX.y), MAILBOX.y)
	var mb: Node3D = v.get_node_or_null("BoiteAuxLettres")
	if mb == null:
		return
	v.x.hotspot(mb, Vector3(0, 1.5, 0.3), "Fouiller le fond de la boîte", func():
		Save.story["lettre_found"] = true
		Save.save_game()
		Bells.play(v.world, "pickup", 0.0, at + Vector3(0, 1.2, 0), -2.0)
		_text(at + Vector3(0, 2.4, 0), "Une enveloppe jaunie, au fond : « Pour Brigitte. En main propre. — Capt. M. »  Elle a quarante ans.", Color(1.0, 0.95, 0.7), 0.75, 6.0)
		v._pico("Une lettre jamais envoyée. Quarante ans de retard. Pour une fois, ce n'est pas moi qui me trompe de jour."), func(): return not _s("lettre_found"), 2.4)
	var br := _folk_named("brigitte")
	if br:
		v.x.hotspot(br, Vector3(0, 2.6, 0), "Lui remettre la lettre", _deliver, func(): return _s("lettre_found") and not _s("lettre_ok"), 2.0, 3.2)


func _deliver() -> void:
	var br := _folk_named("brigitte")
	var cap := _folk_named("moustache")
	if br == null or cap == null:
		return
	br.chibi.say("Une lettre ? Pour moi ? ... Capt. M. ... CAPITAINE MOUSTACHE ?!", 5.0)
	_later(5.5, func(): br.chibi.say("Quarante ans ! Il m'écrivait ! Je croyais qu'il m'avait oubliée pour un bateau !", 5.0))
	_later(11.0, func():
		cap.global_position = br.global_position + Vector3(1.8, 0.0, 0.4)
		Fx.puff(v.world, cap.global_position + Vector3(0, 1.0, 0), Color(1, 1, 1))
		cap.chibi.say("Brigitte ?! Mon bateau, c'était vous ! Enfin... vous étiez sur le quai. Il était à côté.", 6.0))
	_later(17.5, func():
		br.chibi.say("Capitaine. Vous avez encore votre moustache.", 4.0)
		Save.story["lettre_ok"] = true
		Save.save_game()
		_gain(15, br.global_position + Vector3(0, 2.8, 0))
		_text(br.global_position + Vector3(0, 3.4, 0), "La lettre jamais envoyée : terminée", Color(0.8, 1.0, 0.8), 0.9, 4.0)
		v._pico("Ils sont côte à côte. Moi, je prends des notes. Elles disent : « bien »."))


func _place_lovers() -> void:
	if not _s("lettre_ok"):
		return
	var br := _folk_named("brigitte")
	var cap := _folk_named("moustache")
	if br and cap:
		cap.global_position = br.global_position + Vector3(1.8, 0.0, 0.4)


# --- Le jardinier invisible -----------------------------------------------------------------------

func _garden_build() -> void:
	var y := Island.height(GARDEN.x, GARDEN.y)
	_garden = Node3D.new()
	_garden.name = "JardinAbandonne"
	v.add_child(_garden)
	_garden.position = Vector3(GARDEN.x, y, GARDEN.y)
	var b := Builder.new()
	b.box(Vector3(4.0, 0.12, 3.0), Vector3(0, 0.06, 0), Color(0.42, 0.3, 0.2), false)
	for sx in [-2.0, 2.0]:
		b.box(Vector3(0.08, 0.5, 3.0), Vector3(sx, 0.25, 0), Color(0.6, 0.45, 0.3), true)
	for sz in [-1.5, 1.5]:
		b.box(Vector3(4.0, 0.5, 0.08), Vector3(0, 0.25, sz), Color(0.6, 0.45, 0.3), true)
	# trois fleurs sèches
	for k in 3:
		b.box(Vector3(0.04, 0.4, 0.04), Vector3(-1.2 + k * 1.2, 0.3, 0), Color(0.5, 0.45, 0.25), false)
	b.build(_garden, Toon.vertex_color(0.01), "Parterre")
	VB.label(_garden, "JARDIN\n« Ne pas arroser »", Vector3(0, 0.9, 1.58), 0.004, Color(0.2, 0.15, 0.1), 48)
	# empreintes rondes (un socle)
	if _s("jardin_ok"):
		_bloom()
	v.x.hotspot(_garden, Vector3(0, 1.4, 1.2), "Examiner la terre", func():
		Save.story["jardin_clue"] = true
		Save.save_game()
		_text(_garden.global_position + Vector3(0, 2.0, 0), "La terre est mouillée. Des traces carrées, comme un socle. Et un fil de peinture grise.", Color(1.0, 0.95, 0.7), 0.75, 5.0)
		v._pico("Quelqu'un arrose ici, et pas avec des chaussures. Je ne dis pas un nom. Je pense à une statue."), func(): return not _s("jardin_ok"), 2.8)
	v.x.hotspot(_garden, Vector3(0, 1.7, 1.2), "Tourner le dos et compter jusqu'à dix", _wait_back, func(): return _s("jardin_clue") and not _s("jardin_ok") and not _wait_on, 3.2, 3.2)


func _wait_back() -> void:
	_wait_on = true
	var p = v.player
	var to: Vector3 = _garden.global_position - p.global_position
	p._face_yaw(atan2(to.x, to.z) + PI)
	for k in 10:
		var n := k + 1
		_later(float(n), func(): _text(p.global_position + Vector3(0, 2.2, 0), str(n) + "...", Color(1.0, 0.95, 0.8), 0.8, 0.9))
	_later(10.5, _reveal)


func _reveal() -> void:
	_wait_on = false
	var st: Talker = v.fr._statue
	if st == null:
		return
	var gp := _garden.global_position
	st.global_position = gp + Vector3(0, 0.0, 0.0)
	st.global_position.y = gp.y + 0.2
	Fx.puff(v.world, gp + Vector3(0, 1.0, 0), Color(0.6, 0.8, 1.0))
	Bells.play(v.world, "splash", 0.0, gp + Vector3(0, 0.5, 0), -2.0)
	st.chibi.say("... Je peux tout expliquer. Je ne bougeais pas. Je ME DÉPLAÇAIS.", 5.0)
	_later(5.5, func():
		st.chibi.say("Ces fleurs étaient tristes. Quand personne ne regarde, j'arrose. Je suis un jardinier... à temps partiel.", 6.0))
	_later(12.0, func():
		Save.story["jardin_ok"] = true
		Save.save_game()
		_bloom()
		_gain(12, gp + Vector3(0, 2.8, 0))
		_text(gp + Vector3(0, 3.4, 0), "Le jardinier invisible : terminé", Color(0.8, 1.0, 0.8), 0.9, 4.0)
		v._pico("Le jardinier invisible est une statue. Je ne vais pas dire que j'avais deviné. Je vais dire que j'avais des soupçons carrés."))


func _bloom() -> void:
	var b := Builder.new()
	var cols := [Color(1.0, 0.4, 0.55), Color(1.0, 0.85, 0.3), Color(0.6, 0.5, 1.0), Color(1.0, 0.6, 0.3)]
	for k in 12:
		var x := -1.7 + (k % 4) * 1.15
		var z := -1.0 + (k / 4) * 1.0
		b.cylinder(0.02, 0.02, 0.45, Vector3(x, 0.35, z), Color(0.3, 0.65, 0.3), Basis(), 5)
		b.sphere(0.13, Vector3(x, 0.62, z), cols[k % 4], Vector3.ONE, Basis(), 6)
	b.build(_garden, Toon.vertex_color(0.01), "Fleurs")


# --- Épilogue : après la fin choisie dans le Registre -------------------------------------------------

func epilogue() -> void:
	for n in _epi:
		if is_instance_valid(n):
			v.x.hot = v.x.hot.filter(func(h): return not n.is_ancestor_of(h["btn"]))
			n.queue_free()
	_epi.clear()
	if not _s("ch7_done"):
		return
	var kind := String(Save.story.get("ending", ""))
	var sq := Vector2(0.0, -49.5)
	match kind:
		"conserver":
			_npc("basile", Characters.BASILE_PLUME, sq + Vector2(5.5, 3.5), -0.8, [
				"Rien ne change. Je venais respirer l'air de l'île, mais il ne bouge pas non plus.",
				"Lina est en sécurité. Elle dit la même phrase. Je l'écoute encore. Je suis le seul à écouter.",
				"Merci. Je le répète, parce que tout se répète.",
			], "Parler à Basile")
		"liberer":
			_npc("basile", Characters.BASILE_PLUME, sq + Vector2(5.5, 3.5), -0.8, [
				"Je viens m'asseoir ici, le matin. Le phare regarde un peu ailleurs. Elle a dû le décider.",
				"On oublie moins que je le craignais. On oublie plus que je le voulais. C'est peut-être ça, être libre.",
				"Je lui parle encore. Elle ne répond plus. Mais je recommence à entendre les mouettes.",
			], "Parler à Basile")
		"continuer":
			_npc("basile", Characters.BASILE_PLUME, sq + Vector2(5.5, 3.5), -0.8, [
				"Les habitants ont voulu corriger mon calendrier. Je les ai laissés. Ça m'a coûté trois jours de sourire.",
				"Odile et Gaspard se disputent encore le pont. Mais ils s'asseyent dessus, maintenant. Ensemble.",
				"Je ne garde plus rien. Je regarde. C'est une autre façon de tenir à quelqu'un.",
			], "Parler à Basile")
			_npc("lina", Characters.LINA, sq + Vector2(7.2, 3.2), 0.8, [
				"J'ai dessiné un autre phare ! Il regarde les bateaux. Et il a des fenêtres... deux.",
				"Papa dit que je ne répète plus. Moi je dis que j'avais des choses à dire.",
				"Demain je dessine Pico. Il sera de profil. Il chante faux, mais il chante bien de profil.",
			], "Parler à Lina")


func _npc(id: String, def: Dictionary, pos: Vector2, yaw: float, lines: Array, ask: String) -> void:
	var t := Talker.new()
	t.name = "Epilogue_" + id
	v.add_child(t)
	t.position = Vector3(pos.x, Island.height(pos.x, pos.y) + 0.02, pos.y)
	t.setup(v, v.player, def)
	t.rest_yaw = yaw
	_epi.append(t)
	var k := [0]
	v.x.hotspot(t, Vector3(0, 2.05, 0), ask, func():
		t.chibi.say(lines[k[0] % lines.size()], 6.0)
		k[0] += 1, func(): return true, 2.0, 3.0)
