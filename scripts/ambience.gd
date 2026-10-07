extends Node
## Le bruit de la mer, fabriqué en direct (pas besoin de fichier son) :
## un souffle filtré qui monte et descend comme des vagues.
## Plus fort près de la plage, coupé dans le donjon.

const Island := preload("res://scripts/island.gd")

var player
var gen: AudioStreamGenerator
var playback: AudioStreamGeneratorPlayback
var asp: AudioStreamPlayer
var _phase := 0.0
var _lp := 0.0
var _lp2 := 0.0
var _vol := 0.0
var _rate := 22050.0


func setup(p_player) -> void:
	player = p_player
	gen = AudioStreamGenerator.new()
	gen.mix_rate = _rate
	gen.buffer_length = 0.4
	asp = AudioStreamPlayer.new()
	asp.stream = gen
	asp.volume_db = -6.0
	add_child(asp)
	asp.play()
	playback = asp.get_stream_playback()


func _process(_delta: float) -> void:
	if playback == null:
		return
	var target := 0.0
	if player and not player.in_dungeon:
		var p: Vector3 = player.global_position
		var h := Island.height(p.x, p.z)
		var d := Vector2(p.x, p.z).length()
		target = clampf(1.0 - (h - 0.2) / 4.0, 0.15, 1.0) * clampf((d - 10.0) / 30.0, 0.25, 1.0)
	var n := playback.get_frames_available()
	for i in n:
		_vol = lerpf(_vol, target, 0.00005)
		_phase += 1.0 / _rate
		# Deux vagues qui se superposent, pour que ça ne soit pas régulier
		var swell := 0.55 + 0.3 * sin(_phase * 0.9) + 0.15 * sin(_phase * 2.3 + 1.0)
		swell = swell * swell
		var white := randf() * 2.0 - 1.0
		_lp += (white - _lp) * (0.04 + 0.06 * swell)
		_lp2 += (_lp - _lp2) * 0.3
		var s := _lp2 * swell * _vol * 2.2
		playback.push_frame(Vector2(s, s))
