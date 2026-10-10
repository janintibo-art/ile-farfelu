extends RefCounted
## Sons fabriqués en direct (pas de fichiers) : cloches, tambours, oiseaux,
## bruits de pas, petits sons d'interface, notes de musique…
## v32 : sons plus riches (32 kHz, vraies partielles de cloche, enveloppes douces),
## nombreux nouveaux sons, et tout passe par le bus « Effets » (réverbération selon le lieu).

const RATE := 32000
const DO := 261.63
const RE := 293.66
const MI := 329.63
const SOL := 392.0
const LA := 440.0

static var cache := {}


static func _dur(kind: String) -> float:
	match kind:
		"bell":
			return 2.6
		"wood":
			return 0.4
		"metal":
			return 1.3
		"stone":
			return 0.55
		"bird":
			return 0.8
		"flute":
			return 1.0
		"tick":
			return 0.15
		"click":
			return 0.08
		"hover":
			return 0.05
		"coin":
			return 0.7
		"pickup":
			return 0.3
		"sparkle":
			return 0.8
		"splash":
			return 0.6
		"whoosh":
			return 0.4
		"poof":
			return 0.3
		"blip":
			return 0.07
		"step_sand":
			return 0.14
		"step_grass":
			return 0.12
		"step_wood":
			return 0.12
		"step_stone":
			return 0.1
		"step_snow":
			return 0.2
		"land":
			return 0.22
		"jump":
			return 0.18
		"marimba":
			return 1.1
		"pluck":
			return 1.5
		"pad":
			return 4.0
		"drip":
			return 0.45
		"croak":
			return 0.5
		"baa":
			return 0.8
		"cluck":
			return 0.3
		"oink":
			return 0.5
		"squeak":
			return 0.22
		"boing":
			return 0.6
		"meow":
			return 0.8
		"ding":
			return 0.9
	return 1.0


static func wav(kind: String, freq := 440.0) -> AudioStreamWAV:
	var key := kind + str(snappedf(freq, 0.01))
	if cache.has(key):
		return cache[key]
	var w := make(kind, freq)
	cache[key] = w
	return w


## Fabrique un son (sans toucher au cache : peut être appelé depuis un autre thread).
static func make(kind: String, freq := 440.0, rate := RATE) -> AudioStreamWAV:
	var dur := _dur(kind)
	var n := int(rate * dur)
	var f := PackedFloat32Array()
	f.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7 + int(absf(freq) * 10.0) % 1000
	var gain := 0.85
	var ph := 0.0
	var lp := 0.0
	var lp2 := 0.0
	match kind:
		"bell":
			# Partielles d'une vraie cloche : bourdon, fondamentale, tierce mineure, quinte, octave, etc.
			var parts := [[0.5, 0.30, 0.9], [1.0, 0.65, 1.2], [1.2, 0.30, 1.7], [1.5, 0.20, 2.2],
				[2.0, 0.28, 2.8], [2.76, 0.18, 4.0], [4.1, 0.10, 6.0], [5.4, 0.06, 9.0]]
			for i in n:
				var t := float(i) / rate
				var s := 0.0
				for p in parts:
					s += sin(TAU * freq * p[0] * t) * p[1] * exp(-t * p[2])
				var w := rng.randf() * 2.0 - 1.0
				lp += (w - lp) * 0.5
				s += lp * 0.25 * exp(-t * 70.0)
				f[i] = s
		"wood":
			for i in n:
				var t := float(i) / rate
				var w := rng.randf() * 2.0 - 1.0
				lp += (w - lp) * 0.3
				f[i] = sin(TAU * 190.0 * t) * 0.7 * exp(-t * 20.0) + sin(TAU * 430.0 * t) * 0.35 * exp(-t * 38.0) + lp * 0.25 * exp(-t * 90.0)
		"metal":
			for i in n:
				var t := float(i) / rate
				f[i] = (sin(TAU * 880.0 * t) * 0.4 + sin(TAU * 1320.0 * t) * 0.3 + sin(TAU * 2190.0 * t) * 0.2 + sin(TAU * 3140.0 * t) * 0.1) * exp(-t * 4.5) * (1.0 + 0.04 * sin(TAU * 7.0 * t))
		"stone":
			for i in n:
				var t := float(i) / rate
				ph += TAU * (62.0 + 70.0 * exp(-t * 30.0)) / rate
				var w := rng.randf() * 2.0 - 1.0
				lp += (w - lp) * 0.12
				f[i] = sin(ph) * 0.9 * exp(-t * 11.0) + lp * 0.5 * exp(-t * 28.0)
		"bird":
			for i in n:
				var t := float(i) / rate
				var fr := 2400.0 + 900.0 * sin(t * 38.0) + 600.0 * (1.0 if t > 0.4 else 0.0)
				ph += TAU * fr / rate
				var u := fmod(t, 0.4)
				var gate := sin(PI * u / 0.22) if u < 0.22 else 0.0
				f[i] = (sin(ph) * 0.5 + sin(ph * 2.0) * 0.08) * gate * exp(-t * 1.0)
			gain = 0.5
		"tick":
			for i in n:
				var t := float(i) / rate
				f[i] = sin(TAU * 1800.0 * t) * exp(-t * 50.0) + sin(TAU * 3700.0 * t) * 0.2 * exp(-t * 90.0)
			gain = 0.6
		"flute":
			for i in n:
				var t := float(i) / rate
				var vib := 1.0 + 0.006 * sin(TAU * 5.2 * t) * minf(t * 4.0, 1.0)
				ph += TAU * freq * vib / rate
				var env := minf(t / 0.06, 1.0) * exp(-t * 1.8)
				var w := rng.randf() * 2.0 - 1.0
				lp += (w - lp) * 0.25
				f[i] = (sin(ph) * 0.6 + sin(ph * 2.0) * 0.14 + sin(ph * 3.0) * 0.04) * env + lp * 0.09 * env * (0.5 + 0.5 * exp(-t * 6.0))
		"click":
			for i in n:
				var t := float(i) / rate
				f[i] = (sin(TAU * 1500.0 * t) * 0.7 + sin(TAU * 2300.0 * t) * 0.3) * exp(-t * 70.0)
			gain = 0.55
		"hover":
			for i in n:
				var t := float(i) / rate
				f[i] = sin(TAU * 1050.0 * t) * exp(-t * 80.0)
			gain = 0.3
		"coin":
			for i in n:
				var t := float(i) / rate
				var a := sin(TAU * 988.0 * t) * exp(-t * 9.0)
				var t2 := t - 0.07
				var b := 0.0
				if t2 > 0.0:
					b = (sin(TAU * 1319.0 * t2) + 0.3 * sin(TAU * 2638.0 * t2)) * exp(-t2 * 7.0)
				f[i] = a * 0.7 + b
			gain = 0.6
		"pickup":
			for i in n:
				var t := float(i) / rate
				ph += TAU * (500.0 + 1700.0 * t / 0.25) / rate
				f[i] = (sin(ph) + 0.3 * sin(ph * 2.0)) * sin(PI * minf(t / 0.28, 1.0))
			gain = 0.5
		"sparkle":
			var times := [0.0, 0.08, 0.17, 0.3]
			var fr := [2637.0, 3136.0, 3951.0, 3322.0]
			for i in n:
				var t := float(i) / rate
				var s := 0.0
				for k in 4:
					var u: float = t - times[k]
					if u > 0.0:
						s += sin(TAU * fr[k] * u) * exp(-u * 12.0) * (0.8 - k * 0.1)
				f[i] = s
			gain = 0.4
		"splash":
			for i in n:
				var t := float(i) / rate
				var w := rng.randf() * 2.0 - 1.0
				lp += (w - lp) * 0.4
				lp2 += (lp - lp2) * 0.15
				var env := minf(t / 0.01, 1.0) * exp(-t * 6.0)
				ph += TAU * (250.0 + 900.0 * t) / rate
				f[i] = (lp - lp2) * 2.0 * env + sin(ph) * 0.18 * exp(-t * 9.0)
			gain = 0.7
		"whoosh":
			for i in n:
				var t := float(i) / rate
				var w := rng.randf() * 2.0 - 1.0
				var c := 0.04 + 0.35 * sin(PI * t / dur)
				lp += (w - lp) * c
				f[i] = lp * sin(PI * t / dur)
			gain = 0.45
		"poof":
			for i in n:
				var t := float(i) / rate
				var w := rng.randf() * 2.0 - 1.0
				lp += (w - lp) * 0.2
				f[i] = lp * minf(t / 0.01, 1.0) * exp(-t * 14.0)
			gain = 0.35
		"blip":
			for i in n:
				var t := float(i) / rate
				ph += TAU * freq * (1.0 + 0.06 * t / 0.07) / rate
				f[i] = (sin(ph) * 0.7 + sin(ph * 2.0) * 0.2 + sin(ph * 3.0) * 0.1) * minf(t / 0.004, 1.0) * exp(-t * 28.0)
			gain = 0.45
		"step_sand":
			for i in n:
				var t := float(i) / rate
				var w := rng.randf() * 2.0 - 1.0
				lp += (w - lp) * 0.2
				f[i] = lp * minf(t / 0.012, 1.0) * exp(-t * 28.0)
			gain = 0.4
		"step_grass":
			for i in n:
				var t := float(i) / rate
				var w := rng.randf() * 2.0 - 1.0
				lp += (w - lp) * 0.5
				lp2 += (lp - lp2) * 0.1
				f[i] = (lp - lp2) * minf(t / 0.006, 1.0) * exp(-t * 36.0)
			gain = 0.4
		"step_wood":
			var base := 110.0 + 18.0 * fmod(freq, 3.0)
			for i in n:
				var t := float(i) / rate
				var w := rng.randf() * 2.0 - 1.0
				lp += (w - lp) * 0.3
				f[i] = sin(TAU * base * t) * exp(-t * 38.0) + sin(TAU * base * 2.7 * t) * 0.3 * exp(-t * 60.0) + lp * 0.3 * exp(-t * 120.0)
			gain = 0.5
		"step_stone":
			var base := 80.0 + 12.0 * fmod(freq, 3.0)
			for i in n:
				var t := float(i) / rate
				var w := rng.randf() * 2.0 - 1.0
				lp += (w - lp) * 0.6
				lp2 += (lp - lp2) * 0.3
				f[i] = sin(TAU * base * t) * exp(-t * 45.0) + (lp - lp2) * 0.9 * exp(-t * 100.0) + sin(TAU * 410.0 * t) * 0.15 * exp(-t * 70.0)
			gain = 0.5
		"step_snow":
			for i in n:
				var t := float(i) / rate
				var w := rng.randf() * 2.0 - 1.0
				lp += (w - lp) * 0.45
				var crunch := 0.4 + 0.6 * absf(sin(TAU * 70.0 * t + rng.randf() * 0.3))
				f[i] = lp * crunch * minf(t / 0.01, 1.0) * exp(-t * 16.0)
			gain = 0.4
		"land":
			for i in n:
				var t := float(i) / rate
				var w := rng.randf() * 2.0 - 1.0
				lp += (w - lp) * 0.1
				f[i] = sin(TAU * 68.0 * t) * exp(-t * 22.0) + lp * 0.5 * exp(-t * 40.0)
			gain = 0.6
		"jump":
			for i in n:
				var t := float(i) / rate
				ph += TAU * (300.0 + 450.0 * t / 0.18) / rate
				f[i] = sin(ph) * exp(-t * 14.0) * minf(t / 0.008, 1.0)
			gain = 0.3
		"marimba":
			for i in n:
				var t := float(i) / rate
				f[i] = sin(TAU * freq * t) * exp(-t * 4.5) + sin(TAU * freq * 4.0 * t) * 0.28 * exp(-t * 15.0) + sin(TAU * freq * 9.9 * t) * 0.06 * exp(-t * 35.0)
			gain = 0.7
		"pluck":
			# Corde pincée (Karplus-Strong)
			var ln := maxi(int(rate / maxf(freq, 40.0)), 2)
			var buf := PackedFloat32Array()
			buf.resize(ln)
			for i in ln:
				buf[i] = rng.randf() * 2.0 - 1.0
			for pass_i in 3:
				for i in ln:
					buf[i] = (buf[i] + buf[(i + 1) % ln]) * 0.5
			var idx := 0
			for i in n:
				var nxt := (idx + 1) % ln
				var v := (buf[idx] + buf[nxt]) * 0.5 * 0.9965
				buf[idx] = v
				idx = nxt
				f[i] = v
			gain = 0.7
		"pad":
			for i in n:
				var t := float(i) / rate
				var env := sin(PI * t / dur)
				env *= env
				var s := sin(TAU * freq * t) + sin(TAU * freq * 1.004 * t) * 0.8 + sin(TAU * freq * 0.5 * t) * 0.7 + sin(TAU * freq * 2.0 * t) * 0.18 + sin(TAU * freq * 1.5 * t) * 0.2
				f[i] = s * env
			gain = 0.5
		"drip":
			for i in n:
				var t := float(i) / rate
				ph += TAU * (1100.0 + 900.0 * exp(-t * 40.0)) / rate
				var s := sin(ph) * exp(-t * 30.0)
				var t2 := t - 0.13
				if t2 > 0.0:
					s += sin(TAU * 1050.0 * t2) * exp(-t2 * 40.0) * 0.25
				f[i] = s
			gain = 0.45
		"croak":
			for i in n:
				var t := float(i) / rate
				ph += TAU * (150.0 + 40.0 * sin(TAU * 6.0 * t)) / rate
				var am := 0.55 + 0.45 * sin(TAU * 30.0 * t)
				f[i] = (sin(ph) + 0.5 * sin(ph * 2.0) + 0.25 * sin(ph * 3.0)) * am * sin(PI * t / dur)
			gain = 0.5
		"baa":
			# Bêlement : voix nasale qui tremble
			for i in n:
				var t := float(i) / rate
				var f0 := 300.0 + 40.0 * sin(TAU * 5.0 * t) - 40.0 * t
				ph += TAU * f0 / rate
				var s := 0.0
				for k in range(1, 9):
					var form := exp(-pow((k * f0 - 1000.0) / 600.0, 2.0))
					s += sin(ph * k) * form / float(k)
				f[i] = s * (0.55 + 0.45 * sin(TAU * 26.0 * t)) * minf(t / 0.05, 1.0) * sin(PI * minf(t / dur, 1.0))
			gain = 0.55
		"cluck":
			for i in n:
				var t := float(i) / rate
				var u := fmod(t, 0.13)
				var fr := 900.0 - 3000.0 * u
				ph += TAU * maxf(fr, 300.0) / rate
				f[i] = (sin(ph) + 0.5 * sin(ph * 2.0)) * (sin(PI * u / 0.1) if u < 0.1 else 0.0) * (1.0 if t < 0.26 else 0.0)
			gain = 0.5
		"oink":
			for i in n:
				var t := float(i) / rate
				var f0 := 140.0 - 40.0 * t + 15.0 * sin(TAU * 25.0 * t)
				ph += TAU * f0 / rate
				var w := rng.randf() * 2.0 - 1.0
				lp += (w - lp) * 0.2
				var s := 0.0
				for k in range(1, 8):
					s += sin(ph * k) * exp(-pow((k * f0 - 500.0) / 400.0, 2.0)) / float(k)
				f[i] = (s + lp * 0.3) * (0.6 + 0.4 * sin(TAU * 22.0 * t)) * sin(PI * t / dur)
			gain = 0.55
		"squeak":
			for i in n:
				var t := float(i) / rate
				var fr := 1900.0 + 700.0 * sin(PI * t / 0.22) + 120.0 * sin(TAU * 30.0 * t)
				ph += TAU * fr / rate
				f[i] = (sin(ph) + 0.3 * sin(ph * 2.0)) * sin(PI * t / dur)
			gain = 0.45
		"boing":
			for i in n:
				var t := float(i) / rate
				var fr := 220.0 + 260.0 * exp(-t * 6.0) + 60.0 * sin(TAU * 14.0 * t) * exp(-t * 4.0)
				ph += TAU * fr / rate
				f[i] = (sin(ph) + 0.4 * sin(ph * 2.0)) * exp(-t * 6.0)
			gain = 0.55
		"meow":
			for i in n:
				var t := float(i) / rate
				var f0 := 480.0 + 380.0 * sin(PI * minf(t / 0.6, 1.0)) * 1.0 - 120.0 * t
				ph += TAU * f0 / rate
				var s := 0.0
				for k in range(1, 9):
					s += sin(ph * k) * exp(-pow((k * f0 - (900.0 + 800.0 * t)) / 500.0, 2.0)) / float(k)
				f[i] = s * minf(t / 0.06, 1.0) * sin(PI * minf(t / dur, 1.0))
			gain = 0.5
		"ding":
			for i in n:
				var t := float(i) / rate
				f[i] = (sin(TAU * 1568.0 * t) + 0.4 * sin(TAU * 3136.0 * t) + 0.2 * sin(TAU * 4700.0 * t)) * exp(-t * 5.0)
			gain = 0.5
		_:
			pass
	return _pack(f, rate, gain)


static func _pack(f: PackedFloat32Array, rate: int, gain: float) -> AudioStreamWAV:
	var n := f.size()
	var peak := 0.0001
	for i in n:
		peak = maxf(peak, absf(f[i]))
	var k := gain / peak
	var data := PackedByteArray()
	data.resize(n * 2)
	var fo := maxi(int(rate * 0.01), 2)
	for i in n:
		var v := f[i] * k
		if i < 16:
			v *= float(i) / 16.0
		if i > n - fo:
			v *= float(n - i) / fo
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	return w


## Joue un son à un endroit du monde (spatialisé : en VR on entend d'où il vient).
static func play(world: Node, kind: String, freq: float, pos: Vector3, vol_db := 0.0) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.stream = wav(kind, freq)
	p.volume_db = vol_db
	p.unit_size = 7.0
	p.max_distance = 80.0
	if AudioServer.get_bus_index("Effets") >= 0:
		p.bus = "Effets"
	world.add_child(p)
	p.global_position = pos
	p.finished.connect(p.queue_free)
	p.play()
	return p
