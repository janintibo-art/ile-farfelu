extends RefCounted
## Effets manga : onomatopées qui surgissent ("POUF !", "BONK !"...) et
## petits nuages de fumée.

const Toon := preload("res://scripts/toon.gd")

const INK := Color(0.13, 0.08, 0.17)


static func text(parent: Node, pos: Vector3, txt: String, col := Color(1.0, 0.85, 0.2), size := 1.0, life := 1.2) -> Label3D:
	var l := Label3D.new()
	l.text = txt
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.font_size = 128
	l.outline_size = 36
	l.modulate = col
	l.outline_modulate = INK
	l.pixel_size = 0.003 * size
	l.render_priority = 10
	l.outline_render_priority = 9
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.width = 900.0
	parent.add_child(l)
	l.global_position = pos
	l.scale = Vector3.ONE * 0.2
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector3.ONE * 1.25, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "scale", Vector3.ONE, 0.1)
	tw.parallel().tween_property(l, "position", l.position + Vector3(0, 0.45, 0), life)
	tw.tween_property(l, "modulate:a", 0.0, 0.25)
	tw.parallel().tween_property(l, "outline_modulate:a", 0.0, 0.25)
	tw.tween_callback(l.queue_free)
	return l


static func puff(parent: Node, pos: Vector3, col := Color(1, 1, 1)) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.amount = 18
	p.lifetime = 0.7
	p.explosiveness = 0.95
	var m := SphereMesh.new()
	m.radius = 0.12
	m.height = 0.24
	m.radial_segments = 8
	m.rings = 4
	p.mesh = m
	p.material_override = Toon.flat(col)
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = 1.2
	p.initial_velocity_max = 2.8
	p.gravity = Vector3(0, 0.8, 0)
	p.damping_min = 2.0
	p.damping_max = 3.0
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.6
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	p.scale_amount_curve = curve
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	var tw := p.create_tween()
	tw.tween_interval(1.2)
	tw.tween_callback(p.queue_free)
