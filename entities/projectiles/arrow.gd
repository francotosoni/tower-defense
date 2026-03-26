extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 500.0
var damage: int = 8
var _max_range: float = 400.0
var _traveled: float = 0.0
var target_group: String = "enemies"


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _draw() -> void:
	draw_line(-direction.normalized() * 8, direction.normalized() * 8, Color(0.6, 0.4, 0.1), 3.0)
	draw_circle(direction.normalized() * 8, 2.0, Color(0.8, 0.6, 0.2))


func _physics_process(delta: float) -> void:
	var movement := direction * speed * delta * GameManager.game_speed
	position += movement
	_traveled += movement.length()
	if _traveled >= _max_range:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and body.is_in_group(target_group):
		body.take_damage(damage)
		queue_free()
