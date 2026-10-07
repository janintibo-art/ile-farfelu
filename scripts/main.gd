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
const Save := preload("res://scripts/save.gd")
const Shop := preload("res://scripts/shop.gd")
const Shells := preload("res://scripts/shells.gd")
const Gate := preload("res://scripts/gate.gd")
const Dungeon := preload("res://scripts/dungeon.gd")
const Shore := preload("res://scripts/shore.gd")
const Fishing := preload("res://scripts/fishing.gd")
const InventoryPanel := preload("res://scripts/inventory_panel.gd")
const Prologue := preload("res://scripts/prologue.gd")
const Pico := preload("res://scripts/pico.gd")
const Castle := preload("res://scripts/castle.gd")
const Grass := preload("res://scripts/grass.gd")
const Ambience := preload("res://scripts/ambience.gd")
const Village := preload("res://scripts/village.gd")
const SKY_SHADER := preload("res://shaders/sky.gdshader")

var vr := false
var xr_interface: XRInterface
var player
var env: Environment
var sun: DirectionalLight3D


func _ready() -> void:
	randomize()
	Save.load_game()
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

	var shop := Shop.new()
	shop.name = "Shop"
	add_child(shop)
	shop.build(self, player)
	player.shop = shop

	var shells := Shells.new()
	shells.name = "Shells"
	add_child(shells)
	shells.build(player)

	var gate := Gate.new()
	gate.name = "DungeonGate"
	add_child(gate)
	gate.build(self, player)
	var dungeon := Dungeon.new()
	dungeon.name = "Dungeon"
	add_child(dungeon)
	dungeon.build(self, player)
	player.gate = gate
	player.dungeon = dungeon
	player.main = self

	var shore := Shore.new()
	shore.name = "Shore"
	add_child(shore)
	shore.build(self, player)
	player.shore = shore
	var fishing := Fishing.new()
	fishing.name = "Fishing"
	add_child(fishing)
	fishing.setup(player, shore)
	player.fishing = fishing
	var bag := InventoryPanel.new()
	bag.name = "Inventory"
	add_child(bag)
	bag.setup(player)
	player.inventory = bag

	# --- L'histoire : le Château au loin, Pico, la Plage des Bagages Perdus ---
	var castle := Castle.new()
	castle.name = "Castle"
	add_child(castle)
	castle.build()
	var pico := Pico.new()
	pico.name = "Pico"
	add_child(pico)
	pico.build(player)
	player.pico = pico
	var prologue := Prologue.new()
	prologue.name = "Prologue"
	add_child(prologue)
	prologue.build(self, player, pico)
	if not Save.story.get("bridge", false):
		player.global_position = Prologue.start_position()
		player._place_origin(true, 0.0)
	var village := Village.new()
	village.name = "Village"
	add_child(village)
	village.build(self, player)
	player.village = village
	Grass.build(self, [
		[Island.HOUSE_POS, 8.0], [Island.SHOP_POS, 7.0], [Island.GATE_POS, 6.0],
		[Island.SPAWN, 3.5], [Island.pier_base(), 6.0],
	])
	var amb := Ambience.new()
	amb.name = "Ambience"
	add_child(amb)
	amb.setup(player)
	player.refresh_sword()
	if not Save.story.get("woke", false):
		prologue.wake_up()
		return

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
	# Quest 3 : on demande l'affichage en 90 Hz (plus fluide)
	if xr_interface.has_method("get_available_display_refresh_rates"):
		var rates: Array = xr_interface.call("get_available_display_refresh_rates")
		if 90.0 in rates:
			xr_interface.set("display_refresh_rate", 90.0)
	var rate := 0.0
	if xr_interface.has_method("get_display_refresh_rate"):
		rate = xr_interface.call("get_display_refresh_rate")
	if rate <= 0.0:
		rate = 72.0 if OS.has_feature("android") else 90.0
	Engine.physics_ticks_per_second = int(round(rate))


func _environment() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ShaderMaterial.new()
	sm.shader = SKY_SHADER
	sky.sky_material = sm
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.82, 0.84, 1.0)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = true
	env.fog_light_color = Color(0.75, 0.88, 1.0)
	env.fog_density = 0.0028
	env.fog_sky_affect = 0.0
	env.fog_aerial_perspective = 0.4
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.light_energy = 0.55
	# Quest 3 : ombres temps réel, nettes et douces
	sun.shadow_enabled = true
	sun.shadow_opacity = 0.85
	sun.shadow_blur = 1.5
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 30.0
	sun.shadow_bias = 0.04
	sun.shadow_normal_bias = 1.5
	add_child(sun)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		Save.save_game()


## Ambiance sombre et violette dans le donjon, soleil éteint.
func set_dungeon_mood(on: bool) -> void:
	sun.visible = not on
	if on:
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.08, 0.05, 0.12)
		env.ambient_light_color = Color(0.75, 0.68, 1.0)
		env.ambient_light_energy = 0.95
		env.fog_light_color = Color(0.16, 0.1, 0.24)
		env.fog_density = 0.018
	else:
		env.background_mode = Environment.BG_SKY
		env.ambient_light_color = Color(0.82, 0.84, 1.0)
		env.ambient_light_energy = 0.7
		env.fog_light_color = Color(0.75, 0.88, 1.0)
		env.fog_density = 0.0035
