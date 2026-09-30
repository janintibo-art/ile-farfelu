extends RefCounted
## Assemble plein de formes simples (boîtes, sphères, cônes...) en UN seul
## maillage coloré par sommet. Un objet complexe = un seul appel de dessin,
## c'est ce qui permet de garder un bon framerate sur le Quest 2.

var st := SurfaceTool.new()
var shapes: Array = []   # [Transform3D, Vector3 taille] pour les collisions en boîte
var empty := true


func _init() -> void:
	st.begin(Mesh.PRIMITIVE_TRIANGLES)


## Ajoute une forme primitive avec une couleur unie.
func add(mesh: PrimitiveMesh, xf: Transform3D, col: Color) -> void:
	var arr := mesh.get_mesh_arrays()
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var cols := PackedColorArray()
	cols.resize(verts.size())
	cols.fill(col)
	arr[Mesh.ARRAY_COLOR] = cols
	_append_arrays(arr, xf)


## Ajoute une forme primitive colorée sommet par sommet (fonction pos -> Color).
func add_painted(mesh: PrimitiveMesh, xf: Transform3D, painter: Callable) -> void:
	var arr := mesh.get_mesh_arrays()
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var cols := PackedColorArray()
	cols.resize(verts.size())
	for i in verts.size():
		cols[i] = painter.call(verts[i])
	arr[Mesh.ARRAY_COLOR] = cols
	_append_arrays(arr, xf)


## Ajoute un maillage déjà construit (par exemple un palmier entier).
func add_mesh(mesh: Mesh, xf: Transform3D) -> void:
	for s in mesh.get_surface_count():
		st.append_from(mesh, s, xf)
	empty = false


func _append_arrays(arr: Array, xf: Transform3D) -> void:
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	st.append_from(am, 0, xf)
	empty = false


# --- Formes pratiques -------------------------------------------------------

func box(size: Vector3, pos: Vector3, col: Color, collide := true, basis := Basis()) -> void:
	var m := BoxMesh.new()
	m.size = size
	var xf := Transform3D(basis, pos)
	add(m, xf, col)
	if collide:
		shapes.append([xf, size])


## Collision en boîte sans rien afficher.
func collider(size: Vector3, pos: Vector3, basis := Basis()) -> void:
	shapes.append([Transform3D(basis, pos), size])


func sphere(r: float, pos: Vector3, col: Color, scale := Vector3.ONE, basis := Basis(), segments := 12) -> void:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = segments
	m.rings = maxi(segments / 2, 3)
	add(m, Transform3D(basis * Basis.from_scale(scale), pos), col)


func cylinder(r_top: float, r_bottom: float, h: float, pos: Vector3, col: Color, basis := Basis(), segments := 10) -> void:
	var m := CylinderMesh.new()
	m.top_radius = r_top
	m.bottom_radius = r_bottom
	m.height = h
	m.radial_segments = segments
	m.rings = 1
	add(m, Transform3D(basis, pos), col)


func capsule(r: float, h: float, pos: Vector3, col: Color, basis := Basis(), scale := Vector3.ONE) -> void:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = maxf(h, r * 2.0)
	m.radial_segments = 12
	m.rings = 4
	add(m, Transform3D(basis * Basis.from_scale(scale), pos), col)


func prism(size: Vector3, pos: Vector3, col: Color, basis := Basis()) -> void:
	var m := PrismMesh.new()
	m.size = size
	add(m, Transform3D(basis, pos), col)


func torus(inner: float, outer: float, pos: Vector3, col: Color, basis := Basis()) -> void:
	var m := TorusMesh.new()
	m.inner_radius = inner
	m.outer_radius = outer
	m.rings = 16
	m.ring_segments = 8
	add(m, Transform3D(basis, pos), col)


## Cône orienté selon une direction (pointe vers dir).
func spike(r: float, h: float, pos: Vector3, dir: Vector3, col: Color) -> void:
	cylinder(0.0, r, h, pos, col, Basis(Quaternion(Vector3.UP, dir.normalized())), 8)


func commit() -> ArrayMesh:
	return st.commit()


## Crée le MeshInstance3D (et un StaticBody3D si des collisions ont été
## demandées) sous `parent`.
func build(parent: Node3D, mat: Material, node_name := "Mesh") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = st.commit()
	mi.material_override = mat
	parent.add_child(mi)
	if shapes.size() > 0:
		var body := StaticBody3D.new()
		body.name = node_name + "Collision"
		parent.add_child(body)
		for s in shapes:
			var cs := CollisionShape3D.new()
			var bs := BoxShape3D.new()
			bs.size = s[1]
			cs.shape = bs
			cs.transform = s[0]
			body.add_child(cs)
	return mi
