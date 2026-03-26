extends BaseUnit

var _bolt_scene: PackedScene
var _aoe_radius: float = 90.0


func _ready() -> void:
	max_hp = 40
	damage = 15
	attack_speed = 1.5
	move_speed = 75.0
	attack_range = 270.0
	unit_color = Color(0.6, 0.2, 0.8)
	unit_radius = 13.0
	_bolt_scene = load("res://entities/projectiles/magic_bolt.tscn")
	super._ready()


func _find_target() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return null
	var best_target: Node2D = null
	var best_count := 0
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var count := 0
		for other in enemies:
			if is_instance_valid(other) and enemy.global_position.distance_to(other.global_position) <= _aoe_radius:
				count += 1
		if count > best_count or (count == best_count and (best_target == null or global_position.distance_to(enemy.global_position) < global_position.distance_to(best_target.global_position))):
			best_count = count
			best_target = enemy
	return best_target


func _perform_attack() -> void:
	if not target or not is_instance_valid(target):
		return
	var bolt := _bolt_scene.instantiate()
	bolt.position = global_position
	bolt.damage = damage
	bolt.aoe_radius = _aoe_radius
	bolt.setup(target.global_position)
	var proj_container := get_tree().current_scene.find_child("Projectiles", true, false)
	if proj_container:
		proj_container.add_child(bolt)
	else:
		get_parent().add_child(bolt)


func _draw() -> void:
	var bounce := sin(_anim_time) * 2.0
	var squash := 1.0 + sin(_anim_time * 2.0) * 0.05 if _is_moving else 1.0
	var oy := bounce

	# Shadow
	draw_circle(Vector2(0, 13), 8, Color(0, 0, 0, 0.15))

	# Robe (wider at bottom, purple)
	var robe := PackedVector2Array([
		Vector2(-6, -3 + oy), Vector2(6, -3 + oy),
		Vector2(9, 12 + oy), Vector2(-9, 12 + oy)])
	draw_colored_polygon(robe, Color(0.5, 0.15, 0.7))
	draw_rect(Rect2(-5, -1 + oy, 10, 5), Color(0.55, 0.2, 0.75))

	# Staff (floating right)
	var staff_y := sin(_anim_time + 1.0) * 1.5
	draw_line(Vector2(14, 10 + staff_y), Vector2(14, -16 + staff_y), Color(0.5, 0.3, 0.15), 2.5)
	# Crystal orb on staff (glows)
	var orb_glow := 0.7 + sin(_anim_time * 3.0) * 0.3
	draw_circle(Vector2(14, -18 + staff_y), 5.0, Color(0.3 * orb_glow, 0.7 * orb_glow, 1.0 * orb_glow))
	draw_circle(Vector2(14, -18 + staff_y), 3.0, Color(0.5, 0.9, 1.0))

	# Head (big, brotato style)
	var head_y := -14.0 + oy * 1.2
	draw_circle(Vector2(0, head_y), 10 * squash, Color(0.85, 0.72, 0.58))
	# Wizard hat
	var hat_brim := PackedVector2Array([
		Vector2(-13, head_y - 6), Vector2(13, head_y - 6),
		Vector2(11, head_y - 9), Vector2(-11, head_y - 9)])
	draw_colored_polygon(hat_brim, Color(0.35, 0.08, 0.55))
	var hat_top := PackedVector2Array([
		Vector2(-9, head_y - 8), Vector2(2, head_y - 28),
		Vector2(8, head_y - 8)])
	draw_colored_polygon(hat_top, Color(0.4, 0.1, 0.6))
	# Star on hat
	draw_circle(Vector2(3, head_y - 20), 2.5, Color(1.0, 0.9, 0.2))
	# Hat band
	draw_line(Vector2(-9, head_y - 9), Vector2(8, head_y - 9), Color(0.7, 0.5, 0.1), 2.0)
	# Big glowing eyes
	draw_circle(Vector2(-4, head_y), 3.5, Color(0.85, 0.65, 1.0))
	draw_circle(Vector2(4, head_y), 3.5, Color(0.85, 0.65, 1.0))
	draw_circle(Vector2(-3, head_y), 2.0, Color(0.6, 0.1, 0.9))
	draw_circle(Vector2(5, head_y), 2.0, Color(0.6, 0.1, 0.9))
	draw_circle(Vector2(-2, head_y - 1), 0.8, Color.WHITE)
	draw_circle(Vector2(6, head_y - 1), 0.8, Color.WHITE)

	_draw_hp_bar()


func _draw_hp_bar() -> void:
	var bar_w := 24.0
	var bar_h := 3.0
	var bar_y := -32.0
	var hp_ratio := float(hp) / float(max_hp)
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, bar_h), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w * hp_ratio, bar_h), Color.GREEN_YELLOW)
