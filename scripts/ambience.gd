extends Node
## Ambiances sonores (v32) : mer, vent, salle, grillons — fabriqués une fois pour toutes
## dans un thread (le jeu ne ralentit pas), puis lus en boucle sans coupure.
## Le mélange change selon le lieu ; de petits bruits au hasard (oiseaux, gouttes, grenouilles…)
## viennent se placer autour du joueur.

const Island := preload("res://scripts/island.gd")
const Bells := preload("res://scripts/bells.gd")
const Sfx := preload("res://scripts/sfx.gd")

const RATE := 16000
## Volume de base de chaque nappe (linéaire)
const BASE := {"sea": 0.55, "wind": 0.5, "room": 0.5, "crick": 0.28}
## [mer, vent, salle, grillons] selon le lieu
const MIX := {
	"island": [0.0, 0.22, 0.0, 0.0], "maquette": [0.0, 0.0, 0.35, 0.0], "dungeon": [0.0, 0.0, 0.6, 0.0],
	"phare": [0.5, 0.6, 0.0, 0.0], "cells": [0.0, 0.0, 0.5, 0.0], "virevolte": [0.0, 0.25, 0.0, 0.6],
	"travers": [0.0, 0.0, 0.5, 0.0], "brumelune": [0.3, 0.15, 0.0, 0.8], "archive": [0.15, 0.0, 0.45, 0.0],
	"belloche": [0.0, 0.8, 0.0, 0.0], "cathedrale": [0.0, 0.0, 0.7, 0.0], "hautes": [0.0, 0.9, 0.0, 0.0],
	"obs": [0.0, 0.2, 0.45, 0.0], "chateau": [0.0, 0.0, 0.4, 0.0],
}
const NAMES := ["sea", "wind", "room", "crick"]

var player
var _thread: Thread
var _players := {}
var _vol := {"sea": 0.0, "wind": 0.0, "room": 0.0, "crick": 0.0}
var _shot_t := 6.0
var _ready_beds := false


func setup(p_player) -> void:
	player = p_player
	_thread = Thread.new()
	_thread.start(_render)


func _exit_tree() -> void:
	if _thread and _thread.is_started():
		_thread.wait_to_finish()


# --------------------------------------------------------------------------
# Fabrication (dans le thread)
# --------------------------------------------------------------------------

func _render() -> Dictionary:
	var out := {}
	out["sea"] = _sea()
	out["wind"] = _wind()
	out["room"] = _room()
	out["crick"] = _crick()
	return out


static func _loop_wav(f: PackedFloat32Array, gain: float) -> AudioStreamWAV:
	var n := f.size()
	var peak := 0.0001
	for i in n:
		peak = maxf(peak, absf(f[i]))
	var k := gain / peak
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		data.encode_s16(i * 2, int(clampf(f[i] * k, -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = n
	return w


## Bruit blanc filtré deux fois de suite (on garde le 2e tour) : la fin rejoint le début sans clic.
static func _filtered(n: int, rng: RandomNumberGenerator, a: float, b: float) -> PackedFloat32Array:
	var src := PackedFloat32Array()
	src.resize(n)
	for i in n:
		src[i] = rng.randf() * 2.0 - 1.0
	var dst := PackedFloat32Array()
	dst.resize(n)
	var lp := 0.0
	var lp2 := 0.0
	for pass_i in 2:
		for i in n:
			lp += (src[i] - lp) * a
			lp2 += (lp - lp2) * b
			dst[i] = lp2
	return dst


func _sea() -> AudioStreamWAV:
	var T := 10.0
	var n := int(RATE * T)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var rumble := _filtered(n, rng, 0.02, 0.5)
	var mid := _filtered(n, rng, 0.07, 0.5)
	var hiss := _filtered(n, rng, 0.3, 0.6)
	var f := PackedFloat32Array()
	f.resize(n)
	for i in n:
		var t := float(i) / RATE
		var swell := 0.55 + 0.3 * sin(TAU * t / T) + 0.15 * sin(TAU * t * 3.0 / T + 1.0)
		var crest := swell * swell
		f[i] = rumble[i] * 3.0 * (0.4 + 0.6 * swell) + mid[i] * 1.6 * crest + hiss[i] * 0.9 * crest * crest
	return _loop_wav(f, 0.75)


func _wind() -> AudioStreamWAV:
	var T := 10.0
	var n := int(RATE * T)
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var a := _filtered(n, rng, 0.05, 0.5)
	var b := _filtered(n, rng, 0.01, 0.5)
	var f := PackedFloat32Array()
	f.resize(n)
	for i in n:
		var t := float(i) / RATE
		var gust := 0.5 + 0.35 * sin(TAU * t / T) + 0.15 * sin(TAU * t * 2.0 / T + 2.0)
		var g3 := gust * gust * gust
		var whistle := sin(TAU * 523.0 * t + 2.0 * sin(TAU * 3.0 * t / T)) * 0.06 * g3
		f[i] = (a[i] * 1.5 + b[i] * 4.0) * (0.35 + 0.65 * gust) + whistle
	return _loop_wav(f, 0.7)


func _room() -> AudioStreamWAV:
	var T := 6.0
	var n := int(RATE * T)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var a := _filtered(n, rng, 0.012, 0.5)
	var f := PackedFloat32Array()
	f.resize(n)
	for i in n:
		var t := float(i) / RATE
		f[i] = a[i] * 5.0 + sin(TAU * 55.0 * t) * 0.35 + sin(TAU * 110.0 * t + 1.0) * 0.18 + sin(TAU * 165.0 * t + 2.0) * 0.06 * (0.6 + 0.4 * sin(TAU * t / T))
	return _loop_wav(f, 0.6)


func _crick() -> AudioStreamWAV:
	var T := 4.0
	var n := int(RATE * T)
	var f := PackedFloat32Array()
	f.resize(n)
	for i in n:
		var t := float(i) / RATE
		var s := 0.0
		var burst := 1.0 if sin(TAU * 2.0 * t) > 0.2 else 0.0
		var pulse := maxf(0.0, sin(TAU * 18.0 * t))
		s += sin(TAU * 4200.0 * t) * pulse * pulse * burst
		var burst2 := 1.0 if sin(TAU * 1.5 * t + 1.0) > 0.35 else 0.0
		var pulse2 := maxf(0.0, sin(TAU * 14.0 * t))
		s += sin(TAU * 3800.0 * t) * pulse2 * pulse2 * burst2 * 0.7
		f[i] = s
	return _loop_wav(f, 0.5)


# --------------------------------------------------------------------------
# Lecture
# --------------------------------------------------------------------------

func _start_beds(beds: Dictionary) -> void:
	for nm in NAMES:
		var p := AudioStreamPlayer.new()
		p.stream = beds[nm]
		p.bus = "Ambiance"
		p.volume_db = -60.0
		add_child(p)
		p.play()
		_players[nm] = p
	_ready_beds = true


func _process(delta: float) -> void:
	if not _ready_beds:
		if _thread and _thread.is_started() and not _thread.is_alive():
			var beds = _thread.wait_to_finish()
			if beds is Dictionary and beds.has("sea"):
				_start_beds(beds)
		return
	if player == null:
		return
	var p: Vector3 = player.global_position
	var area := Sfx.area_of(p.y)
	var mix: Array = MIX.get(area, [0.0, 0.0, 0.0, 0.0])
	var target := {"sea": mix[0], "wind": mix[1], "room": mix[2], "crick": mix[3]}
	if area == "island":
		var h := Island.height(p.x, p.z)
		var d := Vector2(p.x, p.z).length()
		target["sea"] = clampf(1.0 - (h - 0.2) / 4.0, 0.15, 1.0) * clampf((d - 10.0) / 30.0, 0.25, 1.0)
		# un peu de grillons à l'intérieur des terres
		target["crick"] = clampf((h - 1.5) / 3.0, 0.0, 1.0) * 0.18
		if player.in_dungeon:
			target = {"sea": 0.0, "wind": 0.0, "room": 0.5, "crick": 0.0}
	var k := clampf(delta * 1.2, 0.0, 1.0)
	for nm in NAMES:
		_vol[nm] = lerpf(_vol[nm], target[nm], k)
		var v: float = _vol[nm] * BASE[nm]
		_players[nm].volume_db = linear_to_db(v) if v > 0.002 else -60.0
	_shot_t -= delta
	if _shot_t <= 0.0:
		_one_shot(area, p)


func _one_shot(area: String, p: Vector3) -> void:
	var kind := ""
	var lo := 5.0
	var hi := 12.0
	var fr := 0.0
	var vol := -8.0
	match area:
		"island":
			if Island.height(p.x, p.z) > 1.5 and not player.in_dungeon:
				kind = "bird"
				lo = 6.0
				hi = 15.0
		"virevolte":
			kind = "bird"
			lo = 4.0
			hi = 9.0
		"belloche":
			kind = "bird"
			lo = 10.0
			hi = 22.0
		"brumelune":
			kind = "croak"
			lo = 3.0
			hi = 8.0
		"dungeon", "archive", "cathedrale", "cells", "maquette":
			kind = "drip"
			lo = 3.0
			hi = 9.0
			vol = -13.0
		"hautes", "travers", "obs", "chateau":
			kind = "tick"
			lo = 5.0
			hi = 12.0
			vol = -14.0
	_shot_t = randf_range(lo, hi)
	if kind == "":
		return
	var ang := randf() * TAU
	var dist := randf_range(4.0, 12.0)
	var pos := p + Vector3(cos(ang) * dist, randf_range(0.5, 3.0) if kind == "bird" else 0.3, sin(ang) * dist)
	var sp := Bells.play(player, kind, fr, pos, vol)
	if kind == "bird" or kind == "croak":
		sp.pitch_scale = randf_range(0.8, 1.3)
	elif kind == "drip":
		sp.pitch_scale = randf_range(0.8, 1.2)
