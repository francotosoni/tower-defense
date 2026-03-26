extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 350.0
var damage: int = 15
var aoe_radius: float = 90.0
var _max_range: float = 350.0
var _traveled: float = 0.0
var _target_pos: Vector2


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 6.0
	shape.shape = circle
	add_child(shape)
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 8.0, Color(0.6, 0.2, 0.9, 0.8))
	draw_circle(Vector2.ZERO, 4.0, Color(0.9, 0.6, 1.0))


func setup(target_position: Vector2) -> void:
	_target_pos = target_position
	direction = (target_position - global_position).normalized()


func _physics_process(delta: float) -> void:
	var movement := direction * speed * delta * GameManager.game_speed
	position += movement
	_traveled += movement.length()

	if global_position.distance_to(_target_pos) < 20.0 or _traveled >= _max_range:
		_explode()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		_explode()


func _explode() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy):
			if global_position.distance_to(enemy.global_position) <= aoe_radius:
				enemy.take_damage(damage)
	queue_free()
