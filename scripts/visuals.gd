extends Node
## Petits plus visuels (v33) : particules d'ambiance autour du joueur
## (pollen, pétales, lucioles, neige, poussière…) et étalonnage des couleurs
## qui change doucement selon le lieu.

const Island := preload("res://scripts/island.gd")
const Toon := preload("res://scripts/toon.gd")
const Sfx := preload("res://scripts/sfx.gd")

## [saturation, contraste, luminosité] de l'image selon le lieu
const GRADE := {
	"island": [1.02, 1.06, 1.0], "maquette": [1.05, 1.05, 1.0], "dungeon": [1.0, 1.1, 1.0],
	"phare": [1.02, 1.06, 1.0], "cells": [0.95, 1.1, 1.0], "virevolte": [1.18, 1.05, 1.0],
	"travers": [1.0, 1.08, 1.0], "brumelune": [0.92, 1.1, 0.97], "archive": [0.92, 1.1, 1.0],
	"belloche": [1.05, 1.06, 1.0], "cathedrale": [0.95, 1.12, 1.0], "hautes": [0.85, 1.05, 1.04],
	"obs": [1.0, 1.12, 0.98], "chateau": [1.08, 1.08, 1.0],
}
## Particules : couleur, gravité, vitesse, nombre, taille, zone
const PARTS := {
	"island": {"col": Color(1.0, 0.97, 0.7), "g": Vector3(0.03, 0.05, 0.0), "v": 0.1, "n": 34, "s": 1.0, "box": 9.0},
	"virevolte": {"col": Color(1.0, 0.7, 0.85), "g": Vector3(0.12, -0.28, 0.05), "v": 0.1, "n": 40, "s": 1.6, "box": 9.0},
	"brumelune": {"col": Color(0.8, 1.0, 0.4), "g": Vector3(0, 0, 0), "v": 0.25, "n": 28, "s": 1.5, "box": 8.0},
	"hautes": {"col": Color(1.0, 1.0, 1.0), "g": Vector3(0.12, -0.5, 0.0), "v": 0.1, "n": 70, "s": 1.5, "box": 10.0},
	"belloche": {"col": Color(1.0, 0.75, 0.4), "g": Vector3(0.3, -0.3, 0.1), "v": 0.1, "n": 24, "s": 1.6, "box": 9.0},
	"dungeon": {"col": Color(0.9, 0.85, 1.0), "g": Vector3(0, 0.0, 0), "v": 0.06, "n": 24, "s": 0.8, "box": 7.0},
	"archive": {"col": Color(1.0, 0.95, 0.8), "g": Vector3(0, 0.0, 0), "v": 0.06, "n": 26, "s": 0.8, "box": 7.0},
	"cathedrale": {"col": Color(1.0, 0.92, 0.75), "g": Vector3(0, 0.0, 0), "v": 0.06, "n": 28, "s": 0.8, "box": 8.0},
	"obs": {"col": Color(0.85, 0.9, 1.0), "g": Vector3(0, 0.0, 0), "v": 0.06, "n": 26, "s": 0.8, "box": 8.0},
	"chateau": {"col": Color(1.0, 0.85, 0.95), "g": Vector3(0.0, -0.15, 0), "v": 0.08, "n": 34, "s": 1.1, "box": 8.0},
	"cells": {"col": Color(0.9, 0.85, 1.0), "g": Vector3(0, 0.0, 0), "v": 0.06, "n": 20, "s": 0.8, "box": 7.0},
}

var env: Environment
var player
var parts: CPUParticles3D
var _area := ""
var _grade := [1.02, 1.06, 1.0]


func setup(p_env: Environment, p_player) -> void:
	env = p_env
	player = p_player
	parts = CPUParticles3D.new()
	parts.name = "Ambient"
	parts.local_coords = false
	parts.lifetime = 8.0
	parts.preprocess = 8.0
	parts.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	parts.direction = Vector3.UP
	parts.spread = 180.0
	parts.scale_amount_min = 0.6
	parts.scale_amount_max = 1.4
	parts.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := SphereMesh.new()
	m.radius = 0.035
	m.height = 0.07
	m.radial_segments = 6
	m.rings = 3
	parts.mesh = m
	parts.emitting = false
	add_child(parts)


func _process(delta: float) -> void:
	if player == null or env == null:
		return
	var p: Vector3 = player.global_position
	var area := Sfx.area_of(p.y)
	if area == "island" and player.in_dungeon:
		area = "dungeon"
	var key := area
	if area == "island" and Island.height(p.x, p.z) < 1.3:
		key = ""   # pas de pollen sur la plage
	if key != _area:
		_area = key
		_apply_particles(key)
	parts.global_position = p + Vector3(0, 1.8, 0)
	# Étalonnage doux
	var g: Array = GRADE.get(area, GRADE["island"])
	var k := clampf(delta * 1.5, 0.0, 1.0)
	for i in 3:
		_grade[i] = lerpf(_grade[i], g[i], k)
	env.adjustment_saturation = _grade[0]
	env.adjustment_contrast = _grade[1]
	env.adjustment_brightness = _grade[2]


func _apply_particles(key: String) -> void:
	if not PARTS.has(key):
		parts.emitting = false
		return
	var d: Dictionary = PARTS[key]
	parts.mesh.material = Toon.unlit(d["col"])
	parts.amount = d["n"]
	parts.gravity = d["g"]
	parts.initial_velocity_min = d["v"] * 0.5
	parts.initial_velocity_max = d["v"]
	parts.scale_amount_min = 0.6 * d["s"]
	parts.scale_amount_max = 1.4 * d["s"]
	var b: float = d["box"]
	parts.emission_box_extents = Vector3(b, b * 0.35, b)
	parts.restart()
	parts.emitting = true
