extends CharacterBody2D
class_name BaseEnemy

signal enemy_died(enemy: BaseEnemy, bounty: int)

@export var max_hp: int = 40
@export var damage: int = 5
@export var attack_speed: float = 1.0
@export var move_speed: float = 180.0
@export var attack_range: float = 45.0
@export var base_damage: int = 10
@export var bounty_gold: int = 5
@export var enemy_color: Color = Color(0.8, 0.2, 0.2)
@export var enemy_radius: float = 13.0

const AGGRO_RANGE := 120.0

var hp: int
var attack_timer: float = 0.0
var target: Node2D = null
var _base_node: Node2D = null


func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 5
	_create_collision_shape()


func _create_collision_shape() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = enemy_radius
	shape.shape = circle
	add_child(shape)


func _draw() -> void:
	# Body
	draw_circle(Vector2.ZERO, enemy_radius, enemy_color)
	draw_arc(Vector2.ZERO, enemy_radius, 0, TAU, 32, enemy_color.darkened(0.3), 2.0)
	# HP bar
	var bar_w := enemy_radius * 2.2
	var bar_h := 4.0
	var bar_y := -enemy_radius - 10.0
	var hp_ratio := float(hp) / float(max_hp)
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, bar_h), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w * hp_ratio, bar_h), Color.ORANGE_RED)


func _physics_process(delta: float) -> void:
	var speed_mult := GameManager.game_speed
	attack_timer = max(0.0, attack_timer - delta * speed_mult)

	# Check for nearby player troops to aggro
	target = _find_aggro_target()

	if target and is_instance_valid(target):
		var dist := global_position.distance_to(target.global_position)
		if dist <= attack_range:
			_do_attack()
		else:
			_move_toward(target, speed_mult)
	else:
		# No aggro target — move toward the base
		_move_toward_base(speed_mult)

	queue_redraw()


func _find_aggro_target() -> Node2D:
	var units := get_tree().get_nodes_in_group("player_units")
	var closest: Node2D = null
	var closest_dist := AGGRO_RANGE
	for unit in units:
		if not is_instance_valid(unit):
			continue
		var d := global_position.distance_to(unit.global_position)
		if d < closest_dist:
			closest_dist = d
			closest = unit
	return closest


func _move_toward(t: Node2D, speed_mult: float) -> void:
	var dir := (t.global_position - global_position).normalized()
	velocity = dir * move_speed * speed_mult
	move_and_slide()


func _move_toward_base(speed_mult: float) -> void:
	if not _base_node:
		_base_node = _find_base()
	if _base_node and is_instance_valid(_base_node):
		var dir := (_base_node.global_position - global_position).normalized()
		velocity = dir * move_speed * speed_mult
		move_and_slide()
		# Check if reached the base
		if global_position.distance_to(_base_node.global_position) < 50.0:
			_hit_base()
	else:
		# Fallback: move left
		velocity = Vector2.LEFT * move_speed * speed_mult
		move_and_slide()
		if global_position.x < 60.0:
			_hit_base()


func _find_base() -> Node2D:
	var bases := get_tree().get_nodes_in_group("player_base")
	if bases.size() > 0:
		return bases[0]
	return null


func _do_attack() -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	if attack_timer <= 0.0:
		_perform_attack()
		attack_timer = attack_speed


func _perform_attack() -> void:
	if target and is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(damage)


func _hit_base() -> void:
	GameManager.damage_base(base_damage)
	queue_free()


func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		_die()


func _die() -> void:
	GameManager.add_gold(bounty_gold)
	enemy_died.emit(self, bounty_gold)
	queue_free()
