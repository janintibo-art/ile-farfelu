extends RefCounted
## Sons fabriqués en direct (pas de fichiers) : cloches, tambours, chant d'oiseau.
## Utilisés à Belloche et dans la Cathédrale des Échos.

const RATE := 22050
const DO := 261.63
const RE := 293.66
const MI := 329.63
const SOL := 392.0
const LA := 440.0

static var cache := {}


static func wav(kind: String, freq := 440.0) -> AudioStreamWAV:
	var key := kind + str(snappedf(freq, 0.01))
	if cache.has(key):
		return cache[key]
	var dur := 1.6
	match kind:
		"wood":
			dur = 0.35
		"metal":
			dur = 1.0
		"stone":
			dur = 0.5
		"bird":
			dur = 0.8
		"flute":
			dur = 0.9
		"tick":
			dur = 0.15
	var n := int(RATE * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in n:
		var t := float(i) / RATE
		var s := 0.0
		match kind:
			"bell":
				s = (sin(TAU * freq * t) * 0.6 + sin(TAU * freq * 2.76 * t) * 0.25 * exp(-t * 3.0) + sin(TAU * freq * 5.4 * t) * 0.1 * exp(-t * 6.0)) * exp(-t * 2.2)
			"wood":
				s = (sin(TAU * 190.0 * t) * 0.7 + (rng.randf() * 2.0 - 1.0) * 0.25) * exp(-t * 22.0)
			"metal":
				s = (sin(TAU * 880.0 * t) * 0.4 + sin(TAU * 1320.0 * t) * 0.3 + sin(TAU * 2190.0 * t) * 0.2) * exp(-t * 5.0)
			"stone":
				s = (sin(TAU * 85.0 * t) * 0.8 + (rng.randf() * 2.0 - 1.0) * 0.15) * exp(-t * 11.0)
			"bird":
				var f := 2400.0 + 900.0 * sin(t * 38.0) + 600.0 * (1.0 if t > 0.4 else 0.0)
				var gate := 1.0 if fmod(t, 0.4) < 0.22 else 0.0
				s = sin(TAU * f * t) * 0.35 * gate * exp(-t * 1.2)
			"tick":
				s = sin(TAU * 1800.0 * t) * 0.6 * exp(-t * 50.0)
			"flute":
				s = (sin(TAU * freq * t) * 0.5 + sin(TAU * freq * 2.0 * t) * 0.12) * minf(t * 20.0, 1.0) * exp(-t * 2.5)
		var a := int(clampf(s, -1.0, 1.0) * 28000.0)
		data.encode_s16(i * 2, a)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	cache[key] = w
	return w


## Joue un son à un endroit du monde (spatialisé : en VR on entend d'où il vient).
static func play(world: Node, kind: String, freq: float, pos: Vector3, vol_db := 0.0) -> void:
	var p := AudioStreamPlayer3D.new()
	p.stream = wav(kind, freq)
	p.volume_db = vol_db
	p.unit_size = 7.0
	p.max_distance = 80.0
	world.add_child(p)
	p.global_position = pos
	p.finished.connect(p.queue_free)
	p.play()
