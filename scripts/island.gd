extends Node3D
## L'île : relief généré (plage, prairie, colline), mer animée et collisions.
## La fonction height() sert aussi à poser les objets au sol.

const Toon := preload("res://scripts/toon.gd")
const WATER_SHADER := preload("res://shaders/water.gdshader")

const R := 52.0                            # rayon moyen de l'île
const HOUSE_POS := Vector2(0.0, -12.0)     # (x, z) de la maison
const HOUSE_H := 2.6                       # hauteur du terrain aplani sous la maison
const SPAWN := Vector2(0.0, 12.0)          # point de départ
const HILL := Vector2(-26.0, 4.0)          # la colline

const SIZE := 160.0
const RES := 160

static var _noise: FastNoiseLite


static func noise() -> FastNoiseLite:
	if _noise == null:
		_noise = FastNoiseLite.new()
		_noise.seed = 1234
		_noise.frequency = 0.02
	return _noise


static func height(x: float, z: float) -> float:
	var n := noise()
	var p := Vector2(x, z)
	var r := p.length()
	var ang := atan2(z, x)
	var edge := R + n.get_noise_2d(cos(ang) * 60.0, sin(ang) * 60.0) * 12.0
	var t := r / edge
	var h := 3.0 * (1.0 - smoothstep(0.45, 1.0, t)) - 1.4 * smoothstep(0.85, 1.3, t) - 4.0 * smoothstep(1.2, 1.8, t) - 0.3
	var inland := 1.0 - smoothstep(0.5, 0.8, t)
	h += n.get_noise_2d(x * 2.0, z * 2.0) * 0.8 * inland
	h += 7.0 * exp(-p.distance_squared_to(HILL) / 160.0)
	var w := 1.0 - smoothstep(9.0, 15.0, p.distance_to(HOUSE_POS))
	return lerpf(h, HOUSE_H, w)


static func ground(x: float, z: float) -> Vector3:
	return Vector3(x, height(x, z), z)


static func _color(h: float, x: float, z: float) -> Color:
	var sand := Color(1.0, 0.92, 0.72)
	var wet := Color(0.88, 0.74, 0.5)
	var grass_a := Color(0.5, 0.78, 0.42)
	var grass_b := Color(0.64, 0.86, 0.46)
	var rock := Color(0.62, 0.56, 0.52)
	var path := Color(0.93, 0.8, 0.6)
	if h < -0.15:
		return wet.darkened(clampf(-h * 0.08, 0.0, 0.45))
	var g := grass_a.lerp(grass_b, (noise().get_noise_2d(x * 5.0, z * 5.0) + 1.0) * 0.5)
	var c := sand.lerp(g, smoothstep(0.7, 1.2, h))
	c = c.lerp(rock, smoothstep(6.0, 8.0, h))
	# Chemin de terre entre le départ et la porte
	if absf(x) < 1.6 and z > HOUSE_POS.y + 3.5 and z < SPAWN.y + 1.0:
		c = path
	return c


func build() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step := SIZE / RES
	var half := SIZE * 0.5
	for j in RES + 1:
		for i in RES + 1:
			var x := -half + i * step
			var z := -half + j * step
			var h := height(x, z)
			st.set_color(_color(h, x, z))
			st.add_vertex(Vector3(x, h, z))
	var row := RES + 1
	for j in RES:
		for i in RES:
			var a := j * row + i
			var b := a + 1
			var c := a + row
			var d := c + 1
			st.add_index(a)
			st.add_index(b)
			st.add_index(c)
			st.add_index(b)
			st.add_index(d)
			st.add_index(c)
	st.generate_normals()
	var mesh := st.commit()

	var mi := MeshInstance3D.new()
	mi.name = "Terrain"
	mi.mesh = mesh
	mi.material_override = Toon.vertex_color()
	add_child(mi)

	var body := StaticBody3D.new()
	body.name = "TerrainCollision"
	add_child(body)
	var cs := CollisionShape3D.new()
	cs.shape = mesh.create_trimesh_shape()
	body.add_child(cs)

	# La mer
	var sea := MeshInstance3D.new()
	sea.name = "Sea"
	var pm := PlaneMesh.new()
	pm.size = Vector2(1200, 1200)
	pm.subdivide_width = 90
	pm.subdivide_depth = 90
	sea.mesh = pm
	var wm := ShaderMaterial.new()
	wm.shader = WATER_SHADER
	wm.set_shader_parameter("shore_radius", R)
	sea.material_override = wm
	sea.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sea)
