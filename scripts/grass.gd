extends RefCounted
## Herbe : des milliers de petites touffes dessinées en une seule fois
## (MultiMesh), qui ondulent dans le vent. Réservé au Quest 3.

const Island := preload("res://scripts/island.gd")
const GRASS_SHADER := preload("res://shaders/grass.gdshader")

const COUNT := 9000


static func _tuft() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 5:
		var a := k * TAU / 5.0 + 0.3
		var d := Vector3(cos(a), 0, sin(a))
		var side := Vector3(-d.z, 0, d.x) * 0.035
		var lean := d * (0.08 + 0.04 * (k % 2))
		var h := 0.3 + 0.1 * float(k % 3)
		st.add_vertex(-side)
		st.add_vertex(side)
		st.add_vertex(lean + Vector3(0, h, 0))
	st.generate_normals()
	return st.commit()


static func build(world: Node3D, avoid: Array) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	var xforms: Array[Transform3D] = []
	var tries := 0
	while xforms.size() < COUNT and tries < COUNT * 6:
		tries += 1
		var x := rng.randf_range(-55.0, 55.0)
		var z := rng.randf_range(-55.0, 55.0)
		var h := Island.height(x, z)
		if h < 1.25 or h > 6.5:
			continue
		var p := Vector2(x, z)
		var skip := false
		for a in avoid:
			if p.distance_to(a[0]) < a[1]:
				skip = true
				break
		if skip or Island.is_path(x, z):
			continue
		var s := rng.randf_range(0.7, 1.4)
		xforms.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * rng.randf_range(0.8, 1.3), s)), Vector3(x, h - 0.03, z)))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _tuft()
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Grass"
	mmi.multimesh = mm
	var mat := ShaderMaterial.new()
	mat.shader = GRASS_SHADER
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(mmi)
