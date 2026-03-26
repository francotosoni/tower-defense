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
	var r := unit_radius
	# Body (armored blue)
	draw_circle(Vector2.ZERO, r, unit_color)
	draw_arc(Vector2.ZERO, r, 0, TAU, 32, unit_color.darkened(0.4), 2.0)
	# Helmet visor
	draw_rect(Rect2(-r * 0.5, -r * 0.35, r * 1.0, r * 0.3), Color(0.15, 0.25, 0.6))
	# Eyes through visor
	draw_circle(Vector2(-3, -3), 2.0, Color.WHITE)
	draw_circle(Vector2(3, -3), 2.0, Color.WHITE)
	# Sword (right side)
	draw_line(Vector2(r * 0.6, -r * 0.2), Vector2(r * 1.4, -r * 0.8), Color(0.75, 0.75, 0.8), 2.5)
	draw_line(Vector2(r * 0.8, -r * 0.1), Vector2(r * 0.8, -r * 0.5), Color(0.5, 0.35, 0.15), 2.0)  # crossguard
	# Shield (left side)
	draw_circle(Vector2(-r * 0.7, 0), r * 0.45, Color(0.3, 0.3, 0.7))
	draw_circle(Vector2(-r * 0.7, 0), r * 0.25, Color(0.6, 0.6, 0.1))
	# HP bar
	_draw_hp_bar()


func _draw_hp_bar() -> void:
	var bar_w := unit_radius * 2.2
	var bar_h := 4.0
	var bar_y := -unit_radius - 12.0
	var hp_ratio := float(hp) / float(max_hp)
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, bar_h), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w * hp_ratio, bar_h), Color.GREEN_YELLOW)
