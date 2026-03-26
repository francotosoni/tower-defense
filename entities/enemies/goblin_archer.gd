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
	var bounce := sin(_anim_time) * 2.0
	var squash := 1.0 + sin(_anim_time * 2.0) * 0.05 if _is_moving else 1.0
	var oy := bounce

	# Shadow
	draw_circle(Vector2(0, 10), 6, Color(0, 0, 0, 0.15))

	# Scrawny body (dark green, with vest)
	var body := PackedVector2Array([
		Vector2(-5, -1 + oy), Vector2(5, -1 + oy),
		Vector2(6, 10 + oy), Vector2(-6, 10 + oy)])
	draw_colored_polygon(body, Color(0.25, 0.5, 0.12))
	# Leather vest
	draw_rect(Rect2(-4, 0 + oy, 8, 6), Color(0.35, 0.22, 0.1))

	# Bow (floating left)
	var bow_y := sin(_anim_time + 1.5) * 1.5
	draw_arc(Vector2(-12, 0 + bow_y), 9, -PI / 2.5, PI / 2.5, 14, Color(0.45, 0.28, 0.08), 2.5)
	draw_line(Vector2(-12, -6 + bow_y), Vector2(-12, 6 + bow_y), Color(0.85, 0.8, 0.65), 1.0)
	# Arrow nocked
	draw_line(Vector2(-12, 0 + bow_y), Vector2(0, 0 + bow_y), Color(0.5, 0.35, 0.1), 1.5)
	var arrow_tip := PackedVector2Array([
		Vector2(0, -2 + bow_y), Vector2(3, 0 + bow_y), Vector2(0, 2 + bow_y)])
	draw_colored_polygon(arrow_tip, Color(0.6, 0.6, 0.65))

	# Head (big goblin head)
	var head_y := -11.0 + oy * 1.3
	draw_circle(Vector2(0, head_y), 9 * squash, Color(0.3, 0.55, 0.15))
	# Big pointy ears
	var left_ear := PackedVector2Array([
		Vector2(-8, head_y - 1), Vector2(-17, head_y - 7), Vector2(-7, head_y - 4)])
	draw_colored_polygon(left_ear, Color(0.25, 0.48, 0.1))
	var right_ear := PackedVector2Array([
		Vector2(8, head_y - 1), Vector2(17, head_y - 7), Vector2(7, head_y - 4)])
	draw_colored_polygon(right_ear, Color(0.25, 0.48, 0.1))
	# Bandana / headband
	draw_line(Vector2(-8, head_y - 4), Vector2(8, head_y - 4), Color(0.55, 0.15, 0.1), 2.5)
	draw_line(Vector2(7, head_y - 4), Vector2(12, head_y - 1), Color(0.55, 0.15, 0.1), 2.0)  # tail
	# Yellow eyes (focused, aiming)
	draw_circle(Vector2(-4, head_y - 1), 3.0, Color(1.0, 0.9, 0.1))
	draw_circle(Vector2(4, head_y - 1), 3.0, Color(1.0, 0.9, 0.1))
	# Squinting (one eye more closed for aiming)
	draw_circle(Vector2(-3, head_y - 1), 1.8, Color(0.5, 0.1, 0.05))
	draw_circle(Vector2(5, head_y - 1), 1.2, Color(0.5, 0.1, 0.05))  # squinted
	draw_line(Vector2(2, head_y - 3), Vector2(8, head_y - 2), Color(0.2, 0.4, 0.08), 1.5)  # squint line
	# Sneaky grin
	draw_arc(Vector2(1, head_y + 4), 4.0, 0.0, PI * 0.7, 8, Color(0.2, 0.1, 0.05), 1.5)

	_draw_hp_bar()


func _draw_hp_bar() -> void:
	var bar_w := 20.0
	var bar_h := 3.0
	var bar_y := -26.0
	var hp_ratio := float(hp) / float(max_hp)
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, bar_h), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w * hp_ratio, bar_h), Color.ORANGE_RED)
