extends BaseEnemy

func _ready() -> void:
	max_hp = 40
	damage = 5
	attack_speed = 1.0
	move_speed = 180.0
	attack_range = 45.0
	base_damage = 10
	bounty_gold = 5
	enemy_color = Color(0.4, 0.7, 0.2)  # Green
	enemy_radius = 11.0
	super._ready()


func _draw() -> void:
	var bounce := sin(_anim_time) * 2.5
	var squash := 1.0 + sin(_anim_time * 2.0) * 0.06 if _is_moving else 1.0
	var oy := bounce

	# Shadow
	draw_circle(Vector2(0, 10), 6, Color(0, 0, 0, 0.15))

	# Small scrawny body (green)
	var body := PackedVector2Array([
		Vector2(-5, -1 + oy), Vector2(5, -1 + oy),
		Vector2(6, 10 + oy), Vector2(-6, 10 + oy)])
	draw_colored_polygon(body, Color(0.35, 0.55, 0.15))
	# Loincloth
	var cloth := PackedVector2Array([
		Vector2(-5, 5 + oy), Vector2(5, 5 + oy),
		Vector2(4, 10 + oy), Vector2(-4, 10 + oy)])
	draw_colored_polygon(cloth, Color(0.4, 0.3, 0.15))

	# Dagger (floating right)
	var dagger_y := sin(_anim_time + 2.0) * 1.5
	draw_line(Vector2(11, 3 + dagger_y), Vector2(11, -8 + dagger_y), Color(0.7, 0.72, 0.75), 2.0)
	draw_line(Vector2(9, 1 + dagger_y), Vector2(13, 1 + dagger_y), Color(0.4, 0.25, 0.1), 1.5)

	# Head (BIG relative to body - brotato style)
	var head_y := -11.0 + oy * 1.3
	draw_circle(Vector2(0, head_y), 9 * squash, Color(0.4, 0.65, 0.2))
	# Big pointy ears
	var left_ear := PackedVector2Array([
		Vector2(-8, head_y - 2), Vector2(-18, head_y - 8), Vector2(-7, head_y - 5)])
	draw_colored_polygon(left_ear, Color(0.35, 0.55, 0.15))
	var right_ear := PackedVector2Array([
		Vector2(8, head_y - 2), Vector2(18, head_y - 8), Vector2(7, head_y - 5)])
	draw_colored_polygon(right_ear, Color(0.35, 0.55, 0.15))
	# Big menacing yellow eyes
	draw_circle(Vector2(-4, head_y - 1), 3.5, Color(1.0, 0.92, 0.1))
	draw_circle(Vector2(4, head_y - 1), 3.5, Color(1.0, 0.92, 0.1))
	draw_circle(Vector2(-3, head_y - 1), 2.0, Color(0.6, 0.1, 0.05))
	draw_circle(Vector2(5, head_y - 1), 2.0, Color(0.6, 0.1, 0.05))
	# Angry brow
	draw_line(Vector2(-8, head_y - 5), Vector2(-2, head_y - 4), Color(0.3, 0.45, 0.1), 2.0)
	draw_line(Vector2(8, head_y - 5), Vector2(2, head_y - 4), Color(0.3, 0.45, 0.1), 2.0)
	# Evil grin with fangs
	draw_arc(Vector2(0, head_y + 4), 5.0, 0.1, PI - 0.1, 10, Color(0.2, 0.1, 0.05), 1.5)
	draw_line(Vector2(-3, head_y + 5), Vector2(-2.5, head_y + 8), Color.WHITE, 1.5)
	draw_line(Vector2(3, head_y + 5), Vector2(2.5, head_y + 8), Color.WHITE, 1.5)
	# Nose (pointy)
	draw_circle(Vector2(0, head_y + 2), 1.5, Color(0.35, 0.55, 0.12))

	_draw_hp_bar()


func _draw_hp_bar() -> void:
	var bar_w := 20.0
	var bar_h := 3.0
	var bar_y := -26.0
	var hp_ratio := float(hp) / float(max_hp)
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, bar_h), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w * hp_ratio, bar_h), Color.ORANGE_RED)
