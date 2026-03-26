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
	var r := enemy_radius
	# Body (goblin green)
	draw_circle(Vector2.ZERO, r, enemy_color)
	draw_arc(Vector2.ZERO, r, 0, TAU, 32, enemy_color.darkened(0.3), 2.0)
	# Pointy ears
	var left_ear := PackedVector2Array([Vector2(-r * 0.8, -r * 0.2), Vector2(-r * 1.5, -r * 0.6), Vector2(-r * 0.7, -r * 0.5)])
	draw_colored_polygon(left_ear, Color(0.35, 0.6, 0.15))
	var right_ear := PackedVector2Array([Vector2(r * 0.8, -r * 0.2), Vector2(r * 1.5, -r * 0.6), Vector2(r * 0.7, -r * 0.5)])
	draw_colored_polygon(right_ear, Color(0.35, 0.6, 0.15))
	# Beady yellow eyes
	draw_circle(Vector2(-3, -1), 2.5, Color(1.0, 0.9, 0.1))
	draw_circle(Vector2(3, -1), 2.5, Color(1.0, 0.9, 0.1))
	draw_circle(Vector2(-3, -1), 1.2, Color(0.1, 0.1, 0.1))
	draw_circle(Vector2(3, -1), 1.2, Color(0.1, 0.1, 0.1))
	# Wide evil grin with teeth
	draw_arc(Vector2(0, 2), 5.0, 0.1, PI - 0.1, 10, Color(0.2, 0.1, 0.05), 1.5)
	draw_line(Vector2(-3, 3.5), Vector2(-2, 5), Color.WHITE, 1.5)  # left fang
	draw_line(Vector2(3, 3.5), Vector2(2, 5), Color.WHITE, 1.5)  # right fang
	# Small dagger
	draw_line(Vector2(r * 0.5, r * 0.1), Vector2(r * 1.3, -r * 0.3), Color(0.7, 0.7, 0.75), 2.0)
	draw_line(Vector2(r * 0.5, r * 0.1), Vector2(r * 0.5, r * 0.4), Color(0.4, 0.25, 0.1), 1.5)  # handle
	# HP bar
	_draw_hp_bar()


func _draw_hp_bar() -> void:
	var bar_w := enemy_radius * 2.2
	var bar_h := 4.0
	var bar_y := -enemy_radius - 12.0
	var hp_ratio := float(hp) / float(max_hp)
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, bar_h), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w * hp_ratio, bar_h), Color.ORANGE_RED)
