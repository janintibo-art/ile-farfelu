extends Node3D
## Menu de dialogue flottant réutilisable (titre + boutons à viser).
## Le propriétaire appelle show_options() et fait tourner le menu vers le joueur.

const ChoiceButton := preload("res://scripts/choice_button.gd")

var header: Label3D
var buttons: Array = []


func _ready() -> void:
	header = Label3D.new()
	header.font_size = 36
	header.pixel_size = 0.0024
	header.outline_size = 10
	header.outline_modulate = Color(0.13, 0.08, 0.17)
	header.modulate = Color(1.0, 0.9, 0.5)
	header.position = Vector3(0, 0.34, 0)
	header.visible = false
	add_child(header)


## options = [[texte, Callable, (couleur)], ...]
func show_options(options: Array) -> void:
	clear()
	for o in options:
		var bt := ChoiceButton.new()
		add_child(bt)
		var col: Color = o[2] if o.size() > 2 else ChoiceButton.BASE
		bt.setup(o[0], o[1], 1.3, col)
		bt.position = Vector3(0, 0.12 - buttons.size() * 0.21, 0)
		buttons.append(bt)


func clear() -> void:
	for bt in buttons:
		bt.queue_free()
	buttons.clear()


func set_header(txt: String) -> void:
	header.text = txt
	header.visible = txt != ""


func choose(index: int) -> void:
	if index >= 0 and index < buttons.size():
		buttons[index].press()


func face(target: Vector3) -> void:
	var to := target - global_position
	to.y = 0.0
	if to.length() > 0.1:
		global_rotation.y = atan2(to.x, to.z)
