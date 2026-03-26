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
	var r := enemy_radius
	# Bulky body (brown/greenish)
	draw_circle(Vector2.ZERO, r, enemy_color)
	draw_arc(Vector2.ZERO, r, 0, TAU, 32, enemy_color.darkened(0.4), 3.0)
	# Shoulder pads (armor)
	draw_circle(Vector2(-r * 0.7, -r * 0.3), r * 0.35, Color(0.35, 0.35, 0.35))
	draw_circle(Vector2(r * 0.7, -r * 0.3), r * 0.35, Color(0.35, 0.35, 0.35))
	# Small angry eyes
	draw_circle(Vector2(-4, -3), 2.5, Color(0.9, 0.2, 0.1))
	draw_circle(Vector2(4, -3), 2.5, Color(0.9, 0.2, 0.1))
	draw_circle(Vector2(-4, -3), 1.2, Color(0.1, 0.05, 0.05))
	draw_circle(Vector2(4, -3), 1.2, Color(0.1, 0.05, 0.05))
	# Angry brow
	draw_line(Vector2(-7, -5), Vector2(-2, -6), Color(0.35, 0.2, 0.08), 2.0)
	draw_line(Vector2(7, -5), Vector2(2, -6), Color(0.35, 0.2, 0.08), 2.0)
	# Tusks (upward from jaw)
	draw_line(Vector2(-4, 4), Vector2(-5, 0), Color(0.9, 0.88, 0.8), 2.5)
	draw_line(Vector2(4, 4), Vector2(5, 0), Color(0.9, 0.88, 0.8), 2.5)
	# Wide jaw
	draw_arc(Vector2(0, 3), 5.0, 0.2, PI - 0.2, 10, Color(0.35, 0.2, 0.08), 2.0)
	# Big axe (right side)
	draw_line(Vector2(r * 0.5, -r * 0.1), Vector2(r * 1.5, -r * 0.8), Color(0.5, 0.3, 0.15), 3.0)  # handle
	var axe_head := PackedVector2Array([Vector2(r * 1.2, -r * 1.0), Vector2(r * 1.8, -r * 0.6), Vector2(r * 1.5, -r * 0.8)])
	draw_colored_polygon(axe_head, Color(0.55, 0.55, 0.6))
	# HP bar
	_draw_hp_bar()


func _draw_hp_bar() -> void:
	var bar_w := enemy_radius * 2.2
	var bar_h := 5.0
	var bar_y := -enemy_radius - 12.0
	var hp_ratio := float(hp) / float(max_hp)
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, bar_h), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w * hp_ratio, bar_h), Color.ORANGE_RED)
