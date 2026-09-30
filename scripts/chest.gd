extends StaticBody3D
## Coffre au trésor. On le vise avec la main + gâchette (ou E / clic sur PC).
## Le coffre doré ne s'ouvre qu'une fois le Roi Gloubi vaincu.

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")
const Fx := preload("res://scripts/fx.gd")
const Save := preload("res://scripts/save.gd")
const Props := preload("res://scripts/props.gd")

var golden := false
var opened := false
var locked := false
var dungeon
var lid: Node3D
var _lid_angle := 0.0
var _mesh_body: MeshInstance3D


func setup(p_dungeon, p_golden: bool) -> void:
	dungeon = p_dungeon
	golden = p_golden
	collision_layer = 1 | 16
	collision_mask = 0
	var wood := Color(0.62, 0.38, 0.2) if not golden else Color(1.0, 0.8, 0.2)
	var trim := Color(1.0, 0.82, 0.25) if not golden else Color(0.95, 0.35, 0.5)
	var b := Builder.new()
	b.box(Vector3(0.9, 0.5, 0.6), Vector3(0, 0.25, 0), wood, false)
	for x in [-0.4, 0.4]:
		b.box(Vector3(0.06, 0.52, 0.62), Vector3(x, 0.25, 0), trim, false)
	b.box(Vector3(0.14, 0.16, 0.04), Vector3(0, 0.38, -0.31), trim, false)
	_mesh_body = b.build(self, Toon.vertex_color(0.01), "ChestBody")
	lid = Node3D.new()
	lid.position = Vector3(0, 0.5, 0.3)
	add_child(lid)
	var lb := Builder.new()
	lb.box(Vector3(0.9, 0.18, 0.6), Vector3(0, 0.09, -0.3), wood.lightened(0.08), false)
	for x in [-0.4, 0.4]:
		lb.box(Vector3(0.06, 0.2, 0.62), Vector3(x, 0.09, -0.3), trim, false)
	lb.build(lid, Toon.vertex_color(0.01), "Lid")
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.9, 0.7, 0.6)
	cs.shape = sh
	cs.position.y = 0.35
	add_child(cs)


func reset() -> void:
	opened = false
	_lid_angle = 0.0
	lid.rotation.x = 0.0


func set_hover(on: bool) -> void:
	scale = Vector3.ONE * (1.06 if on and not opened else 1.0)


func press() -> void:
	if opened:
		Fx.text(get_parent(), global_position + Vector3(0, 1.0, 0), "Vide !", Color(1, 1, 1), 0.5, 0.7)
		return
	if golden and dungeon and not dungeon.boss_dead:
		Fx.text(get_parent(), global_position + Vector3(0, 1.1, 0), "Verrouillé... Bats le Roi Gloubi !", Color(1.0, 0.6, 0.6), 0.6, 1.4)
		return
	opened = true
	Save.dungeon["chests"] = int(Save.dungeon["chests"]) + 1
	Fx.puff(get_parent(), global_position + Vector3(0, 0.7, 0), Color(1.0, 0.9, 0.4))
	var gain := 0
	var msg := ""
	if golden:
		gain = 20
		if Save.sword < 3:
			Save.sword = 3
			msg = "ÉPÉE DE FEU !"
			if dungeon and dungeon.player:
				dungeon.player.refresh_sword()
		else:
			gain = 30
	else:
		gain = randi_range(3, 8)
		if randf() < 0.4:
			var kind: String = ["glace", "ramen", "bonbon"][randi() % 3]
			Props.make(get_parent(), kind, global_position + Vector3(0, 0.9, 0))
			msg = "Un truc à manger !"
	Save.shells += gain
	Save.save_game()
	var txt := "TRÉSOR !  +%d coquillages" % gain
	if msg != "":
		txt += "\n" + msg
	Fx.text(get_parent(), global_position + Vector3(0, 1.3, 0), txt, Color(1.0, 0.85, 0.25), 1.0 if not golden else 1.5, 1.8)


func _process(delta: float) -> void:
	var target := 1.9 if opened else 0.0
	_lid_angle = lerpf(_lid_angle, target, clampf(delta * 6.0, 0.0, 1.0))
	lid.rotation.x = _lid_angle
