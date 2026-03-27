extends Area2D
class_name DroppedLoot

signal picked_up(loot: DroppedLoot)

var resource_type: ResourceNode.ResourceType = ResourceNode.ResourceType.GOLD
var amount: int = 0
var _anim_time: float = 0.0
var _color: Color = Color.GOLD

const PICKUP_RADIUS := 25.0
const DESPAWN_TIME := 30.0
var _lifetime: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	_create_collision_shape()
	match resource_type:
		ResourceNode.ResourceType.SILVER:
			_color = Color(0.7, 0.72, 0.75)
		ResourceNode.ResourceType.GOLD:
			_color = Color(0.95, 0.8, 0.15)
		ResourceNode.ResourceType.GEM:
			_color = Color(0.3, 0.8, 0.95)


func setup(res_type: ResourceNode.ResourceType, res_amount: int) -> void:
	resource_type = res_type
	amount = res_amount
	match resource_type:
		ResourceNode.ResourceType.SILVER:
			_color = Color(0.7, 0.72, 0.75)
		ResourceNode.ResourceType.GOLD:
			_color = Color(0.95, 0.8, 0.15)
		ResourceNode.ResourceType.GEM:
			_color = Color(0.3, 0.8, 0.95)


func _create_collision_shape() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = PICKUP_RADIUS
	shape.shape = circle
	add_child(shape)


func _process(delta: float) -> void:
	_anim_time += delta
	_lifetime += delta
	if _lifetime >= DESPAWN_TIME:
		queue_free()
		return

	var units := get_tree().get_nodes_in_group("player_units")
	for unit in units:
		if is_instance_valid(unit) and global_position.distance_to(unit.global_position) < PICKUP_RADIUS:
			_collect()
			return

	queue_redraw()


func _collect() -> void:
	match resource_type:
		ResourceNode.ResourceType.SILVER, ResourceNode.ResourceType.GOLD:
			GameManager.add_gold(amount)
		ResourceNode.ResourceType.GEM:
			GameManager.add_gems(amount)
	picked_up.emit(self)
	queue_free()


func _draw() -> void:
	var bob := sin(_anim_time * 3.0) * 2.0
	var flash := 0.8 + sin(_anim_time * 4.0) * 0.2
	draw_circle(Vector2(0, bob), 10, Color(_color.r, _color.g, _color.b, 0.2 * flash))
	var bag := PackedVector2Array([
		Vector2(-6, 3 + bob), Vector2(-5, -3 + bob), Vector2(0, -6 + bob),
		Vector2(5, -3 + bob), Vector2(6, 3 + bob)])
	draw_colored_polygon(bag, Color(0.55, 0.4, 0.2))
	draw_line(Vector2(-2, -5 + bob), Vector2(2, -5 + bob), Color(0.4, 0.28, 0.12), 2.0)
	draw_circle(Vector2(0, -2 + bob), 3, _color * flash)
