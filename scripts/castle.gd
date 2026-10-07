extends Node3D
## Le Château des Versions Officielles, perché sur sa montagne au loin.
## Visible depuis presque toute l'île, mais inaccessible pour l'instant.

const Toon := preload("res://scripts/toon.gd")
const Builder := preload("res://scripts/builder.gd")

const POS := Vector3(-30.0, 0.0, -230.0)

var window_light: MeshInstance3D


func build() -> void:
	position = POS
	var b := Builder.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	# La montagne : un gros cône rocheux, avec des corniches et de la verdure
	var rock := Color(0.52, 0.5, 0.6)
	b.cylinder(14.0, 70.0, 30.0, Vector3(0, 13.0, 0), rock.darkened(0.1), Basis(), 20)
	b.cylinder(6.0, 26.0, 40.0, Vector3(0, 46.0, 0), rock, Basis(), 18)
	for k in 14:
		var a := rng.randf() * TAU
		var r := rng.randf_range(16.0, 48.0)
		var y := 30.0 - r * 0.55 + rng.randf_range(-3.0, 3.0)
		b.sphere(rng.randf_range(6.0, 11.0), Vector3(cos(a) * r, maxf(y, 2.0), sin(a) * r), Color(0.35, 0.6, 0.38).darkened(rng.randf() * 0.2), Vector3(1.0, 0.5, 1.0), Basis(), 10)
	for k in 10:
		var a := rng.randf() * TAU
		b.sphere(rng.randf_range(4.0, 8.0), Vector3(cos(a) * 22.0, rng.randf_range(30.0, 50.0), sin(a) * 22.0) * Vector3(0.6, 1.0, 0.6), rock.lightened(0.05), Vector3(1.0, 0.7, 1.0), Basis(), 8)
	# Le château au sommet
	var top := Vector3(0, 66.0, 0)
	var wall := Color(0.9, 0.88, 0.95)
	var roof := Color(0.32, 0.3, 0.7)
	b.cylinder(12.0, 13.0, 4.0, top + Vector3(0, 0, 0), rock.lightened(0.1), Basis(), 18)
	b.box(Vector3(16.0, 7.0, 12.0), top + Vector3(0, 5.5, 0), wall)
	b.box(Vector3(8.0, 10.0, 8.0), top + Vector3(0, 12.0, -1.0), wall.darkened(0.04))
	b.prism(Vector3(9.0, 6.0, 9.0), top + Vector3(0, 20.0, -1.0), roof)
	for p in [Vector3(-8, 0, -6), Vector3(8, 0, -6), Vector3(-8, 0, 6), Vector3(8, 0, 6), Vector3(0, 0, 8.5)]:
		var h := 12.0 if p.z < 0.0 else 10.0
		b.cylinder(2.0, 2.2, h, top + p + Vector3(0, h * 0.5, 0), wall, Basis(), 12)
		b.cylinder(0.0, 2.8, 5.0, top + p + Vector3(0, h + 2.5, 0), roof, Basis(), 12)
		b.box(Vector3(0.1, 1.6, 0.1), top + p + Vector3(0, h + 5.5, 0), Color(0.3, 0.3, 0.3), false)
		b.box(Vector3(1.4, 0.8, 0.05), top + p + Vector3(0.7, h + 5.8, 0), Color(0.95, 0.85, 0.3), false)
	# Fenêtres sombres
	for k in 5:
		b.box(Vector3(0.9, 1.6, 0.2), top + Vector3(-5.0 + k * 2.5, 6.0, 6.05), Color(0.15, 0.13, 0.25), false)
	b.box(Vector3(2.5, 3.5, 0.2), top + Vector3(0, 3.5, 6.05), Color(0.35, 0.25, 0.2), false)
	var mi := b.build(self, Toon.vertex_color(), "Castle")
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Une fenêtre qui pourra s'allumer plus tard dans l'histoire
	window_light = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.2, 2.0, 0.1)
	window_light.mesh = bm
	window_light.material_override = Toon.unlit(Color(1.0, 0.85, 0.4))
	window_light.position = top + Vector3(0, 14.0, 3.1)
	window_light.visible = false
	add_child(window_light)
