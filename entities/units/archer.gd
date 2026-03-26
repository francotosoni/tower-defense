extends BaseUnit

var _arrow_scene: PackedScene


func _ready() -> void:
	max_hp = 50
	damage = 8
	attack_speed = 0.8
	move_speed = 90.0
	attack_range = 300.0
	unit_color = Color(0.1, 0.7, 0.3)
	unit_radius = 13.0
	_arrow_scene = load("res://entities/projectiles/arrow.tscn")
	super._ready()


func _perform_attack() -> void:
	if not target or not is_instance_valid(target):
		return
	var arrow := _arrow_scene.instantiate()
	arrow.position = global_position
	arrow.direction = (target.global_position - global_position).normalized()
	arrow.damage = damage
	arrow.rotation = arrow.direction.angle()
	arrow.target_group = "enemies"
	arrow.collision_layer = 0
	arrow.collision_mask = 2
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
	draw_circle(Vector2(0, 12), 7, Color(0, 0, 0, 0.15))

	# Body (green tunic)
	draw_rect(Rect2(-6, -2 + oy, 12, 12), Color(0.1, 0.55, 0.25))
	draw_rect(Rect2(-5, 0 + oy, 10, 8), Color(0.12, 0.6, 0.3))
	# Belt
	draw_rect(Rect2(-6, 6 + oy, 12, 2), Color(0.4, 0.25, 0.1))

	# Quiver (behind, left side)
	draw_rect(Rect2(-10, -8 + oy, 4, 14), Color(0.45, 0.28, 0.1))
	draw_line(Vector2(-9, -9 + oy), Vector2(-9, -6 + oy), Color(0.6, 0.5, 0.3), 1.0)
	draw_line(Vector2(-7, -10 + oy), Vector2(-7, -6 + oy), Color(0.6, 0.5, 0.3), 1.0)

	# Bow (floating right)
	var bow_y := sin(_anim_time + 1.5) * 1.5
	draw_arc(Vector2(13, 0 + bow_y), 10, -PI / 2.5, PI / 2.5, 16, Color(0.55, 0.35, 0.1), 2.5)
	draw_line(Vector2(13, -7 + bow_y), Vector2(13, 7 + bow_y), Color(0.9, 0.85, 0.7), 1.0)

	# Head (big, brotato style)
	var head_y := -14.0 + oy * 1.2
	draw_circle(Vector2(0, head_y), 10 * squash, Color(0.85, 0.72, 0.55))
	# Hood
	draw_arc(Vector2(0, head_y - 2), 11, PI + 0.2, TAU - 0.2, 20, Color(0.08, 0.45, 0.18), 4.0)
	var hood_pts := PackedVector2Array([
		Vector2(-7, head_y - 6), Vector2(0, head_y - 18), Vector2(7, head_y - 6)])
	draw_colored_polygon(hood_pts, Color(0.08, 0.45, 0.18))
	# Big eyes
	draw_circle(Vector2(-4, head_y), 3.0, Color.WHITE)
	draw_circle(Vector2(4, head_y), 3.0, Color.WHITE)
	draw_circle(Vector2(-3, head_y), 1.8, Color(0.15, 0.4, 0.15))
	draw_circle(Vector2(5, head_y), 1.8, Color(0.15, 0.4, 0.15))
	draw_circle(Vector2(-2, head_y - 1), 0.8, Color.WHITE)
	draw_circle(Vector2(6, head_y - 1), 0.8, Color.WHITE)
	# Slight smile
	draw_arc(Vector2(0, head_y + 3), 3.0, 0.2, PI - 0.2, 8, Color(0.5, 0.3, 0.2), 1.0)

	_draw_hp_bar()


func _draw_hp_bar() -> void:
	var bar_w := 22.0
	var bar_h := 3.0
	var bar_y := -30.0
	var hp_ratio := float(hp) / float(max_hp)
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, bar_h), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w * hp_ratio, bar_h), Color.GREEN_YELLOW)
