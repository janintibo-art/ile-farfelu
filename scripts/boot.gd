extends Node3D
## Démarrage minimal : démarre la VR, affiche un écran de diagnostic, vérifie que tous
## les scripts se chargent, puis lance le jeu. Rien n'est préchargé ici : si un script
## est cassé sur le casque, on le voit à l'écran au lieu d'un écran noir.

const VERSION := "v14"

var label: Label3D
var xr: XRInterface


func _ready() -> void:
	var vr := false
	xr = XRServer.find_interface("OpenXR")
	if xr and xr.is_initialized():
		get_viewport().use_xr = true
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		vr = true
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.2, 0.45, 0.75)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var cam: Camera3D
	var rig: Node3D = null
	if vr:
		rig = XROrigin3D.new()
		add_child(rig)
		cam = XRCamera3D.new()
		rig.add_child(cam)
	else:
		cam = Camera3D.new()
		add_child(cam)
		cam.current = true
	label = Label3D.new()
	cam.add_child(label)
	label.position = Vector3(0, 0, -1.6)
	label.font_size = 48
	label.pixel_size = 0.0014
	label.shaded = false
	label.no_depth_test = true
	label.outline_size = 12
	label.outline_modulate = Color(0.1, 0.05, 0.15)
	label.modulate = Color(1, 0.95, 0.6)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.width = 1100.0
	var head := "ÎLE FARFELUE %s\nVR : %s\nSystème : %s\n" % [VERSION, "OK (casque détecté)" if vr else "non démarrée", OS.get_name()]
	label.text = head + "Vérification des scripts…"
	await get_tree().process_frame
	await get_tree().process_frame

	var bad: Array = []
	var n := 0
	for f in _scripts():
		n += 1
		var s = load("res://scripts/" + f)
		if s == null or not s.can_instantiate():
			bad.append(f)
		if n % 10 == 0:
			label.text = head + "Vérification des scripts… %d" % n
			await get_tree().process_frame
	if bad.is_empty():
		label.text = head + "%d scripts OK\nDémarrage du jeu…" % n
	else:
		label.text = head + "SCRIPTS EN ERREUR :\n" + "\n".join(bad)
	await get_tree().create_timer(2.0 if bad.is_empty() else 12.0).timeout
	var ps = load("res://main.tscn")
	if ps == null:
		label.text = head + "main.tscn ne se charge pas"
		return
	var game = ps.instantiate()
	if game == null:
		label.text = head + "main.tscn ne s'instancie pas"
		return
	if rig:
		rig.queue_free()
	else:
		cam.queue_free()
	we.queue_free()
	add_child(game)
	await get_tree().process_frame
	if label and is_instance_valid(label):
		label.queue_free()


func _scripts() -> Array:
	var out: Array = []
	var d := DirAccess.open("res://scripts")
	if d == null:
		return out
	for f in d.get_files():
		var g := f.trim_suffix(".remap")
		if g.ends_with(".gd") and g != "boot.gd" and g != "main.gd" and not out.has(g):
			out.append(g)
	out.sort()
	out.append("main.gd")
	return out
