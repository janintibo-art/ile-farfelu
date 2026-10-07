extends Node3D
## La pêche : lancer le bouchon dans l'eau, attendre la touche, ferrer au bon
## moment (gâchette ou coup sec vers le haut), et découvrir la prise.

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Island := preload("res://scripts/island.gd")
const Fx := preload("res://scripts/fx.gd")
const Save := preload("res://scripts/save.gd")
const Props := preload("res://scripts/props.gd")
const Inv := preload("res://scripts/inventory_items.gd")

const BITE_WINDOW := 1.3

var player
var shore
var state := "idle"      # idle / flying / waiting / bite
var tip := Vector3.ZERO  # bout de la canne (mis à jour par le joueur)
var bobber: Node3D
var line: MeshInstance3D
var _t := 0.0
var _wait := 0.0
var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _bite_label: Label3D


func setup(p_player, p_shore) -> void:
	player = p_player
	shore = p_shore
	bobber = Node3D.new()
	bobber.name = "Bobber"
	add_child(bobber)
	var b := Builder.new()
	b.sphere(0.07, Vector3(0, 0.035, 0), Color(1.0, 0.25, 0.25), Vector3(1, 1, 1), Basis(), 10)
	b.sphere(0.068, Vector3(0, -0.005, 0), Color.WHITE, Vector3(1.02, 0.55, 1.02), Basis(), 10)
	b.cylinder(0.008, 0.008, 0.1, Vector3(0, 0.12, 0), Color(1.0, 0.85, 0.2))
	b.build(bobber, Toon.vertex_color(0.006), "BobberMesh")
	bobber.visible = false
	line = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.004
	cm.bottom_radius = 0.004
	cm.height = 1.0
	cm.radial_segments = 4
	cm.rings = 1
	line.mesh = cm
	line.material_override = Toon.unlit(Color(0.95, 0.95, 1.0))
	line.visible = false
	add_child(line)
	_bite_label = Label3D.new()
	_bite_label.text = "!"
	_bite_label.font_size = 128
	_bite_label.outline_size = 32
	_bite_label.modulate = Color(1.0, 0.3, 0.3)
	_bite_label.outline_modulate = Color.WHITE
	_bite_label.pixel_size = 0.004
	_bite_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bite_label.no_depth_test = true
	_bite_label.visible = false
	add_child(_bite_label)


func busy() -> bool:
	return state != "idle"


## Gâchette (ou clic) avec la canne en main.
func action(from: Vector3, forward: Vector3) -> void:
	match state:
		"idle":
			_cast(from, forward)
		"waiting", "flying":
			_reel("Trop tôt ! Le poisson a eu peur.")
		"bite":
			_catch()


## Coup sec vers le haut (VR) : ferre si ça mord, sinon rien.
func jerk() -> void:
	if state == "bite":
		_catch()


func cancel() -> void:
	state = "idle"
	bobber.visible = false
	line.visible = false
	_bite_label.visible = false


func _cast(from: Vector3, forward: Vector3) -> void:
	if player.in_dungeon:
		Fx.text(player.world, player._front(1.4), "Pas de poissons au donjon !", Color(1, 1, 1), 0.5, 1.2)
		return
	var f := Vector3(forward.x, 0, forward.z)
	if f.length() < 0.01:
		return
	f = f.normalized()
	var target := Vector3.INF
	var d := 4.0
	while d <= 16.0:
		var p := from + f * d
		if Island.height(p.x, p.z) < -0.35:
			var p2 := from + f * minf(d + 2.5, 16.0)
			target = p2 if Island.height(p2.x, p2.z) < -0.35 else p
			break
		d += 0.5
	if target == Vector3.INF:
		Fx.text(player.world, player._front(1.4), "Pas d'eau devant toi !", Color(0.7, 0.9, 1.0), 0.5, 1.2)
		return
	state = "flying"
	_t = 0.0
	_from = from
	_to = Vector3(target.x, 0.03, target.z)
	bobber.visible = true
	line.visible = true
	Save.quest["tries"] = int(Save.quest.get("tries", 0)) + 1
	Fx.text(player.world, from + f * 0.6 + Vector3(0, 0.3, 0), "FSHHH !", Color(0.8, 0.95, 1.0), 0.5, 0.6)


func _reel(msg: String) -> void:
	cancel()
	if msg != "":
		Fx.text(player.world, player._front(1.3), msg, Color(1, 1, 1), 0.45, 1.3)


func _catch() -> void:
	var id := _roll()
	var where := bobber.global_position
	cancel()
	var name: String = Inv.item_name(id)
	if id == "coquillages":
		Save.shells += 3
		name = "3 coquillages"
	else:
		Save.add_item(id)
	Save.quest["catches"] = int(Save.quest.get("catches", 0)) + 1
	if id == "botte":
		Save.quest["boots"] = int(Save.quest.get("boots", 0)) + 1
	if id == "dore":
		Save.quest["golden"] = int(Save.quest.get("golden", 0)) + 1
	Save.save_game()
	Fx.puff(player.world, where + Vector3(0, 0.2, 0), Color(0.75, 0.92, 1.0))
	Fx.text(player.world, player._front(1.6) + Vector3(0, 0.45, 0), "PLOUF ! " + name.to_upper() + " !", Color(1.0, 0.85, 0.3), 0.9, 2.0)
	_show_trophy(id)
	if shore:
		shore.on_catch(id)


## La prise vole vers le joueur, tourne un instant, puis file dans l'inventaire.
func _show_trophy(id: String) -> void:
	var kind: String = Inv.ITEMS.get(id, {}).get("kind", "")
	if kind == "":
		return
	var holder := Node3D.new()
	player.world.add_child(holder)
	holder.global_position = player._front(0.9) + Vector3(0, -0.1, 0)
	var b := Builder.new()
	Props.paint(b, kind, Transform3D(Basis().scaled(Vector3.ONE * 1.6), Vector3.ZERO))
	b.build(holder, Toon.vertex_color(0.01), "Trophy")
	var tw := holder.create_tween()
	tw.tween_property(holder, "rotation:y", TAU, 1.4)
	tw.tween_property(holder, "scale", Vector3.ONE * 0.05, 0.25)
	tw.tween_callback(holder.queue_free)


## Tirage de la prise. Pendant la quête, le slip finit forcément par mordre.
func _roll() -> String:
	var need_slip: bool = Save.quest.get("pierre", "none") == "active" and Save.count("slip") == 0
	if need_slip:
		var n := int(Save.quest.get("slip_try", 0))
		Save.quest["slip_try"] = n + 1
		var chance: float = [0.2, 0.35, 0.6, 1.0][mini(n, 3)]
		if randf() < chance:
			return "slip"
	var r := randf()
	if r < 0.03:
		return "dore"
	if r < 0.15:
		return "arcenciel"
	if r < 0.55:
		return "sardine"
	if r < 0.72:
		return "botte"
	if r < 0.9:
		return "algue"
	return "coquillages"


func _process(delta: float) -> void:
	if state == "idle":
		return
	_t += delta
	match state:
		"flying":
			var k := clampf(_t / 0.6, 0.0, 1.0)
			var p := _from.lerp(_to, k)
			p.y += sin(k * PI) * 2.0
			bobber.global_position = p
			if k >= 1.0:
				state = "waiting"
				_t = 0.0
				_wait = randf_range(2.0, 5.5)
				Fx.puff(player.world, _to, Color(0.8, 0.95, 1.0))
		"waiting":
			bobber.global_position = _to + Vector3(0, sin(_t * 2.5) * 0.02, 0)
			if _t > _wait:
				state = "bite"
				_t = 0.0
				_bite_label.visible = true
				_bite_label.global_position = _to + Vector3(0, 0.6, 0)
				player.fishing_bite()
		"bite":
			bobber.global_position = _to + Vector3(0, -0.12 + absf(sin(_t * 14.0)) * 0.1, 0)
			_bite_label.scale = Vector3.ONE * (1.0 + absf(sin(_t * 10.0)) * 0.3)
			if _t > BITE_WINDOW:
				_bite_label.visible = false
				state = "waiting"
				_t = 0.0
				_wait = randf_range(2.0, 4.5)
				Fx.text(player.world, _to + Vector3(0, 0.6, 0), "Il s'est échappé...", Color(1, 1, 1), 0.5, 1.0)
	# Le fil entre le bout de la canne et le bouchon
	var a := tip
	var c := bobber.global_position
	var len := a.distance_to(c)
	if len > 0.01:
		var up := (c - a) / len
		var basis := Basis(Quaternion(Vector3.UP, up)).scaled(Vector3(1, len, 1))
		line.global_transform = Transform3D(basis, (a + c) * 0.5)
	# Trop loin : on remballe
	if Vector2(player.global_position.x - _to.x, player.global_position.z - _to.z).length() > 25.0:
		_reel("La ligne est trop tendue !")
