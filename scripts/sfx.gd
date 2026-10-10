extends Node
## Chef d'orchestre du son (v32) : crée les « bus » audio (Musique, Ambiance, Effets, Voix),
## la réverbération qui change selon le lieu, et joue les petits sons
## (interface, pas, saut, voix des personnages, pièces gagnées).
## Tous les appels statiques ne font rien si le son n'est pas prêt.

const Save := preload("res://scripts/save.gd")
const Island := preload("res://scripts/island.gd")
const Bells := preload("res://scripts/bells.gd")

const SQUARE := Vector2(0.0, -49.5)
const AREAS := ["island", "maquette", "dungeon", "phare", "cells", "virevolte", "travers",
	"brumelune", "archive", "belloche", "cathedrale", "hautes", "obs", "chateau", "registre"]
## [mouillé, taille de la salle] de la réverbération selon le lieu
const REVERB := {
	"island": [0.0, 0.4], "maquette": [0.08, 0.4], "dungeon": [0.30, 0.8], "phare": [0.15, 0.6],
	"cells": [0.20, 0.6], "virevolte": [0.04, 0.4], "travers": [0.14, 0.5], "brumelune": [0.08, 0.5],
	"archive": [0.28, 0.8], "belloche": [0.05, 0.5], "cathedrale": [0.50, 0.95], "hautes": [0.10, 0.6],
	"obs": [0.30, 0.85], "chateau": [0.38, 0.9], "registre": [0.45, 0.95],
}

static var inst = null

var player
var pool: Array = []
var _i := 0
var _last_shells := 0
var _area_t := 0.0
var area := "island"
var reverb: AudioEffectReverb
var _talk_last := {}


static func area_of(y: float) -> String:
	return AREAS[clampi(int(floor((y + 50.0) / 100.0)), 0, AREAS.size() - 1)]


static func _ensure_bus(bus_name: String, vol_db: float) -> int:
	var i := AudioServer.get_bus_index(bus_name)
	if i < 0:
		AudioServer.add_bus()
		i = AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, bus_name)
		AudioServer.set_bus_send(i, "Master")
	AudioServer.set_bus_volume_db(i, vol_db)
	return i


func setup(p_player) -> void:
	player = p_player
	_ensure_bus("Musique", -9.0)
	_ensure_bus("Ambiance", -3.0)
	var fx := _ensure_bus("Effets", 0.0)
	_ensure_bus("Voix", -4.0)
	if AudioServer.get_bus_effect_count(fx) == 0:
		reverb = AudioEffectReverb.new()
		reverb.dry = 1.0
		reverb.wet = 0.0
		reverb.room_size = 0.4
		reverb.damping = 0.6
		AudioServer.add_bus_effect(fx, reverb)
	else:
		reverb = AudioServer.get_bus_effect(fx, 0)
	# Un limiteur sur la sortie générale : plus de saturation quand tout sonne en même temps
	if AudioServer.get_bus_effect_count(0) == 0:
		var cls := "AudioEffectHardLimiter" if ClassDB.can_instantiate("AudioEffectHardLimiter") else "AudioEffectLimiter"
		if ClassDB.can_instantiate(cls):
			var lim = ClassDB.instantiate(cls)
			AudioServer.add_bus_effect(0, lim)
	for k in 10:
		var p := AudioStreamPlayer.new()
		p.bus = "Effets"
		add_child(p)
		pool.append(p)
	_last_shells = Save.shells
	inst = self


func _exit_tree() -> void:
	if inst == self:
		inst = null


func _process(delta: float) -> void:
	if Save.shells > _last_shells and Save.shells - _last_shells < 400:
		_play("coin", -6.0, 440.0)
	_last_shells = Save.shells
	_area_t -= delta
	if _area_t <= 0.0 and player:
		_area_t = 0.3
		area = area_of(player.global_position.y)
	if reverb and REVERB.has(area):
		var r: Array = REVERB[area]
		reverb.wet = lerpf(reverb.wet, r[0], clampf(delta * 1.5, 0.0, 1.0))
		reverb.room_size = lerpf(reverb.room_size, r[1], clampf(delta * 1.5, 0.0, 1.0))


func _play(kind: String, vol := 0.0, freq := 440.0, pitch := 1.0) -> void:
	if pool.is_empty():
		return
	var p: AudioStreamPlayer = pool[_i]
	_i = (_i + 1) % pool.size()
	p.stream = Bells.wav(kind, freq)
	p.volume_db = vol
	p.pitch_scale = pitch
	p.play()


## Type de sol sous les pieds
func surface(pos: Vector3) -> String:
	match area_of(pos.y):
		"island":
			var h := Island.height(pos.x, pos.z)
			if pos.y - h > 0.35:
				return "wood"
			if Vector2(pos.x, pos.z).distance_to(SQUARE) < 14.0:
				return "stone"
			return "sand" if h < 1.3 else "grass"
		"virevolte":
			return "grass"
		"travers", "brumelune", "maquette":
			return "wood"
		"hautes":
			return "snow"
	return "stone"


# --------------------------------------------------------------------------
# API statique
# --------------------------------------------------------------------------

static func ui(kind: String, vol := 0.0) -> void:
	if inst == null:
		return
	inst._play(kind, vol, 440.0)


static func step(pos: Vector3, wet := false) -> void:
	if inst == null:
		return
	if wet:
		inst._play("splash", -15.0 + randf() * 3.0, 440.0, 0.9 + randf() * 0.3)
		return
	var surf: String = inst.surface(pos)
	inst._play("step_" + surf, -10.0 + randf() * 2.0, float(randi() % 3), 0.93 + randf() * 0.14)


static func land() -> void:
	if inst:
		inst._play("land", -5.0)


static func jump() -> void:
	if inst:
		inst._play("jump", -11.0)


static func splash() -> void:
	if inst:
		inst._play("splash", -3.0)


## Petits « bip-bip » de voix quand un personnage parle (une hauteur par personnage).
static func talk(node: Node3D, text: String, pitch := -1.0) -> void:
	if inst == null or node == null or not node.is_inside_tree():
		return
	inst._talk(node, text, pitch)


func _talk(node: Node3D, text: String, pitch: float) -> void:
	var id := node.get_instance_id()
	var now := Time.get_ticks_msec()
	if now - int(_talk_last.get(id, -9999)) < 700:
		return
	_talk_last[id] = now
	var base := pitch
	if base < 0.0:
		base = 300.0 + float(absi(String(node.name).hash()) % 14) * 20.0
	base = snappedf(base, 20.0)
	var steps := [1.0, 1.125, 0.89, 1.26, 1.06]
	var n := clampi(text.length() / 3, 3, 14)
	var seed_n := absi(text.hash())
	for k in n:
		if not is_instance_valid(node) or not node.is_inside_tree():
			return
		var fr: float = snappedf(base * steps[(seed_n + k * 3) % 5], 10.0)
		var p := AudioStreamPlayer3D.new()
		p.stream = Bells.wav("blip", fr)
		p.volume_db = -8.0
		p.unit_size = 5.0
		p.max_distance = 35.0
		p.bus = "Voix"
		node.add_child(p)
		p.position = Vector3(0, 1.3, 0)
		p.finished.connect(p.queue_free)
		p.play()
		await get_tree().create_timer(0.085 + float((seed_n + k) % 3) * 0.02).timeout


var _puff_last := 0


static func puff_at(parent: Node, pos: Vector3) -> void:
	if inst == null or not is_instance_valid(parent) or not (parent is Node3D) or not parent.is_inside_tree():
		return
	var now := Time.get_ticks_msec()
	if now - inst._puff_last < 150:
		return
	inst._puff_last = now
	Bells.play(parent, "poof", 0.0, pos, -6.0)
	Bells.play(parent, "sparkle", 0.0, pos, -14.0)
