extends CharacterBody2D
class_name BaseUnit

signal unit_died(unit: BaseUnit)

@export var max_hp: int = 100
@export var damage: int = 10
@export var attack_speed: float = 1.0
@export var move_speed: float = 120.0
@export var attack_range: float = 45.0
@export var unit_color: Color = Color.CORNFLOWER_BLUE
@export var unit_radius: float = 15.0

var hp: int
var attack_timer: float = 0.0
var target: Node2D = null


func _ready() -> void:
	hp = max_hp
	add_to_group("player_units")
	collision_layer = 1
	collision_mask = 6
	_create_collision_shape()


func _create_collision_shape() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = unit_radius
	shape.shape = circle
	add_child(shape)


func _draw() -> void:
	# Body
	draw_circle(Vector2.ZERO, unit_radius, unit_color)
	draw_arc(Vector2.ZERO, unit_radius, 0, TAU, 32, unit_color.darkened(0.3), 2.0)
	# HP bar
	var bar_w := unit_radius * 2.2
	var bar_h := 4.0
	var bar_y := -unit_radius - 10.0
	var hp_ratio := float(hp) / float(max_hp)
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, bar_h), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w * hp_ratio, bar_h), Color.GREEN_YELLOW)


func _physics_process(delta: float) -> void:
	var speed_mult := GameManager.game_speed
	attack_timer = max(0.0, attack_timer - delta * speed_mult)

	target = _find_target()
	if target and is_instance_valid(target):
		var dist := global_position.distance_to(target.global_position)
		if dist <= attack_range:
			_do_attack()
		else:
			_move_toward(target, delta * speed_mult)
	else:
		velocity = Vector2.ZERO

	queue_redraw()


func _find_target() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var closest_dist := INF
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var d := global_position.distance_to(enemy.global_position)
		if d < closest_dist:
			closest_dist = d
			closest = enemy
	return closest


func _move_toward(t: Node2D, scaled_delta: float) -> void:
	var dir := (t.global_position - global_position).normalized()
	velocity = dir * move_speed * GameManager.game_speed
	move_and_slide()


func _do_attack() -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	if attack_timer <= 0.0:
		_perform_attack()
		attack_timer = attack_speed


func _perform_attack() -> void:
	if target and is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(damage)


func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		_die()


func _die() -> void:
	unit_died.emit(self)
	queue_free()
