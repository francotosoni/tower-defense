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
	# Bigger, chunkier body
	draw_circle(Vector2.ZERO, enemy_radius, enemy_color)
	draw_arc(Vector2.ZERO, enemy_radius, 0, TAU, 32, enemy_color.darkened(0.4), 3.0)
	# Shield indicator
	draw_arc(Vector2(-4, 0), enemy_radius * 0.5, PI / 2, 3 * PI / 2, 12, Color(0.4, 0.4, 0.4), 3.0)
	# HP bar
	var bar_w := enemy_radius * 2.2
	var bar_h := 5.0
	var bar_y := -enemy_radius - 10.0
	var hp_ratio := float(hp) / float(max_hp)
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, bar_h), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(-bar_w / 2, bar_y, bar_w * hp_ratio, bar_h), Color.ORANGE_RED)
