extends BaseUnit

func _ready() -> void:
	max_hp = 100
	damage = 10
	attack_speed = 1.0
	move_speed = 120.0
	attack_range = 45.0
	unit_color = Color(0.2, 0.4, 0.9)
	unit_radius = 15.0
	super._ready()


func _draw() -> void:
	var bounce := sin(_anim_time) * 2.0
	var squash := 1.0 + sin(_anim_time * 2.0) * 0.05 if _is_moving else 1.0
	var oy := bounce  # vertical offset for bounce

	# Shadow
	draw_circle(Vector2(0, 13), 8, Color(0, 0, 0, 0.15))

	# Body (small blue armored torso)
	draw_rect(Rect2(-7, -2 + oy, 14, 12), Color(0.2, 0.4, 0.9))
	draw_rect(Rect2(-5, 0 + oy, 10, 7), Color(0.25, 0.5, 1.0))

	# Shield (floating left)
	var shield_y := -2 + sin(_anim_time + 1.0) * 1.5
	var shield_pts := PackedVector2Array([
		Vector2(-17, -5 + shield_y), Vector2(-12, -8 + shield_y),
		Vector2(-10, 0 + shield_y), Vector2(-12, 6 + shield_y),
		Vector2(-17, 4 + shield_y)])
	draw_colored_polygon(shield_pts, Color(0.25, 0.3, 0.75))
	draw_circle(Vector2(-14, 0 + shield_y), 2.5, Color(0.7, 0.65, 0.15))

	# Sword (floating right)
	var sword_y := -2 + sin(_anim_time + 2.0) * 1.5
	draw_line(Vector2(13, 4 + sword_y), Vector2(13, -14 + sword_y), Color(0.78, 0.8, 0.85), 2.5)
	draw_line(Vector2(10, -2 + sword_y), Vector2(16, -2 + sword_y), Color(0.55, 0.4, 0.2), 2.0)

	# Head (big, brotato style)
	var head_y := -14.0 + oy * 1.2
	draw_circle(Vector2(0, head_y), 11 * squash, Color(0.2, 0.4, 0.9))
	# Helmet
	draw_arc(Vector2(0, head_y - 1), 11.5, PI + 0.3, TAU - 0.3, 20, Color(0.3, 0.35, 0.72), 3.0)
	var helmet_top := PackedVector2Array([
		Vector2(-8, head_y - 4), Vector2(0, head_y - 16), Vector2(8, head_y - 4)])
	draw_colored_polygon(helmet_top, Color(0.3, 0.38, 0.75))
	# Visor
	draw_rect(Rect2(-8, head_y - 3, 16, 5), Color(0.1, 0.15, 0.4))
	# Big eyes (through visor)
	draw_circle(Vector2(-4, head_y - 1), 3.0, Color.WHITE)
	draw_circle(Vector2(4, head_y - 1), 3.0, Color.WHITE)
	draw_circle(Vector2(-3, head_y - 1), 1.8, Color(0.1, 0.1, 0.3))
	draw_circle(Vector2(5, head_y - 1), 1.8, Color(0.1, 0.1, 0.3))
	# Eye shine
	draw_circle(Vector2(-2, head_y - 2), 0.8, Color.WHITE)
	draw_circle(Vector2(6, head_y - 2), 0.8, Color.WHITE)

	_draw_hp_bar()


func _draw_hp_bar() -> void:
	var bar_w := 24.0
	var bar_h := 3.0
	var bar_y := -30.0
	var hp_ratio := float(hp) / float(max_hp)
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, bar_h), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w * hp_ratio, bar_h), Color.GREEN_YELLOW)
