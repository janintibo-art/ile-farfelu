extends RefCounted
## Fabrique de matériaux "toon" partagés (un seul exemplaire par réglage,
## pour garder peu d'appels de dessin sur le Quest 2).

const TOON_SHADER := preload("res://shaders/toon.gdshader")
const OUTLINE_SHADER := preload("res://shaders/outline.gdshader")
const UNLIT_SHADER := preload("res://shaders/unlit.gdshader")

static var _cache: Dictionary = {}


## Matériau qui prend la couleur de chaque sommet (maillages fusionnés).
static func vertex_color(outline: float = 0.0) -> ShaderMaterial:
	var key := "vc_%.4f" % outline
	if _cache.has(key):
		return _cache[key]
	var m := ShaderMaterial.new()
	m.shader = TOON_SHADER
	m.set_shader_parameter("use_vertex_color", true)
	if outline > 0.0:
		m.next_pass = _outline(outline)
		m.set_shader_parameter("rim_amount", 0.22)
		m.set_shader_parameter("gloss", 0.7)
	_cache[key] = m
	return m


## Matériau d'une seule couleur.
static func flat(c: Color, outline: float = 0.0) -> ShaderMaterial:
	var key := "c_%s_%.4f" % [c.to_html(), outline]
	if _cache.has(key):
		return _cache[key]
	var m := ShaderMaterial.new()
	m.shader = TOON_SHADER
	m.set_shader_parameter("albedo", c)
	if outline > 0.0:
		m.next_pass = _outline(outline)
		m.set_shader_parameter("rim_amount", 0.22)
	_cache[key] = m
	return m


## Couleur pure, sans lumière (rayon de visée).
static func unlit(c: Color) -> ShaderMaterial:
	var key := "u_%s" % c.to_html()
	if _cache.has(key):
		return _cache[key]
	var m := ShaderMaterial.new()
	m.shader = UNLIT_SHADER
	m.set_shader_parameter("color", c)
	_cache[key] = m
	return m


static func _outline(thickness: float) -> ShaderMaterial:
	var key := "o_%.4f" % thickness
	if _cache.has(key):
		return _cache[key]
	var o := ShaderMaterial.new()
	o.shader = OUTLINE_SHADER
	o.set_shader_parameter("thickness", thickness)
	_cache[key] = o
	return o
