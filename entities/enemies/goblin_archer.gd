extends BaseEnemy

var _arrow_scene: PackedScene


func _ready() -> void:
	max_hp = 60
	damage = 7
	attack_speed = 1.0
	move_speed = 120.0
	attack_range = 225.0
	base_damage = 10
	bounty_gold = 10
	enemy_color = Color(0.3, 0.6, 0.15)  # Dark green
	enemy_radius = 12.0
	_arrow_scene = load("res://entities/projectiles/arrow.tscn")
	super._ready()


func _find_aggro_target() -> Node2D:
	# Goblin archers attack from range, so use attack_range for aggro
	var units := get_tree().get_nodes_in_group("player_units")
	var closest: Node2D = null
	var closest_dist := attack_range
	for unit in units:
		if not is_instance_valid(unit):
			continue
		var d := global_position.distance_to(unit.global_position)
		if d < closest_dist:
			closest_dist = d
			closest = unit
	return closest


func _perform_attack() -> void:
	if not target or not is_instance_valid(target):
		return
	var arrow := _arrow_scene.instantiate()
	arrow.position = global_position
	arrow.direction = (target.global_position - global_position).normalized()
	arrow.damage = damage
	arrow.rotation = arrow.direction.angle()
	arrow.target_group = "player_units"
	arrow.collision_layer = 0
	arrow.collision_mask = 1
	var proj_container := get_tree().current_scene.find_child("Projectiles", true, false)
	if proj_container:
		proj_container.add_child(arrow)
	else:
		get_parent().add_child(arrow)


func _draw() -> void:
	draw_circle(Vector2.ZERO, enemy_radius, enemy_color)
	# Bow indicator
	draw_arc(Vector2(-enemy_radius * 0.3, 0), enemy_radius * 0.5, PI / 2, 3 * PI / 2, 8, Color(0.5, 0.3, 0.1), 2.0)
	# HP bar
	var bar_w := enemy_radius * 2.2
	var bar_h := 4.0
	var bar_y := -enemy_radius - 10.0
	var hp_ratio := float(hp) / float(max_hp)
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, bar_h), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w * hp_ratio, bar_h), Color.ORANGE_RED)
