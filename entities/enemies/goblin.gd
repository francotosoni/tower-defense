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
