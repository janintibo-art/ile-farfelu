extends Node
## Musique douce qui s'invente toute seule (v32), une couleur par lieu.
## Les notes sont fabriquées au début dans un thread, puis jouées au hasard dans une gamme.
## Silence à Belloche avant la fin de l'énigme et dans la Cathédrale (pour ne pas
## couvrir les mélodies des énigmes).

const Bells := preload("res://scripts/bells.gd")
const Save := preload("res://scripts/save.gd")
const Sfx := preload("res://scripts/sfx.gd")

const MRATE := 22050
const PRATE := 11025
const SCHEMES := {
	"calm": {"inst": "marimba", "notes": [261.63, 293.66, 329.63, 392.0, 440.0, 523.25], "step": 0.62, "p": 0.36, "pad": 130.81, "vol": -13.0},
	"play": {"inst": "marimba", "notes": [329.63, 392.0, 440.0, 493.88, 587.33, 659.25], "step": 0.34, "p": 0.42, "pad": 164.81, "vol": -14.0},
	"mystic": {"inst": "bell", "notes": [220.0, 261.63, 293.66, 329.63, 392.0, 440.0], "step": 1.2, "p": 0.28, "pad": 110.0, "vol": -17.0},
	"wood": {"inst": "pluck", "notes": [293.66, 329.63, 369.99, 440.0, 493.88, 587.33], "step": 0.52, "p": 0.34, "pad": 146.83, "vol": -12.0},
	"airy": {"inst": "flute", "notes": [392.0, 440.0, 523.25, 587.33, 659.25, 784.0], "step": 1.5, "p": 0.26, "pad": 98.0, "vol": -14.0},
}
const ORDER := ["calm", "wood", "play", "mystic", "airy"]
const AREA_SCHEME := {
	"island": "calm", "maquette": "wood", "dungeon": "mystic", "phare": "wood", "cells": "mystic",
	"virevolte": "play", "travers": "wood", "brumelune": "airy", "archive": "mystic",
	"belloche": "calm", "cathedrale": "", "hautes": "airy", "obs": "mystic",
}

var player
var _thread: Thread
var _mutex := Mutex.new()
var _sounds := {}
var _voices: Array = []
var _vi := 0
var _t := 0.0
var _pad_t := 3.0
var _idx := 2
var _stop := false
var _padp: AudioStreamPlayer


func setup(p_player) -> void:
	player = p_player
	for k in 6:
		var p := AudioStreamPlayer.new()
		p.bus = "Musique"
		add_child(p)
		_voices.append(p)
	_padp = AudioStreamPlayer.new()
	_padp.bus = "Musique"
	add_child(_padp)
	_thread = Thread.new()
	_thread.start(_render)


func _exit_tree() -> void:
	_stop = true
	if _thread and _thread.is_started():
		_thread.wait_to_finish()


func _render() -> void:
	for sn in ORDER:
		var sc: Dictionary = SCHEMES[sn]
		for fr in sc["notes"]:
			if _stop:
				return
			var w := Bells.make(sc["inst"], fr, MRATE)
			_mutex.lock()
			_sounds[sc["inst"] + str(fr)] = w
			_mutex.unlock()
		if _stop:
			return
		var pw := Bells.make("pad", sc["pad"], PRATE)
		_mutex.lock()
		_sounds["pad" + str(sc["pad"])] = pw
		_mutex.unlock()


func _snd(key: String) -> AudioStreamWAV:
	_mutex.lock()
	var w = _sounds.get(key, null)
	_mutex.unlock()
	return w


func _quiet(area: String) -> bool:
	if AREA_SCHEME.get(area, "") == "":
		return true
	if area == "belloche" and not Save.story.get("k_done", false):
		return true
	return false


func _process(delta: float) -> void:
	if player == null:
		return
	var area := Sfx.area_of(player.global_position.y)
	if player.in_dungeon and area == "island":
		area = "dungeon"
	if _quiet(area):
		return
	var sc: Dictionary = SCHEMES[AREA_SCHEME[area]]
	_t -= delta
	_pad_t -= delta
	if _pad_t <= 0.0:
		_pad_t = randf_range(6.0, 9.0)
		var pw := _snd("pad" + str(sc["pad"]))
		if pw:
			_padp.stream = pw
			_padp.volume_db = sc["vol"] - 8.0
			_padp.pitch_scale = 1.0 if randf() < 0.6 else 1.5
			_padp.play()
	if _t <= 0.0:
		_t = sc["step"] * (1.0 if randf() < 0.75 else 2.0)
		if randf() < sc["p"]:
			var notes: Array = sc["notes"]
			_idx = clampi(_idx + randi_range(-2, 2), 0, notes.size() - 1)
			var w := _snd(sc["inst"] + str(notes[_idx]))
			if w:
				_play(w, sc["vol"] + randf_range(-2.0, 1.0), 1.0)


func _play(w: AudioStreamWAV, vol: float, pitch: float) -> void:
	var p: AudioStreamPlayer = _voices[_vi]
	_vi = (_vi + 1) % _voices.size()
	p.stream = w
	p.volume_db = vol
	p.pitch_scale = pitch
	p.play()
