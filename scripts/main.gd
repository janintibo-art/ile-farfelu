extends Node3D
## Point d'entrée : démarre la VR (ou le mode PC si pas de casque),
## construit le ciel, l'île, la maison, le décor, les objets et les persos.

const Island := preload("res://scripts/island.gd")
const House := preload("res://scripts/house.gd")
const Decor := preload("res://scripts/decor.gd")
const Props := preload("res://scripts/props.gd")
const Player := preload("res://scripts/player.gd")
const Npc := preload("res://scripts/npc.gd")
const Fx := preload("res://scripts/fx.gd")

var vr := false
var xr_interface: XRInterface
var player


func _ready() -> void:
	randomize()
	vr = _start_xr()
	_environment()

	var island := Island.new()
	island.name = "Island"
	add_child(island)
	island.build()

	var house := House.new()
	house.name = "House"
	add_child(house)
	house.build()

	player = Player.new()
	player.name = "Player"
	add_child(player)
	player.global_position = Island.ground(Island.SPAWN.x, Island.SPAWN.y) + Vector3(0, 0.1, 0)
	player.setup(self, vr)
	house.player = player

	var palms: Array = Decor.build(self, player)
	Props.spawn_all(self, house, palms)

	var spots := [Vector2(-3.5, 6.0), Vector2(4.0, 4.0)]
	for i in 2:
		var npc := Npc.new()
		npc.name = "Npc%d" % (i + 1)
		add_child(npc)
		npc.global_position = Island.ground(spots[i].x, spots[i].y) + Vector3(0, 0.2, 0)
		npc.setup(player, i + 1)
		player.npcs.append(npc)

	# Petit message de bienvenue devant soi
	await get_tree().create_timer(1.0).timeout
	Fx.text(self, player.global_position + Vector3(0, 1.8, -2.5), "Bienvenue sur l'Île Farfelue !", Color(1.0, 0.85, 0.25), 0.8, 4.0)


func _start_xr() -> bool:
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		get_viewport().use_xr = true
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		if xr_interface.has_signal("session_begun"):
			xr_interface.connect("session_begun", _on_session_begun)
		print("Île Farfelue : casque VR détecté")
		return true
	print("Île Farfelue : pas de casque, mode PC")
	return false


func _on_session_begun() -> void:
	var rate := 0.0
	if xr_interface.has_method("get_display_refresh_rate"):
		rate = xr_interface.call("get_display_refresh_rate")
	if rate <= 0.0:
		rate = 72.0 if OS.has_feature("android") else 90.0
	Engine.physics_ticks_per_second = int(round(rate))


func _environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.22, 0.52, 1.0)
	sm.sky_horizon_color = Color(0.72, 0.9, 1.0)
	sm.ground_horizon_color = Color(0.72, 0.9, 1.0)
	sm.ground_bottom_color = Color(0.2, 0.45, 0.8)
	sm.sky_curve = 0.12
	sm.sun_angle_max = 12.0
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.82, 0.84, 1.0)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = true
	env.fog_light_color = Color(0.75, 0.88, 1.0)
	env.fog_density = 0.0035
	env.fog_sky_affect = 0.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.light_energy = 0.55
	sun.shadow_enabled = not OS.has_feature("android")
	sun.directional_shadow_max_distance = 40.0
	add_child(sun)
