extends StaticBody3D
## Un bouton de choix flottant (menu de la boutique). On le vise avec la main
## (ou la souris) et on appuie sur la gâchette (ou clic).

const Toon := preload("res://scripts/toon.gd")
const Fx := preload("res://scripts/fx.gd")

const BASE := Color(1.0, 0.96, 0.88)
const HOVER := Color(1.0, 0.85, 0.3)

var callback: Callable
var mesh: MeshInstance3D
var label: Label3D
var _col := BASE


func setup(text: String, cb: Callable, width := 1.25, col := BASE) -> void:
	callback = cb
	_col = col
	collision_layer = 16
	collision_mask = 0
	var size := Vector3(width, 0.16, 0.03)
	mesh = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	mesh.material_override = Toon.flat(_col)
	add_child(mesh)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size + Vector3(0, 0.02, 0.04)
	cs.shape = sh
	add_child(cs)
	label = Label3D.new()
	label.text = text
	label.font_size = 40
	label.pixel_size = 0.0024
	label.outline_size = 0
	label.modulate = Color(0.16, 0.1, 0.22)
	label.position = Vector3(0, 0, 0.017)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	add_child(label)
	# Réduit le texte s'il déborde du bouton
	var max_chars := int(width / (0.0024 * 40.0 * 0.52))
	if text.length() > max_chars:
		label.pixel_size = 0.0024 * float(max_chars) / float(text.length())


func set_hover(on: bool) -> void:
	mesh.material_override = Toon.flat(HOVER if on else _col)
	scale = Vector3.ONE * (1.06 if on else 1.0)


func press() -> void:
	scale = Vector3(1.1, 0.8, 1.0)
	if callback.is_valid():
		callback.call()
