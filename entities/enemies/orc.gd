extends BaseEnemy

func _ready() -> void:
	max_hp = 150
	damage = 12
	attack_speed = 1.5
	move_speed = 75.0
	attack_range = 45.0
	base_damage = 30
	bounty_gold = 15
	enemy_color = Color(0.5, 0.3, 0.1)  # Brown
	enemy_radius = 18.0
	super._ready()


func _draw() -> void:
	var bounce := sin(_anim_time) * 1.5  # heavier, less bounce
	var squash := 1.0 + sin(_anim_time * 2.0) * 0.03 if _is_moving else 1.0
	var oy := bounce

	# Shadow (bigger)
	draw_circle(Vector2(0, 16), 11, Color(0, 0, 0, 0.15))

	# Big chunky body
	var body := PackedVector2Array([
		Vector2(-10, -4 + oy), Vector2(10, -4 + oy),
		Vector2(12, 14 + oy), Vector2(-12, 14 + oy)])
	draw_colored_polygon(body, Color(0.45, 0.55, 0.2))
	# Chest armor plate
	draw_rect(Rect2(-8, -2 + oy, 16, 10), Color(0.35, 0.35, 0.35))
	draw_rect(Rect2(-6, 0 + oy, 12, 6), Color(0.4, 0.4, 0.42))
	# Belt with skull buckle
	draw_rect(Rect2(-10, 8 + oy, 20, 3), Color(0.3, 0.2, 0.08))
	draw_circle(Vector2(0, 9.5 + oy), 2.0, Color(0.8, 0.8, 0.75))

	# Shoulder pads
	draw_circle(Vector2(-12, -2 + oy), 5, Color(0.38, 0.38, 0.4))
	draw_circle(Vector2(12, -2 + oy), 5, Color(0.38, 0.38, 0.4))
	# Spikes on shoulders
	draw_line(Vector2(-14, -5 + oy), Vector2(-15, -10 + oy), Color(0.5, 0.5, 0.5), 2.0)
	draw_line(Vector2(14, -5 + oy), Vector2(15, -10 + oy), Color(0.5, 0.5, 0.5), 2.0)

	# Big axe (floating right)
	var axe_y := sin(_anim_time + 1.0) * 1.0
	draw_line(Vector2(17, 10 + axe_y), Vector2(17, -12 + axe_y), Color(0.5, 0.3, 0.15), 3.0)
	var axe_head := PackedVector2Array([
		Vector2(14, -12 + axe_y), Vector2(17, -18 + axe_y),
		Vector2(24, -14 + axe_y), Vector2(22, -8 + axe_y)])
	draw_colored_polygon(axe_head, Color(0.5, 0.5, 0.55))
	draw_polyline(PackedVector2Array([
		Vector2(14, -12 + axe_y), Vector2(17, -18 + axe_y),
		Vector2(24, -14 + axe_y), Vector2(22, -8 + axe_y),
		Vector2(14, -12 + axe_y)]), Color(0.4, 0.4, 0.45), 1.0)

	# Head (big but not as big ratio - orc is beefy)
	var head_y := -14.0 + oy * 1.1
	draw_circle(Vector2(0, head_y), 12 * squash, Color(0.45, 0.55, 0.2))
	# Brow ridge
	draw_line(Vector2(-10, head_y - 5), Vector2(-2, head_y - 7), Color(0.35, 0.42, 0.15), 3.0)
	draw_line(Vector2(10, head_y - 5), Vector2(2, head_y - 7), Color(0.35, 0.42, 0.15), 3.0)
	# Small angry red eyes
	draw_circle(Vector2(-4, head_y - 2), 3.0, Color(0.9, 0.15, 0.1))
	draw_circle(Vector2(4, head_y - 2), 3.0, Color(0.9, 0.15, 0.1))
	draw_circle(Vector2(-4, head_y - 2), 1.5, Color(0.2, 0.05, 0.05))
	draw_circle(Vector2(4, head_y - 2), 1.5, Color(0.2, 0.05, 0.05))
	# Wide jaw / underbite
	draw_arc(Vector2(0, head_y + 5), 7.0, 0.1, PI - 0.1, 12, Color(0.35, 0.42, 0.15), 2.0)
	# Big tusks pointing up
	draw_line(Vector2(-5, head_y + 6), Vector2(-6, head_y - 1), Color(0.92, 0.9, 0.82), 3.0)
	draw_line(Vector2(5, head_y + 6), Vector2(6, head_y - 1), Color(0.92, 0.9, 0.82), 3.0)

	_draw_hp_bar()


func _draw_hp_bar() -> void:
	var bar_w := 28.0
	var bar_h := 3.0
	var bar_y := -32.0
	var hp_ratio := float(hp) / float(max_hp)
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, bar_h), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w * hp_ratio, bar_h), Color.ORANGE_RED)
