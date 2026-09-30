extends Node3D
## Fait tourner et/ou flotter un objet (nuages, canard géant...).
## Peut aussi faire "parler" l'objet quand le joueur passe à côté.

const Fx := preload("res://scripts/fx.gd")

var spin := 0.0
var bob := 0.0
var bob_speed := 1.0
var talk_text := ""
var talk_radius := 0.0
var player: Node3D

var _base_y := 0.0
var _t := 0.0
var _talk_cd := 3.0


func _ready() -> void:
	_base_y = position.y


func _process(delta: float) -> void:
	_t += delta
	if spin != 0.0:
		rotation.y += spin * delta
	if bob != 0.0:
		position.y = _base_y + sin(_t * bob_speed) * bob
		rotation.z = sin(_t * bob_speed * 0.7) * bob * 0.15
	if talk_text != "" and player:
		_talk_cd -= delta
		if _talk_cd <= 0.0:
			_talk_cd = 6.0
			if player.global_position.distance_to(global_position) < talk_radius:
				Fx.text(get_parent(), global_position + Vector3(0, 4.5, 0), talk_text, Color(1.0, 0.9, 0.2), 2.0, 1.8)
