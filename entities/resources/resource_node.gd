extends Area2D
class_name ResourceNode

signal depleted(node: ResourceNode)
signal harvested(node: ResourceNode)

enum ResourceType { SILVER, GOLD, GEM }

@export var resource_type: ResourceType = ResourceType.SILVER
@export var harvest_yield: int = 15
@export var max_charges: int = 5
@export var harvest_time: float = 2.0

var charges: int
var _is_depleted: bool = false
var _anim_time: float = 0.0

var _color: Color
var _glow_color: Color
var _label: String


func _ready() -> void:
	charges = max_charges
	collision_layer = 0
	collision_mask = 0
	_setup_visuals()
	_create_collision_shape()


func _setup_visuals() -> void:
	match resource_type:
		ResourceType.SILVER:
			_color = Color(0.7, 0.72, 0.75)
			_glow_color = Color(0.8, 0.82, 0.85, 0.3)
			_label = "Ag"
			harvest_yield = 12
			max_charges = 6
			harvest_time = 1.5
		ResourceType.GOLD:
			_color = Color(0.9, 0.75, 0.1)
			_glow_color = Color(1.0, 0.9, 0.3, 0.3)
			_label = "Au"
			harvest_yield = 25
			max_charges = 4
			harvest_time = 2.5
		ResourceType.GEM:
			_color = Color(0.3, 0.8, 0.95)
			_glow_color = Color(0.4, 0.9, 1.0, 0.4)
			_label = "Gem"
			harvest_yield = 1
			max_charges = 3
			harvest_time = 3.5
	charges = max_charges


func _create_collision_shape() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 20.0
	shape.shape = circle
	add_child(shape)


func _process(delta: float) -> void:
	_anim_time += delta
	queue_redraw()


func harvest() -> Dictionary:
	if _is_depleted:
		return {}
	charges -= 1
	var result := {"type": resource_type, "amount": harvest_yield}
	harvested.emit(self)
	if charges <= 0:
		_is_depleted = true
		depleted.emit(self)
	return result


func is_available() -> bool:
	return not _is_depleted


func _draw() -> void:
	if _is_depleted:
		_draw_depleted()
		return

	var pulse := 0.8 + sin(_anim_time * 2.0) * 0.2
	draw_circle(Vector2.ZERO, 22, _glow_color * pulse)
	var rock := PackedVector2Array([
		Vector2(-14, 5), Vector2(-10, -8), Vector2(-3, -12),
		Vector2(5, -10), Vector2(12, -5), Vector2(14, 6),
		Vector2(8, 10), Vector2(-8, 10)])
	draw_colored_polygon(rock, Color(0.4, 0.38, 0.35))
	match resource_type:
		ResourceType.SILVER:
			draw_line(Vector2(-6, -4), Vector2(-2, -9), _color, 3.0)
			draw_line(Vector2(2, -3), Vector2(6, -8), _color, 2.5)
			draw_line(Vector2(-1, 2), Vector2(3, -2), _color, 2.0)
		ResourceType.GOLD:
			draw_circle(Vector2(-4, -5), 4, _color)
			draw_circle(Vector2(3, -3), 3, _color)
			draw_circle(Vector2(0, 2), 3.5, _color.darkened(0.1))
		ResourceType.GEM:
			var crystal := PackedVector2Array([
				Vector2(-2, -12), Vector2(2, -12), Vector2(4, -4), Vector2(-4, -4)])
			draw_colored_polygon(crystal, _color)
			var crystal2 := PackedVector2Array([
				Vector2(3, -9), Vector2(7, -9), Vector2(8, -3), Vector2(2, -3)])
			draw_colored_polygon(crystal2, Color(0.2, 0.6, 0.85))
			draw_circle(Vector2(0, -8), 2, Color(1.0, 1.0, 1.0, 0.5 * pulse))

	var dot_start_x := -float(charges) * 3.0
	for i in range(charges):
		draw_circle(Vector2(dot_start_x + i * 6.0, 14), 2.0, _color)


func _draw_depleted() -> void:
	var rock := PackedVector2Array([
		Vector2(-14, 5), Vector2(-10, -8), Vector2(-3, -12),
		Vector2(5, -10), Vector2(12, -5), Vector2(14, 6),
		Vector2(8, 10), Vector2(-8, 10)])
	draw_colored_polygon(rock, Color(0.3, 0.28, 0.25, 0.4))
